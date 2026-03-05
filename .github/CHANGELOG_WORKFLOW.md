# CHANGELOG 和 Release Notes 工作流

## 概述

本文档说明 CHANGELOG.md 如何影响 GitHub Release 和应用内自动更新的显示内容。

## 完整流程

```
CHANGELOG.md
    ↓
GitHub Actions (create-release job)
    ↓
Release Body (GitHub Release 页面)
    ↓
GitHub Actions (generate-updater-manifest job)
    ↓
latest.json (notes 字段)
    ↓
应用内自动更新 (UpdateDialog 组件)
```

## 详细说明

### 1. CHANGELOG.md 格式

遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) 规范：

```markdown
## [0.1.1] - 2026-03-05

### 新增
- 功能 A
- 功能 B

### 改进
- 改进 C

### 修复
- 修复 D
```

### 2. GitHub Actions 提取变更日志

在 `.github/workflows/release.yml` 的 `create-release` job 中：

```yaml
- name: Extract or generate changelog
  run: |
    VERSION="${{ env.PACKAGE_VERSION }}"
    
    # 方式 1: 从 CHANGELOG.md 提取
    if [ -f "CHANGELOG.md" ]; then
      CHANGELOG=$(sed -n "/## \[$VERSION\]/,/## \[/p" CHANGELOG.md | sed '$d' | tail -n +2)
    fi
    
    # 方式 2: 如果找不到，从 Git commits 自动生成
    if [ -z "$CHANGELOG" ]; then
      # 从 commits 生成...
    fi
```

**优先级：**
1. 首先尝试从 CHANGELOG.md 提取对应版本的内容
2. 如果找不到，则从 Git commits 自动生成

### 3. 生成 Release Body

```yaml
- name: Create release body
  run: |
    echo "## 📥 下载安装" > /tmp/release-body.md
    echo "" >> /tmp/release-body.md
    echo "> **提示：** 请只下载以下列出的安装包文件..." >> /tmp/release-body.md
    # ... 添加下载链接 ...
    echo "## 📝 更新内容" >> /tmp/release-body.md
    echo "" >> /tmp/release-body.md
    echo "$CHANGELOG" >> /tmp/release-body.md
```

### 4. 创建 GitHub Release

Release Body 包含：
- 下载安装指南（用户友好的文件列表）
- 更新内容（来自 CHANGELOG.md 或 Git commits）
- 完整变更日志链接

### 5. 生成 latest.json

在 `generate-updater-manifest` job 中：

```yaml
- name: Generate updater manifest
  run: |
    # 从 Release 提取 body
    CHANGELOG=$(gh release view "v${VERSION}" --json body -q .body)
    
    # 生成 JSON
    cat > latest.json << EOF
    {
      "version": "${VERSION}",
      "notes": $(echo "$CHANGELOG" | jq -Rs .),
      "pub_date": "${RELEASE_DATE}",
      "platforms": { ... }
    }
    EOF
```

### 6. 应用内显示

在 `src/components/UpdateDialog.vue` 中：

```vue
<div v-if="updateInfo.body" class="space-y-2">
  <h3 class="text-lg font-semibold">What's New</h3>
  <div class="p-4 bg-surface-50 dark:bg-surface-800 rounded-lg max-h-64 overflow-y-auto">
    {{ updateInfo.body }}
  </div>
</div>
```

## 最佳实践

### 1. 维护 CHANGELOG.md

**推荐：** 在每次发布前手动更新 CHANGELOG.md

```bash
# 编辑 CHANGELOG.md
nano CHANGELOG.md

# 添加新版本的条目
## [0.1.1] - 2026-03-05

### 新增
- HTTP 请求支持文件下载功能
- 集成 Tauri 自动更新功能

### 改进
- 优化 GitHub Actions 工作流

### 修复
- 修复文件下载时文件名为空的问题
```

**优点：**
- 更详细和结构化的变更说明
- 更好的用户体验
- 更专业的 Release 页面

### 2. 使用 Conventional Commits

如果依赖自动生成，确保 commit 消息遵循规范：

```bash
feat: 添加文件下载功能
fix: 修复文件名为空的问题
docs: 更新 README
chore: 更新依赖版本
```

### 3. 发布前检查清单

使用 `scripts/release.sh` 脚本，它会：

1. ✅ 检查 CHANGELOG.md 是否包含新版本条目
2. ✅ 如果没有，提示是否编辑
3. ✅ 自动提交 CHANGELOG.md（如果有更改）

```bash
./scripts/release.sh 0.1.1
```

## 示例

### CHANGELOG.md 条目

```markdown
## [0.1.1] - 2026-03-05

### 新增
- HTTP 请求支持文件下载功能（Send And Download 按钮）
- 集成 Tauri 自动更新功能，支持应用内检查和安装更新
- 添加更新对话框组件，显示更新进度和状态

### 改进
- 优化 GitHub Actions 工作流，支持带密码的签名密钥
- 改进 Release 说明模板，清晰标注用户下载文件

### 修复
- 修复 build-portable job 缺少签名密钥密码配置的问题
- 修复文件下载时文件名为空的问题
```

### GitHub Release 页面显示

```markdown
## 📥 下载安装

> **提示：** 请只下载以下列出的安装包文件...

### Windows
- **PostMock_0.1.1_x64.msi** - 推荐，Windows 安装程序
...

---

## 📝 更新内容

### 新增
- HTTP 请求支持文件下载功能（Send And Download 按钮）
- 集成 Tauri 自动更新功能，支持应用内检查和安装更新
...
```

### latest.json 内容

```json
{
  "version": "0.1.1",
  "notes": "## 📥 下载安装\n\n> **提示：** ...\n\n## 📝 更新内容\n\n### 新增\n- HTTP 请求支持文件下载功能...",
  "pub_date": "2026-03-05T10:30:00Z",
  "platforms": { ... }
}
```

### 应用内更新对话框显示

```
┌─────────────────────────────────────┐
│ Update Available                    │
├─────────────────────────────────────┤
│ New Version: 0.1.1                  │
│ Release Date: 2026年3月5日          │
│                                     │
│ What's New                          │
│ ┌─────────────────────────────────┐ │
│ │ ## 📥 下载安装                  │ │
│ │                                 │ │
│ │ ## 📝 更新内容                  │ │
│ │                                 │ │
│ │ ### 新增                        │ │
│ │ - HTTP 请求支持文件下载功能     │ │
│ │ - 集成 Tauri 自动更新功能       │ │
│ │ ...                             │ │
│ └─────────────────────────────────┘ │
│                                     │
│ [Download and Install] [Later]      │
└─────────────────────────────────────┘
```

## 故障排除

### 问题 1：应用内看不到更新说明

**原因：** CHANGELOG.md 中没有对应版本的条目，且 Git commits 也没有有效内容

**解决方案：**
1. 在 CHANGELOG.md 中添加版本条目
2. 重新创建 Release
3. 或者使用有意义的 commit 消息

### 问题 2：Release 说明格式混乱

**原因：** CHANGELOG.md 格式不规范

**解决方案：**
1. 遵循 Keep a Changelog 格式
2. 使用标准的 Markdown 语法
3. 避免使用特殊字符

### 问题 3：latest.json 中的 notes 为空

**原因：** Release body 为空或提取失败

**解决方案：**
1. 检查 GitHub Actions 日志
2. 确认 Release 已成功创建
3. 验证 `gh` CLI 命令权限

## 相关文档

- [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/) - CHANGELOG 格式规范
- [Conventional Commits](https://www.conventionalcommits.org/) - Commit 消息规范
- [RELEASE_ASSETS_EXPLANATION.md](RELEASE_ASSETS_EXPLANATION.md) - Release Assets 说明
- [UPDATER_QUICKSTART.md](UPDATER_QUICKSTART.md) - 自动更新快速指南

## 维护建议

1. **每次发布前更新 CHANGELOG.md**
   - 在开发过程中持续记录变更
   - 发布前整理和完善

2. **使用有意义的 commit 消息**
   - 即使有 CHANGELOG.md，好的 commit 消息也很重要
   - 便于代码审查和问题追踪

3. **定期审查 Release 页面**
   - 确保用户看到的内容清晰准确
   - 收集用户反馈改进说明

4. **测试自动更新流程**
   - 验证更新说明在应用内正确显示
   - 确保格式友好易读

---

**最后更新：** 2026-03-05
