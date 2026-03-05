# Tauri Updater 快速启动指南

## 当前状态

✅ 已完成的配置：
- 安装了 `tauri-plugin-updater` 和 `@tauri-apps/plugin-process`
- 创建了 `UpdateDialog.vue` 组件
- 修改了 `Navbar.vue` 以支持更新检查
- 配置了 `tauri.conf.json` 的 updater 部分
- 添加了权限配置到 `capabilities/default.json`
- 修改了 GitHub Actions 工作流以生成更新清单

⚠️ 需要完成的步骤：
1. 生成签名密钥对
2. 配置公钥到 `tauri.conf.json`
3. 配置 GitHub Secrets

## 完成设置步骤

### 步骤 1: 生成签名密钥

在项目根目录运行：

```bash
npm run tauri signer generate -- -w ~/.tauri/postmock.key
```

- 会提示输入密码（可选，但推荐设置）
- 生成后会在终端显示公钥
- 私钥保存在 `~/.tauri/postmock.key`

**重要**: 
- 复制终端显示的公钥（以 `dW50cnVzdGVk` 开头的长字符串）
- 妥善保管私钥文件，不要提交到 Git

### 步骤 2: 配置公钥

编辑 `src-tauri/tauri.conf.json`，找到：

```json
"plugins": {
  "updater": {
    "pubkey": "REPLACE_WITH_YOUR_PUBLIC_KEY",
```

将 `REPLACE_WITH_YOUR_PUBLIC_KEY` 替换为步骤 1 中生成的公钥。

### 步骤 3: 配置 GitHub Secrets

1. 进入 GitHub 仓库页面
2. 点击 Settings → Secrets and variables → Actions
3. 点击 "New repository secret"
4. 添加以下 secrets：

**TAURI_SIGNING_PRIVATE_KEY**
- Name: `TAURI_SIGNING_PRIVATE_KEY`
- Value: 私钥文件的完整内容
  ```bash
  cat ~/.tauri/postmock.key
  ```
  复制输出的全部内容

**TAURI_SIGNING_PRIVATE_KEY_PASSWORD** (如果设置了密码)
- Name: `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`
- Value: 你设置的密码

### 步骤 4: 测试更新功能

1. 提交并推送代码：
   ```bash
   git add .
   git commit -m "feat: add auto-update functionality"
   git push
   ```

2. 创建并推送新版本标签：
   ```bash
   # 先更新 package.json 中的版本号为 0.2.0
   git tag v0.2.0
   git push origin v0.2.0
   ```

3. GitHub Actions 会自动：
   - 构建所有平台的安装包
   - 生成签名文件
   - 创建 `latest.json` 更新清单
   - 发布到 GitHub Release

4. 在应用中测试：
   - 运行应用（版本 0.1.0）
   - 点击 Help → Check For Update
   - 应该检测到 0.2.0 版本
   - 点击 "Install Update" 下载并安装

## 更新清单格式

GitHub Actions 会自动生成 `latest.json` 文件，格式如下：

```json
{
  "version": "0.2.0",
  "notes": "更新日志内容",
  "pub_date": "2024-03-05T10:00:00Z",
  "platforms": {
    "linux-x86_64": {
      "signature": "...",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/..."
    },
    "windows-x86_64": {
      "signature": "...",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/..."
    },
    "darwin-x86_64": {
      "signature": "...",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/..."
    },
    "darwin-aarch64": {
      "signature": "...",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.2.0/..."
    }
  }
}
```

## 用户体验流程

1. 用户点击 "Help → Check For Update"
2. 应用请求 `latest.json` 检查更新
3. 如果有新版本：
   - 显示更新对话框
   - 展示版本号、发布日期和更新日志
   - 用户可选择 "Install Update" 或 "Cancel"
4. 点击 "Install Update"：
   - 显示下载进度条
   - 下载完成后验证签名
   - 自动安装更新
   - 重启应用

## 故障排除

### 问题：签名验证失败

**原因**: 公钥配置不正确或私钥不匹配

**解决**:
1. 确认 `tauri.conf.json` 中的公钥与生成的公钥一致
2. 确认 GitHub Secrets 中的私钥内容完整
3. 重新生成密钥对并更新配置

### 问题：无法检测到更新

**原因**: `latest.json` 文件不存在或格式错误

**解决**:
1. 检查 GitHub Release 中是否有 `latest.json` 文件
2. 下载并验证 JSON 格式是否正确
3. 检查 GitHub Actions 工作流日志

### 问题：下载失败

**原因**: 网络问题或文件 URL 不正确

**解决**:
1. 检查网络连接
2. 验证 `latest.json` 中的 URL 是否可访问
3. 确认文件在 GitHub Release 中存在

## 安全注意事项

1. ⚠️ 私钥必须保密，不要泄露
2. ⚠️ 定期备份私钥文件
3. ⚠️ 使用强密码保护私钥
4. ✅ 仅在 HTTPS 端点上提供更新
5. ✅ 定期检查 GitHub Secrets 的访问权限

## 参考文档

- [Tauri Updater 官方文档](https://v2.tauri.app/plugin/updater/)
- [详细设置指南](.github/UPDATER_SETUP.md)
- [GitHub Actions 工作流](.github/workflows/release.yml)

## 下一步

完成上述步骤后，你的应用就具备了自动更新功能。每次发布新版本时：

1. 更新 `package.json` 中的版本号
2. 更新 `CHANGELOG.md`（可选，会自动从 Git commits 生成）
3. 创建并推送版本标签
4. GitHub Actions 自动构建和发布
5. 用户可以通过应用内更新功能升级
