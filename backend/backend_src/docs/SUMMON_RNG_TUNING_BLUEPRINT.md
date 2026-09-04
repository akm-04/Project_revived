# Summon RNG Tuning Blueprint

The current planner is already separated into an injected `SummonRandomSource`, source-derived pool membership/row weights, and versioned private policy. Keep gameplay mutation and response rendering independent from balance tuning.

Future tuning should remain layered:
1. **Category mix** — choose semantic result class (for example item vs Hero) per summon family.
2. **Subtype/tier mix** — optionally split an item category or Hero rarity/tier using field/table-scoped metadata rather than numeric-prefix guessing.
3. **Candidate weighting** — choose a concrete row inside the selected category. For Hero pools, the current conditional probability is `row.drop_rate / sum(hero-pool drop_rate)`; a future policy may replace this with equal-share, rarity buckets, per-Hero weights, or rotation protection without changing transaction code.
4. **Guarantee/milestone overlay** — apply pity/special/10x guarantees as a separate policy layer.
5. **Post-selection conversion** — duplicate `to_stone` remains downstream of selection and must not distort advertised raw draw weights unless a future policy explicitly says so.

Any future balance policy should be data-versioned, deterministic under an injected test RNG, and should preserve recovered client/protocol response contracts.

Pass41.6 adds Magic-specific live overlay knobs and a concrete maintenance procedure. See `SUMMON_BALANCE_TUNING_GUIDE.md` before changing any rate.
