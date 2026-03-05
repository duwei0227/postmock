# Tauri 自动更新快速启动指南

> ✅ 状态：已配置并验证可用
> 📅 最后更新：2026-03-05

## 快速概览

PostMock 已成功配置 Tauri 自动更新功能。本文档提供快速参考。

## 已完成的配置

### 1. 依赖安装 ✅
- `tauri-plugin-updater`
- `@tauri-apps/plugin-updater`
- `@tauri-apps/plugin-process`

### 2. 签名密钥配置 ✅
- 公钥：已配置在 `src-tauri/tauri.conf.json`
- 私钥：已配置在 GitHub Secrets (`TAURI_SIGNING_PRIVATE_KEY`)
- 格式：base64 编码的文件内容

**详细说明：** 参见 [签名密钥配置指南](SIGNING_KEYS_GUIDE.md)

### 3. Tauri 配置 ✅
```json
{
  "bundle": {
    "createUpdaterArtifacts": true
  },
  "plugins": {
    "updater": {
      "pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6...",
      "endpoints": [
        "https://github.com/duwei0227/postmock/releases/latest/download/latest.json"
      ]
    }
  }
}
```

### 4. 权限配置 ✅
`src-tauri/capabilities/default.json`:
```json
{
  "permissions": [
    "updater:default"
  ]
}
```

### 5. UI 组件 ✅
- `src/components/UpdateDialog.vue` - 更新对话框
- `src/components/Navbar.vue` - 集成更新检查

### 6. GitHub Actions ✅
- `.github/workflows/release.yml` - 自动构建和发布
- 自动生成签名文件 (`.sig`)
- 自动生成更新清单 (`latest.json`)

## 使用方法

### 检查更新

用户可以通过以下方式检查更新：
1. 菜单：Help → Check for Updates
2. 应用启动时自动检查（可选）

### 发布新版本

1. 更新版本号：
   ```bash
   # 更新 package.json 和 src-tauri/Cargo.toml 中的版本号
   ```

2. 创建并推送 tag：
   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

3. GitHub Actions 自动执行：
   - 构建所有平台的安装包
   - 生成签名文件
   - 创建 GitHub Release
   - 上传更新清单

4. 用户自动收到更新通知

## 密钥管理

### 查看当前公钥
```bash
cat src-tauri/tauri.conf.json | grep -A 1 "pubkey"
```

### 重新生成密钥（如需要）
```bash
# 1. 生成新密钥
npm run tauri signer generate -- -w ./postmock-new.key

# 2. 更新配置
# - 复制 postmock-new.key.pub 内容到 tauri.conf.json
# - 复制 postmock-new.key 内容到 GitHub Secret

# 3. 提交更改
git add src-tauri/tauri.conf.json
git commit -m "chore: update signing keys"
git push
```

**详细步骤：** 参见 [签名密钥配置指南](SIGNING_KEYS_GUIDE.md)

## 故障排除

### 常见问题

1. **更新检查失败**
   - 首次发布前是正常的（没有 latest.json）
   - 检查网络连接
   - 查看浏览器控制台错误

2. **签名验证失败**
   - 确认公钥和私钥匹配
   - 参考 [快速修复指南](QUICK_FIX_SIGNING_ERROR.md)

3. **GitHub Actions 构建失败**
   - 检查 GitHub Secret 配置
   - 查看 Actions 日志
   - 参考 [故障排除指南](TROUBLESHOOTING.md)

## 相关文档

- **[签名密钥配置指南](SIGNING_KEYS_GUIDE.md)** - 详细的密钥生成和配置流程 ⭐
- [完整设置指南](UPDATER_SETUP.md) - 详细的功能实现说明
- [GitHub Secrets 配置](GITHUB_SECRETS_SETUP.md) - Secrets 配置步骤
- [故障排除](TROUBLESHOOTING.md) - 常见问题解决方案
- [快速修复签名错误](QUICK_FIX_SIGNING_ERROR.md) - 签名问题快速修复

## 技术栈

- Tauri v2 Updater Plugin
- Minisign 签名机制
- GitHub Actions
- GitHub Releases

---

**状态：** ✅ 生产就绪
**维护者：** duwei0227
**最后验证：** 2026-03-05
