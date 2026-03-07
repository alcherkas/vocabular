#!/usr/bin/env python3
"""
publish_words.py — Publish approved words and rebuild the seed store.

Marks approved entries as "published" in the staging file, strips QA metadata,
and rebuilds the pre-seeded SwiftData store.

Usage:
    python3 scripts/publish_words.py \
        --staging data/words_staging.json \
        --confirm

    # Dry run (preview what would be published):
    python3 scripts/publish_words.py \
        --staging data/words_staging.json \
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


def main():
    parser = argparse.ArgumentParser(description="Publish approved words and rebuild seed store.")
    parser.add_argument("--staging", required=True, help="Path to staging JSON (e.g. data/words_staging.json)")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing changes")
    parser.add_argument("--confirm", action="store_true", help="Required for live runs (prevents accidental execution)")
    args = parser.parse_args()

    if not args.dry_run and not args.confirm:
        print("ERROR: --confirm is required for live runs. This is an irreversible action.")
        print("Use --dry-run to preview, or --confirm to proceed.")
        print("See docs/REVERSIBILITY.md for the full protocol.")
        sys.exit(1)

    words = load_json(args.staging)

    approved = [w for w in words if w.get("status") == "approved"]

    if not approved:
        print("No approved words found. Nothing to publish.")
        sys.exit(0)

    print(f"Found {len(approved)} approved word(s) to publish:")
    for w in approved:
        meanings_count = len(w.get("meanings", []))
        print(f"  + {w['term']} ({w.get('partOfSpeech', '?')}, {meanings_count} meaning(s))")

    if args.dry_run:
        print("\nDry run — no files written.")
        sys.exit(0)

    # Mark approved → published, strip QA metadata
    for w in words:
        if w.get("status") == "approved":
            w["status"] = "published"
            w.pop("qa_notes", None)

    save_json(args.staging, words)

    published_count = len([w for w in words if w.get("status") == "published"])
    print(f"\nPublished {len(approved)} word(s). Total published: {published_count}")

    # Rebuild pre-seeded SwiftData store
    print("\n🔨 Rebuilding seed store...")
    result = subprocess.run([
        "swift", "run",
        "--package-path", "tools/VocabSeedBuilder",
        "VocabSeedBuilder",
        "--en", "data/words_staging.json",
        "--lt", "data/words_lt_staging.json",
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
