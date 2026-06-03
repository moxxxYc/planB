# planB

Docs-only repository for a ball-machine-driven auto-battle roguelite design.

As of 2026-06-02, this repo keeps only accepted design documentation. There is no runnable app, package script, source tree, generated asset set, or automated validation suite.

## Current Docs

- `docs/gdd.md`: canonical formal design decisions.
- `docs/PROGRESS.md`: recent decision and cleanup history.
- `AGENTS.md`: collaboration and documentation rules for future work in this repo.

## Project Intent

The player starts with an unstable physical spawning machine, then gradually shapes it into a stable war engine through rewards, slot tuning, race mechanics, enemy pressure, and machine-shop decisions.

The ball machine remains the main system. Buildings, relics, race mechanics, economy, and enemies must support the machine instead of replacing it.

## Current State

- No active implementation code remains.
- No validation scripts remain.
- Formal design language uses `Launch / Tuning / Unit`, with Tuning built around `Prime / Echo / Surge`.
