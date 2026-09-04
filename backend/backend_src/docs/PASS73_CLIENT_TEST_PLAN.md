# Pass73 Client Test Plan

- Log into anonymous debug UID `13371337`; verify Pass73 advanced source-derived items are present around 1000x.
- Stone Evolution: add one point with the Hero's own stone or an authorized universal ticket; confirm exactly one item per point is consumed and state persists after relog. If practical, fill a stage and use MID2609; confirm points reset and stage increments only when the next-stage level/star requirement is satisfied.
- Fumo: refine one ordinary Hero gear item; confirm materials and exact Mana cost are consumed and Fumo state persists.
- Element Equipment: equip, strengthen once, unload/re-equip, and if convenient decompose one; confirm source material/item changes and persistent Hero state.
- Inscription: insert, replace/remove; confirm the relevant item movement and 20 Crystal replacement/removal charge where applicable.
- SuperHero (only if the account naturally owns one): test post-5 evolution, fixed gear equip, and one duplicate equipment enhancement. Do not manufacture a SuperHero just for the test.
- Expected fail-closed: Hero Practice random candidate generation and Inscription make/rebuild/resolve paths should return a nonzero error rather than fake success.
- One-shot seed: consume at least one Pass73-seeded item from 1000 to 999, relog, and confirm it remains 999.
- Persistence: record Mana, Crystal, one or two advanced item counts, and changed Hero state before closing; reopen and verify exact persistence.
- Awakening/Blood Awakening is **not** a Pass73 acceptance criterion. Its active flow is mission-driven and is the dedicated next research/implementation boundary.
- Campaign stage Energy deduction remains deferred and is **not** a Pass73 failure.
