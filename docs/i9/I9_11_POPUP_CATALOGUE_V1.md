# I9_11_POPUP_CATALOGUE_V1

Lead contract, 2026-11-19, user-approved the same day ("keep some sort of catalogue for not only existing systems and fixes but also future ones"). Tooling only, no product code. Reason: most Sol T34 findings (A-152..A-174, `work/audit/t34/popups_t34.json`: 470 popups, 16 UNUSED_BACKEND_GAP) were popups the stock client can show but the backend could never trigger: generic codes instead of named ones, 200 instead of 409, empty lists that skip the award window. No tool recorded which popups a request owes, so tests stayed green. This catalogue makes that record generated, checked and binding for existing and future systems.

## Client evidence (src_64, read from the source archive)

- Every reply with `error_code` and an empty `error_msg` opens `toast` with `xyd.tables.message:getContent(code)` (app/common/network/Backend.lua:428-437); with a non-empty `error_msg` it opens a one-button CommonAlertWindow that exits the game (:438-445). So every code row of data/tables/message.lua is a popup, and the code decides which one.
- Reply callbacks open specific popups: `xyd.CommonAlertWindow.open` (770 sites), `openWindow("common_alert"|"alert_award"|"new_item_tips"|"battle_award_items"|"recycle_award"|...)`, toasts with translation keys, often behind a guard on the reply (`error_code ==`, a field nil or empty, a count).
- Push handlers (event names dispatched by Backend.lua:411-416) open popups the same way.

## P1. Extractor `tools/popup_catalog.py` (backend tree)

Modelled on and reusing `tools/reply_consumers.py`: import its Lua walk (reply callback resolution, same-file helpers, model method bodies, bounded depth) instead of copying it. If reuse needs a small refactor of reply_consumers.py, keep its output byte-identical (`reply_consumers.py --check` stays green). CLI: `--source-archive <zip>` plus exactly one of `--write`, `--check`, `show <mid|system|code|window>`, `owed <system>`. Never guesses: anything unresolved is UNKNOWN with a reason.

Rows, one per popup site (`id` = `<kind>:<client file>:<line>`, stable because the source archive is fixed):
- kind: ERROR_TOAST (one row per message.lua code), REPLY (opened on a MID reply walk), PUSH (opened by a push/event handler), LOCAL (opened only by client UI logic with no server input; recorded, never checked).
- popup: the window name or alert API, the text key or message code, the client file:line.
- trigger: MID(s) or push event, and the guard as written (error code comparison, reply path nil/empty/compare, or "always on success"), with the guard's file:line.
- owner: the system that serves the MID (from system_map's mid_to_system / dispatcher table); for an unserved MID the owner from docs/i9/I9_MODE_SURFACE_V1.json (phase or out_of_i9 ruling); else UNKNOWN.
- status, computed:
  - PRODUCED: the trigger can be produced by the backend. A code trigger: the code appears in the MID's dispatcher failure rows, a `refusal(<code>)` or named constant reachable from that dispatcher, or the shared failure.go classifier rows (balance codes, 35028); cite file:line. A success or field trigger on a served MID is PRODUCED_UNPROVEN until a REVIEWED row (P3) names the test that proves it.
  - GAP: the MID is served but the code trigger has no producer, or a REVIEWED row says the backend cannot reach it.
  - UNBUILT: the MID is not served; carries the owner phase. This is the forward catalogue: future leaves read their owed popups from here.
  - CLIENT_ONLY (LOCAL kind), UNKNOWN (with reason), WAIVED (P3).
- ERROR_TOAST rows: the code, message text, every backend producer (system, MID, file:line); a code with no producer is UNPRODUCED and lists the systems whose client callbacks compare against it, if any.

Outputs in `docs/architecture/popup_catalog/`: `POPUP_CATALOG.json` (rows plus per-status counts and the source archive sha256), `README.md` generated from `tools/popup_catalog_readme.md` (how to read it, status meanings, how to waive), and the lead-owned inputs of P3.

## P2. Check and integration

- `--check` fails on: generated files differing from a fresh run; any GAP without a WAIVERS.json entry; a WAIVERS or REVIEWED entry whose popup id no longer exists or whose status no longer needs it (stale waivers must be removed); a waiver without reason, client evidence and owner phase.
- `tools/system_map.py show <mid>` and `show <system>` print the popup rows of that MID or system (status, popup, guard) from POPUP_CATALOG.json; system_map `--check` stays green and its README source mentions it.
- `owed <system>` lists every non-PRODUCED, non-LOCAL row of that system (served or not): this is what a build contract pastes as "popups owed".
- Unit tests in `tools/test_popup_catalog.py` on small Lua fixtures: code guard, field-empty guard, helper-indirect popup, push popup, unresolved callback -> UNKNOWN, waiver staleness.

## P3. Lead-owned inputs (worker seeds, lead reviews)

- `WAIVERS.json`: popup id -> reason, client evidence, owner phase (e.g. A-155 activity first store -> I10). Seeded only for GAP rows already adjudicated LATER in work/audit/LEAD_VERDICTS.md; every other GAP is reported, not waived.
- `REVIEWED.json`: popup id -> status (REACHABLE / UNUSED_BACKEND_GAP / CLIENT_ONLY), finding id, evidence, test name if any. Seeded from work/audit/t34/popups_t34.json by matching window + client file:line; unmatched Sol rows are listed in the report, never forced. A REVIEWED REACHABLE row with a test turns PRODUCED_UNPROVEN into PRODUCED.
- Recall check (report only): of Sol's REACHABLE and UNUSED_BACKEND_GAP rows, how many the extractor found on its own, and why it missed the rest.

## P4. Binding for later work (lead, after P1-P3 merge)

- Build contracts and worker prompts for a system carry the `owed <system>` rows; a leaf closes only when each owed row of its MIDs is PRODUCED (with a test), WAIVED or out of the leaf's scope by ruling.
- After every merge: `popup_catalog.py --check` joins the existing checks (system_map, mid_effects, reply_consumers).
- I9-E and every later phase close: no GAP; UNBUILT rows of systems the phase claims built are zero.
- ops/FLEET_RULES_WORKER.md research rule points at `show <mid>` instead of a hand listing.

## Not in scope

Product code, client edits, migrations. The extractor reads the client from the archive only; nothing from inputs/ is executed.
