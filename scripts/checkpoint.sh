#!/bin/bash
MSG="${1:-checkpoint}"
TAG="checkpoint-$(date +%Y%m%d-%H%M%S)"
cd ~/.openclaw/workspace
git add -A && git commit -m "$MSG" && git tag "$TAG"
echo "✅ Checkpoint: $TAG"
