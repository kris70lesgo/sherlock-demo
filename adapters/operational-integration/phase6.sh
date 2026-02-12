#!/usr/bin/env bash
# Phase 6: Operational Integration & Actionability
# Executes finalized decisions without influencing reasoning
#
# Core Principle: Phase 6 reads only, emits side effects, never feeds back

set -e

INCIDENT_ID="$1"

if [ -z "$INCIDENT_ID" ]; then
    echo "Usage: phase6.sh <incident_id>"
    exit 1
fi

# Locate artifacts
REVIEW_RECORD="reports/review-record-${INCIDENT_ID}.yaml"
IKR="incidents/${INCIDENT_ID}.yaml"
CONFIG="phase6/config/phase6.yaml"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 6: Operational Integration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Safety checks
if [ ! -f "$REVIEW_RECORD" ]; then
    echo "⚠️  Review record not found: $REVIEW_RECORD"
    echo "   Phase 6 requires finalized Phase 4 output"
    exit 1
fi

if [ ! -f "$IKR" ]; then
    echo "⚠️  Incident Knowledge Record not found: $IKR"
    echo "   Phase 6 requires Phase 5 output"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "⚠️  Phase 6 config not found: $CONFIG"
    exit 1
fi

# Check if Phase 6 is enabled
PHASE6_ENABLED=$(grep "^enabled:" "$CONFIG" | awk '{print $2}')
if [ "$PHASE6_ENABLED" != "true" ]; then
    echo "ℹ️  Phase 6 disabled in config"
    exit 0
fi

# Verify finalization status
APPROVAL_STATUS=$(grep -A 2 "^approval:" "$REVIEW_RECORD" | grep "status:" | awk '{print $2}' | tr -d '#' | head -1)

if [ "$APPROVAL_STATUS" != "FINALIZED" ]; then
    echo "⚠️  Incident $INCIDENT_ID not finalized (status: $APPROVAL_STATUS)"
    echo "   Phase 6 only processes FINALIZED incidents"
    exit 0
fi

echo "✓ Incident $INCIDENT_ID is finalized"
echo

# Extract decision type to determine dispatch rules
DECISION_TYPE=$(grep "^decision:" "$IKR" | awk '{print $2}')
echo "Decision type: $DECISION_TYPE"
echo

# Determine which dispatchers to run based on decision type
DISPATCHERS=()

case "$DECISION_TYPE" in
    ACCEPTED)
        DISPATCHERS=(slack)
        ;;
    MODIFIED)
        DISPATCHERS=(jira slack)
        ;;
    REJECTED)
        DISPATCHERS=(slack)
        ;;
    *)
        echo "⚠️  Unknown decision type: $DECISION_TYPE"
        exit 1
        ;;
esac

echo "Dispatchers to run: ${DISPATCHERS[@]}"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

# Execute dispatchers
DISPATCHER_DIR="phase6/dispatchers"

for dispatcher in "${DISPATCHERS[@]}"; do
    DISPATCHER_SCRIPT="$DISPATCHER_DIR/${dispatcher}.sh"
    
    if [ ! -f "$DISPATCHER_SCRIPT" ]; then
        echo "⚠️  Dispatcher not found: $DISPATCHER_SCRIPT"
        continue
    fi
    
    echo "Running dispatcher: $dispatcher"
    echo "─────────────────────────────────────────────────────────────"
    
    chmod +x "$DISPATCHER_SCRIPT"
    
    if bash "$DISPATCHER_SCRIPT" "$INCIDENT_ID" "$REVIEW_RECORD" "$IKR" "$CONFIG"; then
        echo "✓ $dispatcher dispatcher completed"
    else
        echo "⚠️  $dispatcher dispatcher failed (non-fatal)"
    fi
    
    echo
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Phase 6 Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo "Summary:"
echo "  • Incident: $INCIDENT_ID"
echo "  • Decision: $DECISION_TYPE"
echo "  • Dispatchers executed: ${#DISPATCHERS[@]}"
echo
echo "Note: Phase 6 is read-only and does not influence reasoning"
echo "      Removing Phase 6 changes nothing upstream"
