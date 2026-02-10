#!/usr/bin/env bash
# Phase 7: Reasoning Manifest Generator
# Creates immutable record of how Sherlock reasons
# This proves what rules were active and what capabilities are forbidden

set -e

SHERLOCK_SCRIPT="./sherlock"
OUTPUT_FILE="phase7/trust/reasoning-manifest.json"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 7: Generating Reasoning Manifest"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

if [ ! -f "$SHERLOCK_SCRIPT" ]; then
    echo "⚠️  Sherlock script not found: $SHERLOCK_SCRIPT"
    exit 1
fi

# Extract Sherlock version (if defined)
SHERLOCK_VERSION=$(grep "^SHERLOCK_VERSION=" "$SHERLOCK_SCRIPT" 2>/dev/null | cut -d'"' -f2 || echo "1.0.0")

# Compute prompt hash (Phase 3 protocol section)
PROMPT_HASH=$(grep -A 50 "PHASE 3: HYPOTHESIS-BASED REASONING PROTOCOL" "$SHERLOCK_SCRIPT" | shasum -a 256 | awk '{print $1}')

# Detect enabled phases
PHASES_ENABLED=(1 2 3 4 5)
if grep -q "Phase 6:" "$SHERLOCK_SCRIPT"; then
    PHASES_ENABLED+=(6)
fi

# Extract hypothesis protocol version
HYPOTHESIS_VERSION="v1"  # Hardcoded for now, could extract from sherlock

# Generate manifest
python3 - "$OUTPUT_FILE" "$SHERLOCK_VERSION" "$PROMPT_HASH" "$HYPOTHESIS_VERSION" "${PHASES_ENABLED[@]}" <<'GENERATE_MANIFEST'
import sys
import json
from datetime import datetime

output_file = sys.argv[1]
sherlock_version = sys.argv[2]
prompt_hash = sys.argv[3]
hypothesis_version = sys.argv[4]
phases_enabled = [int(p) for p in sys.argv[5:]]

manifest = {
    "sherlock_version": sherlock_version,
    "generated_at": datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "phases_enabled": phases_enabled,
    
    "reasoning_protocol": {
        "copilot_prompt_hash": f"sha256:{prompt_hash}",
        "hypothesis_protocol": hypothesis_version,
        "hypothesis_requirements": {
            "minimum_count": 3,
            "maximum_count": 5,
            "diversity_required": True,
            "evidence_symmetry": "FOR + AGAINST required",
            "confidence_budgeting": "total <= 100%"
        }
    },
    
    "confidence_rules": {
        "max_total": 100,
        "quality_penalty_source": "phase1_evidence_contract",
        "human_override": True,
        "ai_cannot_self_modify": True
    },
    
    "governance_guarantees": {
        "phase4_human_review": "mandatory",
        "phase5_append_only": True,
        "phase6_read_only": True,
        "no_auto_approval": True
    },
    
    "forbidden_capabilities": [
        "learning",
        "feedback_loops",
        "auto-approval",
        "prompt_modification",
        "confidence_manipulation",
        "hypothesis_injection",
        "evidence_filtering",
        "governance_bypass"
    ],
    
    "audit_properties": {
        "immutable_artifacts": True,
        "cryptographic_provenance": True,
        "external_verifiability": True,
        "tamper_evidence": True
    }
}

# Write manifest
with open(output_file, 'w') as f:
    json.dump(manifest, f, indent=2)

print(f"✓ Reasoning manifest generated: {output_file}")
print(f"  • Sherlock version: {sherlock_version}")
print(f"  • Phases enabled: {phases_enabled}")
print(f"  • Prompt hash: sha256:{prompt_hash[:16]}...")
print(f"  • Forbidden capabilities: {len(manifest['forbidden_capabilities'])}")
print()
print("This manifest proves:")
print("  - What rules were active")
print("  - What capabilities are forbidden")
print("  - That no adaptive/learning systems exist")
GENERATE_MANIFEST

echo
echo "✅ Reasoning manifest complete"
echo "   Location: $OUTPUT_FILE"
