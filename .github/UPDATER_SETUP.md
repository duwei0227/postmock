# Tauri Updater 设置指南

本文档说明如何为 PostMock 应用配置自动更新功能。

## 参考文档

- [Tauri Updater 官方文档](https://v2.tauri.app/plugin/updater/)
- 查询时间：2026-03-05

## 1. 生成签名密钥

Tauri 更新器需要签名密钥来验证更新的真实性。

### 生成密钥对

```bash
npm run tauri signer generate -- -w ~/.tauri/postmock.key
```

执行此命令时会提示输入密码（可选）。生成后会得到：
- 私钥文件：`~/.tauri/postmock.key`
- 公钥：在终端输出中显示

### 重要提示

⚠️ **私钥安全**
- 私钥文件 `~/.tauri/postmock.key` 必须妥善保管
- 不要将私钥提交到版本控制系统
- 如果丢失私钥，将无法为已安装的应用发布更新

✅ **公钥使用**
- 公钥可以安全地公开
- 需要将公钥添加到 `src-tauri/tauri.conf.json` 配置中

## 2. 配置环境变量

### 本地开发

在项目根目录创建 `.env` 文件（不要提交到 Git）：

```bash
# 私钥路径或内容
TAURI_SIGNING_PRIVATE_KEY="path/to/your/private/key"

# 如果设置了密码
TAURI_SIGNING_PRIVATE_KEY_PASSWORD="your_password"
```

### GitHub Actions

在 GitHub 仓库设置中添加以下 Secrets：

1. 进入仓库 Settings → Secrets and variables → Actions
2. 添加以下 secrets：
   - `TAURI_SIGNING_PRIVATE_KEY`: 私钥文件的完整内容
   - `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`: 密钥密码（如果设置了）

## 3. 配置 tauri.conf.json

在 `src-tauri/tauri.conf.json` 中添加 updater 配置：

```json
{
  "bundle": {
    "createUpdaterArtifacts": true
  },
  "plugins": {
    "updater": {
      "pubkey": "YOUR_PUBLIC_KEY_HERE",
      "endpoints": [
        "https://github.com/duwei0227/postmock/releases/latest/download/latest.json"
      ]
    }
  }
}
```

将 `YOUR_PUBLIC_KEY_HERE` 替换为步骤 1 中生成的公钥。

## 4. 更新 GitHub Actions 工作流

工作流已配置为：
1. 自动生成更新清单文件 `latest.json`
2. 为所有平台生成签名文件（`.sig`）
3. 将更新清单和签名文件上传到 GitHub Release

## 5. 更新清单格式

`latest.json` 文件格式：

```json
{
  "version": "0.2.0",
  "notes": "Release notes here",
  "pub_date": "2026-03-05T10:00:00Z",
  "platforms": {
    "linux-x86_64": {
      "signature": "signature_content_here",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/postmock_0.2.0_amd64.AppImage"
    },
    "windows-x86_64": {
      "signature": "signature_content_here",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/postmock_0.2.0_x64-setup.exe"
    },
    "darwin-x86_64": {
      "signature": "signature_content_here",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/postmock_x64.app.tar.gz"
    },
    "darwin-aarch64": {
      "signature": "signature_content_here",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/postmock_aarch64.app.tar.gz"
    }
  }
}
```

## 6. 测试更新流程

### 本地测试

1. 构建应用：
   ```bash
   npm run tauri build
   ```

2. 检查生成的文件：
   - 更新包：`src-tauri/target/release/bundle/`
   - 签名文件：`.sig` 文件

### 发布测试

1. 创建新版本标签：
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

2. GitHub Actions 会自动：
   - 构建所有平台的安装包
   - 生成签名文件
   - 创建 `latest.json`
   - 发布到 GitHub Release

3. 在应用中点击 "Help → Check For Update" 测试更新检测

## 7. 用户更新流程

1. 用户点击 "Help → Check For Update"
2. 应用检查 GitHub Release 中的 `latest.json`
3. 如果有新版本：
   - 显示更新对话框
   - 展示版本号和更新日志
   - 用户可选择立即更新或稍后
4. 点击"Install Update"：
   - 下载更新包
   - 验证签名
   - 安装更新
   - 重启应用

## 8. 权限配置

确保 `src-tauri/capabilities/default.json` 包含 updater 权限：

```json
{
  "permissions": [
    "updater:default"
  ]
}
```

## 故障排除

### 签名验证失败

- 确保公钥配置正确
- 检查私钥环境变量是否设置
- 验证签名文件是否正确生成

### 无法检测更新

- 检查 `latest.json` 文件是否可访问
- 验证 JSON 格式是否正确
- 确保版本号格式符合 SemVer 规范

### 下载失败

- 检查网络连接
- 验证下载 URL 是否正确
- 确保文件在 GitHub Release 中存在

## 安全注意事项

1. 私钥必须保密，不要泄露
2. 定期备份私钥文件
3. 使用强密码保护私钥
4. 仅在 HTTPS 端点上提供更新
5. 定期轮换密钥（可选）

## 参考链接

- [Tauri Updater 文档](https://v2.tauri.app/plugin/updater/)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [SemVer 规范](https://semver.org/)
