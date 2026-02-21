# Agent Audit Log

Agents append one entry here **after each commit** and **after every irreversible action**.

## Format

```
[YYYY-MM-DD] [agent-id] [task-id] [action-type] [confidence%] <description> | doubts: <none or 1 sentence>
```

- `agent-id`: a short identifier for this agent session (e.g. `seeder-en-1`, `feat-agent-3`)
- `action-type`: `commit` | `merge` | `publish` | `status-change` | `decision`
- `confidence`: 0–100% — your honest self-assessment of correctness
- `doubts`: "none" if confident; otherwise one sentence describing the uncertainty

## Example Entries

```
[2025-07-18] [seeder-en-1] [vocab-seeder-en] [commit] [95%] Added 10 EN stubs (ephemeral–laconic) to words_staging.json | doubts: none
[2025-07-18] [feat-agent-2] [word-relations] [merge] [88%] Merged word-relations to main; all tests pass | doubts: @Relationship cascade rules untested on large dataset
[2025-07-18] [qa-agent-1] [vocab-qa] [status-change] [92%] Approved 8 LT words; rejected 2 (missing example) | doubts: none
```

---

<!-- Agents append below this line -->
