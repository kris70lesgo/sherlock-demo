#!/usr/bin/env bash
# Phase 6 Dispatcher: JIRA
# Creates remediation tracking tickets from finalized incidents
# Read-only: never mutates Sherlock state

set -e

INCIDENT_ID="$1"
REVIEW_RECORD="$2"
IKR="$3"
CONFIG="$4"

if [ ! -f "$REVIEW_RECORD" ] || [ ! -f "$IKR" ]; then
    echo "⚠️  JIRA dispatcher: missing artifacts for $INCIDENT_ID"
    exit 1
fi

# Parse config for JIRA settings
JIRA_ENABLED=$(grep "enabled:" "$CONFIG" -A 20 | grep -A 10 "jira:" | grep "enabled:" | head -1 | awk '{print $2}')
if [ "$JIRA_ENABLED" != "true" ]; then
    echo "ℹ️  JIRA dispatcher disabled in config"
    exit 0
fi

JIRA_PROJECT=$(grep "project:" "$CONFIG" -A 20 | grep "jira:" -A 10 | grep "project:" | awk '{print $2}' | tr -d '"')
JIRA_ISSUE_TYPE=$(grep "issue_type:" "$CONFIG" -A 20 | grep "jira:" -A 10 | grep "issue_type:" | awk '{print $2}' | tr -d '"')
JIRA_PRIORITY=$(grep "priority:" "$CONFIG" -A 20 | grep "jira:" -A 10 | grep "priority:" | awk '{print $2}' | tr -d '"')

# Extract remediation promises from IKR
python3 - "$IKR" "$REVIEW_RECORD" <<'CREATE_TICKETS'
import sys
import json

# Simple YAML parser
def parse_yaml(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    data = {}
    current_list = None
    
    for line in lines:
        if line.strip().startswith('#') or not line.strip():
            continue
        
        if not line.startswith(' ') and ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"')
            
            if value:
                data[key] = value
            else:
                current_list = key
                data[key] = []
        elif line.startswith('  -') and current_list:
            value = line.strip()[1:].strip().strip('"')
            data[current_list].append(value)
    
    return data

ikr = parse_yaml(sys.argv[1])

# Check finalization status
with open(sys.argv[2], 'r') as f:
    review_lines = f.readlines()

approval_status = "UNKNOWN"
in_approval_section = False
for line in review_lines:
    if line.strip().startswith('approval:'):
        in_approval_section = True
        continue
    if in_approval_section and 'status:' in line:
        approval_status = line.split(':')[1].split('#')[0].strip()
        break
    if in_approval_section and not line.startswith(' '):
        break

if approval_status != "FINALIZED":
    print(f"⚠️  Incident not finalized - skipping JIRA dispatch")
    sys.exit(0)

incident_id = ikr.get('incident_id', 'unknown')
service = ikr.get('service', 'unknown')
root_cause = ikr.get('primary_root_cause', 'unknown')
remediations = ikr.get('remediation_promises', [])

if not remediations:
    print(f"ℹ️  No remediation promises for {incident_id} - no tickets to create")
    sys.exit(0)

# Generate JIRA ticket payloads
print(f"\n📋 Creating {len(remediations)} JIRA ticket(s) for {incident_id}:\n")

for i, action in enumerate(remediations, 1):
    ticket = {
        "fields": {
            "project": {"key": "PROJECT_KEY"},  # Will be replaced from config
            "summary": f"[{incident_id}] {action[:80]}",
            "description": f"""Remediation action from incident {incident_id}

Root Cause: {root_cause}
Service: {service}

Action:
{action}

Artifacts:
- Postmortem: reports/post-mortem-{incident_id}.md
- Review Record: reports/review-record-{incident_id}.yaml
- Institutional Memory: incidents/{incident_id}.yaml

This ticket was automatically created by Sherlock Phase 6.
""",
            "issuetype": {"name": "ISSUE_TYPE"},  # Will be replaced
            "priority": {"name": "PRIORITY"},     # Will be replaced
            "labels": ["incident-remediation", "sherlock", incident_id, service]
        }
    }
    
    print(f"  {i}. {action[:70]}{'...' if len(action) > 70 else ''}")
    
    # In production, this would POST to JIRA REST API:
    # curl -X POST -H 'Content-Type: application/json' \
    #   -u $JIRA_USER:$JIRA_TOKEN \
    #   -d '$TICKET_JSON' \
    #   $JIRA_API_URL/rest/api/2/issue

print(f"\n✓ {len(remediations)} ticket payload(s) prepared")
print("  (In production, these would POST to JIRA API)")
CREATE_TICKETS

echo
echo "✓ JIRA tickets prepared for project $JIRA_PROJECT"
