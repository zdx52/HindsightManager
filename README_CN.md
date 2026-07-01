<p align="center">
  <img src="SupportingFiles/AppIcon.png" width="128" height="128" alt="Hindsight Manager 图标">
</p>

# Hindsight Manager

> macOS 原生 App — Hindsight 记忆服务安装、升级、状态监控管家

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-14+-lightgrey?logo=apple)](https://developer.apple.com/macos)
[![Platform](https://img.shields.io/badge/Platform-Apple%20Silicon%20%7C%20Intel-brightgreen)](#)
[![License](https://img.shields.io/badge/License-MIT-blue)](#)

[English Version](README.md)

---

## 功能

| 功能 | 状态 |
|------|:----:|
| 🔍 检测 uv / hindsight-api / 服务状态 / PyPI 版本 | ✅ |
| 📥 一键安装最新版 | ✅ |
| ⬆️ 新版本检测 + 一键升级 | ✅ |
| ▶️ / ⏹️ 启动 / 停止服务 | ✅ |
| 🗑️ 卸载 | ✅ |
| 🧠 LLM API Key 安全配置（macOS Keychain） | ✅ |
| 📜 实时操作日志 | ✅ |

---

## 预览

```
┌──────────────────────────────────────────┐
│  🐶 Hindsight Manager      [设置] [刷新] │
├──────────────────────────────────────────┤
│  📦 Hindsight                   v0.8.3   │
│  🔄 PyPI 最新                  v0.8.3 ✅│
│  💚 服务状态                   ● 运行中  │
│  ⚙️ uv 工具链                  ✅       │
│  🧠 LLM 配置                   ● 已配置  │
├──────────────────────────────────────────┤
│  [⬆️ 升级到 v0.9.0] [↻ 重装]   [⏹️]    │
├──────────────────────────────────────────┤
│  [14:32:15] 🔍 正在检测系统环境...       │
│  [14:32:16] 📦 Hindsight v0.8.3 已安装   │
│  [14:32:16] ✅ 已是最新版本: v0.8.3      │
│  [14:32:16] 💚 服务运行中 (端口 9077)    │
└──────────────────────────────────────────┘
```

---

## 快速开始

```bash
git clone git@github.com:zdx52/HindsightManager.git
cd HindsightManager
./build-app.sh
open HindsightManager.app
```

---

## LLM 配置

Hindsight 需要 LLM API Key 来记忆处理（提取事实、合成回答）。

1. 打开 App → 点击 **「设置」**
2. 填写 Provider / API Key / Base URL / 模型
3. API Key 安全存储在 **macOS Keychain**
4. 保存后自动注入 launchd 启动环境

| 参数 | 说明 | 示例（OpenCode Go） |
|------|------|---------------------|
| Provider | 服务商 | `opencode-go` |
| API Key | 你的密钥 | `sk-xxx` |
| Base URL | API 端点 | `https://opencode.ai/zen/go/v1` |
| Model | 模型名 | `deepseek-v4-flash`、`deepseek-v4-pro`、`glm-5.2`、`kimi-k2.7-code`、`mimo-v2.5` 等 |

---

## 技术栈

| 技术 | 版本 |
|------|:----:|
| Swift | 6.0 |
| SwiftUI | macOS 14+ |
| SPM | Swift Package Manager |
| 外部依赖 | **零**（无第三方库） |
| 编译方式 | `swift build` |
| 打包脚本 | `build-app.sh` → `.app` |

---

## 项目结构

```
HindsightManager/
├── Sources/
│   └── HindsightManager/
│       ├── App.swift               # 入口 + 设置场景
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

## 版本管理

版本号在五个位置统一维护：源码 plist → .app 包 → Applications → README → GitHub

```
v1.1.0 — LLM 配置 + 界面重构
```

---

## 许可

MIT License. Copyright © 2026 [zdx52](https://github.com/zdx52).
