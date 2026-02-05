# Design Document: Copilot Sherlock

## Problem Statement

Incident response typically requires manual correlation of git history, deployment logs, metrics, and application logs. This is:
- **Time-consuming**: Engineers spend 20-60 minutes gathering context
- **Error-prone**: Critical evidence may be overlooked under pressure
- **Inconsistent**: RCA quality varies by engineer experience

Copilot Sherlock automates evidence collection and uses GitHub Copilot CLI as a reasoning engine to perform structured root cause analysis.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Sherlock CLI                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Evidence Collection Layer                                   │
│  ├─ Git history (log, diff)                                 │
│  ├─ Deployment events (JSON)                                │
│  ├─ Application logs                                        │
│  └─ Metrics (memory, errors)                                │
│                          ↓                                   │
│  Prompt Generation                                           │
│  ├─ Structured SRE post-mortem template                     │
│  ├─ Evidence injection                                      │
│  └─ Save prompt for auditability                            │
│                          ↓                                   │
├─────────────────────────────────────────────────────────────┤
│              GitHub Copilot CLI (Reasoning Engine)           │
│  ├─ Cross-source correlation                                │
│  ├─ Causal chain analysis                                   │
│  ├─ Non-cause elimination                                   │
│  └─ Structured RCA output                                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Output Persistence                                          │
│  ├─ Post-mortem report (Markdown)                           │
│  └─ Investigation prompt (audit trail)                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Responsibility Split

### What Sherlock Does
- **Evidence collection**: Deterministic data gathering from git, logs, metrics
- **Data normalization**: Formats evidence into structured prompt
- **Orchestration**: Invokes Copilot CLI at the right time with right context
- **Persistence**: Saves both prompt and analysis for auditability
- **UX**: Terminal output, file management, error handling

### What GitHub Copilot CLI Does
- **Cross-source correlation**: Connects deployment timing with metric spikes and log errors
- **Causal reasoning**: Distinguishes primary root cause from contributing factors
- **Non-cause elimination**: Explicitly rules out red herrings (e.g., benign commits)
- **Confidence scoring**: Quantifies certainty based on evidence strength
- **Structured synthesis**: Generates enterprise-grade post-mortem with timeline, remediation, and gaps

**Key insight**: Sherlock is the evidence pipeline. Copilot CLI is the reasoning engine.

## Why a CLI

1. **Repository context**: Runs in the repo, has direct access to git history
2. **Terminal-native workflow**: Engineers already live in terminals during incidents
3. **Scriptable**: Can be integrated into runbooks or CI/CD
4. **Transparent**: All inputs/outputs are files, easy to inspect
5. **No external infrastructure**: Zero dependencies beyond git and gh CLI

## Limitations

### Current Scope
- **Simulated evidence**: Uses pre-generated logs and metrics (not live ingestion)
- **Single incident**: Designed for one-off investigations, not continuous monitoring
- **Git-based only**: Assumes incident relates to recent code changes
- **No automated remediation**: Generates recommendations but doesn't execute rollbacks

### Design Constraints
- **Copilot CLI dependency**: Requires GitHub Copilot CLI to be installed and authenticated
- **Prompt size limits**: Very large repos may exceed LLM context windows
- **Deterministic evidence only**: Does not handle dynamic or streaming data sources

### Production Roadmap
To use this in production environments:
- Integrate with observability platforms (Datadog, Prometheus, CloudWatch)
- Add real-time log streaming and metric queries
- Implement incident correlation across multiple services
- Add automated rollback capability with approval workflows
