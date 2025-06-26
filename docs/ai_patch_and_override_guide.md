# AI Patch 与 Override 支持机制设计

## 一、Taglib2 层支持 Override 指令

通过 `override:` 属性或子标签声明意图，如：

```erb
<kr:datatable override:columns>
  <% override_column(:name, label: "员工姓名") %>
</kr:datatable>
```

### 支持的 override 类型示例

- `columns`: 替换列定义
- `actions`: 替换操作按钮区域
- `search`: 替换搜索区域

## 二、AST 结构中支持注释与作用声明

Taglib2 转 AST 时每个节点结构如下：

```json
{
  "type": "kr:datatable",
  "props": { "source": "user.list" },
  "children": [],
  "meta": {
    "origin": "kr:user-table",
    "override": true,
    "ai_patchable": true,
    "desc": "用于渲染用户表格，可被 AI 修改"
  }
}
```

## 三、AI Patch Prompt 模板

```prompt
你是一个 UI 组件智能编辑器。
根据以下 AST JSON 和规则，输出修改后的 AST：

原始 AST：
{...}

规则说明：
- 修改表格列顺序为：姓名、工号、部门
- 添加一个搜索框绑定字段为“username”
```

该格式支持被 Windsurf 或自定义模型调用。