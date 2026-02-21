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

## [2025-07-15] [enricher-lt] [enrich-lt-batch-1-3]

### What went well
- The pipeline protocol was clear and easy to follow: pick stubs, enrich, validate, commit.
- Validation script caught issues early and gave clear feedback; all 3 batches passed on first attempt.
- The first 15 Lithuanian entries were common greetings/phrases, so definitions were straightforward.

### What was harder than expected
- Several early entries (labas, labanakt, sudie, etc.) had empty `partOfSpeech`; deciding between "phrase" and "adverb" for single-word expressions like "taip", "ne", "gerai" required judgment.
- "prašom" has multiple distinct uses (you're welcome / please go ahead) — collapsing into one meaning felt lossy but kept the batch moving.

### Process friction
- None significant this iteration. The staging file structure and validation script worked smoothly.

### Suggested improvement
- Consider adding a `partOfSpeech` value like "particle" or "interjection" to `VALID_PARTS_OF_SPEECH` — many Lithuanian A1 words (taip, ne, ačiū) are particles, not true adverbs.
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
## [2025-07-17] [requirements-agent] [lt-vocab-app]

### What went well
- Goal description and notes in GOALS.md were detailed and specific — made writing acceptance criteria straightforward.
- ARCHITECTURE.md already documented the data model, JSON schema, and LT word structure, so requirements could reference concrete fields and files.

### What was harder than expected
- Deciding the right session size (10–15 items) required balancing the 5-minute constraint against spaced repetition needs — no prior data to calibrate against.

### Process friction
- None this iteration. Protocol was clear and all referenced docs existed.

### Suggested improvement
- None.
## [2025-07-17] [architecture-agent] [lt-vocab-app]

### What went well
- Requirements doc was thorough (21 ACs, edge cases, constraints) — made architecture decisions straightforward.
- ARCHITECTURE.md and existing source files gave clear picture of current state, so I could design precise model changes.
- Task dependency graph fell out naturally from the AC→task mapping; no orphaned ACs.

### What was harder than expected
- Deciding whether `word-meanings-model` (flat→meanings migration) should be a prerequisite for lt-vocab-app or independent. Resolved by keeping them separate since flat schema works for all 21 ACs.
- The SwiftData unique-key change (term→uniqueKey) has uncertain migration behavior — flagged as a risk but couldn't fully resolve without testing on device.

### Process friction
- ARCHITECTURE.md documents the `meanings` array as the production JSON schema, but `words.json` actually uses the old flat schema. This inconsistency required extra analysis to determine what the current truth is vs. what's aspirational.

### Suggested improvement
- Add a "Current vs. Target" section to ARCHITECTURE.md that explicitly marks which schema changes are aspirational vs. implemented, to reduce confusion for architecture/feature agents.

## [2025-07-17] [feat-language-field] [language-field]

### What went well
- Task scope was clear: exactly 4 files to modify with well-defined acceptance criteria.
- Architecture doc provided exact code sketches for Word model changes and WordService loading, making implementation mechanical.
- Build succeeded on first attempt after all changes.

### What was harder than expected
- Xcode CLI tooling required DEVELOPER_DIR override and the simulator name had changed (iPhone 17 Pro instead of iPhone 16).

### Process friction
- BUILD.md references `iPhone 16` simulator which doesn't exist on this Xcode version; had to discover available simulators manually.

### Suggested improvement
- Update BUILD.md to use `'platform=iOS Simulator,name=Any iOS Simulator Device'` or document how to find available simulators first.
## [2025-07-17] [feat-haptics] [haptics]

### What went well
- Minimal-complexity task; the selectAnswer method was the clear insertion point for haptic feedback.

### What was harder than expected
- Xcode not available in the environment, so build verification was skipped. Change is trivial (2 lines of UIKit API).

### Process friction
- None. Task was well-scoped with clear acceptance criteria.

### Suggested improvement
- None.
## [2025-07-21] [feat-tests-wordservice] [tests-wordservice]

### What went well
- The existing `WordService` API (`loadInitialWords(into:)`) was simple and testable — in-memory `ModelContainer` made isolated testing straightforward.
- Xcode project uses `PBXFileSystemSynchronizedRootGroup` (objectVersion 77), so adding the test file to the `VocabTests/` directory auto-includes it in the target.
- Both tests passed on first run with zero code changes to the production `WordService`.

### What was harder than expected
- No test target existed in the project; had to manually add a `VocabTests` native target, build configurations, dependency proxy, and shared scheme to the pbxproj file.
- `xcode-select` was pointing to CommandLineTools instead of Xcode.app; had to use `DEVELOPER_DIR` env var workaround.

### Process friction
- `docs/BUILD.md` says test targets can only be created via Xcode GUI ("cannot be done via CLI"), but manual pbxproj editing worked fine for objectVersion 77 projects. Consider updating BUILD.md to document the CLI approach.

### Suggested improvement
- Update `docs/BUILD.md` to note that for projects using file-system synchronized groups (objectVersion 77), test targets can be added by editing `project.pbxproj` directly without the Xcode GUI.

## [2025-07-21] [feat-lt-ui-filter] [lt-ui-filter]

### What went well
- Task was well-scoped: single file change with clear acceptance criteria. Existing `filteredWords` computed property made adding the language filter trivial.
- Word model already had `language: String` field from the `language-field` task.

### What was harder than expected
- Xcode not available in the environment, so build verification was skipped. The change is straightforward SwiftUI (enum + Picker + filter).

### Process friction
- None. Task was minimal complexity with clear insertion points.
## [2025-07-23] [enricher-en] [enrich-en-batch-1-3]

### What went well
- Protocol was clear and easy to follow; all 3 batches (15 words) passed validation on first attempt.
- The validation script gave immediate, actionable feedback — no ambiguity about what fields were required.
- C1+ academic words had well-established definitions, making enrichment straightforward with high confidence.

### What was harder than expected
- Deciding between one vs. two meanings per word: most C1 adjectives/verbs had a single dominant sense, but "conflagration" warranted two (literal fire + figurative conflict). Kept it simple where one meaning was sufficient.

### Process friction
- None this iteration. Staging schema, validation, and commit flow all worked smoothly.

### Suggested improvement
- None.
## [2025-07-22] [enricher-lt-2] [enrich-lt-batch-4-8]

### What went well
- Pipeline protocol was smooth: 5 batches of 5 words each, all validated on first attempt.
- Validation script is reliable — caught the correct count (40 enriched) and passed cleanly every batch.
- Words in this range (dabar through gyventi) formed natural clusters (time adverbs, būti conjugations, dirbti conjugations), making definitions consistent.

### What was harder than expected
- Deciding `partOfSpeech` for conjugated verb forms (esu, esi, yra, etc.) — they are verb forms, not standalone verbs, but "verb" is the closest valid category.
- "tik" can function as an adverb, conjunction, or particle depending on context; had to pick the most common usage.

### Process friction
- None significant. The worktree setup, validation, and commit flow all worked as documented.

### Suggested improvement
- Consider adding "particle" or "verb form" to `VALID_PARTS_OF_SPEECH` — Lithuanian has many conjugated forms listed as separate entries, and "verb" is imprecise for forms like "esu" or "dirba".
## [2025-07-21] [feat-lt-session-flow] [lt-session-flow]

### What went well
- Architecture doc had detailed code sketches for SessionService state machine and view structure, making implementation straightforward.
- All 6 files created/modified compiled on second attempt (only issue was a removed import needed by #Preview).

### What was harder than expected
- Xcode CLI environment required DEVELOPER_DIR workaround and simulator name discovery (iPhone 17 Pro, not iPhone 16).

### Process friction
- None significant. Architecture doc and TASKS.md were clear on acceptance criteria and file list.

### Suggested improvement
- None.
