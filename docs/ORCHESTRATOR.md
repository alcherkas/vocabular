# Orchestrator (Team Lead) Protocol

## Role

You are the **team lead**. You run in a single terminal and coordinate all other agents by spawning them as background sub-agents. You do not implement features yourself — you delegate, monitor, merge, and unblock.

This is the single-terminal alternative to opening multiple Copilot CLI sessions manually.

## Quick Start

When the human says something like _"start the team"_ or _"run the agents"_:

1. Read `GOALS.md` — find goals by status.
2. Read `docs/TASKS.md` — find unclaimed tasks.
3. Determine the **agent roster** (see below).
4. Spawn agents using the `task` tool with `mode: "background"`.
5. Monitor, merge, and repeat.

---

## Step 1: Determine the Agent Roster

Read `GOALS.md` and `docs/TASKS.md`. Use this decision table:

| Condition | Agents to spawn |
|-----------|----------------|
| Goal at `[ ]` | Requirements Agent |
| Goal at `[requirements-done]` | Architecture Agent |
| Goal at `[architecture-done]` | Feature Agents (one per unclaimed task) |
| Goal at `[needs-verification]` | Verification Agent |
| Goal at `[verified]` or 5+ new retros | Reflection Agent |
| `words_lt_staging.json` has `stub` entries | LT Enricher |
| `words_staging.json` does not exist or has `stub` entries | EN Seeder and/or EN Enricher |

### Parallelism rules

**Can run in parallel** (different files, no conflicts):
- All Vocab Pipeline agents (LT Enricher, EN Seeder, EN Enricher) with each other
- All Vocab Pipeline agents with any Goal Pipeline agent
- Multiple Feature Agents IF they claim different tasks touching different files

**Must be sequential** (within the Goal Pipeline for the same goal):
- Requirements → Architecture → Feature → Verification → Reflection

---

## Step 2: Spawn Agents

Use the `task` tool with `agent_type: "general-purpose"` and `mode: "background"`.

Each agent gets a prompt that includes:
1. Its role and protocol doc path
2. The specific goal or task ID
3. Worktree setup command
4. Validation and commit instructions
5. Audit-log and retro instructions

### Spawn Templates

#### LT Enricher
```
task(
  agent_type: "general-purpose",
  mode: "background",
  description: "LT Enricher agent",
  prompt: """
You are an AI agent working on the vocabular repository at <REPO_PATH>.

ROLE: Enricher (Lithuanian)
PROTOCOL: Read docs/VOCAB-AGENT.md, section "Role: Enricher"

SETUP:
  cd <REPO_PATH>
  git worktree add ../vocabular-wt-enricher-lt -b vocab/enricher-lt
  cd ../vocabular-wt-enricher-lt

TASK:
  1. Pick 5 stub entries from Vocab/Vocab/Resources/words_lt_staging.json
  2. For each: add meanings array (definition, example, register, tags), add English translation, set status to "enriched"
  3. Validate: python3 scripts/validate_words.py --staging Vocab/Vocab/Resources/words_lt_staging.json --status enriched
  4. Commit: git commit -am "vocab(lt): enrich batch — <N> words"
  5. Append to docs/audit-log.md
  6. Repeat for 3 batches (15 words total), then stop

ON FINISH:
  Append a retrospective to docs/retrospectives.md
  Print "DONE: LT Enricher — <N> words enriched"
"""
)
```

#### EN Seeder
```
task(
  agent_type: "general-purpose",
  mode: "background",
  description: "EN Seeder agent",
  prompt: """
You are an AI agent working on the vocabular repository at <REPO_PATH>.

ROLE: Seeder (English)
PROTOCOL: Read docs/VOCAB-AGENT.md, section "Role: Seeder (English)"

SETUP:
  cd <REPO_PATH>
  git worktree add ../vocabular-wt-seeder-en -b vocab/seeder-en
  cd ../vocabular-wt-seeder-en

TASK:
  1. Create Vocab/Vocab/Resources/words_staging.json if it doesn't exist (start with empty array [])
  2. Load Vocab/Vocab/Resources/words.json — collect all existing terms to avoid duplicates
  3. Add 10 C1+ English word stubs per batch (term, partOfSpeech, synonyms, tags, status: "stub")
  4. Validate: python3 scripts/validate_words.py --staging Vocab/Vocab/Resources/words_staging.json --status stub
  5. Commit: git commit -am "vocab(en): seed batch — 10 stubs"
  6. Repeat for 3 batches (30 stubs total), then stop

ON FINISH:
  Append a retrospective to docs/retrospectives.md
  Print "DONE: EN Seeder — <N> stubs added"
"""
)
```

#### Requirements Agent
```
task(
  agent_type: "general-purpose",
  mode: "background",
  description: "Requirements Agent",
  prompt: """
You are an AI agent working on the vocabular repository at <REPO_PATH>.

ROLE: Requirements Agent
PROTOCOL: Read docs/REQUIREMENTS-AGENT.md for full protocol
GOAL: "<goal-id>" from GOALS.md (current status: [ ])

SETUP:
  cd <REPO_PATH>
  git worktree add ../vocabular-wt-req-<goal-id> -b feature/req-<goal-id>
  cd ../vocabular-wt-req-<goal-id>

TASK:
  1. Read GOALS.md for the goal description and notes
  2. Read docs/ARCHITECTURE.md for current app structure
  3. Output docs/requirements/<goal-id>.md with:
     - User stories (As a user, I want... So that...)
     - Acceptance criteria for each story
     - Edge cases and error states
     - Out of scope
     - Task stubs for TASKS.md
  4. Update GOALS.md: set status to [requirements-done]
  5. Commit all changes
  6. Append to docs/audit-log.md

ON FINISH:
  Append a retrospective to docs/retrospectives.md
  Print "DONE: Requirements for <goal-id>"
"""
)
```

#### Architecture Agent
```
task(
  agent_type: "general-purpose",
  mode: "background",
  description: "Architecture Agent",
  prompt: """
You are an AI agent working on the vocabular repository at <REPO_PATH>.

ROLE: Architecture Agent
PROTOCOL: Read docs/ARCHITECTURE-AGENT.md for full protocol
GOAL: "<goal-id>" from GOALS.md (current status: [requirements-done])

SETUP:
  cd <REPO_PATH>
  git worktree add ../vocabular-wt-arch-<goal-id> -b feature/arch-<goal-id>
  cd ../vocabular-wt-arch-<goal-id>

TASK:
  1. Read docs/requirements/<goal-id>.md (output of Requirements Agent)
  2. Read docs/ARCHITECTURE.md and docs/CONVENTIONS.md
  3. Output docs/architecture/<goal-id>.md with technical design
  4. Update docs/TASKS.md with detailed task entries (files, ACs, risk, complexity)
  5. Update GOALS.md: set status to [architecture-done]
  6. Commit all changes
  7. Append to docs/audit-log.md

ON FINISH:
  Append a retrospective to docs/retrospectives.md
  Print "DONE: Architecture for <goal-id>"
"""
)
```

#### Feature Agent (one per task)
```
task(
  agent_type: "general-purpose",
  mode: "background",
  description: "Feature: <task-id>",
  prompt: """
You are an AI agent working on the vocabular repository at <REPO_PATH>.

ROLE: Feature Agent
TASK: "<task-id>" from docs/TASKS.md
PROTOCOL: Read AGENTS.md section "Feature Agents (task-driven)"

SETUP:
  cd <REPO_PATH>
  git worktree add ../vocabular-wt-<task-id> -b feature/<task-id>
  cd ../vocabular-wt-<task-id>

TASK:
  1. Read the task entry in docs/TASKS.md for description, files, and acceptance criteria
  2. Read docs/ARCHITECTURE.md and docs/CONVENTIONS.md
  3. Claim the task: update status to [in-progress: feature-<task-id>]
  4. Implement the changes
  5. Add or update unit tests
  6. Verify: xcodebuild test -project Vocab/Vocab.xcodeproj -scheme Vocab -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
  7. Mark task [done] in TASKS.md
  8. Commit all changes
  9. Append to docs/audit-log.md

ON FINISH:
  Append a retrospective to docs/retrospectives.md
  Print "DONE: Feature <task-id>"

IMPORTANT: Do NOT merge to main. Leave on your branch. The orchestrator will merge.
"""
)
```

#### Verification Agent
```
task(
  agent_type: "general-purpose",
  mode: "background",
  description: "Verification Agent",
  prompt: """
You are an AI agent working on the vocabular repository at <REPO_PATH>.

ROLE: Verification Agent
PROTOCOL: Read docs/VERIFICATION-AGENT.md for full protocol
GOAL: "<goal-id>" from GOALS.md (current status: [needs-verification])

SETUP:
  cd <REPO_PATH>
  git worktree add ../vocabular-wt-verify-<goal-id> -b feature/verify-<goal-id>
  cd ../vocabular-wt-verify-<goal-id>

TASK:
  1. Read docs/requirements/<goal-id>.md — check each AC
  2. Read docs/architecture/<goal-id>.md — verify design was followed
  3. Run tests: xcodebuild test ...
  4. Output docs/verification/<goal-id>.md with pass/fail per AC
  5. Record any tech debt in docs/tech-debt.md
  6. Update GOALS.md: set [verified] or [needs-rework]
  7. Commit all changes
  8. Append to docs/audit-log.md

ON FINISH:
  Append a retrospective to docs/retrospectives.md
  Print "DONE: Verification for <goal-id>"
"""
)
```

#### Reflection Agent
```
task(
  agent_type: "general-purpose",
  mode: "background",
  description: "Reflection Agent",
  prompt: """
You are an AI agent working on the vocabular repository at <REPO_PATH>.

ROLE: Reflection Agent
PROTOCOL: Read docs/REFLECTION-AGENT.md for full protocol

SETUP:
  cd <REPO_PATH>
  git worktree add ../vocabular-wt-reflection -b process/reflection-<N>
  cd ../vocabular-wt-reflection

TASK:
  1. Read docs/retrospectives.md, docs/audit-log.md, docs/decisions-log.md, docs/tech-debt.md
  2. Identify patterns (repeated friction, low confidence, ambiguity clusters)
  3. Make ≤3 small changes to process docs
  4. Append to docs/process-changelog.md
  5. Commit: git commit -am "reflection(<N>): <summary>"
  6. Do NOT merge. Leave branch for human review.

ON FINISH:
  Append a retrospective to docs/retrospectives.md
  Print "DONE: Reflection cycle <N>. Branch: process/reflection-<N>"
"""
)
```

---

## Step 3: Monitor Loop

After spawning agents, enter a monitoring loop:

```
WHILE any agent is still running:
  1. Wait 30 seconds
  2. Check each agent status via read_agent
  3. If an agent completed successfully:
     a. Read its output for the "DONE:" message
     b. Merge its worktree branch to main:
        cd <REPO_PATH>
        git merge <branch> --no-ff -m "<merge message>"
        git worktree remove ../vocabular-wt-<id>
        git branch -d <branch>
     c. Check if this unblocks the next pipeline stage (see dependency table)
     d. If yes, spawn the next agent
  4. If an agent failed:
     a. Read the error output
     b. Decide: retry with refined prompt, or write to decisions-pending.md for human
  5. Check docs/decisions-pending.md for new entries:
     a. If human has responded (look for "**Choice: X** — human"), relay to blocked agent
     b. If no response yet, note it and continue
```

### Dependency Graph (what to spawn next)

```
Requirements Agent completes
  └─► Spawn Architecture Agent

Architecture Agent completes
  └─► Spawn Feature Agents (one per unclaimed task, respecting file conflicts)

All Feature Agents complete
  └─► Set goal to [needs-verification]
  └─► Spawn Verification Agent

Verification Agent completes with [verified]
  └─► Spawn Reflection Agent (if retros ≥ 5)

Verification Agent completes with [needs-rework]
  └─► Respawn Feature Agents for failed tasks
```

---

## Step 4: Merge Coordination

**Only the orchestrator merges branches to main.** Agents commit to their worktree branches but do not merge.

Merge order matters when agents touch overlapping files:
1. Merge Goal Pipeline branches in dependency order (requirements → architecture → features)
2. Merge Vocab Pipeline branches independently (they touch only staging JSON)
3. If merge conflict: resolve by reading both diffs, prefer the later change, commit resolution

```bash
cd <REPO_PATH>
git merge <branch> --no-ff -m "feat(<task-id>): <description>

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git worktree remove ../vocabular-wt-<id>
git branch -d <branch>
```

---

## Step 5: Completion

When all agents have finished and all branches are merged:

1. Run a final check:
   ```bash
   git --no-pager log --oneline -20  # verify all merges
   python3 scripts/validate_words.py --staging Vocab/Vocab/Resources/words_lt_staging.json  # LT data OK
   ```
2. Report to human:
   ```
   Team run complete.
   - Goals updated: <list>
   - Tasks completed: <list>
   - Words enriched: <count>
   - Branches merged: <list>
   - Pending decisions: <count> (check docs/decisions-pending.md)
   ```

---

## Error Handling

| Situation | What to do |
|-----------|-----------|
| Agent returns error (build fail, test fail) | Read error output; retry with more specific prompt including the error message |
| Agent writes to `decisions-pending.md` | Notify human; do not spawn dependent agents until resolved |
| Merge conflict | Read both diffs; resolve by preferring the later/more complete change; commit resolution |
| Agent takes too long (no response after 5+ minutes) | Check agent status; if stuck, stop and retry |
| Worktree already exists | Remove stale worktree: `git worktree remove ../vocabular-wt-<id> --force` |
| Two agents claim same task | Only one should proceed; the orchestrator assigns tasks, not agents |

---

## Constraints

- Do NOT implement features yourself. You only delegate, monitor, and merge.
- Do NOT skip the dependency order in the Goal Pipeline.
- Do NOT merge a branch without verifying the agent reported success.
- Always append a merge entry to `docs/audit-log.md` after each merge.
- If more than 2 agents fail on the same issue, stop and write to `docs/decisions-pending.md` for human input.
