# Tauri 签名密钥配置参考手册

> 📘 这是一份技术参考文档，详细说明密钥的生成、格式和配置规则  
> 📅 最后更新：2024-03-05  
> ✅ 状态：已验证并在生产环境中使用

## 🎯 文档目的

本文档提供 Tauri 签名密钥配置的完整技术参考，包括：
- 密钥生成的技术细节
- 密钥格式的详细说明
- 配置规则和最佳实践
- 故障排除和调试方法

如果你只是想快速配置，请参考 [签名密钥配置指南](SIGNING_KEYS_GUIDE.md)。

---

## 📖 目录

1. [技术背景](#技术背景)
2. [密钥格式详解](#密钥格式详解)
3. [生成规则](#生成规则)
4. [配置规则](#配置规则)
5. [工作流处理逻辑](#工作流处理逻辑)
6. [验证方法](#验证方法)
7. [故障排除](#故障排除)

---

## 技术背景

### Tauri 更新机制

Tauri 使用 **minisign** 签名机制来确保更新包的完整性和真实性：

1. **构建时**：使用私钥对更新包进行签名，生成 `.sig` 文件
2. **更新时**：应用使用公钥验证签名，确保更新包未被篡改
3. **安全性**：基于 Ed25519 椭圆曲线加密算法

### 密钥对组成

- **公钥（Public Key）**：嵌入到应用中，用于验证签名
- **私钥（Private Key）**：保密存储，用于签名更新包

### 相关工具

- **Tauri CLI**：`npm run tauri signer generate` - 生成密钥对
- **minisign**：底层签名工具（Tauri 内部使用）
- **base64**：编码/解码工具

---

## 密钥格式详解

### Tauri CLI 生成的原始格式

Tauri CLI 生成的密钥文件是 **base64 编码的单行字符串**：

```
# 公钥文件示例 (postmock.key.pub)
dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IEU0OTUzMzg4MEYwN0NENEQKUldSTnpRY1BpRE9WNU9NekxRRllxMExTMmJUSXgxUzJYaWRXUW5yc092MWZYMS96MW1zc2w1d2kK

# 私钥文件示例 (postmock.key)
dW50cnVzdGVkIGNvbW1lbnQ6IHJzaWduIGVuY3J5cHRlZCBzZWNyZXQga2V5ClJXUlRZMEl5NFV4RXFnMmhuMkVJQlIxZjU0Y29sN0lyMEJ2eVFmL3pVNTZmY2czcWEza0FBQkFBQUFBQUFBQUFBQUlBQUFBQW1uZmkzeXhRR21Vak1iZjUyQkhhM09zQTM5OE9qRFdwTGt3WklVRkd0OW5CdXh0NHRVMklaYzJ3a2p2K2dsNTZZTnJlaG5lbDdHSnYvVlpKMHo3cWxrVFMvUTk1TGttSnNxZmdnRTB5QkVYWTVpZE1Ubm1GUWpHVjJXc2NwKzdqd1dwTGZ5T2VTOTA9Cg==
```

### 解码后的标准 minisign 格式

使用 `base64 -d` 解码后，得到标准的 2 行 minisign 格式：

```
# 公钥解码后
untrusted comment: minisign public key: E49533880F07CD4D
RWRNzQcPiDOV5OMzLQFYq0LS2bTIx1S2XidWQnrsOv1fX1/z1mssl5wi

# 私钥解码后
untrusted comment: rsign encrypted secret key
RWRTY0Iy4UxEqg2hn2EIBR1f54col7Ir0BvyQf/zU56fcg3qa3kAABAAAAAAAAAAAAIAAAAAmn...
```

### 格式特征识别

| 特征 | base64 编码格式 | 解码后格式 |
|------|----------------|-----------|
| 行数 | 1 行 | 2 行 |
| 开头 | `dW50` (base64 of "untrusted") | `untrusted comment:` |
| 第二行 | 无 | `RW...` (实际密钥数据) |
| 长度 | 约 200-400 字符 | 第一行约 40-60 字符，第二行约 100-200 字符 |

---

## 生成规则

### 命令格式

```bash
npm run tauri signer generate -- -w <output_path>
```

### 参数说明

- `-w, --write <PATH>`: 指定输出文件路径
- 不指定路径时，默认输出到 `~/.tauri/<app_name>.key`

### 密码设置

生成时会提示输入密码：

```
Password: [按 Enter]
Password (one more time): [按 Enter]
```

**建议：不设置密码**
- 优点：CI/CD 环境无需额外配置 `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`
- 缺点：私钥文件本身不加密（但应该通过其他方式保护）
- 如果设置密码：需要在 GitHub Secrets 中额外配置密码

### 输出文件

生成两个文件：
- `<output_path>` - 私钥文件
- `<output_path>.pub` - 公钥文件

### 示例

```bash
# 生成到当前目录
npm run tauri signer generate -- -w ./postmock.key

# 生成的文件
# - postmock.key (私钥)
# - postmock.key.pub (公钥)
```

---

## 配置规则

### 规则 1: 公钥配置到 tauri.conf.json

**位置：** `src-tauri/tauri.conf.json`

**字段：** `plugins.updater.pubkey`

**格式：** base64 编码的单行字符串（直接使用 `*.key.pub` 文件内容）

**示例：**

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
# 1. 读取公钥文件内容
cat postmock.key.pub

# 2. 复制输出的 base64 字符串

# 3. 粘贴到 tauri.conf.json 的 pubkey 字段
```

**注意事项：**
- ✅ 使用完整的文件内容（包括末尾的换行符编码）
- ❌ 不要手动解码
- ❌ 不要只使用第二行
- ❌ 不要添加额外的空格或换行

### 规则 2: 私钥配置到 GitHub Secrets

**位置：** GitHub Repository Settings → Secrets and variables → Actions

**Secret 名称：** `TAURI_SIGNING_PRIVATE_KEY`

**格式：** base64 编码的单行字符串（直接使用 `*.key` 文件内容）

**操作步骤：**

```bash
# 1. 读取私钥文件内容
cat postmock.key

# 2. 复制输出的 base64 字符串

# 3. 访问 GitHub Secrets 设置页面
# https://github.com/<username>/<repo>/settings/secrets/actions

# 4. 添加或更新 Secret
# Name: TAURI_SIGNING_PRIVATE_KEY
# Value: [粘贴复制的内容]
```

**注意事项：**
- ✅ 只包含 base64 字符串
- ❌ 不要包含分隔线（如 `-----BEGIN PRIVATE KEY-----`）
- ❌ 不要包含说明文字
- ❌ 不要在末尾添加额外字符（如用户名）
- ❌ 不要手动解码

### 规则 3: 密码配置（可选）

如果生成密钥时设置了密码，需要额外配置：

**Secret 名称：** `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`

**格式：** 纯文本密码

---

## 工作流处理逻辑

### GitHub Actions 中的密钥处理

`.github/workflows/release.yml` 中的处理逻辑：

```yaml
- name: Decode signing key
  shell: bash
  run: |
    KEY_VALUE="${{ secrets.TAURI_SIGNING_PRIVATE_KEY }}"
    
    # 检查是否包含换行符（已经是 2 行格式）
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
```

### 处理流程图

```
GitHub Secret (base64 单行)
    ↓
检查格式（计算行数）
    ↓
行数 > 1？
    ├─ 是 → 直接使用（已经是多行格式）
    └─ 否 → 检查是否以 "dW50" 开头
              ├─ 是 → base64 解码为 2 行格式
              │       ├─ Windows: 使用兼容的 base64 命令
              │       └─ Linux/macOS: 使用标准 base64 -d
              └─ 否 → 直接使用（纯文本格式）
    ↓
验证解码结果（行数 >= 2）
    ↓
设置环境变量 TAURI_SIGNING_PRIVATE_KEY
    ↓
传递给 tauri-action
    ↓
Tauri 使用 2 行格式的密钥进行签名
```

### 关键点

1. **自动检测**：工作流会自动检测密钥格式
2. **自动解码**：如果是 base64 编码，会自动解码
3. **跨平台兼容**：支持 Windows、Linux、macOS 三个平台
4. **兼容性处理**：Windows 环境使用特殊的 base64 解码方式
5. **安全性**：密钥只在内存中处理，不写入磁盘

### 平台差异

| 平台 | base64 命令 | 换行符检测 |
|------|------------|-----------|
| Linux | `base64 -d` | 标准 |
| macOS | `base64 -d` | 标准 |
| Windows (Git Bash) | `base64 -d` 或 `base64 --decode` | 需要特殊处理 |

---

## 验证方法

### 1. 验证密钥文件格式

```bash
# 检查文件是否存在
ls -la postmock.key*

# 检查是否是单行
wc -l postmock.key.pub  # 应该输出 1
wc -l postmock.key      # 应该输出 1

# 检查是否以 base64 特征开头
head -c 4 postmock.key.pub  # 应该输出 "dW50"
head -c 4 postmock.key      # 应该输出 "dW50"

# 解码验证（应该得到 2 行）
cat postmock.key.pub | base64 -d | wc -l  # 应该输出 2
cat postmock.key | base64 -d | wc -l      # 应该输出 2

# 查看解码后的内容
cat postmock.key.pub | base64 -d
# 第一行应该是: untrusted comment: minisign public key: ...
# 第二行应该是: RW...

cat postmock.key | base64 -d
# 第一行应该是: untrusted comment: rsign encrypted secret key
# 第二行应该是: RW...
```

### 2. 验证 tauri.conf.json 配置

```bash
# 提取公钥配置
cat src-tauri/tauri.conf.json | jq -r '.plugins.updater.pubkey'

# 验证是否以 base64 特征开头
cat src-tauri/tauri.conf.json | jq -r '.plugins.updater.pubkey' | head -c 4
# 应该输出 "dW50"

# 解码验证
cat src-tauri/tauri.conf.json | jq -r '.plugins.updater.pubkey' | base64 -d
# 应该输出 2 行 minisign 公钥
```

### 3. 验证 GitHub Secret 配置

由于无法直接查看 Secret 内容，需要通过 GitHub Actions 日志验证：

1. 触发一次构建（推送 tag 或手动触发）
2. 查看 "Decode signing key" 步骤的日志
3. 应该看到以下输出之一：
   - `Detected base64 encoded key file, decoding...`
   - `Decoded key has 2 lines`
   - `Key is already in multi-line format (2 lines)`

### 4. 验证签名生成

构建成功后，检查 Release 产物：

```bash
# 下载 Release 文件
gh release download v0.1.0

# 检查签名文件是否存在
ls -la *.sig

# 每个更新包应该有对应的 .sig 文件：
# - postmock_0.1.0_amd64.AppImage.sig
# - postmock_0.1.0_x64-setup.exe.sig
# - postmock_0.1.0_x64.app.tar.gz.sig
# - postmock_0.1.0_aarch64.app.tar.gz.sig
```

### 5. 验证更新清单

```bash
# 下载 latest.json
curl -L https://github.com/duwei0227/postmock/releases/latest/download/latest.json

# 检查内容
cat latest.json | jq .

# 应该包含：
# - version: 版本号
# - notes: 更新说明
# - pub_date: 发布日期
# - platforms: 各平台的签名和下载链接
```

---

## 故障排除

### 错误 1: `failed to decode pubkey`

**完整错误信息：**
```
failed to decode pubkey: failed to decode base64 pubkey: failed to convert base64 to utf8: invalid utf-8 sequence of 1 bytes from index 3
```

**原因分析：**
- 公钥格式不正确
- 可能使用了解码后的内容
- 可能只使用了第二行

**解决方案：**
```bash
# 1. 重新读取公钥文件
cat postmock.key.pub

# 2. 确认输出是单行 base64 字符串

# 3. 完整复制输出内容

# 4. 更新 tauri.conf.json
# 替换 plugins.updater.pubkey 的值

# 5. 提交更改
git add src-tauri/tauri.conf.json
git commit -m "fix: update public key format"
git push
```

### 错误 2: `failed to decode secret key`

**完整错误信息：**
```
failed to decode secret key: failed to decode base64 secret key: failed to decode base64 key: Invalid symbol 10, offset 348
```

**原因分析：**
- 私钥包含换行符或其他非法字符
- 可能在复制时引入了额外内容
- 可能使用了解码后的内容

**解决方案：**
```bash
# 1. 重新读取私钥文件
cat postmock.key

# 2. 确认输出是单行 base64 字符串

# 3. 完整复制输出内容（不要包含任何额外内容）

# 4. 更新 GitHub Secret
# 访问: https://github.com/<username>/<repo>/settings/secrets/actions
# 更新 TAURI_SIGNING_PRIVATE_KEY 的值

# 5. 重新触发构建
git tag v0.1.1
git push origin v0.1.1
```

### 错误 3: `Invalid padding`

**完整错误信息：**
```
failed to decode pubkey: failed to decode base64 pubkey: failed to decode base64 key: Invalid padding
```

**原因分析：**
- base64 字符串被截断或破坏
- 复制时丢失了部分内容

**解决方案：**
```bash
# 1. 使用 cat 命令而不是手动复制
cat postmock.key.pub

# 2. 或者使用管道直接复制到剪贴板（Linux）
cat postmock.key.pub | xclip -selection clipboard

# 3. 或者使用管道直接复制到剪贴板（macOS）
cat postmock.key.pub | pbcopy

# 4. 验证复制的内容
# 粘贴到文本编辑器，确认是完整的单行字符串

# 5. 更新配置
```

### 错误 4: 密钥不匹配

**症状：**
- 构建成功，但更新验证失败
- 应用无法验证签名

**原因分析：**
- 公钥和私钥不是同一对
- 更新了一个但没有更新另一个

**解决方案：**
```bash
# 1. 重新生成密钥对
npm run tauri signer generate -- -w ./postmock-new.key

# 2. 同时更新公钥和私钥
# - 更新 tauri.conf.json 中的公钥
# - 更新 GitHub Secret 中的私钥

# 3. 提交并推送
git add src-tauri/tauri.conf.json
git commit -m "chore: regenerate signing keys"
git push

# 4. 创建新的 release
git tag v0.2.0
git push origin v0.2.0
```

### 错误 5: Windows 平台构建失败（环境变量未设置）

**完整错误信息：**
```
A public key has been found, but no private key. Make sure to set `TAURI_SIGNING_PRIVATE_KEY` environment variable.
```

**原因分析：**
- Windows 平台的 bash 环境处理换行符方式不同
- 密钥解码步骤失败，导致环境变量未设置
- 使用了不兼容的 bash 语法（如 `grep -q $'\n'`）

**解决方案：**

工作流已更新为跨平台兼容的实现：
- 使用 `wc -l` 计算行数而不是 `grep` 检测换行符
- 针对 Windows 环境使用兼容的 base64 解码命令
- 添加解码结果验证

如果仍然遇到问题：

```bash
# 1. 检查 GitHub Actions 日志中的 "Decode signing key" 步骤
# 应该看到：
# - "Detected base64 encoded key, decoding..."
# - "Decoded key has 2 lines"
# - "Successfully decoded key"

# 2. 如果看到 "Warning: Decoded key has unexpected format"
# 说明解码失败，需要检查密钥格式

# 3. 验证本地密钥文件
cat postmock.key | wc -l  # 应该输出 1
cat postmock.key | head -c 4  # 应该输出 dW50

# 4. 重新设置 GitHub Secret
# 确保复制的是完整的单行 base64 字符串
```

**预防措施：**
- 工作流已更新为跨平台兼容
- 使用标准的 bash 命令
- 添加了详细的日志输出
- 包含解码结果验证

### 调试技巧

1. **启用详细日志**
   ```yaml
   # 在 GitHub Actions 中添加
   - name: Build with verbose logging
     run: npm run tauri build -- --verbose
   ```

2. **本地测试签名**
   ```bash
   # 设置环境变量
   export TAURI_SIGNING_PRIVATE_KEY="$(cat postmock.key | base64 -d)"
   
   # 构建
   npm run tauri build
   
   # 检查是否生成 .sig 文件
   find src-tauri/target -name "*.sig"
   ```

3. **验证签名文件**
   ```bash
   # 如果安装了 minisign
   minisign -Vm <bundle_file> -P <public_key>
   ```

---

## 最佳实践

### 1. 密钥管理

- ✅ 使用密码管理器备份密钥
- ✅ 定期轮换密钥（建议每年一次）
- ✅ 限制密钥访问权限
- ❌ 不要在多个项目间共享密钥
- ❌ 不要通过不安全的渠道传输密钥

### 2. 配置管理

- ✅ 使用 `.gitignore` 排除密钥文件
- ✅ 在配置文件中添加注释说明
- ✅ 记录密钥生成和更新的时间
- ❌ 不要在代码注释中包含密钥内容
- ❌ 不要在日志中打印密钥

### 3. CI/CD 配置

- ✅ 使用 GitHub Secrets 存储私钥
- ✅ 限制 Secret 的访问范围
- ✅ 定期审查 Actions 日志
- ❌ 不要在日志中打印密钥内容
- ❌ 不要将密钥写入临时文件

### 4. 版本控制

- ✅ 提交公钥配置到 Git
- ✅ 在 commit 信息中说明密钥更新
- ✅ 使用 tag 标记密钥轮换的版本
- ❌ 不要提交私钥到 Git
- ❌ 不要在 PR 中讨论密钥内容

---

## 参考资料

### 官方文档

- [Tauri Updater Plugin](https://v2.tauri.app/plugin/updater/)
- [Tauri Signer CLI](https://v2.tauri.app/reference/cli/#signer)
- [minisign](https://jedisct1.github.io/minisign/)

### 项目文档

- [签名密钥配置指南](SIGNING_KEYS_GUIDE.md) - 快速配置指南
- [快速启动指南](UPDATER_QUICKSTART.md) - 自动更新功能使用
- [文档索引](README.md) - 所有文档导航

### 相关工具

- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [base64 命令](https://linux.die.net/man/1/base64)
- [jq - JSON 处理工具](https://stedolan.github.io/jq/)

---

**文档维护：**
- 作者：duwei0227
- 创建日期：2024-03-05
- 最后更新：2024-03-05
- 版本：1.0.0

**变更记录：**
- 2024-03-05: 初始版本，基于成功配置的经验编写
