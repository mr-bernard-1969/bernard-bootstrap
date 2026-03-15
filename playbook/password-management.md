# Password Management

As your agent accumulates API keys, service credentials, and account passwords, you need a structured system. This playbook describes the KeePassXC vault pattern that works well for AI agent deployments.

## Why KeePassXC

- **Offline** — `.kdbx` file, no cloud dependency, no subscription
- **AES-256** — strong encryption, industry standard
- **CLI-scriptable** — `keepassxc-cli` for agent access
- **Cross-platform** — desktop apps + mobile via Strongbox (iOS) / KeePassDX (Android)
- **Syncable** — Syncthing for real-time sync between devices
- **Fits "own your infrastructure"** — no third-party vault service

## Setup

### 1. Install KeePassXC

```bash
# Ubuntu/Debian
sudo apt install keepassxc

# Verify CLI is available
keepassxc-cli --version
```

### 2. Create the Vault

```bash
keepassxc-cli db-create ~/.openclaw/vault.kdbx
# Enter a strong master password
# Store the master password in .env:
echo 'VAULT_MASTER_PASSWORD=your-master-password-here' >> ~/.openclaw/.env
```

### 3. Organize with Groups

Create groups to categorize credentials:

```bash
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "APIs"
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "Services"
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "Accounts"
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "Infrastructure"
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "Email"
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "Banking"
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "Bots"
keepassxc-cli mkdir ~/.openclaw/vault.kdbx "Social"
```

### 4. Create a Vault CLI Wrapper

```bash
#!/bin/bash
# scripts/vault.sh — Quick vault access
VAULT="$HOME/.openclaw/vault.kdbx"
PW="${VAULT_MASTER_PASSWORD:-}"

case "${1:-list}" in
  show)   echo "$PW" | keepassxc-cli show "$VAULT" "$2" 2>/dev/null ;;
  list)   echo "$PW" | keepassxc-cli ls "$VAULT" "${2:-/}" 2>/dev/null ;;
  search) echo "$PW" | keepassxc-cli search "$VAULT" "$2" 2>/dev/null ;;
  add)    echo "$PW" | keepassxc-cli add "$VAULT" "$2" -u "$3" -p 2>/dev/null ;;
  clip)   echo "$PW" | keepassxc-cli clip "$VAULT" "$2" 2>/dev/null ;;
  *)      echo "Usage: vault.sh show|list|search|add|clip [entry] [username]" ;;
esac
```

### 5. Add Entries

```bash
# Add an API key
echo "$VAULT_MASTER_PASSWORD" | keepassxc-cli add ~/.openclaw/vault.kdbx \
  "APIs/Anthropic" -u "api-key" --password-prompt

# Add a service credential
echo "$VAULT_MASTER_PASSWORD" | keepassxc-cli add ~/.openclaw/vault.kdbx \
  "Services/My Database" -u "admin" --password-prompt
```

## Mobile Sync (Optional)

Use Syncthing for real-time sync between VPS and mobile:

### VPS Side
```bash
# Install Syncthing
sudo apt install syncthing

# Enable as user service
systemctl --user enable syncthing
systemctl --user start syncthing

# Create sync directory
mkdir -p ~/vault-sync
ln -s ~/.openclaw/vault.kdbx ~/vault-sync/vault.kdbx
```

### Mobile Side
- **iOS:** Install SyncTrain (free, open source) + Strongbox for .kdbx viewing
- **Android:** Install Syncthing + KeePassDX

### Connect Devices
1. Get VPS device ID: `syncthing -device-id`
2. Add VPS as remote device in mobile Syncthing
3. Share the `vault-sync` folder
4. Vault file auto-syncs on changes

## Security Notes

- **Master password** lives in `.env` only — never in workspace files, never in git
- **`.kdbx` file** is encrypted at rest — safe to sync via Syncthing
- **Never commit** `.kdbx` files to git repositories
- **Backup** the vault regularly (it's just a file — include in your backup script)
- **Agent access** via `keepassxc-cli` reads credentials without exposing them in session transcripts
- **Rotate** credentials periodically — the vault makes this trackable

## When to Use the Vault vs `.env`

| Credential Type | Where to Store |
|----------------|---------------|
| API keys used by scripts/services | `.env` (services read from env) |
| API keys for manual/ad-hoc use | Vault |
| Website logins | Vault |
| Database passwords | Vault + `.env` if service needs it |
| SSH keys/passphrases | Vault (key files in `~/.ssh/`) |
| Master passwords | `.env` only |
| Temporary/rotating tokens | Vault (with notes about rotation schedule) |

The vault is your single source of truth for "what credentials do we have?" while `.env` is where running services actually read their keys from.
