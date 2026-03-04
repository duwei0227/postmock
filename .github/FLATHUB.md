# Flathub 发布指南

## 前置条件

1. 在 [Flathub](https://flathub.org) 创建账号
2. Fork [flathub/flathub](https://github.com/flathub/flathub) 仓库
3. 准备好应用的截图（放在 `screenshots/` 目录）

## 首次提交到 Flathub

### 1. 创建 Flathub 仓库

在 GitHub 上创建新仓库：`flathub/cn.probiecoder.postmock`

### 2. 准备文件

将以下文件复制到 Flathub 仓库：

```bash
# 克隆 Flathub 仓库
git clone https://github.com/flathub/cn.probiecoder.postmock.git
cd cn.probiecoder.postmock

# 从主仓库复制文件
cp /path/to/postmock/cn.probiecoder.postmock.yml .
cp /path/to/postmock/flatpak/cn.probiecoder.postmock.desktop .
cp /path/to/postmock/flatpak/cn.probiecoder.postmock.metainfo.xml .
cp -r /path/to/postmock/src-tauri/icons .
```

### 3. 更新 manifest

编辑 `cn.probiecoder.postmock.yml`，确保：

- `url` 指向最新的 release
- `sha256` 是正确的（从 GitHub Actions 日志获取）
- 版本号正确

### 4. 添加 flathub.json

创建 `flathub.json`：

```json
{
  "only-arches": ["x86_64"]
}
```

### 5. 提交到 Flathub

```bash
git add .
git commit -m "Initial commit for PostMock"
git push origin master
```

### 6. 创建 Pull Request

1. 访问 https://github.com/flathub/flathub
2. 创建 Pull Request，将你的仓库添加到 Flathub
3. 在 PR 中说明应用信息

## 更新已发布的应用

### 自动更新（推荐）

使用 GitHub Actions 自动更新 Flathub manifest：

1. 在 Flathub 仓库添加 GitHub Actions workflow
2. 当主仓库发布新版本时，自动创建 PR 到 Flathub

### 手动更新

1. 克隆 Flathub 仓库
2. 更新 `cn.probiecoder.postmock.yml` 中的版本和 SHA256
3. 更新 `cn.probiecoder.postmock.metainfo.xml` 中的 release 信息
4. 提交并推送

```bash
cd cn.probiecoder.postmock
# 更新文件...
git add .
git commit -m "Update to version X.Y.Z"
git push origin master
```

## 测试 Flatpak

在本地测试构建：

```bash
# 安装 flatpak-builder
sudo apt install flatpak-builder

# 构建
flatpak-builder --force-clean build-dir cn.probiecoder.postmock.yml

# 安装并运行
flatpak-builder --user --install --force-clean build-dir cn.probiecoder.postmock.yml
flatpak run cn.probiecoder.postmock
```

## 注意事项

1. **截图要求**：
   - 至少一张截图
   - 推荐尺寸：1600x900 或 1920x1080
   - PNG 格式
   - 放在公开可访问的 URL

2. **AppStream 元数据**：
   - 必须通过 `appstream-util validate` 验证
   - 包含完整的应用描述

3. **权限**：
   - 只请求必要的权限
   - 在 `finish-args` 中明确声明

4. **构建时间**：
   - Flathub 构建可能需要 30-60 分钟
   - 首次提交需要人工审核

## 相关链接

- [Flathub 文档](https://docs.flathub.org/)
- [Flatpak 构建器文档](https://docs.flatpak.org/en/latest/flatpak-builder.html)
- [AppStream 规范](https://www.freedesktop.org/software/appstream/docs/)
