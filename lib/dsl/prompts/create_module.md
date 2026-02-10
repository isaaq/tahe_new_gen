# AI Prompt Template: Create Complete Module

## System Context

You are generating code for the **Tahe Framework**, a Ruby-based low-code business application platform.

This template generates a **complete business module** including:
- Model definition (.krmodel)
- Page definitions (.krdsl)
- API routes (auto-generated from model)

## Project Context

{{PROJECT_CONTEXT}}

**Existing Modules:**
{{EXISTING_MODULES}}

**Available Field Types:**
{{AVAILABLE_FIELD_TYPES}}

**Available Strategies:**
{{AVAILABLE_STRATEGIES}}

## Task

{{USER_REQUIREMENT}}

## Schema Constraints

Your output MUST conform to this JSON Schema:
```json
{{MODULE_DSL_SCHEMA}}
```

## Conventions

Follow these conventions strictly:

1. **Module Structure:**
   ```
   modules/{{module_name_snake}}/
   ├── {{module_name_snake}}.krmodule  # Module definition
   ├── model.krmodel                    # Model (auto-extracted)
   └── pages/                           # Pages (auto-extracted)
       ├── list.krdsl
       ├── form.krdsl
       └── detail.krdsl
   ```

2. **Naming:**
   - Module name: PascalCase (e.g., ProductManagement)
   - Model name: PascalCase (e.g., Product)
   - API base path: `/api/{{model_plural}}` (e.g., /api/products)
   - Page routes: `/{{module_kebab}}` (e.g., /product-management)

3. **Default Pages:**
   - **List page**: CRUD panel with search
   - **Form page**: Create/Edit form
   - **Detail page**: Read-only detail view

4. **API Endpoints (auto-generated):**
   - `GET /api/{{model_plural}}` - List with pagination
   - `POST /api/{{model_plural}}` - Create
   - `GET /api/{{model_plural}}/:id` - Show
   - `PUT /api/{{model_plural}}/:id` - Update
   - `DELETE /api/{{model_plural}}/:id` - Delete
   - `GET /api/{{model_plural}}/search` - Search

## Examples

### Example 1: Simple CRUD Module

**User Request:** "Create a complete product management module with name, price, category, and status"

**Output:**
```json
{
  "module": "ProductManagement",
  "description": "产品管理模块",
  "model": {
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
      },
      {
        "name": "status",
        "type": "enum",
        "label": "状态",
        "default": "draft",
        "options": {
          "enum_values": [
            {"value": "draft", "label": "草稿"},
            {"value": "published", "label": "已发布"},
            {"value": "archived", "label": "已归档"}
          ]
        }
      }
    ],
    "indexes": [
      {
        "fields": [{"field": "name"}]
      },
      {
        "fields": [{"field": "category"}, {"field": "status"}]
      }
    ],
    "strategies": [
      {"action": "save", "context": "normal"},
      {"action": "query", "context": "paginated"},
      {"action": "delete", "context": "soft"}
    ]
  },
  "pages": [
    {
      "name": "产品列表",
      "type": "list",
      "route": "/product-management",
      "layout": "admin",
      "permissions": ["admin", "editor", "viewer"]
    },
    {
      "name": "产品表单",
      "type": "form",
      "route": "/product-management/form",
      "layout": "default",
      "permissions": ["admin", "editor"]
    },
    {
      "name": "产品详情",
      "type": "detail",
      "route": "/product-management/:id",
      "layout": "default",
      "permissions": ["admin", "editor", "viewer"]
    }
  ],
  "api": {
    "base_path": "/api/products",
    "authentication": true,
    "endpoints": [
      {
        "method": "GET",
        "path": "/",
        "action": "list",
        "description": "获取产品列表",
        "parameters": [
          {"name": "page", "type": "integer", "in": "query", "default": 1},
          {"name": "page_size", "type": "integer", "in": "query", "default": 20},
          {"name": "sort", "type": "string", "in": "query"},
          {"name": "order", "type": "string", "in": "query", "enum": ["asc", "desc"]}
        ],
        "strategy": {"action": "query", "context": "paginated"}
      },
      {
        "method": "POST",
        "path": "/",
        "action": "create",
        "description": "创建产品",
        "parameters": [
          {"name": "name", "type": "string", "in": "body", "required": true},
          {"name": "price", "type": "number", "in": "body", "required": true},
          {"name": "category", "type": "string", "in": "body", "required": true},
          {"name": "status", "type": "string", "in": "body"}
        ],
        "strategy": {"action": "save", "context": "normal"}
      },
      {
        "method": "GET",
        "path": "/:id",
        "action": "show",
        "description": "获取产品详情",
        "parameters": [
          {"name": "id", "type": "string", "in": "path", "required": true}
        ],
        "strategy": {"action": "query", "context": "default"}
      },
      {
        "method": "PUT",
        "path": "/:id",
        "action": "update",
        "description": "更新产品",
        "parameters": [
          {"name": "id", "type": "string", "in": "path", "required": true},
          {"name": "name", "type": "string", "in": "body"},
          {"name": "price", "type": "number", "in": "body"},
          {"name": "category", "type": "string", "in": "body"},
          {"name": "status", "type": "string", "in": "body"}
        ],
        "strategy": {"action": "save", "context": "normal"}
      },
      {
        "method": "DELETE",
        "path": "/:id",
        "action": "delete",
        "description": "删除产品",
        "parameters": [
          {"name": "id", "type": "string", "in": "path", "required": true}
        ],
        "strategy": {"action": "delete", "context": "soft"}
      },
      {
        "method": "GET",
        "path": "/search",
        "action": "search",
        "description": "搜索产品",
        "parameters": [
          {"name": "keyword", "type": "string", "in": "query"},
          {"name": "category", "type": "string", "in": "query"},
          {"name": "status", "type": "string", "in": "query"},
          {"name": "min_price", "type": "number", "in": "query"},
          {"name": "max_price", "type": "number", "in": "query"}
        ],
        "strategy": {"action": "search", "context": "default"}
      }
    ]
  }
}
```

### Example 2: Module with Workflow

**User Request:** "Create an order management module with workflow (draft → submitted → approved → completed)"

**Output:**
```json
{
  "module": "OrderManagement",
  "description": "订单管理模块（带审批流程）",
  "model": {
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
        "default": "draft",
        "options": {
          "enum_values": [
            {"value": "draft", "label": "草稿"},
            {"value": "submitted", "label": "已提交"},
            {"value": "approved", "label": "已审批"},
            {"value": "completed", "label": "已完成"},
            {"value": "rejected", "label": "已拒绝"}
          ]
        }
      },
      {
        "name": "items",
        "type": "json",
        "label": "订单明细",
        "description": "订单项列表"
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
      {"action": "save", "context": "draft"},
      {"action": "submit", "context": "publish"},
      {"action": "query", "context": "paginated"},
      {"action": "delete", "context": "soft"},
      {"action": "workflow", "context": "approval"}
    ],
    "hooks": {
      "before_create": "generate_order_number",
      "after_submit": "send_approval_notification",
      "after_approve": "send_completion_notification"
    }
  },
  "pages": [
    {
      "name": "订单列表",
      "type": "list",
      "route": "/order-management",
      "layout": "admin",
      "permissions": ["admin", "sales", "viewer"]
    },
    {
      "name": "订单表单",
      "type": "form",
      "route": "/order-management/form",
      "layout": "default",
      "permissions": ["admin", "sales"]
    },
    {
      "name": "订单详情",
      "type": "detail",
      "route": "/order-management/:id",
      "layout": "default",
      "permissions": ["admin", "sales", "viewer"]
    }
  ],
  "api": {
    "base_path": "/api/orders",
    "authentication": true,
    "rate_limit": {
      "enabled": true,
      "requests": 100,
      "period": "minute"
    },
    "endpoints": [
      {
        "method": "GET",
        "path": "/",
        "action": "list",
        "description": "获取订单列表",
        "strategy": {"action": "query", "context": "paginated"}
      },
      {
        "method": "POST",
        "path": "/",
        "action": "create",
        "description": "创建订单（草稿）",
        "strategy": {"action": "save", "context": "draft"}
      },
      {
        "method": "POST",
        "path": "/:id/submit",
        "action": "submit",
        "description": "提交订单审批",
        "parameters": [
          {"name": "id", "type": "string", "in": "path", "required": true}
        ],
        "strategy": {"action": "submit", "context": "publish"}
      },
      {
        "method": "POST",
        "path": "/:id/approve",
        "action": "approve",
        "description": "审批订单",
        "parameters": [
          {"name": "id", "type": "string", "in": "path", "required": true},
          {"name": "approved", "type": "boolean", "in": "body", "required": true},
          {"name": "comment", "type": "string", "in": "body"}
        ],
        "strategy": {"action": "workflow", "context": "approval"}
      },
      {
        "method": "GET",
        "path": "/:id",
        "action": "show",
        "description": "获取订单详情",
        "strategy": {"action": "query", "context": "default"}
      },
      {
        "method": "PUT",
        "path": "/:id",
        "action": "update",
        "description": "更新订单（仅草稿状态）",
        "strategy": {"action": "save", "context": "draft"}
      },
      {
        "method": "DELETE",
        "path": "/:id",
        "action": "delete",
        "description": "删除订单",
        "strategy": {"action": "delete", "context": "soft"}
      }
    ]
  }
}
```

## Output Format

Generate a valid JSON object conforming to the Module DSL Schema.

**File to create:** `modules/{{module_name_snake}}/{{module_name_snake}}.krmodule`

**Important:**
- Include complete model definition
- Define all necessary pages (list, form, detail at minimum)
- Specify all API endpoints with proper HTTP methods
- Map strategies to appropriate endpoints
- Include authentication and permissions
- Add rate limiting for production APIs

## Validation Checklist

Before outputting, verify:
- [ ] Module name is PascalCase
- [ ] Model is complete and valid
- [ ] At least 3 pages defined (list, form, detail)
- [ ] API base path follows REST conventions
- [ ] All CRUD endpoints are defined
- [ ] Strategies match endpoint actions
- [ ] Permissions are specified
- [ ] Authentication is enabled
- [ ] JSON is valid and properly formatted
