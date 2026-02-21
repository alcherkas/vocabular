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

## [2026-02-21] Reflection cycle #3

### Pattern observed
1. **Repeated simulator destination friction persists outside BUILD.md** — recent feature retros still report unavailable hardcoded simulator names (`iPhone 16 Pro`) and fallback retries.
2. **Append-only process files now receive high-concurrency writes** — cycles 4–6 produced many same-day retro/audit/changelog append operations, increasing conflict risk during rebases.
3. **Schema-compatibility confusion risk** — recent model migration retro noted dual-schema loading (`meanings[]` + legacy flat fields), but architecture docs still presented only the target schema path.

### Change 1
- **File**: `docs/BUILD.md`
- **What changed**: Added a task destination fallback policy: run requested command once, then rerun with discovered/`Any iOS Simulator Device` destination and report both.
- **Why**: Standardizes build/test validation when task prompts hardcode unavailable simulator names.

### Change 2
- **File**: `docs/WORKTREES.md`
- **What changed**: Replaced hardcoded `iPhone 16` test destination with dynamic `DEVICE` guidance, updated rebase command to `origin/main`, and added explicit append-only conflict handling guidance.
- **Why**: Removes stale simulator defaults and reduces avoidable merge conflicts on frequently appended process logs.

### Change 3
- **File**: `docs/ARCHITECTURE.md`
- **What changed**: Added explicit current-vs-target JSON schema note (legacy flat fields accepted, `meanings[]` canonical for new writes) and aligned part-of-speech enum with validator values.
- **Why**: Reduces schema drift confusion between staging/production expectations and documented architecture constraints.

### Retro entries that triggered this
- [2026-02-21] [feat-agent] [lt-quiz-modes] — "requested `iPhone 16 Pro` simulator destination is not available … had to use a nearby fallback target."
- [2026-02-21] [feat-agent] [word-meanings-model] — "Requested build destination (`iPhone 16 Pro`) is unavailable … fallback destination (`iPhone 17 Pro`)."
- [2026-02-21] [feature-agent] [widget] — "`xcodebuild` is unavailable in this environment because the active developer directory points to CommandLineTools."
- [2026-02-21] [feat-agent] [word-meanings-model] — "updated WordService to decode both `meanings[]` and legacy flat fields."
- [2026-02-21] [feat-agent] [lt-session-timer] — "Build verification succeeded immediately after the change." (same-day parallel retro volume indicates append-only collision risk)
- [2026-02-21] [feat-agent] [word-of-day-lt] — "`xcodebuild` initially failed because `xcode-select` pointed to CommandLineTools; needed `DEVELOPER_DIR`."

## [2026-02-25] Reflection cycle #4

### Pattern observed
1. **Pre-existing validation errors block full-file runs** — across enricher-en-11, enricher-en-14, qa-11, relations-11, and relations-13, agents reported that running `validate_words.py` without `--status` always exits 1 due to synonym-count errors in prior-batch `approved` entries, forcing agents to use `--status enriched` workaround which skips structural checks on the whole file.
2. **QA-caught relational errors preventable at Relations stage** — qa-8 through qa-13 consistently flag terms appearing in their own synonyms arrays (self-references) and Lithuanian accusative forms (`-ą`/`-ų` endings) in relation arrays instead of nominative headwords. These are structural/mechanical errors that a linter can catch before QA review.
3. **Orchestrator spawns QA with zero target entries; VOCAB-AGENT.md enum docs are wrong** — qa-2 reported a wasted QA cycle when `relations-added` count was zero. Additionally, the Enricher section of VOCAB-AGENT.md listed `pronoun` and `neutral` as *invalid* examples, but both are accepted by the actual validator; and `preposition`, `conjunction`, `numeral`, `informal`, `slang` were missing entirely, causing avoidable round-trips.

### Change 1
- **File**: `scripts/validate_words.py`
- **What changed**: Added self-reference check (term in its own relation arrays) and LT accusative/genitive form check (`-ą`/`-ų` endings in LT relation arrays) to `validate_relations`; added `--errors-for STATUS[,...]` flag that validates all entries but scopes the exit code to specified statuses, routing other-status errors to warnings.
- **Why**: Self-reference and LT accusative errors were caught by QA in every cycle; `--errors-for` eliminates the pre-existing-errors noise that blocked full-file validation runs.

### Change 2
- **File**: `docs/VOCAB-AGENT.md`
- **What changed**: Fixed the Enricher "Validator enum values" section to list all 11 valid `partOfSpeech` values and all 7 valid `register` values (removed the incorrect note labelling `pronoun`/`neutral` as invalid); added LT relation quality rubric to the Relations section; added preflight stub-count snippet; added `--errors-for` example to the Relations validate step.
- **Why**: The wrong enum docs caused avoidable validation round-trips; the relation rubric addresses the implicit quality bar that multiple Relations/QA retros called out.

### Change 3
- **File**: `docs/ORCHESTRATOR.md`
- **What changed**: Added `relations_added > 0` guard to the QA spawn condition in the Work Scanner loop; added a status-count helper script and per-stage pre-spawn guards (Enricher/Relations/QA/Publisher) with minimum thresholds; added `--errors-for` usage note.
- **Why**: qa-2 reported a wasted QA agent cycle with zero target entries; explicit count guards prevent all four stages from being spawned when their input queue is empty.

### Retro entries that triggered this
- [2026-02-21] [enricher-en-11] [vocab/enricher-en-11] — "22 pre-existing validation failures in relations-added entries (insufficient synonyms) were present at preflight; confirmed as out-of-scope and not touched."
- [2026-02-24] [enricher-en-14] [vocab/enricher-en-14] — "Full validate_words.py run exits with code 1 due to 27 pre-existing synonym-count errors; running with --status enriched is necessary to get a clean signal."
- [2026-02-24] [relations-13] [vocab/relations-13] — "Add a --since-commit flag to validate_words.py so agents can scope validation to only entries changed in the current session."
- [2026-02-21] [qa-10] [vocab/qa-10] — "Add a validation rule to validate_words.py that checks all values in relatedTerms and synonyms against a nominative-form word list."
- [2026-02-21] [qa-10] [vocab/qa-10] — "Consider a linter check that flags when a term's own string appears verbatim inside its synonyms array."
- [2026-02-21] [qa-9] [vocab/qa-9] — "Add an automated check for Lithuanian entries that validates final characters of synonyms/antonymTerms against known declension endings."
- [2026-02-24] [qa-13] [vocab/qa-13] — "Several LT synonyms were incorrectly conjugated/declined forms rather than nominative headwords."
- [2026-02-21] [vocab-qa-agent] [vocab/qa-2] — "Add an orchestrator preflight guard that skips spawning QA when relations-added count is zero."
- [2026-02-21] [enricher-en-8] [enrich-en-8-30-stubs] — "Add a validator mode that lists relation self-references/duplicates explicitly to speed up QA pass/fail decisions."

## [2026-02-21] Reflection cycle #5

### Pattern observed
1. **Cross-array and within-array duplicates in relation fields** — relations-19 found 11 EN entries where the Enricher placed the same term in both a primary relation array and `relatedTerms`; qa-14 found two LT entries (jų, kokie) where the same string appeared twice in `relatedTerms`. Neither pattern was caught by the existing validator. The relations-19 retro explicitly requested a cross-array dedup check.
2. **Substring self-references reach QA** — qa-18 caught `"archaeal methanogenesis"` listed as a synonym for `"methanogenesis"`. The cycle-4 self-reference check only matches the exact headword; it does not catch phrases containing the headword as a substring.
3. **Inflected-form errors persist in new variants** — the cycle-4 `-ą`/`-ų` word-final check has reduced obvious accusative forms, but qa-15 found a new sub-pattern: compound LT phrases where a genitive-plural modifier precedes a head noun (`autobusų stotis`, `traukinių stotis`, `dviračių stotis`). These pass the existing character-ending check because the full string does not end in `-ų`. Enrichers are now explicitly noting they verified nominative forms, indicating rising awareness, but the pattern still reaches QA.

**Answers to specific questions:**
- **QA still catching cross-array duplicates and self-references?** Yes, in every cycle post-4. Exact self-reference is largely prevented by the cycle-4 rule, but substring self-reference and cross-array/within-array duplicates are new variants that bypass it.
- **New failure modes?** (1) Cross-array duplicates (same term in synonyms + relatedTerms). (2) Within-array duplicates (same string twice in one array). (3) Substring self-referential phrases.
- **Validator improvements?** All three patterns above are mechanically detectable and are now addressed (see Change 1).

### Change 1
- **File**: `scripts/validate_words.py`
- **What changed**: Added three new checks to `validate_relations`: (a) substring self-reference (headword appears as substring of any relation item); (b) within-array duplicate detection (same string twice in one array); (c) cross-array duplicate detection (same string in two or more of the three relation arrays).
- **Why**: Cross-array dups found in 11 entries by relations-19; within-array dups in qa-14; substring self-reference in qa-18 — all patterns that the existing validator did not catch.

### Change 2
- **File**: `docs/VOCAB-AGENT.md`
- **What changed**: Expanded the "Rules that the validator now enforces" block in the Relations section to document the three new checks (substring self-reference, cross-array duplicates, within-array duplicates).
- **Why**: Agents will now see the complete rule set before writing relation arrays, preventing the errors rather than just catching them at validate time.

### Retro entries that triggered this
- [2025-07-14] [qa-14] [vocab/qa-14] — "relatedTerms contained duplicate entry 'jos' / 'koks' — simple copy-paste duplicates reaching QA stage."
- [2025-07-18] [qa-18] [vocab/qa-18] — "'archaeal methanogenesis' listed as synonym for 'methanogenesis' — self-referential phrase not caught by exact-match check."
- [2025-07-14] [qa-15] [vocab/qa-15] — "autobusų stotis/traukinių stotis/dviračių stotis in relatedTerms — genitive-plural modifier in compound phrase not flagged by -ų word-final check."
- [2025-02-21] [relations-19] [vocab/relations-19] — "11 EN entries had cross-array duplicates (same term in synonyms/antonyms AND relatedTerms); consider adding a cross-array dedup check to the validator."
