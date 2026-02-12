#!/usr/bin/env bash
# Phase 6 Dispatcher: Email
# Sends incident finalization notifications via email
# Read-only: never mutates Sherlock state

set -e

INCIDENT_ID="$1"
REVIEW_RECORD="$2"
IKR="$3"
CONFIG="$4"

if [ ! -f "$REVIEW_RECORD" ] || [ ! -f "$IKR" ]; then
    echo "⚠️  Email dispatcher: missing artifacts for $INCIDENT_ID"
    exit 1
fi

# Parse config for Email settings
EMAIL_ENABLED=$(grep "enabled:" "$CONFIG" -A 40 | grep -A 10 "email:" | grep "enabled:" | head -1 | awk '{print $2}')
if [ "$EMAIL_ENABLED" != "true" ]; then
    echo "ℹ️  Email dispatcher disabled in config"
    exit 0
fi

EMAIL_TO=$(grep "to:" "$CONFIG" -A 40 | grep "email:" -A 10 | grep "to:" | awk '{print $2}' | tr -d '[]"')

echo "✓ Email notification prepared for $EMAIL_TO"
echo "  (In production, this would send via SMTP or SES)"
