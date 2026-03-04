# Commit 规范

本项目遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范，以便自动生成 changelog。

## Commit 消息格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type（必需）

- `feat`: 新功能
- `fix`: 问题修复
- `docs`: 文档更新
- `style`: 代码格式（不影响代码运行的变动）
- `refactor`: 重构（既不是新增功能，也不是修复 bug）
- `perf`: 性能优化
- `test`: 增加测试
- `chore`: 构建过程或辅助工具的变动
- `ci`: CI 配置文件和脚本的变动
- `build`: 影响构建系统或外部依赖的变更

### Scope（可选）

指定 commit 影响的范围，例如：

- `ui`: UI 相关
- `api`: API 相关
- `auth`: 认证相关
- `collection`: 集合管理
- `environment`: 环境变量
- `test`: 测试相关
- `workflow`: GitHub Actions 工作流

### Subject（必需）

简短描述，不超过 50 个字符：

- 使用祈使句，现在时态："add" 而不是 "added" 或 "adds"
- 首字母小写
- 结尾不加句号

### Body（可选）

详细描述，说明：
- 为什么做这个变更
- 变更的影响
- 迁移指南（如果需要）

### Footer（可选）

- **Breaking Changes**: 不兼容的变更
- **Closes**: 关闭的 issue

## 示例

### 新功能

```bash
git commit -m "feat(collection): add folder drag and drop support"

git commit -m "feat(api): add request timeout configuration

Allow users to set custom timeout for each request.
Default timeout is 30 seconds.

Closes #123"
```

### 问题修复

```bash
git commit -m "fix(environment): variable substitution in headers"

git commit -m "fix(ui): request history not updating

The history panel was not refreshing after sending a request.
This commit fixes the reactivity issue.

Fixes #456"
```

### 文档更新

```bash
git commit -m "docs: update installation guide"

git commit -m "docs(readme): add screenshots and usage examples"
```

### 重构

```bash
git commit -m "refactor(storage): migrate to new storage service"

git commit -m "refactor: extract request validation logic"
```

### 性能优化

```bash
git commit -m "perf(collection): optimize large collection rendering"
```

### 测试

```bash
git commit -m "test(api): add unit tests for request builder"
```

### 构建和 CI

```bash
git commit -m "chore: bump version to 0.2.0"

git commit -m "ci: add automated release workflow"

git commit -m "build: update dependencies"
```

### Breaking Changes

```bash
git commit -m "feat(api)!: change request format

BREAKING CHANGE: Request format has changed from v1 to v2.
Migration guide: https://..."
```

## Changelog 生成规则

当推送 tag 时，GitHub Actions 会自动生成 changelog：

### 优先级 1: 从 CHANGELOG.md 提取

如果 `CHANGELOG.md` 中包含当前版本的条目：

```markdown
## [0.2.0] - 2024-03-05

### 新增
- 添加了请求超时设置
- 支持 WebSocket 连接

### 修复
- 修复了环境变量替换的 bug
```

将直接使用这些内容。

### 优先级 2: 从 Git Commits 自动生成

如果 `CHANGELOG.md` 中没有找到，将从 Git commits 自动生成：

**输入（commits）：**
```
feat(collection): add folder drag and drop
fix(environment): variable substitution in headers
docs: update README with new features
chore: bump version to 0.2.0
```

**输出（changelog）：**
```markdown
### 新增功能

- (collection) add folder drag and drop

### 问题修复

- (environment) variable substitution in headers

### 文档更新

- update README with new features
```

## 最佳实践

### ✅ 好的 Commit

```bash
feat(ui): add dark mode toggle button
fix(api): handle network timeout errors
docs: add API testing guide
refactor(storage): use IndexedDB instead of localStorage
perf(collection): lazy load large collections
test(api): add integration tests for HTTP methods
```

### ❌ 不好的 Commit

```bash
update code
fix bug
WIP
asdfasdf
Updated files
Fixed issue
```

## 工具推荐

### Commitizen

交互式创建符合规范的 commit：

```bash
npm install -g commitizen cz-conventional-changelog

# 使用
git cz
```

### Commitlint

验证 commit 消息格式：

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional

# .commitlintrc.json
{
  "extends": ["@commitlint/config-conventional"]
}
```

### Husky

Git hooks，在 commit 前验证：

```bash
npm install --save-dev husky

# package.json
{
  "husky": {
    "hooks": {
      "commit-msg": "commitlint -E HUSKY_GIT_PARAMS"
    }
  }
}
```

## 手动维护 CHANGELOG

虽然支持自动生成，但推荐手动维护 `CHANGELOG.md`：

### 优势

- ✅ 更清晰的分类
- ✅ 更详细的说明
- ✅ 可以合并相关的变更
- ✅ 可以添加迁移指南
- ✅ 更好的用户体验

### 模板

```markdown
# 更新日志

## [Unreleased]

### 新增
- 

### 变更
- 

### 修复
- 

### 移除
- 

## [0.2.0] - 2024-03-05

### 新增
- 添加了请求超时设置
- 支持 WebSocket 连接
- 新增请求重试功能

### 变更
- 改进了集合管理界面
- 优化了大型响应的显示性能

### 修复
- 修复了环境变量在 headers 中不生效的问题
- 修复了历史记录不更新的 bug
- 修复了深色模式下的显示问题

### 移除
- 移除了已废弃的旧版 API

## [0.1.0] - 2024-03-04

### 新增
- 初始版本发布
- HTTP 请求测试功能
- 集合管理
- 环境变量
- 请求历史
```

## 发布流程

### 方式 1: 手动维护 CHANGELOG（推荐）

```bash
# 1. 更新 CHANGELOG.md
vim CHANGELOG.md

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

## 参考资料

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit)
