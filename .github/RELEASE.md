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

### 删除和重新发布版本

如果需要删除已发布的版本并重新发布：

1. **删除 GitHub Release**
   - 访问 https://github.com/duwei0227/postmock/releases
   - 找到要删除的 Release
   - 点击 "Delete" 删除

2. **删除远程 tag**
   ```bash
   git push --delete origin v0.1.0
   ```

3. **删除本地 tag**
   ```bash
   git tag -d v0.1.0
   ```

4. **重新创建并推送 tag**
   ```bash
   # 确保代码已更新并提交
   git add .
   git commit -m "fix: update release"
   git push
   
   # 重新创建 tag
   git tag v0.1.0
   git push origin v0.1.0
   ```

**注意：** 删除并重新发布同一版本号不是推荐做法，建议使用新的版本号（如 v0.1.1）。

### CI/CD 工作流

- **build.yml**: 在 PR 时自动构建和测试
- **release.yml**: 在推送标签时自动构建并创建 Release
  - Job 1: create-release - 创建 GitHub Release
  - Job 2: build-tauri - 构建所有平台的安装包（Windows、macOS、Linux）
  - Job 3: build-flatpak - 构建 Flatpak 包（依赖 build-tauri 完成）

### 产物说明

发布后，用户可以下载以下格式的安装包：

**Windows:**
- `.msi` - Windows Installer 安装程序（推荐）
- `.exe` - NSIS 安装程序
- `.zip` - 便携版（解压即用，无需安装）

**macOS:**
- `.dmg` - 磁盘映像（通用二进制包含 Intel 和 Apple Silicon）

**Linux:**
- `.AppImage` - 通用便携版（无需安装）
- `.deb` - Debian/Ubuntu 安装包
- `.rpm` - Fedora/RHEL/openSUSE 安装包
- `.flatpak` - Flatpak 通用包
- `.tar.gz` - 便携版（解压即用，无需安装）

构建顺序：
1. 创建 Release
2. 并行构建所有平台的原生包
3. 构建便携版（zip 和 tar.gz）
4. 基于 AppImage 构建 Flatpak 包

### 注意事项

- Release 默认创建为草稿，需要手动发布
- 确保 GitHub 仓库设置中启用了 Actions 权限
- macOS 应用需要签名才能在用户设备上正常运行（需要配置代码签名证书）
- 不建议删除并重新发布同一版本号，应使用新版本号

## 常见问题

### 构建失败怎么办？

1. **检查 Actions 日志**
   - 访问 https://github.com/duwei0227/postmock/actions
   - 点击失败的工作流查看详细日志

2. **常见问题：**
   - 权限错误：检查 Settings → Actions → General → Workflow permissions
   - 依赖安装失败：检查 package.json 和 Cargo.toml
   - 构建失败：检查代码是否有语法错误
   - Flatpak 失败：确保 release.yml 已完成且 AppImage 可用

3. **重新运行：**
   - 在 Actions 页面点击 "Re-run jobs"
   - 选择 "Re-run failed jobs" 或 "Re-run all jobs"

### 如何取消正在运行的构建？

1. 访问 https://github.com/duwei0227/postmock/actions
2. 点击正在运行的工作流
3. 点击右上角的 "Cancel workflow"

### 如何查看历史版本？

访问 https://github.com/duwei0227/postmock/releases 查看所有已发布的版本。
