#!/usr/bin/env python3
"""
validate_words.py — Stage-aware word data validator.

Usage:
    python3 scripts/validate_words.py --staging Resources/words_staging.json
    python3 scripts/validate_words.py --staging Resources/words_staging.json --status enriched
    python3 scripts/validate_words.py --production Resources/words.json

Exit code 0 = all valid. Exit code 1 = validation errors found.
"""

import json
import sys
import argparse
from pathlib import Path

VALID_PARTS_OF_SPEECH = {"noun", "verb", "adjective", "adverb", "phrase", "particle", "interjection", "pronoun", "preposition", "conjunction", "numeral"}
VALID_REGISTERS = {"general", "technical", "formal", "literary", "neutral", "informal", "slang"}
VALID_STATUSES = {"stub", "enriched", "relations-added", "approved"}


def load_json(path: str) -> list:
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"ERROR: File not found: {path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"ERROR: Invalid JSON in {path}: {e}")
        sys.exit(1)


def collect_existing_terms(production_files: list[str]) -> set:
    """Collect all terms already in production files (for dedup)."""
    terms = set()
    for path in production_files:
        if Path(path).exists():
            for word in load_json(path):
                if "term" in word:
                    terms.add(word["term"].lower())
    return terms


def validate_stub(word: dict, idx: int, errors: list):
    """Validate minimum fields for stub status."""
    # term and language are always required; partOfSpeech may be blank at stub stage
    for field in ("term", "language"):
        if not word.get(field, "").strip():
            errors.append(f"[{idx}] '{word.get('term', '?')}': missing required field '{field}'")
    pos = word.get("partOfSpeech", "")
    # Only validate partOfSpeech if it's been set (blank is allowed at stub stage)
    if pos and pos not in VALID_PARTS_OF_SPEECH:
        errors.append(f"[{idx}] '{word.get('term')}': invalid partOfSpeech '{pos}' — must be one of {sorted(VALID_PARTS_OF_SPEECH)}")
    lang = word.get("language", "")
    if lang and lang not in ("en", "lt"):
        errors.append(f"[{idx}] '{word.get('term')}': invalid language '{lang}' — must be 'en' or 'lt'")


def validate_enriched(word: dict, idx: int, errors: list):
    """Validate meanings array is populated and partOfSpeech is set."""
    # partOfSpeech must be set by enriched stage
    pos = word.get("partOfSpeech", "")
    if not pos:
        errors.append(f"[{idx}] '{word.get('term')}': partOfSpeech must be set by Enricher stage")
    elif pos not in VALID_PARTS_OF_SPEECH:
        errors.append(f"[{idx}] '{word.get('term')}': invalid partOfSpeech '{pos}' — must be one of {sorted(VALID_PARTS_OF_SPEECH)}")
    meanings = word.get("meanings", [])
    if not meanings:
        errors.append(f"[{idx}] '{word.get('term')}': 'meanings' array is empty — enricher must add at least 1 meaning")
        return
    for m_idx, meaning in enumerate(meanings):
        for field in ("definition", "example", "register"):
            if not meaning.get(field, "").strip():
                errors.append(f"[{idx}] '{word.get('term')}' meaning[{m_idx}]: missing '{field}'")
        reg = meaning.get("register", "")
        if reg and reg not in VALID_REGISTERS:
            errors.append(f"[{idx}] '{word.get('term')}' meaning[{m_idx}]: invalid register '{reg}' — must be one of {sorted(VALID_REGISTERS)}")
        if not isinstance(meaning.get("tags", []), list):
            errors.append(f"[{idx}] '{word.get('term')}' meaning[{m_idx}]: 'tags' must be an array")
        # Check for duplicate meanings
        if len(meanings) > 1:
            defs = [m.get("definition", "").lower().strip() for m in meanings]
            if len(defs) != len(set(defs)):
                errors.append(f"[{idx}] '{word.get('term')}': duplicate meaning definitions detected")
    # LT words must have translation
    if word.get("language") == "lt" and not word.get("translation", "").strip():
        errors.append(f"[{idx}] '{word.get('term')}': LT word missing 'translation' field")


def validate_relations(word: dict, idx: int, errors: list):
    """Validate synonyms/antonyms/relatedTerms are lists (may be empty for LT)."""
    term_lower = word.get("term", "").lower().strip()
    for field in ("synonyms", "antonymTerms", "relatedTerms"):
        val = word.get(field)
        if val is None:
            errors.append(f"[{idx}] '{word.get('term')}': missing field '{field}' — must be an array (can be [])")
        elif not isinstance(val, list):
            errors.append(f"[{idx}] '{word.get('term')}': '{field}' must be an array")
        else:
            # Exact self-reference check: term must not appear in its own relation arrays
            if term_lower and any(isinstance(v, str) and v.lower().strip() == term_lower for v in val):
                errors.append(f"[{idx}] '{word.get('term')}': '{field}' contains the term itself — remove self-reference")
            # Substring self-reference: multi-word relation item that contains the headword as a whole word token
            # Only flags phrases (items with spaces) to avoid false positives on compound single words.
            if term_lower:
                for v in val:
                    if isinstance(v, str) and " " in v:
                        tokens = v.lower().split()
                        if term_lower in tokens:
                            errors.append(f"[{idx}] '{word.get('term')}': '{field}' item '{v}' contains the headword as a word token — likely a self-referential phrase")
            # Within-array duplicate check: same value appearing twice in one array
            lower_vals = [v.lower().strip() for v in val if isinstance(v, str)]
            if len(lower_vals) != len(set(lower_vals)):
                errors.append(f"[{idx}] '{word.get('term')}': '{field}' contains duplicate entries — remove duplicates")
            # LT: flag accusative/genitive forms (non-nominative headwords) in relation arrays
            if word.get("language") == "lt":
                for v in val:
                    if isinstance(v, str) and (v.endswith("ą") or v.endswith("ų")):
                        errors.append(f"[{idx}] '{word.get('term')}' {field}: '{v}' appears to be an inflected (non-nominative) form — use nominative headword")
    # Cross-array duplicate check: same term must not appear in more than one relation array
    cross_seen: dict = {}
    for field in ("synonyms", "antonymTerms", "relatedTerms"):
        for v in (word.get(field) or []):
            if isinstance(v, str):
                key = v.lower().strip()
                if field not in cross_seen.get(key, []):
                    cross_seen.setdefault(key, []).append(field)
    for v_lower, fields in cross_seen.items():
        if len(fields) > 1:
            errors.append(f"[{idx}] '{word.get('term')}': '{v_lower}' appears in multiple relation arrays ({', '.join(fields)}) — remove cross-array duplicate")
    # EN words should have at least some synonyms
    if word.get("language") == "en":
        synonyms = word.get("synonyms", [])
        if len(synonyms) < 2:
            errors.append(f"[{idx}] '{word.get('term')}': EN word should have at least 2 synonyms, found {len(synonyms)}")


def validate_production(word: dict, idx: int, errors: list):
    """Validate a fully production-ready word (no status field)."""
    validate_stub(word, idx, errors)
    validate_enriched(word, idx, errors)
    validate_relations(word, idx, errors)


def main():
    parser = argparse.ArgumentParser(description="Validate vocabulary word JSON files.")
    parser.add_argument("--staging", help="Path to staging JSON file (words_staging.json)")
    parser.add_argument("--production", help="Path to production JSON file (words.json)")
    parser.add_argument("--status", help="Only validate entries with this status (e.g. enriched)")
    parser.add_argument("--dedup-against", nargs="*", default=[], help="Production files to check for duplicate terms")
    parser.add_argument(
        "--errors-for", metavar="STATUS[,STATUS...]",
        help="Validate all entries but only exit 1 if entries of the specified comma-separated statuses have errors; "
             "errors from other statuses are shown as warnings. Use to get a clean signal for your batch without being "
             "blocked by pre-existing errors in other statuses (e.g. --errors-for enriched)."
    )
    args = parser.parse_args()

    if not args.staging and not args.production:
        print("ERROR: Provide --staging or --production")
        sys.exit(1)

    errors = []
    warnings = []

    # Load production files for dedup
    existing_terms = collect_existing_terms(args.dedup_against)

    # --errors-for: statuses that count toward exit code; other-status errors become warnings
    scope_statuses = set(args.errors_for.split(",")) if args.errors_for else None

    if args.staging:
        words = load_json(args.staging)
        if args.status:
            words = [w for w in words if w.get("status") == args.status]
            print(f"Validating {len(words)} '{args.status}' entries in {args.staging}")
        else:
            print(f"Validating {len(words)} entries in {args.staging}")
        if scope_statuses:
            print(f"  (exit code scoped to statuses: {', '.join(sorted(scope_statuses))}; other-status errors shown as warnings)")

        # Check for duplicates within staging file
        seen_terms = {}
        for idx, word in enumerate(words):
            term = word.get("term", "").lower().strip()
            entry_errors: list = []

            if term in seen_terms:
                entry_errors.append(f"[{idx}] '{word.get('term')}': duplicate term (also at index {seen_terms[term]})")
            else:
                seen_terms[term] = idx

            # Check dedup against production
            if term in existing_terms:
                entry_errors.append(f"[{idx}] '{word.get('term')}': term already exists in production file")

            status = word.get("status", "stub")
            if status not in VALID_STATUSES:
                entry_errors.append(f"[{idx}] '{word.get('term')}': invalid status '{status}'")
            else:
                validate_stub(word, idx, entry_errors)
                if status in ("enriched", "relations-added", "approved"):
                    validate_enriched(word, idx, entry_errors)
                if status in ("relations-added", "approved"):
                    validate_relations(word, idx, entry_errors)

            # Route errors: if --errors-for is set, non-matching statuses go to warnings
            if scope_statuses and status not in scope_statuses:
                warnings.extend([f"(pre-existing, status={status}) {e}" for e in entry_errors])
            else:
                errors.extend(entry_errors)

    elif args.production:
        words = load_json(args.production)
        print(f"Validating {len(words)} production entries in {args.production}")
        seen_terms = {}
        for idx, word in enumerate(words):
            term = word.get("term", "").lower().strip()
            if term in seen_terms:
                errors.append(f"[{idx}] '{word.get('term')}': duplicate term")
            else:
                seen_terms[term] = idx
            validate_production(word, idx, errors)

    # Report
    print()
    if warnings:
        print(f"WARNINGS — {len(warnings)} pre-existing issue(s) outside scoped statuses:")
        for w in warnings:
            print(f"  ⚠ {w}")
        print()
    if errors:
        print(f"FAILED — {len(errors)} error(s):")
        for e in errors:
            print(f"  ✗ {e}")
        sys.exit(1)
    else:
        print(f"PASSED — {len(words)} word(s) valid ✓")
        sys.exit(0)


if __name__ == "__main__":
    main()
