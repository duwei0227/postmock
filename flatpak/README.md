# Flatpak 配置

这个目录包含了构建 PostMock Flatpak 包所需的文件。

## 文件说明

- `cn.probiecoder.postmock.desktop` - 桌面入口文件
- `cn.probiecoder.postmock.metainfo.xml` - AppStream 元数据

## 本地构建

### 安装依赖

```bash
sudo apt install flatpak flatpak-builder
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.freedesktop.Platform//23.08 org.freedesktop.Sdk//23.08
```

### 构建 Flatpak

```bash
# 从项目根目录运行
flatpak-builder --force-clean build-dir cn.probiecoder.postmock.yml
```

### 安装并测试

```bash
# 安装到用户目录
flatpak-builder --user --install --force-clean build-dir cn.probiecoder.postmock.yml

# 运行应用
flatpak run cn.probiecoder.postmock
```

### 导出为 .flatpak 文件

```bash
flatpak-builder --repo=repo --force-clean build-dir cn.probiecoder.postmock.yml
flatpak build-bundle repo postmock.flatpak cn.probiecoder.postmock
```

## 发布到 Flathub

查看 [.github/FLATHUB.md](../.github/FLATHUB.md) 了解如何将应用发布到 Flathub。

## 权限说明

应用请求的权限：

- `--share=ipc` - 进程间通信
- `--socket=fallback-x11` - X11 显示（回退）
- `--socket=wayland` - Wayland 显示
- `--device=dri` - GPU 加速
- `--share=network` - 网络访问（API 测试必需）
- `--filesystem=home` - 访问用户主目录（保存请求数据）

## 更新元数据

发布新版本时，记得更新：

1. `cn.probiecoder.postmock.metainfo.xml` 中的 `<releases>` 部分
2. 根目录的 `cn.probiecoder.postmock.yml` 中的版本和 SHA256

## 验证

```bash
# 验证 desktop 文件
desktop-file-validate flatpak/cn.probiecoder.postmock.desktop

# 验证 AppStream 元数据
appstream-util validate flatpak/cn.probiecoder.postmock.metainfo.xml
```
