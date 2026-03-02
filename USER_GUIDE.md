# PostMock 用户指南

## 快速开始

### 创建第一个请求

1. **启动应用**
   - 运行 `npm run tauri dev`
   - 应用会自动加载之前保存的数据

2. **创建 Collection**
   - 点击左侧 "Collections" 标签
   - 点击 "新建 Collection" 按钮
   - 输入名称（如 "My API Tests"）
   - 点击 "创建"

3. **添加请求**
   - 右键点击 Collection
   - 选择 "Add Request"
   - 或点击顶部工具栏的 "+" 按钮

4. **编辑请求**
   - 选择 HTTP 方法（GET, POST, PUT, DELETE, PATCH）
   - 输入 URL
   - 添加参数、Headers、Body 等
   - 所有更改自动保存

5. **发送请求**
   - 点击 "Send" 按钮
   - 查看响应结果
   - 响应会自动添加到 History

## 主要功能

### Collections 管理

#### 创建 Collection
- 点击 "新建 Collection"
- 输入名称和描述
- 自动保存到本地

#### 创建 Folder
- 右键点击 Collection
- 选择 "Add Folder"
- 可以创建嵌套的文件夹结构

#### 重命名
- 右键点击 Collection/Folder/Request
- 选择 "Rename"
- 输入新名称

#### 删除
- 右键点击要删除的项
- 选择 "Delete"
- 确认删除

### 请求管理

#### 创建请求
方式 1: 从工具栏
- 点击顶部 "+" 按钮
- 自动添加到 "My Requests" Collection

方式 2: 从 Collection
- 右键点击 Collection 或 Folder
- 选择 "Add Request"
- 请求会添加到选中的位置

#### 打开请求
- 双击 Collection 中的请求
- 或右键选择 "Open Request"
- 请求会在新标签页打开

#### 编辑请求
1. **基本信息**
   - Method: 选择 HTTP 方法
   - URL: 输入请求地址
   - 支持环境变量 `{{variable}}`

2. **Params**
   - 添加 URL 查询参数
   - 可以启用/禁用单个参数

3. **Headers**
   - 添加请求头
   - 常用 Headers 会自动提示

4. **Body**
   - None: 无请求体
   - JSON: JSON 格式数据
   - Form Data: 表单数据
   - x-www-form-urlencoded: URL 编码表单

5. **Auth**
   - None: 无认证
   - Bearer Token: Token 认证
   - Basic Auth: 基本认证

6. **Tests**
   - 状态码断言
   - JSON 字段断言
   - 设置全局变量

### 环境变量

#### 创建环境
1. 点击顶部环境管理器图标
2. 点击 "+" 创建新环境
3. 输入环境名称

#### 添加变量
1. 选择环境
2. 添加变量（key-value）
3. 可以启用/禁用变量

#### 使用变量
- 在 URL、Headers、Body 中使用 `{{variableName}}`
- 发送请求时自动替换

#### 全局变量
- 在 Tests 中设置全局变量
- 可以从响应中提取值
- 在所有请求中可用

### 历史记录

#### 查看历史
- 点击左侧 "History" 标签
- 显示最近的请求记录

#### 从历史打开
- 双击历史记录
- 会创建新的请求标签页

#### 清除历史
- 点击 "Clear History" 按钮
- 确认清除

### 导入导出

#### 导出 Collection
1. 右键点击 Collection
2. 选择 "Export"
3. 选择保存位置
4. 保存为 JSON 文件

#### 导入 Collection
1. 点击 Collections 面板的上传图标
2. 选择 JSON 文件
3. 自动导入并保存
4. ID 会自动重映射避免冲突

### 标签页管理

#### 打开多个请求
- 可以同时打开多个请求
- 每个请求在独立标签页中

#### 关闭标签页
- 点击标签页的 "×" 按钮
- 或右键选择 "Close"

#### 标签页操作
右键点击标签页：
- Duplicate Tab: 复制标签页
- Close: 关闭当前标签页
- Close Other Tabs: 关闭其他标签页
- Close All Tabs: 关闭所有标签页

## 数据存储

### 自动保存
- 所有更改自动保存
- 无需手动保存操作
- 防抖机制避免频繁写入

### 数据位置
- **Linux**: `~/.local/share/postmock/`
- **macOS**: `~/Library/Application Support/postmock/`
- **Windows**: `%APPDATA%\postmock\`

### 数据结构
```
postmock/
├── collections/     # Collections 数据
├── requests/        # Requests 数据
├── environments/    # 环境变量
├── history/         # 历史记录
├── app-state.json   # 应用状态
└── backups/         # 备份
```

### 状态恢复
- 关闭应用后重新打开
- 自动恢复所有数据
- 恢复打开的标签页
- 恢复 UI 状态

## 快捷键

### 全局
- `Ctrl/Cmd + N`: 新建请求
- `Ctrl/Cmd + S`: 保存（自动保存，无需手动）
- `Ctrl/Cmd + W`: 关闭当前标签页

### 请求编辑
- `Ctrl/Cmd + Enter`: 发送请求
- `Tab`: 在输入框间切换

## 技巧和最佳实践

### 组织 Collections
1. **按项目分组**
   - 为每个项目创建一个 Collection
   - 使用 Folders 组织相关请求

2. **命名规范**
   - 使用清晰的名称
   - 包含 HTTP 方法（如 "GET Users"）
   - 使用描述性的 Folder 名称

### 使用环境变量
1. **创建多个环境**
   - Development
   - Staging
   - Production

2. **使用变量**
   - `{{baseUrl}}/api/users`
   - `{{apiKey}}`
   - 避免硬编码

### 测试和断言
1. **状态码测试**
   - 验证响应状态码
   - 使用多个断言

2. **JSON 字段测试**
   - 使用 JSONPath 提取值
   - 验证响应数据

3. **全局变量**
   - 从响应中提取 token
   - 在后续请求中使用

### 导入导出
1. **定期导出**
   - 导出重要的 Collections
   - 作为备份

2. **团队协作**
   - 导出 Collection 分享给团队
   - 团队成员导入使用

## 故障排除

### 数据未保存
- 检查文件系统权限
- 查看控制台错误信息
- 确保有足够的磁盘空间

### 请求失败
- 检查 URL 是否正确
- 验证网络连接
- 查看 Console 标签的错误信息

### 导入失败
- 确保 JSON 格式正确
- 检查文件版本兼容性
- 查看错误通知详情

### 应用崩溃
- 查看日志文件
- 删除损坏的数据文件
- 从备份恢复

## 获取帮助

### 日志位置
- 查看控制台输出
- 检查 Tauri 日志

### 报告问题
1. 描述问题
2. 提供复现步骤
3. 附上错误信息
4. 说明操作系统版本

## 更新日志

### v0.1.0 (当前版本)
- ✅ 完整的数据持久化
- ✅ Collections 管理
- ✅ 请求编辑和发送
- ✅ 环境变量支持
- ✅ 历史记录
- ✅ 导入导出功能
- ✅ 自动保存和状态恢复

## 即将推出

- 📋 Postman 格式导入
- 🔄 数据同步
- 🎨 自定义主题
- 📊 请求统计
- 🔌 插件系统
