#!/usr/bin/env bash
# Phase 6 Dispatcher: Slack
# Emits incident finalization notifications to Slack
# Read-only: never mutates Sherlock state

set -e

INCIDENT_ID="$1"
REVIEW_RECORD="$2"
IKR="$3"
CONFIG="$4"

if [ ! -f "$REVIEW_RECORD" ] || [ ! -f "$IKR" ]; then
    echo "⚠️  Slack dispatcher: missing artifacts for $INCIDENT_ID"
    exit 1
fi

# Parse config for Slack settings
SLACK_ENABLED=$(grep "enabled:" "$CONFIG" -A 20 | grep -A 5 "slack:" | grep "enabled:" | head -1 | awk '{print $2}')
if [ "$SLACK_ENABLED" != "true" ]; then
    echo "ℹ️  Slack dispatcher disabled in config"
    exit 0
fi

SLACK_CHANNEL=$(grep "channel:" "$CONFIG" -A 20 | grep "slack:" -A 5 | grep "channel:" | awk '{print $2}' | tr -d '"')

# Extract key data from IKR
python3 - "$IKR" "$REVIEW_RECORD" <<'EXTRACT_DATA'
import sys

# Simple YAML parser for IKR
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
                try:
                    if value.isdigit() or (value.startswith('+') or value.startswith('-')):
                        data[key] = int(value)
                    else:
                        data[key] = value
                except:
                    data[key] = value
            else:
                current_list = key
                data[key] = []
        elif line.startswith('  -') and current_list:
            value = line.strip()[1:].strip().strip('"')
            data[current_list].append(value)
    
    return data

ikr = parse_yaml(sys.argv[1])

# Determine finalization status from review record
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
    print(f"⚠️  Incident {ikr.get('incident_id', 'unknown')} not finalized - skipping Slack dispatch")
    sys.exit(0)

# Build Slack message
incident_id = ikr.get('incident_id', 'unknown')
service = ikr.get('service', 'unknown')
category = ikr.get('category', 'unknown')
decision = ikr.get('decision', 'unknown')
confidence = ikr.get('human_confidence', 0)
root_cause = ikr.get('primary_root_cause', 'unknown')
delta = ikr.get('confidence_delta', 0)

emoji = "✅" if decision == "ACCEPTED" else "📝" if decision == "MODIFIED" else "⚠️"

print(f"""
{emoji} *Incident {incident_id} Finalized*

*Service:* {service}
*Category:* {category}
*Decision:* {decision} (human-reviewed)
*Final Confidence:* {confidence}% (AI vs Human: {delta:+d}%)

*Root Cause:*
{root_cause}

*Artifacts:*
• <file://reports/post-mortem-{incident_id}.md|Postmortem>
• <file://reports/review-record-{incident_id}.yaml|Review Record>
• <file://incidents/{incident_id}.yaml|Institutional Memory>

*Next Steps:*
""")

# Add remediation promises
remediations = ikr.get('remediation_promises', [])
if remediations:
    for i, action in enumerate(remediations[:3], 1):
        print(f"{i}. {action}")
    if len(remediations) > 3:
        print(f"   ... and {len(remediations) - 3} more")
else:
    print("No remediation actions specified")

if decision == "MODIFIED":
    print("\n_⚙️ Remediation tickets will be created in JIRA_")
elif decision == "REJECTED":
    print("\n_⚠️ Analysis rejected - requires further investigation_")
EXTRACT_DATA

# In production, this would use:
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"channel":"'$SLACK_CHANNEL'","text":"'$MESSAGE'"}' \
#   $SLACK_WEBHOOK_URL

echo
echo "✓ Slack notification prepared for $SLACK_CHANNEL"
echo "  (In production, this would POST to Slack API)"
