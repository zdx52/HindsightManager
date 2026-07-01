# 🐶 Hindsight Manager

> macOS 原生 App — Hindsight 记忆服务安装 / 升级 / 状态监控管家  
> Native macOS app for installing, upgrading, and monitoring the Hindsight memory service

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-14+-lightgrey?logo=apple)](https://developer.apple.com/macos)
[![Platform](https://img.shields.io/badge/Platform-Apple%20Silicon%20%7C%20Intel-brightgreen)](#)
[![License](https://img.shields.io/badge/License-MIT-blue)](#)

---

## 📋 功能 / Features

| 功能 | Feature | 状态 |
|------|---------|:----:|
| 🔍 检测 uv / hindsight-api / 服务 / PyPI 版本 | Environment detection | ✅ |
| 📥 一键安装最新版 | One-click install | ✅ |
| ⬆️ 新版本检测 + 一键升级 | Version check & upgrade | ✅ |
| ▶️ / ⏹️ 启动 / 停止服务 | Start / stop service | ✅ |
| 🗑️ 卸载 | Uninstall | ✅ |
| 🧠 LLM API Key 安全配置（Keychain） | Secure LLM API key config | ✅ |
| 📜 实时操作日志 | Real-time operation log | ✅ |

---

## 🖼️ 界面预览 / Preview

```
┌─────────────────────────────────────────┐
│  🐶 Hindsight Manager     [设置] [刷新] │
├─────────────────────────────────────────┤
│  📦 Hindsight              v0.8.3       │
│  🔄 PyPI 最新              v0.8.3 ✅    │
│  💚 服务状态               ● 运行中     │
│  ⚙️ uv 工具链              ✅           │
│  🧠 LLM 配置               ● 已配置     │
├─────────────────────────────────────────┤
│  [⬆️ 升级到 v0.9.0] [↻ 重新安装] [⏹️] │
├─────────────────────────────────────────┤
│  [14:32:15] 🔍 正在检测系统环境...      │
│  [14:32:16] 📦 Hindsight v0.8.3 已安装  │
│  [14:32:16] ✅ 已是最新版本: v0.8.3     │
│  [14:32:16] 💚 服务运行中 (端口 9077)   │
└─────────────────────────────────────────┘
```

---

## 🚀 快速开始 / Quick Start

```bash
git clone git@github.com:zdx52/HindsightManager.git
cd HindsightManager
./build-app.sh
open HindsightManager.app
```

---

## ⚙️ LLM 配置 / LLM Configuration

Hindsight 使用 LLM 处理记忆（提取事实、合成回答），需配置 API Key。

1. 打开 App → 点击 **「设置」**
2. 填写 Provider / API Key / Base URL / 模型
3. API Key 安全存储在 **macOS Keychain**
4. 保存后自动注入 launchd 启动环境

| 参数 | 说明 | 示例（Agnes AI） |
|------|------|------------------|
| Provider | 服务商 | `openai` |
| API Key | 你的密钥 | `sk-ag-xxx` |
| Base URL | API 端点 | `https://apihub.agnes-ai.com/v1` |
| Model | 模型名 | `deepseek-v4-flash` |

---

## 🏗️ 技术栈 / Tech Stack

| 技术 | 版本 |
|------|:----:|
| Swift | 6.0 |
| SwiftUI | macOS 14+ |
| SPM | Swift Package Manager |
| 外部依赖 | **零**（无第三方库） |
| 编译方式 | `swift build` |
| 打包脚本 | `build-app.sh` → `.app` |

---

## 📁 项目结构 / Project Structure

```
HindsightManager/
├── Sources/
│   └── HindsightManager/
│       ├── App.swift               # 入口 + Settings 场景
│       ├── ContentView.swift       # 主界面 UI
│       ├── Models.swift            # 状态管理、LLM 配置
│       ├── HindsightService.swift  # 环境检测
│       ├── InstallService.swift    # 安装 / 启动 / 停止
│       ├── KeychainHelper.swift    # Keychain 安全存储
│       └── LLMConfigView.swift     # LLM 设置面板
├── SupportingFiles/
│   └── Info.plist
├── Package.swift
├── build-app.sh
└── README.md
```

---

## 📦 发行 / Release

版本号统一维护：Info.plist → .app → README → GitHub

```
v1.0.0 — 🎉 初始版本
```

---

## 📄 许可 / License

MIT License. Copyright © 2026 [zdx52](https://github.com/zdx52).
