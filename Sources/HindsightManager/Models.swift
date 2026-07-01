import Foundation

// MARK: - 状态枚举

enum ServiceStatus: Equatable {
    case scanning
    case notInstalled
    case installed(version: String, latest: String?, running: Bool, uvInstalled: Bool)
    case error(String)
}

enum InstallStep: Equatable {
    case idle
    case installingUV
    case installingHindsight
    case configuring
    case starting
    case done
    case failed(String)
    
    var label: String {
        switch self {
        case .idle: return "就绪"
        case .installingUV: return "安装 uv..."
        case .installingHindsight: return "安装 hindsight-api..."
        case .configuring: return "配置服务..."
        case .starting: return "启动服务..."
        case .done: return "完成 ✅"
        case .failed(let msg): return "失败: \(msg)"
        }
    }
    
    var isWorking: Bool {
        switch self {
        case .idle, .failed, .done: return false
        default: return true
        }
    }
}

// MARK: - App 全局状态

@MainActor
class AppState: ObservableObject {
    @Published var status: ServiceStatus = .scanning
    @Published var installStep: InstallStep = .idle
    @Published var logs: [String] = []
    @Published var isWorking = false
    
    private let detector = HindsightDetector()
    private let installer = InstallService()
    
    // MARK: - 扫描
    
    func scan() async {
        status = .scanning
        addLog("🔍 正在检测系统环境...")
        
        let uvInstalled = await detector.checkUVInstalled()
        let hindsightInstalled = await detector.checkHindsightInstalled()
        let running = await detector.checkServiceRunning()
        let latest = await detector.fetchLatestVersion()
        
        if !uvInstalled {
            addLog("⚠️ 未检测到 uv")
        }
        if !hindsightInstalled {
            addLog("⚠️ Hindsight 未安装")
            status = .notInstalled
            return
        }
        
        let currentVer = await detector.getInstalledVersion()
        addLog("📦 Hindsight \(currentVer) 已安装")
        if let latest = latest, latest != currentVer {
            addLog("⬆️ PyPI 最新: \(latest)（可升级）")
        } else if let latest = latest {
            addLog("✅ 已是最新版本: \(latest)")
        } else {
            addLog("ℹ️ 无法获取 PyPI 最新版本")
        }
        
        if running {
            addLog("💚 服务运行中 (端口 9077)")
        } else {
            addLog("⏸️ 服务未运行")
        }
        
        status = .installed(version: currentVer, latest: latest, running: running, uvInstalled: uvInstalled)
    }
    
    // MARK: - 安装 / 升级
    
    func install(upgrade: Bool = false) async {
        isWorking = true
        installStep = .installingUV
        addLog("📥 开始\(upgrade ? "升级" : "安装")...")
        
        // 1. 安装 uv（如果没有）
        if !(await detector.checkUVInstalled()) {
            addLog("⏳ 安装 uv...")
            let result = await installer.installUV()
            switch result {
            case .success:
                addLog("✅ uv 安装成功")
            case .failure(let error):
                installStep = .failed(error.localizedDescription)
                addLog("❌ \(error.localizedDescription)")
                isWorking = false
                return
            }
        } else {
            addLog("✅ uv 已安装")
        }
        
        // 2. 安装/升级 hindsight-api
        installStep = .installingHindsight
        addLog("⏳ \(upgrade ? "升级" : "安装") hindsight-api...")
        let result = await installer.installHindsight(upgrade: upgrade)
        switch result {
        case .success:
            addLog("✅ hindsight-api \(upgrade ? "升级" : "安装")成功")
        case .failure(let error):
            installStep = .failed(error.localizedDescription)
            addLog("❌ \(error.localizedDescription)")
            isWorking = false
            return
        }
        
        // 3. 配置
        installStep = .configuring
        addLog("⏳ 配置 launchd 服务...")
        let configResult = await installer.configureLaunchd()
        if configResult {
            addLog("✅ launchd 配置完成")
        } else {
            addLog("⚠️ launchd 配置可能未完全生效")
        }
        
        // 4. 启动服务
        installStep = .starting
        addLog("⏳ 启动 Hindsight 服务...")
        let startResult = await installer.startService()
        if startResult {
            addLog("✅ 服务已启动")
        } else {
            addLog("⚠️ 服务启动可能稍慢，请稍后检查")
        }
        
        installStep = .done
        isWorking = false
        
        // 重新扫描
        await scan()
    }
    
    func startService() async {
        isWorking = true
        addLog("▶️ 启动服务...")
        let ok = await installer.startService()
        if ok {
            addLog("✅ 服务已启动")
        } else {
            addLog("❌ 启动失败")
        }
        isWorking = false
        await scan()
    }
    
    func stopService() async {
        isWorking = true
        addLog("⏹️ 停止服务...")
        let ok = await installer.stopService()
        if ok {
            addLog("✅ 服务已停止")
        } else {
            addLog("⚠️ 停止命令已执行")
        }
        isWorking = false
        await scan()
    }
    
    func uninstall() async {
        isWorking = true
        addLog("🗑️ 卸载 Hindsight...")
        let ok = await installer.uninstall()
        if ok {
            addLog("✅ 已卸载")
        } else {
            addLog("⚠️ 卸载过程中可能有部分残留")
        }
        isWorking = false
        await scan()
    }
    
    // MARK: - 日志
    
    func addLog(_ msg: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let ts = formatter.string(from: Date())
        logs.append("[\(ts)] \(msg)")
    }
}

// MARK: - 辅助

extension AppState {
    var installedVersion: String {
        if case .installed(let v, _, _, _) = status { return v }
        return ""
    }
}
