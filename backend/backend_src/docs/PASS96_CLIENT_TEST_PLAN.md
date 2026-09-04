# Pass96.0 Client Test Plan

Pass96 is not runtime accepted until this focused smoke is reconciled.

1. Cold-start the legacy UID `13371337` sandbox.
2. Verify Academy level 100, advertised max level 100, and max Energy 160.
3. Inspect representative historically seeded inventory: normal cap-999/9999 test materials should be no higher than 900; the cap-99 seeded rows `50001058` and `50001885` should be no higher than 90. Already-consumed lower quantities must remain lower.
4. Craft/consume a formerly blocked item and confirm the sandbox is usable. Where practical, drive a known stack close to its source ceiling and verify an operation that would exceed it fails without partial sibling economy mutation.
5. On VIP0, verify ordinary single Campaign sweep remains available but multi-sweep is rejected. On VIP4+, verify multi-sweep is allowed. If an account already has active Monthly Privilege, verify that alternative entitlement at VIP0-3.
6. At VIP0, save up to 10 Hero presets and verify the 11th is rejected without overwriting the existing preset string. Verify a higher-VIP account receives the source-expanded limit.
7. Cold restart and verify Academy, inventory normalization marker/state, and saved preset state persist.

SX/Soul Box is out of scope because QA already confirmed its existing mutating purchase action correctly requires VIP9.
