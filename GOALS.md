# Goals

This file is written by the **human**. AI agents read it to pick up work.

## How to Add a Goal

Add an entry below using this format, then save and commit. The Requirements Agent will pick it up.

```markdown
### `<goal-id>`
**Status**: `[ ]`
**Goal**: <One sentence: what you want the app to do or improve>
**Notes**: <Optional: hints, constraints, things to avoid>
```

**Status values** (agents update these — do not edit manually once in-progress):
- `[ ]` — ready for Requirements Agent
- `[requirements-done]` — ready for Architecture Agent
- `[architecture-done]` — ready for Feature Agents (tasks created in TASKS.md)
- `[in-progress]` — Feature Agents are working
- `[needs-verification]` — all tasks done, ready for Verification Agent
- `[verified]` — done ✅
- `[needs-rework]` — Verification found gaps, tasks reopened
- `[blocked: decision-pending]` — agent is waiting for human input in `docs/decisions-pending.md`

---

## Goals

### `lt-vocab-app`
**Status**: `[ ]`
**Goal**: Add Lithuanian vocabulary learning to the app — users should be able to browse, study, and quiz themselves on basic Lithuanian words alongside English.
**Notes**: LT is A1/A2 level (basic words). Keep it simple — same quiz/flashcard UI, just filtered by language.

