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

## [2025-07-24] Reflection cycle #1

### Pattern observed
1. **Repeated friction: BUILD.md simulator name and DEVELOPER_DIR** — 3 agents hit the same issue: hardcoded `iPhone 16` doesn't exist on current Xcode, and `xcode-select` pointing to CommandLineTools requires a DEVELOPER_DIR workaround. Each agent independently discovered the fix.
2. **Repeated friction: missing partOfSpeech values for Lithuanian** — 2 enricher agents independently suggested adding "particle" (and "interjection") because Lithuanian A1 words like taip, ne, ačiū, tik don't fit existing categories.
3. **Docs gap: BUILD.md claims test targets require Xcode GUI** — 1 agent proved CLI editing of pbxproj works for objectVersion 77 projects, contradicting the docs.

### Change 1
- **File**: `docs/BUILD.md`
- **What changed**: Replaced hardcoded `iPhone 16` simulator name with dynamic discovery approach; added `DEVELOPER_DIR` workaround note to prerequisites.
- **Why**: 3 agents wasted time independently discovering the same workaround.

### Change 2
- **File**: `scripts/validate_words.py` + `docs/CONVENTIONS.md`
- **What changed**: Added `"particle"` and `"interjection"` to `VALID_PARTS_OF_SPEECH` and the conventions doc.
- **Why**: 2 enricher agents were forced to use imprecise categories for Lithuanian particles.

### Change 3
- **File**: `docs/BUILD.md`
- **What changed**: Updated "Adding Unit Tests" section to note that CLI pbxproj editing works for objectVersion 77 projects.
- **Why**: The previous docs incorrectly stated test targets can only be created via Xcode GUI.

### Retro entries that triggered this
- [2025-07-17] [feat-language-field] [language-field] — "BUILD.md references `iPhone 16` simulator which doesn't exist on this Xcode version"
- [2025-07-21] [feat-tests-wordservice] [tests-wordservice] — "`xcode-select` was pointing to CommandLineTools instead of Xcode.app; had to use `DEVELOPER_DIR` env var workaround"
- [2025-07-21] [feat-lt-session-flow] [lt-session-flow] — "Xcode CLI environment required DEVELOPER_DIR workaround and simulator name discovery"
- [2025-07-15] [enricher-lt] [enrich-lt-batch-1-3] — "Consider adding a `partOfSpeech` value like 'particle' or 'interjection'"
- [2025-07-22] [enricher-lt-2] [enrich-lt-batch-4-8] — "Consider adding 'particle' or 'verb form' to `VALID_PARTS_OF_SPEECH`"
- [2025-07-21] [feat-tests-wordservice] [tests-wordservice] — "docs/BUILD.md says test targets can only be created via Xcode GUI … but manual pbxproj editing worked fine"

## [2025-07-25] Reflection cycle #2

### Pattern observed
1. **Repeated friction: fixed-size data tasks overshoot target counts** — two new retros reported generating too many items first (229 vs 200 LT words; 107 vs 100 EN words), then trimming.
2. **Docs gap: enricher prompt values drift from validator enums** — one new retro reported prompt-provided values (`pronoun`, `neutral`) failing validator and requiring remapping.

### Change 1
- **File**: `AGENTS.md`
- **What changed**: Added a hard rule requiring exact count verification before commit for tasks with explicit numeric targets.
- **Why**: Prevents repeat overshoot/trim loops on fixed-size data tasks.

### Change 2
- **File**: `docs/VOCAB-AGENT.md`
- **What changed**: Added explicit validator enum lists for `partOfSpeech` and `register`, plus an instruction to prefer validator values over prompt wording.
- **Why**: Reduces avoidable validation round-trips when task prompts suggest invalid enum values.

### Retro entries that triggered this
- [2025-07-22] [data-agent] [lt-vocab-initial] — "Balancing exactly 200 words across categories required a trim pass after initial generation overshot to 229."
- [2025-07-22] [feature/en-words-expansion] [en-words-expansion] — "Initial word list had 107 entries instead of 100; required trimming."
- [2025-07-22] [lt-enricher-3] [enrich-lt-batch-3] — "Allowed values for `register` and `partOfSpeech` differ from the task prompt … had to check validator output and remap."
