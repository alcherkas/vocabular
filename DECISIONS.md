# Vocab App - Technical Decisions

## Project Overview
A personal iOS vocabulary learning app focused on C1+ (advanced) English vocabulary. Built with SwiftUI and SwiftData for offline-first learning.

## Key Decisions

### 1. Technology Stack
| Component | Choice | Rationale |
|-----------|--------|-----------|
| UI Framework | **SwiftUI** | Modern, declarative, less boilerplate, native iOS feel |
| Database | **SwiftData** | Native SwiftUI integration, minimal code, automatic persistence |
| iOS Target | **iOS 26** | Latest features, personal use only |
| Architecture | **MVVM-lite** | Simple Views + Models, services for shared logic |

### 2. Data Storage
- **SwiftData** for persistent storage (words, quiz results, favorites)
- **Bundled JSON** for initial word list (offline-first, no network dependency)
- **No cloud sync** for MVP (personal use, single device)

### 3. Word Data
- **Source**: Curated C1+ vocabulary from CEFR framework
- **Count**: 500 words for MVP
- **Structure**: Term, definition, synonyms, example sentence, part of speech
- **Focus**: Academic/professional vocabulary (GRE, IELTS, TOEFL level)

### 4. Features (MVP)
| Feature | Priority | Status |
|---------|----------|--------|
| Word of the Day | P0 | ✅ Included |
| Flashcards | P0 | ✅ Included |
| Multiple Choice Quiz | P0 | ✅ Included |
| Word List Browser | P0 | ✅ Included |
| Progress Tracking | P0 | ✅ Included |
| Text-to-Speech | P0 | ✅ Included |
| Favorites | P1 | ✅ Included |
| Spaced Repetition | P2 | ❌ Post-MVP |
| AI Recommendations | P2 | ❌ Post-MVP |
| Widgets | P2 | ❌ Post-MVP |

### 5. Distribution
- **Method**: Direct from Xcode (free)
- **Limitation**: App expires every 7 days, requires re-deployment
- **Alternative**: Upgrade to Apple Developer Program ($99/year) for TestFlight

### 6. Design Principles
- **Offline-first**: All features work without internet
- **Minimal UI**: Clean, distraction-free learning experience
- **Progress visibility**: Track learning through quiz scores and mastery levels

## Project Structure
```
Vocab/
├── VocabApp.swift              # App entry point with SwiftData container
├── ContentView.swift           # Tab navigation
├── Models/
│   ├── Word.swift              # SwiftData model for vocabulary
│   └── QuizResult.swift        # SwiftData model for quiz history
├── Views/
│   ├── HomeView.swift          # Word of the day
│   ├── FlashcardsView.swift    # Swipeable flashcards
│   ├── QuizView.swift          # Multiple choice quiz
│   ├── WordListView.swift      # Browse/search all words
│   ├── WordDetailView.swift    # Single word detail
│   └── ProgressView.swift      # Stats and quiz history
├── Services/
│   ├── WordService.swift       # JSON loading, word management
│   └── SpeechService.swift     # AVSpeechSynthesizer wrapper
└── Resources/
    └── words.json              # 500 C1+ vocabulary words
```

## Setup Instructions

### Creating the Xcode Project
1. Open Xcode
2. File → New → Project
3. Select: iOS → App
4. Configure:
   - Product Name: `Vocab`
   - Organization Identifier: `com.yourname` (or your preference)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
5. Choose location: This repository folder
6. Create project

### Adding Source Files
1. In Xcode, right-click the `Vocab` folder → New Group → Name: `Models`
2. Repeat for: `Views`, `Services`, `Resources`
3. Drag and drop the `.swift` files into appropriate groups
4. Drag `words.json` into `Resources` group
   - ✅ Check "Copy items if needed"
   - ✅ Check "Add to target: Vocab"

### Running on Device
1. Connect iPhone via USB
2. Select your device in Xcode toolbar
3. Cmd+R to build and run
4. On iPhone: Settings → General → VPN & Device Management → Trust your Apple ID

## Future Enhancements (Post-MVP)
- [ ] Spaced repetition algorithm (SM-2)
- [ ] Widget for word of the day
- [ ] iCloud sync for multi-device
- [ ] Import custom word lists
- [ ] Dark mode theming options
- [ ] Haptic feedback on quiz answers

---
*Last updated: January 18, 2026*

## Retro — enricher-lt-12 (30 LT stubs)

**Date:** 2026-01-18
**Batch:** 30 entries enriched in a single pass.

### What was enriched
- **Numerals 0–10** (nulis → dešimt): all tagged A1/number, partOfSpeech `numeral`.
- **Core family vocabulary** (žmona, brolis, sesuo, pusseserė, vaikas, kūdikis, anūkas, anūkė, motina, mama, tėvas, tėtis, tėvai, sūnus, duktė, senelis, senelė): tagged A1/family (pusseserė, anūkas, anūkė at A2).
- **Time adverb** kasdien (A1) and **noun** savaitgalis (A1).

### Decisions
- Used `numeral` partOfSpeech for all cardinal numbers (valid enum value).
- `mama`/`motina` and `tėtis`/`tėvas` pairs cross-reference each other in `synonyms`.
- Register `informal` applied to colloquial forms (mama, tėtis); `neutral` elsewhere.
- `Nulis` kept with original capitalisation from the stub to avoid term-key mismatch.

### Validator result
143 enriched entries — all passed ✓
