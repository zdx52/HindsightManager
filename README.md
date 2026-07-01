# 🐶 Hindsight Manager

> Native macOS app for installing, upgrading, and monitoring the Hindsight memory service

[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift)](https://swift.org)
[![macOS](https://img.shields.io/badge/macOS-14+-lightgrey?logo=apple)](https://developer.apple.com/macos)
[![Platform](https://img.shields.io/badge/Platform-Apple%20Silicon%20%7C%20Intel-brightgreen)](#)
[![License](https://img.shields.io/badge/License-MIT-blue)](#)

[**中文版说明**](README_CN.md)

---

## Features

| Feature | Status |
|---------|:------:|
| 🔍 Detect uv / hindsight-api / service / PyPI version | ✅ |
| 📥 One-click install latest version | ✅ |
| ⬆️ Version check & one-click upgrade | ✅ |
| ▶️ / ⏹️ Start / stop service via launchd | ✅ |
| 🗑️ Uninstall | ✅ |
| 🧠 Secure LLM API key config (macOS Keychain) | ✅ |
| 📜 Real-time operation log | ✅ |

---

## Preview

```
┌─────────────────────────────────────────────┐
│  🐶 Hindsight Manager       [Settings] [↻] │
├─────────────────────────────────────────────┤
│  📦 Hindsight                    v0.8.3     │
│  🔄 PyPI Latest                 v0.8.3 ✅  │
│  💚 Service Status              ● Running   │
│  ⚙️ uv Toolchain                ✅         │
│  🧠 LLM Config                  ● Configured│
├─────────────────────────────────────────────┤
│  [⬆️ Upgrade to v0.9.0] [↻ Reinstall] [⏹️] │
├─────────────────────────────────────────────┤
│  [14:32:15] 🔍 Scanning environment...      │
│  [14:32:16] 📦 Hindsight v0.8.3 installed   │
│  [14:32:16] ✅ Latest version: v0.8.3       │
│  [14:32:16] 💚 Service running (port 9077)  │
└─────────────────────────────────────────────┘
```

---

## Quick Start

```bash
git clone git@github.com:zdx52/HindsightManager.git
cd HindsightManager
./build-app.sh
open HindsightManager.app
```

---

## LLM Configuration

Hindsight requires an LLM API key for memory processing (fact extraction, response synthesis).

1. Launch the app → Click **Settings**
2. Enter Provider / API Key / Base URL / Model
3. API key is stored securely in **macOS Keychain**
4. Saved config is automatically injected into the launchd environment

| Parameter | Description | Example (Agnes AI) |
|-----------|-------------|-------------------|
| Provider | API provider | `openai` |
| API Key | Your API key | `sk-ag-xxx` |
| Base URL | API endpoint | `https://apihub.agnes-ai.com/v1` |
| Model | Model name | `deepseek-v4-flash` |

---

## Tech Stack

| Technology | Version |
|------------|:-------:|
| Swift | 6.0 |
| SwiftUI | macOS 14+ |
| SPM | Swift Package Manager |
| Dependencies | **Zero** (no third-party libs) |
| Build | `swift build` |
| Packaging | `build-app.sh` → `.app` |

---

## Project Structure

```
HindsightManager/
├── Sources/
│   └── HindsightManager/
│       ├── App.swift               # Entry point + Settings scene
│       ├── ContentView.swift       # Main UI
│       ├── Models.swift            # State management, LLM config
│       ├── HindsightService.swift  # Environment detection
│       ├── InstallService.swift    # Install / start / stop
│       ├── KeychainHelper.swift    # Keychain secure storage
│       └── LLMConfigView.swift     # LLM settings panel
├── SupportingFiles/
│   └── Info.plist
├── Package.swift
├── build-app.sh
└── README.md
```

---

## Versioning

Version is kept consistent across 5 locations: source plist, project bundle, Applications, README, GitHub.

```
v1.0.0 — 🎉 Initial release
```

---

## License

MIT License. Copyright © 2026 [zdx52](https://github.com/zdx52).
