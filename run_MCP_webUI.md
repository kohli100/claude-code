# Run Open WebUI with or without MCP Tools

**Machine:** MacBook Pro M4 Max · 128 GB Unified Memory  
**Privacy:** 100% local — zero data leaves the machine  
**Date:** April 2026
**Open WebUI version:** v0.9.1 (released April 21, 2026) — see update instructions below

---

## UPDATE TO v0.9.1 — DO THIS FIRST

v0.9.1 fixes two startup crash bugs (missing `aiosqlite` and `asyncpg` dependencies).
v0.9.0 adds major features including a native Desktop App, Calendar, and scheduled tasks.

### CRITICAL — Back up your data before upgrading (v0.9.0 changes database schema):

```bash
# Step 1 — Back up your Open WebUI data volume BEFORE updating
docker run --rm \
  -v open-webui:/data \
  -v ~/Desktop:/backup \
  alpine tar czf /backup/open-webui-backup-apr2026.tar.gz /data
# Backup saved to ~/Desktop/open-webui-backup-apr2026.tar.gz

# Step 2 — Pull the latest image
docker pull ghcr.io/open-webui/open-webui:main

# Step 3 — Stop and restart the container
docker stop open-webui
docker rm open-webui

# Step 4 — Start with the new image (same command as before)
docker run -d \
  --name open-webui \
  --restart always \
  -p 3000:8080 \
  -v open-webui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main

# Step 5 — Open browser and verify
open http://localhost:3000
```

### NEW in v0.9.1 (April 21, 2026):
- Fixed startup crash: missing `aiosqlite` dependency (pip/uv installs)
- Fixed startup crash: missing `asyncpg` dependency (PostgreSQL users)

### NEW in v0.9.0 (April 21, 2026) — features useful for your workflow:

| Feature | What It Means for You |
|---------|----------------------|
| Native Desktop App (Mac) | Run Open WebUI without Docker — simpler startup |
| Calendar workspace | Add patent deadlines directly in Open WebUI |
| Scheduled automations | Auto-run daily patent status checks |
| Previously uploaded files tab | Reuse patent PDFs without re-uploading |
| Ollama Responses API | Better tool calling support with Gemma4 |
| Admin: delete models from UI | Remove models without terminal commands |

### ALTERNATIVE — Native Desktop App (no Docker needed):
Download from: https://github.com/open-webui/open-webui/releases/tag/v0.9.0
- No Docker, no terminal, no setup
- Connects to your existing Ollama at localhost:11434
- System-wide chat bar: Shift+Cmd+I
- Automatic updates
- Zero telemetry

---

## The Short Answer

> **Yes — you always open Open WebUI at `http://localhost:3000` regardless of mode.**  
> The only thing that changes is which URL Open WebUI uses *internally* to reach Ollama.  
> Your browser address bar always stays on port **3000**.

```
YOU (browser)
     │
     │  always http://localhost:3000
     ▼
┌─────────────────┐
│   Open WebUI    │   ← your chat interface, always port 3000
└────────┬────────┘
         │
         │  this internal URL is what you switch:
         │
    ┌────┴──────────────────────────────────────┐
    │                                           │
    ▼ MODE A (MCP tools ON)                     ▼ MODE B (plain chat)
host.docker.internal:8000              host.docker.internal:11434
         │                                      │
         ▼                                      ▼
  ollama-mcp-bridge                         Ollama
  (adds filesystem,                      (direct, no tools)
   14 MCP tools)
         │
         ▼
      Ollama :11434
      gemma4:26b
```

---

## The Two Modes — At a Glance

```
┌─────────────────────────────────────────────────────────┐
│  MODE A — WITH MCP Tools (files, browser, database)     │
│                                                         │
│  Open WebUI  →  bridge :8000  →  Ollama :11434          │
│                     └──► MCP tools (filesystem etc.)    │
│                                                         │
│  Open WebUI Ollama API URL:                             │
│  http://host.docker.internal:8000                       │
├─────────────────────────────────────────────────────────┤
│  MODE B — WITHOUT MCP Tools (plain chat, faster)        │
│                                                         │
│  Open WebUI  →  Ollama :11434  (direct)                 │
│                                                         │
│  Open WebUI Ollama API URL:                             │
│  http://host.docker.internal:11434                      │
└─────────────────────────────────────────────────────────┘
```

**Memory trick — just one rule:**
> **Using MCP tools? → set :8000 internally**  
> **Plain chat? → set :11434 internally**  
> **Your browser? → always localhost:3000**

---

## MODE A — WITH MCP Tools

### Step 1 — Start the bridge

Open Terminal and run:

```bash
cd "/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation/gemma4_google"
./start-ollama-mcp-bridge.sh --bg
```

Verify it started:

```bash
curl http://localhost:8000/health
# Good response: {"status":"healthy","ollama_status":"running","tools":14}
```

### Step 2 — Set Open WebUI to port 8000

1. Go to **http://localhost:3000**
2. Profile icon (bottom-left) → **Admin Panel**
3. **Settings → Connections**
4. Under **Ollama API**, set the URL to:
   ```
   http://host.docker.internal:8000
   ```
5. Click the **↻ refresh icon** on that line → wait for green checkmark
6. Click **Save**

### Step 3 — Chat normally

Select `gemma4:26b` as the model. Gemma4 will automatically call MCP tools
(like reading files, listing directories) when your prompt involves them.

---

## MODE B — WITHOUT MCP Tools (plain chat)

### Step 1 — No bridge needed

Nothing to start. Skip straight to Step 2.

### Step 2 — Set Open WebUI back to port 11434

1. Go to **http://localhost:3000**
2. Profile icon (bottom-left) → **Admin Panel**
3. **Settings → Connections**
4. Under **Ollama API**, set the URL to:
   ```
   http://host.docker.internal:11434
   ```
5. Click the **↻ refresh icon** → green checkmark
6. Click **Save**

### Step 3 — Optionally stop the bridge

```bash
kill $(lsof -ti:8000)
```

(Safe to skip — the bridge does nothing if nobody talks to it.)

---

## Quick Switch Cheat Sheet

Print this or keep it pinned:

```
╔══════════════════════════════════════════════════════════════╗
║                  OPEN WEBUI QUICK SWITCH                     ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  WITH MCP tools (files, browser, database):                  ║
║  1. Run:  ./start-ollama-mcp-bridge.sh --bg                  ║
║  2. Set:  http://host.docker.internal:8000                   ║
║                                                              ║
║  WITHOUT MCP tools (plain chat):                             ║
║  1. Nothing to start                                         ║
║  2. Set:  http://host.docker.internal:11434                  ║
║                                                              ║
║  Where to set it:                                            ║
║  localhost:3000 → Admin Panel → Settings → Connections       ║
║  → Ollama API → change URL → refresh icon → Save             ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Drag & Drop vs MCP — What Changed and What Didn't

**Drag and drop still works exactly the same.** MCP does not replace it.
They serve completely different purposes.

| | Drag & Drop (always worked) | MCP Filesystem (new) |
|---|---|---|
| **Who finds the file** | You — manually every time | Gemma — automatically |
| **How many files** | One at a time | Entire folders at once |
| **Direction** | Read only | Read + Write + Edit + Search |
| **You need to know the path** | Yes | No — Gemma can search |
| **Gemma can create files** | No | Yes |
| **Gemma can edit files** | No | Yes |
| **Works across many files** | No | Yes |

### When to still use Drag & Drop
- Sharing a single PDF, image, or document quickly
- One-off questions about a specific file you have open
- Files outside the MCP allowed paths

### When MCP is better
- You want Gemma to find files itself without you locating them
- Working across multiple files or an entire folder
- You want Gemma to write or edit files (not just read)
- Asking questions like "find everything in my project about X"

### Real examples of what MCP enables that drag & drop cannot

```
"Read all .md files in my gemma4_google folder and summarize them"
→ Gemma finds and reads all files automatically. You drag nothing.

"Search my Documents for any file mentioning 'Kafka architecture'"
→ Gemma searches across hundreds of files in seconds.

"Write a summary of our conversation to a new file called notes.md"
→ Gemma creates the file on your Mac. Drag & drop is read-only.

"Edit ARCHITECTURE_AND_GUIDE.md — add a section at the bottom"
→ Gemma opens, edits, and saves the file directly.

"List everything in my BlackBranch_Research_Innovation folder"
→ Gemma navigates your filesystem like a file manager.
```

### Pointing Gemma to Your Files (MCP mode)

Just tell Gemma the path in plain language — no dragging needed:

```
"Read the file at ~/Documents/notes.txt"
"List all files in ~/Desktop"
"Search ~/Documents for files containing 'budget'"
"Show me the folder structure of my BlackBranch project"
```

Or use the full path:
```
"Read /Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/
 BlackBranch_Research_Innovation/gemma4_google/ARCHITECTURE_AND_GUIDE.md"
```

Gemma will call the filesystem tool automatically and return the contents.

---

## What the MCP Tools Can Do (Port 8000 Mode)

| Tool | What It Does |
|------|-------------|
| `list_directory` | List files in a folder |
| `read_file` | Read contents of any file |
| `write_file` | Create or overwrite a file |
| `edit_file` | Make targeted edits to a file |
| `search_files` | Search for files by name pattern |
| `directory_tree` | Recursive folder structure view |
| `get_file_info` | File size, dates, permissions |
| `read_multiple_files` | Read several files at once |
| `move_file` | Move or rename a file |
| `create_directory` | Create a new folder |

Allowed paths (configured in `mcp-config.json`):
- `~/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation`
- `~/Documents`
- `~/Desktop`

---

## Troubleshooting

**"Trouble accessing Ollama" error after switching to port 8000**  
→ Bridge is not running. Go back to Step 1 of Mode A and start it first.

**Switched to port 8000 but tools are not being called**  
→ Try asking explicitly: *"Use the filesystem tool to list files in ~/Documents"*  
→ Gemma4 supports tool calling but sometimes needs a clear prompt.

**Want to check which mode you're currently in**  
```bash
lsof -ti:8000 > /dev/null && echo "MODE A — MCP tools active (port 8000)" || echo "MODE B — plain chat (port 11434)"
```

**See bridge logs**
```bash
tail -f "/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation/gemma4_google/bridge.log"
```

---

## All Ports on This Machine

| Port | What | You Visit It? | Always Running? |
|------|------|--------------|----------------|
| `3000` | Open WebUI | **Yes — this is your chat UI** | Yes — starts with Docker |
| `11434` | Ollama | No — internal only | Yes — starts at login |
| `8000` | ollama-mcp-bridge | No — internal only | No — start manually |

You only ever type `localhost:3000` in your browser.  
Ports `11434` and `8000` are backend services — Open WebUI talks to them, you don't.

---

---

## Why There Is No "Open Folder" Button — And Why That's Fine

Open WebUI is a browser app. Browsers are sandboxed by design — they cannot
open folders or access your filesystem directly. This is a hard browser
security limit, not a missing feature.

**Drag and drop in the browser works like this:**
```
You drag file → browser uploads it → stored in temporary memory
                                      ↑
                              size limited (~10–50 MB typical)
                              gone when session ends
                              one file at a time
                              read only
```

**This is exactly the ceiling you identified.** Large files, whole folders,
and writing back to disk are all impossible through the browser upload path.

### MCP Bypasses the Browser Entirely

With MCP active (port 8000), Gemma does not use the browser upload system
at all. It calls a filesystem tool that reads directly from your Mac's disk.

```
You type the path in chat
         │
         ▼
Gemma calls filesystem MCP tool
         │
         ▼
Tool reads directly from your Mac's disk  ← no browser, no upload, no temp memory
         │
         ▼
Result returned to Gemma in the chat
```

| | Drag & Drop (browser) | MCP Filesystem |
|---|---|---|
| **Interface** | Drag file into browser window | Type path in message |
| **Storage** | Temp memory (lost after session) | Your actual disk (permanent) |
| **Size limit** | Yes (~10–50 MB) | No — reads any size file |
| **Folders** | No | Yes — entire folder trees |
| **Multiple files** | One at a time | Dozens at once |
| **Write back to disk** | No | Yes |
| **Files persist** | No — re-upload every session | Yes — always there |

### The "Folder Button" Is Your Message Prompt

There is no GUI folder picker. The way you "open" a folder with MCP is to
describe it in your message. That IS the interface.

```
Instead of:  clicking a folder button
You type:    "Read everything in ~/Documents/patents and summarize it"

Instead of:  dragging 10 files one by one
You type:    "Read all .pdf files in ~/Desktop/research"

Instead of:  hitting a 50 MB upload limit on a large file
You type:    "Read the file at ~/Documents/large-report.pdf"
             (Gemma reads it directly from disk — no size limit)
```

### Compared to Cursor

In Cursor (desktop app), you open a folder in the sidebar and Claude sees
the whole project automatically — because Cursor has direct OS-level filesystem
access, not browser sandboxing.

Open WebUI in the browser cannot do that sidebar trick. MCP is the equivalent
capability — just invoked through your chat message instead of a GUI sidebar.
Same power, different trigger.

---

## User Guide — Plain English, No Tech Jargon

### You Already Know How to Use This

If you've used Cursor with Claude/Sonnet where you open a folder and Claude can
read, write, search, and edit your files directly — **this is the exact same
capability**, just available in Open WebUI with Gemma4 running 100% privately
on your Mac.

```
Cursor + Claude (online)       Open WebUI + Gemma4 (offline)
────────────────────────       ─────────────────────────────
Open folder in Cursor    =     Tell Gemma the folder path
Claude reads your files  =     Gemma uses filesystem MCP tool
Claude edits files       =     Gemma writes/edits via MCP
Data goes to Anthropic   ✗     Data stays on your Mac ✓
Requires internet        ✗     Works offline ✓
Costs subscription       ✗     Costs $0 ✓
```

The difference: in Cursor you open a folder in the sidebar and Claude sees it
automatically. In Open WebUI you tell Gemma the path in your message. Same
result — Gemma reads, writes, and navigates your files.

### Everyday Usage — What to Say

**To read a file:**
> "Read the file ~/Documents/my-notes.txt and summarize it"

**To list a folder:**
> "List everything in my BlackBranch Research folder"

**To search across files:**
> "Search ~/Documents for anything mentioning 'patent claims'"

**To create a file:**
> "Save this conversation summary as ~/Desktop/summary.md"

**To edit a file:**
> "Open ~/Documents/draft.md and add a conclusion section"

**To work on a whole project:**
> "Read all the .md files in my gemma4_google folder and tell me
>  what's covered and what's missing"

### One Rule to Remember

> **Just tell Gemma what you want and where to find it.**  
> It handles the rest — no dragging, no copy-pasting, no switching apps.

### You Don't Need to Remember Ports

- Open your browser → go to **localhost:3000** (always)
- If you want MCP file tools → run `./start-ollama-mcp-bridge.sh --bg` first
- If you just want to chat → go straight to localhost:3000, nothing else needed

---

## Daily Usage — Copy-Paste Prompts

Use these as starting points. The patent workspace example below is real —
this exact exchange happened on Apr 12, 2026.

---

### Real Example — Patent Workspace

**You typed:**
> *"List my patent workspace and tell me what's there"*

**Gemma called `filesystem.list_directory` automatically and responded:**

```
Your patent workspace contains the following file:

• patent1_claim_extraction.txt

The contents of your patent workspace (patent1_workplace) are:
• claims        (Directory)
• figures       (Directory)
• specifications (Directory)

It looks like your workspace is organized by the standard components
of a patent application! Would you like me to explore any of these
folders for you?
```

**Gemma then suggested follow-up questions on its own:**
- Can you show me the contents of the 'claims' directory?
- What is inside the 'patent1_claim_extraction.txt' file?
- Can you summarize the claims found in the 'claims' folder?
- Are there any figures available in the 'figures' directory?

**One sentence. No dragging. No path typing. No uploads.**  
Gemma navigated the filesystem, recognized the patent structure,
and offered intelligent next steps — all privately on your Mac.

---

### More Copy-Paste Prompts

**Open your patent workspace:**
```
List my patent workspace and tell me what's there
```

**Read a specific patent file:**
```
Read patent1_claim_extraction.txt and tell me where I left off
```

**Dig into a subfolder:**
```
Show me the contents of the claims directory
```

**Search across your patent files:**
```
Search my patent workspace for anything mentioning "independent claim"
```

**Continue drafting:**
```
Read the specifications folder and help me write the background section
```

**Save work back to disk:**
```
Save this updated claim as a new file called claim2_draft.txt in my claims folder
```

**Read a single file anywhere on your Mac:**
```
Read the file at /Users/sukeshkohli/Documents/[filename] and summarize it
```

**List any folder:**
```
List all files in /Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation
```

**Search across Documents:**
```
Search /Users/sukeshkohli/Documents for any file mentioning "prior art"
```

**Save a session note:**
```
Save a summary of this conversation to ~/Desktop/session-notes.md
```

---

## The Practical "Folder Button" — Use the System Prompt

You don't need a folder button if Gemma already knows your folders. The
**System Prompt** field (visible in the Controls panel on the right side of
Open WebUI) lets you pre-load this information once per session.

### How to Set It

In Open WebUI, click the **Controls** icon (top-right of chat window)
→ expand **System Prompt** → clear the field → paste the block below.

**Just having a path in the field is not enough.** Gemma needs instructions
telling it what to do with the path. Use this format:

```
You have access to my local filesystem via MCP tools.

My patent workspace is at:
/Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/USPTO_Filing_Revised/gemma_workplace/patent1_workplace

My other important folders:
- Research & Innovation: /Users/sukeshkohli/Desktop/Desktop - BeaconBluff M4MaxPro/BlackBranch_Research_Innovation
- Documents:             /Users/sukeshkohli/Documents
- Desktop:               /Users/sukeshkohli/Desktop

When I ask you to read, find, search, or work with files, use the filesystem
tool to access these locations directly. When I say "my patent folder" or
"my workspace", use the patent path above.

Always confirm which files you read and list what you found.
```

Click outside the field to save. Now you can just say:
> *"List my patent workspace and tell me what's there"*
> *"Open my patent folder and help me continue where I left off"*
> *"Search my workspace for anything about claim 3"*

...and Gemma knows exactly where to look — no path typing needed.

---

## Adding a Real Folder Button to Open WebUI — How Hard?

**Short answer: medium effort, but it won't solve the problem you described.**

### Option 1 — HTML Folder Upload Button (Easy, but still hits memory limit)

Browsers actually support folder selection via:
```html
<input type="file" webkitdirectory multiple>
```
Adding this button to Open WebUI's source code is ~1 day of work for a
developer. **However** — it still uploads files into temporary browser memory.
You still hit the same size ceiling. Large folders would crash or fail.
This solves the UX annoyance but not the underlying memory limit.

### Option 2 — Path Input Button (Medium, actually solves it)

A smarter button: a small text field where you type or paste a folder path,
and it inserts *"Read the files in [path]:"* into your chat automatically.
This triggers MCP (reads from disk, no upload, no memory limit).
This is ~2–3 days of work, requires forking Open WebUI's source, and needs
to be maintained when Open WebUI updates.

### Option 3 — System Prompt (Already Available, Zero Effort)

Use the System Prompt field described above. Pre-load your folder paths once.
This is available right now, no code changes needed, and effectively gives
Gemma permanent awareness of your folder structure.

### Recommendation

**Use Option 3 (System Prompt) now.** It solves the daily friction immediately
with no coding. If you find yourself wanting the UI button badly enough later,
Option 2 is the right build — but the System Prompt covers 95% of the need.

---

*BlackBranch Research & Innovation — M4 Max 128 GB*  
*Updated: April 2026*
