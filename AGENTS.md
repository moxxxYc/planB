## Project State

This repository is now docs-only. Generated assets, package scripts, validation probes, local project skills, and implementation code were removed on 2026-06-02 because they validated an obsolete direction.

Active files:

- `README.md`
- `docs/gdd.md`
- `docs/PROGRESS.md`
- `AGENTS.md`

## Agent Conduct

要求保持客观公正，不要献媚，不要敷衍。

- Do not invent missing gameplay, implementation, content, or production status.
- Treat `docs/gdd.md` as the canonical formal design.
- Treat `docs/PROGRESS.md` as the recent decision log, not as proof of implementation.
- If a future implementation starts, create a fresh implementation plan from the current GDD instead of reviving deleted implementation assumptions.
- Mark unknowns clearly instead of filling gaps with plausible details.
- Prefer the best long-term project shape over superficial continuity with deleted code.

## Design Boundaries

- The ball machine must remain the main system.
- No PVP, networking, accounts, backend services, matchmaking, or Steam integration inside this repo state.
- Do not make the battle field a free RTS map.
- Do not use complex RTS pathfinding as a core requirement.
- Formal design terms are `Launch`, `Tuning`, and `Unit`.
- Formal Tuning base slots are `Prime`, `Echo`, and `Surge`.
- Formal Gold comes mainly from post-battle settlement.

## Workflow

- For design discussion, update `docs/gdd.md` and `docs/PROGRESS.md`.
- For implementation work, first create a new scoped implementation plan. Do not assume deleted systems still exist.
- There are currently no npm commands, build commands, or automated validation commands in this repo.
