# 自增序列功能使用说明

## 功能概述

自增序列功能允许您在请求中使用自动递增的数字序列，每次发送请求时序列值会自动增加。支持多个独立序列、自定义步长、零填充等特性。

## 基本用法

### 1. 默认序列

最简单的用法，使用默认序列（名称为 "default"），从 1 开始，每次增加 1：

```
{{$sequence}}
```

**输出示例**：
- 第 1 次：`1`
- 第 2 次：`2`
- 第 3 次：`3`

### 2. 使用命名参数（推荐）

通过命名参数指定需要的配置，其他参数使用默认值：

```
{{$sequence(start=100)}}              // 只指定起始值
{{$sequence(step=10)}}                // 只指定步长
{{$sequence(padding=5)}}              // 只指定零填充
{{$sequence(name=order)}}             // 只指定序列名称
{{$sequence(start=100, step=10)}}     // 指定起始值和步长
{{$sequence(name=order, start=1000, padding=6)}}  // 多个参数组合
```

**命名参数说明**：
- `name`: 序列名称
- `start` 或 `startValue`: 起始值
- `step`: 步长
- `padding` 或 `pad`: 零填充位数

**输出示例**：
```
{{$sequence(start=100)}}              → 100, 101, 102, ...
{{$sequence(step=10)}}                → 1, 11, 21, 31, ...
{{$sequence(padding=5)}}              → 00001, 00002, 00003, ...
{{$sequence(start=100, step=10)}}     → 100, 110, 120, ...
{{$sequence(name=order, start=1000, padding=6)}} → 001000, 001001, 001002, ...
```

### 3. 使用位置参数

按顺序传递参数（传统方式）：

```
{{$sequence(100)}}                    // 只传数字，视为起始值
{{$sequence(orderNo)}}                // 只传字符串，视为序列名称
{{$sequence(orderNo, 5)}}             // 序列名称 + 零填充
{{$sequence(orderNo, 5, 1000)}}       // 序列名称 + 零填充 + 起始值
{{$sequence(orderNo, 5, 1000, 10)}}   // 完整参数
```

**输出示例**：
```
{{$sequence(100)}}                    → 100, 101, 102, ...
{{$sequence(orderNo, 5)}}             → 00001, 00002, 00003, ...
{{$sequence(orderNo, 5, 1000)}}       → 01000, 01001, 01002, ...
{{$sequence(orderNo, 5, 1000, 10)}}   → 01000, 01010, 01020, ...
```

### 4. 命名序列

创建独立的命名序列，不同名称的序列互不影响：

```
{{$sequence(name=orderNo)}}
{{$sequence(name=userId)}}
```

**输出示例**：
- `orderNo` 序列：`1`, `2`, `3`, ...
- `userId` 序列：`1`, `2`, `3`, ...（独立计数）

## 参数说明

### 命名参数格式（推荐）

```
$sequence(key=value, key=value, ...)
```

| 参数名 | 别名 | 类型 | 默认值 | 说明 |
|--------|------|------|--------|------|
| name | - | string | "default" | 序列名称，用于区分不同的序列 |
| padding | pad | number | 0 | 零填充位数，0 表示不填充 |
| start | startValue | number | 1 | 起始值 |
| step | - | number | 1 | 每次递增的步长 |

**示例**：
```
{{$sequence(start=100)}}
{{$sequence(name=order, padding=5, start=1000, step=10)}}
{{$sequence(step=5)}}
```

### 位置参数格式

```
$sequence(name, padding, startValue, step)
或
$sequence(startValue)  // 只传数字时视为起始值
```

| 位置 | 参数 | 类型 | 默认值 | 说明 |
|------|------|------|--------|------|
| 1 | name 或 startValue | string/number | "default" 或 1 | 如果是纯数字则视为起始值，否则视为序列名称 |
| 2 | padding | number | 0 | 零填充位数 |
| 3 | startValue | number | 1 | 起始值 |
| 4 | step | number | 1 | 步长 |

**示例**：
```
{{$sequence(100)}}                    // 起始值 100
{{$sequence(order, 5, 1000, 10)}}     // 完整参数
```

## 序列管理

### 打开序列管理界面

1. 点击顶部工具栏的 **序列图标**（数字上升图标）
2. 在弹出的对话框中可以查看所有序列

### 查看序列信息

序列管理界面显示：
- **序列名称**：序列的唯一标识
- **当前值**：下次使用时将返回的值
- **起始值**：序列的初始值
- **步长**：每次递增的数值
- **填充位数**：零填充的位数

### 编辑序列

1. 点击序列右侧的 **编辑图标**
2. 可以修改：
   - **当前值**：重置序列到指定值
   - **步长**：修改递增步长
   - **填充位数**：修改零填充位数
3. 点击 **保存** 应用更改

### 删除序列

1. 点击序列右侧的 **删除图标**
2. 确认删除操作
3. 序列将被永久删除

## 实际应用场景

### 场景 1：生成订单号（使用命名参数）

```json
{
  "orderId": "ORD-{{$sequence(name=order, padding=8, start=10000000)}}",
  "timestamp": "{{$timestamp}}"
}
```

**输出**：
```json
{
  "orderId": "ORD-10000000",
  "timestamp": "1709510400000"
}
```

### 场景 2：测试不同步长

```json
{
  "evenNumbers": {{$sequence(name=even, start=2, step=2)}},
  "oddNumbers": {{$sequence(name=odd, start=1, step=2)}},
  "multiplesOf5": {{$sequence(name=five, start=5, step=5)}}
}
```

**输出**：
```json
{
  "evenNumbers": 2,
  "oddNumbers": 1,
  "multiplesOf5": 5
}
```

下次请求：
```json
{
  "evenNumbers": 4,
  "oddNumbers": 3,
  "multiplesOf5": 10
}
```

### 场景 3：批量创建用户

```json
{
  "username": "user{{$sequence(padding=4)}}",
  "email": "user{{$sequence(padding=4)}}@example.com",
  "phone": "138{{$sequence(name=phone, padding=8, start=10000000)}}"
}
```

**输出**：
```json
{
  "username": "user0001",
  "email": "user0001@example.com",
  "phone": "13810000000"
}
```

### 场景 4：测试分页

```
GET /api/users?page={{$sequence(name=page)}}&size=20
```

**请求序列**：
- 第 1 次：`/api/users?page=1&size=20`
- 第 2 次：`/api/users?page=2&size=20`
- 第 3 次：`/api/users?page=3&size=20`

### 场景 5：生成流水号

```json
{
  "transactionNo": "TXN{{$date('yyyyMMdd')}}{{$sequence(name=txn, padding=6)}}",
  "amount": 100.00
}
```

**输出**：
```json
{
  "transactionNo": "TXN20260304000001",
  "amount": 100.00
}
```

## 注意事项

1. **序列持久化**：序列状态会自动保存到本地存储，重启应用后序列会从上次的值继续
2. **首次使用**：序列在首次使用时自动创建，无需手动创建
3. **独立计数**：不同名称的序列完全独立，互不影响
4. **参数固定**：序列创建后，起始值参数不会再次生效，只有首次创建时有效
5. **修改参数**：如需修改序列参数，请使用序列管理界面
6. **重置序列**：通过序列管理界面可以将序列重置到任意值

## 与其他变量组合使用

序列可以与其他全局变量组合使用：

```json
{
  "id": "{{$guid}}",
  "orderNo": "{{$date('yyyyMMdd')}}-{{$sequence(name=order, padding=6)}}",
  "userId": "USER-{{$sequence(name=user, padding=5)}}",
  "timestamp": "{{$timestamp}}",
  "randomCode": "{{$randomNumeric(6)}}"
}
```

**输出**：
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "orderNo": "20260304-000001",
  "userId": "USER-00001",
  "timestamp": "1709510400000",
  "randomCode": "392847"
}
```

## 语法对比

| 需求 | 命名参数语法 | 位置参数语法 |
|------|-------------|-------------|
| 默认序列 | `{{$sequence}}` | `{{$sequence}}` |
| 只设置起始值 | `{{$sequence(start=100)}}` | `{{$sequence(100)}}` |
| 只设置步长 | `{{$sequence(step=10)}}` | ❌ 不支持 |
| 只设置填充 | `{{$sequence(padding=5)}}` | ❌ 不支持 |
| 命名序列 | `{{$sequence(name=order)}}` | `{{$sequence(order)}}` |
| 命名+填充 | `{{$sequence(name=order, padding=5)}}` | `{{$sequence(order, 5)}}` |
| 完整参数 | `{{$sequence(name=order, padding=5, start=1000, step=10)}}` | `{{$sequence(order, 5, 1000, 10)}}` |

**推荐使用命名参数**，因为：
1. 更清晰易读
2. 可以只指定需要的参数
3. 参数顺序不重要

## 常见问题

### Q: 如何重置序列？
A: 在序列管理界面中，点击编辑按钮，修改"当前值"为您想要的起始值，然后保存。

### Q: 序列会自动保存吗？
A: 是的，每次使用序列后，新的值会自动保存到本地存储。

### Q: 可以创建多少个序列？
A: 没有数量限制，您可以根据需要创建任意数量的序列。

### Q: 序列的步长可以是负数吗？
A: 目前不支持负数步长，步长必须大于等于 1。

### Q: 如何删除不再使用的序列？
A: 在序列管理界面中，点击序列右侧的删除图标即可删除。
