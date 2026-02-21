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
