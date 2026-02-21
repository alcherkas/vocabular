# Process Changelog

Records every change the Reflection Agent makes to the agent infrastructure (docs, scripts, protocols). Append-only.

This file answers: "Why does the process work the way it does now?" and "What changed since last time?"

## Entry Format

```markdown
## [YYYY-MM-DD] Reflection cycle #N

### Pattern observed
- (what was seen in retrospectives / audit-log / decisions-log)

### Change made
- **File**: `<path>`
- **What changed**: <1 sentence>
- **Why**: <1 sentence linking to the pattern>

### Retro entries that triggered this
- [YYYY-MM-DD] [agent-id] [task-id] — "<brief quote from friction or suggestion>"
```

## Rules

- Each reflection cycle produces **one entry** here with **≤3 changes** listed.
- Every change must cite the specific retro entries or audit-log patterns that motivated it.
- If no changes are needed after a reflection cycle, write: "### Change made\n- None — process is working well."

---

<!-- Reflection Agent: append entries below this line -->
