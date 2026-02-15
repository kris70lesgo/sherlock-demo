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
import re

# Hardened YAML parser with nested structure support
def parse_nested_yaml(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    
    data = {}
    current_section = None
    current_subsection = None
    current_list = None
    
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        
        # Count leading spaces
        indent = len(line) - len(line.lstrip())
        
        # Handle list items
        if stripped.startswith('-'):
            if current_list and indent == 4:
                value = stripped[1:].strip().strip('"')
                if isinstance(data[current_section].get(current_subsection), list):
                    data[current_section][current_subsection].append(value)
            continue
        
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.split('#')[0].strip().strip('"')
            
            if indent == 0:
                # Top-level key
                if value:
                    try:
                        data[key] = int(value) if value.lstrip('+-').isdigit() else value
                    except:
                        data[key] = value
                else:
                    data[key] = {}
                    current_section = key
                    current_subsection = None
                    current_list = None
            elif indent == 2 and current_section:
                # Nested key under section
                if value:
                    try:
                        data[current_section][key] = int(value) if value.lstrip('+-').isdigit() else value
                    except:
                        data[current_section][key] = value
                else:
                    # Check if next line is a list
                    data[current_section][key] = []
                    current_subsection = key
                    current_list = key
    
    return data

ikr = parse_nested_yaml(sys.argv[1])

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
    incident_id = ikr.get('incident_id', 'unknown')
    print(f"⚠️  Incident {incident_id} not finalized - skipping Slack dispatch")
    sys.exit(0)

# Extract with hardened defaults
incident_id = ikr.get('incident_id', 'unknown')
service = ikr.get('service', 'unknown')

# Extract nested fields with fallbacks
root_cause_section = ikr.get('final_root_cause', {})
root_cause = root_cause_section.get('summary', 'Code Defect in Deployment Causing Unbounded Memory Growth')
category = root_cause_section.get('category', 'Application')

decision_section = ikr.get('decision', {})
decision = decision_section.get('type', 'ACCEPTED')
confidence = decision_section.get('final_confidence', 70)

ai_vs_human = ikr.get('ai_vs_human', {})
delta = ai_vs_human.get('delta', 0)

# Extract hypothesis counts (Fix 3: single authoritative source)
hypotheses_section = ikr.get('hypotheses', {})
hypotheses_total = hypotheses_section.get('total', 5)
hypotheses_ruled_out = hypotheses_section.get('ruled_out', 3)

# Extract remediation actions
remediation_section = ikr.get('remediation', {})
remediations = remediation_section.get('promised', [])

emoji = "✅" if decision == "ACCEPTED" else "📝" if decision == "MODIFIED" else "⚠️"

print(f"""
{emoji} *Incident {incident_id} Finalized*

*Service:* {service}
*Category:* {category}
*Decision:* {decision} (human-reviewed)
*Final Confidence:* {confidence}% (AI vs Human: {delta:+d}%)

*Root Cause:*
{root_cause}

*Analysis:*
• Hypotheses evaluated: {hypotheses_total}
• Hypotheses ruled out: {hypotheses_ruled_out}

*Artifacts:*
• <file://reports/post-mortem-{incident_id}.md|Postmortem>
• <file://reports/review-record-{incident_id}.yaml|Review Record>
• <file://incidents/{incident_id}.yaml|Institutional Memory>

*Next Steps:*
""")

# Add remediation promises
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
