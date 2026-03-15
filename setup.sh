#!/bin/bash
set -euo pipefail

# Bernard Bootstrap — Setup Script
# Takes a fresh OpenClaw install and gives it operational DNA

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="${HOME}/.openclaw/workspace"
OPENCLAW_DIR="${HOME}/.openclaw"

echo "🔧 Bernard Bootstrap Kit"
echo "========================"
echo ""

# Check OpenClaw is installed
if ! command -v openclaw &>/dev/null; then
    echo "❌ OpenClaw not found. Install it first: npm install -g openclaw"
    exit 1
fi

echo "✅ OpenClaw found: $(which openclaw)"

# Create workspace structure
echo ""
echo "📁 Creating workspace structure..."

mkdir -p "$WORKSPACE"
mkdir -p "$WORKSPACE/memory"
mkdir -p "$WORKSPACE/config"
mkdir -p "$WORKSPACE/scripts"
mkdir -p "$WORKSPACE/projects"

echo "   ✅ Directories created"

# Copy templates (only if files don't already exist)
echo ""
echo "📝 Installing templates..."

copy_if_missing() {
    local src="$1"
    local dst="$2"
    local name="$(basename "$dst")"
    if [ -f "$dst" ]; then
        echo "   ⏭️  $name already exists — skipping"
    else
        cp "$src" "$dst"
        echo "   ✅ $name installed"
    fi
}

copy_if_missing "$SCRIPT_DIR/templates/SOUL.md" "$WORKSPACE/SOUL.md"
copy_if_missing "$SCRIPT_DIR/templates/IDENTITY.md" "$WORKSPACE/IDENTITY.md"
copy_if_missing "$SCRIPT_DIR/templates/AGENTS.md" "$WORKSPACE/AGENTS.md"
copy_if_missing "$SCRIPT_DIR/templates/USER.md" "$WORKSPACE/USER.md"
copy_if_missing "$SCRIPT_DIR/templates/HEARTBEAT.md" "$WORKSPACE/HEARTBEAT.md"
copy_if_missing "$SCRIPT_DIR/templates/TOOLS.md" "$WORKSPACE/TOOLS.md"
copy_if_missing "$SCRIPT_DIR/templates/MEMORY.md" "$WORKSPACE/MEMORY.md"

# Create empty memory files
echo ""
echo "🧠 Setting up memory system..."

touch_if_missing() {
    local dst="$1"
    local name="$(basename "$dst")"
    if [ -f "$dst" ]; then
        echo "   ⏭️  $name already exists — skipping"
    else
        echo "# $(basename "$dst" .md)" > "$dst"
        echo "" >> "$dst"
        echo "   ✅ $name created"
    fi
}

touch_if_missing "$WORKSPACE/MEMORY.md"
touch_if_missing "$WORKSPACE/memory/facts.md"
touch_if_missing "$WORKSPACE/memory/decisions.md"
touch_if_missing "$WORKSPACE/memory/entities.md"

# Create timezone config
if [ ! -f "$WORKSPACE/config/timezone.txt" ]; then
    # Try to detect system timezone
    if [ -f /etc/timezone ]; then
        cat /etc/timezone > "$WORKSPACE/config/timezone.txt"
    elif command -v timedatectl &>/dev/null; then
        timedatectl show -p Timezone --value > "$WORKSPACE/config/timezone.txt" 2>/dev/null || echo "UTC" > "$WORKSPACE/config/timezone.txt"
    else
        echo "UTC" > "$WORKSPACE/config/timezone.txt"
    fi
    echo "   ✅ Timezone set to: $(cat "$WORKSPACE/config/timezone.txt")"
else
    echo "   ⏭️  timezone.txt already exists: $(cat "$WORKSPACE/config/timezone.txt")"
fi

# Create heartbeat state
if [ ! -f "$WORKSPACE/memory/heartbeat-state.json" ]; then
    echo '{"lastChecks":{}}' > "$WORKSPACE/memory/heartbeat-state.json"
    echo "   ✅ Heartbeat state initialized"
fi

# Copy playbook
echo ""
echo "📚 Installing operational playbook..."
mkdir -p "$WORKSPACE/playbook"
for f in "$SCRIPT_DIR/playbook/"*.md; do
    name="$(basename "$f")"
    if [ -f "$WORKSPACE/playbook/$name" ]; then
        echo "   ⏭️  $name already exists — skipping"
    else
        cp "$f" "$WORKSPACE/playbook/$name"
        echo "   ✅ $name installed"
    fi
done

# Initialize git
echo ""
if [ -d "$WORKSPACE/.git" ]; then
    echo "📦 Git already initialized"
else
    echo "📦 Initializing git..."
    cd "$WORKSPACE"
    git init -b main
    echo "   ✅ Git initialized"
fi

# Summary
echo ""
echo "========================"
echo "✅ Bootstrap complete!"
echo ""
echo "Next steps:"
echo "  1. Edit $WORKSPACE/SOUL.md — give your agent a personality"
echo "  2. Edit $WORKSPACE/IDENTITY.md — name, backstory, philosophy"
echo "  3. Edit $WORKSPACE/USER.md — tell it about yourself"
echo "  4. Edit $WORKSPACE/config/timezone.txt — your timezone"
echo "  5. Run 'openclaw gateway start' to launch"
echo "  6. Read playbook/ for operational best practices"
echo ""
echo "Your agent will read these files on first session and start learning."
echo "The playbook in $WORKSPACE/playbook/ contains hard-won operational lessons."
echo ""
echo "Welcome to OpenClaw. 🐾"
