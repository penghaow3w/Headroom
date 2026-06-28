██╗  ██╗███████╗ █████╗ ██████╗ ██████╗  ██████╗  ██████╗ ███╗   ███╗
  ██║  ██║██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗████╗ ████║
  ███████║█████╗  ███████║██║  ██║██████╔╝██║   ██║██║   ██║██╔████╔██║
  ██╔══██║██╔══╝  ██╔══██║██║  ██║██╔══██╗██║   ██║██║   ██║██║╚██╔╝██║
  ██║  ██║███████╗██║  ██║██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝     ╚═╝
    The Context Compression Layer for AI Agents — Save 60-95% on Tokens

---

[![GitHub Stars](https://img.shields.io/badge/dynamic/json?logo=github&label=Stars&query=%24.stargazers_count&url=https%3A%2F%2Fapi.github.com%2Frepos%2Fchopratejas%2Fheadroom)](https://github.com/chopratejas/headroom)
[![PyPI](https://img.shields.io/pypi/v/headroom-ai.svg)](https://pypi.org/project/headroom-ai/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/chopratejas/headroom/blob/main/LICENSE)

> Original Author: **Tejas Chopra** (Senior Engineer at Netflix)  
> Original Repo: https://github.com/chopratejas/headroom  
> ⭐ 30K+ Stars | 🐍 Python | 📜 Apache 2.0 License

---

## Table of Contents

- [What is Headroom?](#what-is-headroom)
- [Why Do You Need It?](#why-do-you-need-it)
- [Core Architecture](#core-architecture)
- [6 Compression Algorithms](#6-compression-algorithms)
- [Three Integration Modes](#three-integration-modes)
- [Use Cases](#use-cases)
- [Benchmarks](#benchmarks)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [FAQ](#faq)

---

## What is Headroom?

**Headroom** is a "context compression middleware" — it sits between your AI application and the LLM, intelligently compressing text to **5%-40%** of its original size before sending it to the model, while preserving over 97% of critical information.

Its goal is not to train a better model, but to **reduce token consumption and lower API costs**.

**In one sentence**: Cut your LLM API bills by 60-95% without sacrificing output quality.

---

## Why Do You Need It?

If you've used GPT-4, Claude, Gemini, or any LLM API, you know that **tokens equal money**.

| Scenario | Problem | Typical Token Usage | After Headroom |
|----------|---------|-------------------|----------------|
| **AI Coding Assistant** | Agent tool calls produce massive JSON output | ~17,700 tokens/req | ~1,400 (-92%) |
| **Debug Log Analysis** | Huge log contexts in prompts | ~65,694 tokens/req | ~5,118 (-92%) |
| **RAG Retrieval** | Too many retrieved document chunks | ~30,000 tokens/req | ~6,000 (-80%) |
| **Code Review** | Full files uploaded to the model | ~25,000 tokens/req | ~7,500 (-70%) |
| **Long Conversations** | Accumulated multi-turn context | ~50,000 tokens/req | ~15,000 (-70%) |

**Real-world impact**: Across 889 active community instances, Headroom has saved users approximately **$700,000** and freed over **200 billion tokens** in quota.

---

## Core Architecture

Headroom uses a **transparent proxy + intelligent routing + reversible compression** architecture:

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────┐
│  AI App  │────▶│   Headroom   │────▶│  Compressed  │────▶│   LLM    │
│ (Claude  │     │  Proxy/Client│     │  (60-95% ↓)  │     │ (GPT-4)  │
│  Codex)  │     │              │     │              │     │          │
└──────────┘     └──────────────┘     └──────────────┘     └──────────┘
                       │                       ▲
                       ▼                       │
                 ┌─────────────────────────────────────┐
                 │   CCR (Compress-Cache-Retrieve)     │
                 │  Dropped details can be retrieved   │
                 │  on-demand via tool calls           │
                 └─────────────────────────────────────┘
```

**Pipeline**:

1. **Content Detection**: Analyze message type (JSON, code, logs, text, search results, etc.)
2. **Smart Routing**: Dispatch to the optimal compressor per content type
3. **Layered Compression**: Lossless preprocessing → Lossy compression → Reversible markers
4. **Cache Alignment**: Optimize message prefix structure for better KV Cache hit rates
5. **CCR Reversible Layer**: Dropped key rows can be retrieved on-demand via tool calls

---

## 6 Compression Algorithms

### 1. SmartCrusher (JSON Array Crusher)

> **Applies to**: Tool call outputs, API responses, structured data

- **Lossless phase**: JSON re-serialization (remove whitespace, normalize format), saves 15-25%
- **Lossy phase** (core):
  - Ranks array items by information entropy, preserves "anomalies" (errors, warnings, outliers)
  - Drops "normal" items (repeated success responses, routine log lines)
  - Appends CCR markers for on-demand retrieval
- **Use case**: Code search JSON results, monitoring alerts, database query results

### 2. Kompress (ML Text Compression)

> **Applies to**: Plain text, documents, conversation history

- Uses a specialized **ModernBERT small model** (kompress-v2-base)
- ONNX INT8 quantized version runs on CPU (no GPU required)
- Preserves key semantics, removes redundant expressions
- Supports custom `target_ratio`

### 3. CodeCompressor (AST-Aware Code Compression)

> **Applies to**: Source code files

- **AST-aware**: Parses abstract syntax trees to distinguish signatures, docstrings, comments, and implementations
- Prioritizes preserving function/class signatures, compresses implementations and comments
- Supports tree-sitter (precise) and regex fallback
- Supports dozens of programming languages

### 4. LogCompressor

> **Applies to**: Build output, test logs, runtime logs

- Detects duplicate line patterns, replaces with count summaries
- Detects error/warning patterns, prioritizes preserving exception stacks
- Compresses successful-line details, preserves full failure information

### 5. SearchCompressor

> **Applies to**: grep/ripgrep results, file search output

- Recognizes line-number → content format in search results
- Preserves matching line context, compresses non-critical metadata
- Deduplicates repeated file paths

### 6. CacheAligner

> **Applies to**: All scenarios (universal preprocessing)

- Detects dynamic content in system prompts (UUIDs, timestamps, JWTs)
- Warns about cache invalidation risks
- Optimizes message prefix structure for better KV Cache hit rates

### Auxiliary System: CCR (Compress-Cache-Retrieve)

When SmartCrusher drops data rows, it inserts a special marker `{"_ccr_dropped": "<<ccr:HASH N_rows>>"}`. The LLM can call the `headroom_retrieve` tool to fetch the original data on demand.

This enables a **"compress first, retrieve if needed"** pattern — saving tokens without losing information.

**Two distribution channels**:
- **Tool Injection**: Proxy automatically injects `headroom_retrieve` tool
- **MCP Server**: Exposes retrieval capability via MCP protocol

---

## Three Integration Modes

### 1. Function API — Simplest Integration

```python
from headroom import compress

messages = [
    {"role": "user", "content": "Analyze this search result"},
    {"role": "tool", "content": huge_json_output}
]

result = compress(messages, model="claude-sonnet-4-5-20250929")
# result.messages — Compressed messages
# result.tokens_saved — Tokens saved
# result.compression_ratio — Compression ratio

# Pass directly to any LLM SDK
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    messages=result.messages,
)
```

**Best for**: Any Python project — just call a function.

### 2. Proxy Mode — Zero Code Changes

```bash
pip install headroom-ai[proxy]
headroom proxy --port 8787

# Point your LLM client to the local proxy
# Claude Code:
ANTHROPIC_BASE_URL=http://localhost:8787 claude

# OpenAI SDK:
openai.base_url = "http://localhost:8787/v1"
```

**How it works**: The proxy intercepts all LLM API requests, automatically compresses messages, then forwards them to the real API.

**Best for**: Global compression without code changes.

### 3. Client Wrapper Mode

```python
from headroom import HeadroomClient, OpenAIProvider
from openai import OpenAI

client = HeadroomClient(
    original_client=OpenAI(),
    provider=OpenAIProvider(),
    default_mode="optimize",
)

# Fully transparent compression — same API as the original client
response = client.chat.completions.create(
    model="gpt-4o",
    messages=large_messages,
)

# Check savings
stats = client.get_stats()
print(f"Tokens saved: {stats['session']['tokens_saved_total']}")
```

**Best for**: Programmatic control over compression behavior.

---

## Use Cases

### AI Coding Assistants (Most Popular)

**Problem**: Cursor, Claude Code, GitHub Copilot generate massive tool outputs (search results, file contents, Git diffs).

**Results**:

| Operation | Before | After | Savings |
|-----------|--------|-------|---------|
| Code search (grep) | 17,700 | 1,400 | **-92%** |
| File read | 8,500 | 1,700 | **-80%** |
| Git diff analysis | 12,300 | 2,460 | **-80%** |
| Compile error diagnosis | 65,694 | 5,118 | **-92%** |

### RAG Applications

**Problem**: Retrieved documents often exceed context windows.  
**Result**: 60-80% compression, 97%+ answer quality retention.

### Log Analysis Agents

**Problem**: Agents dump huge logs during debugging.  
**Result**: SmartCrusher automatically extracts anomalies, drops duplicate success logs — up to 95% savings.

### Long Conversations / Multi-turn Agents

**Problem**: Context accumulates to tens of thousands of tokens across multiple tool calls.  
**Result**: 50-70% compression with CCR reversible mechanism ensuring important information is retrievable.

### Batch API Processing

**Problem**: Token costs explode with large batch requests.  
**Result**: Native Batch API integration — compress before submission, auto-handle CCR retrieval in results.

### Multi-Agent Collaboration

**Problem**: Multiple agents sharing large contexts.  
**Result**: SharedContext mechanism enables cross-agent context sharing and compression.

---

## Benchmarks

Data from [official benchmarks](https://headroom-docs.vercel.app/docs/benchmarks):

| Model | Scenario | Original Tokens | Compressed | Savings | Relevance |
|-------|----------|----------------|------------|---------|-----------|
| Claude Sonnet | Code Search | 17,765 | 1,408 | **92%** | 97% |
| Claude Sonnet | Debug Logs | 65,694 | 5,118 | **92%** | 96% |
| GPT-4o | Code Search | 16,200 | 2,430 | **85%** | 95% |
| GPT-4o | JSON Tool Output | 24,000 | 3,600 | **85%** | 98% |
| Claude Opus | Doc Analysis | 30,000 | 9,000 | **70%** | 97% |
| Gemini Pro | RAG Retrieval | 28,000 | 8,400 | **70%** | 95% |

---

## Quick Start

### Installation

```bash
pip install headroom-ai                   # Base (Function API)
pip install headroom-ai[proxy]            # Proxy mode (recommended)
pip install headroom-ai[proxy,code,ml]    # Full (code + ML compression)
```

### 5-Minute Demo

```python
# 1. Function API
from headroom import compress

messages = [
    {"role": "user", "content": "Analyze these search results"},
    {"role": "tool", "content": big_search_result}
]

result = compress(messages, model="gpt-4o")
print(f"Saved {result.tokens_saved} tokens!")

# 2. Advanced config
from headroom import CompressConfig

config = CompressConfig(
    compress_user_messages=True,   # Also compress user messages
    target_ratio=0.3,              # Keep 30% (more aggressive)
    protect_recent=2,              # Protect last 2 messages
)

result = compress(messages, model="gpt-4o", config=config)
```

### Start the Proxy

```bash
headroom proxy --port 8787                # Start proxy

# Monitor savings
headroom savings                          # View savings stats
headroom doctor                           # Run health check
```

---

## Project Structure

```
headroom/
├── headroom/                    # Main Python package
│   ├── compress.py              # One-function compress API (recommended entry)
│   ├── client.py                # HeadroomClient wrapper
│   ├── pipeline.py              # Pipeline lifecycle management
│   ├── config.py                # Configuration models
│   ├── transforms/              # All compression transforms
│   │   ├── smart_crusher.py     # JSON array crusher (Rust impl)
│   │   ├── content_router.py    # Content type router
│   │   ├── cache_aligner.py     # Cache alignment detector
│   │   ├── code_compressor.py   # AST code compressor
│   │   ├── log_compressor.py    # Log compressor
│   │   ├── search_compressor.py # Search result compressor
│   │   └── pipeline.py          # Transform pipeline orchestrator
│   ├── proxy/                   # Proxy server
│   │   ├── server.py            # FastAPI proxy main server
│   │   └── handlers/            # Per-provider handler logic
│   ├── ccr/                     # Reversible compression + on-demand retrieval
│   │   ├── tool_injection.py    # Inject retrieval tool
│   │   ├── response_handler.py  # Handle retrieval requests
│   │   └── context_tracker.py   # Track compressed context
│   ├── cli/                     # Command-line interface
│   │   ├── main.py              # CLI entry point
│   │   ├── proxy.py             # proxy subcommand
│   │   └── savings.py           # savings stats subcommand
│   ├── cache/                   # Cache system
│   ├── memory/                  # Memory system
│   └── relevance/               # Relevance scoring
├── crates/                      # Rust core implementation
│   ├── headroom-core/           # Core algorithms (SmartCrusher, etc.)
│   ├── headroom-py/             # Python-Rust bridge (PyO3)
│   └── headroom-proxy/          # Rust proxy layer
├── tests/                       # Tests
├── docs/                        # Documentation (Next.js)
└── examples/                    # Usage examples
```

---

## FAQ

### Q: Does compression affect AI output quality?
A: Official benchmarks show 95-98% relevance retention. The CCR reversible mechanism ensures critical compressed information can be retrieved via tool calls.

### Q: Which LLM providers are supported?
A: OpenAI, Anthropic, Google Gemini, AWS Bedrock, LiteLLM, and any provider compatible with OpenAI/Anthropic API formats.

### Q: Do I need a GPU?
A: No. Kompress uses ONNX INT8 quantization and runs on CPU. SmartCrusher is purely algorithmic.

### Q: How is this different from prompt compression?
A: Traditional prompt compression just trims text. Headroom performs **semantic-aware intelligent compression** — it distinguishes "normal" from "anomalous" values and preserves critical information.

---

## License

Apache 2.0 — Free for commercial use, modification, and distribution.

---

> **Headroom** is not a new LLM, nor an Agent framework.  
> It does one thing: **makes the text sent to LLMs shorter**.  
> In the AI era, that one thing can save you tens of thousands of dollars a year.