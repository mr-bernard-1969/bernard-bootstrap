#!/bin/bash
# emergency-contact.sh — Multi-channel emergency notification
# Usage: bash scripts/emergency-contact.sh sms|telegram|both "message"
#
# Sends urgent messages through multiple channels based on severity.
# Configure with your own bot tokens and phone numbers.
set -uo pipefail

MODE="${1:-telegram}"
MESSAGE="${2:-Emergency: no message provided}"

# ── Configuration (customize these) ──
# Store these in .env and source them, or set them here
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
OWNER_CHAT_ID="${OWNER_CHAT_ID:-}"
SMS_API_KEY="${SMS_API_KEY:-}"
OWNER_PHONE="${OWNER_PHONE:-}"

send_telegram() {
    if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$OWNER_CHAT_ID" ]; then
        echo "❌ Telegram not configured (TELEGRAM_BOT_TOKEN / OWNER_CHAT_ID)"
        return 1
    fi
    curl -sf -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${OWNER_CHAT_ID}" \
        -d text="🚨 ${MESSAGE}" \
        -d parse_mode="Markdown" >/dev/null 2>&1
    echo "✅ Telegram sent"
}

send_sms() {
    if [ -z "$SMS_API_KEY" ] || [ -z "$OWNER_PHONE" ]; then
        echo "❌ SMS not configured (SMS_API_KEY / OWNER_PHONE)"
        return 1
    fi
    # Example using a generic SMS API — replace with your provider (Telnyx, Twilio, etc.)
    # curl -sf -X POST "https://api.your-sms-provider.com/messages" \
    #     -H "Authorization: Bearer ${SMS_API_KEY}" \
    #     -H "Content-Type: application/json" \
    #     -d "{\"to\": \"${OWNER_PHONE}\", \"text\": \"🚨 ${MESSAGE}\"}" >/dev/null 2>&1
    echo "⚠️ SMS sending not configured — customize this script with your SMS provider"
}

case "$MODE" in
    telegram)
        send_telegram
        ;;
    sms)
        send_sms
        ;;
    both)
        send_telegram
        send_sms
        ;;
    *)
        echo "Usage: emergency-contact.sh sms|telegram|both \"message\""
        exit 1
        ;;
esac
