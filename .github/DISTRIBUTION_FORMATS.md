# 分发格式说明

PostMock 提供多种分发格式，满足不同用户的需求。

## 格式对比

| 格式 | 平台 | 安装 | 系统集成 | 自动更新 | 便携性 | 推荐场景 |
|------|------|------|----------|----------|--------|----------|
| `.msi` | Windows | 需要 | ✅ | 计划中 | ❌ | 日常使用 |
| `.exe` (NSIS) | Windows | 需要 | ✅ | 计划中 | ❌ | 日常使用 |
| `.zip` | Windows | 无需 | ❌ | ❌ | ✅ | 测试/临时使用 |
| `.dmg` | macOS | 需要 | ✅ | 计划中 | ❌ | 日常使用 |
| `.deb` | Linux | 需要 | ✅ | ✅ | ❌ | Debian/Ubuntu |
| `.rpm` | Linux | 需要 | ✅ | ✅ | ❌ | Fedora/RHEL |
| `.AppImage` | Linux | 无需 | ⚠️ | ❌ | ✅ | 通用/测试 |
| `.flatpak` | Linux | 需要 | ✅ | ✅ | ❌ | 推荐 Linux 用户 |
| `.tar.gz` | Linux | 无需 | ❌ | ❌ | ✅ | 服务器/测试 |

## Windows 格式

### MSI (Windows Installer)
**文件名**: `postmock_x.x.x_x64_en-US.msi`

**特点:**
- ✅ 标准 Windows 安装程序
- ✅ 添加到开始菜单
- ✅ 添加到"程序和功能"
- ✅ 支持静默安装
- ✅ 支持卸载

**安装:**
```powershell
# GUI 安装
双击 .msi 文件

# 静默安装
msiexec /i postmock_0.1.0_x64_en-US.msi /quiet

# 卸载
msiexec /x postmock_0.1.0_x64_en-US.msi /quiet
```

**适用场景:**
- 企业部署
- 需要 GPO 部署
- 标准 Windows 环境

### NSIS 安装程序
**文件名**: `postmock_x.x.x_x64-setup.exe`

**特点:**
- ✅ 现代化安装界面
- ✅ 多语言支持
- ✅ 自定义安装选项
- ✅ 创建桌面快捷方式

**安装:**
```powershell
# GUI 安装
双击 .exe 文件

# 静默安装
postmock_0.1.0_x64-setup.exe /S

# 卸载
从控制面板卸载
```

**适用场景:**
- 个人用户
- 需要自定义安装
- 喜欢现代化界面

### ZIP 便携版
**文件名**: `postmock-x.x.x-windows-x64-portable.zip`

**特点:**
- ✅ 无需安装
- ✅ 解压即用
- ✅ 可放在 U 盘
- ❌ 不集成到系统

**使用:**
```powershell
# 解压
Expand-Archive postmock-0.1.0-windows-x64-portable.zip

# 运行
cd postmock-0.1.0-windows-x64-portable
.\postmock.exe
```

**适用场景:**
- 测试新版本
- 临时使用
- 不想安装到系统
- 多版本共存

**详细指南:** [PORTABLE_GUIDE.md](PORTABLE_GUIDE.md)

## macOS 格式

### DMG (磁盘映像)
**文件名**: `PostMock_x.x.x_universal.dmg`

**特点:**
- ✅ 标准 macOS 安装方式
- ✅ 通用二进制（Intel + Apple Silicon）
- ✅ 拖拽安装
- ⚠️ 需要允许未签名应用（首次运行）

**安装:**
```bash
# 打开 DMG
open PostMock_0.1.0_universal.dmg

# 拖拽到 Applications 文件夹
# 或双击运行

# 首次运行需要允许
# 系统偏好设置 → 安全性与隐私 → 允许
```

**卸载:**
```bash
# 删除应用
rm -rf /Applications/PostMock.app

# 删除数据（可选）
rm -rf ~/Library/Application\ Support/postmock
```

**适用场景:**
- 所有 macOS 用户
- Intel 和 Apple Silicon Mac

## Linux 格式

### DEB (Debian/Ubuntu)
**文件名**: `postmock_x.x.x_amd64.deb`

**特点:**
- ✅ Debian/Ubuntu 标准格式
- ✅ 依赖管理
- ✅ 系统集成
- ✅ 通过 apt 更新

**安装:**
```bash
# 安装
sudo dpkg -i postmock_0.1.0_amd64.deb
sudo apt-get install -f  # 安装依赖

# 或使用 apt
sudo apt install ./postmock_0.1.0_amd64.deb

# 运行
postmock

# 卸载
sudo apt remove postmock
```

**适用场景:**
- Debian、Ubuntu、Linux Mint 等
- 需要系统包管理
- 自动更新

### RPM (Fedora/RHEL/CentOS)
**文件名**: `postmock-x.x.x-1.x86_64.rpm`

**特点:**
- ✅ Red Hat 系标准格式
- ✅ 依赖管理
- ✅ 系统集成
- ✅ 通过 dnf/yum 更新

**安装:**
```bash
# Fedora
sudo dnf install postmock-0.1.0-1.x86_64.rpm

# RHEL/CentOS
sudo yum install postmock-0.1.0-1.x86_64.rpm

# 或使用 rpm
sudo rpm -i postmock-0.1.0-1.x86_64.rpm

# 运行
postmock

# 卸载
sudo dnf remove postmock
```

**适用场景:**
- Fedora、RHEL、CentOS、openSUSE 等
- 需要系统包管理
- 自动更新

### AppImage
**文件名**: `postmock_x.x.x_amd64.AppImage`

**特点:**
- ✅ 通用格式，适用所有发行版
- ✅ 无需安装
- ✅ 包含所有依赖
- ⚠️ 文件较大

**使用:**
```bash
# 添加执行权限
chmod +x postmock_0.1.0_amd64.AppImage

# 运行
./postmock_0.1.0_amd64.AppImage

# 集成到系统（可选）
./postmock_0.1.0_amd64.AppImage --appimage-integrate
```

**适用场景:**
- 不想安装包管理器
- 需要在多个发行版使用
- 测试新版本
- 旧版本系统

### Flatpak
**文件名**: `postmock.flatpak` 或通过 Flathub

**特点:**
- ✅ 沙盒隔离
- ✅ 自动更新
- ✅ 统一的依赖管理
- ✅ 适用所有发行版

**安装:**
```bash
# 从文件安装
flatpak install postmock.flatpak

# 从 Flathub 安装（即将推出）
flatpak install flathub cn.probiecoder.postmock

# 运行
flatpak run cn.probiecoder.postmock

# 更新
flatpak update cn.probiecoder.postmock

# 卸载
flatpak uninstall cn.probiecoder.postmock
```

**适用场景:**
- 推荐所有 Linux 用户
- 需要沙盒隔离
- 自动更新
- 跨发行版

### TAR.GZ 便携版
**文件名**: `postmock-x.x.x-linux-x64-portable.tar.gz`

**特点:**
- ✅ 无需安装
- ✅ 解压即用
- ✅ 适合服务器环境
- ❌ 不集成到系统

**使用:**
```bash
# 解压
tar -xzf postmock-0.1.0-linux-x64-portable.tar.gz
cd postmock-0.1.0-linux-x64-portable

# 运行
./postmock

# 或使用启动脚本
./postmock.sh
```

**适用场景:**
- 服务器环境
- 测试新版本
- 不想安装到系统
- 多版本共存

**详细指南:** [PORTABLE_GUIDE.md](PORTABLE_GUIDE.md)

## 选择建议

### 日常使用推荐

**Windows:**
1. MSI 或 NSIS 安装程序（推荐）
2. ZIP 便携版（测试）

**macOS:**
1. DMG（唯一选择）

**Linux:**
1. Flatpak（推荐，跨发行版）
2. DEB（Debian/Ubuntu）
3. RPM（Fedora/RHEL）
4. AppImage（通用）
5. TAR.GZ（服务器/测试）

### 特殊场景

**企业部署:**
- Windows: MSI（支持 GPO）
- Linux: DEB/RPM（包管理器）

**测试/开发:**
- Windows: ZIP
- Linux: TAR.GZ 或 AppImage

**多版本共存:**
- 所有平台: 便携版

**无管理员权限:**
- Windows: ZIP
- Linux: AppImage 或 TAR.GZ

## 文件大小对比

| 格式 | 大小（约） | 说明 |
|------|-----------|------|
| `.msi` | 15-20 MB | 压缩的安装程序 |
| `.exe` (NSIS) | 15-20 MB | 压缩的安装程序 |
| `.zip` | 20-25 MB | 未压缩的二进制 |
| `.dmg` | 25-30 MB | 通用二进制 |
| `.deb` | 15-20 MB | 压缩的包 |
| `.rpm` | 15-20 MB | 压缩的包 |
| `.AppImage` | 30-40 MB | 包含所有依赖 |
| `.flatpak` | 25-35 MB | 压缩的包 |
| `.tar.gz` | 20-25 MB | 压缩的归档 |

## 更新机制

| 格式 | 自动更新 | 手动更新 |
|------|----------|----------|
| MSI/NSIS | 计划中 | 下载新版本重新安装 |
| ZIP | ❌ | 下载新版本解压 |
| DMG | 计划中 | 下载新版本重新安装 |
| DEB | ✅ `apt update && apt upgrade` | 下载新版本安装 |
| RPM | ✅ `dnf update` | 下载新版本安装 |
| AppImage | ❌ | 下载新版本替换 |
| Flatpak | ✅ `flatpak update` | 下载新版本安装 |
| TAR.GZ | ❌ | 下载新版本解压 |

## 相关文档

- [便携版使用指南](PORTABLE_GUIDE.md)
- [发布指南](RELEASE.md)
- [包元数据说明](PACKAGE_METADATA.md)
