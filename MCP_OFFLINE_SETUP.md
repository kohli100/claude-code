# MCP Offline Setup — Gemma4 + Ollama + Docker MCP + ollama-mcp-bridge

**Machine:** MacBook Pro M4 Max · 128 GB Unified Memory · 40-core GPU  
**Privacy:** 100% local — zero data leaves the machine  
**Date:** April 2026

---

## What Was Built

Two parallel MCP stacks, both fully offline:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        YOUR MAC (100% LOCAL)                        │
│                                                                     │
│  STACK A — Cursor + Docker MCP Toolkit                             │
│  ─────────────────────────────────────                             │
│  Cursor IDE  ←──MCP tools──►  Docker MCP Gateway                  │
│      │                         • playwright  (21 tools)            │
│      │                         • filesystem  (14 tools)            │
│      └──inference──►  Ollama :11434 → gemma4:26b                  │
│                                                                     │
│  STACK B — Any Client + ollama-mcp-bridge                          │
│  ──────────────────────────────────────                            │
│  Any Client  ──►  Bridge :8000  ──MCP──►  filesystem (14 tools)   │
│                       │                                             │
│                       └──inference──►  Ollama :11434 → gemma4:26b  │
│                                                                     │
│  Both stacks: localhost only. No internet. No cloud.               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Installed Software Versions

| Component | Version | Location |
|-----------|---------|----------|
| Docker Desktop | 29.3.1 | `/usr/local/bin/docker` |
| Docker MCP Toolkit | v0.40.3 | `docker mcp` plugin |
| Ollama | 0.20.5 | `/usr/local/bin/ollama` |
| gemma4:26b | 17 GB | `~/.ollama/models/` |
| ollama-mcp-bridge | v0.11.2 | `/Users/sukeshkohli/miniforge3/bin/ollama-mcp-bridge` |
| Python (bridge) | 3.12.10 | miniforge3 (system Python 3.9.6 is too old) |
| Node.js | v24.3.0 | `/opt/homebrew/bin/node` |
| npx | 11.5.2 | `/opt/homebrew/bin/npx` |
| uvx | 0.11.6 | `/Users/sukeshkohli/miniforge3/bin/uvx` |

---

## Stack A — Cursor + Docker MCP Toolkit

### How It Works

Cursor acts as the MCP client. It connects to the Docker MCP Gateway which
manages containerized MCP servers. Gemma4 runs inference via Ollama. The model
can call MCP tools through Cursor's tool-calling interface.

### Enabled MCP Servers

```
docker mcp server ls
```

| Server | Config | Tools | Description |
|--------|--------|-------|-------------|
| `playwright` | — | 21 | Browser automation, screenshots, web scraping |
| `filesystem` | ✓ | 14 | File read/write/search in allowed paths |
| `git` | ✓ | ~10 | Git status, diff, log, commit |
| `SQLite` | — | 3 | Local database read/write queries |

### Allowed Paths (filesystem + git)

```
~/.docker/mcp/config.yaml
```

```yaml
filesystem:
  paths:
    - /Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation
    - /Users/sukeshkohli/Documents
    - /Users/sukeshkohli/Desktop
git:
  paths:
    - /Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation
    - /Users/sukeshkohli/Documents
```

### Cursor Connection

```
~/.cursor/mcp.json
```

```json
{
  "mcpServers": {
    "MCP_DOCKER": {
      "command": "docker",
      "args": ["mcp", "gateway", "run"]
    }
  }
}
```

This file was written automatically by:

```bash
docker mcp client connect cursor --global
```

### Using Gemma4 in Cursor

1. Open Chat: `Cmd + L`
2. Click model selector at bottom of chat
3. Select `gemma4:26b`
4. Cursor routes inference to `localhost:11434` and MCP tools to the Docker gateway

### Useful Docker MCP Commands

```bash
docker mcp server ls                     # list enabled servers
docker mcp tools ls                      # list all ~47 available tools
docker mcp server add <name>            # add a server from catalog (319 available)
docker mcp server rm <name>             # remove a server
docker mcp catalog show docker-mcp      # browse all 319 servers
docker mcp client connect cursor --global  # reconnect Cursor if needed
```

---

## Stack B — ollama-mcp-bridge (Direct, Cursor-Free)

### Why Use This Stack

- You want MCP tools from scripts, Python, terminal chat, or Open WebUI
- You want tool calling **without Cursor open**
- You want to test tool calling directly via `curl`

### How It Works

The bridge is a FastAPI server that proxies the Ollama API. On `POST /api/chat`
it injects MCP tool definitions into the request, intercepts tool calls Gemma4
makes, executes them against the MCP servers, and feeds results back — looping
until the model is done using tools.

```
POST /api/chat  →  bridge adds tools  →  Ollama/Gemma4
                        ↑ tool calls loop ↑
                   MCP servers execute tools
```

All other Ollama endpoints (`/api/tags`, `/api/generate`, etc.) are passed
through unchanged — the bridge is a transparent proxy for everything except
`/api/chat`.

### Project Files

```
gemma4_google/
├── mcp-config.json              ← MCP servers config for the bridge
├── start-ollama-mcp-bridge.sh   ← startup script
└── bridge.log                   ← created when running in --bg mode
```

### mcp-config.json

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation",
        "/Users/sukeshkohli/Documents",
        "/Users/sukeshkohli/Desktop"
      ],
      "toolFilter": {
        "mode": "exclude",
        "tools": ["delete_file"]
      }
    }
  }
}
```

**Key rule:** Use `npx` for Node-based servers, `uvx` for Python-based servers.
Do NOT use `docker mcp` commands here — that is Stack A's system.

### Adding More MCP Servers to the Bridge

```json
{
  "mcpServers": {
    "filesystem": { "...": "..." },

    "fetch": {
      "command": "uvx",
      "args": ["mcp-server-fetch"]
    },

    "git": {
      "command": "uvx",
      "args": ["mcp-server-git", "--repository", "/path/to/actual/git/repo"]
    },

    "sqlite": {
      "command": "uvx",
      "args": ["mcp-server-sqlite", "--db-path", "/path/to/database.db"]
    }
  }
}
```

> **Note on git server:** Requires an actual git repository (`git init` first).
> A plain directory will fail with "not a valid Git repository".

### Tool Filtering Options

```json
"toolFilter": {
  "mode": "exclude",          ← "exclude" = all tools EXCEPT listed ones
  "tools": ["delete_file"]    ← block dangerous tools
}

"toolFilter": {
  "mode": "include",          ← "include" = ONLY these tools
  "tools": ["read_file", "list_directory"]
}
```

### Starting the Bridge

```bash
cd "/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation/gemma4_google"

# Foreground (see logs live — best for testing)
./start-ollama-mcp-bridge.sh

# Background (logs go to bridge.log)
./start-ollama-mcp-bridge.sh --bg

# Stop the bridge
kill $(lsof -ti:8000)
```

### Manual Start (full options)

```bash
/Users/sukeshkohli/miniforge3/bin/ollama-mcp-bridge \
  --config mcp-config.json \
  --ollama-url http://localhost:11434 \
  --max-tool-rounds 10 \
  --system-prompt "You are a helpful AI assistant with access to local tools."
```

### Verify It Works

```bash
# Health check — shows tool count
curl http://localhost:8000/health
# → {"status":"healthy","ollama_status":"running","tools":14}

# Ask Gemma4 to use the filesystem tool
curl -s -X POST http://localhost:8000/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:26b",
    "stream": false,
    "messages": [
      {
        "role": "user",
        "content": "List the files in ~/Documents using the filesystem tool."
      }
    ]
  }' | python3 -c "import json,sys; print(json.load(sys.stdin)['message']['content'])"

# Interactive API docs (browser)
open http://localhost:8000/docs
```

### Connecting Clients to the Bridge

Any Ollama-compatible client — just change port `11434` → `8000`.

```python
# Python (openai SDK)
from openai import OpenAI
client = OpenAI(base_url="http://localhost:8000/v1", api_key="ollama")
response = client.chat.completions.create(
    model="gemma4:26b",
    messages=[{"role": "user", "content": "List my Documents folder"}]
)
print(response.choices[0].message.content)
```

```bash
# Open WebUI — set Ollama API URL to http://localhost:8000
# LM Studio  — set custom endpoint to http://localhost:8000
```

### Docker Alternative (No Python Install Required)

> You still need to create `mcp-config.json` first. The bridge is not
> configured by Docker MCP Toolkit — it reads its own JSON file.

```bash
docker run -p 8000:8000 \
  -e OLLAMA_URL=http://host.docker.internal:11434 \
  -v "$PWD/mcp-config.json:/mcp-config.json" \
  -w / \
  ghcr.io/jonigl/ollama-mcp-bridge:latest
```

**All flags are required:**

| Flag | Why |
|------|-----|
| `-p 8000:8000` | Expose bridge on host port 8000 |
| `-e OLLAMA_URL=http://host.docker.internal:11434` | Reach Ollama on your Mac (macOS/Windows only; use `--network host` on Linux) |
| `-v "$PWD/mcp-config.json:/mcp-config.json"` | Mount your config into the container |
| `-w /` | **Required** — sets working dir so relative paths in config resolve correctly |

**Docker limitations:**
- MCP server commands inside the container can only use `npx` or `uvx`
- `docker mcp` commands do NOT work inside the container
- Host filesystem paths are only accessible if you add `-v` mounts for each one

---

## What Was Wrong With the Original Instructions (Fixed Here)

| # | Original Problem | Status |
|---|-----------------|--------|
| 1 | `mcp-config.json` never shown or created | ✅ Fixed — file created and documented |
| 2 | Docker command missing `-w /` flag | ✅ Fixed — all required flags documented |
| 3 | `pip install` would fail (Python 3.9.6 < 3.10.15) | ✅ Fixed — installed via miniforge Python 3.12 |
| 4 | Docker container can't access host paths without `-v` mounts | ✅ Fixed — limitation documented |
| 5 | `/api/generate` has no MCP tool support | ✅ Fixed — use `/api/chat` only |
| 6 | Git server needs an actual git repo, not any directory | ✅ Fixed — removed from default config; requirement documented |

---

## Privacy & Security Summary

```
╔══════════════════════════════════════════════════════════════╗
║                  WHAT STAYS LOCAL — ALL OF IT               ║
╠══════════════════════════════════════════════════════════════╣
║  Your prompts         → never leave localhost               ║
║  Your file contents   → read by MCP server on your Mac      ║
║  Gemma4 weights       → ~/.ollama/models/ (not iCloud)      ║
║  Bridge config        → gemma4_google/mcp-config.json       ║
║  Docker MCP config    → ~/.docker/mcp/config.yaml           ║
║  Cursor MCP config    → ~/.cursor/mcp.json                  ║
╠══════════════════════════════════════════════════════════════╣
║  Internet required?   → NO (after one-time model download)  ║
║  Data sent to cloud?  → NONE                                ║
║  Cost per query?      → $0                                  ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Quick Reference — Start Everything

```bash
# 1. Ollama (auto-starts at login — verify it's running)
ollama list

# 2. Stack A: Cursor + Docker MCP (tools available automatically in Cursor)
# — Nothing to start. Docker MCP Gateway starts when Cursor opens a chat.
# — Select gemma4:26b as the model in Cursor's model picker.

# 3. Stack B: ollama-mcp-bridge (for scripts / non-Cursor clients)
cd "/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation/gemma4_google"
./start-ollama-mcp-bridge.sh        # foreground
./start-ollama-mcp-bridge.sh --bg   # background

# Stop bridge
kill $(lsof -ti:8000)
```

---

*BlackBranch Research & Innovation — M4 Max 128 GB*  
*Created: April 2026*
