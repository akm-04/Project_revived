# Pass71.0 client runtime gate

Use `gxb-backend-v0.9.3-pass71.0` with the already accepted player/client state and return a fresh `debug.zip`.

Preferred probes, using whatever items/actions are naturally available in the client:

1. Login after some real elapsed time and confirm bootstrap Energy / Spirit Energy / Skill Point amounts and anchors are sane. A pool already at/above natural cap should retain the zero-anchor paused sentinel.
2. Use one Energy item (MID27) if available. Confirm the item disappears once and the cumulative Energy balance increases by its source item value; no duplicate item reconciliation should appear.
3. Use one Skill Point item (MID90) if available. Confirm one stack removal and cumulative Skill Point increase.
4. Spend a Skill Point through a Hero skill action (MID39 or MID53) and confirm cumulative Skill Point/anchor state remains coherent.
5. If convenient, use MID99 Skill Point purchase and confirm Crystal debit + Skill Point credit occur together.

Do not use MID52 Hero Evolve Mana behavior as a Pass71 acceptance criterion. Its missing Mana settlement is an already-recorded Hero/Girls Progression bug intentionally deferred to the next phase.

Acceptance gate: zero new fallbacks/tracebacks/HTTP 5xx/nonzero engine errors attributable to Pass71, and temporal actions reconcile exactly once with persisted cumulative state across reopen/login where practical.
