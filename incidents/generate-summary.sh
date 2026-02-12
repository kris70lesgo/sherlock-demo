#!/bin/bash
# Incident Summary Generator
# Aggregates per-service analyses into multi-service incident summary.
#
# Purpose: Show complete incident picture WITHOUT violating service sovereignty.
# Each service keeps its own RCA. Summary reports facts, not synthesis.

set -euo pipefail

INCIDENT_ID="$1"

# Files
COORDINATION_FILE="incidents/${INCIDENT_ID}.coordination.yaml"
OUTPUT_FILE="reports/incident-summary-${INCIDENT_ID}.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Incident Summary Generator${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# Check coordination file exists
if [ ! -f "$COORDINATION_FILE" ]; then
    echo -e "${RED}❌ COORDINATION FILE NOT FOUND${NC}"
    echo "   Expected: $COORDINATION_FILE"
    echo
    echo "   This tool is for multi-service incidents only."
    echo "   For single-service incidents, use the standard postmortem."
    exit 1
fi

echo "Incident: $INCIDENT_ID"
echo "Coordination: $COORDINATION_FILE"
echo

# Parse coordination record
INCIDENT_TITLE=$(grep "incident_title:" "$COORDINATION_FILE" | sed 's/incident_title: *"//' | sed 's/"$//')
INCIDENT_SEVERITY=$(grep "incident_severity:" "$COORDINATION_FILE" | sed 's/incident_severity: *//')
DECLARED_BY=$(grep -A 3 "declared_by:" "$COORDINATION_FILE" | grep "name:" | head -1 | sed 's/.*name: *//' | sed 's/"//g')

echo "Title: $INCIDENT_TITLE"
echo "Severity: $INCIDENT_SEVERITY"
echo "Declared by: $DECLARED_BY"
echo

# Extract services
echo "Extracting service analyses..."
SERVICES=$(grep -A 1 "^  - name:" "$COORDINATION_FILE" | grep "name:" | sed 's/.*name: *//')

# Start building summary
mkdir -p reports

cat > "$OUTPUT_FILE" << 'EOF_HEADER'
# Multi-Service Incident Summary

**Purpose:** This document aggregates per-service analyses for a multi-service incident.  
**Not a synthesis:** Each service maintains sovereignty. No cross-service root cause.  
**Not AI-generated:** Facts from coordination record and service postmortems only.

---

EOF_HEADER

# Add incident metadata
cat >> "$OUTPUT_FILE" << EOF_META
## Incident Metadata

- **Incident ID:** ${INCIDENT_ID}
- **Title:** ${INCIDENT_TITLE}
- **Severity:** ${INCIDENT_SEVERITY}
- **Declared by:** ${DECLARED_BY}
- **Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

---

## Services Involved

EOF_META

# List services with roles
for SERVICE in $SERVICES; do
    ROLE=$(grep -A 2 "name: $SERVICE$" "$COORDINATION_FILE" | grep "role:" | sed 's/.*role: *//')
    JUSTIFICATION=$(grep -A 3 "name: $SERVICE$" "$COORDINATION_FILE" | grep "justification:" | sed 's/.*justification: *"//' | sed 's/"$//')
    
    echo "- **${SERVICE}** (${ROLE})" >> "$OUTPUT_FILE"
    echo "  - ${JUSTIFICATION}" >> "$OUTPUT_FILE"
done

cat >> "$OUTPUT_FILE" << 'EOF_DIVIDER'

---

## Per-Service Analysis

EOF_DIVIDER

# Process each service
SERVICE_COUNT=0
FINALIZED_COUNT=0

for SERVICE in $SERVICES; do
    ((SERVICE_COUNT++))
    
    echo "Processing: $SERVICE"
    
    ROLE=$(grep -A 2 "name: $SERVICE$" "$COORDINATION_FILE" | grep "role:" | sed 's/.*role: *//')
    
    # Check for review record
    REVIEW_FILE="reports/review-record-${INCIDENT_ID}-${SERVICE}.yaml"
    POSTMORTEM_FILE="reports/postmortem-${INCIDENT_ID}-${SERVICE}.md"
    
    echo "### Service: ${SERVICE}" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
    echo "**Role:** ${ROLE}" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
    
    if [ ! -f "$REVIEW_FILE" ]; then
        echo "⚠️  **STATUS:** Not yet reviewed" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
        echo "_No review record found. This service's analysis is incomplete._" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
    else
        # Extract review status
        APPROVAL_STATUS=$(grep "status:" "$REVIEW_FILE" | head -1 | sed 's/.*status: *//')
        REVIEWED_BY=$(grep -A 5 "approval:" "$REVIEW_FILE" | grep "name:" | head -1 | sed 's/.*name: *//')
        DETERMINATION=$(grep "determination:" "$REVIEW_FILE" | sed 's/.*determination: *//')
        
        echo "✓ **STATUS:** ${APPROVAL_STATUS}" >> "$OUTPUT_FILE"
        echo "**Reviewed by:** ${REVIEWED_BY}" >> "$OUTPUT_FILE"
        echo "**Determination:** ${DETERMINATION}" >> "$OUTPUT_FILE"
        echo >> "$OUTPUT_FILE"
        
        if [ "$APPROVAL_STATUS" = "FINALIZED" ]; then
            ((FINALIZED_COUNT++))
        fi
        
        # Extract root cause if present
        if [ -f "$POSTMORTEM_FILE" ]; then
            echo "**Root Cause (Service-Local):**" >> "$OUTPUT_FILE"
            echo >> "$OUTPUT_FILE"
            # Extract "what happened" section if present
            if grep -q "## What Happened" "$POSTMORTEM_FILE"; then
                sed -n '/## What Happened/,/^##/p' "$POSTMORTEM_FILE" | sed '$d' | sed '1d' >> "$OUTPUT_FILE"
            else
                echo "_See postmortem: ${POSTMORTEM_FILE}_" >> "$OUTPUT_FILE"
            fi
            echo >> "$OUTPUT_FILE"
        fi
        
        # Extract action items if present
        if [ -f "$REVIEW_FILE" ]; then
            if grep -q "action_item:" "$REVIEW_FILE"; then
                echo "**Action Items:**" >> "$OUTPUT_FILE"
                echo >> "$OUTPUT_FILE"
                grep "action_item:" "$REVIEW_FILE" | sed 's/.*action_item: */- /' >> "$OUTPUT_FILE"
                echo >> "$OUTPUT_FILE"
            fi
        fi
    fi
    
    echo "---" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
done

# Add coordination notes
if grep -q "coordination_notes:" "$COORDINATION_FILE"; then
    echo "## Coordination Notes" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
    grep '    - "' "$COORDINATION_FILE" | sed 's/.*- "/- /' | sed 's/"$//' >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
    echo "---" >> "$OUTPUT_FILE"
    echo >> "$OUTPUT_FILE"
fi

# Add summary statistics
cat >> "$OUTPUT_FILE" << EOF_STATS

## Summary Statistics

- **Total Services:** ${SERVICE_COUNT}
- **Finalized Reviews:** ${FINALIZED_COUNT}
- **Pending Reviews:** $((SERVICE_COUNT - FINALIZED_COUNT))

EOF_STATS

# Check if primary candidate is finalized
PRIMARY_SERVICES=$(grep -B 2 "role: primary_candidate" "$COORDINATION_FILE" | grep "name:" | sed 's/.*name: *//')

if [ -n "$PRIMARY_SERVICES" ]; then
    for PRIMARY_SERVICE in $PRIMARY_SERVICES; do
        PRIMARY_REVIEW="reports/review-record-${INCIDENT_ID}-${PRIMARY_SERVICE}.yaml"
        if [ -f "$PRIMARY_REVIEW" ]; then
            PRIMARY_STATUS=$(grep "status:" "$PRIMARY_REVIEW" | head -1 | sed 's/.*status: *//')
            if [ "$PRIMARY_STATUS" = "FINALIZED" ]; then
                echo "**Incident Closure:** ✓ Primary candidate finalized (${PRIMARY_SERVICE})" >> "$OUTPUT_FILE"
            else
                echo "**Incident Closure:** ⚠️  Awaiting primary candidate finalization (${PRIMARY_SERVICE})" >> "$OUTPUT_FILE"
            fi
        else
            echo "**Incident Closure:** ⚠️  Awaiting primary candidate review (${PRIMARY_SERVICE})" >> "$OUTPUT_FILE"
        fi
    done
else
    echo "**Incident Closure:** No primary candidate declared" >> "$OUTPUT_FILE"
fi

echo >> "$OUTPUT_FILE"
echo "---" >> "$OUTPUT_FILE"
echo >> "$OUTPUT_FILE"

# Add footer
cat >> "$OUTPUT_FILE" << 'EOF_FOOTER'

## Reading This Summary

This summary aggregates service-specific analyses. Key principles:

1. **Service Sovereignty:** Each service owns its root cause analysis
2. **No Cross-Service Synthesis:** This summary reports facts, not correlations
3. **Incident ≠ RCA:** Incident has coordination; each service has its own RCA
4. **Primary Candidate:** Service most likely to contain root cause (must be finalized)
5. **Governance Preserved:** Each service follows its own approval requirements

For detailed analysis of any service, refer to its individual postmortem.

EOF_FOOTER

echo
echo -e "${GREEN}✓ Summary generated${NC}"
echo "   Output: $OUTPUT_FILE"
echo
echo "Services processed: $SERVICE_COUNT"
echo "Finalized reviews: $FINALIZED_COUNT"
echo

# Display summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}Summary Preview${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo
head -30 "$OUTPUT_FILE"
echo
echo "... (see full report at $OUTPUT_FILE)"
echo
