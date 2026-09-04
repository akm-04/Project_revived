# v0.8.5 — Pass 29 P0 Guardrails + Phase-1 Economy Spine

## Scope

Implementation-only expansion of the existing v0.8.4 architecture. No new MID mapping and no ground-up rewrite.

## P0 mutation-safe compatibility boundary

The previous compatibility fallback acknowledged every unmapped ordinary MID with `{}`. That is unsafe because many client callbacks optimistically mutate local state after any successful response.

v0.8.5 changes the rule to:

```text
explicit handler -> normal handler path
unknown MID + explicit audited safe-empty-ack allow-list -> compatibility {}
unknown MID not allow-listed -> error_code=1 local unsupported sentinel
```

The allow-list is `data/compatibility_safe_mids.json`. It is numeric and evidence-backed; no name/payload heuristic is used. The nonzero code is private-server policy and is not claimed to be an official GXB error assignment.

## Phase-1 EconomyRepository

Canonical fields in this phase:

- Mana
- Crystal
- Energy
- cumulative player EXP
- derived player level / max Energy

`apply_deltas()` validates all spends before mutation, snapshots affected scalar state, applies one transaction, rolls back the local snapshot on unexpected failure, and persists at most once when requested. Player EXP remains grant-only; Mana/Crystal/Energy use signed deltas through validated wrappers.

Source-confirmed level-up Energy is preserved. Campaign stamina spending is still unresolved and therefore is **not** added here.

## Response Projector

`gxb_backend/state/response_projector.py` captures the request-bound player before a handler and compares the same canonical player afterward. It merges changed cumulative values into:

```text
economy_: mana, crystal, energy, exp, lev
exps: [{partner_id, exp}, ...]
```

Only changed Phase-1 fields are auto-projected. Existing handler-provided blocks are retained and normalized to current canonical totals. Player-switch/bootstrap requests are not diff-projected. Skill Point is excluded because the known MID90 callback/loading path must not be forced through the global ECONOMY event without stronger evidence.

## Effective-source provenance

`tools/build_campaign_economy_meta.py` now requires an APK `src_64` root and optionally a recovered writable `src_64` root. Each input path is resolved independently:

```text
writable hot-update path if present
else APK baseline path
```

The resulting metadata is stamped `source_resolution=effective_merged`. `EconomyRepository` fails closed if that stamp is absent. For the currently consumed Campaign/player/SelfPlayer inputs, the supplied recovery has no writable override, so the resolved rows are APK-layer rows **through the effective resolver**, not an unlayered baseline assumption.

## Deliberate non-goals

- no new MID semantics;
- no Mission/Shop/Mail/Guild/PvP expansion;
- no Campaign stamina timing guess;
- no Campaign repeat-drop RNG;
- no full 47-field `economy_` implementation;
- no runtime/integration validation by the assistant.

## Validation policy

Static Python compilation and JSON parsing only. No Flask/HTTP, selftests, APK/ADB/emulator, or gameplay execution by the assistant.
