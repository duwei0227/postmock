# 元数据配置状态

## 当前状态总览

✅ = 已配置  
⚠️ = 部分配置  
❌ = 未配置

## Windows 安装包

### MSI (Windows Installer)
- ✅ 产品名称：PostMock
- ✅ 版本号：0.1.0
- ✅ 发布者：duwei0227
- ✅ 描述：Modern API testing tool
- ✅ 详细描述：完整功能说明
- ✅ 版权信息：Copyright © 2024 duwei0227
- ✅ 许可证：MIT (LICENSE 文件)
- ✅ 主页：https://github.com/duwei0227/postmock
- ✅ 图标：icon.ico
- ✅ 多语言：英语、简体中文
- ❌ 代码签名：未配置（需要证书）

### NSIS 安装包
- ✅ 产品名称：PostMock
- ✅ 版本号：0.1.0
- ✅ 发布者：duwei0227
- ✅ 许可证：MIT (LICENSE 文件)
- ✅ 多语言：英语、简体中文
- ✅ 图标：icon.ico
- ❌ 代码签名：未配置（需要证书）

**显示位置：**
- 控制面板 → 程序和功能
- 设置 → 应用 → 已安装的应用
- 安装向导界面

## macOS 安装包

### DMG (磁盘映像)
- ✅ 应用名称：PostMock.app
- ✅ 版本号：0.1.0
- ✅ Bundle ID：cn.probiecoder.postmock
- ✅ 版权信息：Copyright © 2024 duwei0227
- ✅ 分类：DeveloperTool
- ✅ 最低系统版本：macOS 10.13
- ✅ 图标：icon.icns
- ❌ 代码签名：未配置（需要 Apple Developer 账号）
- ❌ 公证：未配置（需要 Apple Developer 账号）

**显示位置：**
- Finder → 应用程序
- 系统信息 → 应用程序
- 关于本机

## Linux 安装包

### DEB (Debian/Ubuntu)
- ✅ 包名：postmock
- ✅ 版本号：0.1.0
- ✅ 维护者：duwei0227
- ✅ 描述：Modern API testing tool
- ✅ 详细描述：完整功能说明
- ✅ 主页：https://github.com/duwei0227/postmock
- ✅ 分类：Development
- ✅ 优先级：optional
- ✅ Desktop 文件：postmock.desktop
- ✅ 图标：内嵌

**显示位置：**
- `apt show postmock`
- GNOME Software / Ubuntu Software
- 应用程序菜单

### RPM (Fedora/RHEL/CentOS)
- ✅ 包名：postmock
- ✅ 版本号：0.1.0
- ✅ Release：1
- ✅ 摘要：Modern API testing tool
- ✅ 描述：完整功能说明
- ✅ 许可证：MIT
- ✅ URL：https://github.com/duwei0227/postmock
- ✅ 分组：Development/Tools
- ✅ Desktop 文件：postmock.desktop
- ✅ 图标：内嵌

**显示位置：**
- `rpm -qi postmock`
- `dnf info postmock`
- GNOME Software
- 应用程序菜单

### AppImage
- ✅ 应用名称：PostMock
- ✅ 版本号：0.1.0
- ✅ Desktop 文件：内嵌
- ✅ 图标：内嵌
- ⚠️ 元数据：基本信息（受限于格式）

**显示位置：**
- 文件属性
- 应用程序菜单（如果集成）

### Flatpak
- ✅ 应用 ID：cn.probiecoder.postmock
- ✅ 名称：PostMock
- ✅ 摘要：Modern API testing tool
- ✅ 详细描述：完整的功能列表和介绍
- ⚠️ 截图：已配置 3 张（需要添加实际图片）
  - main.png
  - collections.png
  - environment.png
- ✅ 发布历史：v0.1.0 (2024-03-04)
- ✅ 分类：Development, Network
- ✅ 关键词：api, http, rest, testing, postman
- ✅ 许可证：MIT
- ✅ 主页：https://github.com/duwei0227/postmock
- ✅ 问题追踪：https://github.com/duwei0227/postmock/issues
- ✅ 帮助文档：https://github.com/duwei0227/postmock#使用指南
- ✅ 开发者：duwei0227

**显示位置：**
- Flathub 网站（发布后）
- GNOME Software
- KDE Discover
- `flatpak info cn.probiecoder.postmock`
- 应用程序菜单

## 待完成项

### 高优先级
1. ⚠️ **添加应用截图**
   - 创建 screenshots/main.png
   - 创建 screenshots/collections.png
   - 创建 screenshots/environment.png
   - 推荐尺寸：1600x900 或 1920x1080

### 中优先级
2. ⚠️ **更新 README 添加截图展示**
   - 在 README.md 中添加截图
   - 展示主要功能

3. ⚠️ **完善发布说明**
   - 每次发布时更新 CHANGELOG.md
   - 更新 Flatpak metainfo.xml 的 releases 部分

### 低优先级（可选）
4. ❌ **代码签名**（Windows/macOS）
   - Windows: 需要代码签名证书
   - macOS: 需要 Apple Developer 账号和证书

5. ❌ **发布到应用商店**
   - Flathub（Linux）
   - Microsoft Store（Windows）
   - Mac App Store（macOS）

## 元数据完整性评分

| 平台 | 完整性 | 说明 |
|------|--------|------|
| Windows MSI | 90% | 缺少代码签名 |
| Windows NSIS | 90% | 缺少代码签名 |
| macOS DMG | 85% | 缺少代码签名和公证 |
| Linux DEB | 100% | 完整配置 |
| Linux RPM | 100% | 完整配置 |
| Linux AppImage | 95% | 格式限制 |
| Flatpak | 95% | 需要添加实际截图 |

**总体评分：93%**

## 验证方法

运行验证脚本：
```bash
./scripts/validate-metadata.sh
```

## 更新流程

发布新版本时：
1. 更新版本号（3 个文件）
2. 更新 CHANGELOG.md
3. 更新 Flatpak metainfo.xml
4. 添加/更新截图（如需要）
5. 运行验证脚本
6. 提交并创建 tag

详见：[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
