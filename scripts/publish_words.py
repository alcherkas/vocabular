#!/usr/bin/env python3
"""
publish_words.py — Move approved words from staging to production.

Reads staging file, finds all entries with status="approved", appends them
to the production file, and removes them from staging.

Usage:
    python3 scripts/publish_words.py \
        --staging Resources/words_staging.json \
        --production Resources/words.json \
        --confirm

    # Dry run (preview what would be published):
    python3 scripts/publish_words.py \
        --staging Resources/words_staging.json \
        --production Resources/words.json \
        --dry-run

--confirm is REQUIRED for live runs (prevents accidental execution).
This is an irreversible action — see docs/REVERSIBILITY.md.

Exit code 0 = success. Exit code 1 = error.
"""

import json
import os
import subprocess
import sys
import argparse
from pathlib import Path
from datetime import datetime


def load_json(path: str) -> list:
    p = Path(path)
    if not p.exists():
        return []
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path: str, data: list):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def strip_staging_fields(word: dict) -> dict:
    """Remove pipeline-only fields before writing to production."""
    staging_only = {"status", "qa_notes"}
    production = {k: v for k, v in word.items() if k not in staging_only}
    return production


def main():
    parser = argparse.ArgumentParser(description="Publish approved words from staging to production.")
    parser.add_argument("--staging", required=True, help="Path to staging JSON (e.g. Resources/words_staging.json)")
    parser.add_argument("--production", required=True, help="Path to production JSON (e.g. Resources/words.json)")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing changes")
    parser.add_argument("--confirm", action="store_true", help="Required for live runs (prevents accidental execution)")
    args = parser.parse_args()

    if not args.dry_run and not args.confirm:
        print("ERROR: --confirm is required for live runs. This is an irreversible action.")
        print("Use --dry-run to preview, or --confirm to proceed.")
        print("See docs/REVERSIBILITY.md for the full protocol.")
        sys.exit(1)

    staging = load_json(args.staging)
    production = load_json(args.production)

    approved = [w for w in staging if w.get("status") == "approved"]
    remaining = [w for w in staging if w.get("status") != "approved"]

    if not approved:
        print("No approved words found in staging. Nothing to publish.")
        sys.exit(0)

    # Check for duplicates against production
    existing_terms = {w["term"].lower() for w in production if "term" in w}
    duplicates = [w["term"] for w in approved if w["term"].lower() in existing_terms]
    if duplicates:
        print(f"ERROR: These terms already exist in production: {duplicates}")
        print("Remove duplicates from staging before publishing.")
        sys.exit(1)

    print(f"Found {len(approved)} approved word(s) to publish:")
    for w in approved:
        meanings_count = len(w.get("meanings", []))
        print(f"  + {w['term']} ({w.get('partOfSpeech', '?')}, {meanings_count} meaning(s))")

    if args.dry_run:
        print("\nDry run — no files written.")
        sys.exit(0)

    # Append to production (strip staging-only fields)
    new_production = production + [strip_staging_fields(w) for w in approved]
    save_json(args.production, new_production)

    # Write back staging without approved entries
    save_json(args.staging, remaining)

    print(f"\nPublished {len(approved)} word(s).")
    print(f"  Production: {args.production} ({len(new_production)} total words)")
    print(f"  Staging: {args.staging} ({len(remaining)} remaining)")

    # Rebuild pre-seeded SwiftData store
    print("\n🔨 Rebuilding seed store...")
    result = subprocess.run([
        "swift", "run",
        "--package-path", "tools/VocabSeedBuilder",
        "VocabSeedBuilder",
        "--en", "Vocab/Vocab/Resources/words.json",
        "--lt", "Vocab/Vocab/Resources/words_lt.json",
        "--output", "Vocab/Vocab/Resources/vocab_seed.store"
    ], capture_output=True, text=True,
       env={**os.environ, "DEVELOPER_DIR": "/Applications/Xcode.app/Contents/Developer"})

    if result.returncode != 0:
        print(f"⚠️  Seed store rebuild failed:\n{result.stderr}")
    else:
        print(result.stdout)
        print("✅ Seed store rebuilt successfully")


if __name__ == "__main__":
    main()
