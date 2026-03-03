---
inclusion: auto
---

# PrimeVue 开发约束规则

本文档定义了在本项目中使用 PrimeVue 组件库的开发规范和约束。所有开发工作必须严格遵循这些规则。

## 核心原则

### 1. 优先使用 PrimeVue 组件

**规则：** 在实现任何功能前，必须先检查 PrimeVue 是否提供了对应的组件。

- ✅ **正确做法：** 查阅 PrimeVue 官方文档 (https://primevue.org/)，使用现成的组件
- ❌ **错误做法：** 在不确认 PrimeVue 是否有对应组件的情况下，自己实现类似功能

**示例：**
- 需要树形结构 → 使用 `Tree` 组件
- 需要下拉菜单 → 使用 `Dropdown` 组件
- 需要对话框 → 使用 `Dialog` 组件
- 需要右键菜单 → 使用 `ContextMenu` 组件
- 需要标签页 → 使用 `TabView` 组件

### 2. 严格遵循 PrimeVue 默认样式

**规则：** 使用 PrimeVue 组件时，不添加任何自定义样式，除非用户明确要求。

#### 2.1 禁止修改的样式属性

- ❌ 不修改 `padding`、`margin`
- ❌ 不修改 `height`、`width`（除非组件文档明确支持）
- ❌ 不修改 `border-radius`
- ❌ 不修改 `background-color`、`color`（除非是业务逻辑需要的动态颜色）
- ❌ 不覆盖 `:hover`、`:focus`、`:active` 等伪类样式
- ❌ 不修改组件内部元素的间距和布局

#### 2.2 允许的样式修改

- ✅ 使用 PrimeVue 提供的 props 来配置组件（如 `size`、`severity`、`variant` 等）
- ✅ 使用 PrimeVue 的主题系统和 CSS 变量
- ✅ 添加业务逻辑相关的动态 class（如根据状态显示不同颜色）
- ✅ 用户明确要求的自定义样式

#### 2.3 样式示例

**❌ 错误示例：**
```vue
<style scoped>
/* 不要这样做 - 覆盖了 PrimeVue 的默认样式 */
:deep(.p-tree .p-tree-node-content) {
  padding: 0.5rem;
  border-radius: 6px;
}

:deep(.p-tree .p-tree-node-content:hover) {
  background-color: var(--p-surface-100);
}
</style>
```

**✅ 正确示例：**
```vue
<style scoped>
/* 只修改必要的容器样式，不触碰组件内部 */
:deep(.p-tree) {
  border: none;
  padding: 0;
  background: transparent;
}

/* 业务逻辑相关的自定义样式 */
.method-badge {
  font-weight: 600;
  font-size: 10px;
  text-transform: uppercase;
}
</style>
```

### 3. 仅在明确要求时自定义

**规则：** 只有当用户明确告诉需要自定义样式时，才添加自定义样式。

**工作流程：**
1. 用户提出功能需求
2. 查阅 PrimeVue 文档，找到对应组件
3. 使用组件的默认样式实现功能
4. 如果用户对样式不满意，等待用户明确指出需要修改的地方
5. 仅修改用户指定的样式属性

**沟通示例：**
- 用户："这个按钮太小了" → 询问："需要使用 PrimeVue 的 `size="large"` 属性，还是需要自定义尺寸？"
- 用户："我想要圆角更大" → 确认具体数值后再修改

### 4. 参考 PrimeVue 官方文档

**规则：** 实现功能时必须参考官方示例，确保使用方式正确。

**官方资源：**
- 官方文档：https://primevue.org/
- 组件示例：每个组件页面都有完整的示例代码
- API 文档：查看组件支持的 props、events、slots

**最佳实践：**
1. 打开对应组件的官方文档页面
2. 查看 "Basic" 或 "Getting Started" 示例
3. 复制官方示例代码作为起点
4. 根据业务需求调整 props 和事件处理
5. 不修改组件的样式部分

## 约束的好处

遵循这些约束能够：

- ✅ **界面风格统一**：所有组件保持一致的外观和交互体验
- ✅ **行为符合预期**：组件按照 PrimeVue 设计的方式工作，减少意外行为
- ✅ **减少样式冲突**：避免自定义样式与 PrimeVue 内部样式冲突
- ✅ **易于维护**：升级 PrimeVue 版本时不会因为自定义样式而出现问题
- ✅ **开发效率高**：直接使用现成组件，无需重复造轮子
- ✅ **代码可读性好**：其他开发者能快速理解代码意图

## 违规检查清单

在提交代码前，检查以下项目：

- [ ] 是否使用了 PrimeVue 提供的组件？
- [ ] 是否添加了不必要的自定义样式？
- [ ] 是否修改了组件的 hover/focus 等状态样式？
- [ ] 是否修改了组件内部元素的间距？
- [ ] 是否参考了官方文档的示例？
- [ ] 自定义样式是否得到了用户的明确要求？

## 例外情况

以下情况可以适当自定义样式：

1. **用户明确要求**：用户明确指出需要修改某个样式属性
2. **业务逻辑需要**：如根据数据状态动态改变颜色（GET=绿色，POST=蓝色等）
3. **布局需要**：容器级别的布局样式（flex、grid 等）
4. **PrimeVue 不支持**：某些特殊功能 PrimeVue 确实没有提供

## 总结

**记住：Less is More！**

使用 PrimeVue 组件时，保持简单，信任框架的设计。只有在真正需要时才添加自定义样式。
