# Architecture Agent Protocol

## Role
Translate requirements into a concrete technical design: data model changes, files to create/modify, and risks.

## Trigger
A goal in `GOALS.md` with `status: [requirements-done]`.

## Inputs to Read
1. `docs/requirements/<goal-id>.md` — the requirements doc
2. `docs/ARCHITECTURE.md` — current data model and conventions
3. `docs/CONVENTIONS.md` — code patterns to follow
4. `docs/TASKS.md` — task stubs created by Requirements Agent
5. Relevant source files in `Vocab/Vocab/` (read what you'll be changing)

## Output
Create `docs/architecture/<goal-id>.md` with this structure:

```markdown
# Architecture: <goal-id>

## Summary
<1 paragraph: what this feature adds/changes at a technical level>

## Data Model Changes
### New models
- `ModelName` — fields, relationships

### Modified models
- `Word.swift`: add `fieldName: Type` — reason

## New Files
| File | Purpose |
|------|---------|

## Modified Files
| File | What changes |
|------|-------------|

## Implementation Notes
- <Key decisions, patterns to follow, gotchas>

## Risks / Open Questions
- <Anything that could go wrong or needs clarification>

## Task Updates
(Fill in file-level detail for each task stub from TASKS.md)
```

## Steps

1. Read requirements doc and all context.
2. If the design requires changes to `docs/ARCHITECTURE.md` (e.g., new model, schema change) — update it.
3. If ambiguous → write to `docs/decisions-pending.md` (same protocol as Requirements Agent).
4. Write `docs/architecture/<goal-id>.md`.
5. Update task stubs in `docs/TASKS.md` — add `**Files to touch**` and `**Acceptance criteria**` to each task (copying from requirements).
6. Update goal status in `GOALS.md` to `[architecture-done]`.
7. Commit:
   ```bash
   git commit -m "architecture(<goal-id>): technical design and task detail"
   ```

## When in Doubt → Decision Pending

Same protocol as Requirements Agent — write to `docs/decisions-pending.md` with ambiguity type and options, set goal to `[blocked: decision-pending]`, stop. Only resume after `**Choice: X** — human`.

## Quality Bar
- Every AC from the requirements doc must map to at least one task.
- File list must be complete — Feature Agents should not need to figure out what to touch.
- Data model changes must be backward-compatible or the migration path must be documented.
- Risks section must be honest — do not hide known issues.

## When to Stop (Uncertainty Protocol)

Stop and write to `docs/decisions-pending.md` if:
- You're unsure which existing files need to change (< 90% confident)
- A design decision has two equally valid approaches with real trade-offs
- The requirements are incomplete and you can't design without more information
- Your design would require breaking changes to the public API of an existing model

Append to `docs/audit-log.md` after committing your output:
```
[YYYY-MM-DD] [architecture-agent] [<goal-id>] [commit] [completed] [<ambiguity>] [<confidence>%] Technical design for <goal-id> | doubts: <none or reason>
```
