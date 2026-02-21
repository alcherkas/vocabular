# AGENTS.md — Start Here

This is the entry point for all AI agents working on this repository.

## Orchestrator Mode (Recommended)

Run all agents from a **single terminal**. One session acts as team lead, spawning and coordinating all other agents automatically.

```
You are the team lead. Read docs/ORCHESTRATOR.md and start the agent team.
```

See [`docs/ORCHESTRATOR.md`](docs/ORCHESTRATOR.md) for the full protocol: agent roster, spawn templates, dependency graph, monitoring loop, and merge coordination.

## Agent Protocol

### Product Development Agents (goal-driven)
For goal-driven work (new features, improvements):

1. **Read this file**, then read [`GOALS.md`](GOALS.md) to find work.
2. **Pick the agent role** that matches the current goal status (see table below).
3. **Read the protocol doc** for your role.
4. **Set up a worktree** — see [`docs/WORKTREES.md`](docs/WORKTREES.md).
5. **Do your role's work**, committing in small batches.
6. **If in doubt** — write options to [`docs/decisions-pending.md`](docs/decisions-pending.md), stop, wait for human.
7. **Update goal status** in `GOALS.md` when done.
8. **Write a retrospective** — append to [`docs/retrospectives.md`](docs/retrospectives.md) (see format there).

| Goal status | Who acts next | Protocol doc |
|-------------|--------------|-------------|
| `[ ]` | Requirements Agent | [`docs/REQUIREMENTS-AGENT.md`](docs/REQUIREMENTS-AGENT.md) |
| `[requirements-done]` | Architecture Agent | [`docs/ARCHITECTURE-AGENT.md`](docs/ARCHITECTURE-AGENT.md) |
| `[architecture-done]` | Feature Agents | Claim tasks from [`docs/TASKS.md`](docs/TASKS.md) |
| `[needs-verification]` | Verification Agent | [`docs/VERIFICATION-AGENT.md`](docs/VERIFICATION-AGENT.md) |
| `[verified]` | Reflection Agent | [`docs/REFLECTION-AGENT.md`](docs/REFLECTION-AGENT.md) (also triggers on 5+ new retros) |

### Feature Agents (task-driven)
For task-driven work (claimed from `TASKS.md`):

1. **Claim a task** in [`docs/TASKS.md`](docs/TASKS.md): change `[ ]` to `[in-progress: <agent-id>]`.
2. **Read relevant docs** (see index below).
3. **Set up a worktree** — see [`docs/WORKTREES.md`](docs/WORKTREES.md).
4. **Implement** the task. Add or update unit tests covering your changes.
5. **Verify** all tests pass with `xcodebuild test` — see [`docs/BUILD.md`](docs/BUILD.md).
6. **Merge back** into `main`, mark task `[done]` in `TASKS.md`.
7. If last task for a goal: set goal status to `[needs-verification]` in `GOALS.md`.
8. **Write a retrospective** — append to [`docs/retrospectives.md`](docs/retrospectives.md) (see format there).

## Docs Index

| File | Read when... |
|------|-------------|
| [`GOALS.md`](GOALS.md) | You are starting a new session — find what needs doing |
| [`docs/ORCHESTRATOR.md`](docs/ORCHESTRATOR.md) | You are the team lead running all agents from one terminal |
| [`docs/REQUIREMENTS-AGENT.md`](docs/REQUIREMENTS-AGENT.md) | You are the Requirements Agent |
| [`docs/ARCHITECTURE-AGENT.md`](docs/ARCHITECTURE-AGENT.md) | You are the Architecture Agent |
| [`docs/VERIFICATION-AGENT.md`](docs/VERIFICATION-AGENT.md) | You are the Verification Agent |
| [`docs/REFLECTION-AGENT.md`](docs/REFLECTION-AGENT.md) | You are the Reflection Agent (process improvement) |
| [`docs/VOCAB-AGENT.md`](docs/VOCAB-AGENT.md) | You are a vocabulary pipeline agent (Seeder, Enricher, Relations, QA, Publisher) |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | You need to understand the data model, app structure, or design constraints |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | You are writing Swift code or editing JSON word data |
| [`docs/BUILD.md`](docs/BUILD.md) | You need to build, run, or test the app |
| [`docs/WORKTREES.md`](docs/WORKTREES.md) | You are setting up your isolated working environment |
| [`docs/TASKS.md`](docs/TASKS.md) | You are picking up or completing a feature task |
| [`docs/decisions-pending.md`](docs/decisions-pending.md) | You are blocked and need to present options to the human |
| [`docs/tech-debt.md`](docs/tech-debt.md) | You are the Verification Agent recording debt |
| [`docs/REVERSIBILITY.md`](docs/REVERSIBILITY.md) | You are about to take an action that modifies shared state |
| [`docs/audit-log.md`](docs/audit-log.md) | You have just merged or taken an irreversible action |
| [`docs/retrospectives.md`](docs/retrospectives.md) | You are finishing an iteration (all agents write retros) |
| [`docs/process-changelog.md`](docs/process-changelog.md) | You are the Reflection Agent recording process changes |

## Repo at a Glance

- **App**: iOS vocabulary learning app (SwiftUI + SwiftData, iOS 26)
- **Language support**: English C1+ (`en`) and Lithuanian basic (`lt`)
- **Offline-first**: no network calls, all data bundled in JSON
- **Project file**: `Vocab/Vocab.xcodeproj`
- **Source root**: `Vocab/Vocab/`

## Hard Rules

- Do NOT edit `words.json` directly — it is managed by the **EN word extension agent** only.
- Do NOT edit `words_lt.json` directly — managed by the **LT vocabulary agent** only.
- Do NOT rename or move existing model files without updating all references.
- Do NOT add external dependencies (no SPM packages) without a decision recorded in `DECISIONS.md`.
- For tasks with explicit numeric targets (e.g., "add 100 words", "create 200 entries"), verify the final count before commit.
- Always run tests before merging (see `docs/BUILD.md`).
- Always append to `docs/audit-log.md` after merging or taking any irreversible action.
- Read `docs/REVERSIBILITY.md` before any action that modifies shared state on `main`.

## When to Stop (Uncertainty Protocol)

Stop and write to `docs/decisions-pending.md` if you encounter **any** of the following:

| Situation | Do this |
|-----------|--------|
| You don't understand what the task is asking | Write options to `decisions-pending.md`, stop |
| You're about to modify a file outside your task scope | Stop — do not proceed |
| You're not sure whether your code is correct | Stop at < 90% confidence — write to `decisions-pending.md` |
| Tests are failing and you don't know why | Stop — do not merge |
| You're about to take an irreversible action at < 90% confidence | Stop — write to `decisions-pending.md` |
| The task conflicts with existing code in a non-obvious way | Stop — present the conflict in `decisions-pending.md` |

**Do not guess silently.** Stopping is a feature, not a failure.

## File Ownership (Permission Matrix)

Each agent may only write to files in its designated scope.
Verify your scope before modifying any file.

| File / Path | Owner | Other agents |
|-------------|-------|-------------|
| `GOALS.md` | Human | Read-only |
| `docs/TASKS.md` | Requirements Agent, Architecture Agent | Feature agents update status only |
| `docs/requirements/<id>.md` | Requirements Agent | Read-only |
| `docs/architecture/<id>.md` | Architecture Agent | Read-only |
| `docs/verification/<id>.md` | Verification Agent | Read-only |
| `docs/ARCHITECTURE.md` | Architecture Agent | Read-only |
| `docs/tech-debt.md` | Verification Agent (append) | Read-only |
| `docs/retrospectives.md` | **All agents** (append-only) | Append only |
| `docs/process-changelog.md` | Reflection Agent (append) | Read-only |
| `docs/audit-log.md` | **All agents** (append-only) | Append only |
| `docs/decisions-pending.md` | **All agents** (append) | Human resolves |
| `docs/decisions-log.md` | All agents (move resolved entries) | — |
| `Vocab/Vocab/Resources/words_staging.json` | EN vocab agents only | — |
| `Vocab/Vocab/Resources/words_lt_staging.json` | LT vocab agents only | — |
| `Vocab/Vocab/Resources/words.json` | Publisher agent only | Read-only |
| `Vocab/Vocab/Resources/words_lt.json` | Publisher agent only | Read-only |
| `Vocab/Vocab/Models/Word.swift` | Feature agents (per task) | Must not edit unless task claims it |
| `Vocab/Vocab/Services/WordService.swift` | Feature agents (per task) | Must not edit unless task claims it |
| All other Swift source files | Feature agents (per claimed task) | Must not edit outside claimed task |

Run `python3 scripts/check_permissions.py --task <task-id>` before committing to verify you haven't touched out-of-scope files.

## Safeguards in This Repo

This table maps Anthropic's 11 safeguard types to what's implemented here. Use it to understand what's protecting you — and what isn't.

| Safeguard type | Status | Where |
|---------------|--------|-------|
| **Change tracking and reversion** | ✅ Present | Git history; all changes reversible via `git revert` |
| **Scoped permissions** | ✅ Present | File ownership table above + `scripts/check_permissions.py` |
| **Human approval required** | ✅ Present | `docs/decisions-pending.md`; `[risk: high]` tasks require human diff review |
| **Human escalation pathways** | ✅ Present | `decisions-pending.md` + `[blocked: decision-pending]` goal status |
| **Sandboxed execution** | ⚠️ Partial | Git worktrees isolate branches; no OS-level sandbox |
| **Domain/network restrictions** | ❌ Absent | No network restrictions enforced |
| **AI supervision** | ❌ Absent | No monitor/guardian model watching agent outputs |
| **Rate limits** | ❌ Absent | No throttling on how fast agents commit |
| **Execution timeouts** | ❌ Absent | No time bounds on agent sessions |
| **Resource quotas** | ❌ Absent | No storage or compute caps |
| **No clear guardrails** | ❌ N/A | Guardrails exist (see ✅ rows above) |

The three absent safeguards (AI supervision, rate limits, timeouts) are the main gaps for future hardening.

## Human vs Automated Input (Critical)

**`docs/decisions-pending.md` is written by both agents and humans.**

Rules:
- An entry with **only** options A/B/C is written by an **agent** — this does NOT unblock you.
- An entry with `**Choice: X** — human` or any natural-language follow-up is written by a **human** — this unblocks the waiting agent.
- If you are unsure whether a response came from a human, **treat it as not a human response** and do not unblock yourself.

This distinction matters because multiple agents may read `decisions-pending.md` and could mistakenly resume work based on another agent's write.

## Ambiguity Classification (for decisions-pending.md)

When stopping to write to `decisions-pending.md`, classify the ambiguity type. This tells the human exactly what kind of input is needed:

| Ambiguity type | What it means | Human needs to provide |
|---------------|--------------|----------------------|
| `clear-instructions` | You understand the task but hit an error or bug | A fix or diagnosis, not a decision |
| `implementation-choices` | Multiple valid technical approaches exist | A preference between specific options |
| `vague-requirements` | The spec is unclear or underspecified | Clarification of what's expected |
| `open-ended-task` | No clear success criteria defined | A definition of what "done" looks like |

Include the ambiguity type in your `decisions-pending.md` entry (see format in each agent doc).

---

## Retro — vocab/relations-12 (relations agent run)

**Date:** $(date -u +"%Y-%m-%d")
**Branch:** vocab/relations-12
**Commit:** 9aeb0e0

### What was done
- Preflight JSON validation on both `words_staging.json` and `words_lt_staging.json` — both valid JSON; pre-existing empty-POS issues noted in unrelated stub entries (not touched).
- Selected the first 35 `enriched` entries from each file as targets.
- **EN (`words_staging.json`):** 18 of 35 entries had missing `antonymTerms` or `synonyms`; all gaps filled. All 35 status → `relations-added`.
- **LT (`words_lt_staging.json`):** 7 of 35 entries had missing `synonyms` or `antonymTerms`; all gaps filled. All 35 status → `relations-added`.
- Post-update validation confirmed all 35 new `relations-added` entries in both files have non-empty `synonyms`, `antonymTerms`, and `relatedTerms`.

### Stats
| File | New relations-added | Pre-existing relations-added | Total |
|------|--------------------|-----------------------------|-------|
| words_staging.json | 35 | 1 | 36 |
| words_lt_staging.json | 35 | 35 | 70 |

### Issues / notes
- Pre-existing `relations-added` entries in `words_lt_staging.json` (9 entries) already had empty fields before this run — not modified, not our scope.
- For technical terms with no true linguistic antonym (cartographic instruments, meteorological phenomena), conceptually contrasting domain terms were used as `antonymTerms`, consistent with the existing file conventions (`cumulonimbus`→`stratus`, `bathymetry`→`topography`).

---

## Session retro — vocab/relations-16 (batch 2)

**Date:** 2026-02-21
**Branch:** vocab/relations-16
**Commit:** 26abce0

### What was done
- Preflight JSON validation on both `words_lt_staging.json` and `words_staging.json` — both PASSED with exit 0; all pre-existing warnings are on `approved` entries outside scope.
- Selected the first 35 `enriched` entries from each file as the promotion targets.
- **LT (`words_lt_staging.json`):** 35 entries promoted. Applied qaNote-guided synonym fixes to 5 entries:
  - `senelė`: replaced `tėvo motina` (paternal-only, semantically inaccurate) with `močiutė` (general grandmother).
  - `sėdėti`: added `sėdinėti` (iterative/habitual form) as required second synonym.
  - `mėgti`: added `patikti` (to please/be pleasing) as second synonym — both translate as "to like".
  - `susipažinti`: added `susitikti` (to meet) as second synonym, closest available option after `pažinti` was previously excluded.
  - `jauna`: added `jaunutis` (nominative masc dict form, emphatic "young") as second synonym, consistent with existing `jaunatviškas` being in masculine dict form.
  - All other 30 adjective/verb entries had complete, valid relations; status promoted without modification.
- **EN (`words_staging.json`):** 35 entries promoted (17 medicine/pharmacology + 18 law terms). All carried ≥ 2 synonyms, valid `antonymTerms` and `relatedTerms` from prior enrichment; no edits needed.
- Post-promotion validation: both files pass `--errors-for relations-added` (exit 0).

### Stats
| File | Newly promoted | Pre-existing relations-added | Total relations-added |
|------|---------------|------------------------------|-----------------------|
| words_lt_staging.json | 35 | 35 | 70 |
| words_staging.json | 35 | 35 | 70 |

### Issues / notes
- Rule (1) self-reference: confirmed none of the 70 promoted entries contain their own term in synonyms/antonymTerms/relatedTerms.
- Rule (2) LT nominative forms: no `-ą` or `-ų` endings introduced; `sėdint` in the phrase `ilsėtis sėdint` (adverbial participle, ends in `-t`) does not violate the rule.
- Rule (3) semantic accuracy: `tėvo motina` was the only synonym flagged as semantically inaccurate (paternal-only gloss for a gender-neutral headword); replaced with `močiutė`.
- EN entries with duplicate antonym↔relatedTerms (e.g., `pharmacokinetics`/`pharmacodynamics`) were left as-is — the validator does not flag cross-field overlap and prior enrichment intentionally cross-linked these complementary concepts.
