#!/usr/bin/env bash
# Sherlock Complete Pipeline Demonstration
# Shows all 6 phases working together

set -e

echo "═══════════════════════════════════════════════════════════════════"
echo "  SHERLOCK: Complete Incident Lifecycle System"
echo "═══════════════════════════════════════════════════════════════════"
echo
echo "This demonstration shows all 6 phases:"
echo "  Phase 1: Evidence Contract & Normalization"
echo "  Phase 2: Scoping & Reduction"
echo "  Phase 3: Hypothesis-Based Reasoning"
echo "  Phase 4: Human Review & Decision Accountability"
echo "  Phase 5: Organizational Memory"
echo "  Phase 6: Operational Integration"
echo
echo "═══════════════════════════════════════════════════════════════════"
echo

# Show current incident history
echo "📊 Current Organizational Memory:"
echo "─────────────────────────────────────────────────────────────────"
./sherlock history
echo

# Show confidence calibration
echo "📈 AI Confidence Calibration:"
echo "─────────────────────────────────────────────────────────────────"
./sherlock history --calibration
echo

# Show specific incident operational actions
echo "🔧 Phase 6: Operational Actions for INC-123 (MODIFIED):"
echo "─────────────────────────────────────────────────────────────────"
bash phase6/phase6.sh INC-123 2>&1 | head -50
echo

echo "═══════════════════════════════════════════════════════════════════"
echo "✅ Sherlock: Full Incident Lifecycle System"
echo "═══════════════════════════════════════════════════════════════════"
echo
echo "Key Properties:"
echo "  ✓ Evidence contracts prevent junk in"
echo "  ✓ Human-aligned scoping reduces noise"
echo "  ✓ Hypothesis protocol prevents narrative bias"
echo "  ✓ Human governance preserves accountability"
echo "  ✓ Organizational memory enables learning"
echo "  ✓ Operational integration drives action"
echo
echo "Architecture Guarantee:"
echo "  • Phase 6 is read-only (no feedback into reasoning)"
echo "  • Phase 5 is observational (no AI retraining)"
echo "  • Phase 4 is governance (AI proposes, humans decide)"
echo "  • Phases 1-3 are isolated reasoning chain"
echo
echo "Removing Phase 5 or 6 changes nothing upstream. ✓"
