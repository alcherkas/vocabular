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
---

## Retro — vocab/relations-7 (Relations Agent)

**Date:** 2025-07-17
**Branch:** vocab/relations-7

### What was done
- Preflighted both staging JSON files — both valid (330 EN, 1960 LT entries).
- Added `synonyms`, `antonymTerms`, `relatedTerms` to **35 enriched EN entries** in `words_staging.json` (economics, sociology, ecology, mathematics domains).
- Added `synonyms`, `antonymTerms`, `relatedTerms` to **35 enriched LT entries** in `words_lt_staging.json` (everyday vocabulary: people, occupations, verbs of motion/action).
- Set `status → relations-added` for all 70 processed entries.
- Remaining 10 enriched EN entries and 78 enriched LT entries left untouched (per 35-per-file cap).

### Validation
- `validate_words.py --status relations-added` passed for both files (70 entries each).

### Decisions
- EN entries: ensured ≥ 2 synonyms per validator rule; antonymTerms/relatedTerms populated from domain knowledge.
- LT entries: synonyms/antonymTerms/relatedTerms as arrays (empty where linguistically appropriate); gendered pairs cross-referenced in relatedTerms.
- No merges performed; branch left for PR review.

## Retro — vocab/enricher-lt-13 (LT Enricher)

**Date:** 2025-07-18
**Branch:** vocab/enricher-lt-13

### What was done
- Preflighted `words_lt_staging.json` — 1960 entries, all valid (1635 stubs at start).
- Enriched **30 Lithuanian stub entries** covering:
  - **Family nouns (6):** močiutė, prosenelis, prosenelė, dėdė, teta, pusbrolis
  - **Marital / state adjectives (6):** Vedęs, ištekėjusi, išsiskyręs, išsiskyrusi, miręs, mirusi
  - **Common verbs (12):** Galėti, mylėti, norėti, pasiilgti, sėdėti, stovėti, turėti, žiūrėti, girdėti, mėgti, susipažinti, žaisti
  - **Adjective pairs (6):** Jaunas/jauna, senas/sena, linksmas/linksma
- Each entry received: `partOfSpeech`, `translation`, `meanings` (definition + Lithuanian example sentence + register + tags), `synonyms`, `antonymTerms`, `relatedTerms`. Status set to `enriched`.

### Validation
- `validate_words.py --status enriched` passed — 139 enriched entries valid ✓
- `validate_words.py` (full file) passed — 1960 entries valid ✓

### Decisions
- Gendered adjective pairs (e.g. jaunas/jauna) each received their own entry with masculine/feminine note in definition and translation; cross-referenced via `relatedTerms`.
- Register set to `neutral` for family/state terms, `general` for verbs and descriptive adjectives, `formal` for death-related adjectives (miręs/mirusi).
- Empty `synonyms`/`antonymTerms` arrays retained as `[]` where linguistically appropriate (validator allows this for LT).
- No merges performed; branch left for PR review.

---

## Session retro — vocab/seeder-en-4 · 100 C1/C2 EN stubs

**Branch:** vocab/seeder-en-4

### What was done
- Preflighted `words.json` + `words_staging.json` — 330 existing EN terms catalogued.
- Added **100 new C1/C2 English stub entries** across 12 specialist domains:
  - **Theology (9):** apophatic, eschatology, soteriology, pneumatology, theophany, kenosis, ecclesiology, theodicy, catechesis
  - **Heraldry (9):** blazon, escutcheon, tincture, passant, rampant, chevron, dexter, sinister, quarterings
  - **Numismatics (8):** obverse, exergue, planchet, mintmark, reeding, bullion, assay, numismatist
  - **Paleontology (8):** taphonomy, biostratigraphy, palynology, paleoecology, permineralization, morphotaxonomy, phylogeny, stratigraphy
  - **Volcanology (8):** pyroclastic, lahar, fumarole, caldera, tephra, solfatara, phreatomagmatic, lapilli
  - **Glaciology (9):** ablation, firn, moraine, cirque, drumlin, esker, periglacial, subglacial, nunatak
  - **Seismology (8):** hypocenter, liquefaction, isoseismal, microseism, seismicity, aftershock, attenuation, seismograph
  - **Epidemiology (8):** incidence, seroprevalence, morbidity, zoonosis, serology, pathogenesis, virulence, etiological
  - **Pharmacology (9):** pharmacokinetics, pharmacodynamics, bioavailability, agonist, antagonist, teratogen, excipient, prodrug, bioequivalence
  - **Oncology (9):** metastasis, angiogenesis, carcinogenesis, cytotoxic, neoplasm, adenocarcinoma, lymphoma, sarcoma, malignancy
  - **Cardiology (8):** arrhythmia, bradycardia, stenosis, ischemia, fibrillation, cardiomyopathy, atherosclerosis, endocarditis
  - **Dermatology (7):** erythema, psoriasis, desquamation, urticaria, seborrheic, hyperpigmentation, pruritus

### Validation
- Zero conflicts against all existing EN terms (330 pre-existing → 430 total, all unique) ✓
- 100 stubs appended to `words_staging.json`; total staging size 430 entries ✓

### Decisions
- Stub format `{"term":"…","status":"stub","language":"en","partOfSpeech":"","tags":[]}` used verbatim per spec.
- Domain spread (9–7 terms per category) chosen to reach exactly 100 while avoiding known existing terms (e.g. `cladistics`, `tachycardia`, `contraindication`, `comorbidity`, `iatrogenic`, `nosocomial` already present).
- No merges performed; branch left for PR review.

---

## Retro — vocab/enricher-lt-16 (35 LT stubs)

**Date:** 2026-01-18
**Branch:** vocab/enricher-lt-16

### What was enriched
- **Adjective pairs (6):** didelis/didelė (big), vidutinis/vidutinė (medium/average), mažas/maža (small) — tagged A1/size.
- **Demonstrative pronouns (8):** Šis/ši (this m./f. sg.), šie/šios (these m./f. pl.), tas/ta (that m./f. sg.), tie/tos (those m./f. pl.) — tagged A1/demonstrative.
- **Possessive pronouns (2):** mūsų (our), jų (their) — tagged A1/possessive.
- **Interrogative pronouns (2):** kokie/kokios (what kind of, m./f. pl.) — tagged A2/interrogative.
- **Adverb (1):** kiek (how much/how many) — tagged A1/quantity.
- **Numerals accusative forms (16):** viena/vieną (one f./acc.), dvi (two f.), tris (three acc.), keturios/keturis (four f./m. acc.), penkios/penkis (five f./m. acc.), šešios/šešis (six f./m. acc.), septynios/septynis (seven f./m. acc.), aštuonios/aštuonis (eight f./m. acc.), devynios/devynis (nine f./m. acc.) — all tagged A1/cardinal/accusative.

### Decisions
- Register `neutral` used throughout; all terms are common everyday vocabulary.
- Gendered adjective pairs cross-referenced in `antonymTerms` (size opposites) and `relatedTerms`.
- Demonstrative pronouns cross-reference their near/far counterparts in `antonymTerms` and full paradigm in `relatedTerms`.
- Numeral accusative forms (keturios, penkios, etc.) treated as `numeral` partOfSpeech; translations note case and gender explicitly.
- `synonyms`/`antonymTerms` kept `[]` where linguistically no clean equivalent exists (pronouns, numerals).

### Validator result
144 enriched entries — all passed ✓ | 1960 total entries — all passed ✓

---

## Retro — vocab/enricher-lt-18 (35 LT stubs)

**Date:** 2026-01-18
**Branch:** vocab/enricher-lt-18

### What was enriched
- **Everyday nouns (10):** Vanduo (water), arbata (tea), duona (bread), kiaušinis (egg), druska (salt), cukrus (sugar), ryžiai (rice), mėnuo (month), metai (year), laikas (time) — all A1, tagged `food`/`drink`/`time`/`calendar`.
- **Common verbs (13):** pirkti (to buy), parduoti (to sell), Kainuoti (to cost), grįžti (to return), sustoti (to stop), nešti (to carry), sumokėti (to pay), atidaryti (to open), uždaryti (to close), sirgti (to be ill), dainuoti (to sing), vairuoti (to drive), Tikrinti (to check) — A1/A2, tagged `shopping`/`movement`/`action`/`health`/`transport`.
- **Basic adjectives (6):** karštas (hot), tuščias (empty), sunkus (heavy/difficult), Švarus (clean), tvarkingas (tidy), Platus (wide) — A1/A2; `sunkus` received two meanings (weight + difficulty).
- **Food/kitchen nouns (3):** aliejus (oil), makaronai (pasta), pipirai (pepper/peppers) — A1, tagged `food`/`cooking`/`spice`.
- **Discourse adverb (1):** po to (after that/then) — A1 temporal connector, tagged `time`/`discourse`/`connector`.
- **Infrastructure nouns (2):** kelias (road/way), namas (house/home) — A1, tagged `transport`/`direction`/`home`.

### Decisions
- Register `neutral` used throughout; all entries are core everyday vocabulary with no register variation.
- `sunkus` given two meanings (physical heaviness + difficulty) to capture the full A1/A2 range; both share `neutral` register.
- `po to` classified as `adverb` (temporal connective function); `synonyms` include `paskui` and `vėliau`, `antonymTerms` includes `prieš tai`.
- Capitalised stub terms (Vanduo, Kainuoti, Tikrinti, Švarus, Platus) matched by exact term key to preserve original casing.
- `synonyms`/`antonymTerms` left `[]` where no clean equivalent exists (most food nouns, time nouns, neutral verbs).
- No merges performed; branch left for PR review.

### Validator result
125 enriched entries — all passed ✓ | 1960 total entries — all passed ✓

---

## Retro — seeder-en-5 · 100 English C1+ stubs ($(date -u +"%Y-%m-%d"))

### What was done
- Preflighted `words_staging.json` (430 entries, 0 duplicates confirmed).
- Added **100 new English C1+ vocabulary stubs** spanning 8 domains:
  - **Cognitive Science (15):** affordance, apophenia, confabulation, automaticity, modularity, sensorimotor, perseveration, apperception, pareidolia, hypnagogia, volition, ideation, anosognosia, phenomenology, prospection
  - **Behavioral Economics (10):** satisficing, intertemporal, precommitment, reciprocity, herding, salience, anchoring, overconfidence, hyperbolic, quasirationality
  - **Materials Science (15):** annealing, crystallography, dendrite, dielectric, sintering, passivation, perovskite, piezoelectric, plasticity, porosity, superalloy, tensile, wettability, magnetostriction, martensitic
  - **Environmental Science (15):** albedo, aquifer, benthic, biogeochemistry, denitrification, ecotone, edaphic, evapotranspiration, geoengineering, leachate, limnology, methanogenesis, pedogenesis, riparian, thermocline
  - **Urban Planning (10):** agglomeration, brownfield, cadastral, densification, gentrification, conurbation, placemaking, pedestrianization, urbanism, wayfinding
  - **Law (15):** abatement, certiorari, chattel, comity, conveyance, derogation, easement, encumbrance, fiduciary, laches, mandamus, novation, rescission, subrogation, surety
  - **History (15):** appanage, decolonization, diaspora, encomienda, feudalism, hagiography, historiography, interregnum, irredentism, mercantilism, periodization, primogeniture, provenance, syncretism, vassalage
  - **Political Theory (5):** biopolitics, constitutionalism, hegemony, majoritarianism, neoliberalism

### Validation
- Zero collisions with existing 430 terms (Python set-diff check).
- JSON parsed successfully post-write; total entries: **530**.
- No duplicate terms in file.

### Decisions
- Stub format used: `{"term": "…", "language": "en", "status": "stub"}` per spec.
- Terms selected at C1+ register: domain-specific, multi-syllabic, not found in common word lists.
- Domains balanced to avoid over-indexing any single field.
- No merges performed; branch left for PR review.
## Retro — vocab/enricher-lt-19 (35 LT stubs)

**Date:** 2026-01-19
**Branch:** vocab/enricher-lt-19

### What was enriched
- **Transport nouns (8):** Autobusas (bus), automobilis (car), metro (subway), taksi (taxi), laivas (ship), traukinys (train), lėktuvas (airplane), dviratis (bicycle) — all A1, tagged `transport`/`vehicle`.
- **Travel verbs & nouns (5):** keliauti (to travel), skristi (to fly), plaukti (to swim/sail), kelionė (journey), greitkelis (motorway) — A2, tagged `travel`/`movement`/`road`.
- **Place nouns (7):** Kaimas (village), darželis (kindergarten), kinas (cinema), autobusų stotis (bus station), traukinių stotis (train station), prekybos centras (shopping centre), turgaus aikštė (market square) — A1/A2, tagged `place`/`transport`/`education`/`entertainment`/`shopping`.
- **Weather nouns (10):** lietus (rain), sniegas (snow), vėjas (wind), audra (storm), šaltis (cold/frost), perkūnija (thunderstorm), saulė (sun), debesis (cloud), rūkas (fog/mist), žaibas (lightning) — A1/A2, tagged `weather`/`nature`.
- **Weather adjectives (2):** debesuotas (cloudy), saulėtas (sunny) — A1, tagged `weather`/`sky`.
- **Measurement noun (1):** temperatūra (temperature) — A2, tagged `weather`/`measurement`.
- **Calendar/month nouns (2):** vasaris (February), rugsėjis (September) — A1, tagged `calendar`/`month`/`winter`/`autumn`.

### Decisions
- Register `neutral` used throughout; all entries are core A1/A2 everyday vocabulary.
- `plaukti` given two meanings (to swim / to sail) to capture both senses of the verb.
- `antonymTerms` used for direct weather opposites: šaltis ↔ karštis, debesuotas ↔ saulėtas, saulė ↔ mėnulis, lietus ↔ saulė.
- Empty `synonyms`/`antonymTerms` arrays kept as `[]` where linguistically no clean equivalent exists (taksi, lėktuvas, traukinys, etc.).
- Capitalised stub terms matched by lower-cased key lookup to preserve original casing (Autobusas, Kaimas).

### Validator result
132 enriched entries — all passed ✓ | 1960 total entries — all passed ✓

## Retro — vocab/enricher-en-16 (35 EN stubs)

**Date:** 2025-07-15
**Branch:** vocab/enricher-en-16

### What was enriched
- **Law (15):** abatement, certiorari, chattel, comity, conveyance, derogation, easement, encumbrance, fiduciary, laches, mandamus, novation, rescission, subrogation, surety — technical register, procedural and property law terms.
- **History (15):** appanage, decolonization, diaspora, encomienda, feudalism, hagiography, historiography, interregnum, irredentism, mercantilism, periodization, primogeniture, provenance, syncretism, vassalage — formal/neutral register, medieval through modern era.
- **Political theory (5):** biopolitics, constitutionalism, hegemony, majoritarianism, neoliberalism — formal register, ranging from Foucauldian theory to liberal democratic governance.

### Decisions
- `partOfSpeech` set to `noun` for all 35 entries; all terms are nominal concepts in their primary sense.
- Register `technical` used for strict legal and procedural terms (certiorari, mandamus, subrogation, encomienda, historiography, periodization, irredentism, mercantilism); `formal` for learned but non-specialist vocabulary (comity, hagiography, interregnum, vassalage, constitutionalism, hegemony, majoritarianism, neoliberalism, appanage, primogeniture, provenance, syncretism); `neutral` for broadly accessible terms (decolonization, diaspora, feudalism).
- Each meaning includes domain tags (e.g. `["law","property","real estate"]`) for downstream filtering.
- All synonyms arrays contain ≥ 2 items to satisfy EN validation rule.
- `antonymTerms` left as `[]` where no natural antonym exists in the domain (e.g. certiorari, mandamus, novation, subrogation).
- No merges performed; branch left for PR review.

### Validator result
PASSED — 530 word(s) valid ✓ (validate_words.py --errors-for enriched, exit 0)
---

## relations-15 retro

**Date:** 2025-07-24  
**Branch:** vocab/relations-15  
**Agent:** Vocab Relations Agent

### What was done
- Added `synonyms`, `antonymTerms`, `relatedTerms` to **35 EN enriched entries** (cognitive science cluster: affordance→quasirationality; materials science cluster: annealing→porosity) — each with ≥2 synonyms as required by validator.
- Added `synonyms`, `antonymTerms`, `relatedTerms` to **35 LT enriched entries** (body-parts cluster: oda/Galva/ranka…; medical vocabulary cluster: receptas/sveikata/karščiavimas…) — using nominative-only headwords, no -ą/-ų inflected forms.
- Status flipped `enriched` → `relations-added` for all 70 entries.

### Validation
- Preflight: both staging files PASSED `--errors-for relations-added` (pre-existing approved-status warnings only).
- Post-update: PASSED on both files, no new errors introduced.

### Decisions & notes
- EN entries that already had all three relation fields from the enricher (first 17: virulence…fibrillation) were skipped; the 35 targeted were those with all-empty arrays.
- LT synonyms for highly specific body-part terms (e.g. *oda*, *pirštas*) are limited to one diminutive/near-synonym, as no true synonym exists; validator imposes no minimum-synonym rule for LT entries.
- Self-reference guard applied manually: no term appears in its own relation arrays.
- Commit follows conventional-commits prefix `vocab(relations-15):`.
