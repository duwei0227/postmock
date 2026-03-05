---
inclusion: always
---

# 信息时效性验证规则

## 核心原则

在提供技术信息时，必须确保信息的时效性和准确性。

## 技术栈文档清单

项目维护了一个技术栈文档清单：`.kiro/tech-stack-docs.md`

**在以下场景必须参考此清单：**
1. 添加新组件或功能
2. 修改配置文件
3. 升级依赖版本
4. 实现新的 API 调用
5. 调整构建流程

**使用流程：**
1. 查看 `.kiro/tech-stack-docs.md` 获取官方文档链接
2. 使用 `remote_web_search` 验证最新版本和 API
3. 使用 `webFetch` 获取具体文档内容
4. 参考官方示例实现功能

## 强制验证场景

当涉及以下内容时，**必须**先查看 `.kiro/tech-stack-docs.md` 清单，然后使用 `remote_web_search` 工具验证最新信息：

1. **版本信息**
   - 编程语言版本（Rust edition, Node.js, Python 等）
   - 框架版本（Tauri, Vue, React 等）
   - 库和依赖的最新版本
   - API 版本和兼容性

2. **技术规范**
   - 配置文件格式和 schema（如 tauri.conf.json）
   - API 接口规范
   - 标准和协议的最新状态

3. **最佳实践**
   - 当前推荐的做法
   - 已废弃的功能或方法
   - 安全建议

4. **工具和命令**
   - CLI 命令的最新语法
   - 构建工具的配置方式
   - 部署流程

5. **新增功能或组件**
   - 添加新的依赖前，必须查询官方文档
   - 实现新功能前，必须参考最新 API 文档
   - 修改配置前，必须验证 schema 规范

## 验证流程

1. **查看技术栈清单**
   - 首先检查 `.kiro/tech-stack-docs.md`
   - 获取相关技术的官方文档链接
   
2. **识别需要验证的信息**
   - 如果不确定信息是否最新，默认进行验证
   
3. **使用搜索和获取工具**
   ```
   # 搜索最新版本信息
   remote_web_search: "Rust edition 2024 stable release"
   remote_web_search: "Tauri v2 latest configuration schema"
   
   # 获取具体文档内容
   webFetch: "https://v2.tauri.app/reference/config/"
   webFetch: "https://doc.rust-lang.org/edition-guide/"
   ```

4. **引用来源**
   - 提供信息来源链接
   - 注明查询时间
   - 说明信息的时效性

5. **更新清单**
   - 如果发现新的官方文档或版本更新
   - 及时更新 `.kiro/tech-stack-docs.md`
   - 记录更新日期和内容

## 响应模板

### 添加新功能时

```
让我先查看技术栈文档清单和最新信息...

[查看 .kiro/tech-stack-docs.md]
[使用 remote_web_search 搜索最新版本]
[使用 webFetch 获取官方文档]

根据官方文档（来源：[URL]）：
- [最新的准确信息]
- [配置示例]
- [注意事项]
```

### 提供版本信息时

```
让我验证一下最新版本信息...

[使用 remote_web_search 搜索]

根据最新信息（来源：[URL]，查询时间：[DATE]）：
- [最新的准确信息]
```

## 禁止行为

❌ 不要基于训练数据直接断言版本信息
❌ 不要说"可能"、"应该"等模糊词汇来掩盖不确定性
❌ 不要在不确定时提供过时的信息
❌ 不要跳过查看技术栈文档清单的步骤
❌ 不要在添加新功能时不查询官方文档

## 允许行为

✅ 主动查看 `.kiro/tech-stack-docs.md` 清单
✅ 主动使用搜索工具验证
✅ 使用 webFetch 获取官方文档内容
✅ 明确说明信息来源和时间
✅ 承认训练数据的局限性
✅ 提供官方文档链接
✅ 更新技术栈文档清单

## 示例

**错误做法：**
> "Rust 2024 edition 还在开发中..."

**正确做法：**
> "让我搜索一下 Rust 2024 edition 的最新状态..."
> [使用 remote_web_search]
> "根据官方文档，Rust 2024 edition 已于 2024 年稳定发布..."
