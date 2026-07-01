import Foundation

// MARK: - Keychain 常量

let LLMKeychainService = "com.aiusagemonitor"
let LLMKeychainAccount = "hindsight-api-key"

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
    @Published var showReinstallAlert = false
    @Published var showSettings = false
    @Published var availableModels: [String] = []
    @Published var modelsLoading = false
    
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
    
    /// 点击「重新安装」：始终弹确认，显示当前版本
    func reinstallTapped() {
        showReinstallAlert = true
    }
    
    // MARK: - 日志
    
    func addLog(_ msg: String) {
        let ts = Self.logFormatter.string(from: Date())
        let entry = "[\(ts)] \(msg)"
        
        // 去重：查找相同消息内容，覆盖时间戳
        let msgPrefix = "] \(msg)"
        if let index = logs.lastIndex(where: { $0.hasSuffix(msgPrefix) }) {
            logs[index] = entry
        } else {
            logs.append(entry)
        }
    }
    
    private static let logFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()
}

// MARK: - 辅助

extension AppState {
    var installedVersion: String {
        if case .installed(let v, _, _, _) = status { return v }
        return ""
    }
    
    /// LLM 是否已配置（API Key 已保存到 Keychain）
    var llmConfigured: Bool {
        KeychainHelper.read(service: LLMKeychainService, account: LLMKeychainAccount) != nil
    }
    
    /// 重新生成 launchd plist 和启动脚本
    func applyConfig() async {
        let ok = await installer.applyLLMConfig()
        if ok {
            addLog("✅ 启动脚本和 launchd 配置已更新")
        } else {
            addLog("⚠️ 配置更新失败")
        }
    }
    
    /// 从 OpenCode API 拉取可用模型列表
    func fetchModels() async {
        guard let apiKey = KeychainHelper.read(service: LLMKeychainService, account: LLMKeychainAccount),
              !apiKey.isEmpty else {
            // 没有 API Key 时使用默认列表
            availableModels = Self.defaultModels
            return
        }
        
        let baseURL = UserDefaults.standard.string(forKey: "llm_base_url") ?? "https://opencode.ai/zen/go/v1"
        let urlStr = baseURL.hasSuffix("/") ? "\(baseURL)models" : "\(baseURL)/models"
        guard let url = URL(string: urlStr) else { return }
        
        modelsLoading = true
        defer { modelsLoading = false }
        
        var req = URLRequest(url: url)
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 10
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["data"] as? [[String: Any]] else {
                availableModels = Self.defaultModels
                return
            }
            let ids = models.compactMap { $0["id"] as? String }.sorted()
            availableModels = ids.isEmpty ? Self.defaultModels : ids
        } catch {
            availableModels = Self.defaultModels
        }
    }
    
    private static let defaultModels = [
        "deepseek-v4-flash", "deepseek-v4-pro",
        "glm-5.2", "glm-5.1", "glm-5",
        "kimi-k2.7-code", "kimi-k2.6", "kimi-k2.5",
        "minimax-m3", "minimax-m2.7", "minimax-m2.5",
        "mimo-v2.5", "mimo-v2.5-pro", "mimo-v2-pro", "mimo-v2-omni",
        "qwen3.7-max", "qwen3.7-plus", "qwen3.6-plus", "qwen3.5-plus",
        "hy3-preview",
    ]
}
