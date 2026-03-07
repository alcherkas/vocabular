#!/usr/bin/env python3
"""
check_permissions.py — Verify that staged git changes are within an agent's allowed file scope.

Usage:
  python3 scripts/check_permissions.py --task <task-id>

Exits 0 if all staged/unstaged changes are within the task's permitted files.
Exits 1 with details if any out-of-scope files are modified.
"""

import argparse
import subprocess
import sys

# Map from task-id to the list of files/prefixes the agent may modify.
# Prefix ending with "/" matches any file under that directory.
TASK_PERMISSIONS: dict[str, list[str]] = {
    # Vocab pipeline
    "vocab-seeder-en":    ["data/words_staging.json", "docs/TASKS.md", "docs/audit-log.md"],
    "vocab-seeder-lt":    ["data/words_lt_staging.json", "docs/TASKS.md", "docs/audit-log.md"],
    "vocab-enricher-en":  ["data/words_staging.json", "docs/TASKS.md", "docs/audit-log.md"],
    "vocab-enricher-lt":  ["data/words_lt_staging.json", "docs/TASKS.md", "docs/audit-log.md"],
    "vocab-relations":    ["data/words_staging.json", "data/words_lt_staging.json", "docs/TASKS.md", "docs/audit-log.md"],
    "vocab-qa":           ["data/words_staging.json", "data/words_lt_staging.json", "docs/TASKS.md", "docs/audit-log.md"],
    # Publisher is special — it writes to production
    "vocab-publisher":    ["data/words.json", "data/words_lt.json",
                           "data/words_staging.json", "data/words_lt_staging.json",
                           "docs/audit-log.md"],

    # App model/feature tasks
    "word-meanings-model": ["Vocab/Vocab/Models/Word.swift", "Vocab/Vocab/Services/WordService.swift",
                            "Vocab/Vocab/Views/", "VocabTests/", "docs/TASKS.md", "docs/audit-log.md"],
    "word-relations":      ["Vocab/Vocab/Models/Word.swift", "Vocab/Vocab/Services/WordService.swift",
                            "docs/TASKS.md", "docs/audit-log.md"],
    "language-field":      ["Vocab/Vocab/Models/Word.swift", "Vocab/Vocab/Services/WordService.swift",
                            "docs/TASKS.md", "docs/audit-log.md"],
    "spaced-rep":          ["Vocab/Vocab/Models/Word.swift", "Vocab/Vocab/Services/SpacedRepetitionService.swift",
                            "Vocab/Vocab/Views/FlashcardsView.swift", "VocabTests/",
                            "docs/TASKS.md", "docs/audit-log.md"],
    "lt-ui-filter":        ["Vocab/Vocab/Views/WordListView.swift", "docs/TASKS.md", "docs/audit-log.md"],
    "word-of-day-lt":      ["Vocab/Vocab/Views/HomeView.swift", "docs/TASKS.md", "docs/audit-log.md"],
    "haptics":             ["Vocab/Vocab/Views/QuizView.swift", "docs/TASKS.md", "docs/audit-log.md"],
    "widget":              ["VocabWidget/", "docs/TASKS.md", "docs/audit-log.md"],
    "tests-wordservice":   ["VocabTests/", "docs/TASKS.md", "docs/audit-log.md"],

    # Data tasks
    "en-words-expansion":  ["data/words.json", "docs/TASKS.md", "docs/audit-log.md"],
    "lt-vocab-initial":    ["data/words_lt.json", "docs/TASKS.md", "docs/audit-log.md"],

    # Product agent tasks — these agents write to docs only
    "requirements-agent":  ["docs/requirements/", "docs/TASKS.md", "GOALS.md", "docs/decisions-pending.md",
                             "docs/decisions-log.md", "docs/audit-log.md", "docs/retrospectives.md"],
    "architecture-agent":  ["docs/architecture/", "docs/ARCHITECTURE.md", "docs/TASKS.md",
                             "docs/decisions-pending.md", "docs/decisions-log.md", "docs/audit-log.md",
                             "docs/retrospectives.md"],
    "verification-agent":  ["docs/verification/", "docs/tech-debt.md", "GOALS.md",
                             "docs/decisions-pending.md", "docs/decisions-log.md", "docs/audit-log.md",
                             "docs/retrospectives.md"],

    # Reflection Agent — can edit all protocol docs and scripts (human reviews before merge)
    "reflection-agent":    ["AGENTS.md", "docs/REQUIREMENTS-AGENT.md", "docs/ARCHITECTURE-AGENT.md",
                             "docs/VERIFICATION-AGENT.md", "docs/REFLECTION-AGENT.md",
                             "docs/VOCAB-AGENT.md", "docs/CONVENTIONS.md", "docs/ARCHITECTURE.md",
                             "docs/REVERSIBILITY.md", "docs/BUILD.md", "docs/WORKTREES.md",
                             "docs/TASKS.md", "docs/process-changelog.md", "docs/retrospectives.md",
                             "docs/audit-log.md", "docs/decisions-pending.md", "docs/decisions-log.md",
                             "scripts/"],

    # Orchestrator (Team Lead) — merges branches, coordinates agents
    "orchestrator":        ["GOALS.md", "docs/TASKS.md", "docs/audit-log.md", "docs/retrospectives.md",
                             "docs/decisions-pending.md", "docs/decisions-log.md"],
}

# Files any agent may always read or minimally append to (never flagged as violations)
ALWAYS_ALLOWED = {
    "docs/audit-log.md",
    "docs/decisions-pending.md",
    "docs/decisions-log.md",
    "docs/retrospectives.md",
}


def get_changed_files() -> list[str]:
    """Return list of files changed (staged + unstaged) relative to HEAD."""
    result = subprocess.run(
        ["git", "diff", "--name-only", "HEAD"],
        capture_output=True, text=True
    )
    files = result.stdout.strip().splitlines()
    # Also include staged changes not yet committed
    result2 = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        capture_output=True, text=True
    )
    files += result2.stdout.strip().splitlines()
    return list(set(f for f in files if f))


def is_allowed(file: str, allowed: list[str]) -> bool:
    if file in ALWAYS_ALLOWED:
        return True
    for pattern in allowed:
        if pattern.endswith("/"):
            if file.startswith(pattern):
                return True
        else:
            if file == pattern:
                return True
    return False


def main():
    parser = argparse.ArgumentParser(description="Check agent file permissions for a task.")
    parser.add_argument("--task", required=True, help="Task ID (e.g. vocab-seeder-en)")
    args = parser.parse_args()

    task_id = args.task
    if task_id not in TASK_PERMISSIONS:
        print(f"WARNING: Unknown task '{task_id}'. No permission rules defined — cannot validate.")
        print("Add this task to TASK_PERMISSIONS in scripts/check_permissions.py")
        sys.exit(1)

    allowed = TASK_PERMISSIONS[task_id]
    changed = get_changed_files()

    if not changed:
        print("No changed files detected.")
        sys.exit(0)

    violations = [f for f in changed if not is_allowed(f, allowed)]

    if violations:
        print(f"PERMISSION VIOLATION for task '{task_id}':")
        print(f"The following files are outside your allowed scope:\n")
        for v in violations:
            print(f"  ✗  {v}")
        print(f"\nAllowed files/prefixes for '{task_id}':")
        for a in allowed:
            print(f"  ✓  {a}")
        print("\nDo NOT commit these changes. If you believe this is correct, update TASK_PERMISSIONS in scripts/check_permissions.py and write a note in docs/decisions-pending.md.")
        sys.exit(1)
    else:
        print(f"✓ All {len(changed)} changed file(s) are within scope for task '{task_id}'.")
        sys.exit(0)


if __name__ == "__main__":
    main()
