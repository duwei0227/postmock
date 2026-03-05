# 使用带密码的签名密钥配置指南

## 概述

本指南说明如何配置和使用带密码保护的 Tauri 签名密钥。这是一种更安全的方式，因为即使私钥泄露，没有密码也无法使用。

## 当前配置状态

✅ 项目已配置为使用带密码的签名密钥
✅ GitHub Actions 工作流已正确配置密码支持
✅ 所有构建 job 都会使用密码

## 前提条件

你需要在 GitHub Secrets 中配置两个密钥：

1. `TAURI_SIGNING_PRIVATE_KEY` - 加密的私钥内容
2. `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` - 私钥的密码

## 配置步骤

### 1. 生成带密码的签名密钥

如果你还没有生成密钥，运行：

```bash
npm run tauri signer generate -- -w ./postmock.key
```

当提示输入密码时，**输入一个强密码**：
```
Enter a password to encrypt the secret key (optional): [输入密码]
Confirm password: [再次输入密码]
```

这将生成两个文件：
- `postmock.key` - 加密的私钥（需要密码才能使用）
- `postmock.key.pub` - 公钥

### 2. 更新 tauri.conf.json

复制公钥内容：
```bash
cat postmock.key.pub
```

更新 `src-tauri/tauri.conf.json`：
```json
{
  "plugins": {
    "updater": {
      "pubkey": "这里粘贴公钥的完整内容",
      "endpoints": [
        "https://github.com/duwei0227/postmock/releases/latest/download/latest.json"
      ]
    }
  }
}
```

### 3. 配置 GitHub Secrets

访问仓库的 Settings → Secrets and variables → Actions

#### 3.1 配置私钥

1. 点击 "New repository secret"
2. Name: `TAURI_SIGNING_PRIVATE_KEY`
3. Secret: 粘贴 `postmock.key` 的完整内容
   ```bash
   cat postmock.key
   ```
4. 点击 "Add secret"

#### 3.2 配置密码

1. 点击 "New repository secret"
2. Name: `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`
3. Secret: 输入你在生成密钥时设置的密码
4. 点击 "Add secret"

### 4. 验证配置

#### 4.1 检查本地密钥

确认密钥文件存在且格式正确：

```bash
# 检查私钥（应该显示 "rsign encrypted secret key"）
head -n 1 postmock.key

# 检查公钥（应该显示 "minisign public key"）
head -n 1 postmock.key.pub
```

#### 4.2 检查 GitHub Secrets

在仓库的 Settings → Secrets and variables → Actions 页面，确认：
- ✅ `TAURI_SIGNING_PRIVATE_KEY` 已配置
- ✅ `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` 已配置

### 5. 提交更改

```bash
# 只提交公钥的更改（私钥不要提交）
git add src-tauri/tauri.conf.json
git add postmock.key.pub
git commit -m "chore: update signing public key"
git push
```

### 6. 测试构建

创建一个新 tag 触发构建：

```bash
git tag v0.1.1
git push origin v0.1.1
```

然后访问 GitHub Actions 页面查看构建结果。

## 工作流配置说明

### build-tauri job

使用 `tauri-apps/tauri-action@v0`，自动处理签名：

```yaml
- name: Build Tauri app
  uses: tauri-apps/tauri-action@v0
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    TAURI_SIGNING_PRIVATE_KEY: ${{ env.TAURI_SIGNING_PRIVATE_KEY }}
    TAURI_SIGNING_PRIVATE_KEY_PASSWORD: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY_PASSWORD }}
  with:
    releaseId: ${{ needs.create-release.outputs.release_id }}
    args: ${{ matrix.args }}
```

### build-portable job

使用 `npm run tauri build`，需要手动配置环境变量：

```yaml
- name: Build Tauri app
  run: npm run tauri build
  env:
    TAURI_SIGNING_PRIVATE_KEY: ${{ env.TAURI_SIGNING_PRIVATE_KEY }}
    TAURI_SIGNING_PRIVATE_KEY_PASSWORD: ${{ secrets.TAURI_SIGNING_PRIVATE_KEY_PASSWORD }}
```

## 安全最佳实践

### ✅ 推荐做法

1. **使用强密码**
   - 至少 16 个字符
   - 包含大小写字母、数字和特殊字符
   - 使用密码管理器生成和存储

2. **妥善保管密钥和密码**
   - 私钥文件不要提交到 Git（已在 `.gitignore` 中）
   - 密码存储在安全的密码管理器中
   - 不要在代码或文档中硬编码密码

3. **定期轮换密钥**
   - 建议每年更换一次签名密钥
   - 密钥泄露时立即更换

4. **限制访问权限**
   - 只有必要的团队成员才能访问 GitHub Secrets
   - 使用 GitHub 的环境保护规则

### ❌ 避免的做法

1. ❌ 不要使用弱密码或空密码
2. ❌ 不要将密钥文件提交到 Git
3. ❌ 不要在公开的地方分享密码
4. ❌ 不要在多个项目中重用同一个密钥
5. ❌ 不要将密码写在代码注释中

## 故障排除

### 错误：incorrect updater private key password

**原因：** GitHub Secret 中的密码不正确

**解决方案：**
1. 确认你记得正确的密码
2. 更新 GitHub Secret `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`
3. 重新触发构建

### 错误：failed to decode secret key

**原因：** 私钥格式不正确或已损坏

**解决方案：**
1. 检查私钥文件内容：
   ```bash
   cat postmock.key
   ```
2. 确认第一行是 `dW50cnVzdGVkIGNvbW1lbnQ6IHJzaWduIGVuY3J5cHRlZCBzZWNyZXQga2V5`
3. 确认 GitHub Secret 中的内容与文件内容完全一致
4. 如果损坏，重新生成密钥

### 错误：A public key has been found, but no private key

**原因：** 环境变量 `TAURI_SIGNING_PRIVATE_KEY` 未设置

**解决方案：**
1. 检查 GitHub Secret `TAURI_SIGNING_PRIVATE_KEY` 是否存在
2. 检查工作流中是否正确配置了环境变量
3. 查看构建日志中的 "Configure signing key" 步骤

## 验证清单

构建成功后，应该看到以下签名文件：

- ✅ `*.AppImage.sig`
- ✅ `*.deb.sig`
- ✅ `*.rpm.sig`
- ✅ `*-setup.exe.sig`
- ✅ `*.msi.sig`
- ✅ `*.app.tar.gz.sig`
- ✅ `latest.json`

## 密钥轮换

如果需要更换密钥：

1. 生成新的密钥对（使用新密码）
2. 更新 `tauri.conf.json` 中的公钥
3. 更新 GitHub Secrets 中的私钥和密码
4. 提交更改并创建新 tag

**注意：** 使用旧公钥的应用将无法验证新密钥签名的更新。

## 相关文档

- [KEY_QUICK_REFERENCE.md](KEY_QUICK_REFERENCE.md) - 签名密钥配置速查卡
- [SIGNING_KEYS_GUIDE.md](SIGNING_KEYS_GUIDE.md) - 签名密钥完整指南
- [KEY_CONFIGURATION_REFERENCE.md](KEY_CONFIGURATION_REFERENCE.md) - 密钥配置技术参考
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 常见问题解决方案

---

**最后更新：** 2026-03-05
