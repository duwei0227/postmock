# 签名密钥配置速查卡

> 📋 快速参考 - 打印或保存此页面以便快速查找  
> 📅 最后更新：2024-03-05

---

## 🚀 快速配置（3 步）

### 1️⃣ 生成密钥对

```bash
npm run tauri signer generate -- -w ./postmock.key
# 提示输入密码时，按两次 Enter（不设置密码）
```

**输出文件：**
- `postmock.key` - 私钥（保密！）
- `postmock.key.pub` - 公钥

---

### 2️⃣ 配置公钥

```bash
# 复制公钥内容
cat postmock.key.pub
```

**粘贴到：** `src-tauri/tauri.conf.json`

```json
{
  "plugins": {
    "updater": {
      "pubkey": "粘贴这里",
      "endpoints": [...]
    }
  }
}
```

---

### 3️⃣ 配置私钥

```bash
# 复制私钥内容
cat postmock.key
```

**粘贴到：** GitHub Settings → Secrets → Actions

- **Name:** `TAURI_SIGNING_PRIVATE_KEY`
- **Value:** 粘贴复制的内容

---

## 📋 格式速查

| 项目 | 格式 | 示例开头 |
|------|------|---------|
| Tauri CLI 输出 | base64 单行 | `dW50cnVzdGVkIGNvbW1lbnQ6...` |
| 解码后格式 | 2 行文本 | `untrusted comment:...` |
| tauri.conf.json | base64 单行 | `dW50cnVzdGVkIGNvbW1lbnQ6...` |
| GitHub Secret | base64 单行 | `dW50cnVzdGVkIGNvbW1lbnQ6...` |

**关键点：** 直接使用文件内容，不要手动解码！

---

## ✅ 验证清单

```bash
# 1. 检查密钥文件格式
wc -l postmock.key.pub  # 应该输出: 1
head -c 4 postmock.key.pub  # 应该输出: dW50

# 2. 检查公钥配置
cat src-tauri/tauri.conf.json | jq -r '.plugins.updater.pubkey' | head -c 4
# 应该输出: dW50

# 3. 检查 .gitignore
grep "*.key" .gitignore  # 应该有匹配

# 4. 提交并推送
git add src-tauri/tauri.conf.json
git commit -m "chore: update signing keys"
git push

# 5. 创建 tag 触发构建
git tag v0.1.0
git push origin v0.1.0

# 6. 检查 GitHub Actions 日志
# 应该看到: "Detected base64 encoded key file, decoding..."
```

---

## ⚠️ 常见错误

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `failed to decode pubkey` | 公钥格式错误 | 使用完整的 base64 文件内容 |
| `failed to decode secret key` | 私钥格式错误 | 重新复制私钥文件内容 |
| `Invalid symbol X` | base64 被破坏 | 使用 `cat` 命令重新复制 |
| `invalid utf-8 sequence` | 误用解码后的内容 | 使用原始 base64 内容 |

---

## 🔧 常用命令

```bash
# 查看公钥
cat postmock.key.pub

# 查看私钥（小心！）
cat postmock.key

# 解码查看（验证用）
cat postmock.key.pub | base64 -d

# 复制到剪贴板（Linux）
cat postmock.key.pub | xclip -selection clipboard

# 复制到剪贴板（macOS）
cat postmock.key.pub | pbcopy

# 检查配置
cat src-tauri/tauri.conf.json | jq '.plugins.updater'

# 查看 GitHub Actions 日志
gh run list
gh run view <run_id> --log

# 下载 Release 文件
gh release download v0.1.0

# 检查签名文件
ls -la *.sig
```

---

## 🔒 安全提醒

### ✅ 应该做的

- 使用 `.gitignore` 排除密钥文件
- 备份密钥到安全位置
- 定期轮换密钥
- 限制 GitHub Secret 访问权限

### ❌ 不应该做的

- 提交私钥到 Git
- 在代码注释中包含密钥
- 通过不安全渠道传输密钥
- 在多个项目间共享密钥

---

## 📚 详细文档

需要更多信息？查看：

- **[SIGNING_KEYS_GUIDE.md](SIGNING_KEYS_GUIDE.md)** - 完整配置指南
- **[KEY_CONFIGURATION_REFERENCE.md](KEY_CONFIGURATION_REFERENCE.md)** - 技术参考手册
- **[UPDATER_QUICKSTART.md](UPDATER_QUICKSTART.md)** - 快速启动指南

---

## 🆘 获取帮助

1. 查看 [常见错误](#常见错误) 部分
2. 阅读 [KEY_CONFIGURATION_REFERENCE.md](KEY_CONFIGURATION_REFERENCE.md) 的故障排除章节
3. 检查 GitHub Actions 日志
4. 查看 [Tauri 官方文档](https://v2.tauri.app/plugin/updater/)

---

**提示：** 将此页面加入书签或打印出来，以便快速查找！
