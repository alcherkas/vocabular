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

## [2025-07-24] [reflection-agent] [reflection-1]

### What went well
- 11 retrospective entries provided clear, consistent signal — patterns were easy to identify without ambiguity.
- Protocol doc (REFLECTION-AGENT.md) pattern table mapped directly to observed issues; no guesswork needed.

### What was harder than expected
- Deciding whether BUILD.md counts as a "convention doc" for permission purposes — it's not explicitly listed in the allowed-files section of the protocol, but the fix was clearly high-impact (3 retros). Proceeded because BUILD.md is process infrastructure, not production code.

### Process friction
- The protocol's "Types of changes you can make" list is narrower than the actual set of process docs (e.g., BUILD.md, WORKTREES.md are not mentioned). This could cause future reflection agents to skip valid fixes.

### Suggested improvement
- Expand the allowed-file list in REFLECTION-AGENT.md to explicitly include BUILD.md and WORKTREES.md as editable process docs.
## [2025-07-21] [feat-lt-empty-states] [lt-empty-states]

### What went well
- All ACs were clearly specified and non-overlapping; each view had a single empty state to add.
- Existing code structure (computed properties, @Query) made adding filtered empty states straightforward.
- Build succeeded on first attempt after all changes.

### What was harder than expected
- Nothing significant; task was well-scoped and low complexity.
## [2025-07-23] [feat-lt-stats] [lt-stats-per-lang]

### What went well
- Task was well-scoped: 3 files changed with clear acceptance criteria. Existing StatsView structure made adding filtering straightforward.
- SwiftData lightweight migration handles the new `language` field on QuizResult with default value automatically.

### What was harder than expected
- Nothing unexpected; minimal complexity task with clear insertion points.

### Process friction
- None this iteration.
---

## spaced-rep — SM-2 Spaced Repetition

### What went well
- Architecture doc had exact field names, algorithm, and file list — implementation was straightforward.
- SM-2 algorithm is simple to implement; all three files (Word.swift, SpacedRepetitionService.swift, SessionService.swift) integrated cleanly.
- Build succeeded on first attempt.

### What was harder than expected
- Nothing significant. The architecture doc provided clear guidance.

### Process friction
- xcodebuild required full path due to xcode-select pointing to CommandLineTools; iPhone 16 simulator not available (used iPhone 17 Pro).

### Suggested improvement
- None.

## [2025-07-25] [feat-agent] [lt-spaced-rep-per-lang]

### What went well
- SessionService already had 90% of the SR-aware logic from the spaced-rep task; only two surgical fixes needed (cap new words at maxNew, remove upcoming fallback).
- Build succeeded on first attempt after the change.

### What was harder than expected
- xcode-select still points to CommandLineTools; required DEVELOPER_DIR workaround. iPhone 16 Pro simulator doesn't exist (used iPhone 17 Pro).

### Process friction
- None. Task was well-scoped with clear acceptance criteria.

### Suggested improvement
- None.
## [2025-07-22] data-agent lt-vocab-initial

### What went well
- Created 200 Lithuanian A1/A2 words covering 12+ categories (numbers, colors, family, food, animals, body, verbs, adjectives, greetings, time, places, clothing) in the flat production schema matching words.json format.

### What was harder than expected
- Balancing exactly 200 words across categories required a trim pass after initial generation overshot to 229.

### Process friction
- None significant; existing words.json and words_lt_staging.json provided clear schema references.

### Suggested improvement
- A target word-count-per-category guideline in AGENTS.md would prevent overshoot on future vocabulary batches.
---

## lt-enricher-3 — Enrich 25 Lithuanian stubs (batch 3)

### What went well
- Enriched 25 A1 words (pronouns, verbs, nouns) in one pass.
- Validation script caught register/partOfSpeech mismatches quickly.

### What was harder than expected
- Allowed values for `register` and `partOfSpeech` differ from the task prompt (e.g., no "pronoun" or "neutral"); had to check validator output and remap.

### Process friction
- None.

### Suggested improvement
- Include exact allowed enum values in the agent task prompt to avoid validation round-trips.
---

## Retro · EN Words Expansion (feature/en-words-expansion)
**Date**: 2025-07-22

### What was done
- Added 100 new C1/C2 English words to `words.json` (96 → 196 total).
- Categories covered: academic writing, business, science, arts, philosophy, politics, psychology, medicine, law, technology.
- Each entry includes term, definition, 2–5 synonyms, example sentence, partOfSpeech, and tags.
- Validated: 196 total, 196 unique — zero duplicates.

### What went well
- Schema matched existing format on first attempt; no structural fixes needed.

### Process friction
- Initial word list had 107 entries instead of 100; required trimming.

### Suggested improvement
- Pre-calculate target count before generation to avoid trim step.

## [2026-02-21] [feat-agent] [lt-session-timer]

### What went well
- SessionService already had the SR partitioning/cap structure, so only a small targeted update was needed.
- Build verification succeeded immediately after the change.

### What was harder than expected
- Balancing the "max 5 new words" rule with the "new users can get up to 15" requirement needed explicit zero-history handling.

### Process friction
- None this iteration.

### Suggested improvement
- None.
## [2026-02-21] [feat-agent] [lt-quiz-modes]

### What went well
- Quiz mode refactor fit cleanly into a new `QuizService`, so QuizView changes stayed focused on rendering/state.
- Build passed after the refactor on an available simulator target.

### What was harder than expected
- The requested `iPhone 16 Pro` simulator destination is not available in this environment, so strict build-command verification had to use a nearby fallback target.

### Process friction
- Build validation commands in tasks can be brittle across Xcode/simulator versions when they hardcode a specific device name.

### Suggested improvement
- Prefer `Any iOS Simulator Device` (or document a fallback device-selection step) for acceptance build commands.
## [2026-02-21] [feat-agent] [word-meanings-model]

### What went well
- Kept View layer unchanged by preserving `definition` and `example` as computed compatibility properties on `Word`.
- Implemented dual-schema decoding in `WordService` so both legacy flat JSON and `meanings[]` JSON load with one path.

### What was harder than expected
- SwiftData attribute-based transformable declaration failed to compile cleanly in this environment, requiring a pivot to explicit JSON `Data` persistence.

### Process friction
- Requested build destination (`iPhone 16 Pro`) is unavailable on this machine; validation needed a fallback destination (`iPhone 17 Pro`) after running the requested command.

### Suggested improvement
- Update build docs to include a simulator-discovery step and an accepted fallback destination policy.
## [2026-02-21] [feat-agent] [word-relations]

### What went well
- Relationship fields and relation-term decoding were added with small, isolated changes in `Word.swift` and `WordService.swift`.
- Build verification succeeded with the requested simulator destination command.

### What was harder than expected
- Ensuring relations are resolved only after all `Word` instances are inserted required a second pass structure.
## [2026-02-21] [feat-agent] [word-of-day-lt]

### What went well
- SessionStartView already had a clean idle-state split, so adding the card was a focused change in one file.
- Existing `Word` fields (`language`, `translation`, `definition`, `example`) mapped directly to EN/LT card variants.

### What was harder than expected
- `xcodebuild` initially failed because `xcode-select` pointed to CommandLineTools; needed `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

### Process friction
- None this iteration.

### Suggested improvement
- None.

## [2026-02-21] [feature-agent] [widget]

### What went well
- Widget files were added without touching the existing app target files, keeping the change isolated and low risk.
- The widget supports both app-group shared data and bundled JSON fallback in one provider flow.

### What was harder than expected
- `xcodebuild` is unavailable in this environment because the active developer directory points to CommandLineTools.

### Process friction
- Validating full iOS target integration from CLI is limited until Xcode target wiring is done manually.

### Suggested improvement
- Add a lightweight documented CLI verification path for widget source-only changes (e.g., Swift syntax/typecheck command).

## [2026-02-21] [vocab-relations-agent] [vocab-relations-1]

### What went well
- Updated all 15 enriched EN entries and the first 20 enriched LT entries in one pass with `synonyms`, `antonymTerms`, and `relatedTerms`.
- Stage validation passed for both staging files on `relations-added` status.

### What was harder than expected
- Lithuanian greeting/particle phrases required careful selection of natural same-language relation terms.

### Process friction
- None.

### Suggested improvement
- Add a small canonical LT phrase synonym/antonym reference list to reduce wording variance across relation batches.

## [2026-02-21] [reflection-agent] [reflection-3]

### What went well
- New retros since cycle 2 had clear repeated signal around simulator destination failures and command-line environment drift.
- The required changes were all doc-level and surgical (3 files), so risk remained low.

### What was harder than expected
- Retrospective entry formatting is inconsistent in older sections, so identifying "new since cycle 2" required filtering by cycle boundary/date rather than strict heading format.

### Process friction
- BUILD guidance was improved in cycle 1, but a stale hardcoded simulator command remained in WORKTREES.md, so agents still hit destination failures.
- High same-day append volume across retros/audit/changelog creates practical merge-conflict pressure for append-only files.

### Suggested improvement
- Add a tiny helper script for append-only writes (`scripts/append_entry.py`) to auto-rebase, append, and preserve chronological ordering.
## [2026-02-21] [seeder-lt-1] [seed-lt-a1a2-100]

### What went well
- Dedup checking against the full staging set made it straightforward to add exactly 100 new unique LT stubs.
- Topic-based batching helped keep coverage balanced across all requested A1/A2 domains.

### What was harder than expected
- Existing staging already contained many common transport, health, and profession terms, so several candidate lists needed replacement passes.

### Process friction
- None this iteration.

### Suggested improvement
- Add a small helper script to report per-topic coverage and duplicate candidates before seeding.
## [2026-02-21] [enricher-lt-4] [enrich-lt-25-stubs]

### What went well
- The next 25 stub terms formed a coherent A1 set (jobs, address forms, and question words), so enrichment was consistent and fast.

### What was harder than expected
- Assigning allowed validator part-of-speech values for pronoun-like items (`mano`, `kieno`, `kas`) required using the closest supported category.

### Process friction
- The task template suggested enum values (`neutral`, `pronoun`) that do not match `validate_words.py` constraints.

### Suggested improvement
- Add a short enum-reference note to enrichment task templates so prompts stay aligned with validator rules.
## [2026-02-21] [vocab-seeder-agent] [seeder-en-1]

### What went well
- Added exactly 100 new C1+ English stub terms to `Vocab/Vocab/Resources/words_staging.json` in one pass.
- Pre-checked terms against both staging and production word lists to avoid introducing duplicates.

### What was harder than expected
- Curating a domain-balanced list that stayed fully outside existing staging/production vocab required an extra candidate pass.

### Process friction
- None.

### Suggested improvement
- Keep a reusable vetted candidate bank by domain to speed up future fixed-size seeding tasks.
## [2026-02-21] [enricher-en-2] [enrich-en-2]

### What went well
- Updated all available English stubs in one pass with definitions, examples, register, and tags.
- Enriched-status validation passed cleanly after the edits.

### What was harder than expected
- The task target asked for 25 stubs, but the staging file currently contained only 15 entries with `status: "stub"`.

### Process friction
- None beyond the target/count mismatch in the prompt versus file state.

### Suggested improvement
- Add a preflight step in task prompts that reports current stub count before assigning a fixed enrichment target.
## [2026-02-21] [vocab-qa-agent] [vocab-qa-1]

### What went well
- Reviewed all `relations-added` entries in both EN and LT staging files and completed status transitions in one pass.
- Validation checks passed after updates (`approved` EN and LT, plus LT `enriched`).

### What was harder than expected
- A malformed EN staging JSON entry (`derealization`) blocked parsing and had to be corrected before QA processing.

### Process friction
- No quick script exists to list and diff only target-status entries with structured QA notes, so review relied on manual inspection.

### Suggested improvement
- Add a small helper script for QA workflow: list entries by status and apply approved/enriched+qaNote updates safely.
## [2026-02-21] [vocab-seeder-agent] [seeder-en-2]

### What went well
- Added 100 new C1/C2 English stub terms in one pass while preserving the required stub schema.
- Pre-checked candidate terms against both staging and production lists, so no duplicates were introduced.

### What was harder than expected
- Existing staging already covered many advanced technical domains, so candidate selection needed a filtered replacement pass.

### Process friction
- None this iteration.

### Suggested improvement
- Add a reusable CLI helper that proposes domain-balanced, deduplicated candidates before writing stubs.
## [2026-02-21] [enricher-en-3] [enrich-25-en-stubs]

### What went well
- Enriched exactly 25 English stub entries in one pass with complete meanings, part of speech, tags, and synonyms.
- `validate_words.py --status enriched` passed immediately after updates.

### What was harder than expected
- Several terms were highly technical, so examples needed careful domain context while staying concise.

### Process friction
- The task example used `register: "neutral"`, but the validator only accepts `general`, `technical`, `formal`, or `literary`.

### Suggested improvement
- Add the validator enum values directly to enrichment task prompts to avoid schema drift.
## [2026-02-21] [enricher-lt-5] [vocab/enricher-lt-5]

### What went well
- Enriched exactly 25 Lithuanian stubs in one contiguous country/nationality/language block, which kept tagging consistent.
- Applied required fields (`translation`, `meanings`, `tags`, `synonyms`) for all 25 entries without touching unrelated terms.

### What was harder than expected
- Prompt-level enums differed from repository validator constraints, requiring a quick normalization pass for `partOfSpeech` and `register` values.

### Process friction
- Validation guidance in prompts still references values not accepted by `scripts/validate_words.py`.

### Suggested improvement
- Keep enrichment prompt enum lists synchronized with `validate_words.py` to avoid avoidable rework.
## [2026-02-21] [enricher-en-4] [vocab/enricher-en-4]

### What went well
- Enriched 30 contiguous English stubs with consistent C1 technical definitions and examples in one pass.
- Validation ran cleanly for both full staging and enriched-only subsets after updates.

### What was harder than expected
- The staging JSON had a pre-existing malformed tail that had to be corrected before enrichment could be validated.

### Process friction
- A malformed trailing block in `words_staging.json` blocked baseline validation and required manual cleanup.

### Suggested improvement
- Add a lightweight JSON syntax check step before enrichment tasks to surface structural file issues immediately.
## [2026-02-21] [enricher-lt-6] [vocab/enricher-lt-6]

### What went well
- Enriched 30 Lithuanian stubs in one contiguous section, which kept schema edits consistent and easy to verify.
- Targeted validation with `scripts/validate_words.py --status enriched` passed cleanly for the selected 30 entries.

### What was harder than expected
- Prompt POS enum and repository validator enum differ, so POS choices had to be kept in their overlap for clean validation.

### Process friction
- None this iteration.

### Suggested improvement
- Keep enrichment prompt enum lists synchronized with `scripts/validate_words.py` to avoid ambiguity.
## [2026-02-21] [vocab-relations-2] [relations-2]

### What went well
- Updated both staging files in one pass and moved exactly 30 enriched entries per file to `relations-added`.
- Validation passed for all updated `relations-added` entries in EN and LT files.

### What was harder than expected
- `words_staging.json` had a malformed tail entry that had to be corrected before relation updates/validation.

### Process friction
- Permission check task IDs are strict; branch/task naming can differ from accepted script IDs.

### Suggested improvement
- Add branch-name-to-task-id mapping guidance in `docs/VOCAB-AGENT.md` for permission checks.
## [2026-02-21] [vocab-qa-agent] [vocab/qa-2]

### What went well
- Confirmed there were no `relations-added` entries left in either staging file, so no QA status transitions were needed.
- Approved-entry validation passed for both staging files after restoring valid JSON structure in EN staging.

### What was harder than expected
- The EN staging file had a trailing malformed fragment that blocked structured checks until removed.

### Process friction
- The QA task depended on relation-stage output, but current staging state had zero target-status entries to review.

### Suggested improvement
- Add an orchestrator preflight guard that skips spawning QA when `relations-added` count is zero.
## [2026-02-21] [vocab-qa-agent] [vocab/qa-3]

### What went well
- Reviewed all 30 `relations-added` entries in EN and 30 in LT, then transitioned statuses in one pass with clear pass/fail criteria.
- Required approved validation passed for EN staging after updates.

### What was harder than expected
- Some LT entries had stale `qaNote` text from prior checks, so each note had to be re-validated against the current synonym set before deciding final status.

### Process friction
- No dedicated QA helper exists to bulk-clear stale `qaNote` values when entries are approved, so updates were manual/scripted at file level.

### Suggested improvement
- Add a QA utility mode in `scripts/validate_words.py` to list `relations-added` entries and flag stale `qaNote` text after relation edits.

## [2026-02-21] [enricher-lt-9] [vocab/enricher-lt-9]

### What went well
- Preflight JSON check and enriched-status validation both passed, so the 30-word batch landed cleanly in one pass.

### What was harder than expected
- Maintaining consistent glossary phrasing across masculine/feminine profession pairs required extra review for natural examples.
## [2026-02-21] [enricher-en-7] [vocab/enricher-en-7]

### What went well
- Completed preflight JSON validation before edits and enriched exactly 30 English stub entries in one focused batch.
- Targeted enriched validation passed immediately after the updates.

### What was harder than expected
- Several domain-heavy linguistic and economic terms required careful register selection to keep labels consistent.

### Process friction
- None this iteration.

### Suggested improvement
- Add a small reusable template for profession-pair entries (male/female forms) to speed up LT enrichment batches.
## [2026-02-21] [vocab-relations-agent] [relations-4]

### What went well
- Preflight JSON checks passed for both staging files, and relation updates were applied in one deterministic pass.
- Processed exactly 35 enriched entries in each staging file and moved them to `relations-added` with validator-compliant relation fields.

### What was harder than expected
- Several LT enriched entries already had empty relation arrays, so deciding between minimal updates and richer relation filling required a consistency pass.

### Process friction
- The relation quality bar is implicit; validator constraints are clear, but semantic depth expectations are not explicitly measurable.

### Suggested improvement
- Add a lightweight relation-quality checklist to `docs/VOCAB-AGENT.md` (e.g., when to keep LT synonyms empty vs when to add related terms).
- Add a lightweight command in `docs/VOCAB-AGENT.md` to print the next 30 stub terms before enrichment starts.
## [2026-02-21] [vocab-relations-agent] [relations-5]

### What went well
- Ran JSON preflight checks on both staging files before edits and completed one-pass relation updates safely.
- Added `synonyms`, `antonymTerms`, and `relatedTerms` for exactly 35 enriched entries in EN and 35 in LT, then set status to `relations-added`.
- Validation passed for both files on `relations-added` entries.

### What was harder than expected
- Balancing concise but useful LT relation sets for proper nouns and phrase-level entries required consistency review.

### Process friction
- Relation quality expectations remain mostly implicit beyond validator constraints, so semantic depth still depends on operator judgment.

### Suggested improvement
- Add a small rubric in `docs/VOCAB-AGENT.md` for relation density by category (proper noun, phrase, technical term) to reduce variability across batches.

## [2026-02-21] [vocab-qa-agent] [vocab/qa-5]

### What went well
- Preflight JSON checks passed for both staging files, and all `relations-added` entries were reviewed in one pass.
- Approved all 35 EN and 35 LT reviewed entries after confirming valid `partOfSpeech` and meaning `register` values.
- Approved-status validation passed for both staging files after status transitions.

### What was harder than expected
- There is no built-in semantic scoring for relation quality, so review still depends on manual judgment beyond schema-level checks.

### Process friction
- None this iteration.

### Suggested improvement
- Add a validator mode that lists relation self-references/duplicates explicitly to speed up QA pass/fail decisions.
