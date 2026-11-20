# I9-11 lead seams V2 (supersedes LEAD_SEAMS_I9-11.md, SEAMS_11AB.md, SEAMS_11C.md)

R1 registry fold 2026-11-19: REGISTRY_SWEEP_I9-11 S1-S6, the seams audit (08-code-seams) and A-136/RQ5/RQ7/unserved-MID
rulings are folded in place.

Written by the lead on 2026-11-18 against repair-final 04ed0b53 (work/backend_i9_11, migration head 00173). Workers
implement against this file and the I9_11{A..E}_V2 contracts. A seam not listed here (rank, migration number, receipt
class, reply field, entropy label) is a stop-and-report, never a guess. A leaf that needs a change to a repair
foundation (R1-R8, D5, ACHIEVEMENT_EVENT_FACTS_V1, the frozen I5/edge code beyond the entries named here) stops and
reports; the backend is frozen at repair-freeze-1118.

## 1. One money path (every leaf)

Every request that debits and grants (11A 39/53/90/99; 11B 27/28/29/82/86/87/96/97/241; 11C 33/2982/34) is one
transaction:

1. Admission through the mode framework (`gen.TimedScope`, `operation.Context`): DecisionAt and a random operation ID.
   No request-body deduplication (B1): the stock client sends no token, so a later request is a new operation. Only
   the R6 edge replays an undelivered reply (section 6).
2. Lock plan in ascending rank (section 2), taken before any read-for-write. The rule is deterministic rank order,
   not "no write before all locks": a lower-rank owner may save before a higher rank is taken, as
   `ObjectiveFacts.PrepareTx` -> `MaterializeTx` saves the rank-610 mission root (rolled at 05:00) before I5 locks its
   700-722 suffix (A-136 addendum, accepted as a text clarification). The player root is taken with
   `FOR NO KEY UPDATE` (R8 root-lock amendment).
3. Pure domain plan in `internal/domain/<owner>`: price, cap, day counter and availability from the catalog, owner
   state and the privilege snapshot. Never from a client field (`client_price`, `nums`, price echoes are ignored).
4. I5 settle in one exchange: `PrepareMaterialExchangeTx` then `ApplyMaterialExchangeTx`
   (internal/application/i5/material_exchange.go:106,207), source identity
   `{Domain, Operation, BusinessKey, Occurrence: op.ID, PolicyVersion}`. The exported Prepare restores stack items only;
   11B adds one I5-owned exported pair beside it, modelled on `i5/glue_purchase.go`, calling the internal
   `prepareMaterialExchangeTx` with one validator that accepts ScalarCurrency, Temporal, StackItem and PlayerExp lines
   (`PrepareItemsEnergyExchangeTx`/`ApplyItemsEnergyExchangeTx`; sweep S1). 11A and 11C reuse that pair. No leaf writes I5 rows directly or settles debit and grant separately.
   A request with no grant line left after netting (11C 34 paid refresh; an 11C stone-priced buy whose product is
   its own price stone) settles through the I5 debit-only pair `PrepareMaterialDebitTx`/`ApplyMaterialDebitTx` in
   the same one transaction. An item that is both product and price nets to one line; it never appears on both
   sides of an exchange (lead amendment 2026-11-18, REVIEW_C C-4).
5. Save owner state with its state_version check, then the receipt where section 5 lists one, in the same transaction.
6. The reply carries post-commit values read back from Apply (`economy_` delta keys and `daily_updates.updates`, as
   dorm/adventure do; B10), never values recomputed from the request.

Refusals are D5: 20005/20006/20007 missing diamonds/coins/stamina, 40002 stale state or receipt conflict, a
message-backed code where the client proves one (35031 energy cap, 34020/34021 shop price), 35028 otherwise; 400
malformed; 503+35033 transient; 500+35028 defect; never a 200 error body (the F4e 30005 terminal of 11D C7 is the one
exception), never `error_code 1`. A refusal changes no state and writes no receipt; its rollback includes refusal
bookkeeping such as a mission root rolled on the refused attempt (A-136, fleet_11fa). Multi-item requests are
all-or-nothing. Shop purchases do not overflow to mail; box contents may (B5).

## 2. Lock ranks

Existing (unchanged): 315 actor fence / player root; 400/410 hero root/instance; 420/430 pet; 490-590 character
assets; 600-609 mode owners (605 per-player mode rows, 606 illusion occurrence); 610 mission; 700 economy, 710
progression, 720 scalar, 721 temporal, 722 stack (I5); 723 guild activity; 750 occurrence. Achievement rows are
locked last, after the producing owner's ranks and the I5 suffix, as the existing observing wrap does.

New in I9-11 (constants in each owner's `internal/domain/<owner>/types.go`; a native asserts every rank is unique
across `internal/`):

| Rank | Owner | Key |
|---|---|---|
| 450 | daily-consume counters (`daily_consumption_players` row; 11A/11B buy counters, MID 28 pipe) | player |
| 460 | 11C shop row; a multi-type request locks in ascending shop_type | player + shop_type |
| 470 | 11D compat preferences | player |

## 3. Daily counters

`daily_consumption_players.counts` (00083, payload_version 00163) holds `modes.Counter{Period, Used}` per id.
Ids 1..10 stay the `daily_consume` table ids (MID 28 pipe; 1 = Golden Hand tenfold). Named counters use reserved ids
**1001 buy_mana_times, 1002 buy_energy_times, 1003 buy_skill_times**, as constants in
`internal/application/dailyconsume` with one shared locked-increment method. No migration. Day = `modes.Day` (05:00
GMT+8): lazily reset, normalised on read, a read never writes. MID 17 and the dailyreset reader project the same
values from the same owner; `stockruntime.Decorated` gets a real CounterReader in place of `ZeroCounters`.

## 4. Migrations

Numbered in planned merge order (section 9). Only the lead renumbers, at merge, if a leaf lands out of order (no
deployed database has applied any I9-11 migration). Every table: FK to players, forward-only (no down migration;
PASS628 wins, lead amendment 2026-11-18), an upgrade-replay fixture entry, classification in `docs/architecture/CANONICAL_TABLE_OWNERSHIP.json`, regenerated
`docs/data/PLAYER_DATA_MANIFEST.json` and `tools/player_data_manifest.py --check`; jsonb payloads carry
payload_version (R8). Content tables follow migration 00116 (`content_*_catalogs`, revision_id FK, object payload).

| Number | Leaf | Content |
|---|---|---|
| 00174 | 11B | `content_daily_buy_input_catalogs` (bundle `daily-buy-inputs`; also serves 11A) |
| 00175 | 11C | `content_shop_catalogs`, `shop_players` (player, shop_type, generation, refresh_times + day, stock jsonb, payload_version, state_version), `shop_tuning` singleton (D476, modelled on summon_tuning) |
| 00176 | 11D | `content_compat_catalogs` (message_push ids), `player_compat_preferences` with the existing-player backfill (11D C1) |
| 00177 | 11E | `achievement_boss_facts`, `achievement_daily_counts`, widened `achievement_streaks` profile CHECK (11E C5, C8) |
| 00178 | seams fix | `payload_version` on the 00174/00175/00176 content catalog jsonb payloads (00163 pattern; seams 4.7) |
| 00179 | G2a | `library_hero_battle_counts` (I9_11_GIRLS_LOG_V1; renumbered from 00180 at merge) |
| 00180 | closure | A-134 drop of the unwritten guild `settled_by`/`settled_index`/`settled_body` columns |

00174 also creates the validated singleton `items_energy_tuning` (D476 overlay, source fallback as a whole unit when
absent or invalid, no endpoint; sweep S4); `shop_players`, `shop_tuning` and `items_energy_tuning` carry
payload_version from their own migrations (fleet_11fd F2). 11A adds no migration (skill points are I5 temporal;
backpack sort is 00173, built).

Upgrade proof (RQ5, approved 2026-11-19): there is no separate upgrade-replay fixture mechanism. The proof is the
migration test, `CUMULATIVE_MIGRATION_LOCK` extended to every I9-11 migration (00173-00180) at closure, and the I7C
upgrade proof at seal, which migrates the previous frozen product's database forward.

## 5. Receipt classes

`receipt.Identity{OwnerKind: "player", OwnerKey: <player>, Domain, Operation, SemanticKey: op.ID}`; fingerprint over
the decoded command; the policy version is stored beside it in the source identity and is not compared on a found
receipt (house convention, internal/foundation/receipt/receipt.go:104-137; seams 5.2). Semantic key = operation id keeps receipts purgeable (R8 6A A-036).

| Leaf | Domain | Operations | Class |
|---|---|---|---|
| 11A | `hero-assets` | `skill_point_buy`, `skill_point_item` | `I9_11A_HERO_ASSETS` |
| 11A | MIDs 39/53 skill upgrade | unchanged frozen receipt (characterhero) | `I9_HERO_SKILL_LEVEL` (lead amendment 2026-11-18) |
| 11B | `items-energy` | `item_use`, `box_open`, `golden_hand` (MID 96 and the MID 29 tenfold), `energy_buy`, `sell` | `I9_11B_ITEMS_ENERGY` |
| 11C | `shop` | `buy`, `multi_buy`, `refresh` | `I9_11C_SHOP` |

11D writes no receipt (toggles; 279 changes nothing). 11E writes none of its own; its facts ride the producer's
transaction and are `ON CONFLICT DO NOTHING`.

## 6. Replay and MID effects (R6)

Every new write MID is classified `state` in `docs/protocol/MID_EFFECTS.json` (regenerated by `tools/mid_effects.py`;
`--check` passes) in the leaf that registers it: 11A 39, 53, 88, 90, 99; 11B 27, 29, 82, 86, 87, 96, 97, 241;
11C 32 (it may generate the player's first generation), 33, 34, 2982; 11D 1025, 1026, 1864. MID 38 stays
`unknown`. Reads, never replayed: MID 3 (`server_time`), 28, 37 (evidence row in
`tools/mid_effects.py`) and 279 (sweep S6, 11cf F3). A MID with no evidence stays `unknown`, which counts as `state` for
reply replay (conservative). The edge stores
the reply bytes of a state MID in `player_undelivered_replies` for 10 minutes and replays only an undelivered reply;
a delivered reply followed by a resend is a new operation (B1/C11). Observations attached to a receipt must not run on
a receipt replay.

## 7. Surface and dormant register

All surface changes are a scripted edit of `docs/i9/I9_MODE_SURFACE_V1.json` followed by `tools/generate_inactive_mids.py`
(`MODE_MAP.json` is a frozen research snapshot); `inactive_mids_gen.go` is never hand-edited. To avoid generator conflicts between
leaves, the lead makes every I9-11 surface amendment in one seam commit before the leaves branch:

- INACTIVE: 35 (SHOP_MAGIC_*), 64 and 66 (INACTIVE_SUPERSEDED, sweep S5), 224, 225 (11A/11B/11C); 17 standalone, 80, 84, 85, 208-213, and new rows 246,
  1412 as INACTIVE_SUPERSEDED (11D C5, C6).
- LATER/I10: 1051.
- New ACTIVE rows with existing owners: 774, 1570, 2484, 2515, 1844; new row 279 (11D C7).
- 3, 6, 120, 1304, 2560, 2568, 2657 unchanged until research leaf 11F gives each a disposition (11D C10).

Later rulings (RULING_I9-11_UNSERVED_MIDS and its addendum): 20, 21, 65, 91, 435, 48 and 144-152 INACTIVE_SUPERSEDED;
2065-2067, 2197, 2198 LATER (I10/I10.5); 2501 stays ACTIVE with real recommend scores owed in I9-11.

The dormant register is the generated `tools/system_map.py show unhandled` report read with the surface dispositions
and `inactive_mids_gen.go`; there is no separate register file and no reason-string column (sweep S5, 11D C9). No
surface MID may answer `unimplemented_mid` at I9-E: every ACTIVE row of the closing stage has a handler or a named
MID 1 detail owner (closure rule), and `tools/generate_inactive_mids.py --check` fails when the surface's stored counts
drift from its rows.

## 8. Entropy recipes (A-107 lesson)

Each random draw states its stream exactly, and a native pins the schedule with a fixed operation seed:

| Leaf | Label | Stream | Draw order |
|---|---|---|---|
| 11B box open (MID 241) | `items-energy.box/v1` | `Operation.Derive("items-energy.box/v1", 0)`, one per operation | unit order, then gift.drops order |
| 11B golden hand (MID 96, MID 29 tenfold) | `items-energy.golden-hand/v1` | `Operation.Derive("items-energy.golden-hand/v1", 0)`, one per operation | crit, then float (sweep S3) |
| 11C stock generation | `shop.stock/v1` | `Operation.Derive("shop.stock/v1", generation)`, one per generation | slot 1..N; group then row |

Weights are relative and normalised by the actual group sum (0 never wins); never assume 10000. Both rules are
approved by the user on 2026-11-18 (B11).

## 9. Order, branches and merge

0. Lead seam commits on i9-11: f25030cc (section 7 surface amendments) and 349f499f (11F dispositions). Leaves
   branch from 349f499f. Each leaf adds its own rank and counter-id constants (section 2) and regenerates
   `MID_EFFECTS.json` with `tools/mid_effects.py --write` for its new MIDs; nothing is pre-added.
1. 11B (00174 content, the I5 currency/temporal exchange pair, counters). 11D and 11E S1-S3 may run in parallel; they
   share no file with 11B except the generated ones below.
2. 11A on top of merged 11B.
3. 11C (00175). 4. 11D (00176). 5. 11E (00177); its 100011 slice after 11C merges.

Each leaf registers its own routes in `cmd/gxb-api/main_postgres.go` through one composition constructor, and its
natives drive that production dispatcher, never `app.Service` (sweep S2); the lead resolves composition conflicts at
merge. Generated files (`MID_EFFECTS.json`, `reply_consumers.json`,
`PLAYER_DATA_MANIFEST.json`, `docs/architecture/system_map`, surface and inactive lists) are regenerated after each
merge, never hand-merged. After every merge: build, `go vet -tags "postgres river"`, archguard, `system_map --check`,
`branch_ledger`. Gate tiers: leaf = impact preflight; I9-11 close = one parallel foundation gate (D521).
The repair branch off 04ed0b53 (Sol T29 findings A-106..A-120) merges into i9-11 before the close, so that one
gate covers both (user approval 2026-11-18).

## 10. Owner-blocked rewards (B5, amended)

A reward whose owner is not built is not granted, substituted or stubbed. Spirit-energy and hero-entity rewards are
live and granted; gear and horcrux stay I10 (B6). A box whose gift or dropbox source row is missing refuses the whole
open with 409+35028 before any debit; the refusal is the record (no register row; MID 241 is ACTIVE), and each
blocked family with its future owner phase is listed in fleet_11b/LEDGER.md (B5 table; seams 10.3). Horcrux (type
24) refuses until I10 (RQ7, approved 2026-11-19).
