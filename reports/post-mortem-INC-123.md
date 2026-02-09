# Incident Post-Mortem: INC-123
**Service:** storage_service  
**Window:** 2015-03-16T23:15:00Z to 2015-03-16T23:20:00Z  
**Generated:** 2025-01-27T14:30:00Z

---

## Hypotheses Evaluated

### Hypothesis 1: Resource Allocation Cascade Failure
**Confidence:** 65%  
**Category:** Resource  

**Evidence FOR:**
- High frequency resource_allocation_failure events (9 occurrences in 10s)
- Progressive pattern: 23:17:47 → 23:17:57 (escalating)
- Preceded process_crash by 1 second (causal relationship plausible)
- Warning severity → Error severity transition observed

**Evidence AGAINST:**
- No explicit memory/disk metrics exceeded thresholds
- Missing lifecycle events (quality penalty: 15%)
- Could be symptom rather than cause

**Outcome:** LEADING CANDIDATE

### Hypothesis 2: Hardware I/O Failure
**Confidence:** 20%  
**Category:** Infrastructure  

**Evidence FOR:**
- Single io_error event at 23:17:46 (preceding cascade)
- DataNode role suggests disk-heavy operations
- WARN severity indicates actual I/O problems

**Evidence AGAINST:**
- Only 1 I/O error (not sustained pattern)
- No subsequent disk-related failures logged
- Timing doesn't explain 9 allocation failures

**Outcome:** RULED OUT (insufficient evidence for sustained failure)

### Hypothesis 3: Code Bug in New Deployment
**Confidence:** 10%  
**Category:** Application  

**Evidence FOR:**
- Deployment occurred in incident window (1 deployment found)
- Service restart at 23:17:44 (typical deployment pattern)

**Evidence AGAINST:**
- No commit metadata available (0 commits in window)
- No error patterns indicating buggy code path
- Would expect application-level exceptions, not resource failures

**Outcome:** RULED OUT (no code change evidence)

### Hypothesis 4: External Load Spike
**Confidence:** 0%  
**Category:** Traffic  

**Evidence FOR:**
- None (no traffic metrics provided)

**Evidence AGAINST:**
- scope-audit shows only storage_service metrics (cpu_util, memory_pct)
- No request_rate or connection_count data
- registration event suggests normal startup, not overload

**Outcome:** RULED OUT (untestable with available data)

### Hypothesis 5: Crash Recovery Loop
**Confidence:** 5%  
**Category:** Application  

**Evidence FOR:**
- Two process_crash events (23:17:58, 23:18:01)
- 3-second interval suggests restart attempt
- Service start at 23:17:44, crash at 23:17:58 (14s runtime)

**Evidence AGAINST:**
- Only 2 crashes (not sustained loop)
- First crash preceded by allocation failures (cause likely upstream)
- No evidence of subsequent restart attempts

**Outcome:** RULED OUT (symptom, not cause)

---

## Root Cause Analysis

**PRIMARY:** Resource allocation cascade failure (65% confidence)

**Timeline:**
1. 23:17:43: DataNode registration + performance degradation warning
2. 23:17:44: Service start
3. 23:17:45: Operational success
4. 23:17:46: I/O error (first warning)
5. 23:17:47-57: 9 resource allocation failures (cascade begins)
6. 23:17:58: First process crash
7. 23:18:01: Second crash (3s later)

**Causal Chain:**
- I/O error (23:17:46) → resource allocation stress
- Allocation failures accumulate → memory/file descriptor exhaustion
- Critical resource exhaustion → process crash (23:17:58)
- Restart without fix → second crash (23:18:01)

**Confidence Budget:**
- 65% allocated to resource cascade
- 20% to hardware I/O failure (plausible alternate)
- 15% uncertainty (missing lifecycle events, no heap dumps)

**Evidence Quality:**
- Contract: PARTIAL (15% penalty)
- Phase 2 reduction: 28.6% (2/7 signals excluded)
- Missing: commit diffs, memory dumps, pre-incident baseline

---

## Remediation Steps

**Immediate (Stop Bleeding):**
1. Check DataNode process limits: `ulimit -n` (file descriptors)
2. Inspect disk I/O: `iostat -x 5` (wait times, queue depth)
3. Review kernel logs: `dmesg | grep -i oom` (out-of-memory kills)

**Short-Term (Restore Service):**
1. Increase resource limits in systemd unit file:
   ```
   LimitNOFILE=65536
   LimitNPROC=4096
   ```
2. Add health checks to detect allocation failures early
3. Implement graceful degradation (fail requests, don't crash)

**Long-Term (Prevent Recurrence):**
1. Add pre-allocation resource checks (fail-fast on startup)
2. Instrument allocation failures with metrics (track rate over time)
3. Implement circuit breaker for I/O operations
4. Add lifecycle logging: startup params, heap dumps on OOM

**Validation Needed:**
- [ ] Verify allocation failure root cause with heap dump
- [ ] Correlate with infrastructure metrics (disk latency?)
- [ ] Check if other DataNodes experienced similar pattern
- [ ] Review recent deployments (even if no commits visible)

---

## Metadata

**Hypotheses Generated:** 5  
**Hypotheses Ruled Out:** 4  
**Evidence Sources:** hadoop_logs (PARTIAL), deployments, metrics  
**Confidence Penalties Applied:** -15% (no lifecycle events, crash without shutdown)  
**Investigation Tool:** Sherlock Phase 3 (Hypothesis-Based Reasoning)  
**Requires Human Review:** YES (confidence <80%, evidence quality PARTIAL)
