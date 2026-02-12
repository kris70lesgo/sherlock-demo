# Multi-Service Incident Coordination

## Overview

Real production incidents rarely respect service boundaries. A database slowdown triggers API timeouts, proxy retries amplify load, and monitoring alerts fire across multiple teams. **Most incident tools force a false choice:**

1. **One RCA for all services** → Violates team autonomy, creates bottlenecks
2. **Separate incidents per service** → Loses causal context, duplicates work

Sherlock's multi-service coordination **preserves service sovereignty while modeling reality:**

- **Incident ≠ Service RCA:** One incident coordinates multiple service-specific analyses
- **Declared roles:** Incident commander explicitly assigns service relationships (no AI correlation)
- **Independent governance:** Each service follows its own approval requirements
- **Mechanical coordination:** Primary candidate must be finalized to close incident

---

## Core Constraint: Service Sovereignty

**Every service keeps its own root cause analysis, governance, and remediation.**

```
Incident INC-456 (Multi-Service)
  ├─ storage_service.yaml      (primary_candidate)
  │    └─ Must be FINALIZED to close incident
  ├─ api-gateway.yaml          (downstream_impact)
  │    └─ Independent review, may have contributing factors
  └─ auth-service.yaml         (symptom_only)
       └─ No remediation required (alerts only, no fault)
```

**No shared postmortems. No unified approvals. No AI correlation.**

---

## Coordination Record

The **Incident Coordination Record (ICR)** declares service relationships **without inference.**

### Example: `incidents/INC-456.coordination.yaml`

```yaml
incident_id: INC-456
incident_title: "Cascading Latency - Storage, API Gateway, Auth"
incident_severity: SEV1

declared_by:
  name: Alice Chen
  role: Incident Commander
  team: SRE-Core
  timestamp: "2024-01-15T18:35:00Z"

services:
  - name: storage_service
    role: primary_candidate
    justification: "Storage latency preceded all other alerts by 5 minutes"
    
  - name: api-gateway
    role: downstream_impact
    justification: "API Gateway retry storm amplified storage issues"
    
  - name: auth-service
    role: symptom_only
    justification: "First alert but no auth-specific failures identified"

coordination_notes:
  - "Storage latency began at 18:25 UTC (5 minutes before auth alerts)"
  - "API Gateway retries escalated after storage degradation"
  - "No auth service defects identified - timeouts were symptom of upstream issues"
```

### Service Roles

| Role | Meaning | Requirements | Remediation |
|------|---------|--------------|-------------|
| **primary_candidate** | Most likely contains root cause | Must be FINALIZED to close incident | Required |
| **downstream_impact** | Affected by primary cause | Independent review | Required if faults found |
| **symptom_only** | Surfaced alert, no fault expected | Standard review | Skipped unless issues found |

**Important:** Roles are DECLARED by incident commander based on timeline, not inferred by AI.

---

## Usage

### 1. Create Coordination Record

Incident commander creates ICR declaring service relationships:

```bash
incidents/INC-456.coordination.yaml
```

### 2. Run Per-Service Investigation

Each service investigates using the SAME pipeline with service flag:

```bash
# Storage team investigates storage aspect
./sherlock investigate INC-456 --service storage_service

# API Gateway team investigates retry behavior
./sherlock investigate INC-456 --service api-gateway

# Auth team investigates alert (may find no fault)
./sherlock investigate INC-456 --service auth-service
```

**Each invocation:**
- Loads service-specific evidence
- Runs independent AI analysis
- Enforces service-specific governance
- Writes service-scoped IKR: `incidents/INC-456-storage_service.yaml`

### 3. Generate Multi-Service Summary

After all services complete analysis:

```bash
./sherlock summarize INC-456
```

**Output:** `reports/incident-summary-INC-456.md`  
**Contains:** Aggregated view WITHOUT violating sovereignty

---

## Artifacts Generated

### Per-Service Artifacts

Each service generates independent artifacts:

```
reports/
  ├─ postmortem-INC-456-storage_service.md
  ├─ postmortem-INC-456-api-gateway.md
  ├─ postmortem-INC-456-auth-service.md
  ├─ review-record-INC-456-storage_service.yaml
  ├─ review-record-INC-456-api-gateway.yaml
  └─ review-record-INC-456-auth-service.yaml

incidents/
  ├─ INC-456.coordination.yaml              # Incident coordination
  ├─ INC-456-storage_service.yaml           # Service-specific IKR
  ├─ INC-456-api-gateway.yaml               # Service-specific IKR
  └─ INC-456-auth-service.yaml              # Service-specific IKR
```

### Multi-Service Summary

```
reports/incident-summary-INC-456.md
```

**Summary aggregates facts without synthesis:**
- Service roles and justifications
- Per-service determinations (ACCEPTED/MODIFIED/REJECTED)
- Service-local root causes (NOT correlated)
- Action items per service
- Coordination notes (timeline, not inference)

---

## Governance Rules

### 1. Service Ownership Enforced

Each service's review must be approved by authorized personnel:

```bash
# Storage team can only approve storage analysis
Reviewer: Bob Martinez (Storage SRE)
Service: storage_service  ✓

# Storage team CANNOT approve API Gateway analysis
Reviewer: Bob Martinez (Storage SRE)
Service: api-gateway      ❌ REJECTED
```

**Validation:** `services/validate-service-policy.py`

### 2. Primary Candidate Required

Incident cannot be closed until primary candidate is FINALIZED:

```bash
# Before storage finalization
./sherlock summarize INC-456
⚠️ Incident Closure: Awaiting primary candidate finalization (storage_service)

# After storage finalization
./sherlock summarize INC-456
✓ Incident Closure: Primary candidate finalized (storage_service)
```

### 3. Symptom-Only Services Skip Remediation

Services with `symptom_only` role skip Phase 6 (operational integration):

```
Phase 6: Operational Integration - SKIPPED
Service role: symptom_only
This service surfaced alerts but contains no fault.
No remediation required - notification only.
```

---

## Validation & Safety

### Coordination Validation Script

`incidents/validate-coordination.py` enforces:

1. **Service in scope:** Requested service is declared in ICR
2. **No unauthorized services:** Cannot investigate service not in ICR
3. **Primary candidate finalization:** Incident closure blocked until primary finalized
4. **Display context:** Shows incident coordination before investigation

**Usage:**

```bash
# Display coordination context
python3 incidents/validate-coordination.py INC-456 storage_service display

# Validate service in scope
python3 incidents/validate-coordination.py INC-456 storage_service validate

# Check primary candidate finalization
python3 incidents/validate-coordination.py INC-456 check-primary
```

### Failure Modes

| Scenario | Behavior |
|----------|----------|
| Missing coordination file | Single-service mode (no error) |
| Service not in ICR | ❌ Abort with error |
| Primary not finalized | ⚠️ Warning in summary, incident not closed |
| Cross-service approval | ❌ Service ownership validation fails |

---

## Design Principles

### 1. Incident ≠ RCA

**Incident** = User-facing problem requiring coordination  
**RCA** = Service-specific root cause analysis

One incident can have **multiple RCAs** (one per service).

### 2. No AI Correlation

**AI does NOT:**
- Infer service relationships
- Correlate logs across services
- Generate unified root cause
- Determine which service is "at fault"

**Humans declare:**
- Service roles (primary_candidate, downstream_impact, symptom_only)
- Timeline relationships (coordination_notes)
- Which service to investigate

### 3. Governance Preserved

Each service maintains:
- Own approval requirements (T0/T1/T2 reviewers)
- Own action item workflows
- Own remediation decisions

**No shortcuts. No exceptions. No "incident commander override."**

### 4. Mechanical Coordination

Coordination is **mechanical, not magical:**

- ICR declares relationships → Explicit accountability
- Primary candidate required → Clear closure criteria
- Per-service execution → Existing pipeline reused
- Summary aggregates → No synthesis

---

## Real-World Example

### Scenario: Database Slowdown Cascade

**18:25 UTC:** Storage latency spikes (disk I/O saturation)  
**18:30 UTC:** Auth service alerts fire (first alert, but symptom not cause)  
**18:32 UTC:** API Gateway error rate increases (retry storm)

### Investigation Flow

#### Step 1: Incident Commander Creates ICR

```yaml
# incidents/INC-456.coordination.yaml
incident_id: INC-456
incident_title: "Cascading Latency - Storage, API Gateway, Auth"

services:
  - name: storage_service
    role: primary_candidate
    justification: "Storage latency preceded all other alerts by 5 minutes"
  
  - name: api-gateway
    role: downstream_impact
    justification: "Retry storm amplified storage issues"
  
  - name: auth-service
    role: symptom_only
    justification: "First alert but no auth-specific failures"
```

#### Step 2: Per-Service Investigations

```bash
# Storage SRE investigates storage
./sherlock investigate INC-456 --service storage_service
# Determination: ACCEPTED - disk I/O saturation from query spike

# API Gateway team investigates retry behavior  
./sherlock investigate INC-456 --service api-gateway
# Determination: MODIFIED - retry backoff insufficient (contributing factor)

# Auth team investigates timeouts
./sherlock investigate INC-456 --service auth-service
# Determination: REJECTED - no auth-specific fault, symptom only
```

#### Step 3: Incident Summary

```bash
./sherlock summarize INC-456
```

**Output:**

```markdown
## Services Involved

- **storage_service** (primary_candidate)
  ✓ STATUS: FINALIZED
  Root Cause: Query optimizer regression → disk I/O saturation
  
- **api-gateway** (downstream_impact)
  ✓ STATUS: FINALIZED
  Root Cause: Insufficient retry backoff (contributing factor)
  
- **auth-service** (symptom_only)
  ✓ STATUS: FINALIZED
  Determination: No auth-specific fault identified

## Incident Closure

✓ Primary candidate finalized (storage_service)
```

---

## Integration Points

### Sherlock Pipeline

Multi-service coordination integrates with existing phases:

- **Phase 1-2:** Evidence filtered per service (if `--service` flag present)
- **Phase 3:** AI analyzes service-specific evidence only
- **Phase 4:** Service ownership enforced (cannot review other team's service)
- **Phase 5:** IKR filename includes service: `INC-456-storage_service.yaml`
- **Phase 6:** Skipped for `symptom_only` services
- **Phase 7:** Trust artifacts reference service-scoped analysis

### Service Ownership

Service policies define authorized reviewers per service:

```yaml
# services/storage_service.yaml
owners:
  primary:
    team: Storage-SRE
    members: [Bob Martinez, Carol Wu]
```

**Enforcement:** Phase 4 validates reviewer is authorized for service being analyzed.

---

## FAQ

### Q: Why not correlate logs across services?

**A:** Service sovereignty. Each team owns their analysis. AI correlation creates ambiguous accountability.

### Q: What if multiple services have faults?

**A:** Each service gets independent RCA. Summary aggregates findings without declaring "THE root cause."

### Q: Can incident commander override service determination?

**A:** No. Service ownership is enforced mechanically. IC declares coordination, not conclusions.

### Q: What if primary candidate rejects analysis?

**A:** IC can reassign `primary_candidate` role to different service. Coordination record is updated.

### Q: How do I know which service to investigate?

**A:** Check coordination record: `cat incidents/INC-456.coordination.yaml`

---

## Commands Reference

```bash
# Investigate specific service
./sherlock investigate <incident_id> --service <service_name>

# Generate multi-service summary
./sherlock summarize <incident_id>

# Validate coordination
python3 incidents/validate-coordination.py <incident_id> <service_name> validate

# Display coordination context
python3 incidents/validate-coordination.py <incident_id> <service_name> display

# Check primary candidate status
python3 incidents/validate-coordination.py <incident_id> check-primary
```

---

## File Specifications

### Coordination Record Schema

```yaml
incident_id: string          # Unique incident identifier
incident_title: string       # Human-readable title
incident_severity: string    # SEV0/SEV1/SEV2/...

declared_by:
  name: string              # Incident commander name
  role: string              # Role (Incident Commander, SRE Lead, etc.)
  team: string              # Team affiliation
  timestamp: ISO8601        # When coordination was declared

services:
  - name: string            # Service identifier (matches services/*.yaml)
    role: enum              # primary_candidate | downstream_impact | symptom_only
    justification: string   # Why this service has this role

coordination_notes:
  - string                  # Timeline facts, NOT inferences
```

### Service-Specific IKR

Same schema as single-service IKR, filename includes service:

```
incidents/INC-456-storage_service.yaml
```

### Multi-Service Summary

Generated markdown, not YAML. Human-readable aggregation.

---

## See Also

- **Service Ownership:** `services/README.md`
- **Standard Investigation:** `DEMO.md`
- **Architectural Invariants:** `INVARIANTS.md`
- **Phase Documentation:** `phase*/README.md`
