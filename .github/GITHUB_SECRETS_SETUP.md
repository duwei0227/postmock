# GitHub Secrets 配置指南

## 概述

为了让 GitHub Actions 能够签名你的应用更新包，需要将私钥添加到 GitHub Secrets 中。

## 前提条件

确保你已经生成了签名密钥：
```bash
./scripts/generate-signing-key.sh
```

## 配置步骤

### 步骤 1: 获取私钥内容

在终端运行以下命令查看私钥内容：

```bash
cat ~/.tauri/postmock.key
```

输出类似：
```
untrusted comment: minisign encrypted secret key
RWRTY6OE+NMxCJBrQFhd...（很长的一串字符）
```

**复制整个输出内容**（包括第一行的注释）。

### 步骤 2: 访问 GitHub 仓库设置

1. 打开浏览器，访问你的 GitHub 仓库：
   ```
   https://github.com/duwei0227/postmock
   ```

2. 点击仓库页面顶部的 **Settings** 标签

3. 在左侧菜单中找到 **Secrets and variables**，点击展开

4. 点击 **Actions**

### 步骤 3: 添加私钥 Secret

1. 点击右上角的 **New repository secret** 按钮

2. 填写 Secret 信息：
   - **Name**: `TAURI_SIGNING_PRIVATE_KEY`
   - **Secret**: 粘贴步骤 1 中复制的私钥内容

3. 点击 **Add secret** 保存

### 步骤 4: 添加密码 Secret（如果设置了密码）

如果你在生成密钥时设置了密码，需要添加密码 Secret：

1. 再次点击 **New repository secret**

2. 填写 Secret 信息：
   - **Name**: `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`
   - **Secret**: 输入你设置的密码

3. 点击 **Add secret** 保存

**注意**: 如果没有设置密码（按了两次 Enter），则不需要添加这个 Secret。

### 步骤 5: 验证配置

配置完成后，你应该能在 Secrets 列表中看到：

- ✅ `TAURI_SIGNING_PRIVATE_KEY` (必需)
- ✅ `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` (可选，仅当设置了密码时)

## 使用截图指南

### 1. 进入 Settings
![Settings Tab](https://docs.github.com/assets/cb-28266/images/help/repository/repo-actions-settings.png)

### 2. 找到 Secrets and variables → Actions
在左侧菜单中：
```
Settings
  ├── General
  ├── ...
  └── Secrets and variables
      └── Actions  ← 点击这里
```

### 3. 添加 Secret
点击 "New repository secret" 按钮，填写表单：

```
┌─────────────────────────────────────────┐
│ Name *                                  │
│ ┌─────────────────────────────────────┐ │
│ │ TAURI_SIGNING_PRIVATE_KEY           │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Secret *                                │
│ ┌─────────────────────────────────────┐ │
│ │ untrusted comment: minisign...      │ │
│ │ RWRTY6OE+NMxCJBrQFhd...             │ │
│ │ ...                                 │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [Add secret]                            │
└─────────────────────────────────────────┘
```

## 安全注意事项

⚠️ **重要安全提示**：

1. **私钥保密**: 私钥是敏感信息，不要分享给任何人
2. **不要提交到 Git**: 确保 `~/.tauri/postmock.key` 不在版本控制中
3. **备份私钥**: 将私钥文件备份到安全的地方
4. **定期检查**: 定期检查 GitHub Secrets 的访问日志
5. **最小权限**: 只给需要的 GitHub Actions 工作流访问权限

## 测试配置

配置完成后，可以通过以下方式测试：

### 方法 1: 手动触发工作流

1. 进入 Actions 标签
2. 选择 "Release Desktop App" 工作流
3. 点击 "Run workflow"
4. 选择分支并运行

### 方法 2: 推送版本标签

```bash
# 更新版本号
npm version patch  # 或 minor, major

# 推送标签
git push origin v0.1.1
```

GitHub Actions 会自动运行，检查工作流日志确认签名是否成功。

## 故障排除

### 问题 1: "TAURI_SIGNING_PRIVATE_KEY not found"

**原因**: Secret 名称不正确或未添加

**解决**:
1. 检查 Secret 名称是否完全匹配 `TAURI_SIGNING_PRIVATE_KEY`
2. 确认 Secret 已成功保存
3. 重新运行工作流

### 问题 2: "Invalid private key"

**原因**: 私钥内容不完整或格式错误

**解决**:
1. 重新复制私钥内容，确保包含所有行
2. 检查是否包含第一行的注释
3. 确保没有多余的空格或换行

### 问题 3: "Password required"

**原因**: 密钥设置了密码但未提供密码 Secret

**解决**:
1. 添加 `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` Secret
2. 或重新生成不带密码的密钥

## 验证 Secrets 是否生效

在 GitHub Actions 工作流日志中，你应该看到类似的输出：

```
✓ Signing bundle with private key
✓ Generated signature file: postmock_0.1.0_amd64.AppImage.sig
✓ Signature verification successful
```

如果看到错误，请检查上述故障排除部分。

## 下一步

配置完成后：

1. ✅ 私钥已添加到 GitHub Secrets
2. ✅ 公钥已配置到 `tauri.conf.json`
3. ✅ GitHub Actions 工作流已配置

现在可以：
- 推送版本标签触发自动构建
- 应用会自动签名
- 用户可以通过应用内更新功能升级

## 参考链接

- [GitHub Secrets 文档](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Tauri Updater 文档](https://v2.tauri.app/plugin/updater/)
- [项目快速启动指南](.github/UPDATER_QUICKSTART.md)
