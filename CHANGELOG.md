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

## [0.1.1] - 2026-03-09

### 新增
- **请求取消功能**：在发送请求时可以随时点击 Cancel 按钮取消正在进行的请求
- **请求加载状态**：Response 区域显示 "Sending Request..." 加载遮罩层，提供更好的视觉反馈
- **JSON 编辑器变量提示**：JSON Body 编辑器支持变量自动完成和参数提示
  - 输入 `{{` 自动显示所有可用变量（环境变量、全局变量、内置变量）
  - 内置变量（如 `$date`、`$time`、`$datetime` 等）优先显示
  - 输入函数参数时（如 `$date(`）显示详细的参数说明面板
  - 支持模糊搜索变量名
  - 按 Esc 键关闭参数提示面板

### 变更
- **测试结果处理**：取消请求后，所有启用的断言将标记为失败，不会设置全局变量
- **AbortController 支持**：使用标准的 AbortController API 实现请求取消功能
- **错误处理优化**：取消的请求不会显示错误提示，避免误导用户

### 修复
- 修复 JSON 编辑器自动完成列表中选中项对比度不足的问题
  - 亮色主题：选中项使用蓝色背景（#3b82f6）和白色文字
  - 暗色主题：选中项使用深蓝色背景（#2563eb）和白色文字
- 修复内置变量（`$date`、`$time` 等）在自动完成列表中不显示的问题
- 优化变量自动完成的触发和匹配逻辑

## [0.1.0] - 2026-03-06

PostMock 首个公开发布版本！一个现代化的跨平台 API 测试工具。

### 核心功能

#### HTTP 请求测试
- 支持所有常用 HTTP 方法（GET、POST、PUT、DELETE、PATCH、HEAD、OPTIONS）
- 灵活配置请求参数、Headers 和 Body
- 支持多种 Body 格式（JSON、Form Data、Raw、Binary）
- 清晰展示响应数据、Headers 和状态码
- 显示请求响应时间

#### 文件下载
- 一键下载 API 响应文件
- 智能识别文件名和类型
- 支持 50+ 种常见文件格式

#### 集合管理
- 创建和组织请求集合
- 使用文件夹分组管理请求
- 导入导出集合（JSON 格式）
- 拖拽排序请求

#### 环境变量
- 创建多个环境配置（开发、测试、生产等）
- 使用 `{{变量名}}` 语法在请求中引用变量
- 快速切换环境
- 支持全局变量

#### 请求历史
- 自动记录所有发送的请求
- 搜索和过滤历史记录
- 从历史快速恢复请求
- 清理历史记录

#### 自动化测试
- 验证响应状态码
- 检查 JSON 字段值
- 测试响应时间
- 提取响应数据到变量
- 查看测试结果

#### 导入功能
- 从 cURL 命令导入请求
- 自动解析 URL、Headers 和 Body

#### 应用内更新
- 自动检查新版本
- 查看更新内容
- 一键下载并安装更新
- 无需手动下载安装包

### 用户界面
- 现代化暗色主题
- 简洁直观的操作界面
- 响应式布局适配不同屏幕
- 代码编辑器支持语法高亮和格式化

### 跨平台支持
- Windows（安装包和便携版）
- macOS（DMG 安装包）
- Linux（DEB、RPM、AppImage 和便携版）

### 便携版特性
- 无需安装，解压即用
- 包含桌面快捷方式创建工具
- 适合在 U 盘或移动设备上使用

---

## 初始发布说明

欢迎使用 PostMock v0.1.0！

PostMock 是一个轻量级、跨平台的 API 测试工具，旨在为开发者提供简单高效的 HTTP 接口测试体验。

### 主要特点
- 🚀 快速启动，低内存占用
- 💻 支持 Windows、macOS 和 Linux
- 🎨 现代化的用户界面
- 📦 集合管理和环境变量支持
- 🔄 应用内自动更新
- 🧪 自动化测试功能

### 下载
请访问 [GitHub Releases](https://github.com/duwei0227/postmock/releases/tag/v0.1.0) 下载适合您操作系统的版本。

### 反馈与支持
- 问题反馈：[GitHub Issues](https://github.com/duwei0227/postmock/issues)
- 功能建议：[GitHub Discussions](https://github.com/duwei0227/postmock/discussions)

感谢您的使用！

---

[Unreleased]: https://github.com/duwei0227/postmock/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/duwei0227/postmock/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/duwei0227/postmock/releases/tag/v0.1.0
