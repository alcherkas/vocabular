# Architecture: lt-vocab-app

## Summary

Extend the existing single-language English vocabulary app into a dual-language (EN + LT) learning tool built around 5-minute micro-sessions. This requires: adding `language` and spaced-repetition fields to the `Word` model, introducing a session orchestration layer (`SessionService`) that selects words per-language using SM-2 scheduling, restructuring navigation from 5 ad-hoc tabs to a 3-tab session-oriented flow (Study → Words → Stats), adding Lithuanian-specific quiz modes (translation matching), and making all stats/progress tracking language-aware. The existing flat JSON schema (`definition`/`example` at top level) is retained for now; migration to the `meanings` array is handled by the separate `word-meanings-model` task and is not a blocker for this goal.

---

## Data Model Changes

### Modified models

#### `Word.swift` — add language, translation, and spaced-repetition fields

```swift
@Model class Word {
    // --- Existing fields (unchanged) ---
    var term: String
    var definition: String
    var synonyms: [String]
    var example: String
    var partOfSpeech: String
    var tags: [String] = []
    var isFavorite: Bool = false
    var timesCorrect: Int = 0
    var timesSeen: Int = 0
    var lastSeen: Date?

    // --- New: language support (task: language-field) ---
    var language: String = "en"         // "en" | "lt"
    var translation: String?            // EN gloss for LT words; nil for EN words

    // --- New: compound unique key (task: language-field) ---
    @Attribute(.unique) var uniqueKey: String  // "en:ephemeral", "lt:katė"

    // --- New: spaced repetition (task: spaced-rep) ---
    var nextReview: Date?               // nil = never reviewed (treat as "new")
    var easeFactor: Double = 2.5        // SM-2 ease factor (default 2.5)
    var interval: Int = 0               // days until next review
    var repetitions: Int = 0            // consecutive correct answers

    // --- Computed (existing, unchanged) ---
    var masteryLevel: Double { ... }
    var masteryDescription: String { ... }
}
```

**Key changes:**
- Remove `@Attribute(.unique)` from `term`. Add `@Attribute(.unique)` to `uniqueKey` (composite `"language:term"`). This prevents collisions if the same term exists in both languages.
- Default `language` to `"en"` so existing EN words migrate without data loss (SwiftData lightweight migration adds the column with the default value).
- SR fields (`nextReview`, `easeFactor`, `interval`, `repetitions`) are per-word. Since `language` is per-word, SR is inherently per-language — no separate tracking table needed.
- `translation` is populated for LT words only (EN gloss, e.g., `"katė"` → `"cat"`).

#### `QuizResult.swift` — add language field

```swift
@Model class QuizResult {
    var date: Date
    var score: Int
    var totalQuestions: Int
    var language: String = "en"   // NEW: "en" | "lt"
    // ... existing computed properties unchanged
}
```

### New models

None. Session state is managed in-memory by `SessionService` (see below). Word-level progress is persisted immediately on each card interaction (AC: app killed mid-session → progress saved).

**Rationale for no `StudySession` model:** The session is a transient flow (select language → review N words → show summary). QuizResult already captures session outcomes. Word-level SR state (`nextReview`, `timesCorrect`, etc.) is updated on each interaction, satisfying the requirement for immediate persistence. Adding a `@Model StudySession` would add schema complexity with no data we need to query later.

---

## New Files

| File | Purpose |
|------|---------|
| `Services/SessionService.swift` | Session orchestration: word selection (overdue-first, then new), session sizing (10–15 items), session state machine (idle → active → complete) |
| `Services/SpacedRepetitionService.swift` | SM-2 algorithm: `nextReview(for:quality:)` → updates Word's SR fields |
| `Services/QuizService.swift` | Quiz question generation: produces question + options for all quiz modes (EN definition match, LT translation match) |
| `Views/SessionStartView.swift` | Language picker + "Start Session" button; shows last-used language as default |
| `Views/SessionSummaryView.swift` | End-of-session summary: items reviewed, correct/incorrect, next review estimate |

## Modified Files

| File | What changes |
|------|-------------|
| `Models/Word.swift` | Add `language`, `translation`, `uniqueKey`, SR fields (`nextReview`, `easeFactor`, `interval`, `repetitions`). Remove `@Attribute(.unique)` from `term`. |
| `Models/QuizResult.swift` | Add `language: String` field |
| `Services/WordService.swift` | Update `WordData` to include `language` and `translation`. Add `loadWords(for:from:into:)` method that loads a specific language file. Update dedup logic to use `uniqueKey`. |
| `Services/SpeechService.swift` | Add `language` parameter to `speak()` — use `"en-US"` for EN, `"lt-LT"` for LT. Graceful fallback if LT voice unavailable. |
| `ContentView.swift` | Restructure tabs: Study (SessionStartView), Words (WordListView), Stats (StatsView). Remove standalone Cards and Quiz tabs (they become part of session flow). Load both EN and LT words on appear. |
| `Views/FlashcardsView.swift` | Accept `[Word]` as input parameter (session words) instead of `@Query`. Show `translation` for LT words on card back. |
| `Views/QuizView.swift` | Accept `[Word]` and `QuizMode` from session. Support 4 quiz modes (EN term→def, EN def→term, LT term→translation, LT translation→term). Update scoring to use SR service. |
| `Views/WordListView.swift` | Add language filter segment (All / English / Lithuanian). Filter `@Query` predicate by `language`. |
| `Views/HomeView.swift` | Show language-specific word of the day (based on last-used language or both). |
| `Views/StatsView.swift` | Add per-language stats breakdown. Filter QuizResult and Word queries by language. |
| `VocabApp.swift` | No schema changes needed — SwiftData auto-discovers new fields via lightweight migration. |

---

## Implementation Notes

### Session Flow Architecture

The session follows a linear state machine managed by `SessionService`:

```
┌──────────┐    pick      ┌────────────┐   words    ┌────────────┐
│  IDLE    │──language──→ │  LOADING   │──ready──→ │  ACTIVE    │
│(picker)  │              │(fetch words)│           │(cards/quiz)│
└──────────┘              └────────────┘           └─────┬──────┘
                                                         │
                                            all done / exit early
                                                         │
                                                  ┌──────▼──────┐
                                                  │  COMPLETE   │
                                                  │ (summary)   │
                                                  └─────────────┘
```

**SessionService API sketch:**

```swift
@Observable
class SessionService {
    enum State { case idle, loading, active, complete }

    private(set) var state: State = .idle
    private(set) var sessionWords: [Word] = []
    private(set) var currentIndex: Int = 0
    private(set) var results: [(word: Word, correct: Bool)] = []
    var language: String = "en"

    func startSession(language: String, context: ModelContext) { ... }
    func recordAnswer(correct: Bool) { ... }
    func skipWord() { ... }
    func endSession() { ... }

    // Config
    static let maxOverdue = 10
    static let maxNew = 5
    static let maxSessionSize = 15
}
```

- `startSession` queries SwiftData for words where `word.language == language`, partitions into overdue (`nextReview < now`) and new (`nextReview == nil`), sorts overdue by most-overdue-first, picks up to `maxOverdue` overdue + fills remaining slots with new words up to `maxSessionSize`.
- `recordAnswer` immediately updates the Word's SR fields via `SpacedRepetitionService` and persists (satisfies AC-6: partial progress saved).
- `endSession` creates a `QuizResult` with the language field and transitions to `complete`.
- `@Observable` so SwiftUI views react to state changes (no Combine, no manual `objectWillChange`).

### Word Selection Algorithm

```
1. Fetch all words for selected language
2. Partition:
   - overdue = words where nextReview != nil AND nextReview < Date.now
   - new     = words where nextReview == nil (never reviewed)
   - upcoming = words where nextReview != nil AND nextReview >= Date.now
3. Sort overdue by nextReview ascending (most overdue first)
4. Session = overdue.prefix(maxOverdue) + new.prefix(maxSessionSize - overdueCount)
5. Shuffle the final session array (avoid predictable ordering)
6. If both overdue and new are empty → "All caught up!" state
```

This satisfies:
- AC-8: overdue words first, then new words
- AC-9: skipping a language doesn't reset intervals (overdue words just accumulate)
- Edge case: long absence → capped at 10 overdue per session
- Edge case: all caught up → empty session, show message

### Spaced Repetition (SM-2)

Use the standard SM-2 algorithm:

```swift
struct SpacedRepetitionService {
    /// quality: 0–5 (0–2 = incorrect/hard, 3 = correct/hard, 4 = correct, 5 = correct/easy)
    static func updateSchedule(for word: Word, quality: Int) {
        if quality >= 3 {
            // Correct answer
            switch word.repetitions {
            case 0: word.interval = 1
            case 1: word.interval = 6
            default: word.interval = Int(Double(word.interval) * word.easeFactor)
            }
            word.repetitions += 1
        } else {
            // Incorrect — reset
            word.repetitions = 0
            word.interval = 1
        }

        // Update ease factor (never below 1.3)
        let q = Double(quality)
        word.easeFactor = max(1.3, word.easeFactor + 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))

        // Set next review date
        word.nextReview = Calendar.current.date(byAdding: .day, value: word.interval, to: .now)
    }
}
```

**Mapping user actions to quality scores:**
- Flashcard "Know it" → quality 4
- Flashcard "Don't know" → quality 1
- Quiz correct answer → quality 4 (or 5 if answered quickly)
- Quiz wrong answer → quality 1

**Per-language behavior** (AC-7, AC-9, US-8):
- SR state is stored on the `Word` model, which has a `language` field
- Session queries filter by language, so EN and LT words are scheduled independently
- Skipping LT for a week means LT overdue words accumulate; they appear (capped) at the next LT session — no penalty, no reset

### Quiz Mode Architecture

```swift
enum QuizMode {
    case termToDefinition      // EN: "What does X mean?" → pick definition
    case definitionToTerm      // EN: "Which word means X?" → pick term
    case termToTranslation     // LT: "What does X mean in English?" → pick translation
    case translationToTerm     // LT: "How do you say X in Lithuanian?" → pick LT term
}

struct QuizQuestion {
    let prompt: String           // The question text
    let correctAnswer: String    // The correct option
    let options: [String]        // 4 options (1 correct + 3 distractors)
    let word: Word               // Reference to the word being tested
}
```

**QuizService** generates questions by:
1. Selecting the prompt field based on mode (e.g., `word.term` for termToDefinition)
2. Selecting the answer field (e.g., `word.definition` for termToDefinition)
3. Picking 3 distractors from other words of the same language (same field)
4. Shuffling options

**Auto-selection:** When a session starts, `QuizService` determines the mode based on language:
- EN → alternates between `termToDefinition` and `definitionToTerm`
- LT → alternates between `termToTranslation` and `translationToTerm`

### Navigation Restructure

**Current (5 tabs):**
```
Today | Cards | Quiz | Words | Progress
```

**Proposed (3 tabs):**
```
Study | Words | Stats
```

- **Study tab**: `SessionStartView` → language picker → session (flashcards + quiz interleaved) → `SessionSummaryView`. Also shows word-of-the-day when no active session.
- **Words tab**: `WordListView` with language filter (All / EN / LT). Links to `WordDetailView`.
- **Stats tab**: `StatsView` with per-language breakdown.

The standalone `FlashcardsView` and `QuizView` are repurposed as session subviews — they receive words from `SessionService` rather than querying all words via `@Query`.

### SpeechService Language Support

```swift
func speak(_ text: String, language: String = "en", rate: Float = 0.45) {
    let localeMap = ["en": "en-US", "lt": "lt-LT"]
    let locale = localeMap[language] ?? "en-US"

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: locale)
    // If LT voice unavailable, voice will be nil — AVSpeechSynthesizer
    // falls back to default. Views should hide TTS button if
    // AVSpeechSynthesisVoice(language: "lt-LT") == nil.
    ...
}
```

### Migration Strategy (Existing Data)

**SwiftData schema migration (automatic):**
- Adding `language: String = "en"` → SwiftData lightweight migration adds column with default. All 96 existing EN words get `language = "en"` automatically.
- Adding `translation: String? = nil` → nullable column, defaults to nil. Correct for EN words.
- Adding SR fields with defaults (`easeFactor = 2.5`, `interval = 0`, etc.) → lightweight migration, no data loss.
- Removing `@Attribute(.unique)` from `term` and adding `@Attribute(.unique)` on `uniqueKey` → requires `uniqueKey` to be populated on first load.

**WordService migration logic:**
```swift
static func migrateExistingWords(context: ModelContext) {
    let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.uniqueKey == "" })
    if let words = try? context.fetch(descriptor) {
        for word in words {
            word.uniqueKey = "\(word.language):\(word.term)"
        }
    }
}
```
Call this in `ContentView.onAppear` after `loadInitialWords`.

**JSON schema (no change for now):**
- `words.json` keeps its current flat schema (`definition`, `example` at top level). No `language` field needed in JSON — WordService sets `language = "en"` during import.
- `words_lt.json` (new file, created by `lt-vocab-initial` task) uses the same flat schema plus `translation` field. WordService sets `language = "lt"` during import.
- Migration to `meanings` array schema is handled by the separate `word-meanings-model` task.

**WordService loading update:**
```swift
static func loadWords(language: String, resourceName: String, into context: ModelContext) {
    // Check if words for this language already exist
    let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.language == language })
    let existingCount = (try? context.fetchCount(descriptor)) ?? 0
    guard existingCount == 0 else { return }

    guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else { return }
    let data = try Data(contentsOf: url)
    let wordData = try JSONDecoder().decode([WordData].self, from: data)

    for wd in wordData {
        let word = Word(...)
        word.language = language
        word.uniqueKey = "\(language):\(wd.term)"
        word.translation = wd.translation  // nil for EN
        context.insert(word)
    }
}
```

Called in `ContentView.onAppear`:
```swift
WordService.loadWords(language: "en", resourceName: "words", into: context)
WordService.loadWords(language: "lt", resourceName: "words_lt", into: context)
```

---

## Risks / Open Questions

### Risks

1. **SwiftData unique-key migration (medium risk):** Changing from `@Attribute(.unique)` on `term` to `@Attribute(.unique)` on `uniqueKey` may not be handled by SwiftData lightweight migration. If it fails, we may need to delete and recreate the local database on first launch after the update. **Mitigation:** Test on a device with existing data before release. Worst case: users lose quiz history (acceptable for a personal app).

2. **SM-2 tuning (low risk):** The 10-overdue + 5-new split and quality-score mapping are reasonable defaults but may feel too easy or too hard in practice. **Mitigation:** Make `maxOverdue`, `maxNew`, and `maxSessionSize` constants in `SessionService` for easy tuning.

3. **Lithuanian TTS availability (low risk):** `AVSpeechSynthesisVoice(language: "lt-LT")` may return nil on some devices. **Mitigation:** Check at runtime and hide the TTS button when unavailable (already documented in requirements).

4. **Navigation restructure (medium risk):** Collapsing 5 tabs to 3 changes the app's UX significantly. Users lose direct access to standalone flashcards and quiz. **Mitigation:** The session flow encompasses both flashcards and quiz, so no functionality is lost — just reorganized. The `WordDetailView` in the Words tab still shows per-word details.

5. **Session interruption handling (low risk):** Requirement says "resuming the app returns to the same session." Using `@Observable SessionService` in memory means if the app is terminated (not just backgrounded), the session is lost. But since SR updates happen immediately per-card, no learning progress is lost — only the session position. **Mitigation:** Acceptable trade-off. If needed later, persist session state to `UserDefaults`.

### Open Questions (non-blocking)

1. **Session mode mix:** Should sessions be pure flashcards, pure quiz, or a mix? Architecture assumes a configurable mix (e.g., 50% flashcard + 50% quiz) managed by `SessionService`. The exact ratio can be tuned during implementation.

2. **Word-of-the-day placement:** Currently in its own tab (HomeView). Proposed: integrate into `SessionStartView` as a "preview card" shown before starting a session. Alternative: keep as a section in the Words tab. Decision deferred to implementation.

3. **`word-meanings-model` sequencing:** The `word-meanings-model` task modifies `Word.swift` and all views. It should be done **either before or after** the lt-vocab-app tasks — not interleaved — to avoid merge conflicts. Recommended: complete `language-field` and `spaced-rep` first, then `word-meanings-model`, then the remaining lt-vocab-app tasks.

---

## Task Dependency Graph

```
                    ┌─────────────────┐
                    │  language-field  │ (foundation: add language + translation + uniqueKey)
                    └────────┬────────┘
           ┌─────────┬──────┼───────────┬──────────────┐
           │         │      │           │              │
           ▼         ▼      ▼           ▼              ▼
     lt-ui-filter  lt-stats  lt-session  lt-quiz-modes  word-of-day-lt
                  -per-lang   -flow     (also needs     (also needs
                              │         lt-vocab-initial) lt-vocab-initial)
                              │
                    ┌─────────┤
                    ▼         ▼
              lt-empty    lt-session-timer
              -states     (also needs lt-spaced-rep-per-lang)
                                    ▲
                    ┌───────────────┘
                    │
              ┌─────┴──────────────┐
              │lt-spaced-rep-per-lang│
              └─────┬──────────────┘
                    │
           ┌────────┴────────┐
           │                 │
     ┌─────▼──────┐   ┌─────▼──────┐
     │ spaced-rep │   │language-field│
     └────────────┘   └────────────┘

Independent:
  lt-vocab-initial (data: create words_lt.json — no code dependency)
  word-meanings-model (separate migration — do before or after, not during)
```

**Recommended implementation order:**
1. `language-field` — foundation (unblocks everything)
2. `spaced-rep` — can parallel with #1 on separate branch if SR fields added to Word in #1
3. `lt-vocab-initial` — data task, can run in parallel
4. `lt-spaced-rep-per-lang` — after #1 + #2
5. `lt-ui-filter` — after #1
6. `lt-session-flow` — after #1
7. `lt-session-timer` — after #4 + #6
8. `lt-quiz-modes` — after #1 + #3
9. `lt-stats-per-lang` — after #1
10. `lt-empty-states` — after #6
11. `word-of-day-lt` — after #1 + #3
12. `word-meanings-model` — after all above (or before all, but not interleaved)

---

## AC → Task Mapping

Every acceptance criterion from `docs/requirements/lt-vocab-app.md` must map to at least one task:

| AC | Task(s) |
|----|---------|
| AC-1 (language picker at launch) | `lt-session-flow` |
| AC-2 (language filters session content) | `lt-session-flow`, `lt-quiz-modes` |
| AC-3 (language preference persists) | `lt-session-flow` |
| AC-4 (10–15 items per session) | `lt-session-timer` |
| AC-5 (session summary) | `lt-session-flow` |
| AC-6 (exit early, partial save) | `lt-session-flow`, `spaced-rep` |
| AC-7 (per-word SR state) | `spaced-rep`, `lt-spaced-rep-per-lang` |
| AC-8 (overdue first, then new) | `lt-session-timer`, `lt-spaced-rep-per-lang` |
| AC-9 (skip language, no penalty) | `lt-spaced-rep-per-lang` |
| AC-10 (EN pool from words.json) | `language-field` (already works, just add language tag) |
| AC-11 (EN flashcard fields) | existing `FlashcardsView` (already shows these) |
| AC-12 (EN quiz modes) | `lt-quiz-modes` (refactors quiz to support both) |
| AC-13 (LT pool from words_lt.json) | `language-field`, `lt-vocab-initial` |
| AC-14 (LT flashcard fields) | `lt-session-flow` (FlashcardsView updated for LT) |
| AC-15 (LT quiz translation modes) | `lt-quiz-modes` |
| AC-16 (per-language stats) | `lt-stats-per-lang` |
| AC-17 (QuizResult language field) | `lt-stats-per-lang` |
| AC-18 (per-language word-of-day) | `word-of-day-lt` |
| AC-19 (tab bar: Session, Words, Stats) | `lt-session-flow` |
| AC-20 (word list language filter) | `lt-ui-filter` |
| AC-21 (SwiftUI only) | all tasks (convention enforced) |

All 21 ACs are covered.

---

## Task Updates

See updated task entries in `docs/TASKS.md`. Key additions per task:
- `language-field`: added SpeechService language support, uniqueKey migration, expanded ACs
- `spaced-rep`: added SM-2 quality mapping, session integration notes
- `lt-session-flow`: added SessionService architecture, state machine, navigation restructure
- `lt-spaced-rep-per-lang`: clarified that per-language is inherent from Word.language + SR fields
- `lt-session-timer`: added word selection algorithm, configurable constants
- `lt-quiz-modes`: added QuizService architecture, 4 quiz modes, auto-selection logic
- `lt-stats-per-lang`: added specific stat fields and filter UI
- `lt-empty-states`: added specific empty states and UX copy
