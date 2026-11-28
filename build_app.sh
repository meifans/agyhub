#!/usr/bin/env bash

set -euo pipefail

SYNC_TOOLS=false
UNIVERSAL=false
BUILD_DMG=false
APP_VERSION="1.1.0"

usage() {
    echo "用法: ./build_app.sh [选项]"
    echo "  --universal        编译 Apple Silicon + Intel 双架构 Universal Binary"
    echo "  --dmg              打包 .dmg 与 .zip 发布安装包到 dist/ 目录（含 SHA256 校验和）"
    echo "  --version <ver>    指定版本号（默认: 1.1.0，如 1.2.0）"
    echo "  --sync-tools       构建完成后同步覆盖 ~/.gemini/config/tools/agy-monitor.py"
    echo "  -h, --help         显示帮助信息"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --sync-tools)
            SYNC_TOOLS=true
            shift
            ;;
        --universal)
            UNIVERSAL=true
            shift
            ;;
        --dmg)
            BUILD_DMG=true
            shift
            ;;
        --version)
            if [ $# -lt 2 ] || [ -z "$2" ]; then
                echo "❌ --version 需要传入版本号参数"
                exit 1
            fi
            APP_VERSION="${2#v}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "❌ 未知参数: $1"
            usage
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="Agyhub"
BUNDLE_ID="com.antigravity.agyhub"
BUILD_DIR="$SCRIPT_DIR/build"
DIST_DIR="$SCRIPT_DIR/dist"
APP_BUNDLE="$SCRIPT_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "========================================================"
echo " ⚡ 开始构建 ${APP_NAME}.app v${APP_VERSION} (macOS 原生状态栏应用)"
echo "========================================================"

if ! command -v swiftc >/dev/null 2>&1; then
    echo "❌ 未检测到 swiftc 编译器，请先执行: xcode-select --install"
    exit 1
fi

SDK_PATH="$(xcrun --show-sdk-path --sdk macosx)"

if [ -f "$SCRIPT_DIR/scripts/check_i18n.py" ] && command -v python3 >/dev/null 2>&1; then
    echo "🌐 正在执行确定性 I18N 护栏检查 (scripts/check_i18n.py)..."
    python3 "$SCRIPT_DIR/scripts/check_i18n.py"
fi

rm -rf "$APP_BUNDLE" "$SCRIPT_DIR/AGY-Hub.app" "$BUILD_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$BUILD_DIR"

cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

if [ -f "$SCRIPT_DIR/assets/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/assets/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
    echo "✅ 已内置应用图标 -> Contents/Resources/AppIcon.icns"
fi

if [ -f "$SCRIPT_DIR/assets/header-cat.png" ]; then
    cp "$SCRIPT_DIR/assets/header-cat.png" "$RESOURCES_DIR/header-cat.png"
    echo "✅ 已内置透明标题栏小猫 -> Contents/Resources/header-cat.png"
fi

if [ -f "$SCRIPT_DIR/agy-monitor.py" ]; then
    cp "$SCRIPT_DIR/agy-monitor.py" "$RESOURCES_DIR/agy-monitor.py"
    chmod +x "$RESOURCES_DIR/agy-monitor.py"
    echo "✅ 已内置 agy-monitor.py (--json 引擎) -> Contents/Resources/agy-monitor.py"
fi

if [ -f "$SCRIPT_DIR/agy-top" ]; then
    cp "$SCRIPT_DIR/agy-top" "$RESOURCES_DIR/agy-top"
    chmod +x "$RESOURCES_DIR/agy-top"
    echo "✅ 已内置 agy-top 终端启动器 -> Contents/Resources/agy-top"
fi

compile_arch() {
    local target_arch="$1"
    local out_bin="$2"
    local swift_sources=("$SCRIPT_DIR"/Sources/*.swift)
    if [ ${#swift_sources[@]} -eq 0 ] || [ ! -f "${swift_sources[0]}" ]; then
        echo "❌ 未找到 Swift 源码: $SCRIPT_DIR/Sources/*.swift"
        exit 1
    fi
    echo "🔨 正在编译 Sources/*.swift (目标架构: ${target_arch}, 优化级别: -O)..."
    swiftc "${swift_sources[@]}" \
        -O \
        -parse-as-library \
        -sdk "$SDK_PATH" \
        -target "${target_arch}-apple-macos13.0" \
        -framework SwiftUI \
        -framework AppKit \
        -framework Security \
        -framework ServiceManagement \
        -o "$out_bin"
}

if [ "$UNIVERSAL" = true ]; then
    ARCH_LABEL="universal"
    compile_arch "arm64" "$BUILD_DIR/${APP_NAME}-arm64"
    compile_arch "x86_64" "$BUILD_DIR/${APP_NAME}-x86_64"
    lipo -create \
        "$BUILD_DIR/${APP_NAME}-arm64" \
        "$BUILD_DIR/${APP_NAME}-x86_64" \
        -output "$MACOS_DIR/${APP_NAME}"
    echo "✅ 已合并 Universal Binary (arm64 + x86_64)"
else
    ARCH_LABEL="$(uname -m)"
    compile_arch "$ARCH_LABEL" "$MACOS_DIR/${APP_NAME}"
fi

chmod +x "$MACOS_DIR/${APP_NAME}"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true
    echo "✅ 已完成本地 Ad-hoc 签名 (codesign)"
fi

if [ "$BUILD_DMG" = true ]; then
    mkdir -p "$DIST_DIR"
    ARTIFACT_BASE="${APP_NAME}-v${APP_VERSION}-${ARCH_LABEL}"
    DMG_PATH="$DIST_DIR/${ARTIFACT_BASE}.dmg"
    ZIP_PATH="$DIST_DIR/${ARTIFACT_BASE}.zip"
    STAGE_DIR="$BUILD_DIR/dmg-stage"

    rm -rf "$STAGE_DIR" "$DMG_PATH" "$ZIP_PATH"
    mkdir -p "$STAGE_DIR"
    cp -R "$APP_BUNDLE" "$STAGE_DIR/"
    ln -s /Applications "$STAGE_DIR/Applications"

    echo "📦 正在打包 DMG 安装镜像 -> $DMG_PATH"
    hdiutil create \
        -volname "${APP_NAME} ${APP_VERSION}" \
        -srcfolder "$STAGE_DIR" \
        -ov \
        -format UDZO \
        "$DMG_PATH" >/dev/null

    echo "📦 正在打包 ZIP 压缩包 -> $ZIP_PATH"
    ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$ZIP_PATH"

    (cd "$DIST_DIR" && shasum -a 256 "${ARTIFACT_BASE}.dmg" "${ARTIFACT_BASE}.zip" > "SHA256SUMS.txt")
    echo "✅ 发布包已生成到 dist/："
    echo "   - $DMG_PATH"
    echo "   - $ZIP_PATH"
    echo "   - $DIST_DIR/SHA256SUMS.txt"
fi

USER_TOOL_DIR="$HOME/.gemini/config/tools"
if [ "$SYNC_TOOLS" = true ]; then
    if [ -d "$USER_TOOL_DIR" ] && [ -f "$SCRIPT_DIR/agy-monitor.py" ]; then
        cp "$SCRIPT_DIR/agy-monitor.py" "$USER_TOOL_DIR/agy-monitor.py"
        chmod +x "$USER_TOOL_DIR/agy-monitor.py"
        echo "✅ 已同步升级本地 $USER_TOOL_DIR/agy-monitor.py"
    else
        echo "⚠️  跳过工具同步: 未找到目标目录 $USER_TOOL_DIR 或源脚本 agy-monitor.py"
    fi
else
    echo "ℹ️  默认未覆盖 $USER_TOOL_DIR/agy-monitor.py（如需同步请传入 --sync-tools）"
fi

mkdir -p "$HOME/.agy-profiles" "$HOME/.antigravity/extensions"

echo ""
echo "🎉 构建成功！产物路径: $APP_BUNDLE"
echo "👉 直接启动: open \"$APP_BUNDLE\""
echo "👉 安装到应用程序: cp -R \"$APP_BUNDLE\" /Applications/ && open /Applications/${APP_NAME}.app"
