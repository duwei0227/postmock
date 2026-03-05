# Tauri 签名密钥配置指南

> 最后更新：2024-03-05  
> 状态：✅ 已验证可用  
> GitHub Actions：✅ 构建成功并生成签名文件

本文档记录了 PostMock 项目中 Tauri 自动更新功能的签名密钥生成和配置流程。

## 📋 目录

- [概述](#概述)
- [密钥格式说明](#密钥格式说明)
- [密钥生成步骤](#密钥生成步骤)
- [配置步骤](#配置步骤)
- [配置总结](#配置总结)
- [常见错误和解决方案](#常见错误和解决方案)
- [密钥轮换](#密钥轮换)
- [安全建议](#安全建议)
- [验证配置](#验证配置)
- [参考文档](#参考文档)

## 概述

Tauri 使用 minisign 签名机制来确保更新包的安全性。需要生成一对密钥：
- **公钥**：配置在 `src-tauri/tauri.conf.json` 中，用于验证更新包
- **私钥**：配置在 GitHub Secrets 中，用于签名更新包

## 密钥格式说明

### Tauri CLI 生成的密钥格式

Tauri CLI (`npm run tauri signer generate`) 生成的密钥文件是 **base64 编码的单行格式**：

```
# 公钥文件 (*.key.pub)
dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IEU0OTUzMzg4MEYwN0NENEQKUldSTnpRY1BpRE9WNU9NekxRRllxMExTMmJUSXgxUzJYaWRXUW5yc092MWZYMS96MW1zc2w1d2kK

# 私钥文件 (*.key)
dW50cnVzdGVkIGNvbW1lbnQ6IHJzaWduIGVuY3J5cHRlZCBzZWNyZXQga2V5ClJXUlRZMEl5NFV4RXFnMmhuMkVJQlIxZjU0Y29sN0lyMEJ2eVFmL3pVNTZmY2czcWEza0FBQkFBQUFBQUFBQUFBQUlBQUFBQW1uZmkzeXhRR21Vak1iZjUyQkhhM09zQTM5OE9qRFdwTGt3WklVRkd0OW5CdXh0NHRVMklaYzJ3a2p2K2dsNTZZTnJlaG5lbDdHSnYvVlpKMHo3cWxrVFMvUTk1TGttSnNxZmdnRTB5QkVYWTVpZE1Ubm1GUWpHVjJXc2NwKzdqd1dwTGZ5T2VTOTA9Cg==
```

### 解码后的格式

base64 解码后是标准的 minisign 格式（2 行）：

```
# 公钥解码后
untrusted comment: minisign public key: E49533880F07CD4D
RWRNzQcPiDOV5OMzLQFYq0LS2bTIx1S2XidWQnrsOv1fX1/z1mssl5wi

# 私钥解码后
untrusted comment: rsign encrypted secret key
RWRTY0Iy4UxEqg2hn2EIBR1f54col7Ir0BvyQf/zU56fcg3qa3kAABAAAAAAAAAAAAIAAAAAmn...
```

## 密钥生成步骤

### 1. 生成密钥对

```bash
# 在项目根目录执行
npm run tauri signer generate -- -w ./postmock.key

# 提示输入密码时，按两次 Enter（不设置密码）
# 这会生成两个文件：
# - postmock.key (私钥)
# - postmock.key.pub (公钥)
```

**重要提示：**
- 不要设置密码，否则需要额外配置 `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`
- 生成的文件是 base64 编码的单行格式
- 私钥文件必须妥善保管，不能泄露

### 2. 验证密钥格式

```bash
# 检查文件是否存在
ls -la postmock.key*

# 查看文件内容（应该是单行 base64 字符串）
head -1 postmock.key.pub
# 输出类似：dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6...

# 解码查看（可选）
cat postmock.key.pub | base64 -d
# 应该输出 2 行：
# untrusted comment: minisign public key: ...
# RW...
```

## 配置步骤

### 1. 配置公钥到 tauri.conf.json

**关键点：使用 base64 编码的完整文件内容**

```json
{
  "plugins": {
    "updater": {
      "pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IEU0OTUzMzg4MEYwN0NENEQKUldSTnpRY1BpRE9WNU9NekxRRllxMExTMmJUSXgxUzJYaWRXUW5yc092MWZYMS96MW1zc2w1d2kK",
      "endpoints": [
        "https://github.com/duwei0227/postmock/releases/latest/download/latest.json"
      ]
    }
  }
}
```

**操作步骤：**
```bash
# 复制公钥文件的完整内容
cat postmock.key.pub

# 将输出的 base64 字符串粘贴到 tauri.conf.json 的 pubkey 字段
```

### 2. 配置私钥到 GitHub Secrets

**关键点：使用 base64 编码的完整文件内容**

1. 复制私钥内容：
   ```bash
   cat postmock.key
   ```

2. 访问 GitHub Secrets 设置：
   ```
   https://github.com/duwei0227/postmock/settings/secrets/actions
   ```

3. 添加或更新 Secret：
   - Name: `TAURI_SIGNING_PRIVATE_KEY`
   - Value: 粘贴私钥的 base64 内容（单行字符串）

4. 点击 "Add secret" 或 "Update secret"

### 3. GitHub Actions 工作流配置

工作流会自动处理密钥解码：

```yaml
- name: Decode signing key
  shell: bash
  run: |
    KEY_VALUE="${{ secrets.TAURI_SIGNING_PRIVATE_KEY }}"
    
    # 检查密钥是否包含换行符
    if echo "$KEY_VALUE" | grep -q $'\n'; then
      echo "Key is already in multi-line format (2 lines)"
      echo "TAURI_SIGNING_PRIVATE_KEY<<EOF" >> $GITHUB_ENV
      echo "$KEY_VALUE" >> $GITHUB_ENV
      echo "EOF" >> $GITHUB_ENV
    else
      # 单行密钥，检查是否是 base64 编码的
      if [[ "$KEY_VALUE" == dW50* ]]; then
        echo "Detected base64 encoded key file, decoding..."
        # 解码 base64 得到原始的 2 行密钥
        DECODED_KEY=$(echo "$KEY_VALUE" | base64 -d)
        
        # 设置环境变量
        echo "TAURI_SIGNING_PRIVATE_KEY<<EOF" >> $GITHUB_ENV
        echo "$DECODED_KEY" >> $GITHUB_ENV
        echo "EOF" >> $GITHUB_ENV
      else
        echo "Key appears to be in plain text format"
        echo "TAURI_SIGNING_PRIVATE_KEY<<EOF" >> $GITHUB_ENV
        echo "$KEY_VALUE" >> $GITHUB_ENV
        echo "EOF" >> $GITHUB_ENV
      fi
    fi

- name: Build Tauri app
  uses: tauri-apps/tauri-action@v0
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    TAURI_SIGNING_PRIVATE_KEY: ${{ env.TAURI_SIGNING_PRIVATE_KEY }}
```

## 配置总结

| 项目 | 格式 | 位置 | 说明 |
|------|------|------|------|
| 公钥 | base64 编码（单行） | `src-tauri/tauri.conf.json` | 直接使用 `*.key.pub` 文件内容 |
| 私钥 | base64 编码（单行） | GitHub Secret | 直接使用 `*.key` 文件内容 |
| 工作流 | 自动解码 | `.github/workflows/release.yml` | 自动检测并解码 base64 |

## 常见错误和解决方案

### 错误 1: "failed to decode pubkey"

**原因：** 公钥格式不正确

**解决方案：**
- 确保使用完整的 base64 编码文件内容
- 不要手动解码或只使用第二行
- 不要在末尾添加额外字符（如用户名）

### 错误 2: "failed to decode secret key"

**原因：** 私钥格式不正确或包含额外内容

**解决方案：**
- 确保 GitHub Secret 中只包含 base64 编码的单行内容
- 不要包含分隔线、空行或说明文字
- 重新复制 `*.key` 文件的完整内容

### 错误 3: "Invalid symbol X, offset Y"

**原因：** base64 字符串被破坏或包含非法字符

**解决方案：**
- 重新生成密钥对
- 确保复制粘贴时没有引入额外字符
- 使用 `cat` 命令而不是手动复制

### 错误 4: "A public key has been found, but no private key"

**原因：** Windows 平台环境变量未正确设置

**解决方案：**
- 工作流已更新为跨平台兼容
- 重新触发构建
- 检查 GitHub Actions 日志中的 "Decode signing key" 步骤
- 确认看到 "Successfully decoded key" 消息

**详细说明：** 参见 [KEY_CONFIGURATION_REFERENCE.md](KEY_CONFIGURATION_REFERENCE.md) 的错误 5

## 密钥轮换

如果需要更换密钥（密钥泄露或定期轮换）：

1. 生成新的密钥对
2. 更新 `tauri.conf.json` 中的公钥
3. 更新 GitHub Secret 中的私钥
4. 提交并推送更改
5. 创建新的 release

**注意：** 旧版本的应用将无法验证新密钥签名的更新包，用户需要手动下载新版本。

## 安全建议

1. **永远不要提交私钥到 Git 仓库**
   - 已在 `.gitignore` 中添加 `*.key` 规则
   
2. **妥善保管私钥**
   - 备份到安全的位置（如密码管理器）
   - 如果丢失，将无法发布更新
   
3. **定期轮换密钥**
   - 建议每年或在密钥可能泄露时轮换
   
4. **限制 GitHub Secret 访问权限**
   - 只有必要的维护者才能访问

## 验证配置

### 本地验证

```bash
# 检查公钥配置
cat src-tauri/tauri.conf.json | grep -A 1 "pubkey"

# 验证密钥文件格式
head -1 postmock.key.pub | wc -c  # 应该是一个较长的数字（base64 长度）
```

### GitHub Actions 验证

1. 创建测试 tag：
   ```bash
   git tag v0.2.0-test
   git push origin v0.2.0-test
   ```

2. 观察 GitHub Actions 日志：
   - 应该看到 "Detected base64 encoded key file, decoding..."
   - 应该看到 "Decoded key has 2 lines"
   - 构建应该成功生成 `.sig` 签名文件

3. 检查 Release 产物：
   - 每个更新包应该有对应的 `.sig` 文件
   - 应该生成 `latest.json` 清单文件

## 参考文档

- [Tauri Updater 官方文档](https://v2.tauri.app/plugin/updater/)
- [Minisign 签名工具](https://jedisct1.github.io/minisign/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## 故障排除

如遇到问题，请参考：
- `.github/TROUBLESHOOTING.md` - 详细故障排除指南
- `.github/QUICK_FIX_SIGNING_ERROR.md` - 签名错误快速修复

---

## 🎯 关键要点总结

### 密钥格式（最重要）

| 项目 | 格式 | 说明 |
|------|------|------|
| **Tauri CLI 生成的文件** | base64 编码的单行字符串 | 这是 Tauri CLI 的默认输出格式 |
| **公钥配置** | 直接使用文件内容（base64） | 复制 `*.key.pub` 的完整内容到 `tauri.conf.json` |
| **私钥配置** | 直接使用文件内容（base64） | 复制 `*.key` 的完整内容到 GitHub Secret |
| **工作流处理** | 自动解码 base64 | GitHub Actions 会自动检测并解码为 2 行格式 |

### 配置流程（3 步）

1. **生成密钥对**
   ```bash
   npm run tauri signer generate -- -w ./postmock.key
   # 按两次 Enter（不设置密码）
   ```

2. **配置公钥**
   ```bash
   # 复制公钥内容
   cat postmock.key.pub
   # 粘贴到 src-tauri/tauri.conf.json 的 plugins.updater.pubkey 字段
   ```

3. **配置私钥**
   ```bash
   # 复制私钥内容
   cat postmock.key
   # 粘贴到 GitHub Secret: TAURI_SIGNING_PRIVATE_KEY
   ```

### 常见错误原因

| 错误信息 | 原因 | 解决方案 |
|---------|------|---------|
| `failed to decode pubkey` | 公钥格式不正确 | 使用完整的 base64 文件内容，不要手动解码 |
| `failed to decode secret key` | 私钥格式不正确 | 确保 GitHub Secret 只包含 base64 内容 |
| `Invalid symbol X, offset Y` | base64 字符串被破坏 | 重新复制密钥文件内容 |
| `invalid utf-8 sequence` | 尝试将 base64 当作 UTF-8 解码 | 检查是否误用了解码后的内容 |

### 验证清单

- [ ] 密钥文件是单行 base64 字符串
- [ ] 公钥已正确配置到 `tauri.conf.json`
- [ ] 私钥已正确配置到 GitHub Secret
- [ ] `.gitignore` 已包含密钥文件规则
- [ ] GitHub Actions 构建成功
- [ ] 生成了 `.sig` 签名文件
- [ ] 生成了 `latest.json` 清单文件

### 安全提醒

⚠️ **永远不要提交私钥到 Git 仓库！**
- 已在 `.gitignore` 中配置：`*.key`, `*.key.pub`, `postmock*.key*`
- 私钥泄露将导致安全风险
- 如果泄露，立即轮换密钥

---

## 📚 相关文档

- [快速启动指南](UPDATER_QUICKSTART.md) - 自动更新功能使用指南
- [文档索引](README.md) - 所有文档的导航
- [Tauri Updater 官方文档](https://v2.tauri.app/plugin/updater/)

---

**维护记录：**
- 2024-03-05: 初始文档，记录成功配置的密钥格式和流程
- 2024-03-05: 添加关键要点总结和验证清单
