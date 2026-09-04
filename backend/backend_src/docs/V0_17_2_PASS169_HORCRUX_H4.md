# v0.17.2 / Pass169 — Horcrux H4 strengthening

Pass169 activates only MID3089 strengthening on the already-accepted Horcrux foundation. It does not introduce a second transaction, economy, persistence, or entropy framework. `HorcruxService` orchestrates validation and settlement inside the existing `PlayerUnitOfWork`; `EconomyLedger` owns Mana, `HorcruxRepository` owns unique-instance persistence, `HorcruxSourceCatalog` owns recovered source facts, `horcrux_policy_v1` owns unrecovered compatibility choices, and the thin Horcrux ROS adapter owns only namespaced entropy requests.

Fresh effective `src_64` reconfirms the request as `{spirit_id, spirit_ids[]}`, complete updated target response, fodder filtering to unequipped/non-collocation instances with locked fodder rejected, transferred EXP as source model base EXP plus `0.6 * fodder.exp`, Mana as transferred EXP times `25`, maximum level `15`, and enhancement milestones at levels `3/6/9/12/15`. The client permits a final fodder choice to overshoot the maximum; Pass169 therefore charges full selected-fodder EXP/Mana while clamping stored target EXP to the level-15 cumulative maximum.

The recovered source does not contain the missing ADD-vs-IMPROVE probabilities or target-selector weights. Pass169 therefore keeps the previously frozen `horcrux_policy_v1`: zero substats forces ADD, maximum sub-count forces IMPROVE, otherwise ADD/IMPROVE is balanced 50/50; ADD selects uniformly among absent source selectors and IMPROVE uniformly among existing sub entries. Forced/single choices consume no entropy. Milestones execute in ascending order.

Fodder must be owned, positive/distinct, not the target, unlocked, unequipped, and absent from saved collocations. The target itself may be locked or equipped because the recovered client source does not establish a prohibition. All deterministic validation and Mana preflight occur before the first enhancement draw.

Exactly-once behavior uses the existing durable UoW receipt store. The receipt identity is target `spirit_id` plus a SHA256 of the sorted distinct consumed fodder IDs; a successful retry replays the complete stored target and does not debit Mana, remove fodder, advance persistence, or consume new entropy. Injected post-debit/post-removal failures restore player state and leave no committed receipt; ephemeral ROS draws intentionally are not rewound.

H4 requires no client patch. OTA 1.631.12 remains byte-for-byte the accepted Pass168 cumulative package with 142 entries. H5 Gods Trial remains disabled.
