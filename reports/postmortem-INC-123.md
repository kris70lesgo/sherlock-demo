# Incident Post-Mortem: INC-123

## Timeline

**2026-02-05 15:46:43 UTC** - Commit f09a9a5 merged: "Add basic input validation to request handler" (includes unbounded cache append in app.py)

**2026-02-12 11:14:58 UTC** - api-gateway service starting

**2026-02-12 11:15:02 UTC** - Deployment v1.1.0 completed (commit HEAD)

**2026-02-12 11:16:10 UTC** - First memory warning detected at 85% utilization (~340MB pre-incident baseline)

**2026-02-12 11:16:42 UTC** - Memory allocation failure (peak memory: 980MB, +860MB delta from baseline)

**2026-02-12 11:16:43 UTC** - Process crash, error rate spiked to 3.8% (from 0.1% baseline)

**Total elapsed time from deployment to crash:** 1 minute 41 seconds

## Hypotheses Considered

### Hypothesis 1: Unbounded Cache Accumulation (Category: Application Logic)

**Evidence FOR:**
- Diff semantic hint explicitly indicates "adds unbounded cache append" in app.py
- Memory growth pattern shows 7.2x increase from baseline (120MB → 980MB) in under 2 minutes
- Rapid, continuous memory growth is characteristic of unbounded data structure accumulation
- Deployment timing (v1.1.0 at 11:15:02) directly precedes memory spike (11:16:10), indicating code-triggered issue
- Commit f09a9a5 modified app.py on Feb 5, deployed Feb 12 - timing aligns with code change deployment

**Evidence AGAINST:**
- Only 1 minute 41 seconds elapsed - extremely rapid growth for typical cache accumulation scenarios
- No explicit log messages about cache size or eviction failures
- Error message "allocation failed" is generic and doesn't confirm cache-specific issue

**Confidence:** 75%  
**Status:** CONFIRMED (Primary Root Cause)

### Hypothesis 2: Traffic Spike Overwhelming Resources (Category: Traffic/Load)

**Evidence FOR:**
- Memory exhaustion occurred rapidly after deployment, which could indicate high request volume
- Error rate increased 38x (0.1% → 3.8%), suggesting load-related strain
- Allocation failure could result from processing excessive concurrent requests

**Evidence AGAINST:**
- No log entries indicating unusual traffic patterns, connection spikes, or request volume anomalies
- Memory growth of 860MB in 92 seconds (9.3MB/sec) is too steep for normal traffic-induced growth
- Baseline memory (120MB) to peak (980MB) suggests structural issue rather than transient load
- Code change (unbounded cache append) provides alternative explanation with stronger evidence
- No deployment of auto-scaling, rate limiting, or other load-management changes mentioned

**Confidence:** 5%  
**Status:** RULED_OUT

### Hypothesis 3: Memory Leak in Runtime/Platform (Category: Dependencies/Runtime)

**Evidence FOR:**
- Continuous memory growth without corresponding cleanup suggests leak behavior
- Allocation failure indicates exhaustion of available heap space
- Platform-level leaks can manifest rapidly under certain workload conditions

**Evidence AGAINST:**
- Code change (app.py with unbounded cache) immediately precedes incident, suggesting application-level cause
- No evidence of runtime version change or platform update in deployment events
- Memory growth rate (9.3MB/sec) is unusually aggressive for typical platform leaks
- No indication of similar issues in other services sharing the runtime environment
- Timeline shows immediate correlation with code deployment, not gradual degradation

**Confidence:** 3%  
**Status:** RULED_OUT

### Hypothesis 4: Insufficient Memory Limits in Deployment Config (Category: Configuration)

**Evidence FOR:**
- Service crashed with "allocation failed" error, which can occur when hitting configured memory limits
- Deployment event (v1.1.0) could have included configuration changes
- Rapid crash suggests hard resource boundary

**Evidence AGAINST:**
- Memory grew from 120MB baseline to 980MB - if limit was misconfigured too low, baseline wouldn't have been 120MB
- Configuration issue would typically manifest as immediate crash or stable constrained operation, not accelerating growth
- Error occurred 1m41s after deployment, not immediately, suggesting accumulation rather than static misconfiguration
- Code change (unbounded cache) provides causal mechanism for memory growth, configuration alone doesn't explain growth rate
- No evidence in deployment metadata of memory limit changes

**Confidence:** 2%  
**Status:** RULED_OUT

### Hypothesis 5: Request Validation Logic Introducing Per-Request Memory Retention (Category: Application Logic)

**Evidence FOR:**
- Commit message explicitly mentions "Add basic input validation to request handler"
- Validation logic could inadvertently retain request data/context in memory
- Timing aligns: code change Feb 5, deployed Feb 12, crash immediately follows deployment
- Semantic hint "unbounded cache append" suggests validation results or request data being cached

**Evidence AGAINST:**
- This is effectively a subcategory of Hypothesis 1 (unbounded cache) rather than distinct root cause
- Evidence points to cache accumulation mechanism rather than validation logic specifically
- Functionally indistinguishable from general unbounded cache hypothesis

**Confidence:** 15% (subsumed into Hypothesis 1)  
**Status:** POSSIBLE (but redundant with H1)

## Evidence Evaluation

**Strong causal indicators:**
1. **Code-level semantic hint:** The diff annotation "adds unbounded cache append" is the most direct evidence, explicitly identifying the problematic pattern
2. **Temporal correlation:** Deployment of code change (11:15:02) → memory warning (11:16:10, 68 seconds later) → crash (11:16:42, 100 seconds later) shows clear causal sequence
3. **Memory growth signature:** 7.2x growth in 92 seconds (9.3MB/second sustained) is characteristic of per-request unbounded accumulation with moderate-to-high traffic

**Weak correlations:**
- Error rate increase (3.8%) is an effect of memory exhaustion, not a root cause
- "allocation failed" error is a symptom, not diagnostic of specific cause
- High memory warning (85%) served as leading indicator but provides no causal information

**Eliminated factors:**
- No traffic anomaly evidence (Hypothesis 2 ruled out)
- No infrastructure/runtime changes (Hypothesis 3 ruled out)  
- No configuration limit evidence (Hypothesis 4 ruled out)

## Ruled-Out Hypotheses

**Traffic Spike (H2):** Eliminated due to absence of traffic anomaly indicators in logs, implausibility of 9.3MB/sec growth from traffic alone, and presence of stronger code-change explanation. Confidence reduced from potential 20% to 5%.

**Platform Memory Leak (H3):** Eliminated due to immediate correlation with application code deployment, absence of runtime version changes, and code-level evidence (unbounded cache) providing sufficient explanation. Residual 3% confidence accounts for potential runtime contribution to growth rate.

**Deployment Configuration (H4):** Eliminated because memory grew dynamically rather than hitting static limit immediately, and baseline memory (120MB) indicates limit was not artificially low. Configuration may have been inadequate but wasn't the triggering cause. Residual 2% confidence.

## Primary Root Cause

**Hypothesis 1: Unbounded Cache Accumulation in Application Code**

**Commit:** f09a9a5351e2a6724fa5436f6e0c2e55d8321237 - "Add basic input validation to request handler"

**Causal Chain:**
1. Code change introduced unbounded cache append operation in app.py (semantic hint confirms)
2. Deployment v1.1.0 on Feb 12 at 11:15:02 activated the modified code path
3. Each incoming request triggered cache append without eviction/size limit
4. Cache grew continuously at ~9.3MB/second under production traffic load
5. After 68 seconds, memory usage reached 85% (340MB), triggering warning
6. After 100 seconds total, memory peaked at 980MB, exhausting available heap
7. Allocation failure occurred at 11:16:42, followed by process crash at 11:16:43

**Mechanistic explanation:** The input validation logic (added in commit f09a9a5) appended validation results, request metadata, or derived data to an in-memory cache structure without implementing size bounds, TTL, or eviction policy. Under production request volume, this caused linear or accelerating memory growth until process termination.

## Contributing Factors

1. **Rapid deployment-to-traffic exposure:** Service received production traffic immediately upon deployment without gradual ramp-up, allowing unbounded cache to fill at maximum rate
2. **Insufficient memory headroom:** Baseline memory (120MB) left only 860MB buffer before exhaustion, providing minimal time-to-detection
3. **Delayed detection threshold:** Memory warning triggered at 85% utilization, only 68 seconds before crash - insufficient time for intervention
4. **Lack of memory growth rate alerting:** No rate-of-change monitoring to detect 9.3MB/sec accumulation before absolute threshold breach

## Detection & Prevention Gaps

**Detection Gaps:**
- No pre-deployment memory profiling or load testing of validation logic changes
- Memory monitoring alert threshold (85%) triggered too late relative to growth rate
- No anomaly detection on memory growth velocity (MB/sec)
- Absence of cache size metrics or logging in application code
- No automated rollback trigger based on memory exhaustion patterns

**Prevention Gaps:**
- Code review process did not identify unbounded data structure accumulation
- No static analysis tooling to detect cache operations without size limits
- Missing guardrails: no max-size enforcement, TTL, or LRU eviction in cache implementation
- Deployment lacked canary phase or gradual traffic shifting to limit blast radius
- No memory limit enforcement at container/process level to fail gracefully

## Remediation & Follow-ups

**Immediate (Complete within 24 hours):**
1. Revert commit f09a9a5 or hotfix app.py to implement bounded cache with max size (e.g., 1000 entries) and LRU eviction
2. Deploy fixed version with canary rollout (10% → 50% → 100% traffic over 30-minute periods)
3. Add real-time dashboard for cache size and memory growth rate (MB/min)

**Short-term (Complete within 1 week):**
4. Implement container memory limits (e.g., 512MB hard limit) with graceful OOM handling
5. Add memory growth rate alerting: trigger at >2MB/min sustained for 30 seconds
6. Conduct forensic analysis of cache contents to understand request patterns driving accumulation
7. Add cache metrics instrumentation: size, hit/miss rate, eviction count

**Long-term (Complete within 1 month):**
8. Establish code review checklist item: "Does this change introduce unbounded data structures?"
9. Deploy static analysis tooling to flag append/insert operations without size checks
10. Implement pre-production load testing gate for all api-gateway changes (sustained 1000 RPS for 5 minutes)
11. Design standardized caching library with enforced size limits and telemetry
12. Conduct architecture review of validation approach - evaluate stateless alternatives

## Remaining Uncertainty

**What we don't know:**
- **Exact cache data contents:** What specific data (request IDs, validation results, user context) was being cached - requires code inspection or memory dump analysis
- **Request volume during incident:** No traffic metrics provided - actual RPS driving accumulation rate is unknown
- **Cache growth function:** Linear (per-request) vs. superlinear (per-request-field) - affects capacity planning
- **Why validation required caching:** Business logic rationale for cache design unclear - may reveal alternative solutions

**Why uncertainty remains:**
- Evidence bundle lacks application-level metrics (cache size, request rate, request characteristics)
- No memory dump or heap analysis available to inspect cached object structure
- Code diff not provided - semantic hint confirms pattern but not implementation details

**Impact of uncertainty on conclusions:**
- Root cause identification (unbounded cache) has high confidence (75%) despite implementation details uncertainty
- Remediation strategy (bounded cache with eviction) is correct regardless of specific cached data types
- Uncertainty primarily affects optimization of cache size tuning and validation redesign

## Confidence Summary

- **Primary root cause confidence:** 75%
- **Total hypothesis confidence budget used:** 85% (75% H1 + 5% H2 + 3% H3 + 2% H4)
- **Uncertainty factors:**
  - Lack of application-level cache metrics (size, growth tracking)
  - No traffic volume data to validate growth rate assumptions
  - Code implementation details not inspected directly
  - No memory profiling or heap dump analysis performed
  - 25% residual uncertainty accounts for potential interaction effects or unidentified contributing factors

**Confidence justification:** High confidence (75%) based on explicit semantic hint "adds unbounded cache append" combined with characteristic memory growth signature and temporal correlation. Remaining 25% uncertainty reflects possibility of compounding factors (e.g., unusual traffic pattern amplifying cache growth) or misinterpretation of semantic hint context.

