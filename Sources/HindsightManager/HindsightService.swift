import Foundation

// MARK: - 环境检测

final class HindsightDetector: Sendable {
    
    /// 检查 uv 是否安装
    func checkUVInstalled() async -> Bool {
        await runCmd("/bin/bash", "-c", "command -v uv") != nil
    }
    
    /// 检查 hindsight-api 是否通过 uv tool 安装
    func checkHindsightInstalled() async -> Bool {
        let out = await runCmd("/bin/bash", "-c", "uv tool list 2>/dev/null | grep hindsight-api")
        return out != nil
    }
    
    /// 获取已安装的 hindsight-api 版本
    func getInstalledVersion() async -> String {
        if let out = await runCmd("/bin/bash", "-c",
            "uv tool run hindsight-api --version 2>/dev/null || uv tool show hindsight-api 2>/dev/null | grep Version | awk '{print $2}'"),
           !out.isEmpty {
            return out
        }
        if let out = await runCmd("/bin/bash", "-c",
            "source ~/.venv/bin/activate 2>/dev/null; pip show hindsight-api 2>/dev/null | grep Version | cut -d' ' -f2"),
           !out.isEmpty {
            return out
        }
        return "?.?.?"
    }
    
    /// 检查服务是否运行（端口 9077）
    func checkServiceRunning() async -> Bool {
        let out = await runCmd("/usr/bin/curl", "-sf", "http://localhost:9077/health")
        return out != nil
    }
    
    /// 从 PyPI 获取最新版本
    func fetchLatestVersion() async -> String? {
        return await runCmd("/usr/bin/python3", "-c", """
        import urllib.request, json
        try:
            req = urllib.request.Request('https://pypi.org/pypi/hindsight-api/json',
                headers={'User-Agent': 'HindsightManager/1.0'})
            resp = urllib.request.urlopen(req, timeout=10)
            data = json.loads(resp.read())
            print(data['info']['version'])
        except:
            pass
        """)
    }
}

// MARK: - Shell 工具

@discardableResult
func runCmd(_ args: String...) async -> String? {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: args[0])
            process.arguments = Array(args.dropFirst())
            
            let outPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = Pipe()
            
            do {
                try process.run()
                process.waitUntilExit()
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: output?.isEmpty == false ? output : nil)
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}

func runCmdOutput(_ args: String...) async -> (output: String?, exitCode: Int32) {
    return await withCheckedContinuation { continuation in
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: args[0])
            process.arguments = Array(args.dropFirst())
            
            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            
            do {
                try process.run()
                process.waitUntilExit()
                let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                continuation.resume(returning: (output, process.terminationStatus))
            } catch {
                continuation.resume(returning: (nil, -1))
            }
        }
    }
}
