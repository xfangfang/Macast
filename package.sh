#!/bin/bash

# Macast macOS平台Swift重写打包发行脚本
# 用于在纯命令行环境下构建、打包和发布Macast应用

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 变量定义
APP_NAME="Macast"
BUNDLE_ID="com.example.Macast"
VERSION="1.0.0"
SHORT_VERSION="1.0"
MIN_MACOS_VERSION="10.15"
SIGNING_IDENTITY=""

# 目录定义
ROOT_DIR="$(pwd)"
BUILD_DIR=".build/release"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
FRAMEWORKS_DIR="${CONTENTS_DIR}/Frameworks"
OUTPUT_DIR="dist"

# 显示帮助信息
show_help() {
    echo "Macast打包发行脚本"
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -v, --version    设置应用版本号（默认: ${VERSION}）"
    echo "  -s, --short      设置应用短版本号（默认: ${SHORT_VERSION}）"
    echo "  -i, --identity   设置签名身份（默认: 未签名）"
    echo "  -c, --clean      只清理构建目录"
    echo ""
    echo "示例:"
    echo "  $0 --identity \"Your Name (Team ID)\" --version 1.1.0 --short 1.1"
    exit 0
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -v|--version)
            VERSION="$2"
            shift
            shift
            ;;
        -s|--short)
            SHORT_VERSION="$2"
            shift
            shift
            ;;
        -i|--identity)
            SIGNING_IDENTITY="$2"
            shift
            shift
            ;;
        -c|--clean)
            CLEAN_ONLY=true
            shift
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            show_help
            ;;
    esac
done

# 显示配置信息
show_config() {
    echo -e "${YELLOW}=== Macast打包配置 ===${NC}"
    echo -e "应用名称: ${APP_NAME}"
    echo -e "Bundle ID: ${BUNDLE_ID}"
    echo -e "版本号: ${VERSION}"
    echo -e "短版本号: ${SHORT_VERSION}"
    echo -e "最低macOS版本: ${MIN_MACOS_VERSION}"
    if [ -n "${SIGNING_IDENTITY}" ]; then
        echo -e "签名身份: ${SIGNING_IDENTITY}"
    else
        echo -e "签名身份: 未签名"
    fi
    echo -e "${YELLOW}========================${NC}\n"
}

# 清理构建目录
clean_build() {
    echo -e "${YELLOW}清理构建目录...${NC}"
    rm -rf "${BUILD_DIR}" "${APP_DIR}" "${OUTPUT_DIR}"
    echo -e "${GREEN}清理完成${NC}\n"
}

# 构建release版本
build_release() {
    echo -e "${YELLOW}构建release版本...${NC}"
    swift build -c release
    if [ $? -ne 0 ]; then
        echo -e "${RED}构建失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}构建完成${NC}\n"
}

# 创建应用目录结构
create_app_structure() {
    echo -e "${YELLOW}创建应用目录结构...${NC}"
    mkdir -p "${MACOS_DIR}"
    mkdir -p "${RESOURCES_DIR}"
    mkdir -p "${FRAMEWORKS_DIR}"
    mkdir -p "${OUTPUT_DIR}"
    echo -e "${GREEN}目录结构创建完成${NC}\n"
}

# 复制文件和创建Info.plist
copy_files() {
    echo -e "${YELLOW}复制文件...${NC}"
    
    # 复制可执行文件
    cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/"
    
    # 创建Info.plist文件
    cat > "${CONTENTS_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${SHORT_VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS_VERSION}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSUIElement</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>icon.icns</string>
</dict>
</plist>
EOF
    
    # 复制资源文件（如果有）
    if [ -d "Resources" ]; then
        cp -R "Resources/"* "${RESOURCES_DIR}/"
    fi
    
    # 复制依赖框架（如果有）
    # echo "复制依赖框架..."
    # cp -R "${BUILD_DIR}/Dependencies"/* "${FRAMEWORKS_DIR}/"
    
    echo -e "${GREEN}文件复制完成${NC}\n"
}

# 签名应用
sign_app() {
    if [ -z "${SIGNING_IDENTITY}" ]; then
        echo -e "${YELLOW}跳过签名（未提供签名身份）${NC}\n"
        return
    fi
    
    echo -e "${YELLOW}签名应用...${NC}"
    codesign --deep --force --verify --verbose --sign "${SIGNING_IDENTITY}" "${APP_DIR}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}签名失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}签名完成${NC}\n"
}

# 创建DMG安装包
create_dmg() {
    echo -e "${YELLOW}创建DMG安装包...${NC}"
    DMG_NAME="${APP_NAME}-${VERSION}.dmg"
    hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_DIR}" -ov -format UDZO "${OUTPUT_DIR}/${DMG_NAME}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}DMG创建失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}DMG创建完成: ${OUTPUT_DIR}/${DMG_NAME}${NC}\n"
}

# 验证应用
verify_app() {
    echo -e "${YELLOW}验证应用...${NC}"
    
    # 检查应用是否存在
    if [ ! -d "${APP_DIR}" ]; then
        echo -e "${RED}应用不存在${NC}"
        exit 1
    fi
    
    # 检查可执行文件是否存在
    if [ ! -f "${MACOS_DIR}/${APP_NAME}" ]; then
        echo -e "${RED}可执行文件不存在${NC}"
        exit 1
    fi
    
    # 检查Info.plist是否存在
    if [ ! -f "${CONTENTS_DIR}/Info.plist" ]; then
        echo -e "${RED}Info.plist不存在${NC}"
        exit 1
    fi
    
    # 验证签名（如果已签名）
    if [ -n "${SIGNING_IDENTITY}" ]; then
        codesign --verify --verbose "${APP_DIR}"
        if [ $? -ne 0 ]; then
            echo -e "${RED}签名验证失败${NC}"
            exit 1
        fi
    fi
    
    # 验证应用是否可以运行
    spctl --assess --verbose "${APP_DIR}"
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}注意: 应用可能无法在Gatekeeper下运行（未签名或签名身份不受信任）${NC}"
    fi
    
    echo -e "${GREEN}应用验证完成${NC}\n"
}

# 显示构建信息
show_build_info() {
    echo -e "${YELLOW}=== 构建信息 ===${NC}"
    echo -e "应用名称: ${APP_NAME}"
    echo -e "版本号: ${VERSION}"
    echo -e "构建路径: ${BUILD_DIR}"
    echo -e "应用路径: ${APP_DIR}"
    echo -e "输出目录: ${OUTPUT_DIR}"
    
    if [ -f "${OUTPUT_DIR}/${APP_NAME}-${VERSION}.dmg" ]; then
        echo -e "DMG文件: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}.dmg"
        echo -e "文件大小: $(du -h "${OUTPUT_DIR}/${APP_NAME}-${VERSION}.dmg" | cut -f1)"
    fi
    
    echo -e "${YELLOW}=================${NC}\n"
}

# 主函数
main() {
    show_config
    
    # 只清理构建目录
    if [ "${CLEAN_ONLY}" = true ]; then
        clean_build
        exit 0
    fi
    
    # 执行构建和打包流程
    clean_build
    build_release
    create_app_structure
    copy_files
    sign_app
    verify_app
    create_dmg
    show_build_info
    
    echo -e "${GREEN}🎉 Macast打包发行完成！${NC}"
    echo -e "应用已打包为DMG文件，可以在${OUTPUT_DIR}目录中找到。"
    echo -e "\n提示: 如果应用无法运行，请检查签名身份或在系统偏好设置中允许来自'任何来源'的应用。"
}

# 执行主函数
main
