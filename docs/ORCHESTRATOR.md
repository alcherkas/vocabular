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

## Step 3: Infinite Main Loop

The orchestrator runs **continuously** until stopped. It cycles through: scan → spawn → monitor → merge → reflect → repeat.

### Graceful Stop

To stop the orchestrator after the current batch completes:
```bash
touch STOP   # create STOP file in repo root
```
The orchestrator checks for this file at the start of each cycle and exits cleanly.

### Work Scanner (Priority Order)

At the start of each cycle, scan for work in this priority order:

| Priority | Source | What to spawn | Max parallel |
|----------|--------|--------------|-------------|
| 1 | `GOALS.md` — goal needs next pipeline stage | Requirements / Architecture / Verification Agent | 1 |
| 2 | `docs/TASKS.md` — unclaimed feature tasks (dependencies met) | Feature Agents | 3 (if different files) |
| 3 | `docs/decisions-pending.md` — human responded | Re-notify / unblock waiting agent | 1 |
| 4 | Staging JSON — stubs needing enrichment | Enricher agents (EN and/or LT) | 2 |
| 5 | Staging JSON — enriched needing relations | Relations agent | 1 |
| 6 | Staging JSON — no more stubs | Seeder agents (add more stubs) | 2 |

**Always fill up to 3–4 parallel agents** per cycle. Mix priorities when possible (e.g., 1 Feature Agent + 1 LT Enricher + 1 EN Enricher).

### The Loop

```
cycle = 0
merges_since_last_reflection = 0

LOOP:
  cycle += 1

  # 0. Check for stop signal
  IF file "STOP" exists in repo root:
    Print "STOP file detected. Finishing after current cycle."
    Remove STOP file
    EXIT after this cycle completes

  # 1. SCAN for work
  work_items = []

  # Priority 1: Goal pipeline
  FOR each goal in GOALS.md:
    IF status == [ ]:                   add (requirements-agent, goal)
    IF status == [requirements-done]:   add (architecture-agent, goal)
    IF status == [architecture-done]:   check TASKS.md for unclaimed tasks → add feature agents
    IF status == [needs-verification]:  add (verification-agent, goal)
    IF status == [verified]:            add (reflection-agent) if not recently run

  # Priority 2: Feature tasks with met dependencies
  FOR each unclaimed task in TASKS.md with "Depends on" satisfied:
    add (feature-agent, task-id)

  # Priority 3: Vocab pipeline
  Count stubs/enriched/relations-added in staging files:
    IF stubs > 0:      add enricher agents (LT and/or EN)
    IF enriched > 0:   add relations agent
    IF stubs == 0 AND total < target: add seeder agents

  # 2. SPAWN batch (max 4 agents from work_items)
  Pick top 4 from work_items (by priority)
  Spawn each as background agent via task tool

  # 3. MONITOR & MERGE
  WHILE any spawned agent is still running:
    Wait 30 seconds
    Check each agent status via read_agent
    IF agent completed successfully:
      Merge its branch to main (resolve conflicts if needed)
      Clean up worktree
      merges_since_last_reflection += 1
      Append merge entry to docs/audit-log.md
    IF agent failed:
      Read error output
      IF retryable: respawn with refined prompt (max 2 retries)
      ELSE: log to decisions-pending.md, continue

  # 4. REFLECTION CHECK
  IF merges_since_last_reflection >= 3:
    Spawn Reflection Agent (background)
    Wait for completion
    Merge reflection branch to main (docs-only)
    merges_since_last_reflection = 0

  # 5. CHECKPOINT (every 5 cycles)
  IF cycle % 5 == 0:
    Print checkpoint summary (see "Context Checkpoint" below)

  # 6. CONTINUE
  GOTO LOOP
```

### Vocab Pipeline — Continuous Progression

The vocab pipeline has enough work to run for hours:

```
LT: 1745 stubs → Enricher (5/batch) → 349 batches → Relations → QA → Publish
EN: 30 stubs → Enricher → Relations → QA → Publish → Seeder adds more → repeat
```

The scanner automatically advances words through the pipeline:
- When stubs exist → spawn Enricher
- When enriched entries exist → spawn Relations agent
- When relations-added entries exist → spawn QA agent
- When approved entries exist → spawn Publisher (with `--confirm`)
- When all stubs are consumed → spawn Seeder to add more

### Dependency Graph (what to spawn next)

```
Requirements Agent completes
  └─► Spawn Architecture Agent
  └─► (if 3+ retros) Spawn Reflection Agent in parallel

Architecture Agent completes
  └─► Spawn Feature Agents (one per unclaimed task, respecting file conflicts)

After each Feature Agent merge batch
  └─► (if 3+ new retros) Spawn Reflection Agent in parallel

All Feature Agents complete
  └─► Set goal to [needs-verification]
  └─► Spawn Verification Agent

Verification Agent completes with [verified]
  └─► Final Reflection Agent cycle (always, regardless of retro count)

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

## Step 5: Context Checkpoint

Copilot CLI sessions have context limits. Every 5 cycles (or when you sense context is getting large), print a checkpoint:

```
═══════════════════════════════════════════
CHECKPOINT — Cycle <N>
═══════════════════════════════════════════

GOALS:
  lt-vocab-app: [architecture-done] → 3/8 feature tasks complete

TASKS COMPLETED THIS SESSION:
  ✅ language-field (merged)
  ✅ haptics (merged)
  ✅ tests-wordservice (merged)

TASKS IN PROGRESS:
  🔄 lt-ui-filter (agent running)

TASKS NEXT UP:
  ⬜ spaced-rep (unblocked, ready)
  ⬜ lt-session-flow (unblocked, ready)

VOCAB PIPELINE:
  LT: 1745 stubs → 1730 stubs, 15 enriched (this session: +15 enriched)
  EN: 0 stubs → 30 stubs (this session: +30 seeded)

REFLECTION:
  Cycles completed: 1
  Retros since last: 2

PENDING DECISIONS: 0

TO CONTINUE: Start a new session and say:
  "You are the team lead. Read docs/ORCHESTRATOR.md.
   Continue from cycle <N>. Last completed: <task-ids>."
═══════════════════════════════════════════
```

### Session Handoff

When starting a new session to continue:
1. The new orchestrator reads `GOALS.md` and `TASKS.md` — status fields tell it exactly where things stand
2. It reads `docs/audit-log.md` for recent activity
3. It runs the Work Scanner — automatically picks up where the previous session left off
4. No manual bookkeeping needed; the repo state IS the checkpoint

---

## Error Handling

| Situation | What to do |
|-----------|-----------|
| Agent returns error (build fail, test fail) | Read error output; retry with more specific prompt including the error message (max 2 retries) |
| Agent writes to `decisions-pending.md` | Notify human; do not spawn dependent agents until resolved |
| Merge conflict | Read both diffs; resolve by preferring the later/more complete change; commit resolution |
| Agent takes too long (no response after 5+ minutes) | Check agent status; if stuck, stop and retry |
| Worktree already exists | Remove stale worktree: `git worktree remove ../vocabular-wt-<id> --force` |
| Two agents claim same task | Only one should proceed; the orchestrator assigns tasks, not agents |
| No more work found by scanner | Print checkpoint, wait 60 seconds, re-scan (human may add goals/tasks) |
| Context getting large | Print checkpoint summary, suggest human start new session |
| Human creates `STOP` file | Finish current batch, print final checkpoint, exit |

---

## Constraints

- Do NOT implement features yourself. You only delegate, monitor, and merge.
- Do NOT skip the dependency order in the Goal Pipeline.
- Do NOT merge a branch without verifying the agent reported success.
- Always append a merge entry to `docs/audit-log.md` after each merge.
- If more than 2 agents fail on the same issue, stop and write to `docs/decisions-pending.md` for human input.
