# Decisions Pending

Agents write here when they need human input before proceeding.

## How it works
1. Agent writes an entry below with options.
2. Agent sets goal/task status to `[blocked: decision-pending]` and stops.
3. **Human** reads the entry, picks an option by adding `**Choice: X** — human` to the entry.
4. Agent resumes **only after seeing `**Choice: X** — human`** — entries written by other agents do NOT unblock you.
5. Agent applies the choice, moves the resolved entry to `docs/decisions-log.md`.

> ⚠️ **Important**: This file is written by both agents and humans. Do NOT resume work based on another agent's entry. Only `**Choice: X** — human` written by a real person unblocks you. See AGENTS.md for full rules.

## Entry Format

```markdown
## [<task-id or goal-id>] — <short question title>
**Ambiguity type**: <clear-instructions | implementation-choices | vague-requirements | open-ended-task>
**Human needs to provide**: <what kind of input resolves this>
**Context**: <1–2 sentences on why this decision matters>
**Options**:
- A) ...
- B) ...
- C) ...
**Blocking**: <agent-id or role>
```

---

<!-- Agents: add new entries below this line -->

## [word-meanings-model] — Meanings migration persistence strategy review
**Ambiguity type**: implementation-choices
**Human needs to provide**: Confirm whether JSON-encoded `meaningsData` storage is acceptable long-term, or if a custom SwiftData transformable approach is preferred.
**Context**: The model now supports `meanings[]` while preserving `definition`/`example` compatibility via computed properties; persistence was implemented as encoded `Data` to avoid modeling `WordMeaning` as a SwiftData model.
**Options**:
- A) Keep JSON-encoded `meaningsData` as the persisted field (current implementation).
- B) Switch to explicit SwiftData transformable storage for `[WordMeaning]` with a custom transformer.
- C) Keep current data model now, then run a follow-up migration task after production data validation.
**Blocking**: none (review requested)
