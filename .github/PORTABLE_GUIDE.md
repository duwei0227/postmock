# 便携版使用指南

PostMock 提供便携版（Portable Edition），无需安装即可使用。

## 下载

从 [Releases](https://github.com/duwei0227/postmock/releases) 页面下载对应平台的便携版：

- **Windows**: `postmock-x.x.x-windows-x64-portable.zip`
- **Linux**: `postmock-x.x.x-linux-x64-portable.tar.gz`

## Windows 便携版

### 系统要求
- Windows 10 或更高版本（64位）
- WebView2 Runtime（Windows 11 通常已预装）

### 使用方法

1. **解压文件**
   ```powershell
   # 右键点击 zip 文件 → 解压到当前文件夹
   # 或使用命令行
   Expand-Archive postmock-0.1.0-windows-x64-portable.zip
   ```

2. **运行应用**
   - 双击 `postmock.exe` 启动应用
   - 或双击 `postmock.bat` 启动（会在后台运行）
   - 或从命令行运行：
     ```powershell
     cd postmock-0.1.0-windows-x64-portable
     .\postmock.exe
     ```

3. **创建桌面快捷方式**（可选）
   - 右键点击 `postmock.exe`
   - 选择"发送到" → "桌面快捷方式"

### 数据存储位置
```
%APPDATA%\postmock\
```
通常是：`C:\Users\YourName\AppData\Roaming\postmock\`

### 卸载
直接删除解压的文件夹即可。如需删除数据：
```powershell
Remove-Item -Recurse -Force $env:APPDATA\postmock
```

## Linux 便携版

### 系统要求
- Linux x64（Ubuntu 22.04+ 或同等版本）
- GTK 3.24+
- WebKit2GTK 4.1+

### 使用方法

1. **解压文件**
   ```bash
   tar -xzf postmock-0.1.0-linux-x64-portable.tar.gz
   cd postmock-0.1.0-linux-x64-portable
   ```

2. **运行应用**
   ```bash
   # 方式 1: 直接运行二进制文件
   ./postmock
   
   # 方式 2: 使用启动脚本
   ./postmock.sh
   
   # 方式 3: 后台运行
   ./postmock &
   ```

3. **添加到应用程序菜单**（可选）
   ```bash
   # 创建 desktop 文件
   cat > ~/.local/share/applications/postmock.desktop << EOF
   [Desktop Entry]
   Version=1.0
   Type=Application
   Name=PostMock
   Comment=Modern API testing tool
   Exec=/path/to/postmock-0.1.0-linux-x64-portable/postmock
   Icon=/path/to/postmock-0.1.0-linux-x64-portable/icon.png
   Terminal=false
   Categories=Development;Network;
   EOF
   
   # 更新桌面数据库
   update-desktop-database ~/.local/share/applications
   ```

4. **添加到 PATH**（可选）
   ```bash
   # 添加到 ~/.bashrc 或 ~/.zshrc
   export PATH="$PATH:/path/to/postmock-0.1.0-linux-x64-portable"
   
   # 或创建符号链接
   sudo ln -s /path/to/postmock-0.1.0-linux-x64-portable/postmock /usr/local/bin/postmock
   ```

### 数据存储位置
```
~/.local/share/postmock/
```

### 卸载
```bash
# 删除应用文件
rm -rf postmock-0.1.0-linux-x64-portable

# 删除数据（可选）
rm -rf ~/.local/share/postmock

# 删除 desktop 文件（如果创建了）
rm ~/.local/share/applications/postmock.desktop
update-desktop-database ~/.local/share/applications
```

## 便携版 vs 安装版

### 便携版优势
- ✅ 无需安装，解压即用
- ✅ 可以放在 U 盘或移动硬盘
- ✅ 不修改系统注册表（Windows）
- ✅ 易于完全卸载
- ✅ 可以同时运行多个版本

### 便携版限制
- ❌ 不会自动添加到开始菜单/应用程序菜单
- ❌ 不会创建桌面快捷方式
- ❌ 不会关联文件类型
- ❌ 不会自动更新
- ❌ 需要手动管理依赖（Linux）

### 推荐使用场景

**使用便携版：**
- 测试新版本
- 在多台电脑上使用
- 不想安装到系统
- 需要同时运行多个版本
- 临时使用

**使用安装版：**
- 日常主力使用
- 需要系统集成（开始菜单、文件关联等）
- 希望自动更新
- 不想手动管理

## 常见问题

### Windows: 缺少 WebView2 Runtime

如果启动时提示缺少 WebView2，请下载安装：
https://developer.microsoft.com/en-us/microsoft-edge/webview2/

### Linux: 缺少依赖库

```bash
# Ubuntu/Debian
sudo apt-get install libwebkit2gtk-4.1-0 libgtk-3-0

# Fedora
sudo dnf install webkit2gtk4.1 gtk3

# Arch Linux
sudo pacman -S webkit2gtk gtk3
```

### 应用无法启动

1. **检查权限**（Linux）
   ```bash
   chmod +x postmock
   ```

2. **查看错误日志**
   - Windows: 在命令行运行查看错误信息
   - Linux: 在终端运行查看错误信息

3. **检查系统要求**
   - 确保操作系统版本符合要求
   - 确保已安装必要的依赖

### 数据迁移

从安装版迁移到便携版（或反之）：

**Windows:**
```powershell
# 数据位置相同，无需迁移
%APPDATA%\postmock\
```

**Linux:**
```bash
# 数据位置相同，无需迁移
~/.local/share/postmock/
```

## 更新便携版

1. 下载新版本的便携版
2. 解压到新位置（或覆盖旧版本）
3. 数据会自动保留（存储在用户目录）

## 技术支持

如有问题，请访问：
- GitHub Issues: https://github.com/duwei0227/postmock/issues
- 文档: https://github.com/duwei0227/postmock#使用指南
