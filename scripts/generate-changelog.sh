#!/bin/bash
# 从 Git commits 生成 CHANGELOG

set -e

VERSION=${1:-""}
PREV_TAG=${2:-""}

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [previous-tag]"
    echo "Example: $0 0.2.0 v0.1.0"
    exit 1
fi

echo "Generating changelog for version $VERSION..."

# 如果没有指定上一个 tag，自动获取
if [ -z "$PREV_TAG" ]; then
    PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

# 获取 commits
if [ -z "$PREV_TAG" ]; then
    echo "First release, including all commits"
    COMMITS=$(git log --pretty=format:"%s" --no-merges)
else
    echo "Generating changelog from $PREV_TAG to HEAD"
    COMMITS=$(git log --pretty=format:"%s" --no-merges $PREV_TAG..HEAD)
fi

# 按类型分类
FEATURES=$(echo "$COMMITS" | grep -i "^feat" || echo "")
FIXES=$(echo "$COMMITS" | grep -i "^fix" || echo "")
DOCS=$(echo "$COMMITS" | grep -i "^docs" || echo "")
REFACTOR=$(echo "$COMMITS" | grep -i "^refactor" || echo "")
PERF=$(echo "$COMMITS" | grep -i "^perf" || echo "")
STYLE=$(echo "$COMMITS" | grep -i "^style" || echo "")
TEST=$(echo "$COMMITS" | grep -i "^test" || echo "")
BUILD=$(echo "$COMMITS" | grep -i "^build" || echo "")
CI=$(echo "$COMMITS" | grep -i "^ci" || echo "")
CHORE=$(echo "$COMMITS" | grep -i "^chore" || echo "")

# 格式化函数
format_commits() {
    echo "$1" | while read -r line; do
        if [ -n "$line" ]; then
            # 移除 type 前缀
            formatted=$(echo "$line" | sed -E 's/^[a-z]+(\([^)]+\))?[!]?: //')
            echo "- $formatted"
        fi
    done
}

# 生成 changelog
DATE=$(date +%Y-%m-%d)
CHANGELOG_ENTRY="## [$VERSION] - $DATE\n\n"

if [ -n "$FEATURES" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 新增\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$FEATURES")\n\n"
fi

if [ -n "$FIXES" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 修复\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$FIXES")\n\n"
fi

if [ -n "$PERF" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 性能优化\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$PERF")\n\n"
fi

if [ -n "$REFACTOR" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 重构\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$REFACTOR")\n\n"
fi

if [ -n "$DOCS" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 文档\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$DOCS")\n\n"
fi

if [ -n "$STYLE" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 样式\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$STYLE")\n\n"
fi

if [ -n "$TEST" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 测试\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$TEST")\n\n"
fi

if [ -n "$BUILD" ] || [ -n "$CI" ] || [ -n "$CHORE" ]; then
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}### 构建和维护\n"
    [ -n "$BUILD" ] && CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$BUILD")\n"
    [ -n "$CI" ] && CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$CI")\n"
    [ -n "$CHORE" ] && CHANGELOG_ENTRY="${CHANGELOG_ENTRY}$(format_commits "$CHORE")\n"
    CHANGELOG_ENTRY="${CHANGELOG_ENTRY}\n"
fi

# 输出到文件或标准输出
if [ -f "CHANGELOG.md" ]; then
    # 在 [Unreleased] 后插入新版本
    if grep -q "\[Unreleased\]" CHANGELOG.md; then
        # 创建临时文件
        awk -v entry="$CHANGELOG_ENTRY" '
            /## \[Unreleased\]/ {
                print
                getline
                print
                print entry
                next
            }
            {print}
        ' CHANGELOG.md > CHANGELOG.md.tmp
        mv CHANGELOG.md.tmp CHANGELOG.md
        echo "✓ Updated CHANGELOG.md"
    else
        # 如果没有 [Unreleased]，在文件开头插入
        echo -e "$CHANGELOG_ENTRY\n$(cat CHANGELOG.md)" > CHANGELOG.md
        echo "✓ Updated CHANGELOG.md"
    fi
else
    # 创建新的 CHANGELOG.md
    cat > CHANGELOG.md << EOF
# 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

$CHANGELOG_ENTRY
EOF
    echo "✓ Created CHANGELOG.md"
fi

echo ""
echo "Generated changelog entry:"
echo "=========================="
echo -e "$CHANGELOG_ENTRY"
echo "=========================="
echo ""
echo "Please review and edit CHANGELOG.md if needed."
