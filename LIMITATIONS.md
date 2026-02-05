# Limitations

This document outlines the current scope boundaries and design constraints of Copilot Sherlock.

## Demo Scope

### Simulated Evidence
- Uses pre-generated logs, metrics, and deployment data
- No real-time ingestion from production systems
- Evidence files are static fixtures in `evidence/` directory

**Why**: Demonstrates the reasoning capability without requiring production infrastructure access

### Single Incident Model
- Designed for one-off investigations (e.g., `INC-123`)
- Does not track incidents over time or correlate across multiple events
- No incident state management or workflow tracking

**Why**: Focuses on core RCA capability rather than incident management features

### Git-Centric Approach
- Assumes incidents are caused by or correlated with recent code changes
- May miss issues from configuration drift, infrastructure changes, or external dependencies
- Limited visibility into non-code-based root causes

**Why**: Git provides deterministic, auditable history ideal for demonstrating causal reasoning

## Technical Constraints

### Copilot CLI Dependency
- Requires GitHub Copilot CLI to be installed (`gh copilot`)
- Needs active GitHub Copilot subscription and authentication
- Subject to Copilot CLI's model capabilities and rate limits

**Impact**: Cannot run without GitHub Copilot access

### Context Window Limits
- Very large repositories may exceed LLM context windows
- Diffs larger than ~50KB may need truncation
- Log files should be pre-filtered to relevant time windows

**Workaround**: Sherlock currently collects only HEAD commit and recent logs

### Evidence Format Assumptions
- Expects JSON for deployments and metrics
- Assumes plaintext application logs
- Git history must be accessible via standard git commands

**Impact**: Non-standard logging systems require preprocessing

## No Automated Remediation

### Analysis Only
- Generates recommendations but does not execute changes
- No automated rollback, restart, or configuration updates
- No integration with deployment pipelines or orchestration tools

**Why**: Human-in-the-loop is intentional for safety and learning

### No Real-Time Alerting
- Does not monitor systems or trigger on anomalies
- Requires manual invocation after incident detection
- Not designed as a replacement for observability platforms

**Why**: Focuses on investigation depth over real-time response

## Production Readiness Gap

To deploy this in a production environment, the following would be needed:

1. **Live Data Integration**
   - API clients for Datadog, Prometheus, CloudWatch, etc.
   - Log streaming from centralized logging systems
   - Dynamic metric queries with time-range filtering

2. **Multi-Service Support**
   - Correlation across microservices
   - Distributed tracing integration
   - Dependency graph awareness

3. **Operational Features**
   - Incident management integration (PagerDuty, Opsgenie)
   - Automated rollback with approval workflows
   - Runbook execution capabilities

4. **Security & Compliance**
   - PII redaction in logs
   - Audit logging of investigations
   - Role-based access control

5. **Scalability**
   - Incremental evidence collection for large repos
   - Caching and summarization for repeated investigations
   - Parallel analysis for multi-region incidents

## Why Document Limitations?

Engineering honesty signals:
- **Production awareness**: Understanding what's demo vs production-ready
- **Scope discipline**: Focused on solving one problem well
- **Credibility**: Prevents over-promising and mis-evaluation
- **Roadmap clarity**: Shows thought about future development

These limitations are design choices, not oversights.
