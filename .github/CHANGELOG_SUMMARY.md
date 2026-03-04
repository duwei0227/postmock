# Changelog 自动化系统总结

## 系统概述

本项目已实现完整的 Changelog 自动化系统，支持两种模式：

1. **手动维护模式**（优先级 1）- 从 CHANGELOG.md 提取
2. **自动生成模式**（优先级 2）- 从 Git commits 自动生成

## 工作原理

### 触发条件

当推送 tag 时（如 `v0.2.0`），GitHub Actions 自动执行：

```bash
git tag v0.2.0
git push origin v0.2.0
```

### 执行流程

```
1. 读取版本号（从 package.json）
   ↓
2. 尝试从 CHANGELOG.md 提取对应版本的内容
   ├─ 找到 → 使用手动维护的内容 ✓
   └─ 未找到 → 继续下一步
   ↓
3. 从 Git commits 自动生成
   ├─ 获取上一个 tag
   ├─ 获取两个 tag 之间的所有 commits
   ├─ 按 Conventional Commits 规范分类
   │  ├─ feat: → 新增功能
   │  ├─ fix: → 问题修复
   │  ├─ docs: → 文档更新
   │  ├─ perf: → 性能优化
   │  ├─ refactor: → 重构
   │  └─ chore: → 构建和维护
   └─ 生成格式化的 changelog
   ↓
4. 创建 Release Body
   ├─ 添加下载说明
   ├─ 插入 changelog 内容
   └─ 添加完整变更日志链接
   ↓
5. 创建 GitHub Release
   └─ 上传所有平台的安装包
```

## 使用方式

### 方式 1: 手动维护（推荐）

**优势：**
- ✅ 更清晰、更专业的描述
- ✅ 可以合并相关变更
- ✅ 可以添加迁移指南
- ✅ 更好的用户体验

**步骤：**

```bash
# 1. 编辑 CHANGELOG.md
vim CHANGELOG.md
```

添加新版本内容：
```markdown
## [0.2.0] - 2024-03-05

### 新增
- 添加了请求超时设置，支持自定义超时时间
- 支持 WebSocket 连接测试

### 修复
- 修复了环境变量在 headers 中不生效的问题
- 修复了历史记录不更新的 bug
```

```bash
# 2. 更新版本号
vim package.json src-tauri/Cargo.toml src-tauri/tauri.conf.json

# 3. 提交
git add .
git commit -m "chore: release v0.2.0"
git push

# 4. 创建 tag
git tag v0.2.0
git push origin v0.2.0
```

### 方式 2: 自动生成（快速发布）

**优势：**
- ✅ 快速发布
- ✅ 不需要手动维护
- ✅ 自动分类

**前提条件：**
所有 commits 必须遵循 Conventional Commits 规范：

```bash
feat(scope): add new feature
fix(scope): fix bug
docs: update documentation
```

**步骤：**

```bash
# 1. 确保所有 commits 遵循规范
git log --oneline

# 2. 更新版本号
vim package.json src-tauri/Cargo.toml src-tauri/tauri.conf.json

# 3. 提交
git add .
git commit -m "chore: release v0.2.0"
git push

# 4. 创建 tag（会自动从 commits 生成 changelog）
git tag v0.2.0
git push origin v0.2.0
```

### 方式 3: 混合模式（最佳实践）

结合两种方式的优势：

```bash
# 1. 使用脚本生成初始 changelog
./scripts/generate-changelog.sh 0.2.0

# 2. 手动编辑和完善
vim CHANGELOG.md

# 3. 更新版本号
vim package.json src-tauri/Cargo.toml src-tauri/tauri.conf.json

# 4. 提交并创建 tag
git add .
git commit -m "chore: release v0.2.0"
git push
git tag v0.2.0
git push origin v0.2.0
```

## Commit 规范

### 标准格式

```
<type>(<scope>): <subject>
```

### Type 分类

| Type | 中文 | 示例 |
|------|------|------|
| `feat` | 新增功能 | `feat(ui): add dark mode` |
| `fix` | 问题修复 | `fix(api): handle timeout` |
| `docs` | 文档更新 | `docs: update README` |
| `refactor` | 重构 | `refactor: extract helper` |
| `perf` | 性能优化 | `perf: optimize rendering` |
| `test` | 测试 | `test: add unit tests` |
| `chore` | 构建/维护 | `chore: bump version` |
| `ci` | CI 配置 | `ci: update workflow` |
| `style` | 代码格式 | `style: format code` |

### 示例

✅ **好的 Commits:**
```bash
feat(collection): add folder drag and drop support
fix(environment): variable substitution in headers
docs: add comprehensive API testing guide
perf(ui): lazy load large collections
refactor(storage): migrate to new storage service
```

❌ **不好的 Commits:**
`