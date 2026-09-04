# Pass72.0 client runtime test plan

Use the anonymous debug account UID `13371337` so the one-shot 1000x Hero test inventory seed is available. Preserve the resulting `data/server_state` and return a fresh `debug.zip`.

1. Login and verify the account starts normally; inspect several Hero equipment/material stacks.
2. MID52: evolve an ordinary 1★-4★ Girl if available. Verify exact Girl-fragment and Mana deductions, star increase, and persistence after relog.
3. MID39/MID53: upgrade skills; verify Mana/Skill Points deduct where applicable and skill state survives relog.
4. MID55/MID63: use one and multiple Hero EXP consumables; verify stacks decrease and Hero level/EXP persists.
5. MID54: equip one ordinary gear slot; verify stack/material cost and equipped slot persist.
6. MID62: one-click equip an ordinary Hero if available.
7. MID51/MID57: perform ordinary color promotion / one-click promotion where the client permits it; verify costs and canonical color/equipment state after relog.
8. Consume a seeded test item, restart server/client, and verify it is **not** automatically replenished to 1000.

Do not use Campaign Energy behavior as a Pass72 failure criterion; its 6-Energy debit remains deferred. Do not probe awakening as an acceptance requirement because its numeric MID is unresolved in effective `src_64`.
