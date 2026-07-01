import SwiftUI

// MARK: - LLM 配置设置面板

struct LLMConfigView: View {
    @EnvironmentObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = ""
    @State private var baseURL: String = "https://opencode.ai/zen/go/v1"
    @State private var model: String = "deepseek-v4-flash"
    @State private var provider: String = "opencode-go"
    @State private var showKey = false
    @State private var saveMessage: String?
    @State private var isSaved = false
    
    private let keychainService = LLMKeychainService
    private let keychainAccount = LLMKeychainAccount
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                Text("LLM 配置")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                if state.llmConfigured {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("已配置")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.08))
                    .clipShape(Capsule())
                }
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("关闭")
            }
            .padding(20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Provider
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Provider")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("OpenCode")
                                .font(.system(size: 12, weight: .medium))
                            Text("(opencode-go)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // API Key
                    VStack(alignment: .leading, spacing: 6) {
                        Text("API Key")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        HStack {
                            if showKey {
                                TextField("输入 API Key", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                            } else {
                                SecureField("输入 API Key", text: $apiKey)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, design: .monospaced))
                            }
                            Button(action: { showKey.toggle() }) {
                                Image(systemName: showKey ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Base URL
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Base URL")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        TextField("https://opencode.ai/zen/go/v1", text: $baseURL)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12, design: .monospaced))
                            .padding(10)
                            .background(Color(NSColor.controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Model
                    VStack(alignment: .leading, spacing: 6) {
                        Text("模型")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        if state.modelsLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("正在加载模型列表...")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                        } else {
                            Picker("", selection: $model) {
                                ForEach(state.availableModels, id: \.self) { id in
                                    Text(displayName(for: id)).tag(id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                        }
                    }
                    
                    Divider()
                    
                    // 操作按钮
                    HStack {
                        Button(action: saveConfig) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                Text("保存配置")
                            }
                            .font(.system(size: 12))
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        .controlSize(.large)
                        
                        if let msg = saveMessage {
                            Text(msg)
                                .font(.system(size: 11))
                                .foregroundColor(isSaved ? .green : .red)
                                .transition(.opacity)
                        }
                        
                        Spacer()
                        
                        if state.llmConfigured {
                            Button(action: clearConfig) {
                                HStack(spacing: 4) {
                                    Image(systemName: "trash")
                                    Text("清除")
                                }
                                .font(.system(size: 12))
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            .controlSize(.large)
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 460)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadConfig()
            Task { await state.fetchModels() }
        }
    }
    
    // MARK: - 显示名转换
    
    private func displayName(for id: String) -> String {
        // deepseek-v4-flash → DeepSeek V4 Flash
        id.split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
    
    // MARK: - 配置加载
    
    private func loadConfig() {
        apiKey = KeychainHelper.read(service: keychainService, account: keychainAccount) ?? ""
        baseURL = UserDefaults.standard.string(forKey: "llm_base_url") ?? "https://opencode.ai/zen/go/v1"
        model = UserDefaults.standard.string(forKey: "llm_model") ?? "deepseek-v4-flash"
        provider = UserDefaults.standard.string(forKey: "llm_provider") ?? "opencode-go"
    }
    
    // MARK: - 保存配置
    
    private func saveConfig() {
        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else {
            saveMessage = "API Key 不能为空"
            isSaved = false
            return
        }
        
        KeychainHelper.save(service: keychainService, account: keychainAccount, value: key)
        UserDefaults.standard.set(baseURL, forKey: "llm_base_url")
        UserDefaults.standard.set(model, forKey: "llm_model")
        UserDefaults.standard.set(provider, forKey: "llm_provider")
        
        withAnimation {
            saveMessage = "✅ 配置已保存"
            isSaved = true
        }
        
        Task {
            await state.applyConfig()
            await state.scan()
        }
    }
    
    // MARK: - 清除配置
    
    private func clearConfig() {
        KeychainHelper.delete(service: keychainService, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: "llm_base_url")
        UserDefaults.standard.removeObject(forKey: "llm_model")
        UserDefaults.standard.removeObject(forKey: "llm_provider")
        
        apiKey = ""
        baseURL = "https://opencode.ai/zen/go/v1"
        model = "deepseek-v4-flash"
        provider = "opencode-go"
        
        withAnimation {
            saveMessage = "🗑️ 配置已清除"
            isSaved = false
        }
        
        Task {
            await state.applyConfig()
            await state.scan()
        }
    }
}
