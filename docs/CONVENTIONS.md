# Conventions

## Swift / SwiftUI

- **No UIKit**. All UI is SwiftUI.
- **No external packages**. Use only Apple frameworks.
- Views are structs conforming to `View`. No classes for views.
- Use `@Query` in views to fetch SwiftData models directly — do not pass large arrays as parameters.
- Use `@Environment(\.modelContext)` for insert/delete in views.
- Business logic that is reusable goes in `Services/` as static methods or singletons.
- Keep views focused: if a view exceeds ~100 lines, extract subviews.

## Naming

| Thing | Convention | Example |
|-------|-----------|---------|
| SwiftData model | PascalCase, singular | `Word`, `QuizResult` |
| View file | `<Name>View.swift` | `FlashcardsView.swift` |
| Service file | `<Name>Service.swift` | `WordService.swift` |
| JSON resource | `words_<lang>.json` | `words_lt.json` |
| Feature branch | `feature/<task-id>` | `feature/spaced-rep` |

## SwiftData Patterns

```swift
// Fetching in a view
@Query(filter: #Predicate<Word> { $0.language == "en" }) var words: [Word]

// Inserting
context.insert(Word(...))

// Relationships — always use @Relationship with deleteRule
@Relationship(deleteRule: .nullify) var antonyms: [Word]
```

- Use `.nullify` delete rule for word-to-word relationships (deleting one word should not cascade-delete related words).
- Use `.cascade` only for child records that have no meaning without their parent (e.g., quiz sub-items).

## JSON Word Data

- All terms must be **unique** across their language file.
- `tags` must be lowercase strings, no spaces (use hyphens: `"word-family"`).
- `partOfSpeech` values: `"noun"`, `"verb"`, `"adjective"`, `"adverb"`, `"phrase"`, `"particle"`, `"interjection"`.
- EN words: `synonyms` should have 2–5 entries. Leave empty `[]` only if truly none.
- LT words: `synonyms` is typically `[]`. Always populate `translation` (EN gloss).
- Do not duplicate terms already in the file — check before adding.

## File Placement

- New views → `Views/`
- New models → `Models/`
- New services → `Services/`
- New JSON data → `Resources/`
- Do not create files at the `Vocab/Vocab/` root level.
