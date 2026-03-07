# VocabSeedBuilder

A Swift Package Manager command-line tool that reads the production JSON word files and pre-builds a SwiftData SQLite store for the Vocab iOS app.

## Requirements

- macOS 15+ (for SwiftData support)
- Xcode installed (SwiftData macros require the full Xcode toolchain)

## Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift build --package-path tools/VocabSeedBuilder
```

## Usage

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift run --package-path tools/VocabSeedBuilder VocabSeedBuilder \
    --en Vocab/Vocab/Resources/words.json \
    --lt Vocab/Vocab/Resources/words_lt.json \
    --output Vocab/Vocab/Resources/vocab_seed.store
```

## What it does

1. Reads both EN and LT JSON word files
2. Creates a SwiftData `ModelContainer` with `Word` and `QuizResult` schemas
3. Inserts all words using the same mapping logic as `WordService.loadWords`
4. Prints stats (count by language, nouns with gender, words with cases, file size)

## Notes

- Relationship properties (`antonyms`, `relatedWords`) are left as empty arrays in the seed store
- All spaced repetition fields use defaults (easeFactor: 2.5, interval: 0, repetitions: 0)
- The `@Attribute(.unique) uniqueKey` is set as `"<language>:<term>"` for each word
- Plain `swift build` without `DEVELOPER_DIR` will fail because the Command Line Tools don't include SwiftData macros
