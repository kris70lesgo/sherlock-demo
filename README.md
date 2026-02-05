# Copilot Sherlock 🔍

Copilot Sherlock is a CLI tool that performs automated incident investigation and root cause analysis using GitHub Copilot CLI.

## What it does

With a single command, Sherlock:
- Analyzes recent git commits and diffs
- Correlates deployments with logs and metrics
- Identifies the most likely root cause
- Generates a blameless post-mortem with confidence scores

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
- Correlates evidence across multiple sources
- Performs causal chain analysis
- Distinguishes root cause from contributing factors
- Explicitly rules out non-causes
- Generates structured post-mortem with confidence scores

## Demo Scenario

This repo includes a controlled incident where a caching change introduces an unbounded memory leak. Sherlock correctly identifies the offending commit, explains the failure mechanism, and suggests remediation.

## Disclaimer

This demo uses simulated logs, metrics, and deployments. The architecture is designed to support real production data sources.
