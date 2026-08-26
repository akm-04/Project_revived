# v0.17.4 Pass171 — Horcrux H6 restart reconciliation

Pass170's first coherent stock-client Horcrux smoke verified the implemented H1-H5 surfaces through live-session use, then exposed a restart-only failure on the one Hero with nonzero persisted Horcrux equipment. The backend correctly persisted the six Spirit IDs and the Backpack correctly contained every referenced unique instance. The defect was the additional fabricated `spirit_item=[]` field in the owned-Hero MID49 payload.

Recovered `NormalHero.lua` assigns `spiritItems_` directly from `hero_info.spirit_item`. On the client, an empty Lua table is truthy. `getSpiritSuitID()` and `getSpiritEquipsAttr()` therefore use `spiritItems_[slot]` when that field is present and only fall back to `Backpack:getSpiritItemBySpiritID(spirit_id)` when the field is absent. During a live equip session `setSpiritEquips()` had populated the cache, hiding the bug until relogin.

Pass171 makes the self-player ownership split explicit: Hero `spirit_equip` stores six persistent instance IDs, Backpack `spirit_list` stores the unique Horcrux objects, and `HeroRepository` does not persist/project a duplicate `spirit_item` cache. Load maintenance removes stale cache fields while preserving the equipment IDs and instances. A regression reproduces the exact KM-Moe smoke fixture and a second restart.

The smoke observation that Adv. Horcrux Pack always produced Oath is not a defect. Source gift `90040453` contains six orange Oath candidates, one for each position, totaling 10000 weight.

No OTA patch is required. H6 remains open pending a targeted restart re-smoke.
