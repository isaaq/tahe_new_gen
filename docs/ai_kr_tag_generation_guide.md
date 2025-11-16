# AI生成kr标签使用指南

## 概述

框架支持通过AI从自然语言需求直接生成kr标签，实现产生式（Generative）的页面生成。

## 三种生成路径

### 路径1：自然语言 → AI → kr标签（直接生成，推荐）

**API端点**: `POST /api/generate-kr-tags`

**请求示例**:
```json
{
  "requirement": "我要做一个商品管理页面，有商品表、店铺表、商家表、分类表，需要列表、详情、新增、修改、删除功能",
  "save_to_file": true
}
```

**响应示例**:
```json
{
  "status": "success",
  "tag_id": "507f1f77bcf86cd799439011",
  "kr_tags": "<kr:datatable source=\"products\" page=\"true\">\n  <kr:col title=\"产品名\" field=\"name\" />\n  ...\n</kr:datatable>",
  "file_path": "api/views/products_management_page.erb"
}
```

### 路径2：schema → kr标签

**API端点**: `POST /api/schema-to-kr-tags`

**请求示例**:
```json
{
  "schema": {
    "type": "datamanage",
    "data": "products",
    "fields": ["name", "price", "category", "shop"],
    "actions": ["add", "edit", "delete", "view"],
    "layout": "auto"
  }
}
```

### 路径3：自然语言 → schema → kr标签（两步生成）

**API端点**: `POST /api/generate-schema-then-kr-tags`

**请求示例**:
```json
{
  "requirement": "商品管理页面..."
}
```

**响应示例**:
```json
{
  "status": "success",
  "schema_id": "507f1f77bcf86cd799439012",
  "tag_id": "507f1f77bcf86cd799439013",
  "schema": { "type": "datamanage", "data": "products", ... },
  "kr_tags": "<kr:datatable>...</kr:datatable>"
}
```

## 查询已生成的标签

### 获取kr标签
**API端点**: `GET /api/kr-tags/:id`

### 获取schema列表
**API端点**: `GET /api/schemas`

### 获取单个schema
**API端点**: `GET /api/schemas/:id`

## 生成流程

### 设计时（产生式）
1. 用户提供自然语言需求
2. AI生成kr标签或schema
3. 保存到数据库（`kr_tags` 或 `crud_schemas` 集合）
4. 可选：保存到文件系统

### 运行时（声明式）
1. 框架读取保存的kr标签
2. 通过 `KrTransformer` 转换为layui标签
3. 渲染为HTML页面

## 核心组件

### 1. KrTagGeneratorParser
- 位置: `api/models/kr_tag_generator_parser.rb`
- 功能: 从自然语言直接生成kr标签
- 使用: `KrTagGeneratorParser.new.parse(data)`

### 2. SchemaGeneratorParser
- 位置: `api/models/schema_generator_parser.rb`
- 功能: 从自然语言生成schema配置
- 使用: `SchemaGeneratorParser.new.parse(data)`

### 3. SchemaToKrConverter
- 位置: `lib/ui/ui_impl/schema_to_kr_converter.rb`
- 功能: 从schema配置生成kr标签
- 使用: `SchemaToKrConverter.convert(schema)`

### 4. KrTagGenerationRoutes
- 位置: `api/routes/kr_tag_generation_routes.rb`
- 功能: 提供API路由接口

## 提示词模板

框架使用以下提示词模板（可在数据库中自定义）:

1. `generate_kr_tags` - 从自然语言生成kr标签
2. `generate_kr_tags_from_schema` - 从schema生成kr标签
3. `generate_crud_schema` - 从自然语言生成schema

## Web界面

框架提供了可视化的Web界面来使用AI生成功能：

**访问地址**: `http://localhost:9292/ai/generator`

界面包含4个标签页：
1. **直接生成** - 自然语言 → kr标签（一步完成）
2. **从Schema生成** - 已有schema → kr标签
3. **两步生成** - 自然语言 → schema → kr标签
4. **已生成列表** - 查看所有已生成的页面

### 界面功能
- ✅ 可视化表单输入
- ✅ 实时生成结果预览
- ✅ 代码复制功能
- ✅ 文件下载功能
- ✅ 生成历史列表

## 使用示例

### 示例1：通过Web界面生成

1. 访问 `http://localhost:9292/ai/generator`
2. 在"直接生成"标签页输入需求
3. 点击"生成kr标签"按钮
4. 查看生成结果并复制代码

### 示例2：通过API直接生成商品管理页面

```bash
curl -X POST http://localhost:4567/api/generate-kr-tags \
  -H "Content-Type: application/json" \
  -d '{
    "requirement": "商品管理页面，包含商品名称、价格、分类、店铺字段，支持增删改查",
    "save_to_file": true
  }'
```

### 示例2：从已有schema生成

```bash
curl -X POST http://localhost:4567/api/schema-to-kr-tags \
  -H "Content-Type: application/json" \
  -d '{
    "schema": {
      "type": "datamanage",
      "data": "products",
      "fields": ["name", "price", "category"],
      "actions": ["add", "edit", "delete", "view"],
      "layout": "search_table"
    }
  }'
```

## 注意事项

1. **AI服务配置**: 确保 `config.yml` 中配置了 `llm_api_key` 和 `llm_api_endpoint`
2. **模型扫描**: 框架会自动扫描模型定义，获取字段和关联信息
3. **关联发现**: 使用 `RelationRegistry` 自动发现关联关系
4. **文件保存**: 设置 `save_to_file: true` 会将生成的标签保存到文件系统

## 数据库集合

- `kr_tags`: 存储生成的kr标签
- `crud_schemas`: 存储生成的schema配置
- `prompt_templates`: 存储AI提示词模板

