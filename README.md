██╗  ██╗███████╗ █████╗ ██████╗ ██████╗  ██████╗  ██████╗ ███╗   ███╗
  ██║  ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗████╗ ████║
  ███████║█████╗  ███████║██║  ██║██████╔╝██║   ██║██║   ██║██╔████╔██║
  ██╔══██║██╔══╝  ██╔══██║██║  ██║██╔══██╗██║   ██║██║   ██║██║╚██╔╝██║
  ██║  ██║███████╗██║  ██║██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝
           AI Agent 上下文压缩层 — 节省 60-95% Token 消耗

---

[![GitHub Stars](https://img.shields.io/badge/dynamic/json?logo=github&label=Stars&query=%24.stargazers_count&url=https%3A%2F%2Fapi.github.com%2Frepos%2Fchopratejas%2Fheadroom)](https://github.com/chopratejas/headroom)
[![PyPI](https://img.shields.io/pypi/v/headroom-ai.svg)](https://pypi.org/project/headroom-ai/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/chopratejas/headroom/blob/main/LICENSE)

> 原作者: **Tejas Chopra** (Netflix 高级工程师)  
> 仓库: https://github.com/chopratejas/headroom  
> ⭐ 当前 30K+ Stars | 🐍 Python 项目 | 📜 Apache 2.0 开源协议

---

## 目录

- [这是什么？](#这是什么)
- [为什么需要它？](#为什么需要它)
- [核心原理](#核心原理)
- [6 大压缩算法详解](#6-大压缩算法详解)
- [三种使用模式](#三种使用模式)
- [实际应用场景](#实际应用场景)
- [效果数据](#效果数据)
- [快速开始](#快速开始)
- [项目结构](#项目结构)

---

## 这是什么？

**Headroom** 是一个"上下文压缩中间层"——它位于你的 AI 应用和 LLM 之间，在把文本发给大模型之前，先把文本智能压缩到原来的 **5%-40%**，同时保留 97% 以上的关键信息。

它的目标不是训练更好的模型，而是让 **Token 消耗变少、API 调用变便宜**。

**一句话总结**: 在不降低 AI 输出质量的前提下，把你的 LLM API 账单砍掉 60-95%。

---

## 为什么需要它？

如果你用过 GPT-4、Claude、Gemini 等大模型 API，你就会知道 **Token 就是钱**。

| 场景 | 问题 | 典型 Token 消耗 | Headroom 压缩后 |
|------|------|----------------|-----------------|
| **AI 编程助手** | Agent 工具调用产生大量 JSON 输出 | ~17,700 tokens/次 | ~1,400 (-92%) |
| **日志调试** | 海量日志上下文塞进 prompt | ~65,694 tokens/次 | ~5,118 (-92%) |
| **RAG 检索** | 检索到的文档片段太多 | ~30,000 tokens/次 | ~6,000 (-80%) |
| **代码审查** | 整个文件上传给模型 | ~25,000 tokens/次 | ~7,500 (-70%) |
| **长对话历史** | 多轮对话积累的上下文 | ~50,000 tokens/次 | ~15,000 (-70%) |

**实际成果**: 该项目社区汇总的 889 个活跃实例显示，已帮助用户节省约 **70 万美元**，释放超过 **2000 亿 Token 配额**。

---

## 核心原理

Headroom 采用**透明代理 + 智能路由 + 可逆压缩**的架构：

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
│  AI App  │────▶│  Headroom    │────▶│   压缩后消息   │────▶│   LLM    │
│ (Claude  │     │  代理/客户端  │     │  (60-95% ↓)   │     │ (GPT-4)  │
│  Codex)  │     │              │     │               │     │          │
└──────────┘     └──────────────┘     └──────────────┘     └──────────┘
                       │                       ▲
                       ▼                       │
                 ┌─────────────────────────────────┐
                 │     CCR (可逆压缩 + 按需检索)     │
                 │  压缩掉的细节可以通过 tool call    │
                 │  让 LLM 按需找回，绝不丢信息       │
                 └─────────────────────────────────┘
```

**工作流程**:

1. **内容检测**: 分析消息类型（JSON、代码、日志、普通文本、搜索结果等）
2. **智能路由**: 根据内容类型分发到最佳压缩器
3. **分层压缩**: 无损预处理 → 有损精压缩 → 可逆标记
4. **缓存对齐**: 优化消息前缀结构，提升 Provider 端 KV Cache 命中率
5. **CCR 可逆层**: 被压缩掉的关键行可以通过工具调用按需检索

---

## 6 大压缩算法详解

### 1. SmartCrusher (JSON 数组粉碎机) 🔥

> **适用**: 工具调用输出、API 响应、结构化数据

- **无损阶段**: JSON 重新序列化（消除冗余空格、统一格式），平均节省 15-25%
- **有损阶段** (核心): 
  - 按信息熵对数组每行排序，保留"异常值"（错误、警告、离群数据）
  - 丢弃"正常值"（重复的成功响应、常规日志行）
  - 附加 CCR 标记，LLM 可以按需找回被丢弃的行
- **应用**: 代码搜索 JSON 结果、监控告警数据、数据库查询结果

### 2. Kompress (ML 文本压缩) 🧠

> **适用**: 普通文本、文档、对话历史

- 使用专门的 **ModernBERT 小模型** (kompress-v2-base) 进行智能压缩
- ONNX INT8 量化版本无需 GPU，CPU 即可运行
- 保留关键语义，去除冗余表达
- 支持自定义目标保留比例 (target_ratio)

### 3. CodeCompressor (代码感知压缩) 💻

> **适用**: 源代码文件

- **AST 感知**: 解析代码的抽象语法树，区分签名、文档字符串、注释和实现体
- 优先保留函数/类签名，压缩实现体和注释
- 支持 tree-sitter 语法树（更精确）和正则后备方案
- 支持数十种编程语言的 AST 解析

### 4. LogCompressor (日志压缩) 📋

> **适用**: 构建输出、测试日志、运行时日志

- 识别重复行模式，用计数替换（"同样的错误重复了 50 次"）
- 检测错误/警告模式，优先保留异常堆栈
- 压缩成功行的细节，保留失败行的完整信息

### 5. SearchCompressor (搜索结果压缩) 🔍

> **适用**: grep/ripgrep 搜索结果、文件查找输出

- 识别搜索结果的行号-内容格式
- 保留匹配行上下文，压缩非关键元数据
- 对重复的文件路径进行去重合并

### 6. CacheAligner (缓存对齐) 💾

> **适用**: 所有场景（通用预处理）

- 检测 system prompt 中的动态内容（UUID、时间戳、JWT Token）
- 提示用户 cache 无效化风险
- 优化消息前缀结构以提升 Provider KV Cache 命中率

### 辅助系统: CCR (可逆压缩 + 按需检索)

当 SmartCrusher 丢弃数据行时，会在数组中插入一个特殊标记 `{"_ccr_dropped": "<<ccr:HASH N_rows>>"}`。LLM 看到这个标记后，可以通过调用 `headroom_retrieve` 工具来获取被压缩掉的原始数据。

这种方式实现了 **"先压缩，不够再查"** 的高效模式，既省 Token 又不丢信息。

**两种分发方式**:
- **Tool Injection**: 代理模式自动注入 `headroom_retrieve` 工具
- **MCP 服务器**: 通过 MCP 协议暴露检索能力

---

## 三种使用模式

### 1. 函数模式 (函数式 API) — 最简单的集成方式

```python
from headroom import compress

messages = [
    {"role": "user", "content": "分析以下日志数据"},
    {"role": "tool", "content": huge_json_output}
]

result = compress(messages, model="claude-sonnet-4-5-20250929")
# result.messages — 压缩后的消息
# result.tokens_saved — 节省的 Token 数
# result.compression_ratio — 压缩率

# 直接传给任何 LLM SDK
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    messages=result.messages,
)
```

**适合**: 任何 Python 项目，直接调用函数即可。

### 2. 代理模式 (Proxy) — 零代码改造

```bash
pip install headroom-ai[proxy]
headroom proxy --port 8787

# 然后将 LLM 客户端指向本地代理
# Claude Code:
ANTHROPIC_BASE_URL=http://localhost:8787 claude

# OpenAI SDK:
openai.base_url = "http://localhost:8787/v1"
```

**原理**: 代理拦截所有 LLM API 请求，自动压缩消息内容，然后转发到真正的 API。

**适合**: 不想改代码、希望全局生效的场景。

### 3. 客户端包装模式 (Client Wrapper)

```python
from headroom import HeadroomClient, OpenAIProvider
from openai import OpenAI

client = HeadroomClient(
    original_client=OpenAI(),
    provider=OpenAIProvider(),
    default_mode="optimize",
)

# 完全透明的压缩，用法和原始客户端一样
response = client.chat.completions.create(
    model="gpt-4o",
    messages=large_messages,
)

# 查看节省了多少
stats = client.get_stats()
print(f"节省 Token: {stats['session']['tokens_saved_total']}")
```

**适合**: 在代码中以编程方式控制压缩行为。

---

## 实际应用场景

### 🎯 场景 1: AI 编程助手 (最热门)

**问题**: Cursor、Claude Code、GitHub Copilot 等编程助手在分析代码时，工具输出（搜索结果、文件内容、Git diff）极其庞大。

**效果**:

| 操作 | 原始 | 压缩后 | 节省 |
|------|------|--------|------|
| 代码搜索 (grep) | 17,700 | 1,400 | **-92%** |
| 文件读取 | 8,500 | 1,700 | **-80%** |
| Git diff 分析 | 12,300 | 2,460 | **-80%** |
| 编译错误诊断 | 65,694 | 5,118 | **-92%** |

### 🎯 场景 2: RAG 应用

**问题**: 检索增强生成中，检索到的文档往往超出上下文窗口。

**效果**: 压缩 60-80%，回答质量保持 97% 以上。

### 🎯 场景 3: 日志分析 Agent

**问题**: Agent 在排查问题时塞入大量日志。

**效果**: SmartCrusher 自动提取异常和关键行，丢弃重复成功日志，最高节省 95%。

### 🎯 场景 4: 长对话 / 多轮 Agent

**问题**: Agent 多轮工具调用后，上下文积累到数万 Token。

**效果**: 压缩 50-70%，且 CCR 可逆机制保证重要信息可控。

### 🎯 场景 5: 批量数据处理 (Batch API)

**问题**: 大批量请求处理时 Token 成本暴增。

**效果**: 与 Batch API 原生集成，支持提交前压缩、结果中自动处理 CCR 检索。

### 🎯 场景 6: 多 Agent 协作

**问题**: 多个 Agent 之间共享上下文。

**效果**: SharedContext 机制支持跨 Agent 的上下文共享和压缩。

---

## 效果数据

以下数据来自 [官方基准测试](https://headroom-docs.vercel.app/docs/benchmarks):

| 模型 | 场景 | 原始 Token | 压缩后 Token | 节省 | 相关度保持 |
|------|------|-----------|-------------|------|-----------|
| Claude Sonnet | 代码搜索 | 17,765 | 1,408 | **92%** | 97% |
| Claude Sonnet | 日志调试 | 65,694 | 5,118 | **92%** | 96% |
| GPT-4o | 代码搜索 | 16,200 | 2,430 | **85%** | 95% |
| GPT-4o | JSON 工具输出 | 24,000 | 3,600 | **85%** | 98% |
| Claude Opus | 文档分析 | 30,000 | 9,000 | **70%** | 97% |
| Gemini Pro | RAG 检索 | 28,000 | 8,400 | **70%** | 95% |

---

## 快速开始

### 安装

```bash
pip install headroom-ai                   # 基础版 (函数 API)
pip install headroom-ai[proxy]              # 代理模式 (推荐)
pip install headroom-ai[proxy,code,ml]      # 全功能 (代码压缩 + ML 压缩)
```

### 5 分钟上手

```python
# 1. 函数式压缩
from headroom import compress

messages = [
    {"role": "user", "content": "分析这个搜索结果"},
    {"role": "tool", "content": big_search_result}
]

result = compress(messages, model="gpt-4o")
print(f"节省了 {result.tokens_saved} 个 Token!")

# 2. 高级配置
from headroom import CompressConfig

config = CompressConfig(
    compress_user_messages=True,   # 也压缩用户消息
    target_ratio=0.3,              # 保留 30% (更激进)
    protect_recent=2,              # 保护最近 2 条消息
)

result = compress(messages, model="gpt-4o", config=config)
```

### 启动代理

```bash
headroom proxy --port 8787                 # 启动代理

# 同时监控 Token 节省
headroom savings                           # 查看节省统计
headroom doctor                            # 运行健康检查
```

---

## 项目结构

```
headroom/
├── headroom/                    # Python 主包
│   ├── compress.py              # 一键压缩 API (推荐入口)
│   ├── client.py                # HeadroomClient 包装器
│   ├── pipeline.py              # 管道生命周期管理
│   ├── config.py                # 配置模型
│   ├── transforms/              # 所有压缩变换
│   │   ├── smart_crusher.py     # JSON 数组粉碎机 (Rust 实现)
│   │   ├── content_router.py    # 内容类型路由
│   │   ├── cache_aligner.py     # 缓存对齐检测
│   │   ├── code_compressor.py   # AST 代码压缩
│   │   ├── log_compressor.py    # 日志压缩
│   │   ├── search_compressor.py # 搜索结果压缩
│   │   └── pipeline.py          # 变换管道编排
│   ├── proxy/                   # 代理服务器
│   │   ├── server.py            # FastAPI 代理主服务
│   │   └── handlers/            # 各 Provider 的处理逻辑
│   ├── ccr/                     # 可逆压缩 + 按需检索
│   │   ├── tool_injection.py    # 注入检索工具
│   │   ├── response_handler.py  # 处理检索请求
│   │   └── context_tracker.py   # 跟踪压缩上下文
│   ├── cli/                     # 命令行工具
│   │   ├── main.py              # CLI 主入口
│   │   ├── proxy.py             # proxy 子命令
│   │   └── savings.py           # 节省统计子命令
│   ├── cache/                   # 缓存系统
│   ├── memory/                  # 记忆系统
│   └── relevance/               # 相关性评分
├── crates/                      # Rust 核心实现
│   ├── headroom-core/           # 核心算法 (SmartCrusher 等)
│   ├── headroom-py/             # Python-Rust 桥接 (PyO3)
│   └── headroom-proxy/          # Rust 代理层
├── tests/                       # 测试
├── docs/                        # 文档 (Next.js)
└── examples/                    # 使用示例
```

---

## 常见问题

### Q: 压缩会影响 AI 输出质量吗？
A: 官方基准测试显示，相关度保持率高达 95-98%。CCR 可逆机制保证了被压缩的关键信息可以通过 tool call 找回。

### Q: 支持哪些 LLM Provider？
A: OpenAI、Anthropic、Google Gemini、AWS Bedrock、LiteLLM，以及任何兼容 OpenAI/Anthropic API 格式的 Provider。

### Q: 运行需要 GPU 吗？
A: 不需要。Kompress 模型使用 ONNX INT8 量化，CPU 即可运行。SmartCrusher 更是纯算法实现。

### Q: 和 Prompt 压缩有什么区别？
A: 传统 Prompt 压缩只是删减文字，而 Headroom 是**语义感知的智能压缩**，能区分"正常值"和"异常值"，保留关键信息。

---

## 许可证

Apache 2.0 — 可自由商用、修改和分发。

---

> **Headroom** 不是一个新的 LLM，也不是一个 Agent 框架。  
> 它只做一件事：**让发给大模型的文本变短**。  
> 但在 AI 时代，这件事每年能帮你省下几万美元。