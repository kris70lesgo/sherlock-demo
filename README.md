# Copilot Sherlock 🔍

Copilot Sherlock is a CLI tool that performs automated incident investigation and root cause analysis using GitHub Copilot CLI.

## What it does

With a single command, Sherlock:
- **Phase 2**: Scopes evidence to incident time window (deployment-anchored commit narrowing)
- **Phase 1**: Normalizes and validates evidence (timestamps, integrity checks)
- **Phase 3**: Enforces hypothesis-based reasoning (enumeration → elimination → root cause)
- **Phase 4**: Human review & decision accountability (AI proposes, humans decide, system records)
- Uses GitHub Copilot CLI for cross-source correlation and causal analysis
- Generates enterprise-grade post-mortem with explicit confidence quantification
- Creates complete audit trail with governance backbone (review records)

## Usage

```bash
./sherlock
```

## Why Copilot CLI

Copilot Sherlock uses GitHub Copilot CLI as an investigative reasoning engine:

- Runs inside the repository
- Operates directly on git history and operational data
- Synthesizes evidence across multiple sources
- Produces structured post-mortems in seconds

## How Copilot CLI Is Used

Copilot Sherlock uses GitHub Copilot CLI as the core reasoning engine. For each investigation:
- Sherlock collects deterministic evidence (git history, diffs, logs, metrics)
- A structured investigation prompt is generated and saved
- GitHub Copilot CLI performs cross-source correlation and RCA
- Both the prompt and Copilot's post-mortem output are persisted for auditability

### What Sherlock Does vs What Copilot CLI Does

**Sherlock (evidence pipeline):**
- Collects evidence from git, logs, deployments, metrics
- Normalizes data into structured format
- Orchestrates the investigation workflow
- Persists artifacts (prompt + report)

**GitHub Copilot CLI (reasoning engine):**
- Enumerates 3-5 competing hypotheses across different categories (Application/Infra/Traffic/Config/Dependency)
- Evaluates evidence FOR and AGAINST each hypothesis
- Explicitly eliminates ruled-out hypotheses with reasoning
- Correlates evidence across multiple sources
- Performs causal chain analysis
- Distinguishes root cause from contributing factors
- Generates structured post-mortem with confidence discipline (total ≤100%)

## Demo Scenario

This repo includes a controlled incident where a caching change introduces an unbounded memory leak. Sherlock correctly identifies the offending commit, explains the failure mechanism, and suggests remediation.

**Phase 3 Reasoning Quality**: See [PHASE3-SUMMARY.md](PHASE3-SUMMARY.md) for details on hypothesis-based reasoning implementation.

**Phase 4 Governance**: See [PHASE4-SUMMARY.md](PHASE4-SUMMARY.md) for human-in-the-loop decision accountability and review record schema.

## Architecture

See [DESIGN.md](DESIGN.md) for system architecture, responsibility separation, and production roadmap.

See [LIMITATIONS.md](LIMITATIONS.md) for demo scope constraints and engineering honesty about what's simulated vs production-ready.

## Complete Artifact Trail

After investigation, Sherlock generates:
- `incident-bundle-INC-123.json` - Normalized evidence (Phase 1)
- `scope-audit-INC-123.json` - Scoping decisions (Phase 2)
- `copilot-prompt-INC-123.txt` - AI reasoning input (Phase 3)
- `postmortem-INC-123.md` - AI-generated analysis (Phase 3)
- `review-record-INC-123.yaml` - Human decision & accountability (Phase 4)

**Nothing is overwritten. Nothing is hidden. Complete forensic trail.**
