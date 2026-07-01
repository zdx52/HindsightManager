import SwiftUI

// MARK: - 主界面

struct ContentView: View {
    @EnvironmentObject var state: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            Divider()
            
            // 状态卡片
            statusCard
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            // 操作按钮
            actionButtons
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            
            Divider()
            
            // 操作日志
            logView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .task {
            await state.scan()
        }
    }
    
    // MARK: - 标题
    
    private var headerView: some View {
        HStack {
            Text("🐶 Hindsight Manager")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            if state.isWorking {
                ProgressView()
                    .scaleEffect(0.7)
                    .padding(.trailing, 4)
            }
            Button("刷新") {
                Task { await state.scan() }
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - 状态卡片
    
    @ViewBuilder
    private var statusCard: some View {
        switch state.status {
        case .scanning:
            scanningView
        case .notInstalled:
            notInstalledView
        case .installed(let version, let latest, let running, let uvInstalled):
            installedView(version: version, latest: latest, running: running, uvInstalled: uvInstalled)
        case .error(let msg):
            errorView(msg)
        }
    }
    
    private var scanningView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text("正在检测系统环境...")
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private var notInstalledView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .foregroundColor(.orange)
                Text("Hindsight 未安装")
                    .font(.system(size: 13, weight: .medium))
            }
            Text("点击下方「安装最新版」自动安装 hindsight-api")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func installedView(version: String, latest: String?, running: Bool, uvInstalled: Bool) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("📦 Hindsight")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text("v\(version)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(statusColor(version: version, latest: latest))
            }
            
            HStack {
                Text("🔄 PyPI 最新")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                if let latest = latest {
                    Text("v\(latest)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(latest != version ? .orange : .green)
                } else {
                    Text("查询失败")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("💚 服务状态")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(running ? Color.green : Color.red)
                        .frame(width: 6, height: 6)
                    Text(running ? "运行中" : "未运行")
                        .font(.system(size: 11))
                }
            }
            
            HStack {
                Text("⚙️ uv 工具链")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text(uvInstalled ? "✅" : "❌")
                    .font(.system(size: 11))
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func errorView(_ msg: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
            Text(msg)
                .font(.system(size: 12))
                .foregroundColor(.red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
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
            HStack {
                Button(action: { Task { await state.install(upgrade: false) } }) {
                    Label("安装最新版", systemImage: "arrow.down.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.isWorking)
                .tint(.blue)
                
                Spacer()
                
                Button("关闭") {
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(.bordered)
            }
            
        case .installed(_, let latest, let running, _):
            HStack(spacing: 8) {
                if let latest = latest, latest != state.installedVersion {
                    Button(action: { Task { await state.install(upgrade: true) } }) {
                        Label("升级到 v\(latest)", systemImage: "arrow.up.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.isWorking)
                    .tint(.orange)
                }
                
                Button(action: { Task { await state.install(upgrade: false) } }) {
                    Label("重新安装", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .disabled(state.isWorking)
                
                Spacer()
                
                if running {
                    Button(action: { Task { await state.stopService() } }) {
                        Label("停止服务", systemImage: "stop.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(state.isWorking)
                    .tint(.red)
                } else {
                    Button(action: { Task { await state.startService() } }) {
                        Label("启动服务", systemImage: "play.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.isWorking)
                    .tint(.green)
                }
            }
            
        default:
            EmptyView()
        }
    }
    
    // MARK: - 日志
    
    private var logView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(state.logs.enumerated()), id: \.offset) { _, log in
                        Text(log)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .id("bottom")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.textBackgroundColor))
            .onChange(of: state.logs.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }
    }
}
