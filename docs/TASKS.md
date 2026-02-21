# Task Backlog

## How to Claim a Task

1. Change `[ ]` to `[in-progress: <your-agent-id>]` on the task line.
2. Set up a worktree: `git worktree add ../vocabular-wt-<task-id> -b feature/<task-id>`
3. When done, change to `[done]` and merge back to `main`.

> Only claim one task at a time. Tasks within the same file area must not be claimed by two agents simultaneously.

## Risk Levels

Each task has a `[risk: low/medium/high]` label.

| Risk | Meaning | What agent must do before merging |
|------|---------|----------------------------------|
| `low` | Isolated change, easy to revert | Tests pass — merge freely |
| `medium` | Touches shared model or multiple files | Tests pass + append to `audit-log.md` |
| `high` | Breaking schema change, large surface area | Tests pass + append to `audit-log.md` + write to `decisions-pending.md` for human diff review |

## Complexity Levels

Each task also has a `[complexity: minimal/low/intermediate/high]` label based on how many subgoals and interdependencies it involves.

| Complexity | Meaning | Agent behavior |
|-----------|---------|---------------|
| `minimal` | Single direct action, no decomposition | Proceed end-to-end |
| `low` | Single goal, multi-step sequence | Proceed; commit each step |
| `intermediate` | Complex goal broken into clear subgoals | Stop after each subgoal, confirm before next |
| `high` | Many subgoals with interdependencies | Stop after each subgoal; write to `audit-log.md` at each checkpoint; escalate any uncertainty |

---

## Vocabulary Pipeline Tasks

> These are **continuous-loop** tasks. See `docs/VOCAB-AGENT.md` for the full protocol.
> Vocab agents use branch prefix `vocab/` not `feature/`.

### `vocab-seeder-en`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `low`
**Role**: Seeder (English)
**Description**: Continuously add C1+ English word stubs to `words_staging.json`. Run the Seeder loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`
**Target**: 500+ stubs (current production: 96 words)

---

### `vocab-seeder-lt`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `minimal`
**Role**: Seeder (Lithuanian)
**Description**: Continuously add A1/A2 Lithuanian word stubs to `words_lt_staging.json`. Run the Seeder loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_lt_staging.json` (create if absent)
**Target**: 200 stubs

---

### `vocab-enricher-en`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `low`
**Role**: Enricher (English)
**Description**: Pick up `stub` entries in `words_staging.json` and add all meanings (definitions, examples, register, tags). Run the Enricher loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`

---

### `vocab-enricher-lt`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `low`
**Role**: Enricher (Lithuanian)
**Description**: Pick up `stub` entries in `words_lt_staging.json` and add meanings + translation. Run the Enricher loop.
**Files to touch**: `Vocab/Vocab/Resources/words_lt_staging.json`

---

### `vocab-relations`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `low`
**Role**: Relations
**Description**: Pick up `enriched` entries in staging files and add synonyms, antonyms, relatedTerms. Run the Relations loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`, `words_lt_staging.json`

---

### `vocab-qa`
**Status**: `[ ]`
**Risk**: `medium`
**Complexity**: `low`
**Role**: QA Reviewer
**Description**: Review `relations-added` entries. Approve or send back for rework. Run the QA loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`, `words_lt_staging.json`

---

### `word-meanings-model`
**Status**: `[ ]`
**Risk**: `high`
**Complexity**: `high`
**Description**: Update `Word.swift` and `WordService.swift` to support the `meanings` array schema (replaces flat `definition`/`example` fields). Update all Views that reference `.definition` or `.example`.
**Files to touch**: `Vocab/Vocab/Models/Word.swift`, `Vocab/Vocab/Services/WordService.swift`, all View files that use `.definition`/`.example`
**Acceptance criteria**:
- `Word` model has `meanings: [WordMeaning]` where `WordMeaning` has `definition`, `example`, `register`, `tags`
- `WordData` codable struct updated to match new JSON schema
- All views compile and show primary meaning (first entry) by default
- App builds without errors, existing words still load

---

## App Model & Feature Tasks

### `word-relations`
**Status**: `[ ]`
**Risk**: `medium`
**Complexity**: `intermediate`
**Description**: Add `antonyms` and `relatedWords` as SwiftData `@Relationship` fields to `Word.swift`.
**Files to touch**: `Vocab/Vocab/Models/Word.swift`, `Vocab/Vocab/Services/WordService.swift` (update `WordData` struct + loader)
**Acceptance criteria**:
- `Word` model compiles with `@Relationship(deleteRule: .nullify) var antonyms: [Word]` and `relatedWords: [Word]`
- `WordData` codable struct supports optional `antonymTerms: [String]?` for JSON
- App builds without errors

---

### `language-field`
**Status**: `[done]`
**Risk**: `medium`
**Complexity**: `low`
**Description**: Add `language: String`, `translation: String?`, and `uniqueKey: String` fields to `Word.swift`. Update `WordService` to support per-language loading. Update `SpeechService` to accept a language parameter.
**Files to touch**: `Vocab/Vocab/Models/Word.swift`, `Vocab/Vocab/Services/WordService.swift`, `Vocab/Vocab/Services/SpeechService.swift`
**Acceptance criteria**:
- `Word` model has `language: String` (default `"en"`) and `translation: String?` (nil for EN)
- `Word` model has `@Attribute(.unique) var uniqueKey: String` (format `"language:term"`); `@Attribute(.unique)` removed from `term`
- `WordData` codable struct updated with optional `language`, `translation` fields
- `WordService.loadWords(language:resourceName:into:)` loads a specific language file, sets `uniqueKey` on each word
- Migration function populates `uniqueKey` for existing words in DB
- `SpeechService.speak(_:language:)` uses `"en-US"` for EN, `"lt-LT"` for LT; graceful fallback if LT voice unavailable
- Both `words.json` and `words_lt.json` can be loaded independently
- App builds without errors; existing EN words load correctly with defaults

---

## Data Population Tasks

### `en-words-expansion`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `low`
**Description**: Expand `words.json` from current count toward 1000 C1+ English words. Add 100 words per batch.
**Files to touch**: `Vocab/Vocab/Resources/words.json`
**Acceptance criteria**:
- All new words follow JSON schema in `docs/ARCHITECTURE.md`
- No duplicate `term` values
- Each word has: term, definition, 2–5 synonyms, example sentence, partOfSpeech, tags

---

### `lt-vocab-initial`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `low`
**Description**: Create `words_lt.json` with 200 Lithuanian A1/A2 basic words.
**Files to touch**: `Vocab/Vocab/Resources/words_lt.json` (create new)
**Acceptance criteria**:
- File follows LT JSON schema in `docs/ARCHITECTURE.md`
- Each word has: term (Lithuanian), definition (English description), translation (EN gloss), example (Lithuanian sentence), partOfSpeech, tags
- 200 words covering: numbers, colors, family, food, animals, daily verbs, common adjectives

---

## Feature Tasks

### `spaced-rep`
**Status**: `[ ]`
**Risk**: `high`
**Complexity**: `high`
**Description**: Implement SM-2 spaced repetition algorithm for word scheduling. Add SR fields to Word model and create SpacedRepetitionService.
**Files to touch**: `Vocab/Vocab/Models/Word.swift` (add `nextReview: Date?`, `easeFactor: Double`, `interval: Int`, `repetitions: Int`), new `Vocab/Vocab/Services/SpacedRepetitionService.swift`
**Acceptance criteria**:
- `Word` model has SR fields: `nextReview: Date?`, `easeFactor: Double = 2.5`, `interval: Int = 0`, `repetitions: Int = 0`
- `SpacedRepetitionService.updateSchedule(for:quality:)` implements SM-2 algorithm, updates Word's SR fields in-place
- Quality mapping: 0–2 = incorrect (reset repetitions), 3–5 = correct (advance interval)
- `easeFactor` never drops below 1.3
- `nextReview` is set to `today + interval` days after each review
- Existing words get default SR values via SwiftData lightweight migration (no data loss)
- App builds and tests pass

---

### `lt-ui-filter`
**Status**: `[done]`
**Risk**: `low`
**Complexity**: `low`
**Description**: Add language filter to `WordListView` so user can browse EN or LT words separately.
**Depends on**: `language-field` task must be done first.
**Files to touch**: `Vocab/Vocab/Views/WordListView.swift`
**Acceptance criteria**:
- Picker or segmented control for `All / English / Lithuanian`
- `@Query` predicate filters by `language` field
- Default is `All`

---

### `word-of-day-lt`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `minimal`
**Description**: Extend `HomeView` to show a Lithuanian Word of the Day alongside the English one (or as a toggle).
**Depends on**: `language-field` and `lt-vocab-initial` must be done first.
**Files to touch**: `Vocab/Vocab/Views/HomeView.swift`
**Acceptance criteria**:
- LT word of the day shown with translation
- Falls back gracefully if no LT words loaded yet

---

### `haptics`
**Status**: `[done]`
**Risk**: `low`
**Complexity**: `minimal`
**Description**: Add haptic feedback on quiz correct/wrong answers.
**Files to touch**: `Vocab/Vocab/Views/QuizView.swift`
**Acceptance criteria**:
- `UIImpactFeedbackGenerator` on correct answer (`.success`)
- `UINotificationFeedbackGenerator` on wrong answer (`.error`)

---

### `widget`
**Status**: `[ ]`
**Risk**: `medium`
**Complexity**: `intermediate`
**Description**: Add a WidgetKit extension for Word of the Day home screen widget.
**Files to touch**: New `VocabWidget/` target (create in Xcode)
**Acceptance criteria**:
- Widget shows today's word + definition
- Updates daily via timeline
- Works on iOS 26 home screen

---

## Test Tasks

### `tests-wordservice`
**Status**: `[done]`
**Risk**: `low`
**Complexity**: `low`
**Description**: Add unit tests for `WordService` (requires `VocabTests` target — see `docs/BUILD.md`).
**Files to touch**: `Vocab/VocabTests/WordServiceTests.swift` (create)
**Acceptance criteria**:
- `test_loadInitialWords_emptyDatabase` — verifies words are inserted
- `test_loadInitialWords_alreadyLoaded` — verifies no duplicates on second load
- All tests pass with `xcodebuild test`

---

## lt-vocab-app Feature Tasks

> These tasks implement the `lt-vocab-app` goal. See `docs/requirements/lt-vocab-app.md` for full requirements.

### `lt-session-flow`
**Status**: `[done]`
**Risk**: `medium`
**Complexity**: `high`
**Description**: Implement session start screen with language picker, session orchestration via `SessionService` (@Observable state machine: idle → loading → active → complete), and session summary. Restructure ContentView tabs from 5 (Today/Cards/Quiz/Words/Progress) to 3 (Study/Words/Stats). Repurpose FlashcardsView and QuizView to accept session words as input.
**Depends on**: `language-field`
**Files to touch**: new `Vocab/Vocab/Views/SessionStartView.swift`, new `Vocab/Vocab/Views/SessionSummaryView.swift`, new `Vocab/Vocab/Services/SessionService.swift`, `Vocab/Vocab/ContentView.swift`, `Vocab/Vocab/Views/FlashcardsView.swift`, `Vocab/Vocab/Views/QuizView.swift`, `Vocab/Vocab/Views/HomeView.swift`
**Acceptance criteria**:
- Language picker (EN / LT) shown on Study tab; defaults to last-used language (stored in `UserDefaults`)
- `SessionService` is `@Observable` with states: `idle`, `loading`, `active`, `complete`
- `startSession(language:context:)` queries words for chosen language, builds session word list
- FlashcardsView and QuizView accept `[Word]` parameter from session (not `@Query`)
- Session ends with SessionSummaryView showing: items reviewed, correct/incorrect counts, next review estimate
- Each card interaction immediately updates Word's SR fields and persists (AC-6: partial progress saved if exited early)
- ContentView restructured to 3 tabs: Study (SessionStartView), Words (WordListView), Stats (StatsView)
- Word-of-the-day integrated into Study tab idle state or Words tab
- App builds without errors

---

### `lt-spaced-rep-per-lang`
**Status**: `[ ]`
**Risk**: `medium`
**Complexity**: `intermediate`
**Description**: Integrate spaced repetition into the session flow with per-language word selection. SR state is inherently per-language because `language` and SR fields are both on the `Word` model — this task wires SR into session word selection and ensures cross-language independence.
**Depends on**: `spaced-rep`, `language-field`
**Files to touch**: `Vocab/Vocab/Services/SessionService.swift`, `Vocab/Vocab/Services/SpacedRepetitionService.swift`
**Acceptance criteria**:
- `SessionService.startSession(language:context:)` partitions words into overdue (`nextReview < now`) and new (`nextReview == nil`) for the selected language only
- Overdue words sorted by `nextReview` ascending (most overdue first)
- Session fills with up to `maxOverdue` (10) overdue words + up to `maxNew` (5) new words, total ≤ `maxSessionSize` (15)
- Skipping a language for days/weeks does not reset SR intervals — overdue words simply accumulate and are capped per session
- If no overdue and no new words remain for a language, session returns empty (triggers "all caught up" state)
- Constants (`maxOverdue`, `maxNew`, `maxSessionSize`) are configurable for tuning
- App builds without errors

---

### `lt-quiz-modes`
**Status**: `[ ]`
**Risk**: `medium`
**Complexity**: `intermediate`
**Description**: Refactor quiz to support 4 modes via a new `QuizService`: EN term→definition, EN definition→term, LT term→EN translation, EN translation→LT term. Quiz mode auto-selected based on session language.
**Depends on**: `language-field`, `lt-vocab-initial`
**Files to touch**: new `Vocab/Vocab/Services/QuizService.swift`, `Vocab/Vocab/Views/QuizView.swift`
**Acceptance criteria**:
- `QuizMode` enum with cases: `termToDefinition`, `definitionToTerm`, `termToTranslation`, `translationToTerm`
- `QuizService.generateQuestion(for:mode:allWords:)` returns a `QuizQuestion` (prompt, correctAnswer, 4 options, source word)
- Distractors drawn from same-language words using the same field as the correct answer
- EN sessions alternate between `termToDefinition` and `definitionToTerm`
- LT sessions alternate between `termToTranslation` and `translationToTerm`
- QuizView updated to accept quiz mode and render questions accordingly
- Minimum 4 words in the session's language required to generate a quiz question
- App builds without errors

---

### `lt-stats-per-lang`
**Status**: `[done]`
**Risk**: `low`
**Complexity**: `low`
**Description**: Add per-language stats breakdown to StatsView and per-language field to QuizResult. All overview cards, mastery breakdown, and quiz history should be filterable by language.
**Depends on**: `language-field`
**Files to touch**: `Vocab/Vocab/Views/StatsView.swift`, `Vocab/Vocab/Models/QuizResult.swift`
**Acceptance criteria**:
- `QuizResult` model has `language: String` field (default `"en"`)
- StatsView has a language picker segment (All / English / Lithuanian)
- Overview cards (Total Words, Mastered, Quizzes Taken, Avg Score) filter by selected language
- Mastery breakdown (Mastered/Familiar/Learning/New) filters by selected language
- Quiz history chart and list filter by selected language
- Existing QuizResult records default to `"en"` via SwiftData lightweight migration
- App builds without errors

---

### `lt-session-timer`
**Status**: `[ ]`
**Risk**: `medium`
**Complexity**: `low`
**Description**: Implement session sizing logic within `SessionService` — cap sessions at 10–15 items with overdue-word prioritization and 5-minute target. This task adds the word-selection algorithm to `SessionService` (created in `lt-session-flow`).
**Depends on**: `lt-spaced-rep-per-lang`, `lt-session-flow`
**Files to touch**: `Vocab/Vocab/Services/SessionService.swift`
**Acceptance criteria**:
- `SessionService.buildSession(language:context:)` returns `[Word]` of 10–15 items max
- Algorithm: fetch all words for language → partition into overdue/new/upcoming → take up to 10 most-overdue + fill remaining with new words → shuffle
- Configurable constants: `maxOverdue = 10`, `maxNew = 5`, `maxSessionSize = 15`
- Returns empty array when no overdue and no new words (triggers "all caught up")
- New users (zero history): all words are "new"; session draws up to `maxSessionSize` from word pool
- App builds without errors

---

### `lt-empty-states`
**Status**: `[ ]`
**Risk**: `low`
**Complexity**: `low`
**Description**: Handle all empty/edge states per requirements: no words loaded for a language, no overdue words, all caught up, first-time user guidance, and Lithuanian TTS unavailability.
**Depends on**: `lt-session-flow`
**Files to touch**: `Vocab/Vocab/Views/SessionStartView.swift`, `Vocab/Vocab/Views/SessionSummaryView.swift`, `Vocab/Vocab/Views/StatsView.swift`, `Vocab/Vocab/Views/WordListView.swift`
**Acceptance criteria**:
- Language option disabled with message ("No words available for [Language] yet") if `words.json` or `words_lt.json` missing/empty
- "You're all caught up! 🎉" message when no overdue words and no new words remain for selected language
- First-time user (no sessions ever) sees guidance to pick a language and start their first session
- LT TTS button hidden if `AVSpeechSynthesisVoice(language: "lt-LT")` returns nil (no crash)
- StatsView shows "No stats yet" for a language with zero quiz results
- App builds without errors
