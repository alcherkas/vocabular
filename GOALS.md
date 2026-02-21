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
**Goal**: Build a dual-language vocabulary learning app (extend EN vocab + learn LT from scratch) designed for short 5-minute micro-sessions throughout the day.
**Notes**:
- User selects which language to study (EN or LT) at session start
- Sessions are ~5 minutes each; user does multiple sessions per day
- Time allocation between languages may be uneven (e.g., 3 EN sessions, 1 LT session) — the app should track per-language progress independently
- EN goal: expand existing C1+ vocabulary (user already knows English, wants deeper/rarer words)
- LT goal: learn Lithuanian from scratch (A1/A2 basics first)
- App should adapt to uneven practice patterns — don't penalize skipping a language for a day
- Spaced repetition or similar should be per-language, not global
- Quick session flow: launch → pick language → study/quiz → done in 5 min

