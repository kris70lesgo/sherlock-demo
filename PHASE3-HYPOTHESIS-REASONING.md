# Phase 3: Hypothesis-Based Reasoning
## (With Real Hadoop Logs, Done Correctly)

**Purpose**: Force structured reasoning over abstractions, not pattern matching on telemetry. Enumerate, evaluate, eliminate, then conclude.

---

## 0. What Phase 3 Actually Is (Re-Grounding)

### Phase 3 is NOT:
- ❌ Pattern matching on log messages
- ❌ Anomaly detection
- ❌ Root cause guessing
- ❌ "LLM intelligence" or hallucination
- ❌ Statistical inference

### Phase 3 IS:
> **A reasoning protocol that forces the AI to consider, test, and eliminate multiple causal explanations using the scoped, validated evidence.**

**If Phase 2 answers "what is relevant?"**  
**Phase 3 answers "what explanations survive scrutiny?"**

---

##1. Phase 3's Single Responsibility (Lock This In)

**Enumerate plausible hypotheses, evaluate them symmetrically against evidence, eliminate weak explanations, and only then select a primary root cause with calibrated confidence.**

**Nothing else.**

---

## 2. Phase 3 Inputs (EXACT, Post Phase 2 + Phase 1)

By the time Phase 3 runs, it receives:

```json
{
  "logs": {
    "entries": [
      {
        "timestamp": "2015-03-16T23:17:47Z",
        "severity": "WARN",
        "component": "storage_service",
        "message": "resource_allocation_failure (count: 9)"
      },
      {
        "timestamp": "2015-03-16T23:17:58Z",
        "severity": "ERROR",
        "component": "storage_service",
        "message": "process_crash (count: 2)"
      }
    ]
  },
  "integrity": {
    "confidence_penalties": [
      {
        "source": "hadoop_logs",
        "reason": "No lifecycle events detected; Crash without clean shutdown",
        "penalty": -15
      }
    ]
  }
}
```

**Important Notes:**
- ✅ No Hadoop jargon (DataNode, HDFS, NameNode)
- ✅ No raw log messages
- ✅ No CSV format
- ✅ No vendor semantics

**This is generic failure telemetry.** Phase 3 reasons over abstractions.

---

## 3. Phase 3 Core Artifact: Hypothesis Set

Phase 3 forces Copilot to construct a **Hypothesis Set**, not jump to conclusions.

### Hypothesis Schema (Conceptual, Enforced by Prompt)

```yaml
Hypothesis:
  id: H1
  name: "Resource Exhaustion"
  category: Application | Resource | Infrastructure | Traffic | Dependency
  evidence_for: [string]
  evidence_against: [string]
  confidence: 0-100
  status: CONFIRMED | RULED_OUT | POSSIBLE
```

**Sherlock does not compute this.**  
**Sherlock enforces its existence and structure.**

---

## 4. Hypothesis Generation Rules (STRICT)

Copilot **MUST** generate **3-5 hypotheses**, spanning **distinct categories**.

### Example Hypotheses for Hadoop-Backed Incident

Even if some are obviously weak, they **must exist**. This prevents tunnel vision.

| Hypothesis | Category | Reason for Inclusion |
|------------|----------|---------------------|
| **Resource exhaustion** | Resource | Storage/memory pressure leading to crash |
| **Application-level fault** | Application | Unhandled error path, bug in error handling |
| **Dependency failure** | Dependency | Downstream service instability |
| **Infrastructure instability** | Infrastructure | Node crash, disk failure, network partition |
| **Traffic spike** | Traffic | Load-induced failure, retry storm |

**Key Point**: Even if "Traffic spike" has 0% confidence, it must be considered and explicitly ruled out.

---

## 5. Evidence Symmetry Requirement (CRITICAL)

For **every hypothesis**, Copilot must list:
1. **Evidence FOR** (supports the hypothesis)
2. **Evidence AGAINST** (contradicts or weakens it)

### Example: Traffic Spike Hypothesis

```markdown
### Hypothesis 4: Traffic Spike (Category: Traffic)

**Evidence FOR:**
- WARN-level resource allocation failures (9 occurrences)
- Process crash under potential load

**Evidence AGAINST:**
- No latency escalation observed in metrics
- No proportional error rate increase
- Failure occurred without traffic surge signal
- Resource failures happened over 10-second window (not sudden)

**Confidence:** 0%
**Status:** RULED_OUT
```

**If either side is missing, Sherlock flags the reasoning as invalid.**

This prevents **narrative bias** (finding only evidence that supports a pre-selected conclusion).

---

## 6. Confidence Budgeting (Non-Negotiable)

### Rules:
1. Each hypothesis gets a confidence score (0-100%)
2. **Total confidence ≤ 100%**
3. Unused confidence = explicit uncertainty
4. **Account for evidence quality penalties**

### Example Confidence Budget:

| Hypothesis | Confidence | Notes |
|------------|------------|-------|
| Resource exhaustion | 65% | Strong evidence from allocation failures + crash |
| Application bug | 10% | Possible error handling issue |
| Dependency failure | 5% | Weak evidence, no external service signals |
| Infra failure | 5% | Possible but no host-level errors |
| Traffic spike | 0% | Ruled out - no traffic surge |
| **Uncertainty** | **15%** | From quality penalty (-15%) + unknown factors |

**Total: 100%**

### Quality Penalty Integration:

The **15% confidence penalty** from Phase 1 (incomplete lifecycle coverage, crash without clean shutdown) flows into uncertainty:

```
Base uncertainty: 5% (unknown factors)
Quality penalty: -15% (incomplete evidence)
Total uncertainty: 20%

But confidence budget already allocated: 85%
So we adjust: Resource exhaustion drops to 65% to make room for 15% quality-driven uncertainty
```

**This is huge for realism.** It prevents overconfident RCA from incomplete evidence.

---

## 7. Explicit Elimination Step (MANDATORY)

Phase 3 **requires** Copilot to explicitly state:

> "The following hypotheses were considered and ruled out."

### Example:

```markdown
## Ruled-Out Hypotheses

### Traffic Spike (0% confidence)
**Reason:** No evidence of increased request volume or latency. Resource failures occurred over a 10-second window without corresponding traffic pattern changes. Metrics show stable load throughout incident window.

### Infrastructure Failure (5% confidence)
**Reason:** No host-level errors, network partition signals, or disk failures observed. Process crash was application-level (ERROR: process_crash), not infrastructure-induced.

### Dependency Failure (5% confidence)
**Reason:** No external service errors logged. No timeout patterns. Storage service isolated in scope.
```

**If Copilot jumps straight to "Root Cause" → Phase 3 validation fails.**

---

## 8. Root Cause Selection (LAST, Not First)

**Only after elimination** does Copilot select:

```markdown
## Primary Root Cause

**Unrecoverable resource exhaustion leading to process crash**

**Category:** Resource

**Confidence:** 65%

**Causal Chain:**
1. Storage service deployment at 2015-03-16T23:16:30Z
2. Performance degradation observed at T+73s (23:17:43Z)
3. I/O error at T+76s (23:17:46Z)
4. Resource allocation failures (9x) from T+77s to T+87s
5. Process crash (2x) at T+88s (23:17:58Z) and T+91s (23:18:01Z)

**Evidence:**
- 9 consecutive resource allocation failures over 10 seconds
- Process crash immediately following allocation failures
- Deployment timing (1 minute before first symptoms)

**Confidence Adjustment:**
- Base hypothesis confidence: 80%
- Evidence quality penalty: -15% (incomplete lifecycle coverage)
- **Final confidence: 65%**
```

### Ordering is Essential:

```
❌ WRONG: Selection → Justification
✅ RIGHT: Elimination → Selection
```

---

## 9. Required Output Structure (Sherlock-Enforced)

Phase 3 output **must** follow this section order:

```markdown
# Incident Analysis: INC-123

## Timeline
[Minute-by-minute sequence of events]

## Hypotheses Considered
[All 3-5 hypotheses with FOR/AGAINST evidence]

## Evidence Evaluation
[Cross-hypothesis evidence analysis]

## Ruled-Out Hypotheses
[Explicit elimination with reasons]

## Primary Root Cause
[Selected hypothesis with causal chain]

## Contributing Factors
[Amplifiers, NOT alternative explanations]

## Remaining Uncertainty
[What you don't know and why]

## Confidence Summary
[Confidence budget breakdown]
```

**Missing or reordered sections → Reasoning flagged as invalid.**

---

## 10. Hadoop-Specific Realism (Important Subtlety)

Even though logs came from Hadoop:

- ✅ Copilot reasons: "resource exhaustion", "allocation failure", "process crash"
- ❌ Copilot **never** says: "NameNode", "HDFS", "DataNode", "blockReceiver"

### Why This Matters:

```
Raw Hadoop Log:
"DataNode registration failed: java.io.IOException: Premature EOF"

Phase 1 Adapter Output:
"registration_failure" (severity: WARN)

Phase 3 Reasoning:
"Service registration failed, indicating possible resource contention or network instability"
```

**That proves log-agnostic design.** Phase 3 works identically for Hadoop, Kubernetes, Postgres, Nginx.

---

## 11. Phase 3 Failure Modes (Intentional)

| Failure Condition | Action | Rationale |
|-------------------|--------|-----------|
| **<3 hypotheses** | Warn | Minimum diversity required |
| **No ruled-out hypotheses** | Warn | Elimination proves rigor |
| **Confidence >100%** | **Abort** | Mathematical impossibility |
| **No uncertainty acknowledged** | Warn | Overconfidence signal |
| **Evidence only FOR, not AGAINST** | **Abort** | Evidence asymmetry = bias |
| **Vendor jargon detected** | Warn | Breaks abstraction layer |

**Failing loudly > Being wrong quietly.**

---

## 12. Why Phase 3 Works With Real Logs

**Key Insight:**

> **Phase 3 reasons over abstractions, not telemetry formats.**

This is why:
- ✅ Hadoop logs (DataNode 16-line crash dump)
- ✅ Kubernetes logs (1000 pod restart events)
- ✅ Postgres logs (slow query logs + connection errors)
- ✅ Nginx logs (1M access logs + 502 errors)

**All produce the same quality of RCA.**

### The Architecture Win:

```
Raw Logs (vendor-specific)
   ↓ Adapter (Phase 1)
Generic Signals (resource_exhaustion, crash, io_error)
   ↓ Phase 2
Relevant Signals (scoped to incident)
   ↓ Phase 3 (THIS LAYER)
Hypothesis-Based RCA (vendor-agnostic reasoning)
```

**Phase 3 never sees "Hadoop" - it only sees "storage service crash with resource exhaustion".**

---

## 13. Sanity Check (Answer Instantly)

**Question:**  
"Why not let Copilot infer hypotheses automatically from raw logs?"

**Correct Answer:**  
> "Because hypothesis generation must be constrained to prevent anchoring and hallucination. Without structure, LLMs jump to the first plausible explanation and backfill justification. Phase 3 forces enumeration → evaluation → elimination → selection, not narrative construction."

**That's a senior-level answer.**

---

## 14. What Phase 3 Deliberately Does NOT Do

❌ **No statistical inference** (no p-values, no correlation coefficients)  
❌ **No anomaly detection** (Phase 2 handles relevance)  
❌ **No root cause guessing** (structured evaluation, not intuition)  
❌ **No Hadoop-specific logic** (works on generic signals)  
❌ **No learning** (stateless protocol, no feedback loops)

**Phase 3 is controlled reasoning, not AI magic.**

---

## Implementation Details

### Prompt Enhancement ([sherlock](sherlock#L1002-L1110))

```bash
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3: HYPOTHESIS-BASED REASONING PROTOCOL (MANDATORY)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1: HYPOTHESIS GENERATION (3-5 hypotheses, diverse categories)
STEP 2: EVIDENCE SYMMETRY (FOR + AGAINST, always)
STEP 3: CONFIDENCE BUDGETING (≤100% total)
STEP 4: EXPLICIT ELIMINATION (before selection)
STEP 5: ROOT CAUSE SELECTION (last step)

CRITICAL CONSTRAINTS:
✓ Reason in GENERIC systems terms (resource exhaustion, crash, allocation failure)
✗ NEVER use vendor jargon (Hadoop, DataNode, HDFS, NameNode, Spark, Kubernetes)
✓ Confidence scores reflect evidence quality (account for penalties)
```

### Validation Logic ([sherlock](sherlock#L1141-L1232))

```python
# Check 1: Hypothesis count (3-5)
if hyp_count < 3:
    errors.append(f"Only {hyp_count} hypotheses found (minimum: 3)")

# Check 2: Category diversity
unique_categories = set(categories)
if len(unique_categories) < 2:
    warnings.append(f"Low category diversity")

# Check 3: Evidence symmetry
if for_count != hyp_count or against_count != hyp_count:
    errors.append(f"Evidence asymmetry detected")

# Check 4: Confidence budget
if total_confidence > 100:
    errors.append(f"Confidence budget exceeded: {total_confidence}%")

# Check 5: Ruled-out hypotheses
if ruled_out == 0:
    warnings.append("No hypotheses explicitly ruled out")

# Check 6: No vendor jargon
vendor_terms = ['hadoop', 'hdfs', 'datanode', 'namenode']
if found_jargon:
    warnings.append(f"Vendor jargon detected: {', '.join(found_jargon)}")

# Check 7: Required sections
required_sections = ['Timeline', 'Evidence Evaluation', 'Primary Root Cause', 
                     'Remaining Uncertainty', 'Confidence Summary']
if missing_sections:
    errors.append(f"Missing required sections")
```

### Example Prompt Generated for Hadoop Incident

```
Evidence Quality Notes:
- Confidence penalties: No lifecycle events detected; Crash without clean shutdown (-15%)

Incident Evidence Bundle:
{
  "logs": {
    "entries": [
      {
        "timestamp": "2015-03-16T23:17:43Z",
        "severity": "WARN",
        "message": "performance_degradation (count: 1)"
      },
      {
        "timestamp": "2015-03-16T23:17:47Z",
        "severity": "WARN",
        "message": "resource_allocation_failure (count: 9)"
      },
      {
        "timestamp": "2015-03-16T23:17:58Z",
        "severity": "ERROR",
        "message": "process_crash (count: 2)"
      }
    ]
  }
}
```

**Notice**: No "DataNode", no "HDFS", no raw stack traces. Just generic failure telemetry.

---

## Testing Evidence

### Validation Output (Expected):

```bash
🔍 Phase 3: Validating hypothesis-based reasoning structure
   ✓ Found 4 hypotheses
   ✓ Category diversity: 4 distinct categories (Resource, Application, Infrastructure, Traffic)
   ✓ Evidence symmetry maintained (4 FOR + 4 AGAINST)
   ✓ Confidence budget: 85% used, 15% uncertainty
   ✓ All hypotheses have status markers
   ✓ 2 hypothesis(es) explicitly ruled out
   ✓ Generic systems reasoning (no vendor jargon)
   ✓ All required sections present

✅ Hypothesis validation passed
```

### Confidence Budget Example:

```
Base Hypotheses:
- H1: Resource exhaustion    80%
- H2: Application bug         10%
- H3: Infrastructure failure   5%
- H4: Traffic spike            0% (RULED_OUT)

Quality Penalty: -15% (from Phase 1)

Adjusted:
- H1: Resource exhaustion    65% (80% - 15%)
- H2: Application bug         10%
- H3: Infrastructure failure   5%
- H4: Traffic spike            0%
- Uncertainty                 20% (15% quality + 5% unknown)

Total: 100%
```

---

## Design Trade-offs

### ✅ Structured Protocol > Free-Form Reasoning
- **Decision**: Force 5-step hypothesis protocol
- **Alternative**: "Explain the root cause" (open-ended)
- **Rationale**: LLMs are vulnerable to anchoring bias. Structure forces rigorous evaluation.

### ✅ Evidence Symmetry > Confirmation Bias
- **Decision**: Require FOR + AGAINST for every hypothesis
- **Alternative**: Only list supporting evidence
- **Rationale**: Humans seek confirming evidence. Forcing counter-evidence prevents narrative construction.

### ✅ Explicit Elimination > Implicit Filtering
- **Decision**: Mandate "Ruled-Out Hypotheses" section
- **Alternative**: Only document selected root cause
- **Rationale**: Elimination proves rigor. Showing what you rejected is as important as what you accepted.

### ✅ Confidence Budget > Binary Conclusions
- **Decision**: Force confidence scoring with ≤100% constraint
- **Alternative**: "This is the root cause" (no uncertainty)
- **Rationale**: All incident investigations have uncertainty. Quantifying it enables better decision-making.

### ✅ Generic Abstraction > Vendor-Specific Reasoning
- **Decision**: Ban Hadoop jargon in Phase 3 reasoning
- **Alternative**: Let Copilot use "DataNode", "HDFS" if relevant
- **Rationale**: Vendor terms trigger memorized solutions from training data, not evidence-based reasoning.

---

## Key Files Modified

- **[sherlock](sherlock#L1002-L1232)**: Enhanced Copilot prompt with Phase 3 protocol (110 lines) + validation logic (90 lines)
- **[reports/copilot-prompt-INC-123.txt](reports/copilot-prompt-INC-123.txt)**: Generated prompt showing Phase 3 structure with Hadoop evidence

---

## Next Steps

1. **Phase 4 Integration**: Connect validated hypotheses to human review (ACCEPT/MODIFY/REJECT)
2. **Hypothesis Templates**: Pre-defined hypothesis patterns for common failure modes (OOM, config error, deployment regression)
3. **Confidence Calibration Tracking**: Compare AI confidence vs human confidence over time (Phase 5 history)
4. **Multi-Hypothesis RCA**: Support scenarios where 2+ root causes have similar confidence (e.g., 45% / 40%)
5. **Phase 3 Metrics**: Track hypothesis diversity, elimination rate, confidence accuracy

---

**Status**: ✅ Complete (Phase 3 Hadoop Edition)  
**Last Updated**: 2026-02-09  
**Author**: Copilot Sherlock Team
