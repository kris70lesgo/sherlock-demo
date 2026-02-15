# Copilot Sherlock — Governed Incident Investigation CLI

**AI proposes. Humans decide. The system verifies.**

Sherlock is a CLI system that turns raw production evidence into a governed, auditable incident decision.

It demonstrates how to build production-grade AI assistance with:
- mandatory human authority
- organizational memory (without feedback loops)
- operational execution
- external cryptographic verification

**AI never decides. Humans always decide.**

---

## 🎯 The 90-Second Pitch

**Sherlock separates intelligence from authority.**

AI performs bounded reasoning.  
Humans make the decision.  
The system enforces governance, records memory, executes actions, and proves integrity.

Every incident outcome is:
- explicitly approved or rejected by a human
- immutable once finalized
- cryptographically verifiable without trusting the system itself

This is not an AI demo.  
It’s an **incident lifecycle system with AI inside it**.

---

## 🚀 One-Command Demo

```bash
./sherlock investigate INC-123
```

## ✅ Fully Successful Demo Run (Append-Only Safe)

If you want a full end-to-end run that writes organizational memory (Phase 5)
without hitting the append-only guard, use a fresh incident ID:

```bash
./sherlock investigate INC-999
```

## 🔐 Copilot Auth vs Offline Mode

Sherlock uses GitHub Copilot CLI for Phase 3 reasoning when authenticated.
If Copilot is not authenticated, Sherlock falls back to an offline post-mortem
generator so the demo can still complete.

To authenticate Copilot:

```bash
gh auth login
```

## 🧪 Non-Interactive Demo Runs

When running non-interactively (e.g., CI), Sherlock auto-selects:
- Decision: `ACCEPT`
- Reviewer: `sherlock-demo` / `Incident Commander` / `demo-user`

This allows the demo to complete without blocking on prompts.

## 🔧 Optional Dependency (Service Ownership Validation)

Service ownership checks use PyYAML. If it isn't installed, validation is skipped in demo mode.

```bash
pip install pyyaml
```
