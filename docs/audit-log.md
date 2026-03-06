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
[2025-07-17] [architecture-agent] [lt-vocab-app] [commit] [completed] [choices] [90%] Technical architecture for lt-vocab-app: data model changes, session flow, SM-2 SR, navigation restructure, 11 tasks detailed | doubts: SwiftData unique-key migration from term to uniqueKey may require manual intervention on existing installs
[2025-07-17] [feat-language-field] [language-field] [commit] [completed] [clear] [95%] Added language, translation, uniqueKey fields to Word model; updated WordService with per-language loading; updated SpeechService with language parameter; updated ContentView to load both EN and LT | doubts: SwiftData lightweight migration for uniqueKey change untested on existing data
[2025-07-17] [feat-haptics] [haptics] [commit] [completed] [clear] [95%] Added UINotificationFeedbackGenerator haptics on quiz correct (.success) and wrong (.error) answers in QuizView.swift | doubts: none
[2025-07-21] [feat-tests-wordservice] [tests-wordservice] [commit] [completed] [clear] [95%] Added VocabTests target to Xcode project and WordServiceTests.swift with 2 passing tests (emptyDatabase, alreadyLoaded). Created shared scheme with test action. | doubts: none
[2025-07-21] [feat-lt-ui-filter] [lt-ui-filter] [commit] [completed] [clear] [95%] Added LanguageFilter segmented control (All/English/Lithuanian) to WordListView; filters words by language field | doubts: none
[2025-07-21] [feat-lt-session-flow] [lt-session-flow] [commit] [completed] [choices] [92%] Implemented session flow: SessionService state machine, SessionStartView with language picker, SessionSummaryView, FlashcardsView/QuizView accept [Word] param, ContentView restructured to 3 tabs (Study/Words/Stats). Build succeeds. | doubts: FlashcardsView session integration uses callback pattern; QuizView still has internal start-quiz flow that may need further refinement in lt-quiz-modes task
[2025-07-24] [reflection-agent] [reflection-1] [commit] [completed] [clear] [92%] Reflection cycle 1: fixed BUILD.md simulator/DEVELOPER_DIR (3 retros), added particle/interjection to partOfSpeech (2 retros), updated test target docs (1 retro) | doubts: none
[2025-07-21] [feat-lt-empty-states] [lt-empty-states] [commit] [completed] [clear] [95%] Added empty state views: SessionStartView shows first-time guidance, no-words-for-language, and all-caught-up states; WordListView distinguishes no-words-loaded from no-search-results; StatsView has language picker and no-stats-yet state; TTS button hidden when voice unavailable. Build succeeds. | doubts: none
[2025-07-23] [feat-lt-stats] [lt-stats-per-lang] [commit] [completed] [clear] [95%] Added language field to QuizResult, language picker to StatsView, per-language filtering for overview cards/mastery/quiz history. Build succeeds. | doubts: none
[2025-07-21] [feat-spaced-rep] [spaced-rep] [commit] [completed] [clear] [95%] Implemented SM-2 spaced repetition: added SR fields (nextReview, easeFactor, interval, repetitions) to Word model; created SpacedRepetitionService with nextReview(for:quality:); updated SessionService to prioritise overdue words; updated FlashcardsView to sort due words first. Build succeeds, tests pass. | doubts: none
[2026-02-21] [feat-agent] [word-meanings-model] [commit] [completed] [choices] [90%] Migrated Word model to JSON-encoded meanings[] with computed definition/example compatibility and updated WordService to decode both meanings[] and legacy flat fields; build succeeds on iPhone 17 Pro (iPhone 16 Pro destination unavailable locally). | doubts: SwiftData upgrade behavior from existing persisted flat fields should be verified on a real upgrade dataset
[2026-02-21] [reflection-agent] [reflection-3] [commit] [completed] [clear] [93%] Reflection cycle 3: added simulator destination fallback policy, updated worktree verification/rebase guidance for append-only files, and documented current-vs-target JSON schema compatibility in architecture docs. | doubts: none
[2026-02-21] [vocab-relations-agent] [relations-5] [commit] [completed] [clear] [95%] Added relation fields and moved 35 enriched EN + 35 enriched LT staging entries to relations-added; validator passed for both files | doubts: none
[2026-02-21] [enricher-en-8] [enrich-en-8-30-stubs] [commit] [completed] [clear] [96%] Enriched 30 EN stubs in words_staging.json, validated enriched stage, and added session retrospective. | doubts: none
[2026-02-21] [enricher-lt-10] [vocab/enricher-lt-10] [commit] [completed] [clear-instructions] [96%] Enriched 30 LT profession stubs in words_lt_staging.json; preflight and enriched validation passed | doubts: none
[2026-02-21] [qa-agent] [qa-28] [commit] [completed] [clear] [95%] QA batch 28: reviewed 37 EN + 35 LT relations-added entries; approved 33 EN + 32 LT; sent 4 EN (ergodicity, attractor, emergence, teleonomy) + 3 LT (Autobusas, atleisti, Kaimas) back to enriched with qaNotes; validator passes for batch-28 entries | doubts: none
[2026-02-25] [reflection-agent] [reflection-6] [commit] [completed] [clear] [90%] Reflection cycle 6: added LT term capitalisation rules to Seeder and Enricher, added semantic synonym/antonym quality rules to Relations section, added Hard Rule reminder in AGENTS.md — all triggered by recurring QA rejections in qa-28/qa-29/qa-30 | doubts: none

[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 1270 EN + 1415 LT approved words from staging to production. Removed 22 EN + 166 LT duplicate entries from staging. Fixed 80 EN + 44 LT self-referential/cross-array relation errors. EN production: 196 → 1466 words. LT production: 200 → 1615 words. | doubts: 824 EN + 608 LT validation warnings remain — all from original pre-pipeline words (old schema without meanings/language/relations fields)
[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 22 LT approved words. LT production: 1615 → 1637 words. | doubts: none
[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 20 EN approved words. EN production: 1466 → 1486 words. | doubts: none
[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 19 LT approved words. LT production: 1637 → 1656 words. Removed 3 duplicates from staging. | doubts: none
[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 20 EN + 32 LT approved words. EN production: 1486 → 1506. LT production: 1656 → 1688. | doubts: none
[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 35 LT approved words. LT production: 1688 → 1723 words. | doubts: none
[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 36 EN + 35 LT approved words. EN production: 1506 → 1542. LT production: 1723 → 1758. | doubts: none
[2026-02-23] [publisher] [vocab-publish] [commit] [planned] [clear-instructions] [95%] Publish 35 EN + 40 LT approved words. EN production: 1542 → 1577. LT production: 1758 → 1798. | doubts: none

## 2025-07-13 — LT verb forms completion

- **Action**: Added forms/governedCase to last missing verb (`užpildyti`) and 10 staging verbs
- **Files**: `words_lt_staging.json`, `docs/ARCHITECTURE.md`
- **Result**: All 270 LT infinitive verbs in production now have forms data; 10 staging verbs updated; schema documented
- **Commit**: `6b99378`

## 2025-07-16 — vocab/backfill-lt-verb-forms

- **Action**: Removed 33 conjugated-form headwords from `words_lt_staging.json`; added `forms`+`governedCase` to 57 production verbs in `words_lt.json`
- **Branch**: `vocab/backfill-lt-verb-forms`
- **Commit**: 6688c23
- **Reversible**: Yes — `git revert 6688c23`

### 2025-07-14 — Publish EN+LT words to production
- **Action**: Published 100 approved EN words and 11 approved LT words from staging to production
- **Branch**: `main`
- **Commit**: aa79046
- **Result**: EN production now 1904 words, LT production now 2304 words; EN staging 0 remaining, LT staging 125 remaining
- **Reversible**: Yes — `git revert aa79046`

## 2025-07-15 — Publish 37 LT words
- **Agent**: Copilot CLI
- **Action**: Published 37 approved LT entries from `words_lt_staging.json` → `words_lt.json`
- **Production count**: 2464 LT words
- **Commit**: `publish: move 37 approved LT words to production`
- **Reversible**: Yes (`git revert`)

## 2026-03-06 — EN Vocabulary Full Pipeline Run
- **Agent**: pipeline-en-agent (Copilot CLI)
- **Action**: Ran full EN vocabulary pipeline on words_staging.json
- **Details**: QA 50 relations-added (47 approved, 3 reset+fixed) + relations 18 enriched + seeded 50 new C1+ stubs + enriched 50 stubs + relations 50 + QA 68 (66 approved + 2 reset+fixed). All 115 EN entries now approved.
- **Doubts**: none
- **Reversible**: Yes — git revert to pre-pipeline state
[2026-03-06] [continuous-lt] [vocab-enricher-lt] [commit] [cycle-complete] [100%] Cycle 103: seeded 100, enriched 100, published 100 LT words | doubts: none
[2026-03-06] [continuous-en] [vocab-enricher-en] [commit] [cycle-complete] [100%] Cycle 3: seeded 50, enriched 50, published 2413 EN words | doubts: none
[2026-03-06] [continuous-en] [vocab-enricher-en] [commit] [cycle-complete] [100%] Cycle 4: seeded 50, enriched 50, published 2463 EN words | doubts: none
[2026-03-06] [continuous-lt] [vocab-enricher-lt] [commit] [cycle-complete] [100%] Cycle 104: seeded 100, enriched 100, published 100 LT words | doubts: none
[2026-03-06] [continuous-en] [vocab-enricher-en] [commit] [cycle-complete] [100%] Cycle 5: seeded 50, enriched 50, published 2513 EN words | doubts: none
[2026-03-06] [continuous-lt] [vocab-enricher-lt] [commit] [cycle-complete] [100%] Cycle 105: seeded 100, enriched 100, published 100 LT words | doubts: none
