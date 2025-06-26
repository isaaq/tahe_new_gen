# DSL 渲染模式设计总结

## 渲染模式

| 模式 | 描述 | 是否适合低代码 | AI支持 | 推荐场景 |
|------|------|----------------|--------|-----------|
| 模式1 | 服务端全渲染（整页刷新） | ✅ | ✅ | 快速表单、传统流程 |
| 模式2 | 服务端渲染 + 客户端 Ajax | ✅ | ✅ | 分区刷新、动态区域 |
| 模式3 | 前后端完全分离（SPA） | ❌ | ❌ | 高互动 Web App（不推荐低代码）|

## 推荐混合策略

- 统一 DSL，组件属性中指定 `type: "full" | "ajax" | "pjax"`
- AI/设计器根据类型自动生成调用策略

## PJAX/Turbo Streams 的使用建议

- 替代整页刷新
- 保留服务端渲染的便利
- 可集成 Hotwired Turbo 提升响应式

## 设计时与运行时区分机制

### 核心机制

框架通过明确的设计时和运行时分离实现低代码开发：

1. **设计时**：在服务端通过 Ruby 代码实现，主要由 `UIPage` 类负责
2. **运行时**：在客户端通过 TypeScript 实现，位于 `assets/ts` 目录下

### 设计时处理流程

设计时由 `UIPage` 类的二次编译机制处理：

1. **编译流程**：
   - **服务端编译 (`server_compile`)**: 处理服务器端的模板解析，将DSL标签转换为HTML/JavaScript代码
   - **前端代码生成 (`front_compile`)**: 处理预编译区域和生成前端运行时所需的代码

2. **编译过程**：
   ```ruby
   def parse_code(source = @page.default_page, b = binding, layout: nil)
     layout = @page.default_layout if layout == :default
     front_code = server_compile(source, b, layout)
     front_compile(front_code)
   end
   ```

### 设计时特性

- **标签库处理**：不同UI框架（Kr、Layui等）有各自的标签库实现
- **未定义标签处理**：通过 `tag_missing` 方法处理未定义标签，使用替代标签（如div）并添加特殊标记
- **预编译区域定义**：通过 `parse_reg_area` 方法定义可在运行时替换的代码区域
- **上下文管理**：通过 `reg_context` 方法注册设计时上下文变量

### 真正的运行时机制

运行时由前端 TypeScript 代码实现，位于 `assets/ts` 目录：

- **全局命名空间**：通过 `window.KR.UI` 提供统一的运行时接口
- **组件工厂**：提供 `createDataTable`、`createTree` 等工厂函数创建组件实例
- **事件处理**：组件提供丰富的事件绑定机制，如 `onToolEvent`、`onRowEvent` 等
- **数据交互**：处理与后端的数据交换，支持 AJAX 请求和数据更新

示例（DataTable 运行时）：
```typescript
export class DataTable {
  constructor(tableId: string, options: DataTableOptions) {
    // 初始化表格组件...
  }
  
  reload(url?: string, where?: object): void {
    // 重载表格数据...
  }
  
  onToolEvent(callback: EventCallback): void {
    // 绑定工具事件...
  }
}
```

### 设计时与运行时的连接

1. **HTML/JS 生成**：设计时生成的 HTML 和 JavaScript 代码包含运行时组件的初始化代码
2. **组件实例化**：页面加载时，运行时代码根据设计时生成的配置创建组件实例
3. **数据绑定**：运行时组件通过 AJAX 从后端获取数据并进行渲染
4. **事件处理**：运行时组件处理用户交互事件并执行相应的业务逻辑

### 不同UI框架的支持

- 通过 `@type` 参数选择对应的标签库和页面模板
- 在 `initialize` 方法中动态加载对应的 Page 类：
  ```ruby
  @page = Object.const_get("#{type.capitalize}Page").new
  ```
- 每种UI框架（Kr、Layui等）有各自的设计时标签库和运行时实现

### 渲染模式与编译机制的关系

- **模式1**（服务端全渲染）：主要依赖服务端生成完整HTML，运行时负责少量交互
- **模式2**（服务端渲染+Ajax）：设计时生成页面结构，运行时负责数据加载和局部更新
- **模式3**（前后端分离）：设计时主要生成配置，运行时负责大部分渲染和交互逻辑