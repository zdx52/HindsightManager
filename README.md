# HindsightManager

macOS 原生 App — 管理 Hindsight 记忆服务的安装、升级、状态监控。

## 功能

- 🔍 检测系统环境（uv / hindsight-api / 服务状态 / PyPI 版本）
- 📥 一键安装最新版 hindsight-api
- ⬆️ 检测到新版本时提示一键升级
- ▶️ / ⏹️ 启动/停止 Hindsight 服务
- 🗑️ 卸载
- 📜 实时操作日志

## 构建

```bash
git clone git@github.com:zdx52/HindsightManager.git
cd HindsightManager
./build-app.sh
open HindsightManager.app
```

## 技术栈

- Swift 6 + SwiftUI (macOS 14+)
- SPM (Swift Package Manager)
- 无外部依赖
- `swift build` 编译，脚本打包为 .app
