# Pass70.0 Client Retest Plan

Preserve the existing accepted Pass69.1 server/player data and normal client app data. Do not reset either side for this smoke unless a reproducible migration failure requires a separate diagnostic run.

## Required smoke

1. Login to the established account and reach MainScene/Girls normally.
2. Perform at least one **generic MID82 item sale** (PSP/Cushion is ideal because the source-derived price is known) and confirm the credited Mana is visible immediately.
3. Close/reopen the client and confirm the credited scalar persists on login.
4. Exercise at least one paid summon and one Campaign battle/result to characterize the legacy projection bridge after the dispatcher integration.
5. Open Shop and, if practical without changing gameplay assumptions, perform an already-working purchase path; watch for duplicate Backpack additions. Pass70 must **not** synthesize generic STACK awards.
6. Open any available PetCampaign/Sky Tower surface; no new feature correctness is expected, but watch for double-added inventory from returned awards.
7. Return `debug.zip` with engine/server/client logs.

## Acceptance signals

- zero Python traceback;
- zero HTTP 5xx;
- zero new blocked/fallback MIDs attributable to Pass70;
- no nonzero engine responses on previously accepted flows;
- generic sale still returns cumulative canonical Mana and persists;
- no duplicated inventory caused by response projection;
- no fabricated zero-filled economy envelope symptoms;
- no RECHARGE/native event regression if a purchase event happens to occur.

Pass70 remains **STATIC_ACCEPTED_RUNTIME_PENDING** until this smoke is reviewed.
