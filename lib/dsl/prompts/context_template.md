# AI Prompt Template: Project Context

## Purpose

This template provides the current project state to AI for context-aware code generation.

## Context Structure

```json
{
  "project": {
    "name": "{{PROJECT_NAME}}",
    "framework": "Tahe",
    "version": "{{VERSION}}",
    "database": "MongoDB",
    "ui_framework": "Layui"
  },
  "models": [
    {
      "name": "{{MODEL_NAME}}",
      "collection": "{{COLLECTION_NAME}}",
      "fields": [
        {
          "name": "{{FIELD_NAME}}",
          "type": "{{FIELD_TYPE}}",
          "label": "{{FIELD_LABEL}}"
        }
      ]
    }
  ],
  "pages": [
    {
      "name": "{{PAGE_NAME}}",
      "route": "{{PAGE_ROUTE}}",
      "type": "{{PAGE_TYPE}}"
    }
  ],
  "available_field_types": [
    "text", "textarea", "number", "boolean", "date", "time", "datetime",
    "enum", "file", "image", "json",
    "amount", "email", "phone", "id_card", "url",
    "address", "coordinate", "color",
    "number_range", "date_range",
    "single_relation", "multiple_relation", "tree_relation",
    "code_editor", "markdown", "rich_text",
    "encrypted", "formula"
  ],
  "available_strategies": {
    "save": ["draft", "normal", "async", "batch", "encrypted", "version"],
    "submit": ["publish", "review", "workflow"],
    "query": ["default", "paginated", "cached", "encrypted"],
    "delete": ["soft", "hard", "cascade", "archive"],
    "validate": ["form", "data", "business"],
    "notification": ["email", "sms", "webhook"],
    "permission": ["role", "field", "data"],
    "search": ["default", "global", "fuzzy"],
    "workflow": ["approval", "state_machine"]
  },
  "available_components": [
    "tree_table_layout",
    "search_table",
    "crud_panel",
    "form",
    "table",
    "chart",
    "card",
    "tabs",
    "toolbar",
    "button",
    "dialog",
    "drawer"
  ],
  "conventions": {
    "file_naming": "snake_case",
    "class_naming": "PascalCase",
    "field_naming": "snake_case",
    "collection_naming": "snake_case_plural",
    "api_base_path": "/api/{{model_plural}}",
    "page_route": "/{{module_kebab}}"
  }
}
```

## Usage in CLI

```ruby
# lib/dsl/context/project_context.rb
require 'json'

module Tahe
  module DSL
    class ProjectContext
      def self.generate
        {
          project: project_info,
          models: load_models,
          pages: load_pages,
          available_field_types: FieldRegistry.all_types,
          available_strategies: StrategyRegistry.all_strategies,
          available_components: ComponentRegistry.all_components,
          conventions: conventions
        }
      end

      def self.project_info
        {
          name: Config.project_name,
          framework: "Tahe",
          version: Tahe::VERSION,
          database: "MongoDB",
          ui_framework: "Layui"
        }
      end

      def self.load_models
        Dir.glob("models/**/*.krmodel").map do |file|
          JSON.parse(File.read(file))
        end
      end

      def self.load_pages
        Dir.glob("pages/**/*.krdsl").map do |file|
          parse_page_metadata(file)
        end
      end

      def self.conventions
        {
          file_naming: "snake_case",
          class_naming: "PascalCase",
          field_naming: "snake_case",
          collection_naming: "snake_case_plural",
          api_base_path: "/api/{{model_plural}}",
          page_route: "/{{module_kebab}}"
        }
      end

      def self.to_json
        JSON.pretty_generate(generate)
      end
    end
  end
end
```

## CLI Command

```bash
# Generate context for AI
$ tahe context

# Output to file
$ tahe context --output context.json

# Compact format (for token efficiency)
$ tahe context --compact
```

## Example Output

```json
{
  "project": {
    "name": "tahe_new_gen",
    "framework": "Tahe",
    "version": "0.1.0",
    "database": "MongoDB",
    "ui_framework": "Layui"
  },
  "models": [
    {
      "name": "Product",
      "collection": "products",
      "fields": [
        {"name": "name", "type": "text", "label": "产品名称"},
        {"name": "price", "type": "amount", "label": "价格"},
        {"name": "category", "type": "single_relation", "label": "分类"}
      ]
    },
    {
      "name": "Category",
      "collection": "categories",
      "fields": [
        {"name": "name", "type": "text", "label": "分类名称"},
        {"name": "parent", "type": "tree_relation", "label": "父分类"}
      ]
    }
  ],
  "pages": [
    {
      "name": "产品管理",
      "route": "/product-management",
      "type": "crud"
    }
  ],
  "available_field_types": [
    "text", "number", "date", "single_relation", "..."
  ],
  "available_strategies": {
    "save": ["draft", "normal", "async"],
    "query": ["default", "paginated", "cached"]
  },
  "available_components": [
    "crud_panel", "search_table", "form", "table"
  ],
  "conventions": {
    "file_naming": "snake_case",
    "class_naming": "PascalCase",
    "api_base_path": "/api/{{model_plural}}"
  }
}
```

## Compact Format (Token-Efficient)

For AI prompts with token limits, use compact format:

```json
{
  "p": {"n": "tahe_new_gen", "f": "Tahe", "v": "0.1.0"},
  "m": [
    {"n": "Product", "c": "products", "f": [
      {"n": "name", "t": "text"},
      {"n": "price", "t": "amount"}
    ]}
  ],
  "ft": ["text", "number", "date", "single_relation"],
  "st": {
    "save": ["draft", "normal"],
    "query": ["paginated"]
  }
}
```

## Integration with Prompt Templates

```markdown
## Project Context

{{PROJECT_CONTEXT}}

**Current Models:**
{{#each models}}
- {{name}} ({{collection}}): {{#each fields}}{{name}}:{{type}}{{#unless @last}}, {{/unless}}{{/each}}
{{/each}}

**Available Field Types:**
{{#each available_field_types}}{{this}}{{#unless @last}}, {{/unless}}{{/each}}
```
