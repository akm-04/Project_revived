# v0.9.6 / Pass74.0 — Awakening Mission Ownership

Status: **STATIC_ACCEPTED_RUNTIME_PENDING**. Pass72.0 remains the last clean runtime-accepted pass. Pass73.0 is runtime-characterized: its core advanced progression paths worked, but the supplied client debug captured four Lua response-contract errors that are corrected here.

## Scope

Pass74.0 implements the source-visible mission-driven Awakening and Blood Awakening lifecycle without inventing the stale/undefined `AWAKE_HERO` MID. It also includes three narrow response/economy corrections discovered by the Pass73 client smoke: deterministic Emblem Dissolve, Quick Enchant, and Stone Evolution rejected-response safety.

## Awakening protocol

The active source path is mission-driven:

- `TAKE_MISSION_AWARD` = MID161
- `AWAKE_MISSION_LIST` = MID2561
- `TASK_LOAD_BY_TYPE` = MID2736
- `TASK_AWAKE_GIVE_UP` = MID2737
- `TASK_AWAKE_OPEN` = MID2738
- ordinary Campaign proof uses `FIGHT_RESULT` = MID114
- Blood Awakening special battle uses `UNLIMIT_START_FIGHT` = MID866 and `UNLIMIT_FIGHT_RESULT` = MID867

`AwakeningMissionService` persists one-player mission ownership. `TASK_AWAKE_OPEN` returns an `awake_mission_` or `twice_awake_mission_` delta because the Lua client does not locally insert the opened row. Stage claims use MID161. Ordinary stage 2 is completed only after the active source mission/campaign is matched and a winning `FIGHT_RESULT` carries the client-attested `awake_mission` proof. Blood stage 2 uses the dedicated unlimited-fight path and `twice_awake_mission` proof.

Final ordinary claim applies bounded HERO ENTITY `AWAKEN_TABLE_ID`. Blood claims advance bounded HERO ENTITY `SET_TWICE_AWAKE_STAGE` through 0→1→2→3.

Give-up clears active server ownership but returns the same mission row with `is_going=0`, matching the Task UI's reopen behavior. Source-defined `delete_item` cleanup remains authoritative.

## Neighbor runtime corrections

### Emblem Dissolve (MID1404)

Source inscription resolve material IDs 19/20/21 are scalar inscription currencies, not Backpack item IDs:

- 19 → `degree_cer`
- 20 → `graduate_cer`
- 21 → `patent_cer`

Dissolve therefore settles `STACK emblem debit + RESOURCE certificate credit` atomically. Example observed in the Pass73 smoke: emblem `160500603` resolves to `patent_cer +1420` per emblem. Pass70 projects the cumulative scalar balance.

### Quick Enchant / Fumo daily consume (MID28/MID29)

Source daily-consume type 2 costs 20 Crystals, grants 150 Fumo, and is limited to one use per server day. MID28 now returns the required `buy_times` representation. MID29 atomically settles Crystal debit + bounded HERO ENTITY Fumo increase and returns cumulative `fumo`, avoiding the Lua nil dereference/freeze captured in the smoke.

### Stone Evolution rejected response (MID2608/MID2609)

The client treats HTTP 200 as transport success before inspecting body `error_code`; its nominal-success callback dereferences `response.evo_info`. Rejected Stone requests therefore now return authoritative unchanged `evo_info` while committing no mutation or journal row. This prevents the nil dereference. A rare rejected MID2608 can still cause a temporary client-local cost-item decrement until authoritative Backpack refresh; the server never debits the item and no fake award/refund is fabricated.

## Deferred / explicit boundaries

- General Campaign ownership and the missing 6-Energy stage cost remain deferred to the Campaign pass.
- The debug UID 13371337 1,225-item seed can trigger a client bag/capacity warning; no production inventory-cap architecture is changed in Pass74.
- Hidden-random Practice/Inscription generation and unresolved unique-instance Horcrux generation remain fail-closed from Pass73.
- `AWAKE_HERO` remains source-version drift and is not assigned an invented numeric MID.

## Static gate

The exact candidate passes Python compile, Pass42.12/42.14 validators, all Pass68 through Pass73 self-tests, and `selftest_pass74_awakening.py`. Runtime acceptance requires a fresh Pass74 client smoke.
