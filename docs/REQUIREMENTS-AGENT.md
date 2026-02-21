# Requirements Agent Protocol

## Role
Expand a high-level goal from `GOALS.md` into structured requirements, user stories, and task stubs.

## Trigger
A goal in `GOALS.md` with `status: [ ]`.

## Inputs to Read
1. `GOALS.md` — the goal entry
2. `docs/ARCHITECTURE.md` — current data model and constraints
3. `docs/CONVENTIONS.md` — patterns to follow
4. `docs/TASKS.md` — existing tasks (avoid duplicating)
5. `docs/requirements/` — existing requirement docs (for consistency)

## Output
Create `docs/requirements/<goal-id>.md` with this structure:

```markdown
# Requirements: <goal-id>

## Goal
<Copy the goal statement>

## User Stories
- As a [user type], I want [action] so that [benefit].
(list all stories; be specific)

## Acceptance Criteria
- [ ] AC-1: <specific, testable criterion>
- [ ] AC-2: ...
(number them — Verification Agent checks these one by one)

## Out of Scope
- <explicit exclusions — prevents scope creep>

## Edge Cases & Constraints
- <failure modes, empty states, offline behavior, etc.>

## Feature Breakdown
Tasks to create in TASKS.md:
- `<task-id>`: <short description> (files: ...)
- `<task-id>`: <short description> (files: ...)
```

## Steps

1. Read the goal from `GOALS.md`.
2. Read relevant context docs.
3. If ambiguous → write to `docs/decisions-pending.md` (see below) before proceeding.
4. Write `docs/requirements/<goal-id>.md`.
5. Add task stubs to `docs/TASKS.md` (status `[ ]`, no file detail yet — Architecture Agent fills that).
6. Update goal status in `GOALS.md` to `[requirements-done]`.
7. Commit:
   ```bash
   git commit -m "requirements(<goal-id>): define user stories and acceptance criteria"
   ```

## When in Doubt → Decision Pending

If you encounter a design ambiguity, **do not guess**. Instead:

1. Add an entry to `docs/decisions-pending.md`:
   ```markdown
   ## [<goal-id>] — <short question title>
   **Context**: <why this decision matters>
   **Options**:
   - A) ...
   - B) ...
   - C) ...
   **Blocking**: Requirements Agent
   ```
2. Set goal status in `GOALS.md` to `[blocked: decision-pending]`.
3. Commit what you have.
4. Stop. Wait for human to pick an option in `docs/decisions-pending.md`.
5. When you see `**Choice: X**` written by the human: apply it, move entry to `docs/decisions-log.md`, resume.

## Quality Bar
- Acceptance criteria must be **testable** — a Verification Agent should be able to check each one by reading code or running the app.
- User stories must be **user-facing** — no implementation details.
- Out of scope must be **explicit** — prevents future misunderstanding.

## When to Stop (Uncertainty Protocol)

Stop and write to `docs/decisions-pending.md` if:
- The goal statement is too vague to write specific, testable acceptance criteria
- A user story requires a platform capability you're unsure the app has
- You're less than 90% confident your acceptance criteria accurately reflect the goal
- You see a conflict with existing requirements or architecture docs

Append to `docs/audit-log.md` after committing your output:
```
[YYYY-MM-DD] [requirements-agent] [<goal-id>] [commit] [<confidence>%] Defined requirements for <goal-id> | doubts: <none or reason>
```
