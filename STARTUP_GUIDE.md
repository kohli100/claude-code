# Daily Startup Guide — Two Modes of Operation

**Machine:** MacBook Pro M4 Max · 128 GB Unified Memory · 40-core GPU  
**Date:** April 2026
**Open WebUI:** v0.9.1 (latest) — update instructions in run_MCP_webUI.md

> UPDATE AVAILABLE: Open WebUI v0.9.1 released April 21, 2026.
> Key addition in v0.9.0: Native Mac Desktop App — no Docker required for WebUI.
> See run_MCP_webUI.md for update command and backup steps before upgrading.

---

## The Two Modes at a Glance

```
╔══════════════════════════════════════════════════════════════════════╗
║   MODE 1 — OFFLINE / PRIVATE                                        ║
║   Docker → Ollama → Gemma4:26b → MCP Server → Open WebUI           ║
║   Privacy: 100% local. Zero data leaves your Mac.                   ║
║   Best for: Patent work, sensitive IP, proprietary research         ║
╠══════════════════════════════════════════════════════════════════════╣
║   MODE 2 — ONLINE / POWERFUL                                        ║
║   Cursor IDE → Claude Sonnet 4.6 (Anthropic cloud)                 ║
║   Privacy: Prompts travel to Anthropic servers                      ║
║   Best for: Complex coding, agent tasks, multi-file editing         ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

# MODE 1 — OFFLINE STACK

## What Runs and How It Starts

```
┌─────────────────────────────────────────────────────────────────────┐
│  STARTUP ORDER                                                       │
│                                                                      │
│  1. Ollama.app ──────── auto-starts at Mac login (menu bar icon)   │
│          │                                                           │
│          │  serves gemma4:26b at localhost:11434                    │
│          ▼                                                           │
│  2. Docker Desktop ──── auto-starts at Mac login                   │
│          │                                                           │
│          │  auto-starts open-webui container (restart: always)      │
│          ▼                                                           │
│  3. Open WebUI ─────── auto-starts in Docker, port 3000            │
│          │                                                           │
│          │  you open localhost:3000 in browser                      │
│          ▼                                                           │
│  4. MCP Bridge ──────── YOU start this manually when needed        │
│          │                                                           │
│          │  adds filesystem tools to Ollama API                     │
│          └─► localhost:8000                                          │
└─────────────────────────────────────────────────────────────────────┘
```

## What Auto-Starts (Nothing to Do)

These start automatically when your Mac boots:

| Service | How | Port | Status |
|---------|-----|------|--------|
| **Ollama.app** | macOS Login Item | `11434` | Auto |
| **Docker Desktop** | macOS Login Item | — | Auto |
| **open-webui container** | Docker restart policy: `always` | `3000` | Auto |

After login, Open WebUI is ready at `http://localhost:3000` with no action needed.

## What You Start Manually (MCP Bridge)

Only needed when you want Gemma4 to read/write your files:

```bash
cd "/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation/gemma4_google"

# Start bridge (background — keeps terminal free)
./start-ollama-mcp-bridge.sh --bg

# Verify it's running
curl http://localhost:8000/health
# → {"status":"healthy","ollama_status":"running","tools":14}
```

## Full Daily Startup Checklist

### Step 1 — Verify auto-started services
```bash
# All three should respond:
ollama list                          # Ollama running? Shows gemma4:26b
curl -s http://localhost:3000        # Open WebUI running?
docker ps --format "{{.Names}}: {{.Status}}" | grep open-webui
```

Expected output:
```
NAME                ID              SIZE
gemma4:26b          5571076f3d70    17 GB   ← Ollama ready
open-webui: Up X hours (healthy)            ← WebUI ready
```

### Step 2 — Open WebUI in browser
```
http://localhost:3000
```
Select model: **gemma4:26b**

### Step 3 — (Optional) Start MCP bridge for file access
```bash
./start-ollama-mcp-bridge.sh --bg
```

Then in Open WebUI Admin Panel → Settings → Connections → Ollama API:
```
WITH MCP tools:    http://host.docker.internal:8000
WITHOUT MCP tools: http://host.docker.internal:11434
```

### Step 4 — Set System Prompt for patent work (persists across sessions)
```
Open WebUI → Profile icon → Settings → General → System Prompt
```
Paste:
```
You have access to my local filesystem via MCP tools.

My patent workspace is at:
/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/USPTO_Filing_Revised/gemma_workplace/patent1_workplace

My other folders:
- Research: /Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation
- Documents: /Users/sukeshkohli/Documents
- Desktop: /Users/sukeshkohli/Desktop

When I ask you to read, find, search, or work with files, use the filesystem
tool to access these locations directly.
```

### Step 5 — You're live in Offline Mode

Ask Gemma4 anything privately. Example to verify MCP works:
```
List my patent workspace and tell me what's there
```
Gemma4 will call `filesystem.list_directory` and show your files — no upload needed.

---

## Offline Stack — Confirmed Working (Apr 12, 2026)

```
✓ Ollama 0.20.5           — gemma4:26b (17 GB) loaded
✓ Docker Desktop 29.3.1   — open-webui healthy on port 3000
✓ Docker MCP Toolkit 0.40.3 — 4 servers: filesystem, git, playwright, SQLite
✓ ollama-mcp-bridge 0.11.2 — 14 filesystem tools on port 8000
✓ Open WebUI              — connected to bridge, model: gemma4:26b
✓ Cursor MCP              — connected via ~/.cursor/mcp.json
```

Verified by real session: Gemma4 successfully called `filesystem.list_directory`
and read patent workspace (`claims/`, `figures/`, `specifications/`) with one prompt.

---

## Stop Everything (when done)

```bash
# Stop MCP bridge
kill $(lsof -ti:8000)

# Stop Open WebUI (optional — auto-restarts on reboot anyway)
docker stop open-webui

# Stop Ollama (optional — frees 17 GB GPU memory)
ollama stop gemma4:26b
# Or quit Ollama.app from menu bar
```

---

# MODE 2 — ONLINE STACK (Claude / Sonnet 4.6)

## What It Is

```
┌─────────────────────────────────────────────────────────────────────┐
│  Cursor IDE (desktop app)                                            │
│         │                                                            │
│         │  HTTPS — encrypted, but leaves your Mac                   │
│         ▼                                                            │
│  Cursor cloud backend                                                │
│         │                                                            │
│         ▼                                                            │
│  Anthropic servers (Claude Sonnet 4.6)                              │
│         │                                                            │
│         ▼                                                            │
│  Response back to Cursor                                             │
└─────────────────────────────────────────────────────────────────────┘
```

## Startup — Nothing to Do

Cursor opens and Claude is available immediately. No local services needed.
No bridge. No Docker. No Ollama.

```
Open Cursor  →  Cmd+L  →  Claude Sonnet 4.6 (default)  →  Chat
```

## What Claude Can Do That Gemma4 Can't

| Capability | Claude (online) | Gemma4 (offline) |
|-----------|----------------|-----------------|
| Agent mode (multi-step) | ✅ Full | ⚠️ Limited |
| Multi-file editing | ✅ Yes | ⚠️ Limited |
| @codebase search | ✅ Yes | ❌ No |
| Web search / current info | ✅ Yes | ❌ No |
| Complex reasoning chains | ✅ Excellent | ✅ Good |
| Privacy | ❌ Prompts to Anthropic | ✅ 100% local |
| Cost | Cursor subscription | $0 |
| Works offline | ❌ No | ✅ Yes |

## Enable Privacy Mode in Cursor (Reduces Cloud Exposure)

Even in online mode, enable this to prevent your code from being used for training:

```
Cmd+,  →  General  →  Privacy Mode  →  ON
```

## Important Limitation — Cannot Use Ollama in Cursor Agent Mode

Cursor routes ALL model requests through its cloud backend.
When `http://localhost:11434` is set as the custom model URL,
Cursor's servers try to reach it from the cloud — and block it
as a private IP (SSRF protection).

**Error you'll see:** `"ssrf_blocked" — connection to private IP is blocked`

**This is not fixable without a tunnel (ngrok etc.) which compromises privacy.**

Use Open WebUI for local Gemma4. Use Cursor for Claude.

---

# Side-by-Side Summary

```
╔═══════════════════════════════════════════════════════════════════════╗
║                     WHICH MODE FOR WHAT                               ║
╠══════════════════════════╦════════════════════════════════════════════╣
║  USE OFFLINE (Gemma4)    ║  USE ONLINE (Claude in Cursor)             ║
╠══════════════════════════╬════════════════════════════════════════════╣
║  Patent claims & drafts  ║  Complex multi-file code refactoring       ║
║  Proprietary research    ║  Agent tasks (run tests, edit many files)  ║
║  Client confidential IP  ║  Open source projects                      ║
║  Pre-filing patent work  ║  Architecture planning                     ║
║  Financial/legal data    ║  Learning & exploration                    ║
║  Anything under NDA      ║  Code review of non-sensitive code         ║
║  Offline / no internet   ║  Complex reasoning needing web search      ║
╚══════════════════════════╩════════════════════════════════════════════╝
```

---

# Port Reference

| Port | Service | Auto-Start | You Open It? |
|------|---------|-----------|-------------|
| `3000` | Open WebUI (Docker) | Yes | **Yes — your browser** |
| `11434` | Ollama | Yes | No — internal |
| `8000` | MCP Bridge | **No — start manually** | No — internal |

---

# All Project Files

```
gemma4_google/
├── STARTUP_GUIDE.md             ← This file — daily startup reference
├── run_MCP_webUI.md             ← Open WebUI + MCP detailed guide
├── run_Cursor_offline.md        ← Cursor offline attempt + limitations
├── MCP_OFFLINE_SETUP.md         ← Full MCP stack technical reference
├── ARCHITECTURE_AND_GUIDE.md    ← Complete system architecture
├── mcp-config.json              ← MCP bridge server config
├── start-ollama-mcp-bridge.sh   ← Bridge startup script
└── NOTE_get_back_to_patent.md   ← Personal reminder
```

---

*BlackBranch Research & Innovation — M4 Max 128 GB*
*Documented: April 12, 2026*
