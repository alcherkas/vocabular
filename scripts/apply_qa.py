#!/usr/bin/env python3
"""
Apply QA branch results to the current staging file.

Safe re-apply logic: only changes entries that are currently at EXACTLY the
status the QA branch reviewed from (relations-added → approved or enriched).
Never downgrades entries that moved to a higher status via a different branch.

Usage:
    python3 scripts/apply_qa.py <qa_branch> <staging_file>

Examples:
    python3 scripts/apply_qa.py vocab/qa-en-65 Vocab/Vocab/Resources/words_staging.json
    python3 scripts/apply_qa.py vocab/qa-lt-69 Vocab/Vocab/Resources/words_lt_staging.json
"""

import json
import subprocess
import sys
from collections import Counter

STATUS_ORDER = {"stub": 0, "enriched": 1, "relations-added": 2, "approved": 3}


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <qa_branch> <staging_file>")
        sys.exit(1)

    qa_branch = sys.argv[1]
    staging_file = sys.argv[2]

    # Read QA branch version of staging file
    result = subprocess.run(
        ["git", "show", f"{qa_branch}:{staging_file}"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"ERROR: Could not read {staging_file} from branch {qa_branch}")
        print(result.stderr)
        sys.exit(1)

    qa_data = json.loads(result.stdout)

    with open(staging_file) as f:
        main_data = json.load(f)

    qa_by_term = {w["term"]: w for w in qa_data}

    approved = rejected = skipped = 0

    for word in main_data:
        term = word["term"]
        if term not in qa_by_term:
            continue

        qw = qa_by_term[term]
        cur_status = word.get("status", "stub")
        qa_status = qw.get("status", "stub")
        qa_source = STATUS_ORDER.get(qa_status, 0)
        cur_source = STATUS_ORDER.get(cur_status, 0)

        # QA reviewed this entry if it was relations-added in the QA branch snapshot
        # OR if QA approved it (advancing from relations-added → approved)
        # Determine what status QA *started from* for this entry
        # We infer: if QA set it to approved, it was reviewing relations-added
        # If QA set it to enriched (rejection), it was reviewing relations-added

        # QA actively reviewed an entry if:
        # - it set it to "approved" (clear intent), OR
        # - it set it to "enriched" AND left qa_notes (explicit rejection note)
        # If QA shows "enriched" with no qa_notes, it just didn't touch the entry
        # (stale snapshot from before another agent advanced it to relations-added)
        if cur_status == "relations-added":
            if qa_status == "approved":
                word.update(
                    {k: qw[k] for k in ["status", "synonyms", "antonymTerms", "relatedTerms", "qa_notes"] if k in qw}
                )
                approved += 1
            elif qa_status == "enriched" and qw.get("qa_notes"):
                # Explicit rejection with notes
                word["status"] = "enriched"
                word["qa_notes"] = qw["qa_notes"]
                rejected += 1
            else:
                # Unreviewed (stale snapshot) — leave unchanged
                skipped += 1
        else:
            skipped += 1

    with open(staging_file, "w") as f:
        json.dump(main_data, f, indent=2, ensure_ascii=False)

    status_counts = dict(Counter(w.get("status") for w in main_data))
    print(f"QA re-apply ({qa_branch}): {approved} approved, {rejected} rejected, {skipped} skipped")
    print(f"Staging now: {status_counts}")


if __name__ == "__main__":
    main()
