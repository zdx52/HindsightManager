#!/bin/bash
# ============================================================
#  HindsightManager 构建 + 打包脚本
#  构建 Swift 项目，生成 HindsightManager.app
# ============================================================

set -euo pipefail

cd "$(dirname "$0")"

BUNDLE_ID="com.zdx52.HindsightManager"
APP_NAME="HindsightManager"
BUILD_DIR=".build"
ARCH="${BUILD_DIR}/arm64-apple-macosx/release"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RESOURCES_DIR="${CONTENTS}/Resources"

echo "========================================"
echo "  🐶 构建 $APP_NAME"
echo "========================================"

# 1. 编译
echo ""
echo "📦 [1/3] swift build (release)..."
swift build -c release --disable-sandbox 2>&1 | tail -3

# 2. 创建 .app 包
echo ""
echo "📦 [2/3] 创建 .app 包..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# 查找编译产物
BINARY="${ARCH}/${APP_NAME}"
if [ ! -f "$BINARY" ]; then
    # 尝试找 debug build
    BINARY="${BUILD_DIR}/apple/Products/Debug/${APP_NAME}"
fi

if [ ! -f "$BINARY" ]; then
    echo "❌ 找不到编译产物 ${BINARY}"
    echo "   搜索中..."
    find "${BUILD_DIR}" -name "${APP_NAME}" -type f -perm +111 | head -5
    exit 1
fi

cp "$BINARY" "$MACOS_DIR/"
echo "   ✅ 二进制: $(du -h "$MACOS_DIR/${APP_NAME}" | cut -f1)"

# 复制 Info.plist
cp "SupportingFiles/Info.plist" "${CONTENTS}/"
echo "   ✅ Info.plist"

# 3. 签名
echo ""
echo "📦 [3/3] 签名 (ad-hoc)..."
codesign --force --sign - "$APP_BUNDLE" 2>&1 | tail -1

echo ""
echo "========================================"
echo "  ✅ 构建完成！"
echo "  位置: $(pwd)/${APP_BUNDLE}"
echo "  大小: $(du -h "$APP_BUNDLE" | cut -f1)"
echo "========================================"
echo ""
echo "📌 运行: open ${APP_BUNDLE}"
echo "   或移动到 Applications 使用"
