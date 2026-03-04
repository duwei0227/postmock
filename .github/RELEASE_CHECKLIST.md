# 发布检查清单

在发布新版本之前，请确保完成以下所有步骤：

## 版本更新

- [ ] 更新 `package.json` 中的版本号
- [ ] 更新 `src-tauri/Cargo.toml` 中的版本号
- [ ] 更新 `src-tauri/tauri.conf.json` 中的版本号
- [ ] 更新 `CHANGELOG.md`，添加新版本的变更内容
  ```bash
  # 方式 1: 手动编辑 CHANGELOG.md（推荐）
  vim CHANGELOG.md
  
  # 方式 2: 从 Git commits 自动生成
  ./scripts/generate-changelog.sh 0.2.0
  ```

## 元数据更新

- [ ] 更新 `flatpak/cn.probiecoder.postmock.metainfo.xml` 中的 releases 部分
  ```bash
  # 使用脚本自动更新
  ./scripts/update-metainfo.sh 0.2.0 "Added new features"
  ```
- [ ] 确保 `src-tauri/Cargo.toml` 中的 description 准确描述应用
- [ ] 确保 `src-tauri/tauri.conf.json` 中的 shortDescription 和 longDescription 是最新的

## 截图和文档

- [ ] 添加或更新应用截图到 `screenshots/` 目录
  - main.png - 主界面
  - collections.png - 集合管理
  - environment.png - 环境变量
- [ ] 更新 README.md 中的功能列表（如有新功能）
- [ ] 检查所有文档链接是否有效

## 代码质量

- [ ] 运行测试确保所有测试通过
  ```bash
  npm test
  ```
- [ ] 本地构建验证
  ```bash
  npm run tauri build
  ```
- [ ] 检查是否有编译警告或错误
- [ ] 代码格式化
  ```bash
  npm run format
  ```

## Git 操作

- [ ] 提交所有更改
  ```bash
  git add .
  git commit -m "chore: release v0.2.0"
  ```
- [ ] 推送到远程仓库
  ```bash
  git push
  ```
- [ ] 创建并推送 tag
  ```bash
  git tag v0.2.0
  git push origin v0.2.0
  ```

## 发布后验证

- [ ] 检查 GitHub Actions 构建状态
  - https://github.com/duwei0227/postmock/actions
- [ ] 验证所有平台的安装包都已上传
  - Windows: .msi, .exe
  - macOS: .dmg
  - Linux: .AppImage, .deb, .rpm, .flatpak
- [ ] 检查 Release Notes 是否正确显示
- [ ] 下载并测试至少一个平台的安装包

## 可选步骤

- [ ] 更新 Flathub 仓库（如果已发布到 Flathub）
- [ ] 在社交媒体或论坛宣布新版本
- [ ] 更新项目网站（如果有）
- [ ] 通知用户或团队成员

## 版本号规范

遵循语义化版本（Semantic Versioning）：

- **主版本号（Major）**: 不兼容的 API 修改
- **次版本号（Minor）**: 向下兼容的功能性新增
- **修订号（Patch）**: 向下兼容的问题修正

示例：
- `0.1.0` → `0.2.0` - 添加新功能
- `0.2.0` → `0.2.1` - 修复 bug
- `0.9.0` → `1.0.0` - 首个稳定版本

## 常见问题

### 如何回滚发布？

如果发现严重问题需要回滚：

1. 删除 GitHub Release
2. 删除 tag
   ```bash
   git push --delete origin v0.2.0
   git tag -d v0.2.0
   ```
3. 修复问题后重新发布

### 如何发布预览版？

使用预发布标记：
```bash
git tag v0.2.0-beta.1
git push origin v0.2.0-beta.1
```

在 release.yml 中设置 `prerelease: true`
