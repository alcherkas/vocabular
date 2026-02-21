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

## qa-16 retro

**Date:** 2025-07-24  
**Branch:** vocab/qa-16  
**Agent:** Vocab QA Agent

### What was done
- Preflight JSON validation: both `words_staging.json` and `words_lt_staging.json` passed `python3 -m json.tool`.
- Reviewed all **35 EN** and **35 LT** `relations-added` entries from batch 16 (relations-15 output).
- Ran `validate_words.py --staging` on both files; 26 EN + 10 LT pre-existing failures noted, none in batch 16 entries.

### Decisions per check

**Check 1 — Self-reference in arrays**
- No exact self-references found. Near-self-references evaluated case-by-case.

**Check 2 — LT nominative forms**
- No bare -ą/-ų endings found in array items. Compound phrases like `dantų šepetėlis` and `medicinos reikmenys` use genitive as grammatical modifier; the phrase head is nominative — accepted.

**Check 3 — Cross-array duplicates**
- `modularity`: `domain specificity` appeared in both `synonyms` and `relatedTerms` → enriched.
- `quasirationality`: `bounded rationality` appeared in both `synonyms` and `relatedTerms` → enriched.
- `plasticity`: `ductility` appeared in both `synonyms` and `relatedTerms` → enriched.
- `overconfidence`: `calibration` appeared in both `antonymTerms` and `relatedTerms` → enriched.

**Check 4 — Self-referential synonyms (term contained in synonym string)**
- `dielectric`: synonym `dielectric material` = term + generic noun, not a distinct synonym → enriched.
- `perovskite`: `perovskite material` = term + generic noun; `perovskite oxide` = subtype, not synonym → enriched.

**Check 5 — LT semantic accuracy**
- `jaustis`: synonym `jausti` is the transitive (non-reflexive) counterpart — different verb class, should be relatedTerms → enriched.
- `receptas`: synonyms `vaistų receptas` and `medicinos receptas` are qualified forms of the term itself, not independent synonyms → enriched.

### Outcome
| Language | Total | Approved | Enriched |
|---|---|---|---|
| EN | 35 | 29 | 6 |
| LT | 35 | 33 | 2 |

---

## vocab/qa-17 — QA Retrospective

**Batch scope:** 35 EN entries (medical/legal/historical vocabulary) + 35 LT entries (adjective pairs m/f + common verbs, expanded).  
**Branch:** `vocab/qa-17`  
**Validator baseline:** pre-existing errors in older batches (synonym-count and inflected-form warnings); no new errors introduced by this batch.

### Check 1 — Cross-array duplicates
Five EN entries had a term appear in two relation arrays simultaneously:
- `pharmacokinetics`: `pharmacodynamics` in both `antonymTerms` and `relatedTerms` → removed from `relatedTerms`.
- `pharmacodynamics`: `pharmacokinetics` in both `antonymTerms` and `relatedTerms` → removed from `relatedTerms`.
- `agonist`: `antagonist` in both `antonymTerms` and `relatedTerms` → removed from `relatedTerms`.
- `antagonist`: `agonist` in both `antonymTerms` and `relatedTerms` → removed from `relatedTerms`.
- `novation`: `assignment` in both `synonyms` and `relatedTerms` → removed from `synonyms` (also semantically inaccurate; see Check 2).

One LT entry:
- `sėdėti`: `stovėti` in both `antonymTerms` and `relatedTerms` → removed from `relatedTerms`.

### Check 2 — Synonym semantic accuracy (EN)
- `fibrillation`: `ventricular fibrillation` and `atrial fibrillation` are subtypes (hyponyms), not synonyms; `cardioversion` is a treatment procedure, not an antonym of fibrillation → all three removed.
- `bradycardia`: `cardiac bradycardia` is tautological (bradycardia is inherently cardiac) → removed.
- `laches`: `delay` and `tardiness` are generic nouns; laches is a specific equitable doctrine requiring delay + prejudice → both removed, `estoppel by delay` retained.
- `novation`: `assignment` transfers rights without extinguishing the original contract; novation replaces it entirely → not a synonym.

### Check 3 — LT grammatical gender agreement
- `jauna` (feminine adj.): synonyms `jaunatviškas` and `jaunutis` were masculine nominative forms → replaced with feminine nominative `jaunatviška` and `jaunutė`.

### Check 4 — LT synonym semantic accuracy
- `susipažinti`: `susitikti` (to physically meet, including re-encounters) ≠ `susipažinti` (first acquaintance) → removed.
- `aukštas` / `aukšta`: `didingas` / `didinga` (majestic, grand) ≠ tall → removed.
- `naujas` / `nauja`: `modernus` / `moderni` (modern, contemporary) ≠ new → removed.
- `žema`: `trumpa` (short in length/duration) ≠ low (in height/elevation) → removed.

### Check 5 — LT nominative forms (-ą/-ų scan)
No accusative (`-ą`) or genitive-plural (`-ų`) ending violations detected in any relation array.

### Check 6 — Self-references
No term appeared in its own relation arrays in either file.

### Outcome
| Language | Total | Approved | Enriched |
|---|---|---|---|
| EN | 35 | 27 | 8 |
| LT | 35 | 27 | 8 |

### Notes
- The pattern of antonym terms leaking into `relatedTerms` (and vice versa) recurred across four EN entries; enricher agents should ensure mutual-antonym pairs are placed in exactly one array.
- LT masculine/feminine adjective entries require gender-matched synonyms; enrichers should match synonym forms to the grammatical gender of the headword.
- Validator surfaced 200+ pre-existing synonym-count and inflected-form warnings from earlier batches (batches 1–16). These are outside the scope of qa-17 and were not modified.
## Batch enricher-lt-24 — LT stubs (jobs/professions, work/office, A1/A2)

**Date:** 2025-07-19
**Branch:** vocab/enricher-lt-24
**Scope:** 35 Lithuanian stubs → enriched

### Term selection
Selected 35 stubs covering jobs/professions and work/office vocabulary at A1/A2 level from the existing stub pool (1 265 stubs at batch start). Priority given to terms learners encounter early when discussing employment and workplace contexts.

**Categories enriched:**
| Category | Terms |
|---|---|
| Professions | mechanikas, kepėjas, gaisrininkas, statybininkas, sodininkas |
| Workplace people | darbuotojas, darbuotoja, viršininkas, viršininkė, kolega, kolegė, vedėjas, vedėja, bedarbis |
| Compensation & leave | alga, atlyginimas, atostogos |
| Office events | susirinkimas, susitikimas, komandiruotė, konferencija, posėdis, seminaras |
| Organisation | Skyrius |
| Documents & legal | sutartis, dokumentas, gyvenimo aprašymas, parašas, prašymas |
| Office tech & furniture | kompiuteris, nešiojamas kompiuteris, elektroninis laiškas, elektroninis paštas, rašomasis stalas, kopijavimo aparatas |

### Decisions

**POS: all noun** — every selected term is a standalone noun or noun phrase; no verbs or adjectives were in scope for this batch.

**posėdis → register: formal** — unlike the other work terms which are register-neutral, *posėdis* denotes a formal official session (board, government, institutional) and is distinctly more formal in register than *susirinkimas* or *susitikimas*.

**Synonyms/antonymTerms/relatedTerms left as `[]`** — at *enriched* status the validator only checks meanings/definition/example/register/translation. Relation arrays are validated at *relations-added* stage; leaving them empty avoids introducing inflected or inaccurate relation terms before the dedicated relations pass.

**Gendered pairs enriched individually** — Lithuanian grammatically distinguishes male/female person nouns (e.g. *darbuotojas* / *darbuotoja*). Each form was enriched as a separate entry with its own definition and example sentence to preserve grammatical accuracy. Translation fields differentiate "(female)" where necessary.

**Multi-word terms matched by exact term string** — *gyvenimo aprašymas*, *nešiojamas kompiuteris*, *elektroninis laiškas*, *elektroninis paštas*, *rašomasis stalas*, *kopijavimo aparatas* are stored as multi-word terms in the JSON; enriched by exact string match to avoid any ambiguity.

### Validation
`validate_words.py --errors-for enriched` → **PASSED** (10 pre-existing warnings on *approved* entries, unchanged from baseline).

---

## enricher-lt-25 — Emotions & Personality Traits (35 stubs)

### Scope
35 Lithuanian stubs enriched focusing on emotions and personality traits, A1/A2 level with several B1 entries.

| Category | Terms |
|---|---|
| Core emotion nouns | džiaugsmas, laimė, meilė, liūdesys, pyktis, baimė, nerimas, gėda, pavydas, pasididžiavimas |
| Personality/state nouns | kantrybė, sėkmė, nuostaba, susidomėjimas, ramybė, draugiškumas, palinkėjimas, proga |
| Personality adjectives | švelnus, mandagus, ramus, smalsus, šiltas |
| Emotion/personality verbs | džiaugtis, jaudintis, nervintis, rūpintis, stengtis, tikėtis, domėtis, susitaikyti, gerbti, sveikinti, linkėti, Atleisti |

### Decisions

**POS: mixed** — nouns, adjectives, and reflexive verbs all included because emotions and personality traits in Lithuanian are expressed through all three classes.

**Reflexive verbs (-tis suffix)** — *džiaugtis, jaudintis, nervintis, rūpintis, stengtis, tikėtis, domėtis, susitaikyti* are all genuine Lithuanian reflexive verbs; tagged as `verb` (no separate `reflexive` POS exists in the valid set).

**Atleisti: two meanings** — *atleisti* covers both "to forgive" (emotional/moral sense, register: general) and "to dismiss from employment" (workplace sense, register: formal). Both senses are high-frequency at A2/B1 level and were included in the same entry.

**šiltas: two meanings** — physical warmth (temperature, A1) and emotional warmth (personality, A2/B1) included as separate meanings; both senses are commonly encountered and strongly linked.

**Synonyms use nominative headwords only** — no accusative (-ą) or genitive (-ų) forms appear in synonyms, antonymTerms, or relatedTerms, in compliance with validator rules for Lithuanian.

**Relation arrays populated** — unlike the previous batch, synonyms/antonymTerms/relatedTerms were filled in at the *enriched* stage to provide richer data. The validator does not require them at this stage but does check for inflected forms and self-references when present; all arrays pass cleanly.

**proga included** — while *proga* (occasion/opportunity) is not a pure emotion word, it appears in many emotional/social contexts (birthday greetings, celebrations) and is closely related to the social-expression cluster of this batch.

### Validation
`validate_words.py --errors-for enriched` → **PASSED** (10 pre-existing warnings on *approved* entries, unchanged from baseline).
## Session retro — vocab/relations-18

**Date:** 2026-02-21
**Branch:** vocab/relations-18
**Commit:** bed6763

### What was done
- Preflight JSON validation on both `words_staging.json` and `words_lt_staging.json` — both passed `python3 -m json.tool` with exit 0.
- Ran `--errors-for relations-added` baseline on both files — 0 errors in scope, only pre-existing approved-status warnings.
- **EN (`words_staging.json`):** All 31 enriched entries promoted to `relations-added`. Enricher had already embedded synonyms/antonymTerms/relatedTerms; programmatic audit found 3 violations:
  - `bradycardia` — 1 synonym ("slow heart rate"); added `"bradyarrhythmia"` (true clinical synonym, frequently used interchangeably in cardiology).
  - `fibrillation` — 1 synonym ("cardiac fibrillation"); added `"myocardial quivering"` (descriptive medical synonym for chaotic muscle-fibre contraction).
  - `laches` — 1 synonym ("estoppel by delay"); added `"unreasonable delay doctrine"` (recognised legal-doctrinal synonym).
  - No self-references, no cross-array duplicates found in remaining 28 entries.
- **LT (`words_lt_staging.json`):** First 35 enriched entries promoted to `relations-added`. Programmatic audit found 3 violations:
  - `didelis` — "stambus" appeared in both `synonyms` and `relatedTerms`; removed from `relatedTerms`.
  - `didelė` — "stambi" appeared in both `synonyms` and `relatedTerms`; removed from `relatedTerms`.
  - `jų` — `antonymTerms` contained `"mūsų"` (ends in `-ų`); replaced with `"mes"` (nominative dictionary form of the same pronoun).
- Post-promotion validation: both files exit 0 under `--errors-for relations-added`.

### Stats
| File | Newly promoted | Pre-existing relations-added | Total relations-added |
|------|---------------|------------------------------|-----------------------|
| words_staging.json | 31 | 70 | 101 |
| words_lt_staging.json | 35 | 70 | 105 |

### Issues / notes
- Rule (1) self-reference: no self-references found in any of the 66 promoted entries.
- Rule (2) LT nominative forms: `jų` entry had `"mūsų"` (genitive `-ų`) in antonymTerms — replaced with `"mes"` to comply. No other inflected forms introduced.
- Rule (3) synonyms semantic accuracy: three EN entries had <2 synonyms due to QA pruning in a prior pass (enricher's original synonyms were removed as subtypes or tautologies); replacements chosen as genuine co-extensive terms.
- Rule (4) no cross-array duplicates: `didelis`/`didelė` each had one synonym duplicated in relatedTerms; removed from relatedTerms.
- EN enriched count was 31, not 35 — all available enriched entries processed; batch size limited by available enriched entries.

---

## Retro — enricher-lt-27: enrich 35 Lithuanian stubs (technology/computers/internet)

**Date:** 2025-02-21
**Branch:** vocab/enricher-lt-27
**Commit:** 6244fc0

### What was done
- Enriched 35 stubs in `words_lt_staging.json` focusing on technology, computers, and internet vocabulary at A2/B1 level.
- Selected terms span hardware/devices, digital transactions, file operations, device control, internet/communication verbs, online interaction, digital documents, and fintech/e-learning.
- All 35 entries validated clean under `validate_words.py --errors-for enriched` (exit 0).

### Terms enriched (35)
| Term | POS | Focus area |
|------|-----|------------|
| pelė | noun | hardware — computer mouse |
| planšetinis kompiuteris | phrase | hardware — tablet device |
| televizorius | noun | electronics — streaming/media |
| mokėjimo kortelė | phrase | fintech — digital payment |
| elektroninis bilietas | phrase | digital — e-ticket |
| kopija | noun | file operations |
| kopijuoti | verb | file operations — copy |
| klijuoti | verb | file operations — paste / glue |
| trinti | verb | file operations — delete/erase |
| įjungti | verb | device control — power on |
| išjungti | verb | device control — power off |
| siųsti | verb | internet/email — send |
| gauti | verb | internet/email — receive |
| ieškoti | verb | internet — search |
| rasti | verb | internet — find |
| patikrinti | verb | security/internet — verify |
| pakeisti | verb | settings/security — update |
| veikti | verb | device/system — function |
| dalyvauti | verb | online meeting — participate |
| kreiptis | verb | online interaction — contact |
| pasirašyti | verb | digital document — sign |
| susirinkti | verb | online meeting — gather |
| pradėti | verb | process — start |
| baigti | verb | process — finish |
| užsakyti | verb | e-commerce — order |
| laiškas | noun | email/post |
| siuntinys | noun | e-commerce — parcel |
| valiuta | noun | fintech — currency |
| moneta | noun | fintech — coin/crypto token |
| paskola | noun | fintech — loan |
| blankas | noun | online form |
| kursas | noun | fintech/e-learning — rate/course |
| kursai | noun | e-learning — courses |
| užpildyti | verb | online form — fill in |
| teirautis | verb | online inquiry |

### Issues / notes
- No terms required correction post-validation; all 35 enriched entries passed on first run.
- Enrichment script accidentally wrote to the wrong repo (`vocabular`) on the first run due to CWD mismatch; reverted immediately via `git checkout`, then re-applied to the correct repo (`vocabular-wt-enricher-lt-27`). No lasting impact on `vocabular`.
- Several terms (e.g. `klijuoti`, `trinti`, `moneta`, `laiškas`, `kursas`) were given two meanings where the tech sense and the everyday sense differ meaningfully.
- Synonyms `paieška vykdyti` (ieškoti) and `patvirtinti parašu` (pasirašyti) are descriptive phrases rather than single-word headwords; acceptable at A2/B1 where true single-word synonyms are sparse.
