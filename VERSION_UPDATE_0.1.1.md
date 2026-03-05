# 版本更新：0.1.0 → 0.1.1

## 更新日期
2026-03-05

## 版本号更新

已更新以下文件中的版本号：

### 1. package.json
```json
"version": "0.1.1"
```

### 2. src-tauri/tauri.conf.json
```json
"version": "0.1.1"
```

### 3. src-tauri/Cargo.toml
```toml
version = "0.1.1"
```

## 本次更新内容

### 新增功能
- ✅ 实现了 HttpRequest 组件的文件下载功能（Send And Download）
- ✅ 集成了 Tauri 自动更新功能（Updater Plugin）
- ✅ 添加了 UpdateDialog 组件用于显示更新信息

### 配置改进
- ✅ 配置了带密码的签名密钥系统
- ✅ 优化了 GitHub Actions 工作流
- ✅ 改进了 Release 说明模板，清晰标注用户下载文件

### 文档完善
- ✅ 创建了签名密钥配置文档（SIGNING_KEY_WITH_PASSWORD.md）
- ✅ 创建了 Release Assets 说明文档（RELEASE_ASSETS_EXPLANATION.md）
- ✅ 创建了 YAML 语法验证脚本（validate-yaml.sh/bat）

### Bug 修复
- ✅ 修复了 build-portable job 缺少密码配置的问题
- ✅ 修复了文件下载时文件名提取的问题

## 测试自动更新功能

### 前置条件

1. **确认 GitHub Secrets 已配置**
   - `TAURI_SIGNING_PRIVATE_KEY` - 私钥内容
   - `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` - 私钥密码

2. **确认本地密钥文件存在**
   ```bash
   ls -la postmock.key postmock.key.pub
   ```

3. **验证 YAML 语法**
   ```bash
   ./scripts/validate-yaml.sh .github/workflows/release.yml
   ```

### 发布步骤

#### 1. 提交版本更新
```bash
git add package.json src-tauri/tauri.conf.json src-tauri/Cargo.toml
git commit -m "chore: bump version to 0.1.1"
git push
```

#### 2. 创建并推送 tag
```bash
git tag v0.1.1
git push origin v0.1.1
```

#### 3. 监控 GitHub Actions
访问：https://github.com/duwei0227/postmock/actions

确认以下 jobs 都成功：
- ✅ create-release
- ✅ build-tauri (所有平台)
- ✅ build-portable (Linux 和 Windows)
- ✅ generate-updater-manifest

#### 4. 验证 Release Assets

访问：https://github.com/duwei0227/postmock/releases/tag/v0.1.1

确认包含以下文件：

**用户安装包：**
- PostMock_0.1.1_x64.msi
- PostMock_0.1.1_x64-setup.exe
- postmock-0.1.1-windows-x64-portable.zip
- PostMock_0.1.1_aarch64.dmg
- PostMock_0.1.1_x64.dmg
- PostMock_0.1.1_amd64.AppImage
- PostMock_0.1.1_amd64.deb
- PostMock-0.1.1-1.x86_64.rpm
- postmock-0.1.1-linux-x64-portable.tar.gz

**自动更新文件：**
- *.sig (签名文件)
- *.app.tar.gz (macOS 更新包)
- latest.json (更新清单)

### 测试自动更新

#### 方法 1：使用 0.1.0 版本测试

1. 安装 0.1.0 版本的应用
2. 打开应用
3. 点击 Help → Check for Updates
4. 应该检测到 0.1.1 版本
5. 点击 Download and Install
6. 等待下载和安装完成
7. 重启应用
8. 验证版本号已更新为 0.1.1

#### 方法 2：手动验证更新清单

```bash
# 下载 latest.json
curl -L https://github.com/duwei0227/postmock/releases/latest/download/latest.json

# 验证内容
cat latest.json | jq .
```

应该看到：
```json
{
  "version": "0.1.1",
  "notes": "...",
  "pub_date": "2026-03-05T...",
  "platforms": {
    "linux-x86_64": {
      "signature": "...",
      "url": "https://github.com/duwei0227/postmock/releases/download/v0.1.1/postmock_0.1.1_amd64.AppImage"
    },
    ...
  }
}
```

## 预期结果

### GitHub Actions 构建
- ✅ 所有平台构建成功
- ✅ 生成所有签名文件
- ✅ 生成 latest.json 清单
- ✅ Release 自动创建并上传所有文件

### 自动更新功能
- ✅ 应用能检测到新版本
- ✅ 能下载更新包
- ✅ 签名验证通过
- ✅ 更新安装成功
- ✅ 重启后版本号正确

### Release 页面
- ✅ Release 说明清晰，引导用户下载正确的文件
- ✅ 所有安装包和技术文件都已上传
- ✅ 文件命名规范，包含版本号

## 故障排除

### 如果构建失败

1. **检查签名密钥配置**
   ```bash
   # 验证本地密钥
   head -n 1 postmock.key
   # 应该显示: dW50cnVzdGVkIGNvbW1lbnQ6IHJzaWduIGVuY3J5cHRlZCBzZWNyZXQga2V5
   ```

2. **检查 GitHub Secrets**
   - 访问仓库 Settings → Secrets and variables → Actions
   - 确认 `TAURI_SIGNING_PRIVATE_KEY` 和 `TAURI_SIGNING_PRIVATE_KEY_PASSWORD` 存在

3. **查看构建日志**
   - 访问 GitHub Actions 页面
   - 点击失败的 workflow
   - 查看详细错误信息

### 如果自动更新失败

1. **检查更新端点**
   - 确认 `src-tauri/tauri.conf.json` 中的 `plugins.updater.endpoints` 正确
   - 确认 `latest.json` 文件存在于 Release 中

2. **检查签名验证**
   - 确认 `.sig` 文件已生成
   - 确认公钥在 `tauri.conf.json` 中配置正确

3. **查看应用日志**
   - 打开开发者工具查看控制台输出
   - 检查是否有网络错误或签名验证错误

## 回滚方案

如果 0.1.1 版本有严重问题，可以：

1. **删除 Release**
   ```bash
   gh release delete v0.1.1 --yes
   git tag -d v0.1.1
   git push origin :refs/tags/v0.1.1
   ```

2. **回滚代码**
   ```bash
   git revert HEAD
   git push
   ```

3. **重新发布修复版本**
   - 修复问题
   - 更新版本号为 0.1.2
   - 重新发布

## 下一步

- [ ] 测试所有平台的安装包
- [ ] 验证自动更新功能
- [ ] 收集用户反馈
- [ ] 准备 0.1.2 版本的改进计划

## 相关文档

- [SIGNING_KEY_WITH_PASSWORD.md](.github/SIGNING_KEY_WITH_PASSWORD.md) - 签名密钥配置
- [RELEASE_ASSETS_EXPLANATION.md](.github/RELEASE_ASSETS_EXPLANATION.md) - Release Assets 说明
- [UPDATER_QUICKSTART.md](.github/UPDATER_QUICKSTART.md) - 自动更新快速指南

---

**创建日期：** 2026-03-05
