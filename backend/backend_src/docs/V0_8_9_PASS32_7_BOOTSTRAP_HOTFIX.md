# v0.8.9 / Pass 32.7 — Fresh-Player Bootstrap Hotfix

Pass 32.7 is a maintenance revision under planning Pass 32. It preserves the Pass 32.6 shared catalog/RequestServices/UnitOfWork/reward/function-state architecture and changes no gameplay protocol semantics.

## User-runtime-confirmed failure

The Pass 32.6 build successfully reached SDK registration/login, then MID1 `RETRIEVE_TOKEN` returned HTTP 500 while `MultiUserDatabase.create_fresh_player()` normalized tutorial summon state. The traceback terminates in `SummonRepository._hero_repo()` with:

`AttributeError: 'SummonRepository' object has no attribute 'save_callback'. Did you mean: '_save_callback'?`

## Root cause

Pass 32.6 extended `SummonRepository` to accept an injected shared `HeroRepository`. Its fallback `_hero_repo()` constructor path was changed from the old no-callback construction to a callback-aware construction, but referenced `self.save_callback`. The constructor stores the callback as `self._save_callback`. Fresh-player normalization constructs `SummonRepository(player, data_dir)` without injected heroes, so that fallback path executes before request-scoped `RequestServices` exists.

## Fix

`SummonRepository._hero_repo()` now passes `self._save_callback` to `HeroRepository`. No response shape, MID, reward, tutorial gate, RNG, stamina, mission chain, compatibility allow-list, or source-derived metadata changed.

## Validation boundary

Static/syntax/AST/JSON/archive validation only. No Flask/HTTP/selftest/ADB/emulator/gameplay execution was performed by the assistant. User runtime remains authoritative.
