# Incident Post-Mortem: INC-123

## Timeline

**2026-02-12 11:14:58 UTC** - Service api-gateway started  
**2026-02-12 11:15:02 UTC** - Deployment of version v1.1.0 completed  
**2026-02-12 11:16:10 UTC** - High memory usage warning triggered (85% utilization, ~340MB pre-incident → approaching limit)  
**2026-02-12 11:16:42 UTC** - Memory allocation failure logged  
**2026-02-12 11:16:43 UTC** - Process crashed (1 second after allocation failure)

**Total incident duration:** ~2 minutes from deployment to crash  
**Memory growth rate:** 860MB increase over ~2 minutes (~430MB/minute)

---

## Hypotheses Considered

### Hypothesis 1: Unbounded Cache Growth in Application Code (Category: Application Logic)

**Evidence FOR:**
- Semantic diff hint explicitly states "adds unbounded cache append" for `app.py` changes
- Memory baseline 120MB → peak 980MB (8.2x increase) in ~2 minutes
- Crash caused by allocation failure, consistent with memory exhaustion
- Deployment timestamp (11:15:02) immediately precedes memory issues (11:16:10)
- Commit f09a9a5351e2a6724fa5436f6e0c2e55d8321237 modified `app.py` within incident window

**Evidence AGAINST:**
- Extremely rapid growth (430MB/min) suggests high request volume or large object sizes
- No explicit log entries showing cache-specific warnings

**Confidence:** 85%  
**Status:** CONFIRMED (Primary Root Cause)

---

### Hypothesis 2: Traffic Spike or Unusual Load Pattern (Category: Traffic/Load)

**Evidence FOR:**
- Error rate increased from 0.1% baseline to 3.8% peak (38x multiplier)
- Rapid memory consumption could correlate with request volume

**Evidence AGAINST:**
- No log entries indicating traffic anomalies, DDoS patterns, or rate limiting
- Memory growth pattern (linear, rapid exhaustion) more consistent with per-request unbounded accumulation than volume spike
- Baseline traffic would need to be extraordinarily high to cause 860MB growth in 2 minutes without caching bug
- Error rate spike occurred AFTER memory warnings, suggesting consequence not cause

**Confidence:** 5%  
**Status:** RULED_OUT (Contributing factor, not root cause)

---

### Hypothesis 3: Infrastructure Resource Limits Too Restrictive (Category: Infrastructure)

**Evidence FOR:**
- Process crashed with allocation failure
- Memory limit appears to be ~1GB based on crash point

**Evidence AGAINST:**
- Baseline memory usage was stable at 120MB before deployment
- Memory grew 8x within minutes of code deployment, not infrastructure change
- No infrastructure changes logged in deployment events or commits
- Crash was symptom of exhaustion, not inappropriate limit

**Confidence:** 0%  
**Status:** RULED_OUT (Limit was appropriate; application violated it)

---

### Hypothesis 4: Dependency or Runtime Memory Leak (Category: Dependencies/Runtime)

**Evidence FOR:**
- Memory leaks are common in runtime environments and third-party libraries

**Evidence AGAINST:**
- No dependency updates in commits within incident window
- Semantic hint specifically identifies application code (`app.py`) as source
- Timing precisely correlates with application deployment, not runtime update
- Growth rate too rapid and deterministic for typical runtime leak patterns

**Confidence:** 3%  
**Status:** RULED_OUT

---

### Hypothesis 5: Configuration Misconfiguration in Deployment (Category: Configuration)

**Evidence FOR:**
- Incident began immediately after deployment v1.1.0

**Evidence AGAINST:**
- No configuration files modified in diffs (no .yaml, .json, .env, etc.)
- Semantic hint points to code logic, not configuration values
- Memory exhaustion pattern consistent with code behavior, not misconfigured limits or parameters

**Confidence:** 2%  
**Status:** RULED_OUT

---

## Evidence Evaluation

**Cross-Hypothesis Analysis:**

The semantic diff hint "adds unbounded cache append" is the most direct evidence and uniquely supports Hypothesis 1. The timing correlation (deployment → memory spike → crash within 2 minutes) combined with the exponential memory growth pattern (120MB → 980MB) creates a clear causal chain pointing to application-level unbounded accumulation.

Alternative hypotheses (traffic spike, infrastructure limits, dependencies, configuration) lack positive evidence and have strong counter-evidence:
- No traffic anomalies logged
- Infrastructure unchanged
- No dependency updates
- No configuration changes

The error rate increase (0.1% → 3.8%) appears to be a downstream consequence of memory pressure causing request failures, not an independent causal factor.

**Confidence Budget Allocation:**
- Hypothesis 1: 85% (supported by direct evidence + elimination)
- Hypotheses 2-5: 10% combined (residual uncertainty)
- Unexplained variance: 5%

---

## Ruled-Out Hypotheses

1. **Infrastructure Resource Limits (H3):** Ruled out due to absence of infrastructure changes and stability of 120MB baseline before deployment. The limit was appropriate; the application violated it.

2. **Dependency Memory Leak (H4):** Ruled out due to no dependency changes in incident window and semantic hint explicitly identifying `app.py` as source.

3. **Configuration Misconfiguration (H5):** Ruled out due to absence of configuration file changes in diffs and behavioral signature matching code logic flaw.

4. **Traffic Spike as Root Cause (H2):** Ruled out as primary cause due to lack of traffic anomaly logs and timing suggesting error rate was consequence of memory exhaustion. May have contributed as amplifier.

---

## Primary Root Cause

**Root Cause:** Unbounded cache growth introduced in application code (`app.py`)

**Commit:** f09a9a5351e2a6724fa5436f6e0c2e55d8321237 (2026-02-05T15:46:43Z)  
**Message:** "Add basic input validation to request handler"

**Causal Chain:**
1. Code change in `app.py` introduced unbounded cache append logic (per semantic diff analysis)
2. Deployed as v1.1.0 on 2026-02-12T11:15:02Z
3. Each incoming request appended data to cache without eviction policy
4. Memory grew from 120MB baseline to 980MB peak over ~2 minutes (~430MB/min)
5. Memory utilization reached 85% at 11:16:10Z (warning triggered)
6. Continued growth exhausted available memory
7. Memory allocation failed at 11:16:42Z
8. Process crashed 1 second later at 11:16:43Z

**Mechanism:** The cache implementation lacked:
- Maximum size limit (bounded capacity)
- Eviction policy (LRU, TTL, etc.)
- Memory monitoring with backpressure

---

## Contributing Factors

1. **Request Volume:** While not the root cause, normal or elevated traffic exercised the unbounded cache rapidly, accelerating exhaustion timeline from theoretical hours/days to <2 minutes.

2. **Lack of Pre-Production Load Testing:** The unbounded growth pattern would have been detectable in staging environment with representative load.

3. **Missing Memory Guardrails:** No application-level memory budget enforcement to gracefully degrade or reject requests before OOM crash.

4. **Delayed Warning Threshold:** High memory warning at 85% utilization provided only 72 seconds before crash (insufficient for human intervention).

---

## Detection & Prevention Gaps

**Detection Gaps:**
1. No application-level metrics for cache size/growth rate (would have provided leading indicator)
2. Memory warning threshold (85%) triggered too late for actionable response
3. No alerting on rate-of-change for memory metrics (slope detection)
4. Code review did not catch semantic hint of "unbounded" operation

**Prevention Gaps:**
1. No static analysis or linting rules to detect unbounded collection growth patterns
2. Missing load testing in CI/CD pipeline to validate memory behavior under traffic
3. No required chaos engineering scenarios for memory exhaustion
4. Deployment lacked canary or gradual rollout to limit blast radius

---

## Remediation & Follow-ups

**Immediate (Complete within 24h):**
1. Revert commit f09a9a5351e2a6724fa5436f6e0c2e55d8321237 or patch `app.py` to add bounded cache with LRU eviction (max size: 1000 entries or 50MB)
2. Add application-level cache size metric (`cache_entries_total`, `cache_memory_bytes`)
3. Lower memory warning threshold to 70% with runbook for investigation

**Short-term (Complete within 1 week):**
4. Implement cache TTL (e.g., 5-minute expiration) in addition to size limit
5. Add memory budget enforcement: reject new requests if cache exceeds 80% of configured limit
6. Add integration test: "cache does not grow beyond configured limit under sustained load"
7. Configure memory profiling in staging environment

**Long-term (Complete within 1 month):**
8. Add static analysis rule to CI: flag collections without size bounds
9. Implement canary deployment strategy (5% → 50% → 100% over 30 minutes with automated rollback)
10. Add chaos engineering scenario: memory pressure test in staging weekly
11. Require load testing for all changes touching caching/storage logic

---

## Remaining Uncertainty

**What we know with high confidence:**
- Unbounded cache in `app.py` caused memory exhaustion (85% confidence)
- Deployment v1.1.0 introduced the vulnerability (timing + semantic hint)

**What remains uncertain:**
1. **Exact request pattern that triggered rapid growth:** Was it uniform traffic or specific endpoint/payload size? (Would require access to request logs with cache key distribution)
2. **Why 2-minute timeline:** Was traffic volume unusually high, or are cached objects unexpectedly large? (Need request rate metrics + object size profiling)
3. **Whether partial data loss occurred:** Did in-flight requests lose data during crash? (Need transaction log analysis)
4. **Why code review didn't catch this:** Was semantic hint visible during review, or generated post-merge? (Need code review tool audit)

**Confidence in uncertainty estimation:** Medium. The core causal chain is well-supported, but operational details (traffic characteristics, cache key cardinality) would increase confidence from 85% → 95%+.

---

## Confidence Summary

- **Primary root cause confidence:** 85%
- **Total hypothesis confidence budget used:** 95%
- **Remaining unexplained variance:** 5%

**Uncertainty factors:**
1. Lack of request-level logs to confirm cache key distribution (reduces confidence by ~10%)
2. No direct code inspection of `app.py` changes (relying on semantic hint, reduces confidence by ~5%)
3. Potential interaction effects between input validation and cache logic not fully explored (residual 5%)

**Assessment reliability:** High. The convergence of semantic hint, timing, memory metrics, and hypothesis elimination creates a robust evidential chain despite operational data gaps.

