# 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 新增
- 待发布的新功能

### 变更
- 待发布的功能变更

### 修复
- 待发布的问题修复

## [0.1.1] - 2026-03-05

### 新增
- HTTP 请求支持文件下载功能（Send And Download 按钮）
- 集成 Tauri 自动更新功能，支持应用内检查和安装更新
- 添加更新对话框组件，显示更新进度和状态
- 智能文件名提取，支持从 Content-Disposition、URL 和 Content-Type 获取文件名
- 支持 50+ 种 MIME 类型的文件扩展名映射

### 改进
- 优化 GitHub Actions 工作流，支持带密码的签名密钥
- 改进 Release 说明模板，清晰标注用户下载文件和技术文件
- 添加 YAML 语法验证脚本（validate-yaml.sh/bat）
- 添加自动化版本发布脚本（release.sh）

### 文档
- 创建签名密钥配置文档（SIGNING_KEY_WITH_PASSWORD.md）
- 创建 Release Assets 说明文档（RELEASE_ASSETS_EXPLANATION.md）
- 完善自动更新功能文档

### 修复
- 修复 build-portable job 缺少签名密钥密码配置的问题
- 修复文件下载时文件名为空的问题

## [0.1.0] - 2024-03-04

### 新增
- HTTP 请求测试功能（GET、POST、PUT、DELETE、PATCH 等）
- 集合和文件夹管理
- 环境变量支持
- 请求历史记录
- 自动化测试（状态码、JSON 字段、全局变量）
- 暗色模式支持
- cURL 命令导入
- 集合导入导出功能
- 代码编辑器（支持 JSON、XML、HTML）
- 响应数据查看（Pretty、Raw、Headers）

### 技术栈
- Vue 3 + Vite
- Tauri 2
- PrimeVue + TailwindCSS
- Pinia 状态管理
- CodeMirror 6 编辑器

[Unreleased]: https://github.com/duwei0227/postmock/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/duwei0227/postmock/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/duwei0227/postmock/releases/tag/v0.1.0
