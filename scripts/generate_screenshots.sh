#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUTPUT_DIR="$REPO_ROOT/assets"
LANG_FILTER="all"
WITH_TELEMETRY=false
OPEN_PREVIEW=false

usage() {
    echo "用法: ./scripts/generate_screenshots.sh [选项]"
    echo "  --lang <all|en|zh>   指定生成语言（默认: all）"
    echo "  --output-dir <dir>   指定输出目录（默认: assets/）"
    echo "  --with-telemetry     同步重新生成 build-telemetry*.svg/.png 卡片"
    echo "  --open               生成完成后用 Preview 打开截图便于人工复核"
    echo "  -h, --help           显示帮助信息"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --lang)
            if [ $# -lt 2 ] || [ -z "$2" ]; then
                echo "❌ --lang 需要传入参数: all | en | zh"
                exit 1
            fi
            LANG_FILTER="$2"
            shift 2
            ;;
        --output-dir)
            if [ $# -lt 2 ] || [ -z "$2" ]; then
                echo "❌ --output-dir 需要传入目录路径"
                exit 1
            fi
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --with-telemetry)
            WITH_TELEMETRY=true
            shift
            ;;
        --open)
            OPEN_PREVIEW=true
            shift
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

if ! command -v swiftc >/dev/null 2>&1; then
    echo "❌ 未检测到 swiftc，请先安装 Xcode Command Line Tools"
    exit 1
fi

TMP_STAGE="$(mktemp -d /tmp/agyhub-screenshots.XXXXXX)"
cleanup() {
    rm -rf "$TMP_STAGE"
}
trap cleanup EXIT

APP_DIR="$TMP_STAGE/AgyhubDemoGen.app"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"
mkdir -p "$MACOS_DIR" "$RES_DIR" "$OUTPUT_DIR"

if [ -f "$REPO_ROOT/assets/header-cat.png" ]; then
    cp "$REPO_ROOT/assets/header-cat.png" "$RES_DIR/header-cat.png"
fi

cat > "$APP_DIR/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>AgyhubDemoGen</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.agyhub.demogen</string>
    <key>CFBundleName</key>
    <string>AgyhubDemoGen</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

echo "🔨 正在编译离屏截图生成器 (基于当前 Sources/*.swift 真实视图)..."
SDK_PATH="$(xcrun --show-sdk-path --sdk macosx)"
ARCH="$(uname -m)"

swiftc -DAGYHUB_TESTING \
    "$REPO_ROOT"/Sources/*.swift \
    "$REPO_ROOT/scripts/generate_demo_screenshots.swift" \
    -parse-as-library \
    -sdk "$SDK_PATH" \
    -target "${ARCH}-apple-macos13.0" \
    -framework SwiftUI -framework AppKit -framework Security -framework ServiceManagement \
    -o "$MACOS_DIR/AgyhubDemoGen"

echo "📸 正在生成 2x Retina 主页宣传图 -> $OUTPUT_DIR (lang=$LANG_FILTER)..."
"$MACOS_DIR/AgyhubDemoGen" --output-dir "$OUTPUT_DIR" --lang "$LANG_FILTER"

if [ "$WITH_TELEMETRY" = true ]; then
    echo "📊 正在同步更新开发遥测卡片..."
    python3 "$REPO_ROOT/scripts/generate_telemetry_card.py" --output-dir "$OUTPUT_DIR"
fi

if [ "$OPEN_PREVIEW" = true ]; then
    case "$LANG_FILTER" in
        en)
            open "$OUTPUT_DIR/screenshot-dashboard.png" "$OUTPUT_DIR/screenshot-detail.png" "$OUTPUT_DIR/screenshot-usage.png"
            ;;
        zh|zh-cn|zh_CN)
            open "$OUTPUT_DIR/screenshot-dashboard-zh.png" "$OUTPUT_DIR/screenshot-detail-zh.png" "$OUTPUT_DIR/screenshot-usage-zh.png"
            ;;
        *)
            open "$OUTPUT_DIR/screenshot-dashboard-zh.png" "$OUTPUT_DIR/screenshot-detail-zh.png" "$OUTPUT_DIR/screenshot-usage-zh.png" \
                 "$OUTPUT_DIR/screenshot-dashboard.png" "$OUTPUT_DIR/screenshot-detail.png" "$OUTPUT_DIR/screenshot-usage.png"
            ;;
    esac
fi

echo "✅ 完成！生成的截图可直接用于 README / 发布预览。"
