#!/usr/bin/env bash
# Phase 6 Dispatcher: GitHub Issues
# Creates remediation tracking issues from finalized incidents
# Read-only: never mutates Sherlock state

set -e

INCIDENT_ID="$1"
REVIEW_RECORD="$2"
IKR="$3"
CONFIG="$4"

if [ ! -f "$REVIEW_RECORD" ] || [ ! -f "$IKR" ]; then
    echo "⚠️  GitHub dispatcher: missing artifacts for $INCIDENT_ID"
    exit 1
fi

# Parse config for GitHub settings
GITHUB_ENABLED=$(grep "enabled:" "$CONFIG" -A 30 | grep -A 10 "github:" | grep "enabled:" | head -1 | awk '{print $2}')
if [ "$GITHUB_ENABLED" != "true" ]; then
    echo "ℹ️  GitHub dispatcher disabled in config"
    exit 0
fi

GITHUB_REPO=$(grep "repo:" "$CONFIG" -A 30 | grep "github:" -A 10 | grep "repo:" | awk '{print $2}' | tr -d '"')

echo "✓ GitHub issue creation prepared for repo $GITHUB_REPO"
echo "  (In production, this would POST to GitHub API)"
