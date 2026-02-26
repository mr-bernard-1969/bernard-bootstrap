# Skills Manifest — What to Install and When

## Phase 1: Essential (Install Immediately)

These make your agent functional from day one.

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **weather** | Weather forecasts | No |
| **github** | GitHub operations via `gh` CLI | No (needs `gh auth login`) |
| **gemini** | Fast Q&A and generation | Yes (free tier available) |

Install with:
```bash
clawhub install weather github gemini
```

## Phase 2: Communication (Install When Setting Up Channels)

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **himalaya** | Email via IMAP/SMTP | No (needs mail account config) |
| **gog** | Google Workspace (Gmail, Calendar, Drive) | Yes (OAuth setup) |

## Phase 3: Media & Creative (Install When Needed)

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **nano-banana-pro** | Image generation (Gemini) | Yes (~$0.13/image) |
| **openai-whisper-api** | Audio transcription | Yes |
| **video-frames** | Extract frames from video | No (needs ffmpeg) |
| **songsee** | Audio spectrograms | No |
| **hume-narration** | High-quality TTS narration | Yes |

## Phase 4: Advanced (Install for Specific Projects)

| Skill | Purpose | Needs API Key? |
|-------|---------|----------------|
| **goplaces** | Google Places lookup | Yes |
| **gh-issues** | Automated GitHub issue management | No |
| **tmux** | Remote-control terminal sessions | No |
| **obsidian** | Obsidian vault management | No |
| **healthcheck** | Security hardening | No |
| **skill-creator** | Create new skills | No |

## Tips

- Install skills with `clawhub install <name>` or `clawhub install <name>@<version>`
- Check what's available: `clawhub search <query>`
- Update all: `clawhub sync`
- Don't install everything at once — each skill adds to your context window
- Configure API keys in `~/.openclaw/.env`
