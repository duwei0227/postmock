<script setup>
import { ref } from 'vue';

const props = defineProps({
  visible: {
    type: Boolean,
    default: false
  }
});

const emit = defineEmits(['update:visible']);

const activeTab = ref(0);

const docs = [
  {
    title: '快速开始',
    content: `# 快速开始

## 创建第一个请求

1. 点击 "+" 按钮或按 Ctrl+N 创建新请求
2. 在地址栏输入 URL
3. 选择 HTTP 方法（GET、POST、PUT、DELETE 等）
4. 点击 "Send" 或按 Ctrl+Enter 发送请求

## 基本操作

### 保存请求
- 点击保存按钮或按 Ctrl+S
- 选择要保存到的 Collection 和 Folder
- 输入请求名称

### 管理标签页
- Ctrl+W: 关闭当前标签页
- Ctrl+Tab: 切换到下一个标签页
- Ctrl+Shift+Tab: 切换到上一个标签页
    `
  },
  {
    title: '请求配置',
    content: `# 请求配置

## URL 参数（Params）

在 Params 标签页中添加查询参数：

**示例**：
\`\`\`
键: page    值: 1
键: size    值: 20
键: sort    值: name
\`\`\`

最终 URL: \`https://api.example.com/users?page=1&size=20&sort=name\`

## 请求头（Headers）

在 Headers 标签页中添加自定义请求头：

**常用示例**：
\`\`\`
Content-Type: application/json
Authorization: Bearer {{token}}
Accept: application/json
User-Agent: Postmock/1.0
\`\`\`

## 请求体（Body）

支持多种格式：

### JSON
\`\`\`json
{
  "username": "user{{$sequence(padding=3)}}",
  "email": "user@example.com",
  "age": {{$randomInt(18, 60)}}
}
\`\`\`

### Form Data
适用于文件上传和表单提交

### URL Encoded
适用于传统表单提交

## 认证（Auth）

支持多种认证方式：
- Bearer Token
- Basic Auth
- No Auth
    `
  },
  {
    title: '变量系统',
    content: `# 变量系统

## 环境变量

创建不同环境（开发、测试、生产）管理 API 端点：

**示例**：
\`\`\`
环境: 开发环境
baseUrl = http://localhost:3000
apiKey = dev_key_123

环境: 生产环境
baseUrl = https://api.example.com
apiKey = prod_key_456
\`\`\`

**使用**：
\`\`\`
{{baseUrl}}/api/users
Authorization: Bearer {{apiKey}}
\`\`\`

## 全局变量

### 时间相关
- \`{{$timestamp}}\` - Unix 时间戳（毫秒）
- \`{{$isoTimestamp}}\` - ISO 8601 格式时间
- \`{{$date}}\` - 当前日期（yyyy-MM-dd）
- \`{{$date("yyyy/MM/dd")}}\` - 自定义日期格式
- \`{{$time}}\` - 当前时间（HH:mm:ss）
- \`{{$datetime}}\` - 日期时间（yyyy-MM-dd HH:mm:ss）

### 随机数据
- \`{{$guid}}\` - 生成 UUID
- \`{{$randomInt}}\` - 随机整数（0-1000）
- \`{{$randomInt(1, 100)}}\` - 指定范围的随机整数
- \`{{$randomInt(min=1, max=100)}}\` - 命名参数格式

### 随机字符串
- \`{{$randomAlpha}}\` - 随机字母（10位）
- \`{{$randomAlpha(20)}}\` - 指定长度
- \`{{$randomNumeric(6)}}\` - 随机数字
- \`{{$randomUppercase(8)}}\` - 随机大写字母
- \`{{$randomLowercase(12)}}\` - 随机小写字母
- \`{{$randomAlphanumeric(16)}}\` - 字母数字混合
- \`{{$randomChinese(10)}}\` - 随机中文字符

### 自增序列
- \`{{$sequence}}\` - 默认序列：1, 2, 3...
- \`{{$sequence(name=order)}}\` - 命名序列
- \`{{$sequence(padding=5)}}\` - 零填充：00001, 00002...
- \`{{$sequence(start=100)}}\` - 指定起始值
- \`{{$sequence(step=10)}}\` - 指定步长
- \`{{$sequence(name=order, padding=6, start=1000, step=5)}}\` - 完整配置

**序列示例**：
\`\`\`json
{
  "orderId": "ORD-{{$sequence(name=order, padding=8)}}",
  "userId": "USER-{{$sequence(name=user, padding=5)}}",
  "timestamp": "{{$timestamp}}"
}
\`\`\`

输出：
\`\`\`json
{
  "orderId": "ORD-00000001",
  "userId": "USER-00001",
  "timestamp": "1709510400000"
}
\`\`\`
    `
  },
  {
    title: '序列管理',
    content: `# 序列管理

## 什么是序列？

序列提供自动递增的数字，适用于：
- 生成订单号
- 创建用户 ID
- 测试分页
- 批量数据生成

## 管理序列

### 查看序列
1. 点击工具栏的序列图标（数字上升图标）
2. 查看所有序列的当前值、步长、填充等信息

### 编辑序列
1. 点击序列右侧的编辑按钮
2. 修改当前值、步长、填充位数
3. 保存更改

### 删除序列
点击序列右侧的删除按钮

## 查看当前请求使用的变量

点击眼睛图标查看：
- 环境变量
- 全局变量
- 当前请求使用的序列

## 参数优先级

**首次创建**：使用提供的所有参数
**后续使用**：
- 忽略 start 和 step 参数（使用序列配置）
- padding 参数仅用于格式化显示

**示例**：
\`\`\`
请求 1: {{$sequence(name=test, padding=4, step=2)}}
发送 → 0001

请求 2: {{$sequence(name=test, padding=6, step=5)}}
发送 → 000003 (使用 step=2，不是 step=5)
\`\`\`

**最佳实践**：
- 在序列管理界面统一配置核心参数
- 请求中只指定 name 和 padding
- 需要不同行为时使用不同序列名称
    `
  },
  {
    title: 'Collections',
    content: `# Collections（集合）

## 创建 Collection

1. 点击 "New Collection" 按钮
2. 输入集合名称和描述
3. 可以创建文件夹组织请求

## 导入/导出

### 导入
- 支持从 Postman、Insomnia 等工具导入
- 导入 cURL 命令（Ctrl+Shift+V）

### 导出
- 导出 Collection 分享给团队
- 支持 JSON 格式

## 管理请求

- 拖拽重新排序
- 复制请求
- 在 Collection 之间移动
- 右键菜单快速操作

## 文件夹

- 创建多级文件夹
- 按功能或模块组织请求
- 折叠/展开文件夹
    `
  },
  {
    title: '测试功能',
    content: `# 测试功能

## 状态码测试

验证响应状态码：
- 等于（equals）
- 不等于（not equals）
- 大于（greater than）
- 小于（less than）

**示例**：
\`\`\`
状态码 equals 200
状态码 less than 400
\`\`\`

## JSON 字段测试

验证响应 JSON 中的字段：

**示例**：
\`\`\`
字段: data.id
操作: exists (存在)

字段: data.status
操作: equals
期望值: success

字段: data.items
操作: has length
期望值: 10
\`\`\`

## 全局变量提取

从响应中提取数据保存为全局变量：

**示例**：
\`\`\`
变量名: token
JSON 路径: data.token

变量名: userId
JSON 路径: data.user.id
\`\`\`

提取后可在后续请求中使用：
\`\`\`
Authorization: Bearer {{token}}
\`\`\`
    `
  },
  {
    title: '实用技巧',
    content: `# 实用技巧

## 批量测试

使用序列快速生成测试数据：

\`\`\`json
{
  "username": "user{{$sequence(padding=4)}}",
  "email": "user{{$sequence}}@test.com",
  "phone": "138{{$sequence(name=phone, padding=8)}}"
}
\`\`\`

连续发送 10 次请求，自动生成不同的用户数据。

## 组合变量

\`\`\`json
{
  "orderId": "{{$date('yyyyMMdd')}}-{{$sequence(name=order, padding=6)}}",
  "createTime": "{{$datetime}}",
  "amount": {{$randomInt(100, 10000)}},
  "currency": "CNY"
}
\`\`\`

输出：
\`\`\`json
{
  "orderId": "20260304-000001",
  "createTime": "2026-03-04 13:30:45",
  "amount": 5678,
  "currency": "CNY"
}
\`\`\`

## 环境切换

快速在不同环境间切换：
1. 在顶部选择环境下拉框
2. 选择目标环境
3. 所有请求自动使用新环境的变量

## 历史记录

- 自动保存所有发送的请求
- 点击历史面板查看
- 可以从历史创建新请求

## 快捷键

按 Ctrl+/ 查看所有快捷键
    `
  }
];

const closeDialog = () => {
  emit('update:visible', false);
};
</script>

<template>
  <Dialog
    :visible="visible"
    @update:visible="closeDialog"
    header="文档"
    :modal="true"
    :style="{ width: '800px', height: '600px' }"
    :dismissableMask="true"
  >

    <div class="documentation-container flex h-full">
      <!-- Sidebar -->
      <div class="doc-sidebar w-48 border-r border-surface-200 dark:border-surface-700 pr-4">
        <div class="space-y-1">
          <button
            v-for="(doc, index) in docs"
            :key="index"
            @click="activeTab = index"
            class="w-full text-left px-3 py-2 rounded text-sm transition"
            :class="activeTab === index 
              ? 'bg-primary text-white' 
              : 'hover:bg-surface-100 dark:hover:bg-surface-800 text-surface-700 dark:text-surface-300'"
          >
            {{ doc.title }}
          </button>
        </div>
      </div>

      <!-- Content -->
      <div class="doc-content flex-1 pl-6 overflow-y-auto">
        <div class="prose dark:prose-invert max-w-none">
          <pre class="whitespace-pre-wrap text-sm leading-relaxed text-surface-700 dark:text-surface-300">{{ docs[activeTab].content }}</pre>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex justify-between items-center">
        <span class="text-xs text-surface-500 dark:text-surface-400">
          按 F1 可随时打开文档
        </span>
        <Button label="关闭" @click="closeDialog" />
      </div>
    </template>
  </Dialog>
</template>

<style scoped>
.documentation-container {
  min-height: 500px;
}

.doc-content {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.doc-content pre {
  background: transparent;
  padding: 0;
  margin: 0;
  border: none;
}
</style>
