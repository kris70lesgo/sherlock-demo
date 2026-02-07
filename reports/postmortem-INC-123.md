# Incident Post-Mortem: INC-123

## Timeline

**2026-02-05T15:46:43Z** - Commit f09a9a5 deployed: "Add basic input validation to request handler"

**2026-02-12T11:14:58Z** - Service api-gateway starting in demo environment

**2026-02-12T11:15:02Z** - Deployment v1.1.0 confirmed (commit HEAD)

**2026-02-12T11:16:10Z** (+1m 8s) - High memory usage warning triggered at 85% (estimated ~850MB based on subsequent crash at 980MB)

**2026-02-12T11:16:42Z** (+1m 40s) - Memory allocation failure reported

**2026-02-12T11:16:43Z** (+1m 41s) - Process crashed due to allocation failure

**Duration:** Service survived 1 minute 45 seconds post-deployment before fatal crash

## Hypotheses Considered

### Hypothesis 1: Unbounded Cache Growth (Category: Application)

**Evidence FOR:**
- Semantic hint in version control explicitly states: "adds unbounded cache append" in app.py
- Memory increased 860MB (717% above baseline) in under 2 minutes
- Memory growth trajectory: 120MB baseline → 340MB pre-incident → 980MB peak
- Rapid memory exhaustion pattern consistent with append-only data structure
- No backpressure or eviction logic implied by "unbounded" descriptor

**Evidence AGAINST:**
- Extremely rapid growth (860MB in ~100 seconds) would require ~8.6MB/second append rate
- Traffic patterns not provided - unclear if request volume supports this growth rate
- No explicit cache-related error messages in logs

**Confidence:** 75%  
**Status:** CONFIRMED (Primary Root Cause)

---

### Hypothesis 2: Traffic Spike Overwhelming Service (Category: Traffic/Load)

**Evidence FOR:**
- Error rate increased from 0.1% baseline to 3.8% peak (38x increase)
- Memory exhaustion could result from request backlog accumulation
- Deployment timing coincides with incident start

**Evidence AGAINST:**
- Memory growth pattern is exponential/linear, not sawtooth (typical of request queue buildup/drain cycles)
- No "connection refused", "queue full", or "timeout" messages in logs
- Memory delta (860MB) far exceeds typical per-request memory footprint
- Incident occurred immediately after deployment, not during known traffic peaks
- No mention of traffic metrics (requests/second, connection count) in evidence

**Confidence:** 5%  
**Status:** RULED_OUT (insufficient supporting evidence, timeline mismatch)

---

### Hypothesis 3: Memory Limit Misconfiguration (Category: Configuration)

**Evidence FOR:**
- Service crashed with "allocation failed" - could indicate hitting configured limit
- Deployment v1.1.0 may have included configuration changes
- No graceful degradation or memory pressure handling observed

**Evidence AGAINST:**
- Log message "High memory usage detected (85%)" implies monitoring thresholds exist
- Crash occurred at 980MB, suggesting limit is ~1GB (not obviously misconfigured for a gateway service)
- Memory growth trend shows unconstrained increase, not oscillation around a limit
- No "OOMKilled", "cgroup limit reached", or platform-level termination messages
- Configuration misconfiguration would not explain WHY memory grew 860MB in 100 seconds

**Confidence:** 10%  
**Status:** RULED_OUT (does not explain memory growth causation)

---

### Hypothesis 4: Dependency Memory Leak (Category: Dependencies/Runtime)

**Evidence FOR:**
- Memory leaks can cause gradual memory exhaustion
- Pre-incident memory (340MB) already elevated above 120MB baseline

**Evidence AGAINST:**
- Memory growth rate (8.6MB/second) too rapid for typical gradual leak
- Semantic hint "adds unbounded cache append" directly implicates application code, not dependency
- Incident triggered immediately after deployment with code change, not gradual degradation
- No dependency version changes mentioned in commit messages
- No garbage collection thrashing or runtime errors in logs

**Confidence:** 5%  
**Status:** RULED_OUT (timeline and semantic hint point to application logic)

---

### Hypothesis 5: Host-Level Resource Contention (Category: Infrastructure)

**Evidence FOR:**
- Memory pressure could result from multiple processes competing for resources
- Pre-incident memory elevation (340MB vs 120MB baseline) could indicate external pressure

**Evidence AGAINST:**
- Incident isolated to api-gateway service only
- No infrastructure alerts or co-located service failures mentioned
- Memory growth correlates precisely with service start time, not external events
- "allocation failed" error message indicates in-process limit, not system-wide exhaustion
- Deployment event timing rules out pre-existing host contention

**Confidence:** 5%  
**Status:** RULED_OUT (no cross-service impact or infrastructure alerts)

---

## Evidence Evaluation

**Temporal Correlation Analysis:**
- Critical code change (app.py with "unbounded cache append") committed 2026-02-05
- Incident manifested immediately upon deployment 2026-02-12 (within 2 minutes)
- No intermediate deployments or configuration changes documented
- Causal chain: Code Change → Deployment → Immediate Memory Growth → Crash

**Memory Growth Pattern:**
- Rate: 860MB growth in ~100 seconds = 8.6MB/second
- Trajectory: Exponential or linear unbounded growth, not cyclic
- Threshold breach: 85% warning → crash within 33 seconds
- Pattern consistent with: Append-only data structure with no eviction policy

**Log Signal Analysis:**
- Progression: INFO (startup) → WARN (memory) → ERROR (allocation) → ERROR (crash)
- No cache eviction, garbage collection, or memory recovery attempts logged
- Single-threaded failure cascade (no partial degradation)

**Cross-Hypothesis Fit:**
- Hypothesis 1 (Unbounded Cache): Explains timing, rate, trajectory, semantic hint ✓
- Hypothesis 2 (Traffic): Does not explain 8.6MB/sec growth or immediate timing ✗
- Hypothesis 3 (Configuration): Addresses symptom (crash), not cause (growth) ✗
- Hypothesis 4 (Dependency): Contradicts semantic hint and timeline ✗
- Hypothesis 5 (Infrastructure): No supporting cross-service evidence ✗

---

## Ruled-Out Hypotheses

1. **Traffic Spike (H2):** No traffic metrics provided, memory pattern inconsistent with request queuing, incident timing tied to deployment not traffic event.

2. **Memory Limit Misconfiguration (H3):** Does not explain causation of memory growth; 1GB limit is reasonable for gateway service; no platform-level termination signals.

3. **Dependency Memory Leak (H4):** Semantic hint directly implicates application code; growth rate too rapid for gradual leak; no dependency changes in commits.

4. **Host Resource Contention (H5):** No cross-service impact, infrastructure alerts, or system-level memory exhaustion indicators; timing excludes pre-existing contention.

---

## Primary Root Cause

**Hypothesis:** Unbounded Cache Growth (Application Logic Bug)

**Commit:** f09a9a5351e2a6724fa5436f6e0c2e55d8321237  
**Message:** "Add basic input validation to request handler"  
**File:** app.py  
**Semantic Hint:** "adds unbounded cache append"

**Causal Chain:**
1. Code change introduced append-only cache in app.py without eviction policy
2. Every incoming request (or validation result) appended to in-memory cache
3. Cache grew at ~8.6MB/second rate (likely caching large validation payloads or serialized request data)
4. Within 100 seconds, cache consumed 860MB beyond baseline
5. Memory allocator failed at 980MB (approaching container/process limit)
6. Process terminated due to allocation failure

**Mechanism:** The validation logic added in commit f09a9a5 likely caches validation results, request metadata, or parsed payloads in an unbounded data structure (e.g., Python list, dict without size limits). Each request appends data without eviction, causing O(n) memory growth with request count.

**Why This Hypothesis:**
- Direct semantic evidence ("unbounded cache append")
- Timing aligns perfectly with deployment
- Memory growth rate consistent with per-request append operation
- Eliminates all alternative explanations via lack of supporting evidence

---

## Contributing Factors

1. **No Memory Monitoring Thresholds in Application:** Warning triggered at 85%, but only 33 seconds before crash - insufficient time for intervention or graceful degradation.

2. **Lack of Circuit Breaker or Backpressure:** Service accepted requests unconstrained, accelerating cache growth.

3. **Missing Pre-Deployment Memory Testing:** Load testing with realistic traffic volume would have detected unbounded growth before production deployment.

4. **No Cache Size Limits in Code:** Language-level or framework-level constraints (e.g., LRU cache with max size) not employed.

---

## Detection & Prevention Gaps

**Detection Gaps:**
- No application-level memory profiling or heap size metrics exposed
- Memory alert threshold (85%) too close to failure point - recommend 60% warning, 75% critical
- No rate-of-change alerting (rapid memory growth detection)
- No per-request memory allocation tracking

**Prevention Gaps:**
- Code review missed "unbounded" append pattern (semantic hint indicates pattern was detectable)
- No automated static analysis for memory safety (e.g., cache size limits enforcement)
- Deployment pipeline lacks memory pressure testing or canary analysis
- Missing observability: cache size, entry count, eviction rate metrics

---

## Remediation & Follow-ups

**Immediate Actions:**
1. Revert commit f09a9a5 and redeploy previous stable version
2. Implement bounded cache with LRU eviction policy (recommend max 1000 entries or 100MB size limit)
3. Add cache size and entry count metrics to dashboard

**Short-Term (1 week):**
1. Add pre-deployment memory load test (simulate 1000 req/sec for 5 minutes, assert memory < 500MB)
2. Implement memory-based circuit breaker (reject requests when memory > 80%)
3. Review all caching logic across codebase for similar unbounded patterns

**Long-Term (1 month):**
1. Integrate static analysis tool to detect unbounded collection growth patterns
2. Establish memory budget per service tier (gateway: 512MB steady-state max)
3. Add application-level memory profiling to observability stack (heap snapshots on alert)
4. Implement canary deployment strategy with automated memory regression detection

---

## Remaining Uncertainty

1. **Exact Append Rate:** Unknown what data is being cached (request bodies? validation results? parsed objects?) - requires code inspection to determine per-request memory footprint.

2. **Traffic Volume During Incident:** No requests/second metrics provided - cannot calculate exact cache entry count or confirm 8.6MB/sec = X requests/sec * Y MB/request.

3. **Pre-Incident Memory Elevation:** Baseline 120MB → Pre-incident 340MB represents +220MB unexplained growth before peak incident. Possible explanations:
   - Gradual cache buildup over days (cache persists across restarts?)
   - Unrelated memory usage increase
   - Measurement timing artifact

4. **Deployment HEAD Commit:** Evidence shows "HEAD" as deployed commit hash instead of explicit SHA - cannot definitively confirm which commits were included in v1.1.0 deployment.

5. **Validation Logic Details:** Commit message references "input validation" - unclear if validation triggers caching of invalid requests, valid requests, or both.

---

## Confidence Summary

- **Primary root cause confidence:** 75%
- **Total hypothesis confidence budget used:** 100%
- **Uncertainty factors:**
  - No code-level inspection of app.py changes
  - Missing traffic volume metrics
  - Ambiguous deployment commit reference (HEAD)
  - Pre-incident memory elevation unexplained
  - Semantic hint provides strong signal but not definitive proof without code review

**Recommendation:** Conduct code review of app.py changes in commit f09a9a5 to confirm cache implementation details and update confidence to 95%+.

