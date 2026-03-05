# PostMock 项目文档

本目录包含 PostMock 项目的配置和文档文件。

## 📚 文档索引

### 核心文档

#### 🔐 签名密钥配置（重要）
- **[KEY_QUICK_REFERENCE.md](KEY_QUICK_REFERENCE.md)** 📋 - 签名密钥配置速查卡（推荐打印）
  - 3 步快速配置
  - 格式速查表
  - 常用命令
  - 常见错误速查
- **[SIGNING_KEYS_GUIDE.md](SIGNING_KEYS_GUIDE.md)** ⭐ - Tauri 签名密钥生成和配置完整指南
  - 密钥格式说明
  - 生成步骤
  - 配置方法
  - 常见错误解决
- **[KEY_CONFIGURATION_REFERENCE.md](KEY_CONFIGURATION_REFERENCE.md)** 📘 - 密钥配置技术参考手册
  - 技术背景和原理
  - 密钥格式详解
  - 配置规则详细说明
  - 工作流处理逻辑
  - 完整的验证和故障排除方法

#### 🚀 自动更新功能
- **[UPDATER_QUICKSTART.md](UPDATER_QUICKSTART.md)** - 快速启动指南（已配置完成）
- [UPDATER_SETUP.md](UPDATER_SETUP.md) - 详细设置指南
- [TESTING_UPDATES.md](TESTING_UPDATES.md) - 测试更新功能

#### ⚙️ GitHub 配置
- [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md) - GitHub Secrets 配置步骤
- [workflows/release.yml](workflows/release.yml) - 发布工作流

#### 🔧 故障排除
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 常见问题和解决方案
- [QUICK_FIX_SIGNING_ERROR.md](QUICK_FIX_SIGNING_ERROR.md) - 签名错误快速修复

### 开发文档

#### 📦 发布流程
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) - 发布前检查清单
- [RELEASE_TEMPLATE.md](RELEASE_TEMPLATE.md) - Release 描述模板
- [RELEASE.md](RELEASE.md) - 发布说明

#### 📝 变更日志
- [CHANGELOG_AUTOMATION.md](CHANGELOG_AUTOMATION.md) - 自动生成变更日志
- [COMMIT_CONVENTION.md](COMMIT_CONVENTION.md) - 提交信息规范

#### 📦 分发
- [DISTRIBUTION.md](DISTRIBUTION.md) - 分发格式说明
- [PORTABLE_GUIDE.md](PORTABLE_GUIDE.md) - 便携版指南

#### 📋 元数据
- [PACKAGE_METADATA.md](PACKAGE_METADATA.md) - 包元数据配置

### 其他

- [copilot-instructions.md](copilot-instructions.md) - GitHub Copilot 指令
- [release.yml](release.yml) - Release 配置

## 🎯 快速导航

### 我想...

**快速查找密钥配置信息**
1. 查看 [KEY_QUICK_REFERENCE.md](KEY_QUICK_REFERENCE.md) 速查卡

**配置自动更新功能**
1. 阅读 [SIGNING_KEYS_GUIDE.md](SIGNING_KEYS_GUIDE.md) 了解密钥配置
2. 参考 [UPDATER_QUICKSTART.md](UPDATER_QUICKSTART.md) 快速上手

**深入了解密钥配置原理**
1. 阅读 [KEY_CONFIGURATION_REFERENCE.md](KEY_CONFIGURATION_REFERENCE.md) 技术参考

**发布新版本**
1. 查看 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)
2. 按照 [UPDATER_QUICKSTART.md](UPDATER_QUICKSTART.md) 中的"发布新版本"步骤操作

**解决签名问题**
1. 查看 [KEY_QUICK_REFERENCE.md](KEY_QUICK_REFERENCE.md) 的常见错误部分
2. 参考 [KEY_CONFIGURATION_REFERENCE.md](KEY_CONFIGURATION_REFERENCE.md) 的故障排除章节
3. 查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**配置 GitHub Secrets**
1. 阅读 [GITHUB_SECRETS_SETUP.md](GITHUB_SECRETS_SETUP.md)
2. 参考 [SIGNING_KEYS_GUIDE.md](SIGNING_KEYS_GUIDE.md) 中的配置步骤

## ✅ 当前状态

- ✅ 自动更新功能已配置并验证
- ✅ 签名密钥已正确配置
- ✅ GitHub Actions 工作流正常运行
- ✅ 所有平台构建成功

## 📞 获取帮助

如果遇到问题：
1. 查看 [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. 检查 GitHub Actions 日志
3. 参考相关文档的"故障排除"部分

---

**维护者：** duwei0227  
**最后更新：** 2024-03-05
