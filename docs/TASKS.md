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

---

## Vocabulary Pipeline Tasks

> These are **continuous-loop** tasks. See `docs/VOCAB-AGENT.md` for the full protocol.
> Vocab agents use branch prefix `vocab/` not `feature/`.

### `vocab-seeder-en`
**Status**: `[ ]`
**Risk**: `low`
**Role**: Seeder (English)
**Description**: Continuously add C1+ English word stubs to `words_staging.json`. Run the Seeder loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`
**Target**: 500+ stubs (current production: 96 words)

---

### `vocab-seeder-lt`
**Status**: `[ ]`
**Risk**: `low`
**Role**: Seeder (Lithuanian)
**Description**: Continuously add A1/A2 Lithuanian word stubs to `words_lt_staging.json`. Run the Seeder loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_lt_staging.json` (create if absent)
**Target**: 200 stubs

---

### `vocab-enricher-en`
**Status**: `[ ]`
**Risk**: `low`
**Role**: Enricher (English)
**Description**: Pick up `stub` entries in `words_staging.json` and add all meanings (definitions, examples, register, tags). Run the Enricher loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`

---

### `vocab-enricher-lt`
**Status**: `[ ]`
**Risk**: `low`
**Role**: Enricher (Lithuanian)
**Description**: Pick up `stub` entries in `words_lt_staging.json` and add meanings + translation. Run the Enricher loop.
**Files to touch**: `Vocab/Vocab/Resources/words_lt_staging.json`

---

### `vocab-relations`
**Status**: `[ ]`
**Risk**: `low`
**Role**: Relations
**Description**: Pick up `enriched` entries in staging files and add synonyms, antonyms, relatedTerms. Run the Relations loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`, `words_lt_staging.json`

---

### `vocab-qa`
**Status**: `[ ]`
**Risk**: `medium`
**Role**: QA Reviewer
**Description**: Review `relations-added` entries. Approve or send back for rework. Run the QA loop from `docs/VOCAB-AGENT.md`.
**Files to touch**: `Vocab/Vocab/Resources/words_staging.json`, `words_lt_staging.json`

---

### `word-meanings-model`
**Status**: `[ ]`
**Risk**: `high`
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
**Description**: Add `antonyms` and `relatedWords` as SwiftData `@Relationship` fields to `Word.swift`.
**Files to touch**: `Vocab/Vocab/Models/Word.swift`, `Vocab/Vocab/Services/WordService.swift` (update `WordData` struct + loader)
**Acceptance criteria**:
- `Word` model compiles with `@Relationship(deleteRule: .nullify) var antonyms: [Word]` and `relatedWords: [Word]`
- `WordData` codable struct supports optional `antonymTerms: [String]?` for JSON
- App builds without errors

---

### `language-field`
**Status**: `[ ]`
**Risk**: `medium`
**Description**: Add `language: String` and `translation: String?` fields to `Word.swift` and update `WordService` to support loading `words_lt.json`.
**Files to touch**: `Vocab/Vocab/Models/Word.swift`, `Vocab/Vocab/Services/WordService.swift`
**Acceptance criteria**:
- `Word` model has `language` (default `"en"`) and `translation` (optional)
- `WordService.loadInitialWords` accepts a language parameter and resource name
- Both `words.json` and `words_lt.json` can be loaded independently

---

## Data Population Tasks

### `en-words-expansion`
**Status**: `[ ]`
**Risk**: `low`
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
**Description**: Implement SM-2 spaced repetition algorithm for word scheduling.
**Files to touch**: `Vocab/Vocab/Models/Word.swift` (add `nextReview: Date?`, `easeFactor: Double`), new `Vocab/Vocab/Services/SpacedRepetitionService.swift`, `Vocab/Vocab/Views/FlashcardsView.swift` (surface due words first)
**Acceptance criteria**:
- `SpacedRepetitionService.nextReview(for: word, quality: Int) -> Date` computes next review date
- Flashcard deck shows overdue words first
- App builds and tests pass

---

### `lt-ui-filter`
**Status**: `[ ]`
**Risk**: `low`
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
**Description**: Extend `HomeView` to show a Lithuanian Word of the Day alongside the English one (or as a toggle).
**Depends on**: `language-field` and `lt-vocab-initial` must be done first.
**Files to touch**: `Vocab/Vocab/Views/HomeView.swift`
**Acceptance criteria**:
- LT word of the day shown with translation
- Falls back gracefully if no LT words loaded yet

---

### `haptics`
**Status**: `[ ]`
**Risk**: `low`
**Description**: Add haptic feedback on quiz correct/wrong answers.
**Files to touch**: `Vocab/Vocab/Views/QuizView.swift`
**Acceptance criteria**:
- `UIImpactFeedbackGenerator` on correct answer (`.success`)
- `UINotificationFeedbackGenerator` on wrong answer (`.error`)

---

### `widget`
**Status**: `[ ]`
**Risk**: `medium`
**Description**: Add a WidgetKit extension for Word of the Day home screen widget.
**Files to touch**: New `VocabWidget/` target (create in Xcode)
**Acceptance criteria**:
- Widget shows today's word + definition
- Updates daily via timeline
- Works on iOS 26 home screen

---

## Test Tasks

### `tests-wordservice`
**Status**: `[ ]`
**Risk**: `low`
**Description**: Add unit tests for `WordService` (requires `VocabTests` target — see `docs/BUILD.md`).
**Files to touch**: `Vocab/VocabTests/WordServiceTests.swift` (create)
**Acceptance criteria**:
- `test_loadInitialWords_emptyDatabase` — verifies words are inserted
- `test_loadInitialWords_alreadyLoaded` — verifies no duplicates on second load
- All tests pass with `xcodebuild test`
