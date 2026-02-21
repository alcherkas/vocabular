# Reversibility Rules for Agents

Every action an agent takes falls into one of three categories.
**Check this table before acting.** When in doubt, treat the action as irreversible.

## Classification

| Category | Definition | Examples |
|----------|-----------|---------|
| **Read-only** | No files changed, no side effects | Reading any file, running `validate_words.py`, running `xcodebuild build` |
| **Reversible** | Changes files, but easily undone via `git revert` or re-running a script | Adding stubs to staging JSON, adding/modifying code in your worktree branch, appending to `docs/audit-log.md`, updating task status in `TASKS.md` |
| **Irreversible** | Hard or impossible to undo without manual recovery | Merging to `main`, running `publish_words.py` (writes to `words.json`), deleting staging entries, modifying shared state on `main` directly |

---

## Rules by Category

### Read-only
- No restrictions. Do these freely.

### Reversible
- Perform freely within your claimed task scope.
- If you make a mistake, the human can `git revert` or re-run the script.
- Always commit before moving on to the next action so there's a recovery point.

### Irreversible — STOP AND CONFIRM
Before taking any irreversible action:

1. **Verify** you have completed all required checks (tests pass, validator passes, all ACs met).
2. **Append to `docs/audit-log.md`** with action details and confidence level.
3. If confidence is **< 90%**, do NOT proceed — write to `docs/decisions-pending.md` instead:
   ```markdown
   ## [task-id] — About to take irreversible action
   **Action**: <describe exactly what you are about to do>
   **Reason**: <why this needs to happen now>
   **Confidence**: <your confidence %, and why it's not higher>
   **Options**:
   - A) Proceed now
   - B) Wait for human review
   **Blocking**: <agent-id>
   ```
4. If confidence is **≥ 90%** and all checks pass — proceed, then log immediately to `audit-log.md`.

---

## Specific Irreversible Actions — Rules

### Merging to `main`
- All tests must pass (`xcodebuild test`).
- Task must be marked `[done]` in `TASKS.md`.
- At least one commit is on the branch (no empty merges).
- If the task is `[risk: high]`, **always** write to `decisions-pending.md` before merging.

### Running `publish_words.py`
- All words being published must have `status: approved` (validated by `validate_words.py`).
- Requires `--confirm` flag (prevents accidental runs).
- Run: `python3 scripts/publish_words.py --confirm`

### Deleting or overwriting staging entries
- Never delete entries — mark them `status: rejected` with a `rejectReason` field instead.
- If you need to restart a batch, add new entries rather than overwrite.

---

## Quick Reference for Each Agent Role

| Agent | Their irreversible actions |
|-------|--------------------------|
| Seeder | None (only adds stubs) |
| Enricher | None within staging (status changes are reversible) |
| Relations | None within staging |
| QA Reviewer | Setting `approved` (triggers publish eligibility) |
| Publisher | Running `publish_words.py` — writes to production |
| Feature Agent | Merging to `main` |
| Requirements Agent | Updating `GOALS.md` status (cascades to other agents) |
| Architecture Agent | Updating `docs/ARCHITECTURE.md` global schema |
| Verification Agent | Setting goal `[verified]` or `[needs-rework]` |
