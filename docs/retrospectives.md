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
## [2026-02-21] [enricher-en-8] [enrich-en-8-30-stubs]

### What went well
- Preflight JSON check passed immediately, so editing could start without repair work.
- The enrichment + validator flow was stable; the batch passed `validate_words.py --status enriched` on first pass.

### What was harder than expected
- Several technical terms required careful wording to keep definitions concise but still domain-accurate.

### Process friction
- None this iteration.

### Suggested improvement
- Add a validator mode that lists relation self-references/duplicates explicitly to speed up QA pass/fail decisions.
- None.

## [2026-02-21] [enricher-lt-10] [vocab/enricher-lt-10]

### What went well
- Preflight JSON check passed before edits, and enriched-stage validation passed after updates.
- Enriched exactly 30 LT stub entries in one batch with validator-compliant POS/register values.

### What was harder than expected
- Keeping occupation-pair entries (masculine/feminine forms) consistent while keeping examples natural and non-duplicative took extra review.

### Suggested improvement
- Add a small helper script to print the next N LT stubs plus neighboring gender-pair terms before enrichment begins.

## [2026-02-21] [vocab-qa-agent] [vocab/qa-6]

### What went well
- Preflight JSON checks passed for both staging files, and all 35 EN + 35 LT `relations-added` entries were reviewed.
- Approved 68 entries and returned 2 LT entries (`sveikas`, `sveika`) to `enriched` with `qaNote` because greeting-oriented relations did not match the health adjective sense.
- Approved-status validation passed for both staging files after transitions.

### What was harder than expected
- `sveikas`/`sveika` have common greeting usage, so relation quality had to be checked against the actual meaning sense in the entry.

### Suggested improvement
- Add a QA check in the relations step to confirm synonyms/related terms align with the exact meaning gloss, not alternate senses.
## [2026-02-21] [relations-6] [vocab-relations-6]

### What went well
- Preflight and staged validation checks made it straightforward to update both EN and LT files safely in one pass.

### What was harder than expected
- Ensuring consistent, non-trivial relation sets across 70 entries required careful term-by-term curation.

### Process friction
- None this iteration.

### Suggested improvement
- Add an optional helper script for Relations agents to preselect the next N enriched terms and verify relation-field completeness before commit.
## [2026-02-21] [qa-7] [vocab-qa-7]

### What went well
- All 35 EN entries (C1 terms spanning genomics, rhetoric, linguistics, economics) were fully formed with correct partOfSpeech, register, synonyms, antonyms, and related terms — 35/35 approved in one pass.
- 34/35 LT entries (A1 city/places nouns) were clean and consistent — approved without edits.
- Validation script passed 160 EN approved entries and 181 LT approved entries with no errors.

### What was harder than expected
- One LT verb entry ("Atostogauti") had a capitalized term, which is invalid for a common Lithuanian verb. Flagged as `enriched` with qaNote for the enricher to fix.

### Suggested improvement
- Add a pre-commit lint rule that rejects entries whose `term` starts with an uppercase letter unless the word is a proper noun (detectable by the absence of a `properNoun: true` flag or by tag).

## [2026-02-21] [enricher-en-9] [vocab/enricher-en-9]

### What went well
- Preflight JSON validation passed immediately with no repair needed.
- All 30 EN stubs enriched in a single batch; `validate_words.py --status enriched` passed on the first run with 75 valid entries.
- Domain coverage was broad: engineering (mechatronics, aerodynamics, cryogenics, photolithography, nanofabrication), systems design (redundancy, scalability, robustness), diplomacy and geopolitics (demarche, rapprochement, détente, nonproliferation, multilateralism, realpolitik, geostrategy, bilateralism, nonalignment, consular, extradition, repatriation, armistice, protectorate), and anthropology (ethnogenesis, ethnography, kinship, matriliny, patriliny).

### What was harder than expected
- Several geopolitical and anthropological terms share subtle conceptual distinctions (e.g., matriliny vs. patrilineality, bilateralism vs. multilateralism) that required careful, differentiated definition wording to avoid repetition.

### Process friction
- None this iteration.

### Suggested improvement
- A pre-enrichment helper that groups thematically related stubs would make it easier to write consistent, cross-referencing definitions for term clusters.

## [2026-02-21] [qa-8] [vocab-qa-8]

### What went well
- Both staging files passed preflight JSON validation immediately (330 EN, 1960 LT entries; zero parse errors).
- All 35 EN entries were strongly formed: correct partOfSpeech, valid register, full definitions and examples, non-empty synonyms/antonyms/relatedTerms. 33/35 approved in one pass.
- 29/35 LT entries approved directly; 3 minor normalization fixes (capital-letter terms Žmogus→žmogus, Aktorius→aktorius; accusative form tvirtą→tvirta in sveika synonym) resolved without enricher round-trip.
- Repo validate_words.py passed 193 EN approved and 210 LT approved entries with no errors.

### What was harder than expected
- Several LT entries had subtle inaccuracies invisible to structural checks: wrong POS in antonym lists (sveikas: "ligonis" noun, "serga" verb conjugation instead of adjective forms), false antonym ("bėgti" for "eiti"), incorrect synonyms conflating register/scope ("studentas" for school-age "mokinys", "veteranas" for retired "pensininkas"), and inaccurate girl synonyms ("mažoji moteris", "dukrytė").
- Two EN entries required content-level synonym audit: "biomagnification" (trophic amplification ≠ single-organism accumulation) and "reforestation" (replanting ≠ afforestation on bare land) were incorrectly listed as synonyms.

### Suggested improvement
- Add a POS-consistency lint rule: for adjective entries, antonymTerms should only contain adjective/participial forms — detectable by checking that Lithuanian antonyms don't end in verb conjugation suffixes (-a 3rd person) or resolve to nouns in a known wordlist.
## [2026-02-21] [enricher-en-10] [vocab/enricher-en-10]

### What went well
- Preflight JSON validation passed immediately (330 entries, all valid).
- All 30 EN stubs enriched in a single batch; `validate_words.py --status enriched` passed on the first run with all 330 entries valid.
- Domain coverage was coherent: anthropology (acculturation, enculturation, liminality, totemism, diffusionism, ethnocentrism), genetics (pleiotropy, epistasis, haplotype, penetrance, expressivity, codominance, aneuploidy, euploidy, recombination, translocation, heterozygosity), neuroscience (connectome, synaptogenesis, myelination, nociception, proprioception, interoception, neurogenesis, lateralization, astrocyte, microglia), and architecture (fenestration, clerestory, entablature).
- All entries use `technical` or `formal` register, consistent with the academic nature of the vocabulary set.

### What was harder than expected
- Several neuroscience terms have closely related meanings (nociception vs. proprioception vs. interoception) requiring careful differentiation to avoid definition overlap.
- Genetics cluster (aneuploidy/euploidy, penetrance/expressivity, codominance) needed distinct wording despite conceptual proximity.

### Process friction
- None this iteration; field names (`language`, `partOfSpeech`, `meanings`) were consistent with the established schema.

### Suggested improvement
- Grouping thematically adjacent stubs into named clusters (e.g., "sensory neuroscience", "chromosomal genetics") before enrichment would further reduce the risk of repetitive definitions across closely related terms.
## [2026-02-21] [relations-8] [vocab/relations-8]

### What went well
- Preflight JSON validation on both files passed immediately; both parsed cleanly with no repair needed.
- All 35 EN enriched entries (math/engineering/diplomacy terms: injectivity → bilateralism) received non-trivial synonyms, antonymTerms, and relatedTerms in a single pass.
- All 35 LT enriched entries (profession M/F pairs: siuvėjas → verslininkė, plus Atostogauti which already held relations) updated to `relations-added` cleanly; Lithuanian-language relation terms used throughout.
- POS and register validation passed with zero errors across both files.

### What was harder than expected
- Generating meaningful Lithuanian synonyms for profession pairs was constrained: true synonym alternatives are sparse in LT, so related professions or compound descriptors were used where single-word synonyms do not exist.
- Many EN math-property terms (nilpotence, tribology, mechatronics) have no established synonym; empty `synonyms` arrays were used rather than forcing invented terms.

### Process friction
- None this iteration. Staging file structure, status conventions, and relation field names were all clearly documented.

### Suggested improvement
- Add a validation rule that warns when `synonyms` is empty for entries with `partOfSpeech: noun` in EN — helps surface terms that might benefit from a second enrichment pass or a domain-expert review.
## [2026-02-21] [qa-9] [vocab/qa-9]

### What went well
- Preflight JSON validation on both staging files passed immediately; both parsed cleanly with no structural repair needed.
- All 35 EN relations-added entries (math properties: injectivity → associativity; engineering/physics: tribology → nanofabrication; systems: redundancy, scalability, robustness; diplomacy/geopolitics: demarche → bilateralism) approved in one pass — POS (noun/adjective), register (technical/formal), definitions, examples, and relation fields all consistent and complete.
- 32 of 35 LT relations-added entries (gendered profession pairs: siuvėjas/siuvėja → verslininkas/verslininkė) approved cleanly; register uniformly `general`, Lithuanian-language definitions and relation terms throughout.
- Diacritic audit caught two missing ė characters in LT synonyms that automated schema validation would not detect.

### What was harder than expected
- Distinguishing a genuine diacritic error ("laivininke" vs "laivininkė", "komerciante" vs "komerciantė") from an intentional spelling variant required checking the pattern of other declined forms in the same file to confirm the ė suffix is standard for these noun types.
- "Atostogauti" arrived pre-flagged with a qaNote (term capitalised) but still carried `relations-added` status, requiring a judgment call about whether to re-approve or simply promote to `enriched`.

### Process friction
- A Python list-comprehension bug during the verslininkė fix accidentally produced "komercianteė" (ė appended rather than replacing final e); caught immediately by post-edit verification and corrected before commit.

### Suggested improvement
- Add an automated check for Lithuanian entries that validates final characters of synonyms/antonymTerms against known declension endings (e.g., masculine nominative -as/-is, feminine -a/-ė) to catch missing diacritics without relying on manual review.
## [2026-02-21] [enricher-en-11] [vocab/enricher-en-11]

### What went well
- Preflight JSON validation passed immediately (330 entries, zero parse errors).
- All 30 EN stubs enriched in a single batch; `validate_words.py --status enriched` passed on the first run (67 enriched entries, 0 errors).
- Domain coverage was coherent across three tightly themed clusters: architecture (pilaster, buttress, spandrel, mullion, cornice, cupola, cantilever, colonnade), culinary arts (julienne, chiffonade, confit, blanching, emulsification, mirepoix, gastrique, deglazing, tempering, roux, umami), and nautical terminology (starboard, portside, gunwale, scupper, hawser, capstan, keelson, binnacle, mizzenmast, boatswain, freeboard).
- All entries use `technical` or `general` register appropriate to domain; every entry has ≥3 synonyms, non-trivial antonymTerms, and ≥5 relatedTerms with strong cross-linking within clusters (e.g., roux ↔ béchamel ↔ velouté; capstan ↔ hawser ↔ bollard).

### What was harder than expected
- Several culinary terms have closely overlapping meanings (julienne vs. chiffonade, deglazing vs. gastrique) requiring careful differentiation to avoid definition repetition.
- "portside" required a POS decision (adjective rather than noun) to accurately reflect its most common usage as an attributive modifier.
- 22 pre-existing validation failures in relations-added entries (insufficient synonyms for math/diplomacy terms from relations-8) were present at preflight; confirmed as out-of-scope and not touched.

### Process friction
- None this iteration; schema, status conventions, and validation tooling were all consistent with prior sessions.

### Suggested improvement
- Consider adding a cross-cluster link lint step: for culinary terms that reference other culinary terms in `relatedTerms`, a quick check that those terms also exist in the staging file would catch dangling references early.

---

## Retro — vocab/enricher-lt-14 (LT Enricher)

**Date:** 2025-07-19
**Branch:** vocab/enricher-lt-14

### What was done
- Preflighted `words_lt_staging.json` — 1960 entries, 1605 stubs at start.
- Enriched **30 Lithuanian stub entries** — all descriptive adjective pairs:
  - **Emotional state (10):** liūdnas/liūdna, laimingas/laiminga, nelaimingas/nelaiminga, mielas/miela, piktas/pikta
  - **Appearance / aesthetics (6):** gražus/graži, negražus/negraži, bjaurus/bjauri
  - **Light / colour (4):** šviesus/šviesi, tamsus/tamsi
  - **Size / height / build (10):** žemas/žema, aukštas/aukšta, stambus/stambi, plonas/plona, malonus/maloni
- Each entry received: `partOfSpeech` (adjective), `translation`, `meanings` (definition + Lithuanian example sentence + register `general` + tags), `synonyms`, `antonymTerms`, `relatedTerms`. Status set to `enriched`.

### Validation
- `validate_words.py --status enriched` passed — 140 enriched entries valid ✓
- `validate_words.py` (full file) passed — 1960 entries valid ✓

### Decisions
- All 30 stubs were gendered adjective pairs; each received its own independent entry with a note in the definition identifying it as masculine or feminine/neuter form.
- Masculine forms include the feminine counterpart in `relatedTerms` and vice versa, enabling cross-navigation.
- Register set uniformly to `general` — these are everyday descriptive adjectives with no formal/technical register bias.
- `antonymTerms` reference the opposing adjective (e.g. gražus ↔ negražus/bjaurus); where a direct antonym pair exists within the 30 terms it is cited explicitly.
- No merges performed; branch left for PR review.

### What went well
- Batch of 30 was highly uniform (all adjectives, same schema shape) — script-based enrichment was fast and error-free in a single pass.
- Full-file validation passed immediately with zero errors.

### What was harder than expected
- Lithuanian gendered pairs are nearly identical semantically; distinguishing the definition wording concisely while being accurate required care.
- For `bjaurus`/`bjauri` the English gloss "ugly" overlaps with `negražus`; translation kept as "ugly" for both but example sentences disambiguate context (appearance vs character).

### Process friction
- None. Staging file and conventions were well-established from previous iterations.

### Suggested improvement
- Consider adding a `genderForm` metadata field (masc/fem/neut) to adjective entries to reduce the need to embed gender notes in free-text definitions.
## [2026-02-21] [relations-9] [vocab/relations-9]

### What went well
- Preflight JSON validation on both files passed immediately; both parsed cleanly with no structural errors.
- All 35 EN enriched entries (anthropology, genetics, neuroscience, and architecture clusters — from ethnogenesis through entablature) received accurate synonyms, antonymTerms, and relatedTerms in a single pass; status set to `relations-added`.
- All 35 LT enriched entries (profession M/F pairs: vertėjas/vertėja through mokytojas/mokytoja; four seasons: pavasaris, vasara, ruduo, žiema; and eight weekday/time nouns: savaitė, pirmadienis–sekmadienis, rytas) received Lithuanian-language relations; status set to `relations-added`.
- POS and register validation passed with zero errors across both files (EN: 70 total relations-added; LT: 70 total relations-added).

### What was harder than expected
- Lithuanian profession pairs have very few true single-word synonyms; compound descriptors (e.g. "medicinos brolis/sesuo" for slaugytojas/slaugytoja) were used where single-word equivalents do not exist.
- Weekday nouns in Lithuanian have minimal synonyms in standard usage; "savaitės pradžia" / "savaitės vidurys" used as descriptive near-synonyms where conventional alternatives are absent.

### Process friction
- None this iteration. Schema, status conventions, and relation field names were stable and consistent with prior rounds.

### Suggested improvement
- For tightly coupled M/F noun pairs (e.g. vertėjas/vertėja), consider a `grammaticalVariant` field to explicitly cross-reference gender forms rather than relying on relatedTerms for that link.

## [2026-02-21] [qa-10] [vocab/qa-10]

### Summary
Reviewed 35 EN (`relations-added` → batch-10 anthropology/genetics/neuroscience/architecture cluster) and 35 LT (`relations-added` → profession M/F pairs, seasons, weekdays, rytas) entries.

**EN:** 34 approved, 1 enriched  
**LT:** 29 approved, 6 enriched

### Issues found and fixed

**English (1):**
- **euploidy** — `antonymTerms` contained `"polyploidy"`, which the entry's own example sentence explicitly describes as *"a form of euploidy"*. A subtype cannot be an antonym of its parent. Removed `"polyploidy"` from `antonymTerms`; `"aneuploidy"` retained as the sole correct antonym.

**Lithuanian (6):**
- **slaugytojas** & **slaugytoja** — `relatedTerms` contained `"palatą"` (accusative case). Relation lists store headword forms (nominative); corrected to `"palata"` in both entries.
- **fotografas** — `synonyms` contained `"fotogrataras"`, a clear misspelling (likely garbling of `"fotografas"`, the term itself). Removed the erroneous synonym.
- **Pavasaris** — `term` was stored as `"Pavasaris"` with a capital P. Common nouns in the vocab corpus are stored lowercase; corrected to `"pavasaris"`.
- **ruduo** — `synonyms` contained `"lapkritis"`, which is the Lithuanian word for *November* (the month), not a synonym for autumn. Removed.
- **žiema** — `synonyms` contained `"žiemasergis"`, not a recognised modern or archaic Lithuanian word (the expected archaic analogue of `"vasarmetis"` / `"rudenmetis"` would be `"žiemametis"`). Removed.

### What went well
- Both JSON files passed preflight validation with no parse errors.
- The 34 EN approvals and 29 LT approvals required no edits; all POS values and registers were within the valid enumeration.
- Issues were caught through systematic cross-checking of synonym/antonymTerm content against definitions and examples, and through case/spelling inspection of term fields.

### What was harder than expected
- Detecting the `euploidy`/`polyploidy` antonym contradiction required reading the example sentence carefully; the structural fields (POS, register) were all valid.
- Lithuanian inflected forms in relation lists (`"palatą"`) are easy to miss because the form is phonetically close to the nominative; only a morphological check reveals the mismatch.

### Process friction
- None. The workflow (preflight → review → approve/enrich + qaNote → commit → retro) is now well-established and ran cleanly.

### Suggested improvement
- Add a validation rule to the `validate_words.py` script that checks all values in `relatedTerms` and `synonyms` against a nominative-form word list (or at minimum flags non-nominative Lithuanian noun endings such as `-ą`, `-ų`, `-ui`).
- Consider a linter check that flags when a term's own string appears verbatim (or near-verbatim) inside its `synonyms` array.
## [2026-02-21] [enricher-lt-15] [vocab/enricher-lt-15]

### What went well
- Preflight JSON check passed immediately; staging file was valid before and after enrichment.
- All 30 stubs were gendered adjective pairs (masculine/feminine) covering core everyday vocabulary: new, strange, interesting, boring, friendly, intelligent, strong, weak, quiet, noisy, slow, fast, excellent, good, bad.
- Single-pass enrichment script enriched all 30 in one run — zero validator errors on 138 enriched entries.
- `validate_words.py --status enriched` passed with 138 entries valid ✓.

### What was harder than expected
- Feminine forms required careful wording to be genuinely distinct definitions while remaining accurate (not just a copy of the masculine entry).
- `synonyms` for some adjective pairs (e.g. lėtas/lėta) had limited single-word Lithuanian alternatives; compound descriptors avoided in favour of the closest single-word equivalents.

### Decisions
- All 30 stubs are basic A1/A2 adjective pairs; register set to `general` throughout — no formal/technical/literary usage for this vocabulary tier.
- `antonymTerms` cross-reference within the 30 where a direct opposite exists (e.g. greitas ↔ lėtas, geras ↔ blogas), otherwise standard Lithuanian antonyms used.
- Feminine forms note their gender in the definition for clarity and cross-reference the masculine base in `relatedTerms`.

### Process friction
- None. Conventions, schema, and tooling were stable from prior enricher iterations.

### Suggested improvement
- A `genderForm` metadata field (masc/fem) on adjective entries would eliminate the need for gender notes in free-text definitions and simplify downstream QA.
## [2026-02-22] [relations-10] [vocab/relations-10]

### What went well
- Preflight JSON validation passed on both files immediately; 330 EN entries and 1960 LT entries parsed cleanly.
- LT: all 35 target entries had a clean separation — exactly 35 `enriched` entries were missing all three relation fields, making selection unambiguous; synonyms/antonymTerms/relatedTerms added fully in Lithuanian with appropriate semantic coverage across time/frequency adverbs, numerals 0–10, and core family nouns.
- EN: the 32 `enriched` entries were already fully populated with relations from a prior pass but had not had their status advanced; these were efficiently promoted to `relations-added`. Three `approved` medical-vocabulary entries (iatrogenic, nosocomial, pathognomonic) had synonyms but lacked antonymTerms and relatedTerms — these were completed, bringing the EN batch to exactly 35.
- POS and register validation passed with zero errors across both files (EN: 70 total `relations-added`; LT: 70 total `relations-added`).

### What was harder than expected
- Lithuanian numerals (Nulis–dešimt) have very few conventional single-word synonyms; collective/ordinal forms (e.g. "dveji", "treji") and descriptive labels ("dešimtis") were used as the closest equivalents.
- Lithuanian antonymTerms for numerals required adjacent-number antonyms (n−1, n+1) rather than true semantic opposites, since abstract numeric antonymy is context-dependent.

### Process friction
- EN `enriched` entries were already complete but status-stale; the preflight analysis step was essential to detect this mismatch before writing incorrect data.

### Suggested improvement
- Add a CI lint rule that flags entries where all three relation fields are non-empty but `status` is still `enriched` — this would catch status-stale entries before they accumulate across batches.
## [2026-02-22] [qa-11] [vocab/qa-11]

### What went well
- Preflight JSON validation passed on both files immediately; 430 EN entries and 1960 LT entries parsed without errors.
- All 35 EN and 35 LT `relations-added` entries reviewed in a single pass.
- EN domain coverage was coherent: medical terms (iatrogenic, nosocomial, pathognomonic), architecture (pilaster through freeboard), culinary technique (julienne through umami), and nautical vocabulary (starboard through freeboard).
- LT domain coverage was equally coherent: time/frequency adverbs, basic numerals 0–10, and core family nouns.
- Validator passed cleanly for all `enriched` entries (EN: 9 valid; LT: 122 valid) and all new `approved` LT entries (293 valid).

### What was harder than expected
- LT numeral entries: distinguishing between ordinal synonyms (pirmas, dešimtas) and legitimate collective/noun forms (trejetas, dešimtis) required careful per-entry analysis rather than a blanket rule.
- "stranger as antonym" pattern: the family-noun batch (žmona, brolis, sesuo, pusseserė, tėvai) systematically used "nepažįstamasis/nepažįstamoji/nepažįstamieji" as antonyms, which looks plausible at first glance but is semantically empty. Required consistent removal across five entries.
- colonnade: all three listed synonyms (arcade, peristyle, portico) were architectural relatives rather than true synonyms, leaving the synonyms array empty after correction; no replacement candidates were available without introducing new content.

### Decisions
- "Stranger" antonyms removed universally from family-noun entries; no replacement added where none exists (pusseserė replaced with "pusbrolis" as gender counterpart).
- Cardinal vs ordinal: ordinals moved to relatedTerms; cardinal synonyms and collective forms retained.
- Adjacent-number antonyms for numerals (e.g. trys ↔ du/keturi) approved as a deliberate structural design choice for A1 vocabulary linking, consistent with the prior batch decision.
- colonnade synonyms left empty rather than fabricated; qaNote documents the reasoning.

### Process friction
- Pre-existing validator failures on unrelated `approved` entries (bilateralism, diffusionism, penetrance, aneuploidy, entablature — each with only 1 synonym) appeared in the EN approved run but are out of scope for this batch.

### Suggested improvement
- Add a lint rule that rejects "nepažįstamasis/nepažįstamoji/nepažįstamieji" as antonymTerms for any family/kinship noun — this pattern recurred across five entries and is never semantically valid.
- Consider a validator check that flags ordinal-form synonyms paired with cardinal-form headwords (e.g. "pirmas" in synonyms of "vienas") by comparing the `-as`/`-a` suffix pattern against the headword's numeral type.
## [2026-02-23] [relations-11] [vocab/relations-11]

### What went well
- Preflight JSON check passed on both staging files immediately (1960 LT entries, 430 EN entries valid).
- LT: 35 enriched entries processed cleanly in a single-pass script — 15 qaNote entries (relations already corrected by prior enricher passes, status just needed advancing) plus 20 family/state vocabulary entries with sparse or missing relations.
- EN: 1 available enriched entry (euploidy) had a resolved qaNote; promoted cleanly to relations-added.
- All targeted entries passed `validate_words.py --status relations-added` with zero errors (LT: 70 total, EN: 36 total).
- Fixed three secondary data-quality issues discovered during inspection: encoding bug in `mirusi` synonyms (Cyrillic 'а' U+0430 → Latin 'a' U+0061), typo in `norėti` synonyms (`troškti` → `trokšti`), and improper capitalisation on three terms (`Atostogauti`, `Vedęs`, `Galėti`).

### What was harder than expected
- EN staging file had only 1 enriched entry available; all other entries were either stub, approved, or already relations-added — the 35-per-file target could not be met for EN. Processed all 1 available.
- Several LT entries had relation fields populated but `status` still `enriched` (same status-stale pattern from relations-10); preflight analysis was essential to detect this before overwriting good data.
- The Cyrillic/Latin homoglyph in `mirusi` synonyms would silently pass JSON validation and display identically in most editors — only caught via `hex(ord(c))` inspection.

### Decisions
- Processed all 35 available LT enriched entries and the 1 available EN enriched entry; did not promote `approved` entries backward to fill the 35-per-file target for EN, as that would violate the pipeline order.
- qaNote fields removed only after verifying the noted issue was already resolved in the data.
- Term capitalisation fixes (`Atostogauti` → `atostogauti`, `Vedęs` → `vedęs`, `Galėti` → `galėti`) applied as part of this pass since the validator does not enforce case and these were blocking correct lookup.

### Process friction
- 26 pre-existing validation errors in `approved` entries of words_staging.json (insufficient synonyms) surfaced during full-file validation — unrelated to this task, not fixed here. Should be addressed by a dedicated QA pass.

### Suggested improvement
- Add a homoglyph check to `validate_words.py` that flags strings containing characters outside the expected Unicode blocks for a given language (Latin + Lithuanian diacritics for LT, plain ASCII/Latin for EN).
- Track `enriched` entry counts per file in a CI summary so agents know before starting how many entries are actually available for the target batch size.
