import SwiftUI

// MARK: - 主界面

struct ContentView: View {
    @EnvironmentObject var state: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            // 状态卡片（可滚动，但保证内容可见高度）
            ScrollView {
                VStack(spacing: 14) {
                    switch state.status {
                    case .scanning:
                        scanningCard
                    case .notInstalled:
                        notInstalledCard
                    case .installed(let v, let l, let r, let u):
                        installedCards(version: v, latest: l, running: r, uvInstalled: u)
                    case .error(let msg):
                        errorCard(msg)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
            }
            .frame(minHeight: 200)
            
            // 操作按钮（固定，不上不下）
            actionButtons
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            
            logView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .task { await state.scan() }
        .sheet(isPresented: $state.showSettings) {
            LLMConfigView()
                .environmentObject(state)
        }
        .alert("确认重新安装", isPresented: $state.showReinstallAlert) {
            Button("取消", role: .cancel) { }
            Button("确认重新安装") {
                Task { await state.install(upgrade: false) }
            }
        } message: {
            Text("当前已是 v\(state.installedVersion) 最新版。\n重新安装不会影响已有记忆数据。")
        }
    }
    
    // MARK: - 标题
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 26, height: 26)
            
            Text("Hindsight Manager")
                .font(.system(size: 17, weight: .semibold))
            
            Spacer()
            
            if state.isWorking {
                ProgressView()
                    .scaleEffect(1.0)
                    .frame(width: 22)
            }
            
            Button(action: { state.showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .help("设置")
            
            Button(action: { Task { await state.scan() } }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .help("刷新")
        }
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - 卡片
    
    private var scanningCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.9)
            VStack(alignment: .leading, spacing: 2) {
                Text("正在检测系统环境...")
                    .font(.system(size: 15))
                Text("检查 uv / hindsight-api / 服务状态")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .cardStyle()
    }
    
    private var notInstalledCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Hindsight 未安装")
                        .font(.system(size: 16, weight: .medium))
                    Text("点击下方按钮全新安装 hindsight-api")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }
    
    private func installedCards(version: String, latest: String?, running: Bool, uvInstalled: Bool) -> some View {
        VStack(spacing: 14) {
            // 版本状态行
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(running ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text("Hindsight")
                        .font(.system(size: 17, weight: .semibold))
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(state.llmConfigured ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(state.llmConfigured ? "LLM 已配置" : "LLM 未配置")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .clipShape(Capsule())
            }
            
            // 状态卡片网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatusCell(
                    icon: "cube.fill",
                    color: .blue,
                    label: "已安装版本",
                    value: "v\(version)",
                    valueColor: statusColor(version: version, latest: latest)
                )
                
                StatusCell(
                    icon: "arrow.up.circle.fill",
                    color: latest != nil && latest != version ? .orange : .green,
                    label: "PyPI 最新",
                    value: latest.map { "v\($0)" } ?? "查询失败",
                    valueColor: latest != nil && latest != version ? .orange : .green
                )
                
                StatusCell(
                    icon: "antenna.radiowaves.left.and.right",
                    color: running ? .green : .red,
                    label: "服务状态",
                    value: running ? "运行中" : "未运行",
                    valueColor: running ? .green : .red
                )
                
                StatusCell(
                    icon: "wrench.and.screwdriver.fill",
                    color: uvInstalled ? .green : .red,
                    label: "uv 工具链",
                    value: uvInstalled ? "已安装" : "未安装",
                    valueColor: uvInstalled ? .green : .red
                )
            }
        }
        .cardStyle()
    }
    
    private func errorCard(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
            Text(msg)
                .font(.system(size: 14))
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.2), lineWidth: 1))
    }
    
    private func statusColor(version: String, latest: String?) -> Color {
        guard let latest = latest, latest != version else { return .green }
        return .orange
    }
    
    // MARK: - 操作按钮
    
    @ViewBuilder
    private var actionButtons: some View {
        switch state.status {
        case .notInstalled:
            HStack(spacing: 10) {
                AccentButton(
                    title: "全新安装",
                    icon: "arrow.down.circle.fill",
                    color: .blue,
                    disabled: state.isWorking
                ) {
                    Task { await state.install(upgrade: false) }
                }
                
                Spacer()
                
                Button("关闭") { NSApp.keyWindow?.close() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
            }
            
        case .installed(_, let latest, let running, _):
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    if let latest = latest, latest != state.installedVersion {
                        AccentButton(
                            title: "升级到 v\(latest)",
                            icon: "arrow.up.circle.fill",
                            color: .orange,
                            disabled: state.isWorking
                        ) {
                            Task { await state.install(upgrade: true) }
                        }
                    }
                    
                    AccentButton(
                        title: "全新安装",
                        icon: "arrow.triangle.2.circlepath",
                        color: .gray,
                        disabled: state.isWorking,
                        bordered: false
                    ) {
                        state.reinstallTapped()
                    }
                    
                    Spacer()
                    
                    if running {
                        AccentButton(
                            title: "停止服务",
                            icon: "stop.circle.fill",
                            color: .red,
                            disabled: state.isWorking,
                            bordered: false
                        ) {
                            Task { await state.stopService() }
                        }
                    } else {
                        AccentButton(
                            title: "启动服务",
                            icon: "play.circle.fill",
                            color: .green,
                            disabled: state.isWorking
                        ) {
                            Task { await state.startService() }
                        }
                    }
                }
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - 日志
    
    private var logView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 12))
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                Text("操作日志")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                Spacer()
                if !state.logs.isEmpty {
                    Button("清空") { state.logs.removeAll() }
                        .font(.system(size: 12))
                        .buttonStyle(.plain)
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            Divider()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        ForEach(Array(state.logs.enumerated()), id: \.offset) { _, log in
                            Text(log)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .id("bottom")
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 80, idealHeight: 120, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor).opacity(0.3))
                .onChange(of: state.logs.count) { _, _ in
                    withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                }
            }
        }
    }
}

// MARK: - 视觉毛玻璃背景

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - 卡片样式

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.45))
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - 状态格子

struct StatusCell: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(valueColor)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - 强调按钮

struct AccentButton: View {
    let title: String
    let icon: String
    let color: Color
    let disabled: Bool
    var bordered: Bool = true
    let action: () -> Void
    
    var body: some View {
        if bordered {
            Button(action: action) {
                Label(title, systemImage: icon)
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .tint(color)
            .disabled(disabled)
            .controlSize(.large)
        } else {
            Button(action: action) {
                Label(title, systemImage: icon)
                    .font(.system(size: 14, weight: .medium))
            }
            .buttonStyle(BorderedButtonStyle())
            .tint(color)
            .disabled(disabled)
            .controlSize(.large)
        }
    }
}
