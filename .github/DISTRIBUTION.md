# 分发指南

PostMock 支持多种分发方式，覆盖所有主流操作系统。

## 支持的平台和格式

### Windows
- `.msi` - Windows Installer 安装包（推荐）
- `.exe` - 便携版可执行文件

### macOS
- `.dmg` - 磁盘映像（通用二进制，支持 Intel 和 Apple Silicon）

### Linux
- `.AppImage` - 通用便携版（无需安装）
- `.deb` - Debian/Ubuntu 系列
- `.rpm` - Fedora/RHEL/CentOS/openSUSE 系列
- `.flatpak` - Flatpak 通用包

## 自动化构建流程

### GitHub Actions 工作流

1. **release.yml** - 主要发布流程
   - 触发：推送 tag（格式：`v*.*.*`）
   - 构建所有平台的原生包
   - 创建 GitHub Release
   - 上传所有安装包

2. **flatpak.yml** - Flatpak 构建
   - 触发：推送 tag
   - 依赖 release.yml 完成后的 AppImage
   - 构建 Flatpak 包
   - 上传到 GitHub Release

3. **build.yml** - CI 测试
   - 触发：Pull Request
   - 在所有平台上测试构建

## 发布新版本

### 1. 准备发布

```bash
# 更新版本号
# - package.json
# - src-tauri/Cargo.toml
# - src-tauri/tauri.conf.json
# - CHANGELOG.md

# 提交更改
git add .
git commit -m "chore: release v0.2.0"
git push
```

### 2. 创建 Tag

```bash
git tag v0.2.0
git push origin v0.2.0
```

### 3. 自动构建

推送 tag 后，GitHub Actions 会自动：

1. 构建所有平台的安装包
2. 创建 GitHub Release
3. 上传安装包到 Release
4. 构建 Flatpak 包

整个过程大约需要 30-60 分钟。

### 4. 发布到 Flathub（可选）

查看 [FLATHUB.md](FLATHUB.md) 了解如何提交到 Flathub。

## 分发渠道

### GitHub Releases（主要）
- 所有平台的安装包
- 自动生成的 Release Notes
- 直接下载链接

### Flathub（Linux）
- 即将推出
- 通过 Flatpak 安装
- 自动更新

### 未来计划
- Microsoft Store（Windows）
- Mac App Store（macOS）
- Snap Store（Linux）
- Homebrew（macOS/Linux）
- Chocolatey（Windows）
- AUR（Arch Linux）

## 安装方式

### Windows

**MSI 安装包（推荐）：**
```powershell
# 下载后双击安装
postmock_0.2.0_x64_en-US.msi
```

**便携版：**
```powershell
# 直接运行
postmock.exe
```

### macOS

**DMG 安装：**
```bash
# 下载后打开 DMG，拖拽到 Applications
open PostMock_0.2.0_universal.dmg
```

### Linux

**AppImage（推荐）：**
```bash
chmod +x postmock_0.2.0_amd64.AppImage
./postmock_0.2.0_amd64.AppImage
```

**Debian/Ubuntu：**
```bash
sudo dpkg -i postmock_0.2.0_amd64.deb
sudo apt-get install -f  # 安装依赖
```

**Fedora/RHEL/CentOS：**
```bash
sudo rpm -i postmock-0.2.0-1.x86_64.rpm
```

**Flatpak：**
```bash
flatpak install postmock_0.2.0_x86_64.flatpak
flatpak run cn.probiecoder.postmock
```

或从 Flathub（即将推出）：
```bash
flatpak install flathub cn.probiecoder.postmock
```

## 签名和公证

### Windows
- 需要代码签名证书
- 配置在 `tauri.conf.json` 的 `bundle.windows.signTool`

### macOS
- 需要 Apple Developer 账号
- 需要配置代码签名和公证
- 配置在 `tauri.conf.json` 的 `bundle.macOS`

### Linux
- Flatpak 包会由 Flathub 签名
- 其他格式不需要签名

## 更新机制

### 自动更新（计划中）
- 使用 Tauri 的更新器
- 检查 GitHub Releases
- 后台下载和安装

### 手动更新
- 用户访问 GitHub Releases
- 下载最新版本
- 重新安装

### Flatpak 自动更新
```bash
flatpak update cn.probiecoder.postmock
```

## 统计和分析

### 下载统计
- GitHub Release 下载次数
- Flathub 安装统计

### 用户反馈
- GitHub Issues
- GitHub Discussions

## 相关文档

- [发布指南](RELEASE.md)
- [Flathub 指南](FLATHUB.md)
- [构建文档](../README.md#开发环境设置)
