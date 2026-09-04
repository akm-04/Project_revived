# v0.8.1 — Fresh Tutorial Summon

## Scope

This release implements only the source-mapped fresh-account Vending tutorial exposed by the runtime-confirmed v0.8.0 multi-user rewrite. It does not implement ordinary post-tutorial gacha.

## Source-confirmed tutorial ownership

Pass 23 correlates `SummonWindow.lua`, `SelfPlayer.lua`, `summon.lua`, `dropbox.lua`, `partner.lua`, `misc.lua`, and the guide enum/text. The tutorial requires stable owned partner IDs 1/2/3:

- partner 1: Aquaris / table 10001001 / source `ini_star=1`;
- partner 2: Lavia / table 10001002 / source `ini_star=1`;
- partner 3: Pandaria / table 10001003 / source `ini_star=1`.

The opening Aquaris animation only calls `populateWithTableID(10001001)` for presentation and does not add her to `SelfPlayer`, while later guide code directly requests owned partner IDs 1, 2 and 3. Therefore v0.8.1 seeds canonical Aquaris id1 for a fresh credential character.

## Deterministic tutorial pulls

The first mapped Mana pull is MID50 `summon_type=1`, `summon_index=1`. Source `summon.lua` selects special dropbox 200005 at the first threshold; source `dropbox.lua` has only Lavia 10001002 at rate 10000.

The first mapped Crystal-free pull is MID50 `summon_type=3`, `summon_index=1`. Source selects special dropbox 200006; that dropbox has only Pandaria 10001003 at rate 10000.

These two results therefore require no invented RNG.

## MID56

`SummonRepository` is now the single canonical owner for both RETRIEVE_TOKEN detail 56 and explicit MID56. It provides:

- `mana_free_time`;
- `crystal_free_time`;
- `mana_free_num`;
- `main_ids` (at least two valid Hero table IDs);
- `second_ids` (at least three valid Hero table IDs);
- valid `mana_id`, `pet_id`, `partner_id` display IDs;
- optional `directional_show_id` if stored.

Source `misc.lua` gives Mana free duration 600 seconds, Crystal free duration 165600 seconds, and initial Mana free count 5. During the fresh tutorial both free timestamps begin at 0, which is the client's "free ready" state.

The exact historical live featured/banner IDs are not recovered. v0.8.1 uses source-valid local display policy solely to prevent `SummonWindow` from dereferencing table ID 0. This policy is stored in `data/tutorial_summon_meta.json` and is not represented as official historical server state.

## Mutation and retry behavior

The first Mana pull creates canonical Lavia id2 and persists `mana_free_time=now`, decrements `mana_free_num` once, and returns the full Hero projection with `is_partner=true` plus `summon_info`.

The first CrystalFree pull requires the Mana tutorial result, creates canonical Pandaria id3, persists `crystal_free_time=now`, and returns the same canonical result shape.

If the server committed the Hero but the response/client callback was interrupted, a retry before the corresponding guide completion checkpoint returns the already-owned Hero. It does not create another Hero or decrement a free counter twice.

Once the guide has advanced through 100105 (Mana) or 100108 (Crystal), repeating that mapped request is rejected. All other MID50 combinations are rejected with generic local error code 1 and no mutation.

## Explicitly deferred

The following remain unmapped enough that v0.8.1 does not implement them:

- paid Mana/Crystal draws;
- Crystal ten-pulls and other summon types;
- base vs super pool selection;
- rate progression/pity/reset logic;
- `fix_rate` / `fix_max_num` semantics;
- duplicate/capacity Hero-to-stone conversion;
- exact reward-juice quantity;
- historical banner rotation.

This prevents tutorial recovery from silently becoming a fabricated gacha implementation.
