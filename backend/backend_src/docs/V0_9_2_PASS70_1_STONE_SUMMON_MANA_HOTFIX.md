# Pass70.1 — MID59 Stone/Fragment Summon Mana Hotfix

Pass70.0 client smoke exposed one inherited omission: `STONE_SUMMON_HERO` (MID59) consumed the submitted Girl fragment/scroll stack and created the Hero, but did not debit the source-defined Mana summon price.

## Effective src_64 authority

- `app/windows/HeroListCell.lua` and `app/windows/HeroCollectWindow.lua` both call `xyd.tables.star:summonPrice(star)`, refuse the summon when current Mana is below that amount, and then invoke `NormalHero:stoneSummonHero()`.
- `data/tables/star.lua` defines `summon_price` by star: 1★=1,000; 2★=50,000; 3★=200,000; 4★=500,000; 5★=1,300,000 Mana.
- `app/model/NormalHero.lua` sends MID59 with `table_id`, `stone`, and `stone_num`.
- `app/model/SelfPlayer.lua` removes the submitted stone stack locally after a successful MID59 callback. `app/common/network/Backend.lua` independently consumes top-level `economy_` for cumulative scalar synchronization.

## Fix

MID59 now requires the Economy facade and, inside the existing one-player `PlayerUnitOfWork`, debits the source-defined Mana price before consuming the fragment stack and creating the Hero. Any insufficient-Mana or downstream failure rolls the entire transaction back. Pass70's journal-aware `ResponseProjector` adds the committed cumulative `economy_.mana` to the successful Hero payload; no fragment `awards` or duplicate local inventory mutation is introduced.

No MID50 vending costs, RNG/pool policy, transport, persistence schema, ResourceRegistry ownership, projection profiles, or feature scope changed.
