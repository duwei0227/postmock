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

## [0.1.0] - 2026-03-06

### 核心功能

#### HTTP 请求测试
- 支持多种 HTTP 方法（GET、POST、PUT、DELETE、PATCH、HEAD、OPTIONS）
- 请求参数配置（Query、Headers、Body）
- 多种 Body 格式支持（JSON、Form Data、Raw、Binary）
- 响应数据查看（Pretty、Raw、Headers）
- 响应时间和状态码显示

#### 文件下载
- 支持 HTTP 响应文件下载（Send And Download 按钮）
- 智能文件名提取（Content-Disposition、URL 路径、Content-Type）
- 支持 50+ 种 MIME 类型的文件扩展名映射
- 下载进度显示

#### 集合管理
- 创建和管理请求集合
- 文件夹分组支持
- 集合导入导出（JSON 格式）
- 拖拽排序

#### 环境变量
- 多环境配置支持
- 变量替换（{{variable}} 语法）
- 环境快速切换
- 全局变量支持

#### 请求历史
- 自动记录所有请求
- 历史记录搜索和过滤
- 从历史恢复请求
- 历史记录清理

#### 自动化测试
- 状态码断言
- JSON 字段值断言
- 响应时间断言
- 全局变量提取和设置
- 测试结果显示

#### 代码编辑器
- CodeMirror 6 集成
- 语法高亮（JSON、XML、HTML）
- 代码格式化
- 暗色主题支持

#### 导入功能
- cURL 命令导入
- 自动解析 URL、Headers、Body
- 支持复杂 cURL 命令

### 自动更新

#### 应用内更新
- 集成 Tauri Updater 插件
- 检查更新功能（Help → Check for Updates）
- 更新对话框显示版本信息和更新内容
- 下载进度显示
- 一键安装更新并重启

#### 更新清单
- GitHub Actions 自动生成更新清单
- 支持多平台更新（Windows、macOS、Linux）
- 签名验证确保更新安全

### 用户界面

#### 主题
- 现代化暗色主题
- PrimeVue Noir 预设
- TailwindCSS 样式系统
- 响应式布局

#### 组件
- 自定义无边框窗口
- 可调整大小的面板
- 上下文菜单
- 快捷键支持
- 加载状态和错误提示

### 数据持久化
- 本地文件系统存储
- 集合数据自动保存
- 环境变量持久化
- 请求历史记录
- 应用状态保存

### 跨平台支持

#### 桌面平台
- Windows（.exe、.msi、便携版 .zip）
- macOS（.dmg、.app.tar.gz）
- Linux（.deb、.rpm、.AppImage、便携版 .tar.gz）

#### 便携版增强
- Linux 便携版包含图标和 desktop 文件
- 自动桌面集成脚本
- Windows 便携版包含快捷方式创建脚本
- 无需安装即可运行

### 构建和发布

#### GitHub Actions
- 自动化构建工作流
- 多平台并行构建
- 签名密钥支持（带密码保护）
- 自动生成 Release 说明
- 更新清单自动发布

#### 开发工具
- YAML 语法验证脚本
- 自动化版本发布脚本
- 签名密钥管理脚本
- 本地更新测试脚本

### 文档

#### 用户文档
- README 使用说明
- 功能特性介绍
- 安装指南
- 快捷键参考

#### 开发文档
- 签名密钥配置指南
- Release Assets 说明
- CHANGELOG 工作流文档
- 本地更新测试指南
- 图标设计对比文档

### 应用图标
- 专业设计的应用图标
- 深色背景圆形设计
- 支持所有桌面平台
- 高分辨率支持（1024x1024）

### 技术栈

#### 前端
- Vue 3.5 - 渐进式 JavaScript 框架
- Vite 6 - 下一代前端构建工具
- PrimeVue 4 - Vue UI 组件库
- TailwindCSS 3 - 实用优先的 CSS 框架
- Pinia 2 - Vue 状态管理
- CodeMirror 6 - 代码编辑器

#### 后端
- Tauri 2 - 跨平台桌面应用框架
- Rust 2024 Edition - 系统编程语言
- tauri-plugin-http - HTTP 客户端
- tauri-plugin-fs - 文件系统访问
- tauri-plugin-dialog - 系统对话框
- tauri-plugin-updater - 自动更新
- tauri-plugin-process - 进程管理

#### 工具
- npm - 包管理器
- Cargo - Rust 包管理器
- GitHub Actions - CI/CD

### 安全性
- 签名密钥验证
- 更新包签名验证
- 密码保护的私钥
- CSP 安全策略

### 性能
- 快速启动时间
- 低内存占用
- 原生性能
- 响应式 UI

---

## 初始发布说明

这是 PostMock 的首个公开发布版本（v0.1.0）。PostMock 是一个现代化的跨平台 API 测试工具，使用 Tauri 和 Vue 3 构建，提供了简洁直观的界面和强大的功能。

### 主要特性
- 完整的 HTTP 请求测试功能
- 集合和环境管理
- 自动化测试支持
- 应用内自动更新
- 跨平台支持（Windows、macOS、Linux）
- 现代化的用户界面

### 下载
请访问 [GitHub Releases](https://github.com/duwei0227/postmock/releases/tag/v0.1.0) 下载适合您操作系统的安装包。

### 反馈
如有问题或建议，请在 [GitHub Issues](https://github.com/duwei0227/postmock/issues) 提交。

---

[Unreleased]: https://github.com/duwei0227/postmock/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/duwei0227/postmock/releases/tag/v0.1.0
