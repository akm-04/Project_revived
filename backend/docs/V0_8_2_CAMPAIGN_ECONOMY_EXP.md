# v0.8.2 — Campaign Economy + EXP Foundation

## Scope

This release implements only Pass 25's source-certain ordinary Normal Campaign reward transaction. It is deliberately not a complete Campaign reward/RNG implementation.

## Source contracts implemented

Authoritative `src_64/data/tables/campaign.lua` provides `energy_cost`, `partner_exp` and `mana_gain`. `SelfPlayer:getExpMulti()` returns 3 for ordinary player/team EXP presentation. `src_64/data/tables/player.lua` provides cumulative player EXP thresholds and per-level metadata. `src_64/data/tables/partner_exp.lua` provides cumulative Hero thresholds.

MID113 stages the source-certain first-clear items before local combat. MID114 commits them on a win. The same pending battle now also stages the deterministic scalar reward plan so MID114 can atomically commit it.

### Player economy projection

For Normal Campaign only:

`player_exp_gain = campaign.energy_cost * 3`

`mana_gain = campaign.mana_gain`

The server persists cumulative `PlayerState.exp`, derives/persists `PlayerState.lev`, persists cumulative Mana, and returns changed cumulative values under `economy_`.

Current energy is intentionally not mutated. `player.max_energy` is updated to the source row corresponding to the canonical level for bootstrap/future coherence, but stamina spending and level-up energy awards remain a later transaction decision.

### Hero EXP

Each unique participating owned `partner_id` from the pending formation receives the full source `campaign.partner_exp`. The mutation uses the existing source-derived Hero EXP thresholds and the post-player-EXP Hero cap. MID114 returns `exps=[{partner_id, exp}, ...]` where `exp` is the new cumulative Hero EXP.

### First-clear items

The existing conservative policy remains unchanged: only source `init_dropbox` rows with `increase_rate == 10000` are staged/granted, quantity one per selected row. Lower-rate first-clear rows and all repeat dropbox RNG remain unresolved.

## Retry/idempotency

After a valid MID114 commit, `active_campaign_battle` becomes a persisted committed receipt containing the request identity and detached response. An identical MID114 received before the next MID113 returns that receipt without applying rewards again. The next MID113 overwrites the receipt and begins a new reward transaction.

This also works across backend restarts because the receipt lives in canonical per-player JSON.

## Architecture introduced

- `gxb_backend/state/economy_repository.py` — canonical cumulative Mana/player-EXP/level owner.
- `HeroProgressionRepository.grant_battle_exp()` — reusable canonical battle EXP mutation.
- `WorldRepository` — transaction coordinator and response projector for this Campaign slice.
- `data/campaign_economy_meta.json` — source-derived Campaign/player progression metadata.
- `tools/build_campaign_economy_meta.py` — regenerates metadata from authoritative `src_64` without executing Lua.
- `tools/selftest_campaign_economy.py` — offline state + persistence + duplicate-result test.

## Explicitly deferred

Pass 25 proved that general Campaign drop RNG is server-owned, but the exact `increase_rate` algorithm is absent from Lua and cannot be safely invented. v0.8.2 therefore does not add random repeat items.

Campaign energy spending/defeat semantics, Missions, equipment mutation, contract summon and chapter-star bonuses remain separate later slices. This release should be expanded through repositories/transactions rather than by adding independent currency fields to feature handlers.
