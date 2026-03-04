# 安装包元数据配置

本文档说明各平台安装包的元数据配置情况。

## 配置文件位置

### 通用配置
- **src-tauri/tauri.conf.json** - 主配置文件，包含所有平台的元数据
- **src-tauri/Cargo.toml** - Rust 包配置，包含描述、作者、许可证等
- **package.json** - Node.js 包配置，包含版本号和基本信息
- **LICENSE** - MIT 许可证文件

### 平台特定配置
- **src-tauri/postmock.desktop** - Linux desktop 入口文件
- **flatpak/cn.probiecoder.postmock.metainfo.xml** - Flatpak AppStream 元数据
- **flatpak/cn.probiecoder.postmock.desktop** - Flatpak desktop 文件

## 各平台元数据说明

### Windows

#### MSI 安装包
配置位置：`tauri.conf.json` → `bundle.windows.wix`

包含的元数据：
- ✅ 产品名称：PostMock
- ✅ 版本号：从 tauri.conf.json 读取
- ✅ 发布者：duwei0227
- ✅ 描述：shortDescription 和 longDescription
- ✅ 版权信息：Copyright © 2024 duwei0227
- ✅ 许可证：LICENSE 文件
- ✅ 主页：https://github.com/duwei0227/postmock
- ✅ 图标：icon.ico
- ✅ 语言：英语、简体中文

显示位置：
- 控制面板 → 程序和功能
- 设置 → 应用 → 已安装的应用
- 安装向导

#### NSIS 安装包
配置位置：`tauri.conf.json` → `bundle.windows.nsis`

包含的元数据：
- ✅ 产品名称：PostMock
- ✅ 版本号：从 tauri.conf.json 读取
- ✅ 发布者：duwei0227
- ✅ 许可证：LICENSE 文件
- ✅ 语言选择：英语、简体中文
- ✅ 图标：icon.ico

显示位置：
- 安装向导
- 卸载程序

### macOS

#### DMG 安装包
配置位置：`tauri.conf.json` → `bundle.macOS`

包含的元数据：
- ✅ 应用名称：PostMock.app
- ✅ 版本号：从 tauri.conf.json 读取
- ✅ Bundle ID：cn.probiecoder.postmock
- ✅ 版权信息：Copyright © 2024 duwei0227
- ✅ 分类：DeveloperTool
- ✅ 最低系统版本：macOS 10.13
- ✅ 图标：icon.icns

显示位置：
- Finder → 应用程序
- 系统信息 → 应用程序
- 关于本机

Info.plist 包含：
- CFBundleName
- CFBundleDisplayName
- CFBundleIdentifier
- CFBundleVersion
- CFBundleShortVersionString
- NSHumanReadableCopyright
- LSApplicationCategoryType

### Linux

#### DEB 包（Debian/Ubuntu）
配置位置：`tauri.conf.json` → `bundle.linux.deb`

包含的元数据：
- ✅ 包名：postmock
- ✅ 版本号：从 tauri.conf.json 读取
- ✅ 维护者：duwei0227
- ✅ 描述：shortDescription 和 longDescription
- ✅ 主页：https://github.com/duwei0227/postmock
- ✅ 分类：Development
- ✅ 优先级：optional
- ✅ Desktop 文件：postmock.desktop

显示位置：
- `apt show postmock`
- 软件中心（如 GNOME Software）
- 应用程序菜单

#### RPM 包（Fedora/RHEL/CentOS）
配置位置：`tauri.conf.json` → `bundle.linux.rpm`

包含的元数据：
- ✅ 包名：postmock
- ✅ 版本号：从 tauri.conf.json 读取
- ✅ Release：1
- ✅ 摘要：shortDescription
- ✅ 描述：longDescription
- ✅ 许可证：MIT
- ✅ URL：https://github.com/duwei0227/postmock
- ✅ 分组：Development/Tools
- ✅ Desktop 文件：postmock.desktop

显示位置：
- `rpm -qi postmock`
- `dnf info postmock`
- GNOME Software
- 应用程序菜单

#### AppImage
配置位置：`tauri.conf.json` → `bundle.linux.appimage`

包含的元数据：
- ✅ 应用名称：PostMock
- ✅ 版本号：从 tauri.conf.json 读取
- ✅ Desktop 文件：内嵌
- ✅ 图标：内嵌

显示位置：
- 文件属性
- 应用程序菜单（如果集成）

#### Flatpak
配置位置：
- `cn.probiecoder.postmock.yml` - Flatpak manifest
- `flatpak/cn.probiecoder.postmock.metainfo.xml` - AppStream 元数据
- `flatpak/cn.probiecoder.postmock.desktop` - Desktop 文件

包含的元数据：
- ✅ 应用 ID：cn.probiecoder.postmock
- ✅ 名称：PostMock
- ✅ 摘要：Modern API testing tool
- ✅ 详细描述：完整的功能列表和介绍
- ✅ 截图：3 张（main, collections, environment）
- ✅ 发布历史：包含版本号、日期、变更说明
- ✅ 分类：Development, Network
- ✅ 关键词：api, http, rest, testing, postman
- ✅ 许可证：MIT
- ✅ 主页、问题追踪、帮助链接
- ✅ 开发者信息

显示位置：
- Flathub 网站
- GNOME Software
- KDE Discover
- `flatpak info cn.probiecoder.postmock`
- 应用程序菜单

## 元数据完整性检查

### 必需字段（所有平台）
- [x] 应用名称
- [x] 版本号
- [x] 描述（短描述和长描述）
- [x] 发布者/维护者
- [x] 许可证
- [x] 主页 URL
- [x] 图标

### 推荐字段
- [x] 版权信息
- [x] 分类
- [x] 关键词
- [ ] 截图（需要添加实际截图）
- [x] 发布历史（Flatpak）
- [ ] 更新日志 URL

### 可选字段
- [ ] 代码签名（Windows/macOS）
- [ ] 公证（macOS）
- [ ] 帮助文档 URL
- [ ] 支持 URL
- [ ] 捐赠 URL

## 验证方法

### Windows
```powershell
# 查看 MSI 属性
msiexec /i postmock.msi /qn /l*v install.log
Get-Content install.log | Select-String "Property"
```

### macOS
```bash
# 查看应用信息
mdls -name kMDItemDisplayName -name kMDItemVersion PostMock.app
plutil -p PostMock.app/Contents/Info.plist
```

### Linux DEB
```bash
# 查看包信息
dpkg-deb -I postmock_0.1.0_amd64.deb
apt-cache show postmock
```

### Linux RPM
```bash
# 查看包信息
rpm -qip postmock-0.1.0-1.x86_64.rpm
rpm -qi postmock
```

### Flatpak
```bash
# 验证 AppStream 元数据
appstream-util validate flatpak/cn.probiecoder.postmock.metainfo.xml

# 查看已安装的应用信息
flatpak info cn.probiecoder.postmock
```

## 更新元数据

当发布新版本时，需要更新以下文件：

1. **版本号**（3 个文件）：
   - package.json
   - src-tauri/Cargo.toml
   - src-tauri/tauri.conf.json

2. **变更日志**：
   - CHANGELOG.md

3. **Flatpak 发布信息**：
   - flatpak/cn.probiecoder.postmock.metainfo.xml
   ```bash
   ./scripts/update-metainfo.sh 0.2.0 "Added new features"
   ```

4. **截图**（如有更新）：
   - screenshots/ 目录

## 最佳实践

1. **保持一致性**：所有平台使用相同的描述和版本号
2. **本地化**：提供多语言支持（至少英语和中文）
3. **详细描述**：清楚说明应用功能和用途
4. **截图**：提供高质量的应用截图
5. **发布说明**：每个版本都应有详细的变更说明
6. **许可证**：明确标注开源许可证
7. **联系方式**：提供问题反馈和支持渠道

## 参考资料

- [Tauri Bundle Configuration](https://tauri.app/v1/api/config/#bundleconfig)
- [AppStream Metadata Guidelines](https://www.freedesktop.org/software/appstream/docs/)
- [Flatpak Manifest](https://docs.flatpak.org/en/latest/manifests.html)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/latest/)
