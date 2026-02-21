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

### `words.json` (English)

```json
[
  {
    "term": "ubiquitous",
    "definition": "Present, appearing, or found everywhere",
    "synonyms": ["omnipresent", "pervasive"],
    "example": "Mobile phones have become ubiquitous.",
    "partOfSpeech": "adjective",
    "tags": ["academic"]
  }
]
```

### `words_lt.json` (Lithuanian)

```json
[
  {
    "term": "katė",
    "definition": "A small domesticated carnivorous mammal",
    "translation": "cat",
    "synonyms": [],
    "example": "Katė miega ant sofos.",
    "partOfSpeech": "noun",
    "tags": ["animals", "basic"]
  }
]
```

## What NOT to Change

- `VocabApp.swift` ModelContainer configuration — only touch if adding a new `@Model` type.
- `words.json` — owned by EN word extension agent.
- `words_lt.json` — owned by LT vocabulary agent.
- `DECISIONS.md` — append only, never rewrite existing entries.
