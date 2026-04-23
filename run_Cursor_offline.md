# Run Cursor IDE in Offline / Private Mode with Gemma4

**Machine:** MacBook Pro M4 Max · 128 GB Unified Memory  
**Privacy:** AI inference stays 100% local — your code never leaves the machine  
**Date:** April 2026

---

## The Short Answer

Cursor is a desktop app — it can call Ollama directly over localhost.
You configure it once, then just pick `gemma4:26b` from the model selector.
That's it. No bridge needed. No Docker. No browser.

```
YOU TYPE IN CURSOR
       │
       │  HTTP to localhost:11434/v1/chat/completions
       │  (stays on your Mac — no internet)
       ▼
  Ollama (localhost:11434)
       │
       ▼
  gemma4:26b on M4 Max GPU
       │
       ▼
  Response streamed back to Cursor
```

---

## Critical Limitation — Cursor Routes Through Its Cloud

**Cursor routes ALL model requests through its own cloud backend — including
custom local models.** This is not obvious and is not documented clearly.

When you set `http://localhost:11434/v1` as the Base URL, Cursor's cloud
servers try to reach that address. From their servers, `localhost` is a
private IP and is blocked by SSRF (Server-Side Request Forgery) protection.

**The error you will see:**
```
"ssrf_blocked" — connection to private IP is blocked
Request failed with status code 400
```

**What this means in practice:**

| Feature | Private/Local? |
|---------|---------------|
| Cursor app itself | No — phones home for license, sync, telemetry |
| AI chat (Claude/Sonnet) | No — prompts go to Anthropic servers |
| gemma4:26b via Ollama | ❌ Blocked — Cursor can't reach localhost |
| Cursor Agent mode | ❌ Always routes through Cursor cloud |

**Cursor cannot use Ollama on localhost in Agent mode.**
This is a fundamental architectural limitation, not a configuration problem.

## What Actually Works for Private AI

For 100% private, local AI inference — use **Open WebUI** with the bridge:

```
CURSOR  →  Claude/Sonnet 4.6 (best for coding, agent tasks)
           Code goes to Anthropic — enable Privacy Mode below

OPEN WEBUI  →  gemma4:26b (best for patent work, sensitive research)
               100% local, MCP tools, nothing leaves your Mac
```

## Enable Cursor Privacy Mode (Reduces Cloud Data)

Even when using Claude in Cursor, enable Privacy Mode to prevent your code
from being used for training:

```
Cursor Settings (Cmd+,)  →  General  →  Privacy Mode  →  ON
```

With Privacy Mode ON, Anthropic cannot use your prompts/code for model training.

---

## One-Time Setup — Add Gemma4 to Cursor

### Step 1 — Open Cursor Settings
```
Cmd + ,  (comma)  →  Models tab
```

### Step 2 — Add the Model Name

Click **+ Add Model** and type exactly:
```
gemma4:26b
```
Press Enter. It appears in the model list.

### Step 3 — Enable the OpenAI-Compatible Endpoint

Scroll down to the **OpenAI API Key** section. Toggle it **ON**.  
Two fields appear — fill them in:

```
OpenAI API Key:   ollama
Override Base URL: http://localhost:11434/v1
```

> `ollama` in the key field is intentional — Ollama doesn't need a real key.
> Any non-empty text works. `ollama` is just a clear label.

### Step 4 — Confirm It's Active

There is no Verify button in current versions of Cursor. The model list
shows a **green toggle** next to `gemma4:26b` when it's enabled. That's all
you need — green toggle = ready to use.

If the toggle is grey, click it to enable it.

### Verify via Terminal (fastest, always works)

```bash
# Test Ollama is running
curl -s http://localhost:11434/api/tags | python3 -m json.tool | grep "gemma4"
# Should show: "gemma4:26b"

# Test the OpenAI-compatible endpoint (what Cursor actually uses)
curl -s http://localhost:11434/v1/models | python3 -m json.tool | grep "gemma4"
# Should show: "gemma4:26b"
```

If both return `gemma4:26b` — Cursor can reach it. The connection works.

### Step 5 — Test It in Cursor Chat

```
Cmd + L  →  click model name at bottom  →  select gemma4:26b
```

Type: `Say hello` — if Gemma responds, everything is working.

### Step 6 — Done

This is a one-time setup. Cursor remembers it permanently.
Re-enable your other models in the model list if you want them back.

---

## Daily Use — Switching Between Private and Cloud Mode

Every time you open a chat in Cursor you can pick the model.
No settings to change — just click the model name.

```
Cmd + L  →  click model name at bottom  →  choose:

  gemma4:26b    ← OFFLINE / PRIVATE
                   • Your code stays on your Mac
                   • Works without internet
                   • Great for patent work, sensitive code, proprietary IP
                   • Free forever

  claude-sonnet-4-5   ← ONLINE / POWERFUL
                   • Your prompts go to Anthropic servers
                   • Best for complex multi-step tasks
                   • Requires internet + Cursor subscription
                   • Better at agent/multi-file tasks
```

You can switch **mid-session** — each new conversation can use a different model.

---

## Cursor + MCP Tools (Advanced — Same as Open WebUI)

Cursor already has Docker MCP Toolkit connected (set up earlier today).
When using `gemma4:26b` in Cursor, it has access to the same MCP tools:
- `filesystem` — read/write files in your allowed paths
- `playwright` — browser automation
- `git` — git operations
- `SQLite` — local database queries

This works automatically. No extra setup needed.

```
Cursor chat (gemma4:26b)
    ├── AI inference  →  Ollama localhost:11434
    └── MCP tools     →  Docker MCP Gateway
                          • filesystem (14 tools)
                          • playwright (21 tools)
                          • git
                          • SQLite
```

> **Difference from Open WebUI:** In Cursor, MCP tools are always available
> when using gemma4:26b — no bridge to start, no port to change. Docker MCP
> is permanently connected to Cursor via `~/.cursor/mcp.json`.

---

## Offline Mode vs Open WebUI — When to Use Which

| | Cursor (offline) | Open WebUI (browser) |
|---|---|---|
| **Best for** | Writing and editing code | Research, documents, chat |
| **File access** | MCP tools + Cursor sidebar | MCP bridge (port 8000) |
| **Model** | gemma4:26b via Ollama | gemma4:26b via Ollama |
| **MCP setup** | Always on (Docker MCP) | Start bridge manually |
| **Patent drafting** | Good for claim text editing | Good for reading + research |
| **Works offline** | AI yes, app needs occasional internet | Yes (once Docker/Ollama running) |

---

## Verify Everything Is Working

```bash
# 1. Ollama running?
ollama list
# Should show gemma4:26b

# 2. Gemma4 responding?
curl -s http://localhost:11434/api/generate \
  -d '{"model":"gemma4:26b","prompt":"Say hello in one word","stream":false}' \
  | python3 -c "import json,sys; print(json.load(sys.stdin)['response'])"

# 3. MCP tools connected to Cursor?
docker mcp server ls
# Should show 4 servers: playwright, filesystem, git, SQLite
```

---

## Quick Reference

```
╔═══════════════════════════════════════════════════════════╗
║            CURSOR OFFLINE MODE — QUICK REFERENCE          ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  One-time setup:                                          ║
║  Cmd+, → Models → OpenAI section → enable                ║
║  Base URL:   http://localhost:11434/v1                    ║
║  API Key:    ollama                                       ║
║  Model:      gemma4:26b                                   ║
║                                                           ║
║  Daily use:                                               ║
║  Cmd+L → click model name → select gemma4:26b            ║
║                                                           ║
║  OFFLINE (private):  gemma4:26b  → localhost only        ║
║  ONLINE (powerful):  claude-sonnet → Anthropic servers   ║
║                                                           ║
║  MCP tools: always available in Cursor (no bridge needed) ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
```

---

## All Files in This Project

```
gemma4_google/
├── run_Cursor_offline.md        ← This file — Cursor offline setup
├── run_MCP_webUI.md             ← Open WebUI + MCP setup
├── MCP_OFFLINE_SETUP.md         ← Full MCP stack reference
├── ARCHITECTURE_AND_GUIDE.md    ← Full system architecture
├── mcp-config.json              ← Bridge MCP server config
├── start-ollama-mcp-bridge.sh   ← Bridge startup script
└── NOTE_get_back_to_patent.md   ← Personal reminder note
```

---

*BlackBranch Research & Innovation — M4 Max 128 GB*  
*Created: April 2026*
