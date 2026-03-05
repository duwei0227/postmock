# 快速修复：签名密钥错误

## 错误信息

```
failed to decode secret key: failed to decode base64 secret key: 
failed to decode base64 key: Invalid symbol 45, offset 0.
```

## 原因

GitHub Secrets 中的私钥格式不正确。

## 快速修复步骤

### 1. 验证本地密钥格式

```bash
./scripts/verify-key-format.sh
```

如果显示错误，重新生成密钥：

```bash
rm ~/.tauri/postmock.key*
./scripts/generate-signing-key.sh
```

### 2. 正确获取私钥

**方法 A: 使用剪贴板（推荐）**

```bash
# macOS
cat ~/.tauri/postmock.key | pbcopy

# Linux
cat ~/.tauri/postmock.key | xclip -selection clipboard

# Windows Git Bash
cat ~/.tauri/postmock.key | clip
```

**方法 B: 手动复制**

```bash
cat ~/.tauri/postmock.key
```

复制输出的**全部 2 行**，不要包含任何其他内容。

### 3. 更新 GitHub Secrets

1. 访问: https://github.com/duwei0227/postmock/settings/secrets/actions

2. 找到 `TAURI_SIGNING_PRIVATE_KEY`，点击 "Update"（或删除后重新添加）

3. 粘贴私钥内容（应该是 2 行）

4. 点击 "Update secret"

### 4. 验证格式

粘贴到 GitHub Secrets 的内容应该看起来像这样：

```
untrusted comment: minisign encrypted secret key
RWRTYabcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ==
```

**检查清单**：
- [ ] 恰好 2 行
- [ ] 第 1 行以 `untrusted comment:` 开头
- [ ] 第 2 行以 `RW` 开头
- [ ] 没有额外的空行
- [ ] 没有分隔线或说明文字

### 5. 重新运行工作流

1. 进入 GitHub Actions 标签
2. 找到失败的工作流
3. 点击 "Re-run all jobs"

## 常见错误

### ❌ 错误 1: 包含了分隔线

```
========================================
untrusted comment: minisign encrypted secret key
RW...
========================================
```

**修复**: 只复制中间的 2 行

### ❌ 错误 2: 包含了额外的空行

```
untrusted comment: minisign encrypted secret key

RW...
```

**修复**: 确保没有空行

### ❌ 错误 3: 只复制了第二行

```
RW...
```

**修复**: 必须包含第一行的注释

### ❌ 错误 4: 包含了说明文字

```
Private key:
untrusted comment: minisign encrypted secret key
RW...
```

**修复**: 只复制密钥本身的 2 行

## ✅ 正确的格式

```
untrusted comment: minisign encrypted secret key
RWRTYabcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ==
```

- 2 行
- 没有额外内容
- 没有空行

## 验证成功

工作流应该显示：

```
✓ Signing bundle with private key
✓ Generated signature file: postmock_0.1.0_amd64.AppImage.sig
✓ Signature verification successful
```

## 仍然失败？

1. **检查密钥文件**:
   ```bash
   ls -la ~/.tauri/postmock.key*
   ```
   应该看到 `postmock.key` 和 `postmock.key.pub`

2. **重新生成密钥**:
   ```bash
   rm ~/.tauri/postmock.key*
   ./scripts/generate-signing-key.sh
   ```

3. **更新公钥**:
   - 复制新生成的公钥
   - 更新 `src-tauri/tauri.conf.json`

4. **更新私钥**:
   - 按照上述步骤更新 GitHub Secrets

5. **提交更改**:
   ```bash
   git add src-tauri/tauri.conf.json
   git commit -m "fix: update signing public key"
   git push
   ```

6. **重新运行工作流**

## 需要帮助？

查看完整文档：
- `.github/TROUBLESHOOTING.md` - 故障排除
- `.github/GITHUB_SECRETS_SETUP.md` - Secrets 配置
- `.github/UPDATER_SETUP.md` - 完整设置指南

---

**最后更新**: 2024-03-05
