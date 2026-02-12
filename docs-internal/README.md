# Sherlock Internal Documentation

This directory contains **implementation details, validation reports, and deep-dive documentation**.

**If you're a judge or evaluator, you probably don't need to read this.**  
The judge-facing documentation is at the repository root:
- [README.md](../README.md) - Quick start
- [DEMO.md](../DEMO.md) - Demo walkthrough
- [DESIGN.md](../DESIGN.md) - System architecture
- [INVARIANTS.md](../INVARIANTS.md) - Architectural guarantees
- [LIMITATIONS.md](../LIMITATIONS.md) - Honest constraints

---

## Directory Structure

### `/docs-internal/phases/` - Phase Implementation Details

Deep dives on specific pipeline phases:

| Document | Phase | Topic |
|----------|-------|-------|
| [phase1-evidence-contract.md](phases/phase1-evidence-contract.md) | Phase 1 | Evidence validation |
| [phase2-scoping-reduction.md](phases/phase2-scoping-reduction.md) | Phase 2 | Noise reduction |
| [phase3-hypothesis-reasoning.md](phases/phase3-hypothesis-reasoning.md) | Phase 3 | AI hypothesis generation |
| [phase4-governance.md](phases/phase4-governance.md) | Phase 4 | Human review |
| [phase5-memory.md](phases/phase5-memory.md) | Phase 5 | Organizational memory |
| [phase6-operational.md](phases/phase6-operational.md) | Phase 6 | JIRA, Slack, GitHub integration |
| [phase8-freeze.md](phases/phase8-freeze.md) | Phase 8 | Architecture freeze |

**Audience:** Engineers implementing similar systems  
**Purpose:** Implementation patterns, dispatcher architecture, phase isolation

**Note:** Phase 7 (Trust & Verification) implementation is in [adapters/trust-verification/](../adapters/trust-verification/)

### `/docs-internal/governance/` - Enterprise Enhancements

Production-grade governance features:

| Document | Enhancement | Topic |
|----------|-------------|-------|
| [service-ownership.md](governance/service-ownership.md) | Part 1 | Authority gating, reviewer enforcement |
| [multi-service-incidents.md](governance/multi-service-incidents.md) | Part 2 | Service coordination without sovereignty violation |
| [lifecycle-model.md](governance/lifecycle-model.md) | Part 3 | Incident state machine, phase gating |
| [enterprise-enhancements.md](governance/enterprise-enhancements.md) | Overview | All three enhancements |

**Audience:** Enterprise architects, compliance team  
**Purpose:** How Sherlock enforces organizational policies mechanically

### `/docs-internal/validation/` - Test Reports & Verification

Validation and test suite documentation:

| Document | Type | Topic |
|----------|------|-------|
| [validation-report.md](validation/validation-report.md) | Test Suite | Comprehensive feature validation |

**Audience:** QA engineers, auditors  
**Purpose:** Verify that system behaves as documented

---

## Why This Structure?

**Problem:** Most hackathon projects dump 15+ markdown files at the repository root.  
**Effect:** Judges spend 10 minutes figuring out what to read, then give up.

**Sherlock's approach:**
- **5 files at root** for judges (understand, run, evaluate)
- **Everything else in /docs-internal** for engineers who want to implement similar systems

**Design principle:**  
> "If a document is not required to understand, run, or judge the project, it must be hidden from the default reading path."

This is that hidden path. If you're here, you're deep diving.

---

## Reading Order (For Engineers)

If you want to understand **how Sherlock was built**:

1. Start with root [DESIGN.md](../DESIGN.md) - Architecture overview
2. Read [governance/service-ownership.md](governance/service-ownership.md) - Part 1 enhancement
3. Read [governance/multi-service-incidents.md](governance/multi-service-incidents.md) - Part 2 enhancement
4. Read [governance/lifecycle-model.md](governance/lifecycle-model.md) - Part 3 enhancement
5. Read [phases/phase6-operational.md](phases/phase6-operational.md) - Phase 6 details
6. Read [phases/phase7-trust.md](phases/phase7-trust.md) - Phase 7 details
7. Read [validation/validation-report.md](validation/validation-report.md) - Test coverage

**Total reading time:** ~45 minutes for complete system understanding.

---

## For Auditors

If you're verifying **architectural claims**:

1. [INVARIANTS.md](../INVARIANTS.md) - The 7 guarantees
2. [phases/phase8-freeze.md](phases/phase8-freeze.md) - Feature freeze commitment
3. [validation/validation-report.md](validation/validation-report.md) - Test verification
4. [phases/phase7-trust.md](phases/phase7-trust.md) - External verification process

These documents let you verify Sherlock's claims without trusting Sherlock.

---

## Contributing Updates

**Rule:** New implementation details go in `/docs`, not at root.

**Judge-facing updates** (root files):
- README: Quick start instructions
- DEMO: Demo script changes
- DESIGN: Core architecture (7 phases + 3 enhancements)
- INVARIANTS: Architectural guarantees
- LIMITATIONS: Honest constraints

**Engineer-facing updates** (this directory):
- `/phases`: Phase implementation patterns
- `/governance`: Enterprise enhancement deep-dives
- `/validation`: Test reports, verification procedures

When in doubt: **If not required to judge the project, put it in /docs-internal.**

---

## Questions?

This structure is designed around **three audiences**:

1. **Judges** (5 minutes): Root files only, especially DEMO.md
2. **Engineers** (30 minutes): Root + /docs/governance + /docs/phases
3. **Auditors** (60 minutes): Everything, especially /docs/validation

If you can't find what you're looking for, check the root [README.md](../README.md) first.
