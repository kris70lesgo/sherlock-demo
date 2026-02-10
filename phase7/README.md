# Phase 7: Trust, Assurance & External Verifiability

## Purpose

Phase 7 makes Sherlock **externally verifiable without trusting Sherlock**. It provides cryptographic proof that:
- Reasoning rules are fixed and documented
- No incident can trigger adaptive behavior
- All processing is bound to specific artifacts
- Tampering is immediately detectable

## Core Principle

**"Sherlock does not require trust in Sherlock."**

Phase 7 is observational only—it never modifies behavior, never influences reasoning, and never enforces runtime constraints. It exists solely to make trust unnecessary through external verification.

## The Problem Phase 7 Solves

When presenting an incident investigation system to judges, auditors, or compliance teams, they ask:

- "How do we know the AI won't drift over time?"
- "How can we trust this won't evolve into something unsafe?"
- "What prevents someone from quietly changing the reasoning rules?"
- "Can historical data influence future investigations?"
- "How do we verify your claims without trusting you?"

Phase 7 answers all of these with **cryptographic provenance** and **immutable manifests**.

## Architecture

Phase 7 generates three types of artifacts:

### 1. Reasoning Manifest (System-Wide, Version-Bound)
**File:** `phase7/reasoning-manifest.json`

Generated once per Sherlock version. Documents:
- Exact reasoning protocol (with SHA-256 hash)
- Enabled phases
- Confidence rules
- Governance requirements
- **Forbidden capabilities** (learning, feedback loops, auto-approval, prompt evolution, etc.)
- Isolation guarantees

**Key Property:** This manifest is immutable for a Sherlock version. Any change requires a new version and a new manifest hash.

### 2. Cryptographic Provenance (Per-Incident)
**File:** `phase7/provenance-{INCIDENT_ID}.json`

Generated for every finalized incident. Contains:
- SHA-256 hashes of all 5 artifacts:
  - Incident bundle
  - Scope audit
  - Post-mortem
  - Review record
  - Incident Knowledge Record (IKR)
- Executed phases sequence
- Link to reasoning manifest hash
- Verification status (all artifacts present, governance enforced, mandatory phases complete)

**Key Property:** Any modification to any artifact changes its hash, making tampering immediately detectable.

### 3. Trust Report (Per-Incident, Human-Readable)
**File:** `phase7/trust-report-{INCIDENT_ID}.md`

Markdown report for security reviewers, auditors, legal teams, and judges. Contains:
- Executive summary (fixed rules + mandatory governance)
- Reasoning protocol details
- Governance compliance verification
- Trust guarantees (no feedback loops, phase isolation)
- Forbidden capabilities list
- Artifact integrity (all hashes)
- External verifiability instructions
- Verification commands
- Answers to common audit questions:
  - "Can historical incidents bias future RCAs?" → No, Phase 5 read-only
  - "Can Sherlock learn automatically?" → No, learning forbidden
  - "Can someone bypass human review?" → No, Phase 4 mandatory
  - "How do we know the prompt wasn't changed?" → Cryptographic hash
  - "Can AI manipulate confidence?" → No, `ai_cannot_self_modify: true`

**Key Property:** Transforms technical guarantees into judge-level explanations.

## Integration with Pipeline

Phase 7 is invoked automatically after Phase 6 (if Phase 7 exists):

```bash
# In sherlock main pipeline (lines 1817-1821):
if [ -f "phase7/phase7.sh" ]; then
    echo
    bash phase7/phase7.sh "$INCIDENT_ID"
fi
```

Phase 7 only processes **finalized** incidents. If an incident is still DRAFT, Phase 7 skips it (with message).

## Workflow

1. **Incident finalized** (Phase 4 ACCEPT/MODIFY/REJECT)
2. **IKR written** (Phase 5 organizational memory)
3. **Optional dispatchers** (Phase 6 operational integration)
4. **Phase 7 invoked:**
   - Checks finalization status
   - Verifies reasoning manifest exists (generates if first run)
   - Computes SHA-256 hashes of all 5 artifacts
   - Generates `provenance-{INCIDENT_ID}.json`
   - Generates `trust-report-{INCIDENT_ID}.md`
   - Displays verification summary

## External Verification (No Trust Required)

Anyone can verify an incident's processing:

```bash
# 1. Recompute artifact hashes
shasum -a 256 reports/incident-bundle-INC-123.json
shasum -a 256 reports/scope-audit-INC-123.json
shasum -a 256 reports/post-mortem-INC-123.md
shasum -a 256 reports/review-record-INC-123.yaml
shasum -a 256 incidents/INC-123.yaml

# 2. Compare with provenance record
cat phase7/provenance-INC-123.json

# 3. Verify reasoning manifest
cat phase7/reasoning-manifest.json
shasum -a 256 prompts/investigate.txt  # Compare with protocol_hash
```

**No trust in Sherlock or its operators is required.** The cryptographic trail is self-verifying.

## Files Generated

### Per Sherlock Version (Generated Once)
- `phase7/reasoning-manifest.json` - Fixed reasoning rules

### Per Incident (Generated Every Finalization)
- `phase7/provenance-{INCIDENT_ID}.json` - Cryptographic binding
- `phase7/trust-report-{INCIDENT_ID}.md` - Human-readable security report

## Trust Guarantees

Phase 7 proves:

1. **Fixed reasoning rules** - No adaptation or learning
2. **Mandatory human governance** - No auto-approval
3. **Cryptographic provenance** - Tampering detectable
4. **No feedback loops** - Historical data doesn't influence reasoning
5. **External verifiability** - No trust required

## Forbidden Capabilities (Verified Absent)

Phase 7 documents that these are **architecturally impossible**:

- ❌ Learning
- ❌ Feedback Loops
- ❌ Auto-Approval
- ❌ Prompt Modification
- ❌ Confidence Manipulation
- ❌ Hypothesis Injection
- ❌ Evidence Filtering
- ❌ Governance Bypass

## Positioning for High-Stakes Environments

**For judges/auditors:**
> "Every decision is cryptographically bound to a fixed, documented reasoning protocol. Historical incidents cannot influence future reasoning. Human review is mandatory. Tampering is immediately detectable."

**For security teams:**
> "Sherlock does not require trust in Sherlock. All processing is externally verifiable through SHA-256 hashes and immutable manifests."

**For compliance teams:**
> "Complete audit trail with cryptographic provenance. All artifacts human-readable and git-trackable. No adaptive behavior or learning capabilities."

## Example: Trust Report for INC-123

```markdown
# Trust Report: INC-123

**Generated:** 2026-02-09 00:30:00 UTC
**Sherlock Version:** 1.0.0
**Decision:** MODIFIED

## Executive Summary
This incident was processed under **fixed reasoning rules** with **mandatory human governance**.

## Trust Guarantees
✅ No Feedback Loops: Phase 5 read-only
✅ Phase Isolation: Phases 5-7 don't influence reasoning
✅ Mandatory Human Review: Phase 4 non-optional
✅ Cryptographic Provenance: All artifacts hashed
✅ External Verifiability: No trust required

## Artifact Integrity
- Incident Bundle: `sha256:a1b2c3d4...`
- Review Record: `sha256:d4e5f678...`
- IKR: `sha256:e5f67890...`

## External Verification
Anyone can recompute hashes and verify processing.
```

## Why This Matters

Very few incident investigation systems provide:
- Cryptographic binding of decisions to reasoning rules
- Documented forbidden capabilities
- External verifiability without trust
- Judge-level trust documentation

Phase 7 makes Sherlock suitable for high-stakes environments where **"trust us" is not acceptable**.

## Usage

```bash
# Automatic (after Phase 6)
./sherlock investigate <incident_id>

# Manual generation
./phase7/phase7.sh INC-123

# Generate only provenance
./phase7/generate-provenance.sh INC-123

# Generate only trust report
./phase7/generate-trust-report.sh INC-123

# Generate reasoning manifest
./phase7/generate-reasoning-manifest.sh
```

## See Also
- [Phase 5: Organizational Memory](../incidents/README.md) - How historical data is stored (read-only)
- [Phase 6: Operational Integration](../phase6/README.md) - How decisions are dispatched (read-only)
- [Reasoning Manifest](trust/reasoning-manifest.json) - Current system-wide rules
- [Example Provenance](trust/provenance-INC-123.json) - Sample cryptographic binding
- [Example Trust Report](trust/trust-report-INC-123.md) - Sample security documentation
