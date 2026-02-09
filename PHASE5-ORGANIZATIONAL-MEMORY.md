# Phase 5: Organizational Memory & Institutional Learning

## Core Principle

**Phase 5 is memory, not intelligence.**

This phase provides organizational learning without creating feedback loops that could bias AI reasoning. The governing rule: **removing Phase 5 must not change Phase 1-4 behavior.**

## Purpose

Phase 5 answers organizational questions after incidents are resolved:

- "Have we seen this before?"
- "Are we improving?"
- "Is AI overconfident?"
- "Do we keep failing the same way?"
- "Are humans always overriding AI?"

It does not improve individual RCAs. It improves the organization.

## Trigger Condition

Phase 5 only executes when Phase 4 review status is `FINALIZED`:

```yaml
approval:
  status: FINALIZED  # Required for Phase 5 write
```

If the review is `DRAFT`, incomplete, or rejected-but-not-finalized → **Phase 5 does nothing.**

This prevents:
- Polluted memory
- Premature learning
- Indecision capture

## Storage Model

**File-based, append-only YAML**

```
incidents/
├── INC-123.yaml
├── INC-124.yaml
├── INC-125.yaml
```

Each file = one finalized incident.

**Why YAML?**
- Git-trackable
- Diff-friendly
- Auditable
- Portable
- Zero infrastructure dependencies

## Incident Knowledge Record (IKR) Schema

Each IKR is a compressed index entry, not a full postmortem:

```yaml
# Incident Knowledge Record: INC-123
# Phase 5: Organizational Memory (Read-Only)
# This record does not influence future AI reasoning

incident_id: INC-123
date: 2025-01-27
service: storage_service

category: Resource
decision: MODIFIED

ai_confidence: 65
human_confidence: 80
confidence_delta: +15

primary_root_cause: "File descriptor exhaustion (specific resource type)"

signals:
  - resource_allocation_failure
  - io_error
  - process_crash

contributing_factors:
  - missing alerts
  - delayed detection

remediation_promises:
  - "Increase file descriptor limits in systemd unit file"
  - "Add health checks to detect allocation failures early"

evidence_quality:
  completeness: PARTIAL
  penalty: 15

reviewer_role: SRE
finalized_at: 2025-01-27T20:45:00Z

artifacts:
  review_record: reports/review-record-INC-123.yaml
  ai_postmortem: reports/post-mortem-INC-123.md
  scope_audit: reports/scope-audit-INC-123.json
```

This is institutional memory, not analysis.

## What Phase 5 Deliberately Excludes

Phase 5 NEVER stores:

❌ Raw logs  
❌ Hypotheses  
❌ Evidence details  
❌ Prompt text  
❌ Copilot output verbatim

**Why?**

Memory must be:
- Compact
- Searchable
- Stable
- Comparable across incidents

Details stay in Phase 3/4 artifacts (linked via `artifacts:` field).

## Append-Only Enforcement

**Rules:**

- If `incidents/INC-123.yaml` exists → **abort write**
- No overwrite
- No update
- No merge

If someone wants to change history:
- They create a new incident
- Or a follow-up incident

This preserves trust.

## Phase 5 Write Path (Mechanically)

When Phase 4 finalizes:

1. Read `review-record-INC-123.yaml`
2. Read `postmortem-INC-123.md`
3. Extract:
   - Root cause category
   - Signals
   - Confidence delta
   - Remediation items
4. Generate IKR
5. Write to `incidents/INC-123.yaml`
6. Log success

**No AI involved.**

## Phase 5 Read Path: History Queries

### Basic Command

```bash
./sherlock history
```

**Output:**

```
ID           | Service         | Category     | Conf | Decision   | Date      
─────────────────────────────────────────────────────────────────────────────
INC-123      | storage_service | Resource     | 80  % | MODIFIED   | 2025-01-27
INC-124      | api-gateway     | Config       | 75  % | ACCEPTED   | 2025-02-03
INC-125      | storage_service | Resource     | 45  % | REJECTED   | 2025-02-09

Total: 3 incident(s)
```

This alone is powerful.

### Supported Filters

Each filter answers a real organizational question:

```bash
# "Which storage_service incidents do we have?"
./sherlock history --service storage_service

# "How many Resource-category failures?"
./sherlock history --category Resource

# "Which analyses were modified by humans?"
./sherlock history --decision MODIFIED

# "Which RCAs had low confidence?"
./sherlock history --confidence-below 60

# "Have we seen resource_allocation_failure before?"
./sherlock history --signal resource_allocation_failure
```

**Example: Service Filter**

```bash
$ ./sherlock history --service storage_service

ID           | Service         | Category     | Conf | Decision   | Date      
─────────────────────────────────────────────────────────────────────────────
INC-123      | storage_service | Resource     | 80  % | MODIFIED   | 2025-01-27
INC-125      | storage_service | Resource     | 45  % | REJECTED   | 2025-02-09

Total: 2 incident(s)
```

**Example: Signal Filter**

```bash
$ ./sherlock history --signal resource_allocation_failure

ID           | Service         | Category     | Conf | Decision   | Date      
─────────────────────────────────────────────────────────────────────────────
INC-123      | storage_service | Resource     | 80  % | MODIFIED   | 2025-01-27

Total: 1 incident(s)

Incidents with signal 'resource_allocation_failure':
  • INC-123: File descriptor exhaustion (specific resource type)
```

### Confidence Calibration Analysis

**Command:**

```bash
./sherlock history --calibration
```

**Example Output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Confidence Calibration Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
AI confidence average:     74.0%
Human confidence average:  66.7%
Mean delta:                -7.3%
Total incidents:           3

⚠️  AI systematically underconfident
```

**This is gold:**
- Shows humility
- Shows measurement
- Shows maturity

And still: **No feedback into AI.**

## What Phase 5 Explicitly Does NOT Do

❌ No retraining  
❌ No hypothesis weighting  
❌ No prompt tuning  
❌ No "learning"  
❌ No future biasing

Phase 5 is **observational, not corrective.**

## Why This Design Survives Real Scrutiny

If a security, legal, or SRE reviewer asks:

> "Can historical incidents bias future RCAs?"

Your answer:

> "No. Phase 5 is strictly read-only and disconnected from reasoning."

That's the right answer.

## Mental Model

| Phase | Role |
|-------|------|
| Phase 3 | Reason |
| Phase 4 | Decide |
| Phase 5 | Remember |

**Never mix them.**

## When Phase 5 is "Done"

Phase 5 is complete when:

✅ Incidents are written only after FINALIZED review  
✅ Records are append-only  
✅ History queries work  
✅ Calibration works  
✅ Removing Phase 5 does not change Phase 1–4 behavior

At that point, Sherlock is **institution-grade.**

## What This Unlocks (Future, Optional)

Not implementation now, but capability:

- Org-level retrospectives
- Repeat failure detection
- AI trust reporting
- Incident trend analysis
- Governance audits

All without touching reasoning.

## File Modifications

### sherlock (lines 4-230)
- History command entry point
- Filter parsing (--service, --category, --decision, --confidence-below, --signal, --calibration)
- Python script for IKR parsing and display
- Calibration analysis logic

### sherlock (lines 1615-1822)
- Phase 5 write trigger (only if `approval: FINALIZED`)
- Append-only check
- IKR generation from review record + postmortem
- Success confirmation message

## Example Files

- [incidents/INC-123.yaml](incidents/INC-123.yaml) - MODIFIED decision, confidence +15%
- [incidents/INC-124.yaml](incidents/INC-124.yaml) - ACCEPTED decision, well-calibrated
- [incidents/INC-125.yaml](incidents/INC-125.yaml) - REJECTED decision, confidence -37%

## Testing

```bash
# List all incidents
./sherlock history

# Filter by service
./sherlock history --service storage_service

# Filter by category
./sherlock history --category Resource

# Filter by decision type
./sherlock history --decision MODIFIED

# Filter by confidence threshold
./sherlock history --confidence-below 60

# Filter by signal
./sherlock history --signal resource_allocation_failure

# Calibration analysis
./sherlock history --calibration
```

## Impact

With Phase 5:

- Sherlock is no longer "an AI RCA tool"
- It is a **complete incident reasoning system**
  - With governance
  - With memory
  - With accountability

Very few systems get this right.

## Final Status

Phase 5 implementation complete:

✅ Write path (only after FINALIZED)  
✅ Append-only enforcement  
✅ IKR schema (compressed, searchable)  
✅ History command  
✅ 6 filters (service, category, decision, confidence, signal, calibration)  
✅ Calibration analysis  
✅ Zero influence on reasoning
