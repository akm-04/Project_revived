# Pass 87.0 Client Test Plan

- Start the backend with a clean copy of the packaged established sandbox state.
- Log in and confirm normal Pass83 Daily Reset/Campaign/Skill behavior remains healthy.
- Open the Recharge/VIP window using the `+` beside Crystal.
- Confirm the Crystal tab is populated rather than empty.
- Expected direct Crystal SKUs are 100, 500, 1,000, 2,000, 5,000, 10,000 and 30,000 Crystal packs. The client itself hides the 30,000 pack on iOS.
- Cards/Privilege products should **not** be advertised by MID354 in Pass87.
- Confirm the server MID354 response contains seven `charges` rows with `charge_count=0` and `last_buy_time=0` on a clean migrated sandbox.
- Confirm the established sandbox logs/boot state are coherent at `vip=15, charge=500000`; Crystal must not increase merely because the migration ran.
- Restart the backend and log in again. `charge` must remain 500000 and the migration must not run as a second purchase or alter Crystal/product history.
- Open Skill Point purchase UI and verify existing VIP15 Skill behavior remains unchanged.
- Open/use the already-supported SX/Soul Box path and verify its VIP gate remains unchanged.
- Do **not** expect tapping a Crystal product to complete a purchase in Pass87. The native PurchaseIntent bridge and MID36857 settlement are intentionally Phase 2.
- Preserve `server.txt`, client Lua errors, and the resulting player JSON if MID354 is empty, the Recharge window crashes, or VIP/charge changes unexpectedly.
