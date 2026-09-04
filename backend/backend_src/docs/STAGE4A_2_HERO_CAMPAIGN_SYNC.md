# Stage 4A.2 — Hero detail stability + Campaign state synchronization

Date: 2026-08-16

This pass follows two user-confirmed facts from Stage 4A.1:

1. `HeroListWindow` works and owned Aquaris is selectable, but opening Aquaris does not finish constructing `hero_main`.
2. Normal Campaign combat already runs successfully in the client, but MID114 does not persist the clear/unlock and MID117 opens a blank sweep result.

The pass intentionally does not add combat simulation or invented rewards. It repairs one source-confirmed HeroMain data hazard and introduces the first persistent Campaign/world-state commit boundary.

## HeroMain: why the first tap can do nothing and the second tap hides UI

`HeroListCell.lua` sends MID234 for HalfPriceSkill (1032), then immediately asks `WindowManager` to open `hero_main`; the MID234 callback is not the gate.

`WindowManager:openWindow()` places the newly constructed window in its internal `windows_` registry before `loadRes()/willOpen()/layout()` finish. A synchronous exception during HeroMain layout can therefore leave an invisible half-open `hero_main` object registered. A second tap finds that registered window and can apply its background/hide-window behavior even though the first open never became visible. This matches the observed first-tap/no-op then second-tap/UI-disappears sequence.

### Exact element-equipment nil hazard

`HeroMainWindow:layout()` calls `updateElementEquip()` before `didOpen()`.

The supplied Lua contains this guard:

```lua
if not xyd.isSuperHero(hero) and not hero:getColor() == xyd.MAX_HERO_COLOR then
    return
end
```

Because of Lua operator precedence, this does not reliably exclude a normal color-3 hero. HeroMain proceeds into its four element slots.

`NormalHero:populate_()` assigns `element_equips` and `element_levels` directly. Stage 4A/4A.1 sent empty arrays. In Lua an empty table is truthy, while `elementEquips[i]` is nil. HeroMain then evaluates:

```lua
if elementEquips and elementEquips[i] ~= 0 then
```

For an empty table, `nil ~= 0` is true. It next executes `tonumber(nil)` and passes the result into the element-equipment table lookup. The source constant `xyd.MAX_ELEMENT_ITEM_NUM` is 4.

Stage 4A.2 therefore normalizes owned normal heroes to explicit empty slots:

```json
"element_equips": [0, 0, 0, 0],
"element_levels": [0, 0, 0, 0]
```

No element item IDs are invented.

If Aquaris still fails after this correction, use `tools/adb_stage4a2_hero_probe.sh`; it captures the client error DB plus targeted hot-update HeroMain Lua/CSB/effect resources so the next pass can distinguish a later Lua dependency from a missing/overridden resource.

## Campaign: the client already simulates normal combat locally

The user completed campaign `100001` with formation `10001`. The trace shows:

- MID112 `LOAD_WORLD_MAP`
- MID2768 `GET_RENT_HEROS`
- MID113 `FIGHT`
- client-local battle
- MID114 `FIGHT_RESULT` with `star=3`

`SelectTeamWindow` only consumes optional `items` from MID113 before creating the enemy party from client campaign/battle tables. `BattleCreate:campaignResult()` sends the result back through MID114 and consumes `chapter_info`, `campaigns`, and optional reward fields.

The backend therefore owns persistent eligibility/progression/rewards around the local simulator; it does not need to duplicate the normal Campaign combat engine.

## Source-derived campaign links

`data/campaign_meta.json` is generated from authoritative `src_64/data/tables/campaign.lua` and packages only:

- `campaign_id`
- `chapter`
- `next_campaign_id`
- `last_campaign_id`

It contains 917 source rows. This matters because the chain is not arithmetic:

```text
100001 -> 100002 -> 100004 -> 100005 -> ...
```

Handlers must never infer the next stage with `campaign_id + 1`.

## Canonical WorldRepository

New `gxb_backend/state/world_repository.py` owns:

- persisted `world_map` rows;
- current chapter/campaign cursor;
- best stars;
- a pending MID113 Campaign battle session;
- MID114 clear/unlock commits;
- source-shaped empty sweep results.

`player_db.json` schema is now 3 and has a first-class `player.world` section:

```text
player.world.world_map
player.world.active_campaign_battle
```

The existing request-scoped `RLock` means MID113/MID114 mutations are saved under the same refresh -> mutate -> atomic-save boundary used by HeroRepository.

## Initial campaign correction

Stage 3 used `100001 star=3` as a compatibility seed. That incorrectly marked the first campaign cleared and exposed Raid before a real win.

Stage 4A.2 fresh state is:

```json
{
  "campaign_id": 100001,
  "star": 0
}
```

with `chapter_info.normal_campaign_id=100001` and `normal_stars=0`.

After a successful `100001` result with three stars, MID114 persists/returns:

- `100001` with best star 3;
- source-next `100002` with star 0;
- updated `chapter_info.normal_campaign_id=100002`;
- updated chapter star total;
- empty `items` until rewards are reconstructed.

`BattleCreate` explicitly treats a returned different campaign with `star=0` as the newly opened campaign.

## MID117 Sweep/Raid contract

The old response `{"awards":[],"campaign_id":...}` did not match `SweepWindow`.

Stage 4A.2 returns the consumed containers:

```text
items       -> one list per sweep
 economys   -> one economy object per sweep
additional  -> additional item list
campaign    -> campaign_id/daily_limit/reset_count/etc.
```

For now rewards are intentionally empty and economy entries are explicit `{exp:0,mana:0}`. `SweepWindow` otherwise defaults missing EXP to 12, so `{}` would fabricate client-side XP.

## MID2768 empty rental contract

`SelfGuild:loadAllTeamHeros()` consumes:

```text
guild_rent_heroes.partners
guild_rent_heroes.rent_type
guild_rent_heroes.rent_count
tutor_rent_heroes
rent_count
```

Stage 4A.2 returns all of those with zero/empty values for an account with no rentals. This removes the previous compatibility fallback without inventing rental heroes.

## Deliberate non-goals

Not implemented yet:

- campaign item/mana/EXP drops;
- campaign energy spending;
- sweep-ticket/crystal accounting;
- hero level/skill/evolution mutations;
- formation semantics beyond the already-working formation string;
- server-side battle simulation;
- payment.

These should be layered onto the same HeroRepository/WorldRepository/Inventory state owners as their exact contracts are implemented.
