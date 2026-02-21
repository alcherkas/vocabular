# Git Worktrees

Each agent works in an isolated worktree — a separate directory on the same repo. This allows multiple agents to work in parallel without `git checkout` conflicts.

## Worktree Layout

```
~/Documents/GitHub/
├── vocabular/                  # main integration branch
├── vocabular-wt-en-words/      # EN word extension agent
├── vocabular-wt-lt-vocab/      # LT vocabulary agent
├── vocabular-wt-spaced-rep/    # spaced repetition agent
└── vocabular-wt-<task-id>/     # any other agent
```

## Setup: Create Your Worktree

From the main repo directory:

```bash
# 1. Create a new branch + worktree in one command
git worktree add ../vocabular-wt-<task-id> -b feature/<task-id>

# Example for spaced repetition task:
git worktree add ../vocabular-wt-spaced-rep -b feature/spaced-rep
```

## Work in Your Worktree

```bash
cd ../vocabular-wt-<task-id>

# Make changes, then verify:
# Pick DEVICE from: xcrun simctl list devices available | grep -E "iPhone|iPad"
xcodebuild test \
  -project Vocab/Vocab.xcodeproj \
  -scheme Vocab \
  -destination 'platform=iOS Simulator,name=DEVICE,OS=latest'
```

## Merge Back to Main

```bash
# Switch to main repo
cd ../vocabular

# Merge your branch
git merge feature/<task-id> --no-ff -m "feat(<task-id>): <short description>

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

# Remove worktree after merge
git worktree remove ../vocabular-wt-<task-id>
git branch -d feature/<task-id>
```

## Conflict Resolution

- If `main` has moved forward, rebase your branch before merging:
  ```bash
  cd ../vocabular-wt-<task-id>
  git fetch origin main
  git rebase origin/main
  ```
- For append-only files (`docs/retrospectives.md`, `docs/audit-log.md`, `docs/process-changelog.md`), rebase right before appending; if a conflict occurs, keep both entries and preserve chronological order.
- Word JSON files (`words.json`, `words_lt.json`) are agent-owned — only the designated agent edits them. If two agents both modify the same JSON, the integration lead resolves the conflict manually.

## List Active Worktrees

```bash
git worktree list
```

## Branch Naming

| Pattern | Used for |
|---------|---------|
| `feature/<task-id>` | Any task from `TASKS.md` |
| `fix/<short-description>` | Bug fixes not in task list |
| `data/en-batch-<n>` | EN word data batches |
| `data/lt-batch-<n>` | LT word data batches |
