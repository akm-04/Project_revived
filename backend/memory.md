# Backend machine memory — Pass171.0

Canonical implementation: `gxb-backend-v0.17.4-pass171.0`.

- H1-H5 Horcrux implementation remains static/regression accepted.
- Pass170 stock-client smoke was broadly positive through generated rewards, Gods Trial manual/auto, equip/collocation and strengthening, but exposed a restart-only Hero/Horcrux crash.
- Debug source fact: KM-Moe partner_id 10073 persisted `spirit_equip=[7,4,12,1,5,15]`; MID81 simultaneously carried complete instances for all six IDs. MID49 also emitted `spirit_item=[]`.
- Recovered `NormalHero.lua` sets `spiritItems_ = hero_info.spirit_item`; a present empty Lua table is truthy, so `getSpiritSuitID()` / `getSpiritEquipsAttr()` select the empty slot cache instead of Backpack fallback and dereference nil after relogin.
- Pass171 fix: canonical self-player `HeroRepository` removes/omits `spirit_item`; unique Spirit objects remain owned only by Backpack `spirit_list`, while Hero `spirit_equip` remains six-slot ID authority. Durable load normalization self-heals stale cache fields.
- Exact smoke fixture is protected by `tools/selftest_pass171_horcrux_restart_reconciliation.py`, including a numeric materialized-attribute lookup after restart.
- Adv. Horcrux Pack `50002168` / gift `90040453` is source-defined Oath-only: six orange Oath position candidates, weights 1666/1666/1666/1666/1666/1670 = 10000. User observation is not an RNG bug.
- OTA remains 1.631.12 / 142 cumulative entries; Pass171 is backend-only.
- NEXT: targeted stock-client restart re-smoke on the preserved player state. H6 remains open; do not declare runtime closure until re-smoke and follow-up reconciliation pass.
- Permanent rule: cross-check effective `src_64` before every backend behavioral modification and preserve source fact vs runtime observation vs compatibility decision.
