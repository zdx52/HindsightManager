import Foundation

// MARK: - 环境检测

final class HindsightDetector: Sendable {
    
    /// 检查 uv 是否安装（在常见位置查找）
    func checkUVInstalled() async -> Bool {
        // 尝试 PATH 和常见安装位置
        let checks = [
            "/bin/bash -c 'command -v uv'",
            "ls ~/.local/bin/uv 2>/dev/null",
            "ls /usr/local/bin/uv 2>/dev/null",
            "ls /opt/homebrew/bin/uv 2>/dev/null",
        ]
        for check in checks {
            if await runCmd("/bin/bash", "-c", check) != nil {
                return true
            }
        }
        return false
    }
    
    /// 检查 hindsight-api 是否安装（通过 uv tool、pip 或服务状态）
    func checkHindsightInstalled() async -> Bool {
        // 1. 通过 uv tool list（尝试不同 uv 路径）
        for uv in ["uv", "~/.local/bin/uv", "/usr/local/bin/uv", "/opt/homebrew/bin/uv"] {
            if await runCmd("/bin/bash", "-c", "\(uv) tool list 2>/dev/null | grep hindsight-api") != nil {
                return true
            }
        }
        
        // 2. 检查 pip 安装
        if await runCmd("/bin/bash", "-c",
            "python3 -c 'import hindsight_api' 2>/dev/null") != nil {
            return true
        }
        if await runCmd("/bin/bash", "-c",
            "source ~/.venv/bin/activate 2>/dev/null; pip show hindsight-api 2>/dev/null | grep -q Version") != nil {
            return true
        }
        
        // 3. 如果服务正在运行，说明已安装
        if await checkServiceRunning() {
            return true
        }
        
        return false
    }
    
    /// 获取已安装的 hindsight-api 版本
    func getInstalledVersion() async -> String {
        if let out = await runCmd("/bin/bash", "-c",
            "uv tool run hindsight-api --version 2>/dev/null | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' || uv tool show hindsight-api 2>/dev/null | grep Version | awk '{print $2}'"),
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
    
    /// 检查 PostgreSQL 是否运行（检查两个实例）
    func checkPostgresRunning() async -> Bool {
        let ports = ["5432", "5433"]
        for port in ports {
            if await runCmd("/bin/bash", "-c", "/usr/sbin/lsof -i :\(port) 2>/dev/null | grep LISTEN") != nil {
                return true
            }
        }
        return false
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
