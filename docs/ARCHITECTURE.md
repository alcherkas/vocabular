# Architecture

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI (declarative, no UIKit) |
| Persistence | SwiftData (SQLite-backed, no CoreData boilerplate) |
| Speech | AVFoundation / AVSpeechSynthesizer |
| iOS Target | iOS 26 |
| Architecture | MVVM-lite: Views + `@Model` classes + stateless Services |

## Folder Structure

```
Vocab/Vocab/
├── VocabApp.swift              # App entry point, SwiftData ModelContainer setup
├── ContentView.swift           # Tab bar navigation (3 tabs: Study, Words, Stats)
├── Models/
│   ├── Word.swift              # @Model: vocabulary entry (EN + LT) with SR fields
│   └── QuizResult.swift        # @Model: quiz/session result with language
├── Views/
│   ├── SessionStartView.swift  # Session start screen with language picker + Word of the Day
│   ├── SessionSummaryView.swift# Post-session results display
│   ├── FlashcardsView.swift    # Swipeable flashcard deck (used in sessions)
│   ├── QuizView.swift          # Multiple-choice quiz with 4 modes
│   ├── CaseTrainingView.swift  # Text-input case declension training (LT only)
│   ├── WordListView.swift      # Searchable word browser with language filter
│   └── StatsView.swift         # Per-language progress, mastery, streaks, quiz history
├── Services/
│   ├── WordService.swift       # JSON loading → SwiftData, per-language word queries
│   ├── SessionService.swift    # @Observable session state machine (idle → active → complete)
│   ├── SpacedRepetitionService.swift # SM-2 algorithm for word scheduling
│   ├── QuizService.swift       # Quiz question generation (4 modes: term↔def, term↔translation)
│   ├── CaseMapping.swift       # GovernedCase → grammatical case + preposition mapping
│   ├── CaseTrainingService.swift # Case declension exercise generation
│   └── SpeechService.swift     # AVSpeechSynthesizer wrapper (EN + LT)
└── Resources/
    ├── words.json              # English C1+ vocabulary (production)
    ├── words_lt.json           # Lithuanian A1/A2 vocabulary (production)
    ├── words_staging.json      # EN vocab pipeline staging
    └── words_lt_staging.json   # LT vocab pipeline staging
```

## Data Model

### Word (`Models/Word.swift`)

```swift
@Model class Word {
    var term: String
    var meaningsData: Data           // JSON-encoded [WordMeaning]
    var synonyms: [String]
    var partOfSpeech: String
    var tags: [String]
    var isFavorite: Bool
    var timesCorrect: Int
    var timesSeen: Int
    var lastSeen: Date?

    // Language support
    var language: String             // "en" | "lt"
    var translation: String?         // LT→EN gloss (nil for EN words)
    @Attribute(.unique) var uniqueKey: String  // "language:term"

    // Word relations
    @Relationship(deleteRule: .nullify) var antonyms: [Word]
    @Relationship(deleteRule: .nullify) var relatedWords: [Word]

    // Spaced repetition (SM-2)
    var nextReview: Date?
    var easeFactor: Double = 2.5
    var interval: Int = 0
    var repetitions: Int = 0

    // Verb grammar (LT)
    var formsData: Data               // JSON-encoded WordForms? (present3, past3)
    var governedCase: String?          // e.g. "ką?", "ko?", "kur?"

    // Noun/adjective grammar (LT)
    var gender: String?                // "masculine" | "feminine" (nouns only)
    var casesData: Data                // JSON-encoded WordCases? (declension forms)

    // Computed
    var meanings: [WordMeaning]      // decoded from meaningsData
    var definition: String           // shortcut to meanings[0].definition
    var example: String              // shortcut to meanings[0].example
    var masteryLevel: Double         // timesCorrect / timesSeen
    var masteryDescription: String   // "Mastered" / "Familiar" / "Learning" / "New"
    var forms: WordForms?            // decoded from formsData (LT verbs)
    var cases: WordCases?            // decoded from casesData (LT nouns/adjectives)
}
```

### QuizResult (`Models/QuizResult.swift`)

```swift
@Model class QuizResult {
    var date: Date
    var score: Int
    var totalQuestions: Int
    var language: String = "en"      // "en" | "lt"
}
```

Stores per-session outcomes for both quiz and flashcard study sessions.

## Language Support

- All existing words are English (`language: "en"`).
- Lithuanian words use `language: "lt"` and populate `translation` with an EN gloss.
- LT words are A1/A2 level — simpler structure, `synonyms` array will typically be empty.
- UI filters by language where relevant (word list, stats, quiz, session start).

## JSON Schema

### Production files (`words.json`, `words_lt.json`)

Current state: the app loader accepts both legacy flat fields (`definition`, `example`, `tags`, `register`) and `meanings[]` for backward compatibility.
Target/write state: all new staging and production entries should use `meanings[]` as the canonical schema.

Words in production use a `meanings` array to capture multiple senses of a word:

```json
[
  {
    "term": "ephemeral",
    "language": "en",
    "partOfSpeech": "adjective",
    "meanings": [
      {
        "definition": "Lasting for a very short time",
        "example": "The ephemeral beauty of cherry blossoms makes them precious.",
        "register": "general",
        "tags": ["time", "academic"]
      },
      {
        "definition": "Existing only briefly; used in computing for short-lived resources",
        "example": "Ephemeral containers are destroyed after each use.",
        "register": "technical",
        "tags": ["technology", "computing"]
      }
    ],
    "synonyms": ["transient", "fleeting", "momentary"],
    "antonymTerms": ["permanent", "enduring", "perpetual"],
    "relatedTerms": ["transience", "impermanence"]
  }
]
```

**Field rules:**
- `meanings`: array, minimum 1 entry. Add all genuinely distinct senses.
- `meanings[].register`: one of `"general"` | `"technical"` | `"formal"` | `"literary"`
- `meanings[].tags`: lowercase, hyphen-separated (e.g. `"word-family"`)
- `partOfSpeech`: one of `"noun"` | `"verb"` | `"adjective"` | `"adverb"` | `"phrase"` | `"particle"` | `"interjection"`
- `synonyms`: 2–5 entries for EN; typically `[]` for LT
- `antonymTerms`, `relatedTerms`: string arrays, may be `[]`
- `language`: `"en"` or `"lt"`

### Lithuanian additions

LT words add a `translation` field (EN gloss) and typically have 1 meaning:

```json
{
  "term": "katė",
  "language": "lt",
  "partOfSpeech": "noun",
  "translation": "cat",
  "meanings": [
    {
      "definition": "A small domesticated carnivorous mammal kept as a pet",
      "example": "Katė miega ant sofos.",
      "register": "general",
      "tags": ["animals", "basic"]
    }
  ],
  "synonyms": [],
  "antonymTerms": [],
  "relatedTerms": ["šuo", "gyvūnas"]
}
```

### Lithuanian verb forms

LT verbs include the 3 principal forms and governed grammatical case:

```json
{
  "term": "valgyti",
  "language": "lt",
  "partOfSpeech": "verb",
  "translation": "to eat",
  "forms": {
    "present3": "valgo",
    "past3": "valgė"
  },
  "governedCase": "ką?",
  ...
}
```

- `forms`: optional object with `present3` (3rd person present) and `past3` (3rd person past). The infinitive is the `term` itself.
- `governedCase`: optional string — the grammatical question the verb requires (e.g., `"ką?"` accusative, `"ko?"` genitive, `"kur?"` locative, `"kam?"` dative, `"kuo?"` instrumental, `"su kuo?"` with whom). Null for intransitive/impersonal verbs.

### Staging files (`words_staging.json`, `words_lt_staging.json`)

Staging files live in `Resources/` and track curation progress via a `status` field:

```json
{
  "term": "ephemeral",
  "language": "en",
  "partOfSpeech": "adjective",
  "status": "stub",
  "meanings": [],
  "synonyms": [],
  "antonymTerms": [],
  "relatedTerms": [],
  "translation": null
}
```

**Status values** (pipeline stages):
| Status | Set by | Fields populated |
|--------|--------|-----------------|
| `stub` | Seeder agent | `term`, `language`, `partOfSpeech` |
| `enriched` | Enricher agent | + `meanings` (all senses) |
| `relations-added` | Relations agent | + `synonyms`, `antonymTerms`, `relatedTerms` |
| `approved` | QA agent | All fields verified |
| *(removed)* | Publisher script | Moved to `words.json`, deleted from staging |

## Lithuanian Grammar Data

### Noun gender

LT nouns include a `gender` field (`"masculine"` or `"feminine"`), inferred from word endings and declension class.

### Case declension forms

LT nouns and adjectives may include a `cases` field with declined forms for all 7 Lithuanian grammatical cases (nominative, genitive, dative, accusative, instrumental, locative, vocative) in both singular and plural.

```json
{
  "term": "brolis",
  "gender": "masculine",
  "cases": {
    "masculine": {
      "singular": { "nominative": "brolis", "genitive": "brolio", "dative": "broliui", "accusative": "brolį", "instrumental": "broliu", "locative": "brolyje", "vocative": "broli" },
      "plural": { "nominative": "broliai", "genitive": "brolių", "dative": "broliams", "accusative": "brolius", "instrumental": "broliais", "locative": "broliuose", "vocative": "broliai" }
    }
  }
}
```

- **Nouns**: only the matching gender key is populated (masculine or feminine)
- **Adjectives**: both `masculine` and `feminine` keys are populated
- `vocative` is optional; all other case values are required

### Verb governed cases

LT verbs include `forms` (3rd person present/past) and `governedCase` — the grammatical question the verb governs (e.g., `"ką?"` for accusative). The `CaseMapping` service maps all 14 governed case strings to their grammatical case and optional preposition.

## Data Loading (planned migration)

**Current flow**: JSON files → parsed on first launch → inserted into SwiftData.

**Planned flow**: JSON files → `build_seed_db.swift` → pre-seeded SwiftData SQLite store → copied on first launch (no parsing needed). The JSON pipeline (Seeder → Enricher → Relations → QA → Publisher) remains unchanged — SQLite is only the app delivery format.


## What NOT to Change

- `VocabApp.swift` ModelContainer configuration — only touch if adding a new `@Model` type.
- `words.json` — owned by EN word extension agent.
- `words_lt.json` — owned by LT vocabulary agent.
- `DECISIONS.md` — append only, never rewrite existing entries.
