#!/bin/bash
# 智能 Changelog 生成器
# 结合 Git commits 和代码变更分析生成详细的 changelog

set -e

VERSION=${1:-""}
PREV_TAG=${2:-""}

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version> [previous-tag]"
    echo "Example: $0 0.2.0 v0.1.0"
    exit 1
fi

echo "🔍 Analyzing changes for version $VERSION..."
echo ""

# 获取上一个 tag
if [ -z "$PREV_TAG" ]; then
    PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

if [ -z "$PREV_TAG" ]; then
    echo "📦 First release detected"
    RANGE="HEAD"
else
    echo "📊 Comparing $PREV_TAG..HEAD"
    RANGE="$PREV_TAG..HEAD"
fi

# 1. 分析 Git commits
echo ""
echo "📝 Analyzing Git commits..."
COMMITS=$(git log --pretty=format:"%s|||%b" --no-merges $RANGE)

# 2. 分析代码变更
echo "🔬 Analyzing code changes..."

# 统计变更的文件
CHANGED_FILES=$(git diff --name-only $RANGE 2>/dev/null || git ls-files)
TOTAL_FILES=$(echo "$CHANGED_FILES" | wc -l)

# 按类型分类文件
UI_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(vue|css|scss)$" | wc -l)
API_FILES=$(echo "$CHANGED_FILES" | grep -E "src/(services|api|utils)" | wc -l)
CONFIG_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(json|toml|yml|yaml)$" | wc -l)
DOC_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(md|txt)$" | wc -l)
TEST_FILES=$(echo "$CHANGED_FILES" | grep -E "test|spec" | wc -l)

# 统计代码行数变化
STATS=$(git diff --shortstat $RANGE 2>/dev/null || echo "")
if [ -n "$STATS" ]; then
    INSERTIONS=$(echo "$STATS" | grep -oE "[0-9]+ insertion" | grep -oE "[0-9]+" || echo "0")
    DELETIONS=$(echo "$STATS" | grep -oE "[0-9]+ deletion" | grep -oE "[0-9]+" || echo "0")
else
    INSERTIONS="0"
    DELETIONS="0"
fi

echo "  📁 Changed files: $TOTAL_FILES"
echo "  🎨 UI files: $UI_FILES"
echo "  🔧 API/Service files: $API_FILES"
echo "  📄 Config files: $CONFIG_FILES"
echo "  📚 Documentation: $DOC_FILES"
echo "  🧪 Test files: $TEST_FILES"
echo "  ➕ Insertions: $INSERTIONS"
echo "  ➖ Deletions: $DELETIONS"

# 3. 智能分类 commits
echo ""
echo "🏷️  Categorizing changes..."

# 按 Conventional Commits 分类
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

# 检测 Breaking Changes
BREAKING=$(echo "$COMMITS" | grep -i "BREAKING CHANGE" || echo "")

# 4. 生成智能描述
generate_smart_description() {
    local category=$1
    local commits=$2
    
    if [ -z "$commits" ]; then
        return
    fi
    
    echo "$commits" | while IFS='|||' read -r subject body; do
        if [ -n "$subject" ]; then
            # 移除 type 前缀
            clean_subject=$(echo "$subject" | sed -E 's/^[a-z]+(\([^)]+\))?[!]?: //')
            
            # 提取 scope
            scope=$(echo "$subject" | grep -oE "\([^)]+\)" | tr -d '()' || echo "")
            
            # 生成描述
            if [ -n "$scope" ]; then
                echo "- **$scope**: $clean_subject"
            else
                echo "- $clean_subject"
            fi
            
            # 如果有 body，添加详细说明
            if [ -n "$body" ]; then
                echo "$body" | sed 's/^/  /' | head -3
            fi
        fi
    done
}

# 5. 生成 Changelog
DATE=$(date +%Y-%m-%d)
CHANGELOG=""

# 添加统计信息
CHANGELOG="## [$VERSION] - $DATE\n\n"
CHANGELOG="${CHANGELOG}**变更统计**: $TOTAL_FILES 个文件，+$INSERTIONS/-$DELETIONS 行代码\n\n"

# Breaking Changes（如果有）
if [ -n "$BREAKING" ]; then
    CHANGELOG="${CHANGELOG}### ⚠️ 破坏性变更\n\n"
    CHANGELOG="${CHANGELOG}$(generate_smart_description "breaking" "$BREAKING")\n\n"
fi

# 新增功能
if [ -n "$FEATURES" ]; then
    CHANGELOG="${CHANGELOG}### ✨ 新增功能\n\n"
    CHANGELOG="${CHANGELOG}$(generate_smart_description "feat" "$FEATURES")\n\n"
fi

# 问题修复
if [ -n "$FIXES" ]; then
    CHANGELOG="${CHANGELOG}### 🐛 问题修复\n\n"
    CHANGELOG="${CHANGELOG}$(generate_smart_description "fix" "$FIXES")\n\n"
fi

# 性能优化
if [ -n "$PERF" ]; then
    CHANGELOG="${CHANGELOG}### ⚡ 性能优化\n\n"
    CHANGELOG="${CHANGELOG}$(generate_smart_description "perf" "$PERF")\n\n"
fi

# 重构
if [ -n "$REFACTOR" ]; then
    CHANGELOG="${CHANGELOG}### ♻️ 代码重构\n\n"
    CHANGELOG="${CHANGELOG}$(generate_smart_description "refactor" "$REFACTOR")\n\n"
fi

# 文档
if [ -n "$DOCS" ] || [ "$DOC_FILES" -gt 0 ]; then
    CHANGELOG="${CHANGELOG}### 📚 文档更新\n\n"
    if [ -n "$DOCS" ]; then
        CHANGELOG="${CHANGELOG}$(generate_smart_description "docs" "$DOCS")\n"
    fi
    if [ "$DOC_FILES" -gt 0 ]; then
        CHANGELOG="${CHANGELOG}- 更新了 $DOC_FILES 个文档文件\n"
    fi
    CHANGELOG="${CHANGELOG}\n"
fi

# 样式和 UI
if [ -n "$STYLE" ] || [ "$UI_FILES" -gt 0 ]; then
    CHANGELOG="${CHANGELOG}### 💄 样式和 UI\n\n"
    if [ -n "$STYLE" ]; then
        CHANGELOG="${CHANGELOG}$(generate_smart_description "style" "$STYLE")\n"
    fi
    if [ "$UI_FILES" -gt 0 ]; then
        CHANGELOG="${CHANGELOG}- 更新了 $UI_FILES 个 UI 组件\n"
    fi
    CHANGELOG="${CHANGELOG}\n"
fi

# 测试
if [ -n "$TEST" ] || [ "$TEST_FILES" -gt 0 ]; then
    CHANGELOG="${CHANGELOG}### 🧪 测试\n\n"
    if [ -n "$TEST" ]; then
        CHANGELOG="${CHANGELOG}$(generate_smart_description "test" "$TEST")\n"
    fi
    if [ "$TEST_FILES" -gt 0 ]; then
        CHANGELOG="${CHANGELOG}- 更新了 $TEST_FILES 个测试文件\n"
    fi
    CHANGELOG="${CHANGELOG}\n"
fi

# 构建和维护
if [ -n "$BUILD" ] || [ -n "$CI" ] || [ -n "$CHORE" ] || [ "$CONFIG_FILES" -gt 0 ]; then
    CHANGELOG="${CHANGELOG}### 🔧 构建和维护\n\n"
    [ -n "$BUILD" ] && CHANGELOG="${CHANGELOG}$(generate_smart_description "build" "$BUILD")\n"
    [ -n "$CI" ] && CHANGELOG="${CHANGELOG}$(generate_smart_description "ci" "$CI")\n"
    [ -n "$CHORE" ] && CHANGELOG="${CHANGELOG}$(generate_smart_description "chore" "$CHORE")\n"
    [ "$CONFIG_FILES" -gt 0 ] && CHANGELOG="${CHANGELOG}- 更新了 $CONFIG_FILES 个配置文件\n"
    CHANGELOG="${CHANGELOG}\n"
fi

# 6. 更新 CHANGELOG.md
echo ""
echo "📝 Updating CHANGELOG.md..."

if [ -f "CHANGELOG.md" ]; then
    # 在 [Unreleased] 后插入
    if grep -q "\[Unreleased\]" CHANGELOG.md; then
        awk -v entry="$CHANGELOG" '
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
    else
        echo -e "$CHANGELOG\n$(cat CHANGELOG.md)" > CHANGELOG.md
    fi
else
    cat > CHANGELOG.md << EOF
# 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

$CHANGELOG
EOF
fi

echo "✓ CHANGELOG.md updated"

# 7. 更新 Flatpak metainfo.xml
echo ""
echo "📦 Updating Flatpak metainfo..."

METAINFO_FILE="flatpak/cn.probiecoder.postmock.metainfo.xml"
if [ -f "$METAINFO_FILE" ]; then
    # 生成简化的描述（用于 metainfo）
    SIMPLE_DESC="Version $VERSION"
    
    # 提取主要变更
    if [ -n "$FEATURES" ]; then
        FEAT_COUNT=$(echo "$FEATURES" | wc -l)
        SIMPLE_DESC="$SIMPLE_DESC with $FEAT_COUNT new features"
    fi
    if [ -n "$FIXES" ]; then
        FIX_COUNT=$(echo "$FIXES" | wc -l)
        SIMPLE_DESC="$SIMPLE_DESC and $FIX_COUNT bug fixes"
    fi
    
    # 创建 release 条目
    RELEASE_ENTRY="    <release version=\"$VERSION\" date=\"$DATE\">\n"
    RELEASE_ENTRY="${RELEASE_ENTRY}      <description>\n"
    RELEASE_ENTRY="${RELEASE_ENTRY}        <p>$SIMPLE_DESC</p>\n"
    
    if [ -n "$FEATURES" ]; then
        RELEASE_ENTRY="${RELEASE_ENTRY}        <ul>\n"
        echo "$FEATURES" | head -5 | while IFS='|||' read -r subject body; do
            clean=$(echo "$subject" | sed -E 's/^feat(\([^)]+\))?[!]?: //')
            RELEASE_ENTRY="${RELEASE_ENTRY}          <li>$clean</li>\n"
        done
        RELEASE_ENTRY="${RELEASE_ENTRY}        </ul>\n"
    fi
    
    RELEASE_ENTRY="${RELEASE_ENTRY}      </description>\n"
    RELEASE_ENTRY="${RELEASE_ENTRY}    </release>"
    
    # 在 <releases> 后插入
    sed -i "/<releases>/a\\
$RELEASE_ENTRY" "$METAINFO_FILE"
    
    echo "✓ Flatpak metainfo updated"
else
    echo "⚠ Flatpak metainfo not found, skipping"
fi

# 8. 生成 Release Notes 预览
echo ""
echo "📋 Generating Release Notes preview..."

cat > /tmp/release-notes-$VERSION.md << EOF
# PostMock v$VERSION

## 📦 下载安装

请根据你的操作系统下载对应的安装包。

## 📊 变更统计

- **文件变更**: $TOTAL_FILES 个文件
- **代码变更**: +$INSERTIONS/-$DELETIONS 行
- **UI 组件**: $UI_FILES 个文件
- **API/服务**: $API_FILES 个文件
- **文档**: $DOC_FILES 个文件

## 📝 详细变更

$(echo -e "$CHANGELOG" | sed 's/^## \[.*\] - .*$//')

---

**完整变更日志**: https://github.com/duwei0227/postmock/blob/main/CHANGELOG.md
EOF

echo "✓ Release notes saved to /tmp/release-notes-$VERSION.md"

# 9. 显示摘要
echo ""
echo "✅ Changelog generation complete!"
echo ""
echo "📊 Summary:"
echo "  Version: $VERSION"
echo "  Date: $DATE"
echo "  Files changed: $TOTAL_FILES"
echo "  Code changes: +$INSERTIONS/-$DELETIONS"
[ -n "$FEATURES" ] && echo "  New features: $(echo "$FEATURES" | wc -l)"
[ -n "$FIXES" ] && echo "  Bug fixes: $(echo "$FIXES" | wc -l)"
[ -n "$BREAKING" ] && echo "  ⚠️  Breaking changes: $(echo "$BREAKING" | wc -l)"
echo ""
echo "📁 Updated files:"
echo "  - CHANGELOG.md"
[ -f "$METAINFO_FILE" ] && echo "  - $METAINFO_FILE"
echo "  - /tmp/release-notes-$VERSION.md (preview)"
echo ""
echo "📝 Next steps:"
echo "  1. Review and edit CHANGELOG.md if needed"
echo "  2. Review /tmp/release-notes-$VERSION.md"
echo "  3. Commit changes: git add . && git commit -m 'chore: release v$VERSION'"
echo "  4. Create tag: git tag v$VERSION && git push origin v$VERSION"
echo ""
