# Retrospectives

Every agent appends a brief retrospective note at the **end of each iteration** (not every commit — see below).

## What counts as an "iteration"?

| Agent type | One iteration = |
|-----------|----------------|
| Vocab pipeline (Seeder, Enricher, etc.) | End of a session (may span multiple batches) |
| Feature Agent | After completing a task (before or after merging) |
| Product Dev Agent (Req/Arch/Verify) | After completing their role's output |
| Reflection Agent | After completing a reflection cycle |

## Entry Format

```markdown
## [YYYY-MM-DD] [agent-id] [task-id]

### What went well
- (what part of the process helped you succeed)

### What was harder than expected
- (unexpected complexity, missing context, etc.)

### Process friction
- (where agent docs were unclear, scripts failed, guardrails were wrong/too tight/too loose, conventions didn't cover a case)

### Suggested improvement
- (one specific, actionable change to docs/scripts/protocols — optional but encouraged)
```

## Rules

- **Append-only** — do not edit or delete existing entries.
- Keep each section to 1–3 bullet points. This is a quick note, not an essay.
- Be honest about friction — that's the whole point. The Reflection Agent reads these to improve the process.
- If nothing went wrong, say so: "### Process friction\n- None this iteration."
- If you have no suggestion, say: "### Suggested improvement\n- None."

---

<!-- Agents: append entries below this line -->

## [2025-07-17] [seeder-en] [seed-en-30-stubs]

### What went well
- Protocol in VOCAB-AGENT.md was clear and easy to follow; stub schema and validation script worked on first try for all 3 batches.
- No duplicates against the 96 existing production terms — the dedup check was straightforward.

### What was harder than expected
- Minor mismatch between the task prompt's stub schema and the protocol's schema (e.g. `definition`/`example` at top level vs `meanings` array, `antonyms` vs `antonymTerms`). Resolved by following VOCAB-AGENT.md as the source of truth.

### Process friction
- None this iteration. Scripts, validation, and commit flow all worked smoothly.

### Suggested improvement
- Consider adding a `--dedup-against` flag to the validate command in the seeder instructions so production dedup is checked automatically during validation.
