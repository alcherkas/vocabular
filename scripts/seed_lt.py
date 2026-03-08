#!/usr/bin/env python3
"""
seed_lt.py — Bootstrap words_lt_staging.json from lt.txt.

Parses the raw Lithuanian word list in lt.txt and creates stub entries
in words_lt_staging.json. Run once to bootstrap the LT vocabulary pipeline.

Usage:
    python3 scripts/seed_lt.py
    python3 scripts/seed_lt.py --source lt.txt --staging data/words_lt_staging.json
    python3 scripts/seed_lt.py --dry-run   # preview without writing

Exit code 0 = success.
"""

import json
import sys
import re
import argparse
from pathlib import Path


VERB_SUFFIXES = (
    "ti", "yti", "oti", "uoti", "auti", "inti", "enti", "ėti", "išti", "ysti"
)


def infer_pos(term: str) -> str:
    """Rough part-of-speech heuristic. Enricher agent will correct these."""
    t = term.lower().strip()
    # Multi-word → phrase
    if " " in t:
        return "phrase"
    # Lithuanian verb infinitives end in characteristic suffixes
    for suffix in VERB_SUFFIXES:
        if t.endswith(suffix) and len(t) > len(suffix) + 2:
            return "verb"
    # Default: leave blank for Enricher to fill in
    return ""


def parse_lt_txt(path: str) -> list[str]:
    """Parse comma/newline separated word list into individual terms."""
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    terms = []
    for line in content.split("\n"):
        line = line.strip()
        if not line:
            continue
        for token in line.split(","):
            term = token.strip().rstrip(".")
            if term:
                terms.append(term)

    return terms


def load_json(path: str) -> list:
    p = Path(path)
    if not p.exists():
        return []
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: str, data: list):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def make_stub(term: str) -> dict:
    return {
        "term": term,
        "language": "lt",
        "partOfSpeech": infer_pos(term),
        "status": "stub",
        "meanings": [],
        "synonyms": [],
        "antonymTerms": [],
        "relatedTerms": [],
        "translations": {}
    }


def main():
    parser = argparse.ArgumentParser(description="Bootstrap words_lt_staging.json from lt.txt")
    parser.add_argument("--source", default="lt.txt", help="Path to lt.txt (default: lt.txt)")
    parser.add_argument(
        "--staging",
        default="data/words_lt_staging.json",
        help="Path to staging JSON (contains all words including published)"
    )
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing")
    args = parser.parse_args()

    # Parse source
    raw_terms = parse_lt_txt(args.source)
    print(f"Parsed {len(raw_terms)} raw tokens from {args.source}")

    # Deduplicate raw list (case-insensitive)
    seen = {}
    unique_terms = []
    for term in raw_terms:
        key = term.lower()
        if key not in seen:
            seen[key] = True
            unique_terms.append(term)
    print(f"After dedup: {len(unique_terms)} unique terms")

    # Load existing staging (includes published words) — skip already-present terms
    existing_staging = load_json(args.staging)
    existing_terms = {w["term"].lower() for w in existing_staging if "term" in w}

    # Build new stubs
    new_stubs = []
    skipped = 0
    for term in unique_terms:
        if term.lower() in existing_terms:
            skipped += 1
            continue
        new_stubs.append(make_stub(term))

    print(f"Skipped {skipped} terms already in staging/production")
    print(f"New stubs to add: {len(new_stubs)}")

    # POS breakdown
    pos_counts = {}
    for s in new_stubs:
        pos = s["partOfSpeech"] or "(unknown)"
        pos_counts[pos] = pos_counts.get(pos, 0) + 1
    print("Part-of-speech breakdown (heuristic):")
    for pos, count in sorted(pos_counts.items(), key=lambda x: -x[1]):
        print(f"  {pos}: {count}")

    if not new_stubs:
        print("Nothing to add.")
        sys.exit(0)

    if args.dry_run:
        print("\nDry run — no files written.")
        print("Sample stubs:")
        for stub in new_stubs[:5]:
            print(" ", json.dumps(stub, ensure_ascii=False))
        sys.exit(0)

    # Write
    combined = existing_staging + new_stubs
    save_json(args.staging, combined)
    print(f"\nWrote {len(combined)} entries to {args.staging} ({len(new_stubs)} new)")


if __name__ == "__main__":
    main()
