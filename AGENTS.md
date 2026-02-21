# AGENTS.md — Start Here

This is the entry point for all AI agents working on this repository.

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

| Goal status | Who acts next | Protocol doc |
|-------------|--------------|-------------|
| `[ ]` | Requirements Agent | [`docs/REQUIREMENTS-AGENT.md`](docs/REQUIREMENTS-AGENT.md) |
| `[requirements-done]` | Architecture Agent | [`docs/ARCHITECTURE-AGENT.md`](docs/ARCHITECTURE-AGENT.md) |
| `[architecture-done]` | Feature Agents | Claim tasks from [`docs/TASKS.md`](docs/TASKS.md) |
| `[needs-verification]` | Verification Agent | [`docs/VERIFICATION-AGENT.md`](docs/VERIFICATION-AGENT.md) |

### Feature Agents (task-driven)
For task-driven work (claimed from `TASKS.md`):

1. **Claim a task** in [`docs/TASKS.md`](docs/TASKS.md): change `[ ]` to `[in-progress: <agent-id>]`.
2. **Read relevant docs** (see index below).
3. **Set up a worktree** — see [`docs/WORKTREES.md`](docs/WORKTREES.md).
4. **Implement** the task. Add or update unit tests covering your changes.
5. **Verify** all tests pass with `xcodebuild test` — see [`docs/BUILD.md`](docs/BUILD.md).
6. **Merge back** into `main`, mark task `[done]` in `TASKS.md`.
7. If last task for a goal: set goal status to `[needs-verification]` in `GOALS.md`.

## Docs Index

| File | Read when... |
|------|-------------|
| [`GOALS.md`](GOALS.md) | You are starting a new session — find what needs doing |
| [`docs/REQUIREMENTS-AGENT.md`](docs/REQUIREMENTS-AGENT.md) | You are the Requirements Agent |
| [`docs/ARCHITECTURE-AGENT.md`](docs/ARCHITECTURE-AGENT.md) | You are the Architecture Agent |
| [`docs/VERIFICATION-AGENT.md`](docs/VERIFICATION-AGENT.md) | You are the Verification Agent |
| [`docs/VOCAB-AGENT.md`](docs/VOCAB-AGENT.md) | You are a vocabulary pipeline agent (Seeder, Enricher, Relations, QA, Publisher) |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | You need to understand the data model, app structure, or design constraints |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | You are writing Swift code or editing JSON word data |
| [`docs/BUILD.md`](docs/BUILD.md) | You need to build, run, or test the app |
| [`docs/WORKTREES.md`](docs/WORKTREES.md) | You are setting up your isolated working environment |
| [`docs/TASKS.md`](docs/TASKS.md) | You are picking up or completing a feature task |
| [`docs/decisions-pending.md`](docs/decisions-pending.md) | You are blocked and need to present options to the human |
| [`docs/tech-debt.md`](docs/tech-debt.md) | You are the Verification Agent recording debt |

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
- Always run tests before merging (see `docs/BUILD.md`).
