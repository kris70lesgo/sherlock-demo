# Incident Post-Mortem: INC-999

## Timeline
- 2015-03-16T23:17:43Z: WARN performance_degradation (count: 1)
- 2015-03-16T23:17:46Z: WARN io_error (count: 1)
- 2015-03-16T23:17:47Z: WARN resource_allocation_failure (count: 9)
- 2015-03-16T23:17:58Z: ERROR process_crash (count: 2)

## Hypotheses Considered

### Hypothesis 1: Application memory growth from unbounded request accumulation (Category: Application)
**Evidence FOR:**
- Logs show high memory usage followed by memory allocation failure and a crash.
- Memory metric increased sharply within the incident window.

**Evidence AGAINST:**
- No direct code change in the commit window to confirm a recent introduction.
- Limited log coverage; no explicit allocation stack traces.

**Confidence:** 55%
**Status:** POSSIBLE

### Hypothesis 2: Resource exhaustion due to load spike (Category: Traffic)
**Evidence FOR:**
- Error rate increased during the same window as memory growth.
- Sudden resource pressure can trigger allocation failures.

**Evidence AGAINST:**
- No explicit traffic metrics in the evidence bundle.
- Logs do not mention request volume anomalies.

**Confidence:** 15%
**Status:** RULED_OUT

### Hypothesis 3: Dependency failure cascading into retries (Category: Dependency)
**Evidence FOR:**
- Error rate spike could be consistent with downstream instability.

**Evidence AGAINST:**
- No dependency error logs or timeout messages in the scoped logs.
- Memory growth suggests local resource pressure instead.

**Confidence:** 10%
**Status:** RULED_OUT

## Evidence Evaluation
- Memory usage spiked sharply in the incident window, with errors indicating allocation failure and process crash.
- Error rate increased but no explicit external dependency errors or traffic spikes are in evidence.

## Ruled-Out Hypotheses
- Traffic spike (ruled out due to missing traffic evidence).
- Dependency failure (ruled out due to lack of supporting logs).

## Primary Root Cause
Unbounded memory growth in the application leading to allocation failure and crash.
**Commit:** unknown - no commits in window
**Causal Chain:** Memory accumulation increased → allocation failure → worker crash → error rate spike.

## Contributing Factors
- Limited log coverage and no traffic telemetry in the evidence bundle.
- Rapid memory growth without backpressure signals.

## Detection & Prevention Gaps
- Missing alerts for memory growth thresholds before failure.
- Lack of traffic/request volume telemetry in scope.

## Remediation & Follow-ups
- Add memory growth alerts with lower thresholds.
- Add request volume and latency metrics to evidence scope.
- Audit in-memory caches for bounded growth patterns.

## Remaining Uncertainty
- No direct evidence of a code-level change or traffic surge in the bundle.

## Confidence Summary
- Primary root cause confidence: 55%
- Total hypothesis confidence budget used: 80%
- Uncertainty factors: limited telemetry, missing dependency signals
