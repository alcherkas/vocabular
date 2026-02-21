# Requirements: lt-vocab-app

## Goal
Build a dual-language vocabulary learning app (extend EN vocab + learn LT from scratch) designed for short 5-minute micro-sessions throughout the day.

## User Stories

### US-1: Language Selection at Session Start
As a user, I want to choose which language (English or Lithuanian) to study when I start a session, so that I can focus on one language at a time.

### US-2: English Vocabulary Expansion
As an advanced English speaker, I want to study rare/C1+ English words through flashcards and quizzes, so that I can expand my existing vocabulary beyond everyday usage.

### US-3: Lithuanian from Scratch
As a Lithuanian beginner, I want to learn basic A1/A2 Lithuanian vocabulary with English translations, so that I can build foundational knowledge of the language.

### US-4: Five-Minute Micro-Sessions
As a busy user, I want each study session to be completable in roughly 5 minutes, so that I can fit vocabulary practice into short breaks throughout the day.

### US-5: Per-Language Spaced Repetition
As a user, I want words to be scheduled for review independently per language using spaced repetition, so that skipping one language for a day doesn't disrupt my progress in the other.

### US-6: Per-Language Progress Tracking
As a user, I want to see my progress (words learned, review stats, streak) tracked separately for English and Lithuanian, so that I can monitor my improvement in each language independently.

### US-7: Quick Session Flow
As a user, I want a streamlined flow — launch → pick language → study/quiz → done — so that I spend my time learning, not navigating.

### US-8: Uneven Practice Tolerance
As a user, I want the app to handle uneven practice patterns (e.g., 3 EN sessions, 1 LT session per day) without penalizing me or degrading the spaced repetition schedule for the less-practiced language.

## Acceptance Criteria

### Language Selection
- [ ] AC-1: App presents a language picker (EN / LT) immediately after launch or on the session start screen.
- [ ] AC-2: Selected language filters all content for that session — flashcards, quiz questions, and word-of-the-day are from the chosen language only.
- [ ] AC-3: Language selection persists as a preference for "last used" but can be changed at any session start.

### Session Structure
- [ ] AC-4: A session presents a fixed number of words (flashcards or quiz items) calibrated to take ~5 minutes (target: 10–15 items per session).
- [ ] AC-5: Session ends with a brief summary showing items reviewed, correct/incorrect counts, and next review estimate.
- [ ] AC-6: User can exit a session early; partial progress is saved (words already reviewed are recorded).

### Spaced Repetition (Per-Language)
- [ ] AC-7: Each word has its own spaced repetition state (next review date, ease factor) independent of other words and other languages.
- [ ] AC-8: Session word selection prioritizes overdue words first, then introduces new words to fill the session.
- [ ] AC-9: Skipping a language for one or more days does not reset or penalize spaced repetition intervals — overdue words simply appear at the next session.

### English Content (C1+)
- [ ] AC-10: English word pool contains C1+ vocabulary loaded from `words.json`.
- [ ] AC-11: English flashcards show: term, definition, example sentence, synonyms, and part of speech.
- [ ] AC-12: English quiz questions test definition recall (term → pick correct definition) or reverse (definition → pick correct term).

### Lithuanian Content (A1/A2)
- [ ] AC-13: Lithuanian word pool contains A1/A2 vocabulary loaded from `words_lt.json`.
- [ ] AC-14: Lithuanian flashcards show: Lithuanian term, English translation, definition, and example sentence (in Lithuanian).
- [ ] AC-15: Lithuanian quiz questions test translation recall (LT term → pick correct EN translation) and reverse (EN translation → pick correct LT term).

### Progress Tracking
- [ ] AC-16: Stats screen shows per-language breakdown: words seen, words mastered (passed N reviews), accuracy rate.
- [ ] AC-17: Quiz results are stored per-language in `QuizResult` with a language field.
- [ ] AC-18: Home screen shows language-specific word-of-the-day (one for each language, or for the last-used language).

### Navigation & UX
- [ ] AC-19: Tab bar or main navigation provides quick access to: Session Start, Word List, Stats.
- [ ] AC-20: Word list is filterable by language (EN / LT / All).
- [ ] AC-21: Entire UI is SwiftUI with no UIKit dependencies.

## Edge Cases & Constraints

### Empty States
- **No words loaded**: If `words.json` or `words_lt.json` is missing or empty, the language option is disabled with a message ("No words available for [Language] yet").
- **No overdue words**: If all words for a language are up-to-date, session shows new words only. If no new words remain either, show a "You're all caught up!" message.
- **First session ever**: Guide user to pick a language; no prior stats to show.

### Partial Sessions
- **App killed mid-session**: Words already reviewed in the session must be persisted immediately (not batched at session end).
- **Session interrupted by phone call**: Resuming the app returns to the same session in progress.

### Spaced Repetition Edge Cases
- **Long absence (days/weeks)**: Overdue words accumulate but do not all flood a single session. Cap overdue words per session (e.g., max 10 overdue + 5 new) to keep sessions at ~5 minutes.
- **All words overdue**: Prioritize most-overdue words first (longest time past due date).
- **New user with zero history**: All words are "new"; session draws from the word pool in a sensible order (e.g., by tag grouping or alphabetical).

### Data Constraints
- **Offline-only**: No network requests. All word data is bundled in the app.
- **SwiftData persistence**: All models use SwiftData; no CoreData or raw SQLite.
- **iOS 26 minimum**: No backward compatibility required.

### Language-Specific
- **Lithuanian TTS**: AVSpeechSynthesizer supports Lithuanian (`lt-LT` locale). If unavailable on a device, degrade gracefully (hide TTS button, don't crash).
- **Lithuanian characters**: UI must correctly render Lithuanian diacritics (ą, č, ę, ė, į, š, ų, ū, ž).

## Out of Scope

- **User accounts or cloud sync** — app is single-user, local-only.
- **Custom word entry** — users cannot add their own words in v1; words come from bundled JSON only.
- **Gamification features** — no points, badges, leaderboards, or streaks beyond basic "days practiced" count.
- **Grammar lessons** — this is vocabulary-only; no grammar drills, sentence construction, or conjugation exercises.
- **Audio pronunciation from recordings** — TTS only via AVSpeechSynthesizer; no pre-recorded audio files.
- **More than two languages** — only EN and LT are supported; no framework for adding a third language.
- **Adaptive difficulty within a session** — word difficulty is managed by spaced repetition scheduling, not by real-time session adaptation.
- **WidgetKit integration** — covered by separate `widget` task, not part of this goal.
- **Apple Watch or macOS** — iOS only.

## Feature Breakdown

Tasks to create in TASKS.md:

- `lt-session-flow`: Implement session start screen with language picker and session orchestration (select language → load words → present flashcards/quiz → show summary). (files: new `Views/SessionStartView.swift`, new `Views/SessionSummaryView.swift`, `Services/WordService.swift`)
- `lt-spaced-rep-per-lang`: Extend spaced repetition to be per-language — each word tracks its own SR state; session word selection filters by language and prioritizes overdue words. (files: `Models/Word.swift`, `Services/SpacedRepetitionService.swift`, depends on: `spaced-rep`)
- `lt-quiz-modes`: Add Lithuanian-specific quiz modes (LT→EN translation, EN→LT translation) alongside existing EN definition-matching quiz. (files: `Views/QuizView.swift`, possibly new `Services/QuizService.swift`)
- `lt-stats-per-lang`: Add per-language stats breakdown to StatsView and per-language field to QuizResult. (files: `Views/StatsView.swift`, `Models/QuizResult.swift`)
- `lt-session-timer`: Implement session sizing logic — cap sessions at ~10–15 items with overdue-word prioritization and 5-minute target. (files: new `Services/SessionService.swift`)
- `lt-empty-states`: Handle all empty/edge states — no words loaded, no overdue words, all caught up, first-time user. (files: various Views)
