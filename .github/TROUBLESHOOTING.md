# 故障排除指南

## 常见问题和解决方案

### 1. 构建错误：找不到私钥

**错误信息**:
```
A public key has been found, but no private key. 
Make sure to set `TAURI_SIGNING_PRIVATE_KEY` environment variable.
```

**原因**: GitHub Secrets 中没有配置 `TAURI_SIGNING_PRIVATE_KEY`

**解决方案**:

1. 生成签名密钥（如果还没有）:
   ```bash
   ./scripts/generate-signing-key.sh
   ```

2. 获取私钥内容:
   ```bash
   cat ~/.tauri/postmock.key
   ```

3. 添加到 GitHub Secrets:
   - 访问: https://github.com/duwei0227/postmock/settings/secrets/actions
   - 点击 "New repository secret"
   - Name: `TAURI_SIGNING_PRIVATE_KEY`
   - Secret: 粘贴私钥内容
   - 点击 "Add secret"

4. 重新运行 GitHub Actions 工作流

### 2. 更新检查失败：无法获取 JSON

**错误信息**:
```
Could not fetch a valid release JSON from the remote
```

**原因**: GitHub Release 中还没有 `latest.json` 文件

**解决方案**:

这是正常的，在第一次发布之前会出现此错误。解决方法：

**方法 1**: 等待第一次正式发布
- 配置好签名密钥
- 推送版本标签（如 v0.2.0）
- GitHub Actions 会自动生成 `latest.json`

**方法 2**: 手动创建测试文件
- 在 GitHub Release 中手动上传 `latest.json`
- 使用项目根目录的 `latest.json` 作为模板

**临时方案**: 代码已更新，会显示友好的提示信息而不是错误

### 3. 签名验证失败

**错误信息**:
```
Signature verification failed
```

**原因**: 公钥和私钥不匹配

**解决方案**:

1. 确认 `tauri.conf.json` 中的公钥正确:
   ```bash
   # 查看公钥
   cat ~/.tauri/postmock.key.pub
   ```

2. 确认 GitHub Secrets 中的私钥完整:
   ```bash
   # 查看私钥（确保复制了全部内容）
   cat ~/.tauri/postmock.key
   ```

3. 如果不匹配，重新生成密钥对:
   ```bash
   rm ~/.tauri/postmock.key*
   ./scripts/generate-signing-key.sh
   ```

4. 更新配置:
   - 更新 `tauri.conf.json` 中的公钥
   - 更新 GitHub Secrets 中的私钥

### 3.1. 私钥解码失败

**错误信息**:
```
failed to decode secret key: failed to decode base64 secret key: 
failed to decode base64 key: Invalid symbol 45, offset 0.
```

**原因**: GitHub Secrets 中的私钥格式不正确，包含了额外的字符或格式问题

**解决方案**:

1. **重新获取私钥**:
   ```bash
   ./scripts/show-private-key.sh
   ```

2. **正确复制私钥**:
   - 私钥应该是 **恰好 2 行**
   - 第 1 行: `untrusted comment: minisign encrypted secret key`
   - 第 2 行: 以 `RW` 开头的 base64 编码字符串
   - **不要**包含任何分隔线（`===`）
   - **不要**包含任何额外的空行
   - **不要**包含任何说明文字

3. **验证复制的内容**:
   ```bash
   # 正确的格式示例：
   untrusted comment: minisign encrypted secret key
   RWRTYabcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ==
   ```

4. **重新添加到 GitHub Secrets**:
   - 删除现有的 `TAURI_SIGNING_PRIVATE_KEY` Secret
   - 重新添加，确保只粘贴 2 行内容
   - 不要在开头或结尾添加任何空格或换行

5. **使用命令行直接复制**（推荐）:
   ```bash
   # macOS
   cat ~/.tauri/postmock.key | pbcopy
   
   # Linux (需要 xclip)
   cat ~/.tauri/postmock.key | xclip -selection clipboard
   
   # 或者手动复制
   cat ~/.tauri/postmock.key
   ```

6. **重新运行工作流**

### 4. 权限错误

**错误信息**:
```
Permission process:allow-relaunch not found
```

**原因**: 使用了不存在的权限名称

**解决方案**: 已修复，`relaunch()` 不需要额外权限

### 5. 下载进度不显示

**问题**: 更新下载时进度条不动

**原因**: 下载事件处理逻辑问题

**解决方案**:

检查 `Navbar.vue` 中的 `downloadAndInstall` 回调:

```javascript
await updateInfo.value.downloadAndInstall((event) => {
  switch (event.event) {
    case 'Started':
      console.log(`Started downloading ${event.data.contentLength} bytes`);
      break;
    case 'Progress':
      const downloaded = event.data.chunkLength;
      const total = event.data.contentLength || 1;
      downloadProgress.value = Math.round((downloaded / total) * 100);
      break;
    case 'Finished':
      downloadProgress.value = 100;
      break;
  }
});
```

### 6. 文件下载没有文件名

**问题**: 使用 "Send And Download" 时保存对话框没有默认文件名

**原因**: 服务器没有提供 Content-Disposition 或文件名信息

**解决方案**: 已实现智能文件名提取:
1. 优先使用 Content-Disposition 头
2. 其次从 URL 路径提取
3. 最后根据 Content-Type 生成

如果仍然没有文件名，检查:
- 服务器响应头
- URL 格式
- Content-Type 映射

### 7. GitHub Actions 工作流失败

**问题**: 工作流运行失败

**检查清单**:

1. **检查 Secrets 配置**:
   - `TAURI_SIGNING_PRIVATE_KEY` 是否存在
   - 内容是否完整（包括注释行）

2. **检查 YAML 语法**:
   ```bash
   # 验证 YAML 文件
   yamllint .github/workflows/release.yml
   ```

3. **检查依赖安装**:
   - Node.js 版本
   - Rust 工具链
   - 系统依赖

4. **查看详细日志**:
   - 进入 Actions 标签
   - 点击失败的工作流
   - 展开每个步骤查看详细输出

### 8. 本地构建失败

**问题**: 本地运行 `npm run tauri build` 失败

**解决方案**:

1. **检查环境变量**:
   ```bash
   # 设置私钥环境变量
   export TAURI_SIGNING_PRIVATE_KEY="$(cat ~/.tauri/postmock.key)"
   
   # 如果有密码
   export TAURI_SIGNING_PRIVATE_KEY_PASSWORD="your_password"
   ```

2. **检查依赖**:
   ```bash
   # 前端依赖
   npm install
   
   # Rust 依赖
   cd src-tauri
   cargo check
   ```

3. **清理缓存**:
   ```bash
   # 清理前端
   rm -rf node_modules dist
   npm install
   
   # 清理 Rust
   cd src-tauri
   cargo clean
   ```

### 9. 更新安装后应用不重启

**问题**: 更新安装完成但应用没有自动重启

**原因**: `relaunch()` 调用失败

**解决方案**:

检查 `Navbar.vue` 中的重启逻辑:

```javascript
// 等待 toast 显示
await new Promise(resolve => setTimeout(resolve, 2000));

// 重启应用
await relaunch();
```

如果仍然失败，手动重启应用。

### 10. 开发模式下更新检查报错

**问题**: 开发环境运行时更新检查失败

**原因**: 开发模式下没有签名，且没有发布版本

**解决方案**: 这是正常的，更新功能仅在生产构建中完全可用

可以添加环境检查:

```javascript
const isDev = import.meta.env.DEV;

if (isDev) {
  console.log('Update check disabled in development mode');
  return;
}
```

## 调试技巧

### 启用详细日志

在 `Navbar.vue` 中添加更多日志:

```javascript
const checkForUpdate = async () => {
  console.log('=== Update Check Started ===');
  console.log('Current version:', '0.1.0');
  console.log('Endpoint:', 'https://github.com/duwei0227/postmock/releases/latest/download/latest.json');
  
  try {
    const update = await check();
    console.log('Update check result:', update);
    // ...
  } catch (error) {
    console.error('Update check error:', error);
    console.error('Error details:', JSON.stringify(error, null, 2));
  }
};
```

### 检查网络请求

在浏览器开发者工具中:
1. 打开 Network 标签
2. 点击 "Check For Update"
3. 查看请求到 `latest.json` 的详情
4. 检查响应状态和内容

### 验证签名文件

```bash
# 查看签名文件内容
cat path/to/app.AppImage.sig

# 验证签名（需要 minisign 工具）
minisign -Vm app.AppImage -P <public_key>
```

## 获取帮助

如果以上方案都无法解决问题:

1. **查看文档**:
   - `.github/UPDATER_SETUP.md`
   - `.github/UPDATER_QUICKSTART.md`
   - `.github/GITHUB_SECRETS_SETUP.md`

2. **检查日志**:
   - GitHub Actions 工作流日志
   - 浏览器控制台日志
   - 应用日志（如果有）

3. **参考官方文档**:
   - [Tauri Updater](https://v2.tauri.app/plugin/updater/)
   - [GitHub Actions](https://docs.github.com/en/actions)

4. **提交 Issue**:
   - 包含错误信息
   - 包含相关日志
   - 说明复现步骤

## 预防措施

### 发布前检查清单

- [ ] 签名密钥已生成
- [ ] 公钥已配置到 `tauri.conf.json`
- [ ] 私钥已添加到 GitHub Secrets
- [ ] GitHub Actions 工作流语法正确
- [ ] 版本号已更新
- [ ] CHANGELOG 已更新
- [ ] 本地构建测试通过
- [ ] 所有测试通过

### 定期维护

- 每月检查依赖更新
- 每季度检查 Tauri 版本
- 定期备份签名密钥
- 定期检查 GitHub Secrets 访问日志

---

**最后更新**: 2026-03-05
