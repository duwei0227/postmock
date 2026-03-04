# Changelog 自动化

本项目支持两种方式生成 Release Notes：

## 方式 1: 手动维护 CHANGELOG.md（推荐）

### 优势
- ✅ 更清晰、更专业的描述
- ✅ 可以合并相关变更
- ✅ 可以添加迁移指南
- ✅ 更好的用户体验

### 使用方法

1. **编辑 CHANGELOG.md**
   ```markdown
   ## [0.2.0] - 2024-03-05
   
   ### 新增
   - 添加了请求超时设置
   - 支持 WebSocket 连接
   
   ### 修复
   - 修复了环境变量替换的 bug
   ```

2. **提交并创建 tag**
   ```bash
   git add CHANGELOG.md
   git commit -m "chore: update changelog for v0.2.0"
   git push
   git tag v0.2.0
   git push origin v0.2.0
   ```

3. **GitHub Actions 会自动**
   - 从 CHANGELOG.md 提取对应版本的内容
   - 创建 Release
   - 生成所有平台的安装包

## 方式 2: 自动从 Git Commits 生成

### 优势
- ✅ 快速发布
- ✅ 不需要手动维护
- ✅ 自动分类

### 前提条件

所有 commits 必须遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```bash
feat(scope): add new feature
fix(scope): fix bug
docs: update documentation
```

详见：[COMMIT_CONVENTION.md](COMMIT_CONVENTION.md)

### 使用方法

#### 选项 A: 完全自动（推送 tag 时生成）

```bash
# 1. 确保所有 commits 遵循规范
git log --oneline

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

GitHub Actions 会：
- 检查 CHANGELOG.md 中是否有 v0.2.0 的条目
- 如果没有，自动从 Git commits 生成
- 按类型分类（新增、修复、文档等）

#### 选项 B: 预先生成（推荐）

使用脚本预先生成，然后可以手动编辑：

```bash
# 生成 changelog
./scripts/generate-changelog.sh 0.2.0

# 查看生成的内容
cat CHANGELOG.md

# 手动编辑（可选）
vim CHANGELOG.md

# 提交
git add CHANGELOG.md
git commit -m "chore: update changelog for v0.2.0"
git push

# 创建 tag
git tag v0.2.0
git push origin v0.2.0
```

## 工作流程详解

### GitHub Actions 逻辑

```yaml
1. 提取或生成 changelog
   ├─ 尝试从 CHANGELOG.md 提取当前版本
   │  └─ 如果找到 → 使用手动维护的内容
   │
   └─ 如果没找到 → 从 Git commits 自动生成
      ├─ 获取上一个 tag
      ├─ 获取两个 tag 之间的 commits
      ├─ 按 Conventional Commits 分类
      │  ├─ feat → 新增功能
      │  ├─ fix → 问题修复
      │  ├─ docs → 文档更新
      │  └─ 其他 → 其他变更
      └─ 生成格式化的 changelog

2. 创建 Release
   └─ 使用生成的 changelog 作为 Release Notes

3. 构建所有平台的安装包
```

### Commit 分类规则

| Commit 前缀 | 分类 | 示例 |
|------------|------|------|
| `feat:` | 新增功能 | `feat(ui): add dark mode` |
| `fix:` | 问题修复 | `fix(api): handle timeout` |
| `docs:` | 文档更新 | `docs: update README` |
| `refactor:` | 重构 | `refactor: extract helper` |
| `perf:` | 性能优化 | `perf: optimize rendering` |
| `test:` | 测试 | `test: add unit tests` |
| `chore:` | 构建/维护 | `chore: bump version` |
| `ci:` | CI 配置 | `ci: update workflow` |
| `style:` | 代码格式 | `style: format code` |

## 示例

### 示例 1: 手动维护

**CHANGELOG.md:**
```markdown
## [0.2.0] - 2024-03-05

### 新增
- 添加了请求超时设置，支持自定义超时时间
- 支持 WebSocket 连接测试
- 新增请求重试功能，最多重试 3 次

### 修复
- 修复了环境变量在 headers 中不生效的问题
- 修复了历史记录不更新的 bug
- 修复了深色模式下按钮颜色不正确的问题

### 性能优化
- 优化了大型响应数据的渲染性能
- 减少了集合加载时间

### 文档
- 更新了 README，添加了使用示例
- 添加了 API 文档
```

**生成的 Release Notes:**
```markdown
## 下载安装
...

## 更新内容

### 新增
- 添加了请求超时设置，支持自定义超时时间
- 支持 WebSocket 连接测试
- 新增请求重试功能，最多重试 3 次

### 修复
- 修复了环境变量在 headers 中不生效的问题
- 修复了历史记录不更新的 bug
- 修复了深色模式下按钮颜色不正确的问题

...
```

### 示例 2: 自动生成

**Git Commits:**
```
feat(api): add request timeout configuration
feat(websocket): add WebSocket connection support
feat(retry): implement request retry mechanism
fix(environment): variable substitution in headers
fix(history): update history panel reactivity
fix(ui): button color in dark mode
perf(response): optimize large response rendering
perf(collection): reduce collection loading time
docs: update README with usage examples
docs(api): add API documentation
```

**自动生成的 Changelog:**
```markdown
### 新增功能

- (api) add request timeout configuration
- (websocket) add WebSocket connection support
- (retry) implement request retry mechanism

### 问题修复

- (environment) variable substitution in headers
- (history) update history panel reactivity
- (ui) button color in dark mode

### 性能优化

- (response) optimize large response rendering
- (collection) reduce collection loading time

### 文档更新

- update README with usage examples
- (api) add API documentation
```

## 最佳实践

### 推荐工作流

1. **开发阶段**
   - 遵循 Conventional Commits 规范提交代码
   - 每个功能/修复一个 commit

2. **准备发布**
   - 运行脚本生成初始 changelog
     ```bash
     ./scripts/generate-changelog.sh 0.2.0
     ```
   - 手动编辑和完善
   - 添加详细说明和迁移指南

3. **发布**
   - 提交 CHANGELOG.md
   - 创建 tag
   - GitHub Actions 自动构建和发布

### Commit 规范建议

✅ **好的 Commits:**
```bash
feat(collection): add folder drag and drop support
fix(api): handle network timeout errors properly
docs: add comprehensive API testing guide
perf(ui): lazy load large collections for better performance
```

❌ **不好的 Commits:**
```bash
update code
fix bug
WIP
changes
```

## 工具和脚本

### generate-changelog.sh

自动从 Git commits 生成 changelog：

```bash
# 基本用法
./scripts/generate-changelog.sh 0.2.0

# 指定上一个 tag
./scripts/generate-changelog.sh 0.2.0 v0.1.0

# 查看帮助
./scripts/generate-changelog.sh
```

### update-metainfo.sh

更新 Flatpak 元数据：

```bash
./scripts/update-metainfo.sh 0.2.0 "Added new features"
```

### validate-metadata.sh

验证所有元数据：

```bash
./scripts/validate-metadata.sh
```

## 故障排除

### 问题：自动生成的 changelog 为空

**原因：** Commits 不符合 Conventional Commits 规范

**解决：**
1. 检查 commits：`git log --oneline`
2. 确保 commits 以 `feat:`, `fix:` 等开头
3. 或手动维护 CHANGELOG.md

### 问题：生成的 changelog 分类不正确

**原因：** Commit 前缀不标准

**解决：**
1. 使用标准前缀（feat, fix, docs 等）
2. 或手动编辑生成的 CHANGELOG.md

### 问题：想要更详细的 Release Notes

**解决：**
1. 使用脚本生成初始版本
2. 手动编辑添加详细说明
3. 提交 CHANGELOG.md

## 相关文档

- [Commit 规范](COMMIT_CONVENTION.md)
- [发布检查清单](RELEASE_CHECKLIST.md)
- [发布指南](RELEASE.md)
