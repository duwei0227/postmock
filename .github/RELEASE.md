# 发布指南

## 自动发布流程

本项目使用 GitHub Actions 自动构建和发布桌面应用。

### 支持的平台

- **macOS**: Intel (x86_64) 和 Apple Silicon (aarch64)
- **Linux**: Ubuntu 22.04+ (AppImage, deb, rpm)
- **Windows**: Windows 10+ (msi, exe)

### 如何发布新版本

1. **更新版本号**
   
   在以下文件中更新版本号：
   - `package.json`
   - `src-tauri/Cargo.toml`
   - `src-tauri/tauri.conf.json`

2. **提交更改**
   ```bash
   git add .
   git commit -m "chore: bump version to x.x.x"
   ```

3. **创建并推送标签**
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

4. **自动构建**
   
   推送标签后，GitHub Actions 会自动：
   - 在所有平台上构建应用
   - 创建 GitHub Release（草稿状态）
   - 上传构建产物到 Release

5. **发布 Release**
   
   - 访问 GitHub 仓库的 Releases 页面
   - 找到自动创建的草稿 Release
   - 编辑 Release 说明
   - 点击 "Publish release" 发布

### 手动触发构建

也可以在 GitHub Actions 页面手动触发 `Release Desktop App` 工作流。

### CI/CD 工作流

- **build.yml**: 在每次推送和 PR 时自动构建和测试
- **release.yml**: 在推送标签时自动构建并创建 Release

### 产物说明

发布后，用户可以下载以下格式的安装包：

- **macOS**: `.dmg` (通用二进制包含 Intel 和 Apple Silicon)
- **Linux**: `.AppImage` (通用), `.deb` (Debian/Ubuntu), `.rpm` (Fedora/RHEL/openSUSE)
- **Windows**: `.msi` (安装程序), `.exe` (便携版)

### 注意事项

- Release 默认创建为草稿，需要手动发布
- 确保 GitHub 仓库设置中启用了 Actions 权限
- macOS 应用需要签名才能在用户设备上正常运行（需要配置代码签名证书）
