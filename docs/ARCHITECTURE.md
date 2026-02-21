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
├── VocabApp.swift          # App entry point, SwiftData ModelContainer setup
├── ContentView.swift       # Tab bar navigation (4 tabs)
├── Models/
│   ├── Word.swift          # @Model: vocabulary entry (EN + LT)
│   └── QuizResult.swift    # @Model: quiz session result
├── Views/
│   ├── HomeView.swift      # Word of the Day
│   ├── FlashcardsView.swift# Swipeable flashcard deck
│   ├── QuizView.swift      # Multiple-choice quiz
│   ├── WordListView.swift  # Searchable word browser
│   ├── WordDetailView.swift# Single word detail + TTS
│   └── StatsView.swift     # Progress / quiz history
├── Services/
│   ├── WordService.swift   # JSON loading → SwiftData, word queries
│   └── SpeechService.swift # AVSpeechSynthesizer wrapper (singleton)
└── Resources/
    ├── words.json          # English C1+ vocabulary (500 words, growing)
    └── words_lt.json       # Lithuanian basic vocabulary (A1/A2) [to be created]
```

## Data Model

### Word (`Models/Word.swift`)

```swift
@Model class Word {
    @Attribute(.unique) var term: String
    var definition: String
    var synonyms: [String]          // flat list of synonym strings
    var example: String
    var partOfSpeech: String
    var tags: [String]
    var isFavorite: Bool
    var timesCorrect: Int
    var timesSeen: Int
    var lastSeen: Date?

    // Language support
    var language: String            // "en" | "lt"
    var translation: String?        // LT→EN gloss (nil for EN words)

    // Word relations (SwiftData @Relationship — no graph DB needed)
    @Relationship(deleteRule: .nullify) var antonyms: [Word]
    @Relationship(deleteRule: .nullify) var relatedWords: [Word]
}
```

> **Note**: `antonyms` and `relatedWords` are planned additions (see `docs/TASKS.md` task `word-relations`). Current model has `synonyms: [String]` only.

### QuizResult (`Models/QuizResult.swift`)

Stores per-session quiz outcomes: score, total, date, words attempted.

## Language Support

- All existing words are English (`language: "en"`).
- Lithuanian words use `language: "lt"` and populate `translation` with an EN gloss.
- LT words are A1/A2 level — simpler structure, `synonyms` array will typically be empty.
- UI filters by language where relevant (separate browse lists planned).

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


## What NOT to Change

- `VocabApp.swift` ModelContainer configuration — only touch if adding a new `@Model` type.
- `words.json` — owned by EN word extension agent.
- `words_lt.json` — owned by LT vocabulary agent.
- `DECISIONS.md` — append only, never rewrite existing entries.
