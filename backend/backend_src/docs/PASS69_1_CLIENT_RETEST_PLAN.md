# Pass69.1 Client Re-Smoke Plan

Preserve the existing `data/server_state`, `data/player_db.json`, `local_assets/res`, and client app data. Do not clear the app unless a later log proves a clean-data comparison is necessary.

1. Start the backend and confirm the startup banner contains `GXB modular v0.9.1 Pass69.1 Economy Backbone Part2 + item-sale settlement hotfix`.
2. Login with the same established account.
3. Record the current Mana value.
4. In Bag, sell exactly one **PSP** (`50001011`) if available. Expected: the stack decreases by one and Mana increases by **500,000**.
5. Record Mana again, then sell exactly one **Cushion** (`50001012`) if available. Expected: the stack decreases by one and Mana increases by **20,000**.
6. If the UI offers a multi-item sale path, sell a small group whose displayed `Will Get` value is easy to verify. Expected: MID86 succeeds and the cumulative Mana/Crystal increase matches the displayed total once.
7. Restart the backend/client and login again. Verify the credited Mana/Crystal and reduced stack counts persist.
8. Run neighboring regression probes: one Girl skill/Mana spend, one currently working summon, and one Campaign battle/reward.
9. Return the normal `debug.zip` with `server.txt` and request/client logs.

Specialized Inscription/Horcrux/Dorm-key resolve/exchange flows are not part of this generic sale hotfix and should not be used as acceptance probes for MID82/MID86.
