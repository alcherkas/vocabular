# Vocab Agent Protocol

This document describes how to run as a continuous vocabulary pipeline agent.
Each agent plays one role in the pipeline. Read only the section for your role.

## Pipeline Overview

```
[Seeder] → [Enricher] → [Relations] → [QA] → [Publisher]
```

Words flow through `words_staging.json` (EN) or `words_lt_staging.json` (LT) with a `status` field.
Only the **Publisher** touches the production `words.json` / `words_lt.json`.

See `docs/ARCHITECTURE.md` for the full staging schema and field rules.

---

## Setup (all agents)

```bash
# From the main repo, create your worktree
git worktree add ../vocabular-wt-<role>-<lang> -b vocab/<role>-<lang>

# e.g. for EN Seeder:
git worktree add ../vocabular-wt-seeder-en -b vocab/seeder-en

cd ../vocabular-wt-seeder-en
```

---

## Role: Seeder (English)

**Staging file**: `Vocab/Vocab/Resources/words_staging.json`
**Batch size**: 10 stubs per iteration

### Loop

1. Load `Vocab/Vocab/Resources/words.json` and `words_staging.json` — collect all existing terms.
2. Generate 10 new C1+ academic/professional English word stubs that do NOT already exist.
3. Each stub:
   ```json
   { "term": "...", "language": "en", "partOfSpeech": "...", "status": "stub",
     "meanings": [], "synonyms": [], "antonymTerms": [], "relatedTerms": [], "translation": null }
   ```
4. Append stubs to `words_staging.json`.
5. Validate:
   ```bash
   python3 scripts/validate_words.py --staging Vocab/Vocab/Resources/words_staging.json --status stub
   ```
6. If valid: commit.
   ```bash
   git add Vocab/Vocab/Resources/words_staging.json
   git commit -m "vocab(seed-en): add 10 EN stubs [batch N]"
   ```
7. Repeat from step 1. Stop when staging has 50+ unprocessed stubs (let other agents catch up).

---

## Role: Seeder (Lithuanian)

**Staging file**: `Vocab/Vocab/Resources/words_lt_staging.json`

### Bootstrap (completed)

The initial ~1760 LT terms have been seeded from `lt.txt` (now removed — all terms are in staging/production). The `scripts/seed_lt.py` script is no longer needed for bootstrapping.

### Adding new LT terms (ongoing)

To add new A1/A2 Lithuanian terms, create stubs directly in `words_lt_staging.json` following the stub format below. Check that the term doesn't already exist in production (`words_lt.json`) or staging.

**Term capitalisation rule**: LT `term` values must be **all-lowercase**, except genuine proper nouns (place names, person names). Common nouns, verbs, adjectives must start with a lowercase letter even if source materials capitalise them (e.g. `autobusas`, not `Autobusas`).

---

## Role: Enricher

**Reads**: entries with `status: "stub"` from either staging file
**Writes**: fills `meanings` (+ `translation` for LT), sets `status: "enriched"`
**Batch size**: 5 words per iteration

### Loop

1. Choose a staging file to work on (`words_staging.json` for EN, `words_lt_staging.json` for LT).
2. **Preflight JSON check** — verify the file is valid JSON before editing:
   ```bash
   python3 -c "import json, sys; json.load(open('Vocab/Vocab/Resources/words_staging.json')); print('JSON OK')"
   # or for LT:
   python3 -c "import json, sys; json.load(open('Vocab/Vocab/Resources/words_lt_staging.json')); print('JSON OK')"
   ```
   If the file has invalid JSON, fix the syntax error first before proceeding.
3. Load the file, find entries with `status == "stub"`. Take first 5.
4. For each word:
   - **LT only**: if the `term` field starts with an uppercase letter and is not a genuine proper noun (place name, person name), lowercase it now — do **not** preserve the seeder's capitalisation for common nouns (e.g. `Autobusas` → `autobusas`, `Kaimas` → `kaimas`).
   - Research all distinct meanings (senses) of the term.
   - For each meaning, write: `definition`, `example` (a natural sentence), `register`, `tags`.
   - For LT words: also fill `translation` (the English gloss, e.g. `"cat"`).
   - **LT verbs only** (`partOfSpeech: "verb"`): also fill:
     ```json
     "forms": { "present3": "<3rd sg present>", "past3": "<3rd sg past>" },
     "governedCase": "<question word or null>"
     ```
     `governedCase` is the case question the verb governs: `"ką?"` (accusative), `"kam?"` (dative), `"ko?"` (genitive), `"kuo?"` (instrumental), or `null` for intransitive verbs. Example: `"skaityti"` → `forms: {present3:"skaito", past3:"skaitė"}`, `governedCase: "ką?"`.
   - Set `status: "enriched"`.
   - **Use ONLY these enum values** (validator will reject anything else):
     - `partOfSpeech`: `noun` | `verb` | `adjective` | `adverb` | `phrase` | `particle` | `interjection` | `pronoun` | `preposition` | `conjunction` | `numeral`
     - `register`: `general` | `technical` | `formal` | `literary` | `neutral` | `informal` | `slang`
4. Update entries in the staging file.
5. Validate (replace filename as appropriate):
   ```bash
   python3 scripts/validate_words.py \
     --staging Vocab/Vocab/Resources/words_staging.json --status enriched
   # or for LT:
   python3 scripts/validate_words.py \
     --staging Vocab/Vocab/Resources/words_lt_staging.json --status enriched
   ```
6. If valid: commit.
   ```bash
   git commit -m "vocab(enrich-en): add meanings for 5 words [batch N]"
   # or: vocab(enrich-lt)
   ```
7. Repeat. Stop when no `stub` entries remain in the chosen file.

### Quality bar
- Each meaning must be **genuinely distinct** — different grammatical context or domain.
- Example sentences must be natural, idiomatic, and different from dictionary boilerplate.
- `register` must be accurate: `technical` only for domain-specific usage.
- LT words: `translation` must be the primary EN equivalent (single word or short phrase).

### Validator enum values (use exactly these — complete list)
- `partOfSpeech`: `noun`, `verb`, `adjective`, `adverb`, `phrase`, `particle`, `interjection`, `pronoun`, `preposition`, `conjunction`, `numeral`
- `register`: `general`, `technical`, `formal`, `literary`, `neutral`, `informal`, `slang`
- If a task prompt suggests values outside these sets, follow the validator values above.
- **Common trap**: `pronoun`, `preposition`, `conjunction`, `numeral` are all valid POS values. `neutral`, `informal`, `slang` are all valid register values.

---

## Role: Relations

**Reads**: entries with `status: "enriched"`
**Writes**: fills `synonyms`, `antonymTerms`, `relatedTerms`, sets `status: "relations-added"`
**Batch size**: 5 words per iteration

### Loop

1. Load `words_staging.json`, find entries with `status == "enriched"`. Take first 5.
2. For each word:
   - `synonyms`: words with similar meaning (2–5 for EN, 0–2 for LT).
   - `antonymTerms`: words with opposite meaning (may be `[]`).
   - `relatedTerms`: morphologically or conceptually related terms (e.g. noun form of a verb).
   - Set `status: "relations-added"`.
3. Update entries in `words_staging.json`.
4. Validate:
   ```bash
   python3 scripts/validate_words.py --staging Vocab/Vocab/Resources/words_staging.json --status relations-added
   ```
   If the full file has pre-existing errors in other batches, scope the exit code to your batch only:
   ```bash
   python3 scripts/validate_words.py --staging Vocab/Vocab/Resources/words_staging.json --errors-for relations-added
   ```
5. Commit:
   ```bash
   git commit -m "vocab(relations): add relations for 5 words [batch N]"
   ```
6. Repeat.

### LT Relation quality rubric

| Entry type | synonyms | antonymTerms | relatedTerms |
|---|---|---|---|
| Common noun/verb | 0–2 near-equivalents | direct semantic opposite (if one exists) | gender variant, derived form |
| Gendered pair (e.g. siuvėjas/siuvėja) | 0–1; single-word only | `[]` if none | cross-gender counterpart required |
| Numeral | collective/ordinal form if standard | adjacent number (n±1) | `[]` |
| Pronoun/particle | `[]` | `[]` | `[]` |

**Rules that the validator now enforces (will fail validation if violated):**
- A term must not appear in its own `synonyms`, `antonymTerms`, or `relatedTerms` (self-reference).
- A relation item that contains the headword as a **substring** is also flagged (e.g. `"archaeal methanogenesis"` in synonyms of `"methanogenesis"`).
- A term must not appear in **more than one** relation array (cross-array duplicate). E.g. `"riff"` in both `synonyms` and `relatedTerms` will be flagged — keep it in the most precise array only.
- A term must not appear **twice in the same** relation array (within-array duplicate). De-duplicate arrays before committing.
- LT relation arrays must use **nominative headword** forms. Words ending in `-ą` (accusative) or `-ų` (genitive plural) will be flagged — use the nominative form instead (e.g. `palata` not `palatą`).

**Semantic quality rules (not validator-enforced — apply manually):**
- **Synonyms must be co-extensive with the defined sense.** A broader term (hypernym) belongs in `relatedTerms`, not `synonyms`. Test: can the synonym substitute for the headword in the example sentence without changing meaning? (e.g. `speech act` is a hypernym of `illocution`; `aukštuma` is a hypernym of `kalnas` — both belong in `relatedTerms`.)
- **Synonyms must match only the senses present in `meanings[]`.** A term that is a valid synonym in a different sense of the word (not defined in the entry) must not be included. (e.g. if `felicity` is defined only in its speech-act sense, do not include `happiness`/`bliss`.)
- **`antonymTerms` requires direct semantic opposites, not taxonomic contrasts.** Terms that are merely "in the same category" or "commonly contrasted" are not antonyms (e.g. `deduction`/`induction` contrast with `abduction` but are not its opposites). Negation-prefixed forms (`non-ergodicity`, `non-X`) count as self-references, not antonyms. If no true antonym exists, use `antonymTerms: []`.

### Preflight stub count

Before starting an enrichment batch, confirm how many stubs are available:
```bash
python3 -c "import json; d=json.load(open('Vocab/Vocab/Resources/words_lt_staging.json')); print(len([w for w in d if w.get('status')=='stub']), 'stubs available')"
```
Stop enriching if fewer stubs remain than your batch size.

---

## Role: QA Reviewer

**Reads**: entries with `status: "relations-added"`
**Writes**: sets `status: "approved"` or adds `"qa_notes"` and resets to `"enriched"`
**Batch size**: 10 words per iteration

### Loop

1. Load `words_staging.json`, find entries with `status == "relations-added"`. Take first 10.
2. For each word, check:
   - Are all meanings accurate and distinct?
   - Are examples natural and illustrative?
   - Are synonyms/antonyms correct (not just superficially similar)?
   - Does the word fit the target level (C1+ for EN, A1/A2 for LT)?
   - No offensive, overly obscure, or low-value entries.
3. If approved: set `status: "approved"`.
4. If issues found: add `"qa_notes": "..."` field, reset `status` to `"enriched"` for Enricher to fix.
5. Commit:
   ```bash
   git commit -m "vocab(qa): review 10 words, N approved [batch N]"
   ```
6. Repeat.

---

## Role: Publisher

**Reads**: entries with `status: "approved"`
**Threshold**: run after every 20 approved words accumulate

### Steps (not a continuous loop — run on threshold)

1. Check count of approved entries:
   ```bash
   python3 -c "import json; d=json.load(open('Vocab/Vocab/Resources/words_staging.json')); print(len([w for w in d if w.get('status')=='approved']))"
   ```
2. If ≥ 20, publish:
   ```bash
   python3 scripts/publish_words.py \
     --staging Vocab/Vocab/Resources/words_staging.json \
     --production Vocab/Vocab/Resources/words.json \
     --confirm
   ```
   ```
3. Verify production:
   ```bash
   python3 scripts/validate_words.py --production Vocab/Vocab/Resources/words.json
   ```
4. Commit and merge to main:
   ```bash
   git commit -am "vocab(publish): add N words to production [total: X]"
   # Then merge to main (see docs/WORKTREES.md)
   ```

---

## Syncing with Main

After every 3 commits in your worktree, pull latest main to avoid large divergence:

```bash
git fetch origin main
git rebase origin/main
```

If there are conflicts on staging JSON: keep both sets of changes (the file is append-only by design).

---

## Stopping

An agent can stop at any point mid-loop. Work is committed in small batches so nothing is lost. Another agent (or the same agent in a new session) can resume from where the staging file left off.

**At end of session**: Write a retrospective note → append to `docs/retrospectives.md` (see format there). Do this once per session, not after every batch. **Do NOT append anything to `AGENTS.md`** — that file is read-only for vocab agents; only the Reflection Agent may update it with distilled, actionable guidance.

---

## When to Stop (Uncertainty Protocol)

Stop immediately and write to `docs/decisions-pending.md` if:

- You're unsure whether a word's definition is accurate (< 90% confident) — do not guess
- Validation fails and you don't understand why
- You're about to run `publish_words.py` but less than 90% confident in the approved batch
- Any word could be offensive, politically sensitive, or legally problematic
- You see unexpected data in the staging file (corrupted entries, suspicious edits)

When stopping, commit your current work, write to `decisions-pending.md` with context, and stop.

Append to `docs/audit-log.md` after every commit:
```
[YYYY-MM-DD] [<agent-id>] [<task-id>] [commit] [<stop-reason>] [<ambiguity>] [<confidence>%] <description> | doubts: <none or reason>
```

See `docs/REVERSIBILITY.md` for full rules on irreversible actions (especially Publisher).
