# Verification Agent Protocol

## Role
Verify that a completed feature meets its acceptance criteria, and identify any tech debt introduced.

## Trigger
A goal in `GOALS.md` with `status: [needs-verification]` (set by the last Feature Agent to complete a task for this goal).

## Inputs to Read
1. `docs/requirements/<goal-id>.md` — acceptance criteria to check
2. `docs/architecture/<goal-id>.md` — expected files/changes
3. Actual source code in `Vocab/Vocab/` (read changed files)
4. `docs/CONVENTIONS.md` — check for convention violations
5. `docs/ARCHITECTURE.md` — check for architecture drift

## Output 1: Verification Report

Create `docs/verification/<goal-id>.md`:

```markdown
# Verification: <goal-id>

## Result: ✅ PASSED / ❌ FAILED / ⚠️ PARTIAL

## Acceptance Criteria Check
- [x] AC-1: <criterion> — ✅ Met. <brief evidence>
- [x] AC-2: <criterion> — ❌ Not met. <what's missing>
- [x] AC-3: <criterion> — ⚠️ Partial. <what works, what doesn't>

## Architecture Compliance
- Expected files: <list from architecture doc>
- Missing: <any expected files not created>
- Unexpected changes: <files changed that weren't in the architecture doc>

## Test Coverage
- [ ] Unit tests present for new services/logic
- [ ] Edge cases covered (empty state, offline, etc.)

## Issues Found
(list blockers that must be fixed before marking verified)
```

## Output 2: Tech Debt

Append to `docs/tech-debt.md` (even if the feature passed):

```markdown
## [<goal-id>] — <date>
- <debt item>: <description and suggested fix>
```

Only include genuine debt: missing tests, shortcuts taken, convention violations, architectural drift. Skip if nothing to report.

## Steps

1. Read requirements, architecture doc, and actual code.
2. Check each AC from the requirements doc — mark ✅ / ❌ / ⚠️.
3. Check architecture compliance (files match what was designed).
4. Check test coverage.
5. Write `docs/verification/<goal-id>.md`.
6. Append to `docs/tech-debt.md` if debt found.
7a. If **all ACs met**: set goal status to `[verified]` in `GOALS.md`.
7b. If **any AC failed**: set goal status to `[needs-rework]`, reopen blocked tasks in `TASKS.md` (change `[done]` back to `[ ]` with a note), set goal to `[needs-rework]`.
8. Commit:
   ```bash
   git commit -m "verification(<goal-id>): <PASSED|FAILED|PARTIAL> — <summary>"
   ```

## Quality Bar
- Every AC must be checked — no skipping.
- Evidence must be specific: reference file names and line numbers where relevant.
- Tech debt must be actionable: vague entries like "code could be cleaner" are not acceptable.
- Do not reopen tasks for style issues — only for functional gaps against ACs.

## When to Stop (Uncertainty Protocol)

Stop and write to `docs/decisions-pending.md` if:
- You can't determine whether an AC is met without running the app (and you can't run it)
- You find a potential security or data-loss bug — do not mark verified; escalate immediately
- The code diverged so significantly from the architecture doc that you can't map ACs to code

Append to `docs/audit-log.md` after committing your output:
```
[YYYY-MM-DD] [verification-agent] [<goal-id>] [commit] [completed] [<ambiguity>] [<confidence>%] Verification <PASSED|FAILED> for <goal-id> | doubts: <none or reason>
```
