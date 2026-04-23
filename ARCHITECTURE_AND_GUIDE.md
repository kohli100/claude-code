# Gemma 4 + Ollama + Docker MCP + Cursor — Architecture, Data Flow & User Guide

**Machine:** MacBook Pro M4 Max · 128 GB Unified Memory · 40-core GPU  
**Purpose:** Private, offline-capable AI with MCP tool servers integrated into Cursor IDE  
**Date:** April 2026

---

## Table of Contents

1. [Component Overview](#1-component-overview)
2. [Offline Mode — Architecture & Data Flow](#2-offline-mode--architecture--data-flow)
3. [Online Mode — Architecture & Data Flow](#3-online-mode--architecture--data-flow)
4. [Docker MCP Toolkit — Local Tool Servers](#4-docker-mcp-toolkit--local-tool-servers)
5. [Side-by-Side Comparison](#5-side-by-side-comparison)
6. [Pros & Cons](#6-pros--cons)
7. [Security Guide](#7-security-guide)
8. [Installation Steps](#8-installation-steps)
9. [Cursor Integration Steps](#9-cursor-integration-steps)
10. [Daily Usage Guide](#10-daily-usage-guide)
11. [Recommended Models for M4 Max 128 GB](#11-recommended-models-for-m4-max-128-gb)

---

## 1. Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOUR MACBOOK PRO                         │
│                                                                 │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────────┐  │
│  │   CURSOR    │    │    OLLAMA    │    │     GEMMA 4       │  │
│  │  (IDE/UI)   │◄──►│  (Runtime   │◄──►│  (Model Weights)  │  │
│  │             │    │   Engine)   │    │  ~/.ollama/models │  │
│  └─────────────┘    └──────────────┘    └───────────────────┘  │
│                                                                 │
│  What each does:                                                │
│  • CURSOR   — Your coding environment. Sends prompts, shows    │
│               responses. Does NOT process AI itself.           │
│  • OLLAMA   — Loads model into GPU RAM, runs inference,        │
│               serves API at http://localhost:11434             │
│  • GEMMA 4  — The actual AI brain (Google's model weights).   │
│               Just files on disk until Ollama loads them.      │
└─────────────────────────────────────────────────────────────────┘
```

**Analogy:**
- Gemma 4 = A movie file on your hard drive
- Ollama = The video player (VLC)
- Cursor = Your TV screen

---

## 2. Offline Mode — Architecture & Data Flow

> In offline mode, **zero data leaves your machine**. No internet required after initial setup.

```
╔══════════════════════════════════════════════════════════════════╗
║                     OFFLINE MODE DATA FLOW                      ║
╚══════════════════════════════════════════════════════════════════╝

  YOU TYPE A PROMPT IN CURSOR
           │
           ▼
  ┌─────────────────┐
  │  Cursor (IDE)   │  ← Your code, questions, context
  │  localhost only │
  └────────┬────────┘
           │  HTTP request to localhost:11434/v1/chat/completions
           │  (OpenAI-compatible format — NO internet)
           ▼
  ┌─────────────────┐
  │  Ollama Server  │  ← Running on YOUR Mac
  │  localhost:11434│
  └────────┬────────┘
           │  Loads model into unified memory
           │  Runs inference on M4 Max GPU (Metal 4)
           ▼
  ┌─────────────────────────────────────────────────────────┐
  │              M4 Max — 128 GB Unified Memory             │
  │                   40-core Apple GPU                     │
  │                                                         │
  │   Gemma 4 weights (27B ≈ 16 GB) loaded into GPU RAM    │
  │   Processes your prompt entirely on-device             │
  └────────┬────────────────────────────────────────────────┘
           │  Generated tokens streamed back
           ▼
  ┌─────────────────┐
  │  Ollama Server  │
  │  formats response
  └────────┬────────┘
           │  HTTP response back to Cursor
           ▼
  ┌─────────────────┐
  │  Cursor (IDE)   │  ← Response displayed to you
  └─────────────────┘

  ════════════════════════════════════════
  INTERNET:  ✗ NOT USED
  Data sent to cloud:  NONE
  Cost per query:  $0
  Privacy:  TOTAL
  ════════════════════════════════════════
```

### What happens at each stage:

| Stage | Location | Data Present | Leaves Machine? |
|-------|----------|--------------|-----------------|
| You type prompt | Cursor UI | Your text, code context | No |
| Request sent | localhost only | Prompt + context | No |
| Ollama receives | Your Mac RAM | Prompt | No |
| GPU processes | M4 Max GPU | Prompt + model weights | No |
| Response returned | localhost | Generated text | No |
| Displayed in Cursor | Cursor UI | Response | No |

---

## 3. Online Mode — Architecture & Data Flow

> Online mode uses Cursor's default cloud AI (Claude by Anthropic). Your prompts travel over the internet.

```
╔══════════════════════════════════════════════════════════════════╗
║                      ONLINE MODE DATA FLOW                      ║
╚══════════════════════════════════════════════════════════════════╝

  YOU TYPE A PROMPT IN CURSOR
           │
           ▼
  ┌─────────────────┐
  │  Cursor (IDE)   │
  └────────┬────────┘
           │  HTTPS request — encrypted
           │  ⚠️  LEAVES YOUR MACHINE
           ▼
  ┌─────────────────────────────────────────────────────────┐
  │                   THE INTERNET                          │
  │         (encrypted, but data does travel)               │
  └────────┬────────────────────────────────────────────────┘
           │
           ▼
  ┌─────────────────────────────────────────────────────────┐
  │           ANTHROPIC DATA CENTERS (Claude)               │
  │           or OPENAI DATA CENTERS (GPT-4)                │
  │                                                         │
  │   Your prompt + code context processed here            │
  │   Subject to provider's privacy policy                 │
  │   May be used for model training (check settings)      │
  └────────┬────────────────────────────────────────────────┘
           │  Response returned over HTTPS
           ▼
  ┌─────────────────┐
  │  Cursor (IDE)   │  ← Response displayed
  └─────────────────┘

  ════════════════════════════════════════
  INTERNET:  ✓ REQUIRED
  Data sent to cloud:  Your prompts + code
  Cost per query:  Covered by Cursor subscription
  Privacy:  Depends on provider policy
  ════════════════════════════════════════
```

---

## 4. Docker MCP Toolkit — Local Tool Servers

> Docker MCP Toolkit provides **tools** (file access, browser automation, databases) to the AI.  
> Gemma 4 / Ollama provides the **intelligence** (inference).  
> Cursor connects both. Everything stays on your Mac.

### Architecture with MCP

```
╔═══════════════════════════════════════════════════════════════════╗
║              FULL LOCAL STACK — ALL ON YOUR MAC                   ║
╚═══════════════════════════════════════════════════════════════════╝

  ┌──────────────────────────────────────────────────────────────┐
  │                        CURSOR (IDE)                          │
  │                                                              │
  │   You type a prompt → Cursor decides what tools to call     │
  └──────┬───────────────────────────────────────┬──────────────┘
         │  Model inference (OpenAI-compat API)   │  MCP tools (stdio)
         │  http://localhost:11434/v1             │  docker mcp gateway run
         ▼                                        ▼
  ┌─────────────────┐              ┌──────────────────────────────┐
  │  Ollama :11434  │              │  Docker MCP Gateway          │
  │  gemma4:26b     │              │  (containerized, isolated)   │
  │  17 GB on GPU   │              │                              │
  │  M4 Max Metal   │              │  ┌─────────────────────────┐ │
  └─────────────────┘              │  │ playwright  — browser   │ │
                                   │  │ filesystem — file I/O   │ │
                                   │  │ git        — git ops    │ │
                                   │  │ SQLite     — database   │ │
                                   │  └─────────────────────────┘ │
                                   └──────────────────────────────┘

  All traffic: localhost only. Zero internet. Zero cloud.
```

### What Each MCP Server Does

| Server | Tools Available | Use Case |
|--------|----------------|----------|
| `playwright` | 21 browser tools | Automate web tasks, screenshot, scrape |
| `filesystem` | 11 file tools | Read/write files in allowed paths |
| `git` | git status/diff/log/commit | Manage repos without leaving Cursor |
| `SQLite` | read/write SQL queries | Query local databases |

### Current Setup Status

```
Installed:  Docker MCP Toolkit v0.40.3
Connected:  Cursor (via ~/.cursor/mcp.json)
Servers:    4 enabled (playwright, filesystem, git, SQLite)
Tools:      ~47 tools available to Cursor
Config:     ~/.docker/mcp/config.yaml
```

### Allowed Paths (filesystem + git)

```yaml
# ~/.docker/mcp/config.yaml
filesystem:
  paths:
    - ~/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation
    - ~/Documents
    - ~/Desktop
git:
  paths:
    - ~/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation
    - ~/Documents
```

### Key Limitation: Gemma 4 Tool Calling

Gemma 4 supports function/tool calling but is less reliable at it than Claude.
When using Gemma 4 as the model in Cursor with MCP tools:

- ✓ Simple tool calls work well (read file, git status, browser navigate)
- ✓ Multi-step tool chains work with clear prompting
- △ Complex agent loops are better with Claude (online mode)
- △ Gemma may sometimes need explicit instruction to "use the filesystem tool"

**Workaround:** For complex MCP tool workflows, switch to Claude in Cursor.  
For private/sensitive work with file ops, use Gemma 4 — it works fine.

### Adding More MCP Servers

```bash
# Browse 319 available servers
docker mcp catalog show docker-mcp

# Add a server (example: fetch for web content)
docker mcp server add fetch

# Remove a server
docker mcp server rm fetch

# See all active tools
docker mcp tools ls

# Test a specific tool
docker mcp tools call browser_navigate --url https://example.com
```

### Ollama MCP Bridge — Direct Tool Calling Without Cursor

When you want Ollama/Gemma4 to use MCP tools **without Cursor** (scripts, other clients, Open WebUI,
terminal chat), use `ollama-mcp-bridge`. It sits between your client and Ollama as a transparent proxy.

```
Your Client  →  localhost:8000 (bridge)  →  MCP tools (filesystem, etc.)
                        │
                        └→  localhost:11434 (Ollama / Gemma4)
```

**This stack is 100% offline.** Nothing leaves your Mac.

#### What the Bridge Does and Does NOT Do

| | |
|---|---|
| ✅ Adds MCP tool support to `POST /api/chat` | Only this endpoint gets tools |
| ✅ Proxies all other Ollama endpoints unchanged | `/api/generate`, `/api/tags`, etc. work normally |
| ✅ Multi-round tool execution (loops until done) | Gemma4 can call tools multiple times per response |
| ✅ Streaming responses with tool results | |
| ❌ Does NOT use Docker MCP Toolkit's config | Separate `mcp-config.json` — see below |
| ❌ `/api/generate` has no tool support | Use `/api/chat` for all tool-capable requests |

#### Setup (Already Installed on This Machine)

```bash
# Bridge is installed at:
/Users/sukeshkohli/miniforge3/bin/ollama-mcp-bridge   # v0.11.2

# Config file is at:
gemma4_google/mcp-config.json

# Start script:
gemma4_google/start-ollama-mcp-bridge.sh
```

Why miniforge Python? System Python on this Mac is 3.9.6.
The bridge requires Python >= 3.10.15. Miniforge provides 3.12.

#### The mcp-config.json

This is separate from Docker MCP Toolkit's `~/.docker/mcp/config.yaml`.
The bridge launches MCP servers as local processes using `npx` or `uvx`.

**Do NOT use `docker mcp` commands inside this config** — the bridge
can't call Docker MCP gateway as a subprocess.

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/allowed/dir1",
        "/path/to/allowed/dir2"
      ],
      "toolFilter": {
        "mode": "exclude",
        "tools": ["delete_file"]
      }
    }
  }
}
```

To add more servers, use `npx` (Node-based) or `uvx` (Python-based):

```json
{
  "mcpServers": {
    "filesystem": { ... },
    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },
    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/path/to/a/git/repo"]
    }
  }
}
```

**Note on git server:** It requires an actual git repository path.
Run `git init` in a directory first, or point it at an existing repo.

#### Starting the Bridge

```bash
# Foreground (see all logs — recommended when testing)
./start-ollama-mcp-bridge.sh

# Background (runs silently, logs go to bridge.log)
./start-ollama-mcp-bridge.sh --bg

# Manual command (equivalent):
/Users/sukeshkohli/miniforge3/bin/ollama-mcp-bridge \
  --config mcp-config.json \
  --ollama-url http://localhost:11434 \
  --max-tool-rounds 10

# Stop bridge:
kill $(lsof -ti:8000)
```

#### Verify It Works

```bash
# Health check — shows tool count
curl http://localhost:8000/health
# → {"status":"healthy","ollama_status":"running","tools":14}

# Test Gemma4 + filesystem tool
curl -s -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:26b",
    "stream": false,
    "messages": [{"role":"user","content":"List the files in ~/Documents using the filesystem tool."}]
  }' | python3 -c "import json,sys; print(json.load(sys.stdin)['message']['content'])"

# Interactive API docs (browser)
open http://localhost:8000/docs
```

#### Connecting Other Clients to the Bridge

Any Ollama-compatible client: just change the base URL from `:11434` to `:8000`.

```python
# Python (openai SDK)
from openai import OpenAI
client = OpenAI(base_url="http://localhost:8000/v1", api_key="ollama")

# Open WebUI — set Ollama API URL to http://localhost:8000
# LM Studio — point custom endpoint to http://localhost:8000
# curl — use port 8000 instead of 11434
```

#### Docker Alternative (Skip the Python Install)

If you prefer containers, the correct full command is:

```bash
# NOTE: You MUST create mcp-config.json first (see above).
# The Docker version can only use npx/uvx — not local host paths for commands.

docker run -p 8000:8000 \
  -e OLLAMA_URL=http://host.docker.internal:11434 \
  -v "$PWD/mcp-config.json:/mcp-config.json" \
  -w / \
  ghcr.io/jonigl/ollama-mcp-bridge:latest
```

Key flags explained:
- `-e OLLAMA_URL=http://host.docker.internal:11434` — routes to Ollama on your Mac (macOS specific; use `--network host` on Linux)
- `-v "$PWD/mcp-config.json:/mcp-config.json"` — mounts your config into the container
- `-w /` — **required** so relative paths in mcp-config.json resolve correctly

⚠️ **Docker limitation:** MCP server commands in the config must use `npx` or `uvx` — no `docker` commands inside Docker (unless Docker-in-Docker is configured). Also, host filesystem paths are NOT accessible from inside the container unless you add `-v` mounts for each one.

---

## 5. Side-by-Side Comparison

```
┌────────────────────┬─────────────────────────┬─────────────────────────┐
│ Factor             │ OFFLINE (Gemma 4/Ollama) │ ONLINE (Claude/GPT-4)   │
├────────────────────┼─────────────────────────┼─────────────────────────┤
│ Internet needed    │ No                       │ Yes                     │
│ Data leaves Mac    │ Never                    │ Yes (encrypted)         │
│ Cost per query     │ $0 forever               │ Cursor subscription     │
│ Privacy            │ Total/absolute           │ Provider-dependent      │
│ Response quality   │ Very good (27B)          │ Excellent (Claude)      │
│ Response speed     │ Fast (~50 tok/sec)       │ Fast (network-dependent)│
│ Works offline      │ Yes (airplane mode)      │ No                      │
│ Proprietary code   │ Safe to share            │ Review policy first     │
│ Context window     │ 128K tokens              │ 200K tokens (Claude)    │
│ Image support      │ Yes (Gemma 4)            │ Yes                     │
│ Agent/multi-step   │ Limited                  │ Full support            │
│ Codebase indexing  │ No                       │ Yes                     │
│ Model size         │ 27B parameters           │ Unknown (very large)    │
│ Setup effort       │ One-time 15 min          │ Already configured      │
└────────────────────┴─────────────────────────┴─────────────────────────┘
```

---

## 6. Pros & Cons

### Offline Mode (Gemma 4 + Ollama)

**PROS**
- Absolute privacy — proprietary code, client data, trade secrets never leave your machine
- Zero ongoing cost after setup
- Works anywhere — no Wi-Fi needed (flights, travel, remote sites)
- No rate limits, no quotas, no API throttling
- No subscription dependency — works even if Cursor cancels your plan
- Full control over model version — no silent updates
- Can run multiple models simultaneously (128 GB gives you plenty of headroom)
- No data used for third-party model training

**CONS**
- Lower raw capability than frontier cloud models for complex reasoning
- No built-in web search or real-time information
- Limited agent/tool-use capabilities compared to Claude
- No automatic codebase-wide indexing
- You manage model updates manually
- Initial model download requires internet (one-time, ~16 GB for 27B)
- Disk space: models are large (16–40 GB each)

### Online Mode (Claude via Cursor)

**PROS**
- State-of-the-art reasoning and code quality
- Full agent capabilities (multi-step, file edits, terminal)
- Automatic codebase indexing and @codebase search
- Always up to date with latest model improvements
- No local GPU/RAM usage for AI inference
- Web search and real-time information access

**CONS**
- Requires active internet connection
- Your code and prompts travel to third-party servers
- Subject to Anthropic/Cursor privacy policies
- Tied to subscription continuity
- Not suitable for highly sensitive/classified code without policy review
- Rate limits apply on heavy usage

---

## 7. Security Guide

### Rule 1 — Know What to Send Where

```
USE OFFLINE (Gemma 4) FOR:              USE ONLINE (Claude) FOR:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Client proprietary code              • Open source projects
• Passwords, API keys, secrets         • General coding questions
• Internal business logic              • Complex multi-step refactors
• Financial/medical/legal data         • Architecture planning
• Pre-patent IP or research            • Code reviews of public code
• Anything under NDA                   • Learning and exploration
```

### Rule 2 — Ollama Network Binding

By default, Ollama only listens on `localhost` — it cannot be reached from other devices on your network. **Keep it this way.** Never run:
```bash
# DANGEROUS — exposes your AI to your entire network
OLLAMA_HOST=0.0.0.0 ollama serve   # Do NOT do this
```

### Rule 3 — Model Storage Location

Models are stored at:
```
~/.ollama/models/
```
This is outside iCloud sync by default. Verify iCloud Drive is not syncing your home folder to avoid uploading 16+ GB model files.

Check: System Settings → Apple ID → iCloud → iCloud Drive → Desktop & Documents Folders should be OFF for `~/.ollama`.

### Rule 4 — Cursor's Privacy Mode

When using online Claude in Cursor, enable Privacy Mode:
```
Cursor Settings → General → Privacy Mode → ON
```
This tells Cursor not to store your code for training purposes.

### Rule 5 — Audit What Models You Have Installed

```bash
# See all installed models and their sizes
ollama list
```
Remove models you no longer use:
```bash
ollama rm model-name
```

### Rule 6 — Keep Ollama Updated

```bash
# Check current version
ollama --version

# Update: re-download from ollama.com or use Homebrew
brew upgrade ollama   # if installed via Homebrew
```

---

## 8. Installation Steps

### Step 1 — Install Ollama

1. Go to [https://ollama.com](https://ollama.com)
2. Click **Download for Mac**
3. Unzip the downloaded file
4. Drag `Ollama.app` to your `/Applications` folder
5. Open Ollama — it appears as a llama icon in your menu bar

### Step 2 — Download Gemma 4 Model

Open Terminal and run:

```bash
# Best all-around model for M4 Max 128 GB (recommended)
ollama pull gemma4:27b

# Smaller/faster option (if you want near-instant responses)
ollama pull gemma4:e4b

# Verify download succeeded
ollama list
```

The 27B model is approximately 16 GB. Download time depends on your connection speed.

### Step 3 — Test It Works

```bash
# Quick test from terminal
ollama run gemma4:27b "Explain what unified memory architecture means in 2 sentences"

# Exit the interactive session
/bye
```

---

## 9. Cursor Integration Steps

### Step 1 — Open Cursor Settings
Press `Cmd + ,` (comma) → navigate to **Models** tab

### Step 2 — Add Custom Model

Scroll to the **"OpenAI API Key"** section and enable it. Then add:

```
Base URL:    http://localhost:11434/v1
API Key:     ollama
Model Name:  gemma4:27b
```

Click **Verify** — Cursor will confirm the connection is working.

### Step 3 — Use It in Chat

1. Open Chat panel: `Cmd + L`
2. Click the model name at the bottom of the chat input
3. Select `gemma4:27b` from the dropdown
4. Type your prompt — everything runs locally

### Step 4 — Switch Between Models

You can freely switch between Gemma 4 (offline) and Claude (online) **in the same Cursor session** by clicking the model selector. Each conversation can use a different model.

```
Cmd+L → model selector → gemma4:27b   ← offline/private
Cmd+L → model selector → claude-4.5   ← online/powerful
```

---

## 10. Daily Usage Guide

### Morning Startup (if Ollama isn't already running)

Ollama auto-starts with your Mac after installation. Verify it's running:
```bash
ollama list   # if this responds, Ollama is running
```

### Workflow Decision Tree

```
Have a task in Cursor?
        │
        ├── Contains sensitive/proprietary code?
        │           │
        │           YES → Use gemma4:27b (offline)
        │           │
        │           NO
        │           │
        ├── Need agent/multi-file editing?
        │           │
        │           YES → Use Claude (online)
        │           │
        │           NO
        │           │
        ├── Need web search or current info?
        │           │
        │           YES → Use Claude (online)
        │           │
        │           NO → Either works, prefer gemma4:27b
        │
        └── On airplane/no internet?
                    │
                    YES → gemma4:27b only option (and it works great)
```

### Useful Ollama Commands

```bash
ollama list                    # See installed models
ollama ps                      # See currently running models
ollama run gemma4:27b          # Interactive terminal chat
ollama stop gemma4:27b         # Free up GPU memory
ollama rm gemma4:27b           # Delete model from disk
ollama pull gemma4:27b         # Update to latest version
```

### Freeing GPU Memory

When you're done with Gemma 4 and want full GPU for other tasks:
```bash
ollama stop gemma4:27b
```

---

## 11. Recommended Models for M4 Max 128 GB

Your machine can run any of these simultaneously or individually:

| Model | Size on Disk | RAM Used | Best For |
|-------|-------------|----------|----------|
| `gemma4:27b` | ~16 GB | ~18 GB | Best Gemma 4 — coding, reasoning |
| `gemma4:e4b` | ~3 GB | ~5 GB | Fast responses, light tasks |
| `llama3.3:70b` | ~40 GB | ~45 GB | Meta's most capable open model |
| `qwen2.5:72b` | ~40 GB | ~45 GB | Excellent for coding tasks |
| `deepseek-r1:70b` | ~40 GB | ~45 GB | Math, logic, reasoning |
| `mistral:7b` | ~4 GB | ~5 GB | Ultra-fast for quick questions |

With 128 GB unified memory, you could run `gemma4:27b` + `mistral:7b` simultaneously and still have 100+ GB free for your other work.

---

## Quick Reference Card

```
╔════════════════════════════════════════════════════════════╗
║                QUICK REFERENCE — DAILY USE                 ║
╠════════════════════════════════════════════════════════════╣
║  OLLAMA                                                    ║
║  Start Ollama:     Opens automatically at login            ║
║  Check running:    ollama list                             ║
║  Pull model:       ollama pull gemma4:26b                  ║
║  Test in terminal: ollama run gemma4:26b                   ║
║  Use in Cursor:    Cmd+L → select gemma4:26b               ║
║  Free GPU memory:  ollama stop gemma4:26b                  ║
╠════════════════════════════════════════════════════════════╣
║  DOCKER MCP TOOLKIT                                        ║
║  Check servers:    docker mcp server ls                    ║
║  List tools:       docker mcp tools ls                     ║
║  Add a server:     docker mcp server add <name>            ║
║  Browse catalog:   docker mcp catalog show docker-mcp      ║
║  Config path:      ~/.docker/mcp/config.yaml               ║
║  Cursor config:    ~/.cursor/mcp.json                      ║
╠════════════════════════════════════════════════════════════╣
║  ACTIVE MCP SERVERS (4)                                    ║
║  playwright  — browser automation (21 tools)              ║
║  filesystem  — file read/write (11 tools)                  ║
║  git         — git operations                              ║
║  SQLite      — local database queries                      ║
╠════════════════════════════════════════════════════════════╣
║  PRIVACY MODES                                             ║
║  OFFLINE (Private):  gemma4:26b + MCP tools → local only  ║
║  ONLINE (Powerful):  Claude → cursor subscription          ║
╠════════════════════════════════════════════════════════════╣
║  ENDPOINTS                                                 ║
║  Ollama API:       http://localhost:11434                  ║
║  Models stored at: ~/.ollama/models/                       ║
╚════════════════════════════════════════════════════════════╝
```

---

*Document created for BlackBranch Research & Innovation — M4 Max 128 GB configuration*  
*Last updated: April 2026 — added Docker MCP Toolkit integration (v0.40.3)*
*Open WebUI: v0.9.1 (April 21, 2026) — update instructions in run_MCP_webUI.md*
