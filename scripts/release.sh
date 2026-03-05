#!/bin/bash

# 版本发布脚本
# 自动化版本发布流程

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 显示帮助信息
show_help() {
    cat << EOF
版本发布脚本

用法:
    $0 <版本号>

示例:
    $0 0.1.1
    $0 0.2.0

说明:
    此脚本会自动执行以下操作：
    1. 验证版本号格式
    2. 更新 package.json、tauri.conf.json 和 Cargo.toml 中的版本号
    3. 验证 YAML 语法
    4. 提交更改
    5. 创建并推送 git tag
    6. 触发 GitHub Actions 构建

前置条件:
    - Git 工作目录干净（无未提交的更改）
    - 已配置 GitHub Secrets（TAURI_SIGNING_PRIVATE_KEY 和 TAURI_SIGNING_PRIVATE_KEY_PASSWORD）
    - 本地存在签名密钥文件（postmock.key 和 postmock.key.pub）

EOF
}

# 验证版本号格式
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "版本号格式不正确，应该是 x.y.z 格式（如 0.1.1）"
        exit 1
    fi
}

# 检查 Git 工作目录状态
check_git_status() {
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Git 工作目录有未提交的更改"
        git status --short
        echo ""
        read -p "是否继续？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "已取消"
            exit 0
        fi
    fi
}

# 获取当前版本号
get_current_version() {
    grep '"version"' package.json | head -1 | sed 's/.*"version": "\(.*\)".*/\1/'
}

# 更新版本号
update_version() {
    local new_version=$1
    local current_version=$(get_current_version)
    
    print_info "当前版本: $current_version"
    print_info "新版本: $new_version"
    echo ""
    
    # 更新 package.json
    sed -i.bak "s/\"version\": \"$current_version\"/\"version\": \"$new_version\"/" package.json
    rm package.json.bak
    print_success "已更新 package.json"
    
    # 更新 src-tauri/tauri.conf.json
    sed -i.bak "s/\"version\": \"$current_version\"/\"version\": \"$new_version\"/" src-tauri/tauri.conf.json
    rm src-tauri/tauri.conf.json.bak
    print_success "已更新 src-tauri/tauri.conf.json"
    
    # 更新 src-tauri/Cargo.toml
    sed -i.bak "s/version = \"$current_version\"/version = \"$new_version\"/" src-tauri/Cargo.toml
    rm src-tauri/Cargo.toml.bak
    print_success "已更新 src-tauri/Cargo.toml"
    
    echo ""
}

# 验证 YAML 语法
validate_yaml() {
    print_info "验证 YAML 语法..."
    if [ -f "scripts/validate-yaml.sh" ]; then
        ./scripts/validate-yaml.sh .github/workflows/release.yml
    else
        print_warning "未找到 validate-yaml.sh 脚本，跳过 YAML 验证"
    fi
    echo ""
}

# 检查签名密钥
check_signing_keys() {
    print_info "检查签名密钥..."
    
    if [ ! -f "postmock.key" ]; then
        print_error "未找到私钥文件: postmock.key"
        exit 1
    fi
    
    if [ ! -f "postmock.key.pub" ]; then
        print_error "未找到公钥文件: postmock.key.pub"
        exit 1
    fi
    
    print_success "签名密钥文件存在"
    echo ""
}

# 检查 CHANGELOG
check_changelog() {
    local version=$1
    
    print_info "检查 CHANGELOG.md..."
    
    if [ ! -f "CHANGELOG.md" ]; then
        print_warning "未找到 CHANGELOG.md 文件"
        return 0
    fi
    
    # 检查是否包含新版本的条目
    if grep -q "## \[$version\]" CHANGELOG.md; then
        print_success "CHANGELOG.md 包含版本 $version 的条目"
    else
        print_warning "CHANGELOG.md 中未找到版本 $version 的条目"
        echo ""
        print_info "GitHub Actions 将从 Git commits 自动生成变更日志"
        print_info "建议手动更新 CHANGELOG.md 以提供更详细的说明"
        echo ""
        read -p "是否现在编辑 CHANGELOG.md？(y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-nano} CHANGELOG.md
            print_info "请在编辑器中添加版本 $version 的变更内容"
            read -p "编辑完成后按 Enter 继续..."
        fi
    fi
    echo ""
}

# 提交更改
commit_changes() {
    local version=$1
    
    print_info "提交版本更新..."
    git add package.json src-tauri/tauri.conf.json src-tauri/Cargo.toml
    
    # 如果 CHANGELOG.md 有更改，也一起提交
    if git diff --cached --quiet CHANGELOG.md 2>/dev/null; then
        : # CHANGELOG 没有更改
    else
        git add CHANGELOG.md
        print_success "已添加 CHANGELOG.md 到提交"
    fi
    
    git commit -m "chore: bump version to $version"
    print_success "已提交更改"
    echo ""
}

# 创建并推送 tag
create_and_push_tag() {
    local version=$1
    local tag="v$version"
    
    print_info "创建 git tag: $tag"
    
    # 检查 tag 是否已存在
    if git rev-parse "$tag" >/dev/null 2>&1; then
        print_warning "Tag $tag 已存在"
        read -p "是否删除并重新创建？(y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git tag -d "$tag"
            git push origin ":refs/tags/$tag" 2>/dev/null || true
            print_success "已删除旧 tag"
        else
            print_info "已取消"
            exit 0
        fi
    fi
    
    git tag "$tag"
    print_success "已创建 tag: $tag"
    echo ""
    
    print_info "推送更改到远程仓库..."
    git push
    git push origin "$tag"
    print_success "已推送到远程仓库"
    echo ""
}

# 显示后续步骤
show_next_steps() {
    local version=$1
    
    echo "=========================================="
    echo "版本发布流程已启动！"
    echo "=========================================="
    echo ""
    print_success "版本 $version 的构建已触发"
    echo ""
    print_info "后续步骤："
    echo ""
    echo "1. 访问 GitHub Actions 监控构建进度："
    echo "   https://github.com/duwei0227/postmock/actions"
    echo ""
    echo "2. 构建完成后，访问 Release 页面："
    echo "   https://github.com/duwei0227/postmock/releases/tag/v$version"
    echo ""
    echo "3. 验证以下内容："
    echo "   - ✅ 所有平台的安装包已生成"
    echo "   - ✅ 签名文件（*.sig）已生成"
    echo "   - ✅ latest.json 清单已生成"
    echo "   - ✅ Release 说明正确显示"
    echo ""
    echo "4. 测试自动更新功能："
    echo "   - 安装旧版本应用"
    echo "   - 点击 Help → Check for Updates"
    echo "   - 验证能检测到新版本并成功更新"
    echo ""
    print_warning "如果构建失败，请查看 GitHub Actions 日志排查问题"
    echo ""
}

# 主函数
main() {
    echo "=========================================="
    echo "PostMock 版本发布脚本"
    echo "=========================================="
    echo ""
    
    # 检查参数
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_help
        exit 0
    fi
    
    local new_version=$1
    
    # 验证版本号格式
    validate_version "$new_version"
    
    # 检查 Git 状态
    check_git_status
    
    # 检查签名密钥
    check_signing_keys
    
    # 检查 CHANGELOG
    check_changelog "$new_version"
    
    # 更新版本号
    update_version "$new_version"
    
    # 验证 YAML 语法
    validate_yaml
    
    # 确认发布
    print_warning "即将发布版本 $new_version"
    read -p "确认继续？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "已取消"
        # 恢复更改
        git checkout package.json src-tauri/tauri.conf.json src-tauri/Cargo.toml
        exit 0
    fi
    
    # 提交更改
    commit_changes "$new_version"
    
    # 创建并推送 tag
    create_and_push_tag "$new_version"
    
    # 显示后续步骤
    show_next_steps "$new_version"
}

# 运行主函数
main "$@"
