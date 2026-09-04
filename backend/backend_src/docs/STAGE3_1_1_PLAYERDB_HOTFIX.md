# Stage 3.1.1 — player DB hero-section hotfix

Date: 2026-08-16

## Live regression

Stage 3.1 reached `RETRIEVE_TOKEN` (MID 1) and `ALBUM_SPECIAL_COLLECT_INFO`
(MID 2784), then stopped before the previously proven `GET_BOARD_INFO` / MainScene
fanout.

The live MID1 payload exposed the regression directly:

```text
Stage 3 working:
detail["49"].heros = { "10001": {hero record...} }

Stage 3.1 broken:
detail["49"].heros = {
  "heroes": { "10001": {hero record...} },
  "collected_heros": ...,
  "hero_pieces": ...,
  "formation": ...
}
```

## Root cause

The human-editable JSON schema uses a section named `player.heroes`, while
`PlayerState` also owns a field named `heroes`.

`JsonPlayerDatabase.load()` checked `PLAYER_FIELD_NAMES` before organizational
section names, so the entire `player.heroes` section was assigned to
`PlayerState.heroes`.

Lua `Player:herosEvent_()` iterates `params.heros` and treats **every value** as a
hero record. The extra `heroes`, `collected_heros`, `formation`, etc. values are
therefore invalid bootstrap objects.

## Fix

- Nested database section names are now recognized before legacy flat fields.
- `heroes_payload()` defensively unwraps one accidental `heroes` layer.
- The JSON database format and editable values remain unchanged.
- The established `guide_id=101001` experiment remains enabled; Stage 3.1 never
  reached MainScene far enough to test that change because MID49 aborted first.

## Validation

Only Python syntax compilation is performed for handoff. No Flask/APK runtime
smoke test is run in this environment.
