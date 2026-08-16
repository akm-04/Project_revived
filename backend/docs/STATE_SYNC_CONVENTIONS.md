# State synchronization conventions

This file is a short implementation rulebook for later gameplay stages.

## One canonical player document

`data/player_db.json` is the authoritative local account/player state while the
protocol is still being reconstructed. Keep it human-editable. Do not create a
second hidden state store for a gameplay domain unless there is source evidence
that the game truly has a separate identity/session store.

## Domain repositories own mutations

Handlers should be thin protocol adapters. Persistent gameplay mutations belong
in a domain repository operating on the current `PlayerState`:

- `HeroRepository` — owned girls, local partner IDs, collection/pieces, hero
  payload normalization and later hero progression.
- `WorldRepository` — Campaign unlock/star state and MID113->MID114 sessions.
- future Inventory/Formation repositories should follow the same pattern when
  their mutation contracts are implemented.

Do not update a response payload without updating the canonical state that the
next request/relog will read.

## Request transaction boundary

Stateful HTTP handling runs inside `StateRepository.request_scope()`:

```text
reload hand-edited JSON
        -> handler/repository mutation
        -> atomic save (when mutated)
        -> response built from the same PlayerState
```

The repository uses an `RLock`, so nested `save()` calls are safe. This is the
current local-server transaction model; it is intentionally simpler than SQL
while schemas are changing.

## Source-shaped, not speculative

Persist only fields/IDs whose client consumers or source tables are known.
Compatibility zero/empty values are acceptable when their shape is confirmed;
label them as such in comments/docs. Never invent numeric MIDs, hero/item table
IDs, campaign links, rewards or error codes.

## Client simulation vs server commit

Some systems simulate locally. Normal Campaign is the first confirmed example:
MID113 establishes the session, Cocos/Lua runs the fight, MID114 commits the
result. In those cases the backend should own eligibility and durable state, not
duplicate the client simulator without evidence.

## Database expansion

`JsonPlayerDatabase` groups known fields into readable sections and preserves
new `PlayerState` fields under `player.domains` until they receive a permanent
section. When a domain becomes stateful enough to deserve first-class grouping,
add its field set to `SECTION_FIELDS` and bump schema documentation; the loader
continues to accept older flat/`domains` layouts.
