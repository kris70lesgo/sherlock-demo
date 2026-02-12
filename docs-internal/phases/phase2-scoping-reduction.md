# Phase 2: Incident Scoping & Evidence Reduction
## (Hadoop Logs Edition)

**Purpose**: Transform "all valid evidence" into "relevant evidence for THIS incident" using human-aligned reduction, not AI guessing.

---

## 0. What Phase 2 IS (and is NOT)

### Phase 2 IS:
- **A relevance gate**: Only evidence temporally/contextually related to the incident passes through
- **A noise destroyer**: Eliminates background chatter (heartbeats, DEBUG spam, unrelated components)
- **A scale control layer**: Prevents token limit exhaustion by reducing 10,000 events → 50 events
- **A human-aligned narrowing mechanism**: Driven by **Incident Scope Object** (ISO), not heuristics

### Phase 2 is NOT:
- ❌ **Validation** (that's Phase 1)
- ❌ **Reasoning** (that's Phase 3)
- ❌ **Pattern detection** (Phase 3's hypothesis evaluation)
- ❌ **Root cause inference** (Phase 3/4)

**Phase 2 answers only one question:**

> "Out of all valid evidence, what is actually relevant to THIS incident?"

---

## 1. Why Phase 2 is Critical for Real Hadoop Logs

Hadoop logs in production are:
- **Long-running**: Days/weeks of continuous operation
- **Chatty**: INFO heartbeats every 3 seconds, 28,800/day
- **Multi-component**: DataNode, NameNode, ResourceManager, NodeManager all logging simultaneously
- **Partially unrelated**: Most WARNs are routine (slow disk, network hiccup, retries succeeded)

**Without Phase 2:**
- Copilot sees 10,000+ events
- Hypotheses get diluted across unrelated noise
- Confidence collapses (everything looks equally suspicious)
- RCA becomes generic ("check logs, restart service")

**With Phase 2:**
- Copilot sees 10-50 highly relevant events
- Hypotheses focus on incident timeframe
- Confidence calibrated to signal density
- RCA is specific and actionable

---

## 2. Phase 2 Position in Pipeline

**Correct Order (After Phase 1 Enhancement):**

```
Raw Hadoop Logs (evidence/hadoop.log)
   ↓
Hadoop Log Adapter (parse + abstract → signals)
   ↓
PHASE 2: Scope & Reduce   ← YOU ARE HERE
   ↓  (7 events → 5 events)
PHASE 1: Validate Contract
   ↓  (enforce ISO-8601, severity, no jargon)
Phase 3: Hypothesis Evaluation
Phase 4: Human Review
Phase 5: Institutional Memory
```

**Critical Dependencies:**
- Phase 2 **never sees raw logs** (adapter handles parsing)
- Phase 2 **never fixes bad data** (Phase 1 validates after scoping)
- Phase 2 **assumes adapter output is structurally sound** (but not necessarily relevant)

---

## 3. Phase 2 Inputs (EXACT Format)

Phase 2 receives **adapter output**, not validated output.

### Example Input (from `hadoop-adapter.py`):
```json
{
  "source": "hadoop",
  "quality": {
    "completeness": "PARTIAL",
    "confidence_penalty": 15
  },
  "signals": [
    {
      "event": "resource_allocation_failure",
      "severity": "WARN",
      "component": "storage_service",
      "count": 9,
      "first_seen": "2015-03-16T23:17:47Z"
    },
    {
      "event": "heartbeat",
      "severity": "INFO",
      "component": "storage_service",
      "count": 1200,
      "first_seen": "2015-03-16T22:40:10Z"
    },
    {
      "event": "process_crash",
      "severity": "ERROR",
      "component": "storage_service",
      "count": 1,
      "first_seen": "2015-03-16T23:18:01Z"
    }
  ]
}
```

**Problem**: This has 1,210 events total (9 + 1200 + 1).

**Phase 2 Goal**: Cut to ~5-10 events relevant to the incident.

---

## 4. Phase 2 Core Artifact: Incident Scope Object (ISO)

Phase 2 is **driven by a human-defined scope**, not AI heuristics.

### Example ISO ([incident-scope.json](incident-scope.json)):
```json
{
  "service": "storage_service",
  "time_window": {
    "start": "2015-03-16T23:15:00Z",
    "end": "2015-03-16T23:20:00Z"
  },
  "log_policy": {
    "min_severity": "WARN",
    "lifecycle_events": true,
    "event_allowlist": [
      "service_start",
      "service_shutdown",
      "resource_allocation_failure",
      "io_error",
      "process_crash",
      "registration",
      "performance_degradation"
    ],
    "include_components": ["storage_service"]
  }
}
```

### ISO Field Semantics:

| Field | Purpose | Failure Mode |
|-------|---------|--------------|
| `service` | Target component for incident | Abort if missing |
| `time_window.start/end` | Primary temporal filter (causal proximity) | Abort if missing/invalid |
| `log_policy.min_severity` | Drop DEBUG/INFO noise | Default: WARN |
| `log_policy.lifecycle_events` | Allow startup/shutdown even if below threshold | Default: true |
| `log_policy.event_allowlist` | **KEY**: Only these event types pass through | If empty, allow all |
| `log_policy.include_components` | Cross-service events allowed explicitly | Default: [service] |

**If ISO is missing or invalid → Investigation ABORTS immediately.**

---

## 5. Phase 2 Reduction Steps (Strict Order)

**This order is non-negotiable.** Each step builds on the previous.

### Step 2.1: Time Window Filtering (PRIMARY CUT)

**Rule:**
```python
start_time ≤ event.timestamp ≤ end_time
```

**Optional**: Buffer of ±1-2 minutes allowed for causal proximity.

**Effect**: Removes all background noise outside incident timeframe.

**Example**:
- Input: 1,210 events (spanning 6 hours)
- After 2.1: 42 events (5-minute incident window)
- **Reduction**: 96.5%

**Code Reference**: [sherlock](sherlock#L543-L565) (`scope_events_by_time`)

---

### Step 2.2: Severity Threshold Filtering

**Rules:**
1. Drop all events below `min_severity` (default: WARN)
2. **Exception**: Allow INFO if:
   - `lifecycle_events: true` AND
   - Event type in `[service_start, service_shutdown, startup, shutdown, deployment]`

**Why**: Heartbeat spam dies here.

**Example**:
- Input: 42 events (7 ERROR, 11 WARN, 24 INFO)
- After 2.2: 20 events (7 ERROR, 11 WARN, 2 INFO lifecycle)
- **Reduction**: 52%

**Code Reference**: [sherlock](sherlock#L567-L593) (`scope_events_by_severity`)

---

### Step 2.3: Event Allowlist Filtering (**KEY for Hadoop**)

**Rule:**
```python
if allowlist exists:
    keep only events where event_type in allowlist
else:
    keep all
```

**Why This Matters**:
- Hadoop has **hundreds** of WARN types:
  - `PacketResponder timeout`
  - `Slow BlockReceiver write`
  - `Disk space low (warn threshold)`
  - `Missing heartbeat (recovered)`
  - `Slow compaction (non-blocking)`
- **Most are irrelevant** to any single incident
- Allowlist enforces human judgment: "Only these 7 event types matter for *this* incident"

**Example**:
- Input: 20 events (resource_allocation_failure, io_error, slow_disk, retry_succeeded, ...)
- Allowlist: `[resource_allocation_failure, io_error, process_crash]`
- After 2.3: 11 events
- **Reduction**: 45%

**This is the single most powerful reduction step.**

**Code Reference**: [sherlock](sherlock#L595-L611) (`scope_events_by_allowlist`)

---

### Step 2.4: Component Relevance Check

**Rule:**
```python
keep events where:
    event.component in include_components
```

**Default**: If `include_components` is empty, use `[service]`

**Why**:
- Prevents cascading false causality (e.g., "NameNode restarted" ≠ cause of DataNode failure)
- Eliminates irrelevant node chatter in multi-node clusters

**Example**:
- Input: 11 events (9 storage_service, 2 name_service)
- include_components: `[storage_service]`
- After 2.4: 9 events
- **Reduction**: 18%

**Code Reference**: [sherlock](sherlock#L613-L632) (`scope_events_by_component`)

---

### Step 2.5: Deduplication & Consolidation

**Rule**:
Group by `(event_type, severity, component)` and merge:
```python
{
  "event": "resource_allocation_failure",
  "severity": "WARN",
  "count": 9,
  "first_seen": "...",
  "last_seen": "..."
}
```

**Why**:
- Adapter already aggregates identical events
- Phase 2 dedup handles edge cases (e.g., events from different time slices)
- Preserves temporal spread (`first_seen` → `last_seen`) for Phase 3 timeline correlation

**Example**:
- Input: 9 events (4 unique types, some already aggregated)
- After 2.5: 5 events (fully deduplicated)
- **Reduction**: 44%

**Code Reference**: [sherlock](sherlock#L634-L673) (`deduplicate_events`)

---

## 6. Phase 2 Output (Post-Reduction, Pre-Validation)

After all 5 steps, output becomes:

```json
{
  "source": "hadoop",
  "quality": {
    "completeness": "PARTIAL",
    "confidence_penalty": 15
  },
  "signals": [
    {
      "event": "resource_allocation_failure",
      "severity": "WARN",
      "component": "storage_service",
      "count": 9,
      "first_seen": "2015-03-16T23:17:47Z"
    },
    {
      "event": "process_crash",
      "severity": "ERROR",
      "component": "storage_service",
      "count": 1,
      "first_seen": "2015-03-16T23:18:01Z"
    }
  ]
}
```

**This is perfect input for Phase 1 validation.**

---

## 7. Scope Audit (MANDATORY)

Phase 2 **must** produce an audit trail for:
- **Judges/auditors**: "Why were 1,200 events excluded?"
- **Debugging**: "Did scoping drop the smoking gun signal?"
- **Trust**: "Is Phase 2 making correct relevance decisions?"
- **Defensibility**: "Can we justify this RCA in post-mortem review?"

### Audit Structure:
```json
{
  "source": "hadoop",
  "included": 5,
  "excluded": 1205,
  "exclusion_breakdown": {
    "outside_time_window": 845,
    "severity_below_threshold": 311,
    "event_not_allowlisted": 47,
    "component_mismatch": 2,
    "deduplicated": 0
  },
  "reduction_ratio": "99.6%"
}
```

### Audit is Saved To:
- **File**: `reports/scope-audit-INC-123.json`
- **Section**: `hadoop_event_reduction` (added to existing scope audit)

**Without this, Phase 2 is opaque and weak.**

**Code Reference**: [sherlock](sherlock#L732-L740) (audit generation)

---

## 8. Phase 2 Failure Modes (Intentional)

| Condition | Action | Rationale |
|-----------|--------|-----------|
| **No events in window** | Abort | Can't investigate with zero evidence |
| **Only INFO remains** | Mark low-signal (⚠️ warning) | Likely false alarm or scope too narrow |
| **No ERROR/WARN** | Mark low-signal | No actionable signals |
| **Scope missing** | Abort | Phase 2 requires human-defined relevance |
| **Service mismatch** | Abort | Scope points to wrong component |

**Failing loudly is a feature.** Better to abort than produce garbage RCA.

**Code Reference**: [sherlock](sherlock#L743-L749) (failure checks)

---

## 9. Interaction with Phase 1 (Critical)

**Phase 2 does NOT validate.**

Phase 1 will (after scoping):
- Enforce ISO-8601 timestamps
- Check severity enums (INFO/WARN/ERROR only)
- Verify event types (no vendor jargon)
- Validate aggregation structure
- Propagate quality penalties

**Phase 2 only decides relevance, not correctness.**

**Pipeline Flow:**
```python
# Phase 2: Scope
scoped_events = phase2_reduce(adapter_output.signals, incident_scope)

# Reconstruct evidence object with scoped events
scoped_evidence = {
    "source": adapter_output["source"],
    "quality": adapter_output["quality"],
    "signals": scoped_events
}

# Phase 1: Validate scoped evidence
is_valid, violations = validate_evidence_contract(scoped_evidence)
if not is_valid:
    abort()
```

**Code Reference**: [sherlock](sherlock#L752-L762) (Phase 1 validation of scoped events)

---

## 10. Why Phase 2 + Phase 1 Together Make Hadoop Safe

**Key Insight:**

> **Phase 2 removes irrelevant truth.**  
> **Phase 1 removes untrustworthy truth.**  
> **Only then do you reason.**

This is why Sherlock can:
- ✅ Handle **Hadoop** (chatty, multi-component, long-running)
- ✅ Handle **Kubernetes** (event storm, rapid churn)
- ✅ Handle **Postgres** (slow query logs with 10K entries/hour)
- ✅ Handle **Nginx** (access logs with 1M requests/day)

**Without changing Phase 3 at all.**

---

## 11. What Phase 2 Deliberately Does NOT Do

❌ **No anomaly detection** (that's Phase 3 hypothesis evaluation)  
❌ **No correlation** (Phase 3 timeline reconstruction)  
❌ **No heuristics** (human-defined scope, not AI guessing)  
❌ **No AI** (deterministic filtering only)  
❌ **No guessing** (abort if scope is ambiguous)

**Phase 2 is human-aligned reduction, not automated reasoning.**

---

## 12. Sanity Check (Answer Instantly)

**Question:**  
"Why not just let Copilot decide what logs matter?"

**Correct Answer:**  
> "Because relevance is an operational decision, not a reasoning problem. Copilot doesn't know which deployment caused the incident, which service is affected, or which timeframe matters. Humans define scope, AI reasons within scope."

**That answer alone signals seniority.**

---

## Testing Evidence

### Test Run Output:
```bash
$ ./sherlock --investigate
🔍 Detected raw Hadoop logs - invoking evidence contract adapter
📐 Phase 2: Scoping & Reducing events
  Step 2.1 (Time): 7 → 7 events (-0)
  Step 2.2 (Severity): 7 → 5 events (-2)
  Step 2.3 (Allowlist): 5 → 5 events (-0)
  Step 2.4 (Component): 5 → 5 events (-0)
  Step 2.5 (Dedup): 5 → 5 events (-0)
✓ Phase 2 complete: 7 events → 5 events (reduction: 28.6%)
✓ Phase 1 complete: Evidence contract validated (5 scoped signals)
```

### Breakdown:
- **Adapter**: 16 raw Hadoop log lines → 7 aggregated signals
- **Step 2.1**: 7 → 7 (all within 5-min window)
- **Step 2.2**: 7 → 5 (dropped 2 INFO: `operational_success`, kept `service_start` as lifecycle)
- **Step 2.3**: 5 → 5 (all on allowlist)
- **Step 2.4**: 5 → 5 (all `storage_service`)
- **Step 2.5**: 5 → 5 (adapter already aggregated)

**Final Reduction**: 16 raw events → 5 scoped signals = **68.75% reduction**

---

## Implementation Details

### Files Modified:
- **[sherlock](sherlock#L455-L782)**: Phase 2 reduction pipeline (5 steps + audit)
- **[incident-scope.json](incident-scope.json)**: Enhanced with `event_allowlist`, `lifecycle_events`
- **[evidence/deployments.json](evidence/deployments.json)**: Adjusted timestamp to match Hadoop logs timeframe

### Key Functions:
1. `scope_events_by_time()` - Step 2.1 (lines 543-565)
2. `scope_events_by_severity()` - Step 2.2 (lines 567-593)
3. `scope_events_by_allowlist()` - Step 2.3 (lines 595-611)
4. `scope_events_by_component()` - Step 2.4 (lines 613-632)
5. `deduplicate_events()` - Step 2.5 (lines 634-673)

### Audit Trail:
- Scope audit saved to `reports/scope-audit-INC-123.json`
- Includes `hadoop_event_reduction` section with exclusion breakdown
- Reduction ratio calculated: `(1 - scoped/initial) * 100%`

---

## Design Trade-offs

### ✅ Strict Order > Flexible Pipeline
- **Decision**: 5 steps in fixed sequence
- **Alternative**: Allow reordering based on data characteristics
- **Rationale**: Predictable behavior beats optimization. Time filtering MUST happen first (causal proximity).

### ✅ Allowlist > Blocklist
- **Decision**: `event_allowlist` (opt-in)
- **Alternative**: `event_blocklist` (opt-out)
- **Rationale**: Safer default ("allow nothing unless specified"). Blocklist risks letting unknown event types through.

### ✅ Human Scope > AI Detection
- **Decision**: Require human-defined Incident Scope Object
- **Alternative**: Auto-detect incident window from anomaly signals
- **Rationale**: Relevance requires operational context (who got paged? which deployment?) that AI can't infer.

### ✅ Fail-Fast > Graceful Degradation
- **Decision**: Abort if no events remain after scoping
- **Alternative**: Continue with warning, let Phase 3 handle empty evidence
- **Rationale**: Better to fail at scoping than produce "no root cause found" after 5 phases.

---

## Next Steps

1. **Elasticsearch Adapter**: Implement Phase 2 for nested JSON logs
2. **Kubernetes Adapter**: Handle event storm scoping (1000s of pod restarts)
3. **Auto-Scope Suggestion**: Use deployment events to suggest time_window start/end
4. **Scope Templates**: Pre-defined ISOs for common incident types (OOM, network partition, deployment rollback)
5. **Phase 2 Metrics**: Track reduction ratios across incidents for scope optimization

---

**Status**: ✅ Complete (Phase 2 Hadoop Edition)  
**Last Updated**: 2026-02-09  
**Author**: Copilot Sherlock Team
