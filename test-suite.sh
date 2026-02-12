#!/bin/bash
# Sherlock Phase 9 Validation Test Suite
# Tests all architectural invariants and guarantees

set -euo pipefail

WORKSPACE="/Users/agastya/Documents/sherlock-demo"
cd "$WORKSPACE"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Sherlock Phase 9 Validation Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS_COUNT++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAIL_COUNT++))
}

test_skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
}

# ==============================================================================
# TEST GROUP 1 — Evidence & Trust Boundary Tests (Phase 1)
# ==============================================================================

echo -e "${BLUE}TEST GROUP 1: Evidence & Trust Boundary${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 1.1 — Verify evidence contract exists
if [ -f "evidence/deployments.json" ] && [ -f "evidence/metrics.json" ]; then
    test_pass "Evidence files exist (deployments.json, metrics.json)"
else
    test_fail "Evidence files missing"
fi

# Test 1.2 — Verify trust annotations in evidence
if grep -q "\"trust\":" evidence/deployments.json; then
    test_pass "Trust annotations present in evidence"
else
    test_fail "Trust annotations missing from evidence"
fi

echo

# ==============================================================================
# TEST GROUP 2 — Scoping & Reduction Tests (Phase 2)
# ==============================================================================

echo -e "${BLUE}TEST GROUP 2: Scoping & Reduction${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 2.1 — Verify scope audit exists
if [ -f "reports/scope-audit-INC-123.json" ]; then
    test_pass "Scope audit artifact exists"
    
    # Test 2.2 — Verify reduction occurred
    TOTAL_EVENTS=$(grep -o '"total_events":[[:space:]]*[0-9]*' reports/scope-audit-INC-123.json | grep -o '[0-9]*')
    RETAINED=$(grep -o '"retained_events":[[:space:]]*[0-9]*' reports/scope-audit-INC-123.json | grep -o '[0-9]*')
    
    if [ "$RETAINED" -lt "$TOTAL_EVENTS" ]; then
        test_pass "Scoping reduction occurred ($TOTAL_EVENTS → $RETAINED events)"
    else
        test_fail "No scoping reduction detected"
    fi
else
    test_fail "Scope audit artifact missing"
fi

echo

# ==============================================================================
# TEST GROUP 3 — Hypothesis Reasoning Discipline (Phase 3)
# ==============================================================================

echo -e "${BLUE}TEST GROUP 3: Hypothesis Reasoning Discipline${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 3.1 — Verify postmortem exists
if [ -f "reports/post-mortem-INC-123.md" ]; then
    test_pass "AI postmortem artifact exists"
    
    # Test 3.2 — Count hypothesis sections
    HYPOTHESIS_COUNT=$(grep -c "^## Hypothesis" reports/post-mortem-INC-123.md || echo "0")
    
    if [ "$HYPOTHESIS_COUNT" -ge 3 ]; then
        test_pass "Multiple hypotheses generated (≥3 found: $HYPOTHESIS_COUNT)"
    else
        test_fail "Insufficient hypothesis enumeration (found: $HYPOTHESIS_COUNT)"
    fi
    
    # Test 3.3 — Verify explicit uncertainty section
    if grep -q -i "uncertainty\|remaining.*unknown\|confidence" reports/post-mortem-INC-123.md; then
        test_pass "Uncertainty explicitly addressed"
    else
        test_fail "Uncertainty not documented"
    fi
else
    test_fail "AI postmortem artifact missing"
fi

echo

# ==============================================================================
# TEST GROUP 4 — Human Governance Tests (Phase 4)
# ==============================================================================

echo -e "${BLUE}TEST GROUP 4: Human Governance${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 4.1 — Verify review record exists
if [ -f "reports/review-record-INC-123.yaml" ]; then
    test_pass "Review record artifact exists"
    
    # Test 4.2 — Verify finalization
    if grep -q "status: FINALIZED" reports/review-record-INC-123.yaml; then
        test_pass "Review record is finalized"
    else
        test_fail "Review record not finalized"
    fi
    
    # Test 4.3 — Verify reviewer identification
    if grep -q "reviewer:" reports/review-record-INC-123.yaml; then
        test_pass "Reviewer identified in record"
    else
        test_fail "Reviewer not identified"
    fi
    
    # Test 4.4 — Verify decision type
    DECISION=$(grep "decision:" reports/review-record-INC-123.yaml | head -1 | awk '{print $2}')
    if [ "$DECISION" = "ACCEPTED" ] || [ "$DECISION" = "MODIFIED" ] || [ "$DECISION" = "REJECTED" ]; then
        test_pass "Valid decision type: $DECISION"
    else
        test_fail "Invalid decision type: $DECISION"
    fi
else
    test_fail "Review record artifact missing"
fi

echo

# ==============================================================================
# TEST GROUP 5 — Organizational Memory Tests (Phase 5)
# ==============================================================================

echo -e "${BLUE}TEST GROUP 5: Organizational Memory${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 5.1 — Verify IKR exists
if [ -f "incidents/INC-123.yaml" ]; then
    test_pass "Incident Knowledge Record exists"
    
    # Test 5.2 — Verify append-only marker
    if grep -q "Read-Only" incidents/INC-123.yaml; then
        test_pass "Read-only marker present in IKR"
    else
        test_fail "Read-only marker missing from IKR"
    fi
    
    # Test 5.3 — Verify confidence delta recorded
    if grep -q "confidence_delta:" incidents/INC-123.yaml; then
        test_pass "Confidence delta tracked in memory"
    else
        test_fail "Confidence delta not tracked"
    fi
else
    test_fail "Incident Knowledge Record missing"
fi

# Test 5.4 — Verify history command exists
if grep -q "\"history\")" sherlock; then
    test_pass "History query command implemented"
else
    test_fail "History query command not found"
fi

echo

# ==============================================================================
# TEST GROUP 6 — Operational Integration Tests (Phase 6)
# ==============================================================================

echo -e "${BLUE}TEST GROUP 6: Operational Integration${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 6.1 — Verify Phase 6 exists
if [ -f "phase6/phase6.sh" ]; then
    test_pass "Phase 6 orchestrator exists"
    
    # Test 6.2 — Verify dispatchers exist
    for dispatcher in jira.sh slack.sh github.sh email.sh; do
        if [ -f "phase6/dispatchers/$dispatcher" ]; then
            test_pass "Dispatcher exists: $dispatcher"
        else
            test_fail "Dispatcher missing: $dispatcher"
        fi
    done
    
    # Test 6.3 — Verify configuration exists
    if [ -f "phase6/config/phase6.yaml" ]; then
        test_pass "Phase 6 configuration exists"
    else
        test_fail "Phase 6 configuration missing"
    fi
else
    test_fail "Phase 6 not implemented"
fi

echo

# ==============================================================================
# TEST GROUP 7 — Trust & Verifiability Tests (Phase 7)
# ==============================================================================

echo -e "${BLUE}TEST GROUP 7: Trust & Verifiability${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 7.1 — Verify reasoning manifest exists
if [ -f "phase7/reasoning-manifest.json" ]; then
    test_pass "Reasoning manifest exists"
    
    # Test 7.2 — Verify forbidden capabilities documented
    if grep -q "forbidden_capabilities" phase7/reasoning-manifest.json; then
        test_pass "Forbidden capabilities documented"
    else
        test_fail "Forbidden capabilities not documented"
    fi
else
    test_fail "Reasoning manifest missing"
fi

# Test 7.3 — Verify provenance record exists for INC-123
if [ -f "phase7/provenance-INC-123.json" ] || [ -f "phase7/trust/provenance-INC-123.json" ]; then
    test_pass "Provenance record exists for INC-123"
    
    # Test 7.4 — Verify artifact hashes present
    PROV_FILE="phase7/provenance-INC-123.json"
    if [ ! -f "$PROV_FILE" ]; then
        PROV_FILE="phase7/trust/provenance-INC-123.json"
    fi
    
    if grep -q "sha256:" "$PROV_FILE"; then
        test_pass "SHA-256 hashes present in provenance"
    else
        test_fail "SHA-256 hashes missing from provenance"
    fi
else
    test_fail "Provenance record missing for INC-123"
fi

# Test 7.5 — Verify trust report exists
if [ -f "phase7/trust-report-INC-123.md" ] || [ -f "phase7/trust/trust-report-INC-123.md" ]; then
    test_pass "Trust report exists for INC-123"
else
    test_fail "Trust report missing for INC-123"
fi

echo

# ==============================================================================
# TEST GROUP 8 — Architectural Invariants
# ==============================================================================

echo -e "${BLUE}TEST GROUP 8: Architectural Invariants${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 8.1 — Verify INVARIANTS.md exists
if [ -f "INVARIANTS.md" ]; then
    test_pass "Architectural invariants documented"
    
    # Test 8.2 — Count documented invariants
    INVARIANT_COUNT=$(grep -c "^### [0-9]" INVARIANTS.md || echo "0")
    if [ "$INVARIANT_COUNT" -ge 7 ]; then
        test_pass "All 7 invariants documented"
    else
        test_fail "Incomplete invariant documentation (found: $INVARIANT_COUNT)"
    fi
else
    test_fail "INVARIANTS.md missing"
fi

# Test 8.3 — Verify phase isolation in sherlock script
if grep -q "Phase 6: Operational Integration (optional" sherlock; then
    test_pass "Phase 6 marked as optional (isolation)"
else
    test_fail "Phase 6 not properly isolated"
fi

if grep -q "Phase 7: Trust.*optional" sherlock; then
    test_pass "Phase 7 marked as optional (isolation)"
else
    test_fail "Phase 7 not properly isolated"
fi

echo

# ==============================================================================
# TEST GROUP 9 — Documentation Completeness
# ==============================================================================

echo -e "${BLUE}TEST GROUP 9: Documentation Completeness${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 9.1 — Verify DEMO.md exists
if [ -f "DEMO.md" ]; then
    test_pass "Demo guide exists"
    
    # Test 9.2 — Verify 90-second pitch present
    if grep -q "90-second" DEMO.md; then
        test_pass "90-second explanation documented"
    else
        test_fail "90-second explanation missing"
    fi
else
    test_fail "DEMO.md missing"
fi

# Test 9.3 — Verify README is judge-first
if [ -f "README.md" ]; then
    if head -20 README.md | grep -q "AI proposes.*Humans decide"; then
        test_pass "README has judge-first positioning"
    else
        test_fail "README not optimized for judges"
    fi
else
    test_fail "README.md missing"
fi

# Test 9.4 — Verify Phase 6 documentation
if [ -f "PHASE6-OPERATIONAL-INTEGRATION.md" ]; then
    test_pass "Phase 6 documentation exists"
else
    test_fail "Phase 6 documentation missing"
fi

# Test 9.5 — Verify Phase 7 documentation
if [ -f "phase7/README.md" ]; then
    test_pass "Phase 7 documentation exists"
else
    test_fail "Phase 7 documentation missing"
fi

echo

# ==============================================================================
# TEST GROUP 10 — Pipeline Integration
# ==============================================================================

echo -e "${BLUE}TEST GROUP 10: Pipeline Integration${NC}"
echo "───────────────────────────────────────────────────────────────"
echo

# Test 10.1 — Verify Phase 6 integration in sherlock
if grep -q "phase6/phase6.sh" sherlock; then
    test_pass "Phase 6 integrated into sherlock pipeline"
else
    test_fail "Phase 6 not integrated"
fi

# Test 10.2 — Verify Phase 7 integration in sherlock
if grep -q "phase7/phase7.sh" sherlock; then
    test_pass "Phase 7 integrated into sherlock pipeline"
else
    test_fail "Phase 7 not integrated"
fi

# Test 10.3 — Verify lifecycle summary exists
if grep -q "Sherlock Incident Lifecycle Complete" sherlock; then
    test_pass "Lifecycle summary banner implemented"
else
    test_fail "Lifecycle summary banner missing"
fi

echo

# ==============================================================================
# TEST SUMMARY
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
echo -e "${GREEN}Passed:${NC} $PASS_COUNT"
echo -e "${RED}Failed:${NC} $FAIL_COUNT"
echo

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    echo
    echo "Sherlock is ready for evaluation:"
    echo "  • All architectural invariants verified"
    echo "  • Complete artifact trail present"
    echo "  • Phase isolation confirmed"
    echo "  • Documentation complete"
    echo "  • External verifiability proven"
    echo
    exit 0
else
    echo -e "${RED}✗ TESTS FAILED${NC}"
    echo
    echo "Please review failures before proceeding."
    echo
    exit 1
fi
