# Sherlock: AI-Assisted Incident Investigation System

**Purpose:** Automated evidence collection + AI reasoning + human decisioning + mechanical governance

**Not:** An AI that fixes your incidents. A system that ensures no human shortcuts during RCA.

---

## The Problem

Real incident response fails at three points:

1. **Evidence Gathering (20-60 minutes):** Engineers manually correlate git, logs, metrics, deployments
2. **Root Cause Analysis (inconsistent):** Quality depends on engineer experience and time pressure
3. **Organizational Memory (broken):** RCAs live in docs that are never queried again

**Result:** Duplicate incidents, lost context, no institutional learning.

---

## Sherlock's Solution

**Seven-phase pipeline** where humans control decisions but system enforces accountability:

```
Phase 1: Evidence      → Validate git, logs, metrics, deployments
Phase 2: Scoping       → Reduce noise, focus on incident window
Phase 3: AI Reasoning  → GitHub Copilot CLI generates hypothesis + RCA
Phase 4: Human Review  → Human decides: ACCEPT | MODIFY | REJECT
Phase 5: Memory Write  → Append-only institutional memory
Phase 6: Actions       → Create tickets, notify teams (read-only)
Phase 7: Trust         → Cryptographic provenance, external audit
```

**Key Architecture Principle:**  
Evidence → AI proposes → Human decides → System remembers → Actions execute → Trust verifies

---

## Why This Architecture

### Constraint 1: AI Cannot Be Trusted With Decisions

**Problem:** LLMs hallucinate. Confidence scores are unreliable.  
**Solution:** AI proposes 3+ hypotheses. Human reviews evidence, makes final call.

**Enforcement:**
- Phase 4 requires explicit human decision (ACCEPT/MODIFY/REJECT)
- AI output preserved even if rejected (audit trail)
- Decision authority tracked (name, role, timestamp)

### Constraint 2: Evidence Must Be Validated Before AI

**Problem:** Garbage in → garbage out. AI will reason over corrupted data.  
**Solution:** Phase 1 validates schema, Phase 2 reduces scope mechanically.

**Contracts:**
- Each evidence file has required schema (see `contracts/`)
- Scoping eliminates events outside incident time window
- AI never sees unvalidated data

### Constraint 3: Institutional Memory Must Be Append-Only

**Problem:** Overwriting past incidents destroys learning.  
**Solution:** Phase 5 writes to `incidents/*.yaml` with duplicate detection.

**Guarantee:**
- IKRs (Incident Knowledge Records) are immutable once written
- Queries use pattern matching (no embeddings, no magic)
- System refuses to overwrite existing incident ID

### Constraint 4: Actions Must Not Influence Reasoning

**Problem:** Auto-creating tickets could bias future AI analysis.  
**Solution:** Phase 6 runs after Phase 5 memory write completes.

**Isolation:**
- JIRA/GitHub/PagerDuty integrations are read-only from AI perspective
- Action dispatch happens post-finalization
- No feedback loop between actions and AI reasoning

### Constraint 5: Trust Must Be Externally Verifiable

**Problem:** "Trust us, the AI was correct" is not credible.  
**Solution:** Phase 7 generates cryptographic provenance + trust reports.

**Artifacts:**
- SHA-256 hashes of all evidence files
- Reasoning manifest (AI protocol fixed at system freeze)
- Trust report linking decisions to immutable evidence

---

## The Seven Phases (Detailed)

### Phase 1: Evidence Contract Validation

**Input:** Git commits, deployment events, logs, metrics (JSON/text)  
**Process:** Schema validation, required field checks, format normalization  
**Output:** `reports/incident-bundle-INC-123.json`

**Why:** AI cannot handle malformed data. Validate before reasoning.

### Phase 2: Scoping & Noise Reduction

**Input:** Evidence bundle + incident time window  
**Process:** Filter events outside window, reduce to relevant subset  
**Output:** `reports/scope-audit-INC-123.json`

**Why:** Large repos generate massive git history. Scope = signal, not noise.

### Phase 3: AI Hypothesis Generation

**Input:** Scoped evidence + structured prompt  
**Process:** GitHub Copilot CLI generates RCA with 3+ hypotheses  
**Output:** `reports/postmortem-INC-123.md`

**Why:** AI is good at correlation. Copilot CLI is already authenticated, no new API.

**Prompt Engineering:**
- Require 3+ hypotheses with different categories
- Force "evidence FOR" and "evidence AGAINST" for each
- Demand explicit hypothesis elimination (ruled out)
- Constrain confidence scores (sum ≤ 100%)

### Phase 4: Human Review & Governance

**Input:** AI-generated postmortem  
**Process:** Human decides ACCEPT | MODIFY | REJECT  
**Output:** `reports/review-record-INC-123.yaml`

**Why:** Accountability. No AI decision goes to production without human stamp.

**Enforcement:**
- Service ownership: Only authorized reviewers can finalize service RCAs
- Role-based approval: T0 services require specific roles
- Override tracking: If human modifies AI, both versions preserved

### Phase 5: Organizational Memory

**Input:** Finalized review record  
**Process:** Write IKR to `incidents/INC-123.yaml` (append-only)  
**Output:** Indexed, queryable incident record

**Why:** Institutional learning. Query with `./sherlock history --pattern`.

**Guarantee:** Duplicate incident IDs rejected. No overwrites. Ever.

### Phase 6: Operational Integration

**Input:** Finalized review + action items  
**Process:** Create GitHub issues, JIRA tickets, PagerDuty notes  
**Output:** External system updates (optional)

**Why:** Close the loop. RCA → action items → ticket tracking.

**Critical:** This is read-only from AI perspective. No feedback loop.

### Phase 7: Trust & Verifiability

**Input:** All artifacts from Phases 1-6  
**Process:** Generate SHA-256 hashes, reasoning manifest, trust report  
**Output:** `phase7/provenance-INC-123.json`, `phase7/trust-report-INC-123.md`

**Why:** External auditors need proof. Cryptography > promises.

---

## Enterprise Enhancements

Three extensions add production-grade realism **without AI risk**:

### Part 1: Service Ownership

**Problem:** Anyone can approve any service's RCA (unrealistic).  
**Solution:** Service policies define authorized reviewers per service.

**Files:**
- `services/storage_service.yaml` - Ownership policy
- `services/validate-service-policy.py` - Enforcement script

**Rule:** Storage SRE cannot finalize API Gateway RCA. Authority is mechanical.

### Part 2: Multi-Service Coordination

**Problem:** Real incidents span multiple services.  
**Solution:** Coordination record declares service relationships explicitly.

**Files:**
- `incidents/INC-456.coordination.yaml` - Service roles
- `incidents/validate-coordination.py` - Scope validation

**Roles:**
- `primary_candidate` - Most likely root cause (must finalize to close incident)
- `downstream_impact` - Affected but may have contributing factors
- `symptom_only` - Surfaced alert but no fault (skips remediation)

**Rule:** One incident → multiple independent service RCAs. No AI correlation.

### Part 3: Incident Lifecycle States

**Problem:** "Is the incident still happening?" (system had no answer).  
**Solution:** Five-state lifecycle gates which phases can execute.

**States:**
```
OPEN → MITIGATING → MONITORING → RESOLVED → POSTMORTEM_COMPLETE
```

**Files:**
- `incidents/INC-456.status.yaml` - Current state
- `incidents/validate-status.py` - Phase gate enforcement

**Rules:**
- Investigation (1-3): Requires OPEN or MITIGATING
- RCA Finalization (4): Requires RESOLVED
- Memory Write (5): Requires POSTMORTEM_COMPLETE
- Actions (6): Requires MITIGATING
- Trust Artifacts (7): Requires POSTMORTEM_COMPLETE

**Critical:** Human sets state. System enforces. AI never changes state.

---

## Why This Is Safe

### No AI Decision Authority

- AI proposes, human decides (Phase 4)
- Every decision has explicit human identity
- AI output preserved even if rejected

### Mechanical Enforcement

- Evidence validated before AI sees it (Phase 1)
- Scoping is deterministic, not learned (Phase 2)
- Memory is append-only (Phase 5)
- Actions isolated from reasoning (Phase 6)

### External Verifiability

- All artifacts have SHA-256 hashes (Phase 7)
- Reasoning protocol is fixed (no learning)
- Trust reports link decisions to immutable evidence

### No Feedback Loops

- Actions (Phase 6) cannot influence future reasoning
- Memory queries use pattern matching (no embeddings)
- Lifecycle states set by humans only (Part 3)

---

## Why This Is Realistic

### Service Ownership (Part 1)

Real orgs have authority boundaries. Storage team cannot approve API Gateway RCA.  
Sherlock enforces this mechanically, not via process docs.

### Multi-Service Incidents (Part 2)

Real incidents span multiple services. Most tools force "one RCA for all" (wrong) or "separate incidents" (loses context).  
Sherlock: One incident, multiple service-specific RCAs, explicit coordination.

### Lifecycle States (Part 3)

Real incidents have states: investigating → mitigating → resolved → postmortem.  
Sherlock gates phase execution based on state. Can't finalize RCA if incident still MITIGATING.

### Operational Integration (Phase 6)

Real RCAs generate action items. Sherlock creates tickets automatically.  
But: Actions isolated from AI reasoning. No feedback loop.

---

## Architectural Invariants

Seven guarantees that define the system:

1. **Evidence First:** AI reasoning blocked until evidence validates (Phase 1)
2. **AI as Tool:** AI proposes only. Humans decide. Always. (Phase 4)
3. **Human Authority:** Every decision has identity tracking (Phase 4)
4. **Append-Only Memory:** No overwrites. No deletes. (Phase 5)
5. **Action Isolation:** Phase 6 cannot influence future reasoning
6. **External Trust:** Cryptographic provenance, not promises (Phase 7)
7. **Lifecycle Gating:** Wrong state → hard block (Part 3)

**These are enforced in code, not documentation.**

See [INVARIANTS.md](INVARIANTS.md) for detailed verification.

---

## What This Is Not

**Not an AI autopilot.** Humans make every final decision.  
**Not a monitoring system.** Sherlock investigates after incidents, not during.  
**Not a ticket tracker.** Integrates with JIRA/GitHub, doesn't replace them.  
**Not production-ready.** Demo system with simulated evidence.

But: **The architecture shows how to build production-grade AI incident systems safely.**

---

## Running Sherlock

**Single-service investigation:**
```bash
./sherlock investigate INC-123
```

**Multi-service investigation:**
```bash
./sherlock investigate INC-456 --service storage_service
./sherlock investigate INC-456 --service api-gateway
./sherlock summarize INC-456
```

**Lifecycle management:**
```bash
./sherlock status INC-456
./sherlock status INC-456 set RESOLVED
```

**Query history:**
```bash
./sherlock history --service storage_service --decision REJECTED
```

See [DEMO.md](DEMO.md) for complete walkthrough.

---

## Documentation Structure

**Judge-facing (you are here):**
- [README.md](README.md) - Quick start
- [DEMO.md](DEMO.md) - How to run
- [DESIGN.md](DESIGN.md) - Architecture (this file)
- [INVARIANTS.md](INVARIANTS.md) - System guarantees
- [LIMITATIONS.md](LIMITATIONS.md) - Honest constraints

**Internal implementation details:**
- [docs-internal/phases/](docs-internal/phases/) - Per-phase deep dives
- [docs-internal/governance/](docs-internal/governance/) - Service ownership, multi-service, lifecycle
- [docs-internal/validation/](docs-internal/validation/) - Test suite, verification reports

**Full documentation index:** [docs-internal/README.md](docs-internal/README.md)

---

## The Bottom Line

**What Sherlock demonstrates:**

- AI can assist incident response without decision authority
- Evidence validation + human review + append-only memory = safe AI integration
- Enterprise governance (ownership, coordination, lifecycle) can be mechanical
- External trust requires cryptography, not promises

**What makes this different:**

Most "AI incident tools" are black boxes where AI decides everything.  
Sherlock shows: **AI inside a system designed by humans who don't trust AI.**

That's the architecture.
