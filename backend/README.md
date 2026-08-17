# GXB backend v0.8.7 — Pass 30.1 Skill Point / Crystal Purchase Fix

v0.8.7 is a narrow runtime correction on top of v0.8.6. It does **not** add new MIDs or widen beyond the early Campaign→Skill tutorial boundary.

Pass 30 runtime proved Campaign Crystal grants and FunctionID33 unlocks work, then exposed two Skill Point state defects and one MID99 Economy omission:

1. **Fresh Skill Point pool.** New credential players now start at the effective-source natural cap for their current VIP (VIP0 => 10) with `skill_time=0`, the client's full-pool/no-regeneration sentinel. This is a runtime-informed compatibility policy using source-derived cap data; it is not claimed as a recovered historical account-creation row.
2. **Skill timer sentinel/cap semantics.** `skill_time=0` is preserved on player-info responses instead of being replaced with server-now. Spending from a full natural pool starts the timer; gains at/above the natural cap stop it. Purchased points can exceed the natural cap because the cap governs timed recovery, not absolute inventory.
3. **MID99 Crystal spend.** Skill Point purchase cost is now derived from effective `refresh_cost.lua`, VIP permission from effective `vip.lua`, and the +10 grant from effective `translation.lua`. The server repeats those validations, spends Crystal through `EconomyRepository`, increments `buy_skill_times`, grants the points, normalizes the timer, saves once, and lets `ResponseProjector` attach cumulative `economy_.crystal`.
4. **Effective-source enforcement.** `hero_skill_regen_meta.json` now carries `source_resolution=effective_merged` and is rejected at runtime if that provenance stamp is absent.

No Story Mission, Campaign drop RNG/stamina, Skills pricing/level formulas, Institute, Guild or PvP semantics are expanded by this patch.

See `docs/V0_8_7_PASS30_1_SKILL_POINT_CRYSTAL_FIX.md`. v0.8.6 Campaign Crystal/Function Unlock/Story Mission behavior remains the baseline and is documented in `docs/V0_8_6_PASS30_CAMPAIGN_CRYSTAL_FUNCTION_MISSION.md`.

# GXB backend v0.8.5 — Pass 29 P0 Guardrails + Phase-1 Economy Spine

v0.8.5 is an incremental architecture hardening release on top of v0.8.4. It does **not** add new gameplay MIDs.

Pass 29 changes four shared foundations:

1. **Mutation-safe compatibility boundary.** Unknown engine MIDs no longer receive unconditional empty success. Empty fallback is permitted only for numeric MIDs in `data/compatibility_safe_mids.json`, whose entries are backed by retained audit/ownership evidence. Everything else returns a local nonzero unsupported response. Existing explicit handlers are unchanged.
2. **Atomic Phase-1 Economy API.** `EconomyRepository` now supports validated single-commit Mana, Crystal, Energy and cumulative player-EXP mutations, including source-confirmed level/max-energy/level-up-energy side effects. Campaign Mana+EXP uses the same atomic delta transaction.
3. **Request Response Projector.** `ResponseProjector` snapshots request-bound canonical state and automatically merges changed cumulative `economy_` (`mana`, `crystal`, `energy`, `exp`, `lev`) and Hero `exps` rows into ordinary handler payloads. Existing explicit projections are normalized/merged. Skill Point is intentionally outside this Phase-1 projector because of the known MID90 client-path exception.
4. **Effective-source economy metadata.** `tools/build_campaign_economy_meta.py` now resolves each consumed source path through writable-hot-update-over-APK precedence. Runtime `EconomyRepository` refuses economy metadata not stamped `source_resolution=effective_merged`. The packaged metadata was regenerated from the supplied recovery tree using that resolver.

No Campaign drop RNG, stamina timing, Mission rewards, new Shop/PvP/Guild behavior, or new MID mapping is introduced by this release.

See `docs/V0_8_5_PASS29_P0_ECONOMY_SPINE.md` and canonical Pass 29 for the implementation contract.

# Historical v0.8.4 baseline — Tutorial Guide + Canonical Hero Gear Fix

v0.8.4 is the next narrow runtime correction on top of the Pass 25 economy architecture and the user-runtime-confirmed v0.8.3 Campaign progression slice. It does **not** change the v0.8.3 Campaign Mana/player-EXP/Hero-EXP/Energy transaction.

The fresh v0.8.3 runtime proved that Campaign now advances smoothly past the former post-MID114 loading freeze, Mana accumulates, level-up presentation works, later stages open, and the original tutorial progresses substantially farther. That successful progression exposed three downstream client/server contract gaps.

## 1. Tutorial double-overlay compatibility

The stuck text `Let's get that letter!` is source guide **100135**, the Fight-3 Campaign-node guide. It is not the later Hero-scroll text; the explicit scroll guide is **100147** (`It's a battle girl's scroll!`).

The backend previously returned A for every MID2864 A/B key. Authoritative `abtest.lua` defines MTSPY as:

- A: use the extra weak/function guide;
- B: do not use the extra weak/function guide.

At player level 7, guide-function 17 becomes eligible. The runtime dump shows the old strong story guide and the weak/function-guide path colliding, followed by MID2865 for guide-function 17 after the user skips the overlay.

v0.8.4 therefore returns **B only for `unique_key=mtspy`**. Other A/B keys keep the previous compatibility value A. This is a local compatibility policy selecting a source-defined client branch; it is not claimed to reproduce the historical live-server cohort assignment.

## 2. Generated-name response shape

MID119 `GENERATE_PLAYER_NAME` previously returned `{name=...}`. Source `EditPlayerName:onGeneratePlayerName_()` requires `player_name_list`, and the runtime showed a nil `nameList` Lua error.

v0.8.4 returns a non-empty `player_name_list` populated with deterministic source entries from `random_name.lua`. Exact historical random sampling remains unknown.

## 3. Canonical early Hero equipment / promotion

The v0.8.3 runtime exposed that three early Hero mutation MIDs were still status-only compatibility stubs:

- MID54 `SET_HERO_EQUIP`;
- MID62 `ONE_CLICK_EQUIP`;
- MID57 `ONE_CLICK_JINJIE`.

The source explains the different symptoms:

- MID54 can look correct in-session because the client consumes the exact equipment and marks the slot locally after OK, even if the server persists nothing.
- MID62 only updates the Hero if the response includes `equips`; status-only OK therefore plays the animation but leaves Aquaris/Pandaria visually unequipped.
- MID57 locally increments color/clears gear after OK, so Lavia can appear promoted while canonical server Hero/Backpack state remains unchanged and would diverge on relog.

v0.8.4 adds a canonical `HeroEquipmentRepository` for the **early ordinary NormalHero** path. The requests carry only `partner_id` (and MID54's slot), so the server independently mirrors the supplied client source calculation using generated authoritative metadata:

- current-color six-slot equipment requirements from `partner.lua`;
- equipment level/compose recipes/compose counts/compose Mana from `item.lua`;
- source Hero EXP thresholds and the player-derived Hero level cap;
- source EXP-juice order `50001001, 50001002, 50001004, 50001005, 50005182`.

The transaction validates canonical state, consumes Backpack materials/potions, spends compose Mana through the shared `EconomyRepository`, grants canonical Hero EXP when potions are needed, persists equipment/color state, saves once, and projects the response fields the client actually consumes.

This preserves the Pass 25 ownership rule: Hero equipment does not keep a private Mana balance.

## Deliberate v0.8.4 boundary

Still not implemented here:

- awakened/bloodline/Fumo restoration semantics beyond the safe fresh/early NormalHero path;
- Story Mission MID2736/MID161 state/rewards;
- MID59 Hero-contract/stone summon;
- MID118 chapter-star rewards;
- Campaign stamina deduction / defeat-cost semantics;
- general `campaign_dropbox.increase_rate` RNG or repeat-clear random drops;
- general post-tutorial Vending RNG/pity;
- Arena/PvP invitation mechanics.

The next authentic tutorial boundary is expected to expose one of the already-mapped Story Mission/equipment-adjacent systems; do not broaden those with guessed behavior.

## Recommended runtime test

For the cleanest validation, use a **fresh credential account**. A v0.8.3 account can be copied forward, but any MID54/MID57/MID62 actions already performed under v0.8.3 may exist only in that old client's local session and were not canonically persisted.

Preserve resources as usual if needed:

```bash
cp -a /path/to/v0.8.3/local_assets/res/. \
      /path/to/v0.8.4/local_assets/res/
```

For a clean fresh test, do not copy old credential `server_state`. If deliberately continuing an old account, copy it as usual and expect past status-only Hero mutations to reflect the old canonical state after relog.

Check specifically:

1. Campaign `100001` still clears smoothly with the v0.8.3 economy behavior unchanged.
2. The Fight-3 `Let's get that letter!` guide does not get a second weak-guide overlay.
3. MID119 generated-name UI no longer throws the `nameList` nil error.
4. Tutorial MID54 consumes the exact gear canonically and survives relog.
5. MID62 one-click equip returns visible equipment and that equipment survives relog.
6. MID57 one-click promotion persists color, consumed materials/potions, and any compose-Mana spend.

See `docs/V0_8_4_RUNTIME_HERO_GUIDE_FIX.md`, root `memory.md`, and cumulative Pass 26 for provenance.

## Validation policy

Assistant validation for this package is deliberately limited to Python static compilation. No Flask/HTTP, selftest, APK/ADB/emulator, or gameplay runtime test is executed by the assistant; user-device testing remains authoritative.
