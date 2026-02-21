# Agent Audit Log

Agents append one entry here **after each commit** and **after every irreversible action**.

## Format

```
[YYYY-MM-DD] [agent-id] [task-id] [action-type] [stop-reason] [ambiguity] [confidence%] <description> | doubts: <none or 1 sentence>
```

- `agent-id`: a short identifier for this agent session (e.g. `seeder-en-1`, `feat-agent-3`)
- `action-type`: `commit` | `merge` | `publish` | `status-change` | `decision`
- `stop-reason`: why the agent stopped after this action:
  - `completed` — task or subgoal fully done
  - `clarification` — blocked, need human input before continuing
  - `interrupted` — human interrupted mid-work
  - `checkpoint` — pausing at planned subgoal boundary (intermediate/high complexity tasks)
  - `other` — none of the above
- `ambiguity`: level of ambiguity when stopping:
  - `clear` — executing well-defined instructions
  - `choices` — making implementation choices between valid options
  - `vague` — interpreting underspecified requirements
  - `open-ended` — navigating a task where success criteria aren't defined
- `confidence`: 0–100% — your honest self-assessment of correctness
- `doubts`: "none" if confident; otherwise one sentence describing the uncertainty

## Example Entries

```
[2026-02-21] [seeder-en-1] [vocab-seeder-en] [commit] [completed] [clear] [95%] Added 10 EN stubs (ephemeral–laconic) | doubts: none
[2026-02-21] [feat-agent-2] [word-relations] [merge] [completed] [clear] [88%] Merged word-relations to main; all tests pass | doubts: @Relationship cascade rules untested on large dataset
[2026-02-21] [feat-agent-3] [word-meanings-model] [commit] [checkpoint] [vague] [70%] Completed Word.swift migration; pausing before View updates | doubts: unclear if primary meaning should be first or highest-register
[2026-02-21] [qa-agent-1] [vocab-qa] [status-change] [completed] [clear] [92%] Approved 8 LT words; rejected 2 (missing example) | doubts: none
```

---

<!-- Agents append below this line -->
[2025-07-17] [requirements-agent] [lt-vocab-app] [commit] [completed] [clear] [92%] Defined requirements for lt-vocab-app: 8 user stories, 21 acceptance criteria, 6 task stubs | doubts: session item count (10-15) is an estimate; may need tuning after implementation
