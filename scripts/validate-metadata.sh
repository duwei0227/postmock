#!/bin/bash
# 验证所有平台的元数据配置

set -e

echo "🔍 Validating package metadata..."
echo ""

ERRORS=0
WARNINGS=0

# 颜色定义
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# 检查文件是否存在
check_file() {
    if [ ! -f "$1" ]; then
        echo -e "${RED}✗ Missing file: $1${NC}"
        ((ERRORS++))
        return 1
    else
        echo -e "${GREEN}✓ Found: $1${NC}"
        return 0
    fi
}

# 检查 JSON 字段
check_json_field() {
    local file=$1
    local field=$2
    local value=$(node -p "try { require('./$file').$field } catch(e) { '' }")
    
    if [ -z "$value" ] || [ "$value" = "undefined" ]; then
        echo -e "${YELLOW}⚠ Missing field in $file: $field${NC}"
        ((WARNINGS++))
        return 1
    else
        echo -e "${GREEN}✓ $file.$field: $value${NC}"
        return 0
    fi
}

echo "📦 Checking configuration files..."
check_file "package.json"
check_file "src-tauri/Cargo.toml"
check_file "src-tauri/tauri.conf.json"
check_file "LICENSE"
check_file "CHANGELOG.md"
check_file "README.md"
echo ""

echo "🔧 Checking Tauri configuration..."
check_json_field "src-tauri/tauri.conf.json" "productName"
check_json_field "src-tauri/tauri.conf.json" "version"
check_json_field "src-tauri/tauri.conf.json" "identifier"
check_json_field "src-tauri/tauri.conf.json" "bundle.shortDescription"
check_json_field "src-tauri/tauri.conf.json" "bundle.longDescription"
check_json_field "src-tauri/tauri.conf.json" "bundle.homepage"
check_json_field "src-tauri/tauri.conf.json" "bundle.publisher"
echo ""

echo "🐧 Checking Linux configuration..."
check_file "src-tauri/postmock.desktop"
check_file "flatpak/cn.probiecoder.postmock.desktop"
check_file "flatpak/cn.probiecoder.postmock.metainfo.xml"
check_file "cn.probiecoder.postmock.yml"
echo ""

echo "📸 Checking screenshots..."
if [ ! -d "screenshots" ]; then
    echo -e "${YELLOW}⚠ Screenshots directory not found${NC}"
    ((WARNINGS++))
else
    if [ ! -f "screenshots/main.png" ]; then
        echo -e "${YELLOW}⚠ Missing screenshot: screenshots/main.png${NC}"
        ((WARNINGS++))
    else
        echo -e "${GREEN}✓ Found: screenshots/main.png${NC}"
    fi
fi
echo ""

echo "🔍 Validating Flatpak metadata..."
if command -v appstream-util &> /dev/null; then
    if appstream-util validate flatpak/cn.probiecoder.postmock.metainfo.xml; then
        echo -e "${GREEN}✓ Flatpak metadata is valid${NC}"
    else
        echo -e "${RED}✗ Flatpak metadata validation failed${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${YELLOW}⚠ appstream-util not found, skipping validation${NC}"
    echo "  Install with: sudo apt-get install appstream-util"
    ((WARNINGS++))
fi
echo ""

echo "🔍 Validating desktop files..."
if command -v desktop-file-validate &> /dev/null; then
    for desktop_file in src-tauri/postmock.desktop flatpak/cn.probiecoder.postmock.desktop; do
        if [ -f "$desktop_file" ]; then
            if desktop-file-validate "$desktop_file"; then
                echo -e "${GREEN}✓ $desktop_file is valid${NC}"
            else
                echo -e "${RED}✗ $desktop_file validation failed${NC}"
                ((ERRORS++))
            fi
        fi
    done
else
    echo -e "${YELLOW}⚠ desktop-file-validate not found, skipping validation${NC}"
    echo "  Install with: sudo apt-get install desktop-file-utils"
    ((WARNINGS++))
fi
echo ""

echo "📊 Summary:"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Validation failed with $ERRORS error(s)${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Validation passed with $WARNINGS warning(s)${NC}"
    exit 0
else
    echo -e "${GREEN}✅ All metadata validation passed!${NC}"
    exit 0
fi
