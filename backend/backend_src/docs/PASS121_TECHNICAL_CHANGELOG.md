# Pass121.0 Technical Changelog

Pass121 closes only the Super Campaign MID117 infinite-sweep exploit. The existing MID117 client UUID, permanent receipt, RandomOutcomeService planner, and PlayerUnitOfWork transaction remain authoritative.

For `campaign_type=2`, source membership is now validated before repeat-pool lookup and the mutable unlocked Super row is revalidated inside the UoW. After receipt replay and sweep/VIP validation, `sweep_num` must be positive and no greater than the current `daily_limit`. Failure returns `campaign_daily_limit_insufficient` before cost validation, RNG, receipt staging, or durable mutation.

A successful batch applies the existing Energy + Raid Ticket/Crystal costs and deterministic/repeat rewards, then decrements the exact Super row by `sweep_num` before response/receipt staging. Because all of this occurs in the same PlayerUnitOfWork snapshot/commit boundary, receipt commit and attempt consumption are atomic. A committed same-UUID retry replays the receipt first and consumes zero extra attempts.

No OTA bytes changed. Challenge, manual MID113/MID114 simplification, Campaign EXP/Mana sweep economy, and Generated/Unique remain deferred to their accepted roadmap passes.
