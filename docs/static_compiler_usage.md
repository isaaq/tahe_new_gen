# 静态编译功能使用指南

本文档介绍如何使用静态编译功能，将动态生成的页面预编译为静态HTML文件，以提高性能。

## 概述

静态编译系统允许您：

1. 将动态模板预编译为静态HTML文件
2. 在运行时自动使用预编译的静态文件（如果存在）
3. 保留动态解析能力，实现动静结合的最佳性能

## 使用方法

### 编译静态页面

使用以下命令编译静态页面：

```bash
# 完整编译流程（清理、编译、验证）
ruby bin/compile_static.rb full

# 或使用单独的命令
ruby bin/compile_static.rb clean    # 清理输出目录
ruby bin/compile_static.rb compile  # 编译所有模板
ruby bin/compile_static.rb incremental  # 增量编译（只编译修改过的文件）
ruby bin/compile_static.rb validate # 验证编译后的文件
```

### 启用静态页面

设置环境变量 `USE_STATIC_PAGES=true` 来启用静态页面：

```bash
USE_STATIC_PAGES=true rackup -p 9292
```

### Rake任务

也可以使用Rake任务来编译静态页面：

```bash
rake static:clean      # 清理静态编译输出目录
rake static:compile    # 编译所有模板为静态HTML
rake static:incremental # 增量编译修改过的模板
rake static:validate   # 验证编译后的文件
rake static:full       # 完整的编译流程：清理、编译、验证
rake static:watch      # 监视文件变化并自动重新编译（需要Listen gem）
```

## 工作原理

1. **双重解析**：系统首先将 `kr:xxx` 标签解析为中间形式，然后再解析为最终的HTML。
2. **静态中间件**：`StaticPagesMiddleware` 在处理请求时，会先检查是否存在对应的静态文件，如果存在则直接返回，否则继续动态解析。
3. **增量编译**：只编译修改过的文件，提高编译效率。

## 最佳实践

1. **开发环境**：在开发环境中禁用静态页面，以便实时查看更改。
2. **生产环境**：在生产环境中启用静态页面，提高性能。
3. **动静结合**：对于需要动态内容的页面，可以使用静态页面框架 + AJAX加载动态内容的方式。
4. **定期重新编译**：在部署新版本时，应重新编译所有静态页面。

## 注意事项

1. 静态编译不适用于高度动态的页面，如用户仪表板等。
2. 编译后的静态文件位于 `public/static` 目录中。
3. 修改模板后需要重新编译静态文件，或使用 `rake static:watch` 自动编译。
