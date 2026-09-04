# Pass111.0 Client Smoke Plan — MID50 UUID/Replay Migration

Runtime smoke should be performed against OTA resource version `1.631.5` after release packaging.

1. Launch/restart until MID2 installs `1.631.5`; confirm normal lobby entry.
2. Open Summon and execute one Classic x1, Classic x10, Medium x1/10 where affordable, and an SX pull where available.
3. Confirm each successful pull renders exactly the same result shape/cost/counter behavior as before Pass111.
4. Capture `server.txt` and verify MID50 requests now contain `summon_op_id` with `mid50-` UUIDv4 form.
5. Exercise a transport retry if practical (temporary connection interruption after dispatch). Confirm the repeated request retains the same `summon_op_id`; server result rows are replayed without another debit/counter change.
6. Perform a later unrelated economy mutation, then retry a previously committed MID50 only in a controlled debug scenario if available; response must attach current economy projection rather than the old post-Summon balance.
7. Verify tutorial first Mana/Crystal pulls remain functional and post-tutorial free pulls carry UUIDs through the same OTA choke point.
8. Verify Campaign/MID117 behavior is unchanged in this pass.

Acceptance boundary: no Summon probability judgement should be made from one smoke run. Pass111 changes infrastructure only; policy hash pins prove rate/pool/pity files are unchanged.
