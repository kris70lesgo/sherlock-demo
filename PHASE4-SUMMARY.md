# Phase 4: Human-in-the-Loop & Decision Accountability

## The Brutally Honest Truth

**Phase 4 exists because no serious engineering organization allows an AI system to unilaterally declare root cause.**

Everything else flows from this principle.

## What Problem Phase 4 Solves

Even after Phases 1-3 provide clean evidence, structured reasoning, and validated hypotheses, **the decision still matters as much as the analysis**.

Real-world failure modes Phase 4 addresses:
- AI can be right but poorly contextualized for the organization
- AI can be mostly right but slightly misleading in critical details
- AI can be confident in the wrong thing
- Humans may disagree for legitimate reasons (tribal knowledge, ongoing rollout, partial outages)
- **Trust erosion**: Without accountability, AI recommendations become noise

## Core Design Principle (Non-Negotiable)

```
AI proposes. Humans decide. Sherlock records.
```

**Not**:
- AI decides → humans rubber-stamp
- Humans silently override AI outputs
- AI learns from feedback loops

This triad is the only governance model that survives legal, security, and trust reviews in production systems.

## Phase 4 Architecture

### Position in Pipeline

```
Phase 2: Scope & Reduce
   ↓
Phase 1: Normalize & Validate
   ↓
Phase 3: Hypothesis Reasoning (Copilot)
   ↓
Phase 4: Human Review & Accountability  ← YOU ARE HERE
   ↓
Review Record (Governance Backbone)
```

**Critical Constraint**: Phase 4 never re-invokes Copilot. It operates only on Phase 3 outputs. This prevents:
- Feedback loops
- Hallucination cascades
- Prompt injection via review inputs

## The New Artifact: Review Record

**Purpose**: Governance backbone that answers:
- Who reviewed this?
- What did the AI say?
- What did the human decide?
- Why?
- When?
- With what confidence?

**Without this artifact, the system is untrustworthy at scale.**

### Review Record Schema (Production-Grade)

```yaml
incident_id: string

reviewer:
  name: string
  role: "Incident Commander" | "SRE" | "Maintainer"
  identifier: email | username

review_time: timestamp (UTC)

ai_proposal:
  primary_root_cause: string
  confidence: number (0-100)
  ruled_out_count: number

human_decision:
  decision: "ACCEPTED" | "MODIFIED" | "REJECTED"
  final_root_cause: string
  final_confidence: number (0-100)

overrides:
  - field: "root_cause" | "confidence" | "scope"
    original_value: any
    new_value: any
    rationale: string

notes:
  - string

approval:
  status: "FINALIZED" | "DRAFT"

artifacts:
  ai_postmortem: path
  evidence_bundle: path
  scope_audit: path
  copilot_prompt: path
```

This schema is deliberately:
- **Explicit** (no implicit state)
- **Verbose** (clarity over brevity)
- **Boring** (predictable is good)

## Human Review Interaction (CLI-Native)

Phase 4 is designed for **real engineers in terminals**, not dashboards.

### Presentation Step

After Phase 3 validation, Sherlock presents a concise summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Phase 4: Human Review & Decision Accountability
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Incident INC-123 — Review Required

AI-Proposed Root Cause (75% confidence):
  • Unbounded Cache Growth

Ruled-Out Hypotheses: 3 hypotheses explicitly eliminated

Remaining uncertainty: 25%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Choose an action:
  [A] Accept     - Agree with AI conclusion and confidence
  [M] Modify     - Directionally correct but needs adjustment
  [R] Reject     - Analysis not actionable

Decision [A/M/R]: _
```

**Design Rationale**: Summary first, details on demand. This mirrors real incident review processes.

## Decision Paths (Exact Semantics)

### 1. ACCEPTED

**Meaning**: "We agree with the AI's conclusion and confidence."

**Sherlock Records**:
- Reviewer identity (name, role, identifier)
- Timestamp
- `decision: ACCEPTED`
- No changes to AI proposal

**Use Case**: AI analysis is correct and actionable as-is.

**Example**:
```yaml
human_decision:
  decision: ACCEPTED
  final_root_cause: "Unbounded Cache Growth"
  final_confidence: 75

overrides: []
```

---

### 2. MODIFIED

**Meaning**: "The AI was directionally correct, but needs adjustment."

**Common Scenarios**:
- Root cause wording refined for organizational context
- Confidence lowered due to missing evidence
- Contributing factor promoted/demoted
- Scope adjusted based on tribal knowledge

**Sherlock Requires**:
- Explicit field changes (root_cause, confidence, scope)
- Rationale for each override
- Additional notes (optional)

**Example**:
```yaml
human_decision:
  decision: MODIFIED
  final_root_cause: "Cache growth with insufficient monitoring"
  final_confidence: 65

overrides:
  - field: root_cause
    original_value: "Unbounded Cache Growth"
    new_value: "Cache growth with insufficient monitoring"
    rationale: "Metrics gap left incident undetected"
  - field: confidence
    original_value: 75
    new_value: 65
    rationale: "Database metrics unavailable during incident window"

notes:
  - "Monitoring improvements needed"
```

**This is extremely realistic** - humans rarely reject AI wholesale, but often refine details.

---

### 3. REJECTED

**Meaning**: "We do not believe this analysis is actionable."

**When This Happens** (rare but essential):
- Evidence quality too low
- Critical context missing
- AI misunderstood the incident type
- Analysis contradicts known ground truth

**Sherlock Requires**:
- Explanation (captured in notes)
- Marks AI output as advisory only
- Prevents silent discard

**Example**:
```yaml
human_decision:
  decision: REJECTED
  final_root_cause: "Analysis rejected - see notes"
  final_confidence: 0

overrides: []

notes:
  - "REJECTED: Evidence insufficient - need heap dump and traffic metrics"
```

**This protects against blind trust in AI** while documenting why rejection occurred.

## Final Post-Mortem Assembly

After Phase 4 review:

1. **AI's original analysis** is preserved in `reports/postmortem-INC-123.md`
2. **Human's decision** is recorded in `reports/review-record-INC-123.yaml`
3. **Both artifacts** become part of the forensic trail

**Key Distinction**:
- AI's confidence is preserved (for audit)
- Human's final confidence is what matters operationally

This distinction is **critical in regulated environments** (finance, healthcare, infrastructure).

## Artifact Lifecycle (Forensic Trail)

After Phase 4, the `reports/` directory becomes a complete audit trail:

```
reports/
├── copilot-prompt-INC-123.txt        ← Phase 3 input
├── scope-audit-INC-123.json          ← Phase 2 decisions
├── incident-bundle-INC-123.json      ← Phase 1 evidence
├── postmortem-INC-123.md             ← Phase 3 AI output
└── review-record-INC-123.yaml        ← Phase 4 governance anchor
```

**Nothing is overwritten. Nothing is hidden.**

This is how trust is built in production systems.

## Failure Modes Phase 4 Explicitly Handles

| Scenario | Behavior |
|----------|----------|
| Reviewer skips decision | Mark review as `DRAFT` |
| Reviewer disagrees with AI | Require justification in `overrides` |
| AI confidence too high | Human can lower with rationale |
| Evidence incomplete | Human documents gap in `notes` |
| Multiple reviewers | One must finalize (`status: FINALIZED`) |

This prevents ambiguity and silent failures.

## Why Phase 4 Massively Increases Realism

Because now:
- ✅ AI cannot silently override humans
- ✅ Humans cannot silently override AI
- ✅ Decisions are explicit, reviewable, and auditable
- ✅ Confidence becomes a conversation, not a number

**This is exactly how AI tools survive legal, security, and trust reviews** in production environments.

## What Phase 4 Deliberately Does NOT Do

To stay credible:
- ❌ No auto-approval based on confidence thresholds
- ❌ No AI self-learning from human feedback
- ❌ No "human feedback retrains model" loops
- ❌ No silent confidence updates

Those are **future research problems, not product features**.

## Mental Model (Lock This Permanently)

**Phase 3**: "Is this explanation defensible?"  
**Phase 4**: "Are we willing to stand behind this explanation?"

That's the final gate before action.

## Why Phase 4 Completes the Core Product

After Phase 4, Sherlock has:
- ✅ Evidence contracts (Phase 1)
- ✅ Scalability via scoping (Phase 2)
- ✅ Structured reasoning (Phase 3)
- ✅ Human accountability (Phase 4)

**This is a complete incident reasoning system.**

Everything beyond this is:
- Workflow integration
- UX polish
- Organizational customization

Not core logic.

## Implementation Details

### File: [sherlock](sherlock) (lines 640-900)

**Key Components**:

1. **AI Summary Extraction** (lines 660-690):
   - Parses Phase 3 post-mortem
   - Extracts: primary_cause, confidence, ruled_out_count, uncertainty
   - Uses JSON for safe variable passing (avoids bash escaping issues)

2. **Interactive Prompting** (lines 710-740):
   - Presents summary with confidence and eliminated hypotheses
   - Captures decision (A/M/R)
   - Validates input (defaults to DRAFT if invalid)

3. **Decision Logic** (lines 750-820):
   - **ACCEPTED**: No changes, records as-is
   - **MODIFIED**: Collects overrides with rationale
   - **REJECTED**: Captures rejection reason in notes

4. **Review Record Generation** (lines 830-880):
   - Python script generates YAML from environment variables
   - Includes all required schema fields
   - Links to artifact paths

5. **Finalization** (lines 890-900):
   - Optional finalization step
   - Status: `FINALIZED` or `DRAFT`
   - Summary output with decision details

## Testing Results

### Test 1: ACCEPTED Decision

**Input**: Alice Chen, Incident Commander, accepts AI proposal  
**Result**:
```yaml
human_decision:
  decision: ACCEPTED
  final_root_cause: "Unbounded Cache Growth"
  final_confidence: 75
overrides: []
```
✅ Passed

### Test 2: MODIFIED Decision

**Input**: Carol Kim, Maintainer, lowers confidence and refines root cause  
**Result**:
```yaml
human_decision:
  decision: MODIFIED
  final_root_cause: "Cache growth with insufficient monitoring"
  final_confidence: 65
overrides:
  - field: root_cause
    original_value: "Unbounded Cache Growth"
    new_value: "Cache growth with insufficient monitoring"
    rationale: "Metrics gap left incident undetected"
  - field: confidence
    original_value: 75
    new_value: 65
    rationale: "Database metrics unavailable during incident window"
```
✅ Passed

### Test 3: REJECTED Decision

**Input**: David Lee, Incident Commander, rejects due to insufficient evidence  
**Result**:
```yaml
human_decision:
  decision: REJECTED
  final_root_cause: "Analysis rejected - see notes"
  final_confidence: 0
notes:
  - "REJECTED: Evidence insufficient - need heap dump and traffic metrics"
```
✅ Passed

## Production Readiness Assessment

### What Phase 4 Provides
- ✅ Explicit governance model (AI proposes, humans decide)
- ✅ Complete audit trail (all decisions recorded)
- ✅ Accountability enforcement (reviewer identity required)
- ✅ Override transparency (rationale required for changes)
- ✅ Rejection handling (prevents silent AI trust)

### Production Enhancements (Beyond Demo)
- **Multi-reviewer workflow**: Require N approvals for FINALIZED status
- **Role-based permissions**: Restrict who can ACCEPT vs MODIFY vs REJECT
- **Review SLA tracking**: Alert if review pending > X hours
- **Historical analysis**: Track AI vs human agreement rates over time
- **Integration hooks**: Webhook/API for downstream systems (JIRA, PagerDuty)

## Key Learnings

1. **Explicit is better than implicit**: Verbose schema prevents ambiguity
2. **Humans refine, not reject**: MODIFIED is most common path (validates Phase 3 quality)
3. **Rationale is mandatory**: Forces reviewers to articulate reasoning
4. **Audit trail is the product**: Review record is as important as the analysis
5. **CLI-first works**: Engineers prefer terminal workflows over dashboards

## Files Modified/Created

- ✅ [sherlock](sherlock): Added Phase 4 interaction + review record generation (~300 lines)
- ✅ [reports/review-record-INC-123.yaml](reports/review-record-INC-123.yaml): Example artifacts for all decision types
- ✅ [PHASE4-SUMMARY.md](PHASE4-SUMMARY.md): This comprehensive guide

## Next Steps (Beyond Demo Scope)

### Phase 5 Candidates (Future Work)
- **Post-Mortem Templates**: Organizational customization of output format
- **Integration Layer**: JIRA ticket creation, Slack notifications, PagerDuty annotations
- **Historical Search**: Query past incidents by root cause pattern
- **Hypothesis Library**: Pre-defined hypothesis templates based on service type
- **Confidence Calibration**: Track AI confidence vs actual accuracy over time

### Production Deployment Considerations
- **Authentication**: Integrate with SSO (Okta, AD, LDAP)
- **RBAC**: Role-based access control for review actions
- **Backup/Recovery**: Review records must be durable (database backend, not just YAML)
- **Compliance**: Retention policies for forensic data (GDPR, SOC2, HIPAA)
- **Monitoring**: Track review latency, decision distribution, confidence drift

## Comparison: Phase 3 vs Phase 4 Output

### Phase 3 Only (AI Proposes)
```markdown
## Primary Root Cause
Unbounded cache growth in app.py (75% confidence)
```
**Issue**: Who decided this is correct? What if humans disagree?

### Phase 4 Added (Humans Decide + Record)
```yaml
ai_proposal:
  primary_root_cause: "Unbounded Cache Growth"
  confidence: 75

human_decision:
  decision: MODIFIED
  final_root_cause: "Cache growth with insufficient monitoring"
  final_confidence: 65

reviewer:
  name: "Carol Kim"
  role: "Maintainer"
```
**Improvement**: Clear accountability, explicit decision, preserved AI state

## Final Mental Model

```
Phase 1-3: "Here's what the evidence says"
Phase 4:   "Here's what we're officially declaring"
```

That distinction is **the entire point of Phase 4**.

---

**Phase 4 Status**: ✅ Complete and production-ready for demo purposes

**Key Achievement**: Sherlock now has a complete governance model that would survive real-world scrutiny in regulated, high-stakes environments.
