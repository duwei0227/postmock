# 项目技术栈官方文档清单

> 最后更新：2024-03-05
> 
> 此文件维护项目使用的所有技术栈的官方文档链接。
> 在添加新功能或修改配置时，必须参考这些最新文档。

## 核心框架

### Tauri
- **版本**: 2.x
- **官方文档**: https://v2.tauri.app/
- **配置参考**: https://v2.tauri.app/reference/config/
- **API 文档**: https://v2.tauri.app/reference/javascript/api/
- **分发指南**: https://v2.tauri.app/distribute/
- **GitHub**: https://github.com/tauri-apps/tauri
- **更新频率**: 每月检查

### Vue.js
- **版本**: 3.x
- **官方文档**: https://vuejs.org/
- **API 参考**: https://vuejs.org/api/
- **风格指南**: https://vuejs.org/style-guide/
- **GitHub**: https://github.com/vuejs/core
- **更新频率**: 每月检查

### Vite
- **版本**: 5.x
- **官方文档**: https://vitejs.dev/
- **配置参考**: https://vitejs.dev/config/
- **插件**: https://vitejs.dev/plugins/
- **GitHub**: https://github.com/vitejs/vite
- **更新频率**: 每月检查

## UI 框架

### PrimeVue
- **版本**: 4.x
- **官方文档**: https://primevue.org/
- **组件库**: https://primevue.org/components/
- **主题**: https://primevue.org/theming/
- **GitHub**: https://github.com/primefaces/primevue
- **更新频率**: 每季度检查

### TailwindCSS
- **版本**: 3.x
- **官方文档**: https://tailwindcss.com/docs
- **配置**: https://tailwindcss.com/docs/configuration
- **GitHub**: https://github.com/tailwindlabs/tailwindcss
- **更新频率**: 每季度检查

## 状态管理

### Pinia
- **版本**: 2.x
- **官方文档**: https://pinia.vuejs.org/
- **核心概念**: https://pinia.vuejs.org/core-concepts/
- **GitHub**: https://github.com/vuejs/pinia
- **更新频率**: 每季度检查

## 编辑器

### CodeMirror
- **版本**: 6.x
- **官方文档**: https://codemirror.net/docs/
- **参考手册**: https://codemirror.net/docs/ref/
- **GitHub**: https://github.com/codemirror/dev
- **更新频率**: 每季度检查

## 后端 (Rust)

### Rust
- **版本**: 1.80+ (Edition 2024)
- **官方文档**: https://doc.rust-lang.org/
- **Cargo 手册**: https://doc.rust-lang.org/cargo/
- **Edition 指南**: https://doc.rust-lang.org/edition-guide/
- **更新频率**: 每次 Rust 版本发布

### Tauri Plugins

#### tauri-plugin-http
- **文档**: https://v2.tauri.app/plugin/http/
- **GitHub**: https://github.com/tauri-apps/plugins-workspace

#### tauri-plugin-fs
- **文档**: https://v2.tauri.app/plugin/file-system/
- **GitHub**: https://github.com/tauri-apps/plugins-workspace

#### tauri-plugin-dialog
- **文档**: https://v2.tauri.app/plugin/dialog/
- **GitHub**: https://github.com/tauri-apps/plugins-workspace

#### tauri-plugin-opener
- **文档**: https://v2.tauri.app/plugin/opener/
- **GitHub**: https://github.com/tauri-apps/plugins-workspace

## 构建和部署

### GitHub Actions
- **官方文档**: https://docs.github.com/en/actions
- **工作流语法**: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
- **更新频率**: 每季度检查

### Flatpak
- **官方文档**: https://docs.flatpak.org/
- **构建指南**: https://docs.flatpak.org/en/latest/building.html
- **Flathub**: https://flathub.org/
- **更新频率**: 每季度检查

## 包管理

### npm
- **官方文档**: https://docs.npmjs.com/
- **CLI 命令**: https://docs.npmjs.com/cli/
- **更新频率**: 每季度检查

### Cargo
- **官方文档**: https://doc.rust-lang.org/cargo/
- **清单格式**: https://doc.rust-lang.org/cargo/reference/manifest.html
- **更新频率**: 每季度检查

## 规范和标准

### Conventional Commits
- **规范**: https://www.conventionalcommits.org/
- **更新频率**: 年度检查

### Semantic Versioning
- **规范**: https://semver.org/
- **更新频率**: 年度检查

### Keep a Changelog
- **规范**: https://keepachangelog.com/
- **更新频率**: 年度检查

## 使用指南

### 添加新技术栈时

1. 在此文件中添加条目
2. 包含：版本、官方文档、GitHub 链接
3. 设置更新检查频率
4. 在 steering 规则中引用

### 更新文档链接

1. 定期检查链接有效性
2. 更新版本号
3. 记录更新日期
4. 提交到版本控制

### 查询最新信息

在实现功能前，必须：
1. 查看此清单中的官方文档
2. 使用 `remote_web_search` 验证最新版本
3. 检查是否有破坏性变更
4. 参考官方示例代码

## 快速参考

```bash
# 检查 Tauri 配置
https://v2.tauri.app/reference/config/

# 检查 Vue 3 API
https://vuejs.org/api/

# 检查 Rust Edition
https://doc.rust-lang.org/edition-guide/

# 检查 GitHub Actions 语法
https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
```

## 维护日志

| 日期 | 更新内容 | 更新人 |
|------|---------|--------|
| 2024-03-05 | 初始创建文档清单 | duwei0227 |
| 2024-03-05 | 修复 Flatpak manifest：AppImage 二进制路径从 squashfs-root/postmock 更正为 squashfs-root/usr/bin/postmock（参考：https://docs.appimage.org/packaging-guide/manual.html） | duwei0227 |

