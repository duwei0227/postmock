# GitHub Actions 工作流说明

## 工作流概览

### release.yml - 发布工作流
**触发条件：**
- 推送 tag（格式：`v*.*.*`，如 `v0.1.0`）
- 手动触发

**功能：**
1. 创建 GitHub Release
2. 在多平台构建应用：
   - macOS (Intel + Apple Silicon)
   - Linux (Ubuntu 22.04)
   - Windows
3. 生成安装包：
   - Windows: `.msi`, `.exe`
   - macOS: `.dmg`
   - Linux: `.AppImage`, `.deb`, `.rpm`
4. 上传到 GitHub Release
5. 从 CHANGELOG.md 提取更新说明

**运行时间：** 约 30-45 分钟

### flatpak.yml - Flatpak 构建工作流
**触发条件：**
- 推送 tag（格式：`v*.*.*`）
- 手动触发

**功能：**
1. 等待 release.yml 完成
2. 下载 AppImage
3. 构建 Flatpak 包
4. 上传到 GitHub Release

**运行时间：** 约 10-15 分钟

**注意：** 此工作流依赖 release.yml 先完成，因为它需要 AppImage 文件。

### build.yml - CI 测试工作流
**触发条件：**
- Pull Request 到 main/master/develop 分支
- 手动触发

**功能：**
1. 在多平台测试构建
2. 验证代码可以正常编译
3. 不创建 Release

**运行时间：** 约 20-30 分钟

## 使用指南

### 发布新版本

1. **更新版本号：**
   ```bash
   # 编辑以下文件中的版本号
   - package.json
   - src-tauri/Cargo.toml
   - src-tauri/tauri.conf.json
   - CHANGELOG.md
   ```

2. **提交并推送：**
   ```bash
   git add .
   git commit -m "chore: release v0.2.0"
   git push
   ```

3. **创建并推送 tag：**
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

4. **等待构建完成：**
   - 访问 https://github.com/duwei0227/postmock/actions
   - 查看工作流运行状态
   - release.yml 完成后，flatpak.yml 会自动开始

5. **检查 Release：**
   - 访问 https://github.com/duwei0227/postmock/releases
   - 验证所有安装包都已上传
   - 检查 Release Notes

### 手动触发工作流

1. 访问 Actions 页面
2. 选择要运行的工作流
3. 点击 "Run workflow"
4. 选择分支
5. 点击 "Run workflow" 按钮

### 调试失败的构建

1. **查看日志：**
   - 点击失败的工作流运行
   - 展开失败的步骤
   - 查看详细错误信息

2. **常见问题：**
   - **权限错误：** 检查 Settings → Actions → General → Workflow permissions
   - **依赖安装失败：** 检查 package.json 和 Cargo.toml
   - **构建失败：** 检查代码是否有语法错误
   - **Flatpak 失败：** 确保 release.yml 已完成且 AppImage 可用

3. **重新运行：**
   - 点击 "Re-run jobs"
   - 选择 "Re-run failed jobs" 或 "Re-run all jobs"

## 工作流配置

### 权限要求

在仓库设置中配置：

**Settings → Actions → General → Workflow permissions:**
- ✅ Read and write permissions
- ✅ Allow GitHub Actions to create and approve pull requests

### Secrets（可选）

如果需要代码签名：

**Settings → Secrets and variables → Actions:**
- `APPLE_CERTIFICATE` - macOS 代码签名证书
- `APPLE_CERTIFICATE_PASSWORD` - 证书密码
- `APPLE_ID` - Apple ID
- `APPLE_PASSWORD` - App-specific password
- `WINDOWS_CERTIFICATE` - Windows 代码签名证书
- `WINDOWS_CERTIFICATE_PASSWORD` - 证书密码

## 工作流依赖

### release.yml
- Node.js LTS
- Rust stable
- 平台特定依赖：
  - Ubuntu: webkit2gtk, libappindicator3, librsvg2, patchelf, rpm
  - macOS: Xcode Command Line Tools
  - Windows: Visual Studio Build Tools

### flatpak.yml
- Flatpak
- flatpak-builder
- freedesktop runtime 23.08

### build.yml
- 与 release.yml 相同的依赖

## 性能优化

### 缓存
- Node.js 依赖缓存（npm cache）
- Rust 编译缓存（cargo cache）
- Flatpak 构建缓存

### 并行构建
- release.yml 使用 matrix 策略并行构建多平台
- 每个平台独立运行，互不影响

## 监控和通知

### GitHub 通知
- 工作流失败时会发送邮件通知
- 可在 Settings → Notifications 配置

### Status Badge
在 README.md 中添加状态徽章：

```markdown
[![Release](https://github.com/duwei0227/postmock/actions/workflows/release.yml/badge.svg)](https://github.com/duwei0227/postmock/actions/workflows/release.yml)
[![Build](https://github.com/duwei0227/postmock/actions/workflows/build.yml/badge.svg)](https://github.com/duwei0227/postmock/actions/workflows/build.yml)
```

## 相关文档

- [发布指南](../RELEASE.md)
- [分发指南](../DISTRIBUTION.md)
- [Flathub 指南](../FLATHUB.md)
