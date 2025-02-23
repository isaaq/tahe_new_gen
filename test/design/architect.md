你是一个高级 Ruby 开发助手，熟悉 Sinatra、MongoDB 和 LLM 解析。
/api 目录下有如下需求:

---

## **📌 目标**
创建一个 **DCI（数据-上下文-交互）+ LLM + 自学习** 的解析引擎，采用 **Sinatra + MongoDB** 作为后端框架，提供 REST API：

1. **数据层（Data）**  
   - 使用 MongoDB 存储文档，每个文档带 `_meta` 字段，包含 `parser`（解析器类型）。
   - 解析结果和用户反馈存入数据库。

2. **上下文层（Context）**  
   - 解析器可插拔，支持：
     - **规则解析（RuleBasedParser）**
     - **AI 解析（AIInterpreter，基于 LLM）**
     - **混合解析（HybridParser）**
   - 可根据 `_meta.parser` 选择解析器。

3. **交互层（Interaction）**  
   - 提供 REST API：
     - `GET /parse/:id` 解析 MongoDB 中的文档
     - `POST /feedback` 记录解析反馈
   - 解析器支持自适应优化（基于用户反馈调整解析方式）。

---

## **📜 项目结构**
/api
│── models/
│   ├── parser.rb         # 解析引擎
│   ├── rule_based.rb     # 规则解析器
│   ├── ai_interpreter.rb # LLM 解析器
│   ├── hybrid_parser.rb  # 混合解析器
│── routes/
│   ├── parse_routes.rb   # 解析 API
│   ├── feedback_routes.rb # 反馈 API
│── services/
│   ├── llm_service.rb    # LLM 处理
│   ├── rag_service.rb    # RAG 处理
│── helpers/  # 辅助helper类
│   ├── application_helper.rb # 应用层helper

---

## **💎 具体代码要求**

1. ** `/config.ru`**  
   - web api的入口 使用rackup命令启动

2. **`/lib/util/common`**  
   - 公共方法， 提供了访问数据库的能力, 统一使用M访问数据库

3. **`/api/models/parser.rb`（解析引擎）**  
   - `select_parser(parser_name)` 选择合适的解析器
   - `parse(data)` 调用相应解析器处理数据

4. **`/api/models/rule_based.rb`（规则解析器）**  
   - 读取 `content` 字段，返回规则解析结果。

5. **`/api/models/ai_interpreter.rb`（AI 解析器）**  
   - 通过 LLM 解析 `content`，调用 `services/llm_service.rb`

6. **`/api/models/hybrid_parser.rb`（混合解析器）**  
   - 先使用 `RuleBasedParser`，然后调用 `AIInterpreter`
   - 返回合并结果

7. **`/api/services/llm_service.rb`（LLM API 服务）**  
   - 通过 `Faraday` 调用 LLM API（DeepSeek, OpenAI, Claude等）
   - 传入 `prompt`，返回解析文本

8. **`/api/routes/parse_routes.rb`（解析 API）**  
   - `GET /parse/:id`：根据 ID 读取 MongoDB 数据，调用解析器，返回解析结果。

9. **`/api/routes/feedback_routes.rb`（反馈 API）**  
   - `POST /feedback`：存储用户反馈，优化解析逻辑。

10. **`/config.ru`（Sinatra 入口）**  
   - 根目录上已经有config.ru，可以直接使用rackup命令启动。所以不要再创建config.ru了
   -新建一个map, 用来载入 `parse_routes` 和 `feedback_routes` 并运行 Sinatra。

---

## **🌟 生成代码要求**
- **代码应清晰、可读、模块化**
- **遵循 Sinatra & MongoDB 最佳实践**
- **支持未来扩展，例如 RAG、向量数据库**
- **错误处理完善**
- **生成完整项目代码**
- **是在原有架构基础上增加东西进行改造**

请按以上结构 **完整生成 Sinatra 项目代码**，并确保可以运行。谢谢！