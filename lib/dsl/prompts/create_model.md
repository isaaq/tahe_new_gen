# AI Prompt Template: Create Model

## System Context

You are generating code for the **Tahe Framework**, a Ruby-based low-code business application platform.

**Framework Capabilities:**
- MongoDB-based data persistence
- Plugin-driven architecture (78+ field types, 168+ strategies)
- Strategy pattern (domain/action/context)
- Automatic CRUD API generation
- UI component auto-generation

## Project Context

{{PROJECT_CONTEXT}}

**Current Models:**
{{EXISTING_MODELS}}

**Available Field Types:**
{{AVAILABLE_FIELD_TYPES}}

**Available Strategies:**
{{AVAILABLE_STRATEGIES}}

## Task

{{USER_REQUIREMENT}}

## Schema Constraints

Your output MUST conform to this JSON Schema:
```json
{{MODEL_DSL_SCHEMA}}
```

## Conventions

Follow these conventions strictly:

1. **File Naming:**
   - Model file: `models/{{model_name_snake}}.krmodel`
   - Model class: `{{model_name_pascal}}`
   - Collection: `{{model_name_snake_plural}}` (e.g., Product → products)

2. **Field Naming:**
   - Use `snake_case` for field names
   - Use descriptive names (e.g., `created_at` not `ca`)
   - Common fields: `name`, `description`, `status`, `created_at`, `updated_at`

3. **Field Types:**
   - Use `text` for short strings (< 255 chars)
   - Use `textarea` for long text
   - Use `amount` for money (not `number`)
   - Use `single_relation` for foreign keys
   - Use `enum` for fixed options

4. **Validation:**
   - Always add `required: true` for essential fields
   - Add `min`/`max` for numbers and amounts
   - Add `min_length`/`max_length` for text fields

5. **Strategies:**
   - Default save strategy: `{action: "save", context: "normal"}`
   - Default query strategy: `{action: "query", context: "paginated"}`
   - Default delete strategy: `{action: "delete", context: "soft"}`

6. **Timestamps:**
   - Always enable `timestamps: true` unless explicitly told not to
   - Enable `soft_delete: true` for business data (not for system data)

## Examples

### Example 1: Simple Model

**User Request:** "Create a Product model with name, price, and category"

**Output:**
```json
{
  "model": "Product",
  "collection": "products",
  "description": "产品模型",
  "timestamps": true,
  "soft_delete": true,
  "fields": [
    {
      "name": "name",
      "type": "text",
      "label": "产品名称",
      "required": true,
      "validation": {
        "min_length": 2,
        "max_length": 100
      }
    },
    {
      "name": "price",
      "type": "amount",
      "label": "价格",
      "required": true,
      "options": {
        "min": 0,
        "precision": 2,
        "currency": "CNY"
      }
    },
    {
      "name": "category",
      "type": "single_relation",
      "label": "分类",
      "required": true,
      "options": {
        "target": "Category",
        "display_field": "name"
      }
    }
  ],
  "indexes": [
    {
      "fields": [{"field": "name"}]
    }
  ],
  "strategies": [
    {"action": "save", "context": "normal"},
    {"action": "query", "context": "paginated"},
    {"action": "delete", "context": "soft"}
  ]
}
```

### Example 2: Model with Enum and Validation

**User Request:** "Create an Order model with order_number, customer, total_amount, and status (pending/paid/shipped/completed)"

**Output:**
```json
{
  "model": "Order",
  "collection": "orders",
  "description": "订单模型",
  "timestamps": true,
  "soft_delete": true,
  "fields": [
    {
      "name": "order_number",
      "type": "text",
      "label": "订单号",
      "required": true,
      "unique": true,
      "validation": {
        "pattern": "^ORD\\d{8}$",
        "message": "订单号格式：ORD + 8位数字"
      },
      "ui": {
        "readonly": true,
        "placeholder": "保存后自动生成"
      }
    },
    {
      "name": "customer",
      "type": "single_relation",
      "label": "客户",
      "required": true,
      "options": {
        "target": "Customer",
        "display_field": "name"
      }
    },
    {
      "name": "total_amount",
      "type": "amount",
      "label": "总金额",
      "required": true,
      "options": {
        "min": 0,
        "precision": 2,
        "currency": "CNY"
      }
    },
    {
      "name": "status",
      "type": "enum",
      "label": "状态",
      "required": true,
      "default": "pending",
      "options": {
        "enum_values": [
          {"value": "pending", "label": "待支付"},
          {"value": "paid", "label": "已支付"},
          {"value": "shipped", "label": "已发货"},
          {"value": "completed", "label": "已完成"}
        ]
      }
    }
  ],
  "indexes": [
    {
      "fields": [{"field": "order_number"}],
      "unique": true
    },
    {
      "fields": [{"field": "customer"}, {"field": "status"}]
    }
  ],
  "strategies": [
    {"action": "save", "context": "normal"},
    {"action": "query", "context": "paginated"},
    {"action": "delete", "context": "soft"}
  ],
  "hooks": {
    "before_create": "generate_order_number",
    "after_create": "send_order_notification"
  }
}
```

### Example 3: Model with Complex Relations

**User Request:** "Create a Project model with name, description, start_date, end_date, manager (single user), and team_members (multiple users)"

**Output:**
```json
{
  "model": "Project",
  "collection": "projects",
  "description": "项目模型",
  "timestamps": true,
  "soft_delete": true,
  "fields": [
    {
      "name": "name",
      "type": "text",
      "label": "项目名称",
      "required": true,
      "validation": {
        "min_length": 2,
        "max_length": 200
      }
    },
    {
      "name": "description",
      "type": "textarea",
      "label": "项目描述",
      "validation": {
        "max_length": 2000
      }
    },
    {
      "name": "start_date",
      "type": "date",
      "label": "开始日期",
      "required": true
    },
    {
      "name": "end_date",
      "type": "date",
      "label": "结束日期",
      "required": true
    },
    {
      "name": "manager",
      "type": "single_relation",
      "label": "项目经理",
      "required": true,
      "options": {
        "target": "User",
        "display_field": "name"
      }
    },
    {
      "name": "team_members",
      "type": "multiple_relation",
      "label": "团队成员",
      "options": {
        "target": "User",
        "display_field": "name"
      }
    },
    {
      "name": "status",
      "type": "enum",
      "label": "状态",
      "default": "planning",
      "options": {
        "enum_values": [
          {"value": "planning", "label": "规划中"},
          {"value": "in_progress", "label": "进行中"},
          {"value": "completed", "label": "已完成"},
          {"value": "cancelled", "label": "已取消"}
        ]
      }
    }
  ],
  "indexes": [
    {
      "fields": [{"field": "name"}]
    },
    {
      "fields": [{"field": "manager"}]
    },
    {
      "fields": [{"field": "status"}]
    }
  ],
  "strategies": [
    {"action": "save", "context": "normal"},
    {"action": "query", "context": "paginated"},
    {"action": "delete", "context": "soft"}
  ],
  "permissions": {
    "create": ["admin", "project_manager"],
    "read": ["admin", "project_manager", "team_member"],
    "update": ["admin", "project_manager"],
    "delete": ["admin"]
  }
}
```

## Output Format

Generate a valid JSON object conforming to the Model DSL Schema.

**File to create:** `models/{{model_name_snake}}.krmodel`

**Important:**
- Use double quotes for JSON strings
- Ensure all required fields are present
- Validate against the schema before outputting
- Use appropriate field types from the available list
- Add indexes for frequently queried fields
- Include appropriate strategies for the model's use case

## Validation Checklist

Before outputting, verify:
- [ ] Model name is PascalCase
- [ ] Collection name is snake_case plural
- [ ] All field names are snake_case
- [ ] All required fields have `required: true`
- [ ] Numeric fields have min/max constraints
- [ ] Text fields have length constraints
- [ ] Relations specify target model and display_field
- [ ] Enums have at least 2 options
- [ ] Strategies are appropriate for the model
- [ ] JSON is valid and properly formatted
