# v0.17.5 Pass172 — Horcrux runtime closure + Vows acquisition/tab closure

Pass172 records the successful Pass171 stock-client restart re-smoke and closes the currently reconstructed Horcrux scope as runtime accepted. The backend remains the authority for persistent Horcrux instances and rolled/materialized stat IDs/values; the stock client consumes those values for Hero attribute/UI calculations.

The same client run exposed the next bounded gap: Institute → Vows → Balder sent source-correct MID305 (`SUMMON_SUPER_HERO`, `table_id=11002`) and was rejected only because the backend had no semantic handler. Pass172 adds a source-generated `VowSourceCatalog` plus a small `VowService` that reuses existing HeroRepository, StackInventory and PlayerUnitOfWork owners.

MID305 validates all five source-defined prerequisite Girls (exact table ID or source awakened counterpart), requires at least one resolved prerequisite to be exactly 5-star, sets the new Vow's initial star to the count of resolved prerequisites that are exactly 5-star, returns `partner_info`, and preserves all prerequisite Girls because the recovered successful client path performs no removal. Natural retries return the already-owned Vow instead of allocating a duplicate.

MID306 atomically exchanges source-defined Vows Essence item `50001666` at 100 essence per selected Vow scroll and returns ordinary `awards` in the shape consumed by `SuperPartnerExchangeWindow`.

No client patch is needed. OTA remains 1.631.12 / 142 entries. Existing MID52/MID54/MID304 Vow progression/equipment behavior is unchanged.
