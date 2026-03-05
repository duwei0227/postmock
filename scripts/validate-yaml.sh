#!/bin/bash

# YAML 语法验证脚本
# 用于验证项目中的 YAML 文件语法是否正确

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
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

# 检查 Python 是否安装
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 未安装，请先安装 Python 3"
        exit 1
    fi
}

# 检查 PyYAML 是否安装
check_pyyaml() {
    if ! python3 -c "import yaml" 2>/dev/null; then
        print_warning "PyYAML 未安装，正在尝试安装..."
        if command -v pip3 &> /dev/null; then
            pip3 install pyyaml --user
            print_success "PyYAML 安装成功"
        else
            print_error "pip3 未找到，请手动安装 PyYAML: pip3 install pyyaml"
            exit 1
        fi
    fi
}

# 验证单个 YAML 文件
validate_yaml_file() {
    local file=$1
    local result
    
    if [ ! -f "$file" ]; then
        print_error "文件不存在: $file"
        return 1
    fi
    
    # 使用 Python 验证 YAML 语法
    result=$(python3 -c "
import yaml
import sys

try:
    with open('$file', 'r', encoding='utf-8') as f:
        yaml.safe_load(f)
    print('valid')
    sys.exit(0)
except yaml.YAMLError as e:
    print(f'error: {e}')
    sys.exit(1)
except Exception as e:
    print(f'error: {e}')
    sys.exit(1)
" 2>&1)
    
    if [ $? -eq 0 ]; then
        print_success "$file - 语法正确"
        return 0
    else
        print_error "$file - 语法错误"
        echo "$result"
        return 1
    fi
}

# 验证 GitHub Actions 工作流特定规则
validate_github_workflow() {
    local file=$1
    local has_on=false
    local has_jobs=false
    
    # 检查是否有 'on' 字段
    if grep -q "^on:" "$file"; then
        has_on=true
    fi
    
    # 检查是否有 'jobs' 字段
    if grep -q "^jobs:" "$file"; then
        has_jobs=true
    fi
    
    if [ "$has_on" = false ]; then
        print_warning "$file - 缺少 'on' 字段（触发条件）"
    fi
    
    if [ "$has_jobs" = false ]; then
        print_error "$file - 缺少 'jobs' 字段"
        return 1
    fi
    
    # 提取 job 名称
    local jobs=$(grep -A 1 "^jobs:" "$file" | grep "^  [a-zA-Z]" | sed 's/://g' | sed 's/^  //g' | tr '\n' ', ' | sed 's/,$//')
    
    if [ -n "$jobs" ]; then
        print_info "$file - 包含的 jobs: [$jobs]"
    fi
    
    return 0
}

# 主函数
main() {
    echo "=========================================="
    echo "YAML 语法验证工具"
    echo "=========================================="
    echo ""
    
    # 检查依赖
    check_python
    check_pyyaml
    
    echo ""
    print_info "开始验证 YAML 文件..."
    echo ""
    
    local exit_code=0
    local total_files=0
    local valid_files=0
    local invalid_files=0
    
    # 如果提供了参数，验证指定的文件
    if [ $# -gt 0 ]; then
        for file in "$@"; do
            total_files=$((total_files + 1))
            if validate_yaml_file "$file"; then
                valid_files=$((valid_files + 1))
                
                # 如果是 GitHub Actions 工作流，进行额外验证
                if [[ "$file" == *".github/workflows/"* ]]; then
                    validate_github_workflow "$file"
                fi
            else
                invalid_files=$((invalid_files + 1))
                exit_code=1
            fi
            echo ""
        done
    else
        # 默认验证所有 YAML 文件
        
        # 验证 GitHub Actions 工作流
        if [ -d ".github/workflows" ]; then
            print_info "验证 GitHub Actions 工作流..."
            for file in .github/workflows/*.yml .github/workflows/*.yaml; do
                if [ -f "$file" ]; then
                    total_files=$((total_files + 1))
                    if validate_yaml_file "$file"; then
                        valid_files=$((valid_files + 1))
                        validate_github_workflow "$file"
                    else
                        invalid_files=$((invalid_files + 1))
                        exit_code=1
                    fi
                    echo ""
                fi
            done
        fi
        
        # 验证其他 YAML 配置文件
        print_info "验证其他 YAML 配置文件..."
        for file in *.yml *.yaml .*.yml .*.yaml; do
            if [ -f "$file" ]; then
                total_files=$((total_files + 1))
                if validate_yaml_file "$file"; then
                    valid_files=$((valid_files + 1))
                else
                    invalid_files=$((invalid_files + 1))
                    exit_code=1
                fi
                echo ""
            fi
        done
    fi
    
    # 打印总结
    echo "=========================================="
    echo "验证完成"
    echo "=========================================="
    echo "总文件数: $total_files"
    print_success "有效文件: $valid_files"
    if [ $invalid_files -gt 0 ]; then
        print_error "无效文件: $invalid_files"
    fi
    echo ""
    
    if [ $exit_code -eq 0 ]; then
        print_success "所有 YAML 文件语法正确！"
    else
        print_error "发现语法错误，请修复后重试"
    fi
    
    exit $exit_code
}

# 显示帮助信息
show_help() {
    cat << EOF
YAML 语法验证工具

用法:
    $0 [文件路径...]

选项:
    -h, --help      显示此帮助信息

示例:
    # 验证所有 YAML 文件
    $0

    # 验证指定文件
    $0 .github/workflows/release.yml

    # 验证多个文件
    $0 .github/workflows/release.yml .github/workflows/test.yml

    # 验证 release.yml 的快捷方式
    $0 .github/workflows/release.yml

依赖:
    - Python 3
    - PyYAML (会自动尝试安装)

EOF
}

# 解析命令行参数
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 运行主函数
main "$@"
