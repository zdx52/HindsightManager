import Foundation

// MARK: - 错误类型

enum InstallError: LocalizedError {
    case uvInstallFailed(exitCode: Int32)
    case hindsightInstallFailed(detail: String)
    case configFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .uvInstallFailed(let code):
            return "uv 安装失败 (exit: \(code))"
        case .hindsightInstallFailed(let detail):
            return "安装失败: \(detail)"
        case .configFailed(let msg):
            return "配置失败: \(msg)"
        }
    }
}

// MARK: - 安装 / 卸载服务

final class InstallService: Sendable {
    
    /// 安装 uv
    func installUV() async -> Result<Void, InstallError> {
        let result = await runCmdOutput("/bin/bash", "-c",
            "curl -LsSf https://astral.sh/uv/install.sh | sh")
        if result.exitCode == 0 {
            return .success(())
        }
        return .failure(.uvInstallFailed(exitCode: result.exitCode))
    }
    
    /// 安装或升级 hindsight-api
    func installHindsight(upgrade: Bool) async -> Result<Void, InstallError> {
        let cmd: String
        if upgrade {
            cmd = "uv tool upgrade hindsight-api 2>&1"
        } else {
            cmd = "uv tool install hindsight-api 2>&1"
        }
        let result = await runCmdOutput("/bin/bash", "-l", "-c", cmd)
        if result.exitCode == 0 {
            return .success(())
        }
        // fallback: pip install
        let fallback = await runCmdOutput("/bin/bash", "-c",
            "source ~/.venv/bin/activate 2>/dev/null; pip install hindsight-api --upgrade 2>&1")
        if fallback.exitCode == 0 {
            return .success(())
        }
        return .failure(.hindsightInstallFailed(detail: result.output ?? "未知错误"))
    }
    
    /// 配置 launchd 守护进程
    func configureLaunchd() async -> Bool {
        let home = NSHomeDirectory()
        let scriptsDir = home + "/.hermes/scripts"
        _ = await runCmdOutput("/bin/mkdir", "-p", scriptsDir)
        
        // 始终重写启动脚本
        let startScript = scriptsDir + "/hindsight-start.sh"
        let script = Self.startScriptContent(home: home)
        do {
            try script.write(toFile: startScript, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: startScript)
        } catch {
            NSLog("[HindsightManager] Failed to write start script: \(error.localizedDescription)")
            return false
        }
        
        // 重写 plist
        let plistContent = Self.plistContent(home: home, startScript: startScript)
        let plistPath = home + "/Library/LaunchAgents/com.user.hindsight-embed.plist"
        do {
            try plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
        } catch {
            NSLog("[HindsightManager] Failed to write launchd plist: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    /// 启动服务
    func startService() async -> Bool {
        let home = NSHomeDirectory()
        let plist = home + "/Library/LaunchAgents/com.user.hindsight-embed.plist"
        
        // 尝试多种启动方式
        let methods: [() async -> (output: String?, exitCode: Int32)] = [
            { await runCmdOutput("/bin/launchctl", "load", plist) },
            { await runCmdOutput("/bin/launchctl", "bootstrap",
                "gui/\(getuid())", plist) },
        ]
        
        for method in methods {
            if await method().exitCode == 0 { break }
        }
        
        // 等待服务启动（最长 30 秒）
        for _ in 0..<15 {
            let health = await runCmdOutput("/usr/bin/curl", "-sf", "http://localhost:9077/health")
            if health.exitCode == 0 {
                return true
            }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        return false
    }
    
    /// 停止服务
    func stopService() async -> Bool {
        let r1 = await runCmdOutput("/bin/launchctl", "bootout",
            "gui/\(getuid())/com.user.hindsight-embed")
        let r2 = await runCmdOutput("/bin/launchctl", "unload",
            NSHomeDirectory() + "/Library/LaunchAgents/com.user.hindsight-embed.plist")
        _ = await runCmdOutput("/usr/bin/killall", "-9", "hindsight-api")
        return r1.exitCode == 0 || r2.exitCode == 0
    }
    
    /// 卸载
    func uninstall() async -> Bool {
        _ = await stopService()
        _ = await runCmdOutput("/bin/bash", "-c", "uv tool uninstall hindsight-api 2>/dev/null")
        
        let files = [
            NSHomeDirectory() + "/Library/LaunchAgents/com.user.hindsight-embed.plist",
            NSHomeDirectory() + "/.hermes/scripts/hindsight-start.sh",
            NSHomeDirectory() + "/.hermes/scripts/hindsight-upgrade.sh",
        ]
        for f in files {
            try? FileManager.default.removeItem(atPath: f)
        }
        return true
    }
    
    // MARK: - 模板生成（静态方法避免字符串插值污染）
    
    private static func startScriptContent(home: String) -> String {
        return #"""
        #!/bin/bash
        export HF_ENDPOINT=https://hf-mirror.com
        export PYTHONPATH=""
        
        PG_BIN="\#(home)/.pg0/installation/18.1.0/bin"
        PG_DIR="\#(home)/.pg0/instances/hindsight-embed-hermes/data"
        
        # PostgreSQL
        if ! /usr/sbin/lsof -i :5432 >/dev/null 2>&1; then
            rm -f "$PG_DIR/postmaster.pid"
            "$PG_BIN/pg_ctl" -D "$PG_DIR" -l /tmp/pg-hindsight.log start
            sleep 3
        fi
        
        # 从 Keychain 读取 API Key
        API_KEY=$(security find-generic-password -s "com.aiusagemonitor" -a "hindsight-api-key" -w 2>/dev/null)
        if [ -z "$API_KEY" ]; then
            echo "[FATAL] Hindsight API key not found in Keychain" >&2
            exit 1
        fi
        
        # 启动 API（通过 opencode-go 访问 DeepSeek V4 Flash）
        exec /usr/bin/env \
          HF_ENDPOINT=https://hf-mirror.com \
          PYTHONPATH="" \
          HINDSIGHT_API_LLM_PROVIDER=opencode-go \
          HINDSIGHT_API_LLM_API_KEY="$API_KEY" \
          HINDSIGHT_API_LLM_MODEL=deepseek-v4-flash \
          \#(home)/.local/share/uv/tools/hindsight-api/bin/python \
          \#(home)/.local/share/uv/tools/hindsight-api/bin/hindsight-api \
          --port 9077 --idle-timeout 0
        """#
    }
    
    private static func plistContent(home: String, startScript: String) -> String {
        return #"""
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.user.hindsight-embed</string>
            <key>ProgramArguments</key>
            <array>
                <string>\#(startScript)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>ThrottleInterval</key>
            <integer>30</integer>
            <key>StandardOutPath</key>
            <string>\#(home)/.hindsight/profiles/hermes-launchd.log</string>
            <key>StandardErrorPath</key>
            <string>\#(home)/.hindsight/profiles/hermes-launchd.log</string>
            <key>EnvironmentVariables</key>
            <dict>
                <key>PATH</key>
                <string>\#(home)/.local/bin:/usr/local/bin:/usr/bin:/bin</string>
                <key>HOME</key>
                <string>\#(home)</string>
                <key>HF_ENDPOINT</key>
                <string>https://hf-mirror.com</string>
            </dict>
        </dict>
        </plist>
        """#
    }
    
    /// 重新生成 launchd plist 和启动脚本
    func applyLLMConfig() async -> Bool {
        let home = NSHomeDirectory()
        let scriptsDir = home + "/.hermes/scripts"
        _ = await runCmdOutput("/bin/mkdir", "-p", scriptsDir)
        
        // 重写启动脚本
        let startScript = scriptsDir + "/hindsight-start.sh"
        let script = Self.startScriptContent(home: home)
        do {
            try script.write(toFile: startScript, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: startScript)
        } catch {
            return false
        }
        
        // 重写 plist
        let plistContent = Self.plistContent(home: home, startScript: startScript)
        let plistPath = home + "/Library/LaunchAgents/com.user.hindsight-embed.plist"
        do {
            try plistContent.write(toFile: plistPath, atomically: true, encoding: .utf8)
        } catch {
            return false
        }
        
        return true
    }
}
