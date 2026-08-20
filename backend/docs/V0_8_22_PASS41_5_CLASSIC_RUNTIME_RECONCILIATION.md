# v0.8.22 / Pass41.5 — Classic Vending Runtime Reconciliation

User runtime evidence from `debug.zip` (SHA-256 `8be737d3098d0b35dbdc657a299cb224a4728c96913aad3a7e9388ae5d9346da`) confirms the Pass41.4 Small/Medium paid implementation in live client use.

Confirmed behavior:
- Small paid1 and paid10 debit 10,000 / 90,000 Mana and return 1 / 10 result rows.
- Medium paid1 and paid10 debit 288 / 2,590 Crystal and return 1 / 10 result rows.
- New Hero rows hydrate into the Girls collection.
- Duplicate Hero conversion produces `to_stone=true` fragment rows and Backpack accumulation; observed quantities are consistent with Custom Private Server Policy v1.
- One rapid Medium-10 retry replayed the identical stored response with unchanged Crystal balance, validating the 1.5s replay guard.
- No Summon Lua exception appears in this bundle. The observed Lua errors belong to the separately deferred Golden Hand currency exchange.

Maintenance change:
- Established/anonymous sandbox starting Mana is raised from `999,999` to `999,999,999` for private-server testing. Credential-created fresh tutorial accounts remain conservative and unchanged.

No Summon probability, pool membership, duplicate quantity, cost, guarantee, or response-channel policy changed in this revision.
