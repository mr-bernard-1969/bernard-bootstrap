# Skills Manifest — What to Install and When

## Phase 1: Essential (Install Immediately)

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **weather** | Weather forecasts | No |
| **github** | GitHub operations via `gh` CLI | No (needs `gh auth login`) |
| **gemini** | Fast Q&A and generation | Yes (free tier available) |

```bash
clawhub install weather github gemini
```

## Phase 2: Communication (Install When Setting Up Channels)

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **himalaya** | Email via IMAP/SMTP | No (needs mail account config) |
| **gog** | Google Workspace (Gmail, Calendar, Drive) | Yes (OAuth setup) |
| **telegram-groups** | Manage Telegram group presence | No (needs bot token) |

**Himalaya tips:** Account flag is `-a <name>`, folder flag is `-f <folder>`. For sending, pipe raw EML via stdin (CLI compose args may crash).

## Phase 3: Media & Creative (Install When Needed)

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **nano-banana-pro** | Image generation (Gemini 3 Pro, ~$0.13/image) | Yes |
| **openai-whisper-api** | Audio transcription | Yes |
| **video-frames** | Extract frames from video | No (needs ffmpeg) |
| **songsee** | Audio spectrograms | No |

**TTS options (not skills, set up separately):**
- **Piper** (local, free): Quick voice messages, low latency
- **Hume Octave** (API, paid): Narration, documentary, dramatic content
- **ElevenLabs** (API, paid): High quality, voice cloning

## Phase 4: Advanced (Install for Specific Projects)

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **goplaces** | Google Places lookup | Yes |
| **gh-issues** | Automated GitHub issue management + PR creation | No |
| **tmux** | Remote-control terminal sessions | No |
| **obsidian** | Obsidian vault management | No |
| **healthcheck** | Security hardening audits | No |
| **skill-creator** | Create and package new skills | No |
| **mcporter** | MCP server integration | Varies |

## Phase 5: Custom Skills You'll Build

As your agent matures, you'll build custom skills for your workflows:

| Example | Purpose |
|---------|---------|
| **twitter** | Post, reply, follow, listen — with content strategy |
| **news-digest** | Automated email newsletter summarization |
| **photo-pipeline** | Upload → AI classify → smart crop → publish |
| **channel-monitor** | Dashboard for all messaging channels |
| **hallucination-watchdog** | Automated checks for stale/incorrect references |

Document them as skills (`SKILL.md` + scripts) so they're reproducible.

## Tips

- Install: `clawhub install <name>` or `clawhub install <name>@<version>`
- Search: `clawhub search <query>`
- Update all: `clawhub sync`
- Don't install everything at once — each skill adds to context window
- Configure API keys in `~/.openclaw/.env`
- **Test each skill immediately after install**
- **Document quirks in TOOLS.md**
