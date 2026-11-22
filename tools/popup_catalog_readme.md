# Popup catalogue

This README is generated from `tools/popup_catalog_readme.md`; edit that source and run `--write`.

The catalogue answers one question for every window the stock client can show:
**can the backend produce the reply, push or code that opens it?** It is
generated from the client archive and the Go backend, and it is binding for
build contracts: paste an `owed <system>` list into a build prompt, and do not
call a leaf closed while a row of its MIDs is still GAP or PRODUCED_UNPROVEN
without a reviewed test.

## Files

- `POPUP_CATALOG.json` – one row per popup site and per `message.lua` code, with
  per-kind and per-status counts, the source archive sha256, and every row.
- `REVIEWED.json` – lead-owned: popup id → REACHABLE / UNUSED_BACKEND_GAP /
  CLIENT_ONLY, finding id, evidence and test name. Seeded from
  `work/audit/t34/popups_t34.json`; only matched rows are seeded.
- `WAIVERS.json` – lead-owned: popup id → reason, client evidence, owner phase.
  Seeded only for GAP rows the lead adjudicated LATER; every other GAP is
  reported, never waived.

## Rows

Each row has `id` = `<kind>:<client file>:<line>`, `kind`, `popup`, `trigger`
(MIDs or push event, and the guard as written with its `file:line`), `owner`,
`status` and `reason`.

Kinds:

- `ERROR_TOAST` – one per `data/tables/message.lua` code. Any reply with
  `error_code` and an empty `error_msg` opens the toast with that row's content
  (Backend.lua:428-437). Lists every backend producer (system, MID, file:line),
  the client callbacks that compare the code, and is `UNPRODUCED` when no
  backend path emits it.
- `REPLY` – a popup opened on a MID reply walk (request callback, same-file
  helper, model method).
- `PUSH` – a popup opened by a registered `xyd.event` handler for an event a
  MID dispatches.
- `LOCAL` – a popup opened only by client UI logic; recorded, never checked.

Statuses:

- `PRODUCED` – a code trigger with a producer on every served MID (the
  producer's `file:line` is on the row), or a REVIEWED REACHABLE row with a test.
- `PRODUCED_UNPROVEN` – a success or field trigger on a served MID; the client
  opens it, but no reviewed test names it yet.
- `GAP` – the MID is served but the code trigger has no producer, or a REVIEWED
  row says the backend cannot reach it.
- `UNBUILT` – the MID is not served; the row carries the owner phase from
  `docs/i9/I9_MODE_SURFACE_V1.json`. This is the forward catalogue.
- `CLIENT_ONLY` – a LOCAL popup.
- `UNKNOWN` – the walk could not decide; the reason is on the row.
- `WAIVED` – a reviewed GAP deferred by a `WAIVERS.json` entry.
- `UNPRODUCED` – an ERROR_TOAST code with no producer.

Owners come from `system_map`'s `mid_to_system`; an unserved MID takes its
phase or `out_of_i9:<disposition>` from `I9_MODE_SURFACE_V1.json`.

## Commands

```
python3 tools/popup_catalog.py --source-archive <zip> --write
python3 tools/popup_catalog.py --source-archive <zip> --check
python3 tools/popup_catalog.py show <mid|system|code|window>
python3 tools/popup_catalog.py owed <system>
```

`--check` fails on stale generated files, a GAP without `WAIVERS.json` entry, a
waiver or REVIEWED entry whose popup id no longer exists or whose status no
longer needs it, and a waiver without reason, client evidence or owner phase.
`show` prints the catalogue rows of a MID, system, message code or window.
`owed <system>` lists every non-PRODUCED, non-CLIENT_ONLY row of that system
(served or not): this is what a build contract pastes as "popups owed".

## Waiving

Add an entry to `WAIVERS.json`:

```json
{"popup_id": {"reason": "why the popup is out of scope now", "client": "app/windows/X.lua:12", "owner_phase": "I10"}}
```

Every field is required, and the id must exist with status GAP. Add a
`REVIEWED.json` entry when a finding proves a popup reachable or unreachable:

```json
{"popup_id": {"status": "REACHABLE", "finding": "A-152", "evidence": ["src_64/app/windows/X.lua:12"], "test": "TestXxx"}}
```

## Limits

- The reply walk is bounded the same way as `reply_consumers.py`: callbacks it
  cannot resolve stay `UNKNOWN` with a reason, and popups inside a local
  closure defined in a callback are attributed to that callback even if the
  closure is never invoked.
- Producer analysis is a static dispatcher-case walk; a MID whose case cannot
  be parsed stays `UNKNOWN`, never a guessed GAP.
- Pushes are attributed through `mid2EventNames_`; a push with no MID mapping is
  `UNKNOWN` because backend emission is not proven here.
