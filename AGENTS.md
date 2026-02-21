# AGENTS.md — Start Here

This is the entry point for all AI agents working on this repository.

## Agent Protocol

1. **Read this file** to understand the repo and protocol.
2. **Claim a task** in [`docs/TASKS.md`](docs/TASKS.md): change `[ ]` to `[in-progress: <agent-id>]`.
3. **Read relevant docs** for your task (see index below).
4. **Set up a worktree** — see [`docs/WORKTREES.md`](docs/WORKTREES.md).
5. **Implement** the task in your worktree. Add or update unit tests covering your changes (see [`docs/BUILD.md`](docs/BUILD.md) for test conventions).
6. **Verify** all tests pass with `xcodebuild test` — see [`docs/BUILD.md`](docs/BUILD.md).
7. **Merge back** into `main` and mark task `[done]` in `TASKS.md`.

## Docs Index

| File | Read when... |
|------|-------------|
| [`docs/VOCAB-AGENT.md`](docs/VOCAB-AGENT.md) | You are running a continuous vocabulary pipeline agent (Seeder, Enricher, Relations, QA, or Publisher) |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | You need to understand the data model, app structure, or design constraints |
| [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) | You are writing Swift code or editing JSON word data |
| [`docs/BUILD.md`](docs/BUILD.md) | You need to build, run, or test the app |
| [`docs/WORKTREES.md`](docs/WORKTREES.md) | You are setting up your isolated working environment |
| [`docs/TASKS.md`](docs/TASKS.md) | You are picking up or completing a task |

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
