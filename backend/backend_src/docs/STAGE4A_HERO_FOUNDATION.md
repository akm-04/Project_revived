# Stage 4A — canonical Girls/Hero state

Stage 4A is the first post-lobby gameplay slice. Its goal is deliberately narrow:
make the Girls/Hero list consume one coherent persisted roster, and establish the
save/sync primitive that later summon, formation, campaign rewards, and hero
progression will reuse.

## Why Girls could fail without a new MID49

`MainSceneBottomWindow` calls `SelfPlayer:loadHeros()` before opening `hero_list`.
The login bootstrap already hydrates MID49, so `Player.herosLoaded_` is true and
`loadHeros()` immediately calls its success callback without sending another
network request.

`HeroListWindow.ctor()` then runs, before layout:

```lua
self.teams = selfPlayer:getSaveTeams()
```

`SelfPlayer:getSaveTeams()` parses `save_team`, `save_team_name`, and `save_pet`
with `xyd.split` / `string.split`. Stage 3 serialized those fields as JSON
objects (`{}`), but the source contract is **serialized strings**. A synchronous
client error here explains a Girls click that produces no new MID.

Safe empty values are:

```json
"save_team": "",
"save_team_name": "",
"save_pet": ""
```

The Stage 4A database loader automatically migrates legacy non-string values to
those empty strings and atomically rewrites the player JSON.

## Canonical hero identifiers

Do not conflate these IDs:

- `table_id`: source/content ID used by client tables (example starter `10001001`).
- `partner_id`: owned local entity ID used to identify this particular copy of a girl.
- `player_id`: owner account/game-player ID.

The bundled established profile already owns one source-valid starter hero:
`partner_id=10001`, `table_id=10001001`, star 3. Stage 4A does not fabricate a
second tutorial reward because the supplied source/captures do not prove one.

## HeroRepository

`gxb_backend/state/hero_repository.py` is now the state owner for hero data.
Future code that grants a girl should use:

```python
state.get_hero_repository().add_owned_hero({...})
```

The caller must provide a source-valid `table_id` and `star`. If `partner_id` is
omitted, the repository allocates a local entity ID, binds the hero to the
current player, adds the table ID to collection state, normalizes Lua-facing
fields, and atomically persists the JSON file.

This is the intended sync path for later summon rewards and battle rewards;
they should not construct separate MID49-only blobs.

## Stage 4A exact/verified contracts

### MID49 `LOAD_HEROS`

Response:

```text
sort_type
heros = partner_id -> hero record
```

Each record is passed to `Hero:populate()`. Stage 4A normalizes the fields used by
`NormalHero:populate_()` and HeroList sorting/cells, while refusing to invent a
missing `table_id`, `partner_id`, or `star`.

### MID65 `LOAD_COLLECTED_HEROS`

`SelfPlayer:collectedHerosEvent_()` consumes `params.list`, so the backend
serializes the internal collection map as:

```json
{"list": [10001001]}
```

### MID67 `LOAD_HERO_PIECES`

The response itself is iterated as a hero-table-ID -> count map. Stage 3's
`{"pieces": [], "list": []}` compatibility wrapper was wrong. Stage 4A uses:

```json
{"10001001": 3}
```

(or `{}` when there are no pieces).

### MID89 `SAVA_SORT_TYPE`

Request field: `sort_type`. No response fields are consumed. Stage 4A persists
it as `heroes.hero_sort_type`, and MID49 returns that value on the next load.

### MID1793 `SAVE_TEAM`

The request carries serialized strings (`team_str`, `team_name_str`, optionally `pet_str`). Some client delete paths omit `pet_str`, so an absent field is preserved rather than erased. The response fields consumed by `SelfPlayer:heroPreset()` are exactly:

```text
save_team
save_team_name
save_pet
```

Stage 4A persists and echoes those strings verbatim.

### MID835 `SET_BOARD_HERO`

`TuJianHeroDetailWindow` sends `partner_id`, `card_status`, `board_model_id` and
consumes `board_partner`, `board_card`, `board_model_id` from the callback.
Stage 4A persists those board fields on the owned hero. Board/poster selection
is intentionally separate from `formation.rep_partner_id`.

The same client request is used for both set and reset. When the selected
partner/card/model already matches the current board state, Stage 4A clears
`is_board` and returns `board_partner=0`, matching the callback's reset branch.

## Request-level JSON synchronization

The JSON database was already atomically replaced on save, but a threaded Flask
request could previously refresh/replace `PlayerState` between another handler's
mutation and save. Stage 4A adds `StateRepository.request_scope()` and keeps each
stateful request's refresh -> handler -> response path under one re-entrant lock.

This is intentionally simple: for a local restoration server, serializing state
requests is preferable to introducing SQL transactions before gameplay schemas
have stabilized.

`HeroRepository.add_owned_hero()` also refuses to overwrite an existing
`partner_id`. Future summon/reward code must allocate a fresh local entity ID or
use `update_owned_hero()` for an intentional mutation.

## Deliberate non-goals

Stage 4A does **not** implement:

- semantic summon rewards;
- hero level/evolve/equip mutations;
- formation/team battle semantics;
- campaign fight/reward progression;
- Arena/Peak Arena;
- payment.

Those domains will reuse the canonical roster established here.

## APK test target

1. Login and confirm the Stage 3 stable lobby remains intact.
2. Press **Girls**. It should open locally even if no new MID49 is emitted.
3. Confirm the owned starter girl appears as collected; the client may also show
   its table-driven uncollected catalog.
4. Change hero-list sort/filter and watch for MID89.
5. Open/save a preset team and watch for MID1793; relog and confirm it persists.
6. If the list opens but clicking the individual girl later freezes/spins, save
   that server log separately. The next dependency is then the hero-detail/window
   path rather than the basic roster constructor.

## Static validation

Only the agreed syntax check was run:

```bash
find . -name '*.py' -print0 | xargs -0 python3 -m py_compile
```

Result: PASS, 56 Python files. No Flask, HTTP, APK, ADB, emulator, or gameplay
runtime test was performed by the build process.
