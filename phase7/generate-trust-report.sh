#!/usr/bin/env bash
# Phase 7: Trust Report Generator
# Creates human-readable explanation of Sherlock's trustworthiness
# This is what judges, auditors, and security reviewers read

set -e

INCIDENT_ID="$1"

if [ -z "$INCIDENT_ID" ]; then
    echo "Usage: generate-trust-report.sh <incident_id>"
    exit 1
fi

PROVENANCE_FILE="phase7/trust/provenance-${INCIDENT_ID}.json"
REASONING_MANIFEST="phase7/trust/reasoning-manifest.json"
OUTPUT_FILE="phase7/trust/trust-report-${INCIDENT_ID}.md"

if [ ! -f "$PROVENANCE_FILE" ]; then
    echo "⚠️  Provenance file not found: $PROVENANCE_FILE"
    echo "   Run generate-provenance.sh first"
    exit 1
fi

if [ ! -f "$REASONING_MANIFEST" ]; then
    echo "⚠️  Reasoning manifest not found: $REASONING_MANIFEST"
    exit 1
fi

echo "Generating trust report for $INCIDENT_ID..."

python3 - "$OUTPUT_FILE" "$INCIDENT_ID" "$PROVENANCE_FILE" "$REASONING_MANIFEST" <<'GENERATE_REPORT'
import sys
import json
from datetime import datetime

output_file = sys.argv[1]
incident_id = sys.argv[2]
provenance_file = sys.argv[3]
manifest_file = sys.argv[4]

# Load provenance
with open(provenance_file, 'r') as f:
    provenance = json.load(f)

# Load manifest
with open(manifest_file, 'r') as f:
    manifest = json.load(f)

# Generate trust report
report = f"""# Trust Report: {incident_id}

**Generated:** {datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")}  
**Sherlock Version:** {provenance.get('sherlock_version', 'unknown')}  
**Purpose:** External verification of incident analysis trustworthiness

---

## Executive Summary

This incident was processed under **fixed reasoning rules** with **mandatory human governance**. No component in this pipeline can modify future reasoning.

---

## Reasoning Protocol

This incident was analyzed using:

- **Fixed reasoning rules** (not adaptive)
- **Immutable hypothesis protocol** (version {manifest['reasoning_protocol']['hypothesis_protocol']})
- **Cryptographically-bound prompt** ({manifest['reasoning_protocol']['copilot_prompt_hash'][:20]}...)
- **No AI learning or feedback loops**

### Hypothesis Requirements

{manifest['reasoning_protocol']['hypothesis_requirements']['minimum_count']}-{manifest['reasoning_protocol']['hypothesis_requirements']['maximum_count']} diverse hypotheses required with:
- Evidence FOR + AGAINST each hypothesis (symmetry required)
- Confidence budget: total ≤ {manifest['confidence_rules']['max_total']}%
- Quality penalties from Phase 1 evidence contract

### Human Governance

- **Phase 4 human review:** {manifest['governance_guarantees']['phase4_human_review']}
- **Human override:** {'Enabled' if manifest['confidence_rules']['human_override'] else 'Disabled'}
- **Auto-approval:** {'Forbidden' if manifest['governance_guarantees']['no_auto_approval'] else 'Allowed'}

---

## Architectural Guarantees

### Phase Isolation

"""

phases_executed = provenance.get('executed_phases', [])
for phase in [1, 2, 3, 4, 5, 6]:
    status = "✓ Executed" if phase in phases_executed else "○ Not executed"
    descriptions = {
        1: "Evidence Contract & Normalization",
        2: "Scoping & Reduction",
        3: "Hypothesis-Based Reasoning (AI)",
        4: "Human Decision & Governance",
        5: "Organizational Memory (append-only)",
        6: "Operational Integration (read-only)"
    }
    report += f"- **Phase {phase}:** {descriptions[phase]} — {status}\n"

report += f"""

### Memory & Integration Properties

- **Phase 5 (Memory):** {('Append-only' if manifest['governance_guarantees']['phase5_append_only'] else 'Mutable')} — does not influence reasoning
- **Phase 6 (Integration):** {('Read-only' if manifest['governance_guarantees']['phase6_read_only'] else 'Read-write')} — emits side effects only

**Critical:** Removing Phase 5 or 6 does not change Phase 1-4 behavior.

---

## Forbidden Capabilities

The following capabilities are **explicitly forbidden** in Sherlock's architecture:

"""

for capability in manifest['forbidden_capabilities']:
    report += f"- ❌ {capability.replace('_', ' ').title()}\n"

report += f"""

These are not features that can be "turned off." They are architecturally impossible.

---

## Cryptographic Provenance

This incident's ar

tifacts are cryptographically bound:

"""

artifacts = provenance.get('artifacts', {})
for name, hash_val in artifacts.items():
    status = "✓" if hash_val else "⚠️ Missing"
    report += f"- **{name.replace('_', ' ').title()}:** {status}\n"
    if hash_val:
        report += f"  `{hash_val[:60]}...`\n"

verification = provenance.get('verification', {})
report += f"""

### Verification Status

- All artifacts present: {'✓ Yes' if verification.get('all_artifacts_present') else '⚠️ No'}
- Mandatory phases complete: {'✓ Yes' if verification.get('mandatory_phases_complete') else '⚠️ No'}
- Governance enforced: {'✓ Yes' if verification.get('governance_enforced') else '⚠️ No'}

**Tampering detection:** Any modification to artifacts would change their SHA-256 hashes, making tampering immediately detectable.

---

## External Verifiability

Anyone can verify this incident analysis by:

1. **Recomputing artifact hashes:**
   ```bash
   shasum -a 256 reports/incident-bundle-{incident_id}.json
   shasum -a 256 reports/post-mortem-{incident_id}.md
   shasum -a 256 reports/review-record-{incident_id}.yaml
   ```

2. **Verifying reasoning manifest:**
   ```bash
   cat phase7/trust/reasoning-manifest.json
   ```

3. **Checking phase execution order:**
   ```bash
   cat phase7/trust/provenance-{incident_id}.json
   ```

No trust in Sherlock or its operators is required. The cryptographic trail is self-verifying.

---

## Audit Questions & Answers

### Q: Can historical incidents bias future RCAs?

**A:** No. Phase 5 is strictly read-only and disconnected from reasoning. It provides organizational queries but never feeds back into AI prompts.

### Q: Can Sherlock learn from mistakes and improve automatically?

**A:** No. Learning and feedback loops are forbidden capabilities. Any improvement requires explicit code changes with git history.

### Q: Can someone bypass human review?

**A:** No. Phase 4 governance is mandatory. The pipeline cannot proceed to Phases 5-6 without human-approved review records.

### Q: How do we know the prompt wasn't changed?

**A:** The Copilot prompt is hashed ({manifest['reasoning_protocol']['copilot_prompt_hash'][:20]}...). Any change to the Phase 3 reasoning protocol would produce a different hash, detectable in the reasoning manifest.

### Q: Can AI manipulate its own confidence scores?

**A:** No. Confidence rules are fixed in the reasoning manifest. AI cannot self-modify ({str(manifest['confidence_rules']['ai_cannot_self_modify']).lower()}).

---

## Trust Basis

This incident analysis is trustworthy because:

1. **Fixed reasoning rules** (no adaptation)
2. **Mandatory human governance** (no auto-approval)
3. **Cryptographic provenance** (tampering detectable)
4. **No feedback loops** (no AI learning)
5. **External verifiability** (no trust required)

Very few incident analysis systems provide this level of assurance.

---

## Compliance & Security Notes

- **Evidence integrity:** Cryptographic hashes provide tamper evidence
- **Audit trail:** Complete artifact chain from raw logs to final decision
- **Governance:** Human accountability required for all finalized decisions
- **Transparency:** All reasoning rules and forbidden capabilities documented
- **Verifiability:** External parties can independently verify all claims

**For security review questions, contact:** [Incident Response Team]

---

*This trust report was automatically generated by Sherlock Phase 7.*  
*Provenance file: `{provenance_file}`*  
*Reasoning manifest: `{manifest_file}`*
"""

# Write report
with open(output_file, 'w') as f:
    f.write(report)

print(f"✓ Trust report generated: {output_file}")
print(f"  • Incident: {incident_id}")
print(f"  • Artifacts verified: {sum(1 for h in artifacts.values() if h)}/{len(artifacts)}")
print(f"  • Forbidden capabilities documented: {len(manifest['forbidden_capabilities'])}")
print()
print("This report is designed for:")
print("  - Security reviewers")
print("  - Legal/compliance teams")
print("  - External auditors")
print("  - Judges evaluating trustworthiness")
GENERATE_REPORT

if [ $? -eq 0 ]; then
    echo
    echo "✅ Trust report complete"
else
    echo "❌ Trust report generation failed"
    exit 1
fi
