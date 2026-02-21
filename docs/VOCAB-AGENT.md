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

### First-time bootstrap (run once)

The word list in `lt.txt` is the authoritative seed source for LT vocabulary.
Run this once to populate the staging file from it:

```bash
python3 scripts/seed_lt.py
```

This creates ~1760 stubs in `words_lt_staging.json`. Commit the result:

```bash
git add Vocab/Vocab/Resources/words_lt_staging.json
git commit -m "vocab(seed-lt): bootstrap 1760 stubs from lt.txt"
```

### Adding new LT terms (ongoing)

After the bootstrap, the LT Seeder only adds terms that are **not** already in lt.txt or staging.
If you have new A1/A2 Lithuanian terms to add, append them to `lt.txt` first, then re-run:

```bash
python3 scripts/seed_lt.py
git add lt.txt Vocab/Vocab/Resources/words_lt_staging.json
git commit -m "vocab(seed-lt): add N new stubs from lt.txt"
```

---

## Role: Enricher

**Reads**: entries with `status: "stub"` from either staging file
**Writes**: fills `meanings` (+ `translation` for LT), sets `status: "enriched"`
**Batch size**: 5 words per iteration

### Loop

1. Choose a staging file to work on (`words_staging.json` for EN, `words_lt_staging.json` for LT).
2. Load the file, find entries with `status == "stub"`. Take first 5.
3. For each word:
   - Research all distinct meanings (senses) of the term.
   - For each meaning, write: `definition`, `example` (a natural sentence), `register`, `tags`.
   - For LT words: also fill `translation` (the English gloss, e.g. `"cat"`).
   - Set `status: "enriched"`.
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

### Validator enum values (use exactly these)
- `partOfSpeech`: `noun`, `verb`, `adjective`, `adverb`, `phrase`, `particle`, `interjection`
- `register`: `general`, `technical`, `formal`, `literary`
- If a task prompt suggests values outside these sets (e.g., `pronoun`, `neutral`), follow the validator values above.

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
5. Commit:
   ```bash
   git commit -m "vocab(relations): add relations for 5 words [batch N]"
   ```
6. Repeat.

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

**At end of session**: Write a retrospective note → append to `docs/retrospectives.md` (see format there). Do this once per session, not after every batch.

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
