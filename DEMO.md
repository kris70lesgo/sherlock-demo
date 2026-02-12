# Sherlock Demo: Judge-First Presentation

## The 90-Second Explanation

> **"Sherlock is a CLI system that turns raw production evidence into a governed incident decision.**
>
> **It separates relevance, trust, reasoning, governance, memory, execution, and verification into strict phases.**
>
> **AI never decides. Humans always decide.**
>
> **Every decision is auditable, immutable, and cryptographically verifiable."**

That's it. No buzzwords. No jargon.

---

## The One-Command Demo

Judges will run **one command only**:

```bash
./sherlock investigate INC-123
```

This single command demonstrates the **complete incident lifecycle**:

1. **Phase 1-2:** Evidence preparation (fast, quiet)
2. **Phase 3:** Hypothesis reasoning (visible AI work)
3. **Phase 4:** Human decision (interactive or pre-recorded)
4. **Phase 5:** Organizational memory (logged)
5. **Phase 6:** Operational integration (Slack/JIRA stubs)
6. **Phase 7:** Trust artifacts (cryptographic provenance)
7. **Phase 8:** Lifecycle summary (judge-visible timeline)

**No branching. No flags. No confusion.**

---

## What Judges Will See

### Opening Banner

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Copilot Sherlock — Production Incident Investigation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Incident ID: INC-123
Service: storage_service
Severity: P1
```

### Phase-by-Phase Progress

Each phase shows:
- Clear entry/exit markers
- Visible reasoning (Phase 3)
- Human governance checkpoint (Phase 4)
- Side effects (Phase 6)
- Trust artifacts (Phase 7)

### Closing Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sherlock Incident Lifecycle Complete: INC-123
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Phase 1: Evidence validated & normalized
✓ Phase 2: Scope reduced & focused
✓ Phase 3: Hypotheses evaluated & confidence scored
✓ Phase 4: Human decision recorded & governance enforced
✓ Phase 5: Incident indexed in organizational memory
✓ Phase 6: Operational actions dispatched
✓ Phase 7: Trust artifacts generated & cryptographically bound

All artifacts:
  • Evidence: reports/incident-bundle-INC-123.json
  • Scope: reports/scope-audit-INC-123.json
  • Analysis: reports/post-mortem-INC-123.md
  • Governance: reports/review-record-INC-123.yaml
  • Memory: incidents/INC-123.yaml
  • Provenance: phase7/provenance-INC-123.json
  • Trust Report: phase7/trust-report-INC-123.md

Note: AI proposed. Human decided. System remembered. Actions executed.
      Every decision is auditable, immutable, and externally verifiable.
```

**This is what wins.**

---

## Demo Data Discipline

The canonical demo incident is **INC-123**:

- **Service:** storage_service
- **Category:** Resource exhaustion
- **Evidence:** Hadoop logs (10,000+ lines)
- **Outcome:** MODIFIED decision (AI 65% → Human 80%)
- **Remediation:** 5 action items
- **Artifacts:** All 7 files generated

**No randomness. No "try another one". No surprises.**

Judges should never wonder: *"What if this behaves differently?"*

---

## Pre-Demo Checklist

Before presenting to judges:

```bash
# 1. Verify clean state
rm -rf reports/ incidents/INC-123.yaml phase7/provenance-INC-123.json

# 2. Run canonical demo
./sherlock investigate INC-123

# 3. Verify all artifacts generated
ls -lh reports/
ls -lh incidents/
ls -lh phase7/provenance-INC-123.json
ls -lh phase7/trust-report-INC-123.md

# 4. Check lifecycle summary appeared
# Look for final "Sherlock Incident Lifecycle Complete" banner
```

✅ All artifacts present  
✅ Lifecycle banner shown  
✅ Trust report generated

**Demo is ready.**

---

## Key Questions & Positioning

### Q: "How is this different from just using ChatGPT?"

**A:** Sherlock separates **AI reasoning** from **human governance**. ChatGPT is a conversation. Sherlock is a **governed pipeline** with phase isolation, mandatory human review, and cryptographic provenance.

---

### Q: "Can't the AI just get better over time?"

**A:** No. Sherlock's reasoning protocol is **fixed per version**. There is no learning, no feedback loops, no adaptive behavior. Historical incidents are stored read-only and never influence future reasoning. This is documented in [INVARIANTS.md](INVARIANTS.md).

---

### Q: "What if I don't trust the AI's analysis?"

**A:** You don't have to. **Phase 4 is mandatory.** Every incident requires explicit human decision: ACCEPT, MODIFY, or REJECT. The AI proposes, humans decide. Always.

---

### Q: "How do I know this system won't drift?"

**A:** Because Sherlock has **seven architectural invariants** that prevent adaptive behavior. These are enforced through:
- Phase isolation (no shared state)
- Immutable artifacts (written once)
- Cryptographic hashing (tampering detectable)
- Reasoning manifest (fixed per version)

See [INVARIANTS.md](INVARIANTS.md) for complete list.

---

### Q: "What about production deployment?"

**A:** Sherlock is designed for **real engineering workflows**:
- Phase 6 integrates with JIRA, Slack, GitHub, Email
- Phase 7 provides trust artifacts for security/compliance teams
- All artifacts are git-trackable and human-readable
- History queries enable calibration analysis
- Remediation promises become tracked action items

Not a toy. A tool.

---

### Q: "Can this system auto-remediate?"

**A:** **No.** Auto-remediation is explicitly out of scope. Sherlock:
- Investigates (Phase 1-3)
- Governs (Phase 4)
- Remembers (Phase 5)
- Dispatches (Phase 6)
- Verifies (Phase 7)

Remediation is a separate system with separate governance.

---

### Q: "Why should we trust this?"

**A:** You don't have to. Phase 7 makes Sherlock **externally verifiable**:
- Every artifact has SHA-256 hash
- Reasoning protocol is documented and hashed
- Trust reports provide verification instructions
- Anyone can recompute hashes and verify claims

**"Sherlock does not require trust in Sherlock."**

---

## What NOT to Show

During the demo, **DO NOT**:

❌ Show configuration files (judges don't care)  
❌ Explain bash implementation details (irrelevant)  
❌ Run multiple incidents (dilutes story)  
❌ Show history queries (advanced feature, not core)  
❌ Discuss future features (stay focused)  
❌ Mention token limits or API costs (technical noise)

**Stay focused on the lifecycle.**

---

## Judge-Visible Architecture

When asked "How does this work?", show this diagram:

```
Production Evidence (10,000+ log lines)
   ↓
Phase 1: Normalize & Validate (evidence contract)
   ↓
Phase 2: Scope & Reduce (trust-based filtering)
   ↓
Phase 3: Hypothesis Reasoning (AI proposes 3-5 hypotheses)
   ↓
Phase 4: Human Decision (ACCEPT/MODIFY/REJECT + governance)
   ↓
Phase 5: Organizational Memory (append-only, read-only)
   ↓
Phase 6: Operational Integration (JIRA, Slack, etc.)
   ↓
Phase 7: Trust Artifacts (cryptographic provenance)
```

**One-way data flow. No feedback loops.**

---

## The Positioning Statement

If you have 30 seconds, say this:

> "Most incident response tools either:
> 1. Give you AI without governance, or
> 2. Give you governance without AI
>
> Sherlock gives you both by keeping them in separate phases.
>
> AI generates hypotheses. Humans make decisions.
>
> Every decision is cryptographically bound to a fixed reasoning protocol.
>
> This is what production-grade AI assistance looks like."

---

## Why This Wins

Most Copilot CLI submissions are:
- Single-shot tools
- No governance
- No memory
- No verification
- No integration

Sherlock demonstrates:

✅ **Complete lifecycle** (not just analysis)  
✅ **Governance-first** (AI proposes, humans decide)  
✅ **Organizational memory** (without feedback loops)  
✅ **Operational integration** (real workflows)  
✅ **External verifiability** (cryptographic provenance)  
✅ **Architectural maturity** (documented invariants)  
✅ **Production-ready** (not a prototype)

This is **demonstrably ahead** of typical hackathon submissions.

---

## Final Demo Tips

### Before the demo:
1. Clean state (delete old artifacts)
2. Verify INC-123 logs exist
3. Rehearse 90-second explanation
4. Have [INVARIANTS.md](INVARIANTS.md) open in another tab

### During the demo:
1. Run `./sherlock investigate INC-123`
2. Let judges see complete lifecycle
3. Point out key transitions (Phase 3→4→5)
4. Show final summary banner
5. Open trust report in markdown viewer

### After the demo:
1. Show artifacts in `reports/` and `incidents/`
2. Display provenance JSON
3. Reference [INVARIANTS.md](INVARIANTS.md) for architecture questions
4. Emphasize: "AI proposed, human decided, system verified"

---

## Success Metrics

You've succeeded if judges say:

- "This feels production-ready"
- "I understand the governance model"
- "I like that it's not trying to do everything"
- "The phase isolation is clever"
- "I trust this more than I expected"

You've **won** if judges say:

- "We should deploy this"
- "Can we integrate this with our systems?"
- "This solves a real problem"
- "I've never seen AI governance done this well"

---

## The Ultimate Hook

End with this statement:

> **"Most AI tools ask you to trust them.**
> **Sherlock gives you a way to verify them.**
> **That's the difference between a demo and a product."**

---

*This demo structure was finalized on 2026-02-10 for Sherlock 1.0.0.*  
*No feature changes after this point—only clarity improvements.*

---

## Quick Reference

**One command:** `./sherlock investigate INC-123`  
**90 seconds:** AI proposes → humans decide → system verifies  
**7 phases:** Evidence → Scope → Reason → Govern → Remember → Execute → Verify  
**Zero trust required:** Externally verifiable, cryptographically bound  
**Production-ready:** JIRA, Slack, GitHub, Email integrations  
**Documented invariants:** [INVARIANTS.md](INVARIANTS.md)  

**That's the pitch.**
