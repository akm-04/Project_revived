# Stage 4A.3 — Girls Skin-tab + skill-state synchronization

Date: 2026-08-16

## Runtime evidence entering this pass

User testing confirms the Stage 4A.2 HeroMain element-slot fix worked: owned Aquaris now opens normally.

The same runtime session also confirms Stage 4A.2 Campaign persistence is operational across repeated normal Campaign clears. The observed source-link sequence includes:

`100001 -> 100002 -> 100004 -> 100005 -> 100007 -> 100008 -> 100011 -> 100012`.

Normal Campaign remains client-simulated and MID114 remains the durable progression commit. Campaign rewards/energy accounting are still intentionally incomplete.

Two Girls-detail issues remain:

1. Skin tab appears to do nothing.
2. Skill-point purchase / skill upgrades are not canonical in Stage 4A.2.

## Skin-tab root cause

Stage 4A.2 normalized `illusion_skin_id` to `-1`.

`NormalHero:populate_()` copies this to `illusionSkinId_`. On the first Skin-tab click, `HeroMainWindow:clickSkinButton()` enables the Skin cache and calls `updateEquipInfoContainer()`.

That function contains:

```lua
if hero.illusionSkinId_ <= 1 then
    skinSelect = hero.illusionSkinId_ + 1
end
...
skinIllusionEquip = skinSelect
updateBtnSkinBtnShow(true, skinDatas[skinIllusionEquip].modelID)
```

With `illusionSkinId_ = -1`, the selector becomes `0`, so the code dereferences `skinDatas[0]`. This is a synchronous local failure and produces no required network request, matching the observed "does nothing" behavior.

For ordinary/non-awakened normal-card state, source semantics use illusion selector `0`. Stage 4A.3 therefore normalizes absent/negative compatibility illusion values to `0` and seeds Aquaris with `illusion_skin_id=0`.

No skin item/model IDs are invented.

## MID99 BUY_SKILL_POINT

Source call site: `SelfPlayer:buySkillPoint()`.

Consumed response fields:

- `buy_skill_times`
- `skill_point`
- `skill_time`

Stage 4A.2 had no semantic handler and returned only `error_code=0`, so the client never received a new skill-point total.

The supplied English translation for `SKILL_POINT_BUY` explicitly says one purchase buys **10 skill points**. Stage 4A.3 persists:

- `buy_skill_times += 1`
- `skill_point += 10`
- a nonzero `skill_time`

and returns those source-consumed fields.

Crystal charging is deliberately deferred. The UI-side request/response path inspected here does not expose a proven canonical crystal-sync field for MID99, and full Hero/Economy mutation remains a Stage 4D concern.

## MID39 SET_ALL_SKILL_LEVEL

`HeroMainWindow:sendSkillLevUpRequest()` sends:

- `partner_id`
- `skill_colors` — pipe-merged changed skill indexes
- `skill_counts` — pipe-merged increment counts

The callback consumes:

- `skills` — full pipe-serialized six-slot base skill vector
- `skill_point`
- `skill_time`

Stage 4A.2 treated MID39 as status-only, so neither the canonical hero skill vector nor the canonical skill-point count changed.

Stage 4A.3 moves MID39 into `HeroRepository`:

- parses the pipe/int request shape;
- validates only indexes 1..6 and positive counts;
- commits increments to the owned hero's canonical six-slot `skills` array;
- deducts the same count from canonical `player.skill_point` when sufficient points exist;
- persists the mutation atomically through the existing request scope;
- returns `skills`, `skill_point`, and `skill_time` in the form HeroMain consumes.

The older MID53 single-skill path is routed through the same repository owner so it cannot diverge if reached elsewhere.

Mana charging is deliberately deferred to the full Hero/Economy progression pass.

## Confidence labels

Source-confirmed:

- Skin-tab selector arithmetic and the `skinDatas[0]` hazard from `illusion_skin_id=-1`.
- Normal-card illusion selector `0` behavior.
- MID99 numeric ID and consumed response fields.
- `SKILL_POINT_BUY` translation granting 10 skill points per purchase.
- MID39 numeric ID, HeroMain request fields, and callback consumption of full `skills` + skill-point state.
- six skill indexes and six-slot hero skill state.

Live-confirmed:

- HeroMain now opens in Stage 4A.2.
- Skin tab does not visibly open in Stage 4A.2.
- Stage 4A.2 MID99 was compatibility-only.
- Stage 4A.2 MID39 returned bare success.
- repeated Campaign MID113/MID114 progression is operational and persists/unlocks source-linked stages.

Inferred compatibility/default:

- initializing a previously zero `skill_time` when the first skill-point purchase is persisted.

Unknown / deferred:

- exact server-side crystal debit/sync semantics for MID99.
- exact server-side mana debit/sync semantics for MID39/MID53.
- owned skin acquisition/equip flows beyond making the Skin tab itself safe to enter.

## Aquaris star provenance correction

Earlier Stage 4A memory called owned Aquaris `10001001 star=3` "source-confirmed initial star 3". That label was too strong.

Authoritative `src_64/data/tables/partner.lua` row `10001001` is Aquaris and has `ini_star=1`. The current local profile still carries `star=3`, but without an identified official capture proving that upgraded state, Stage 4A.3 classifies it as **current-profile/unknown provenance**, not source-confirmed initial star.

The backend does not change the user's current star=3 profile in this pass.

## Validation rule

Only Python syntax compilation is performed by the assistant. No Flask/HTTP/APK/ADB/emulator runtime test is performed.
