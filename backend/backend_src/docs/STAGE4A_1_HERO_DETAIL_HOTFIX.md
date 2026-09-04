# Stage 4A.1 — owned-girl detail window hotfix

## Live discriminator

Stage 4A is confirmed to open the Girls list. Pressing owned Aquaris then emits
MID234 `LOAD_SINGLE_ACTIVITY` with `activity_id=1032`; Stage 4A answered only
`{details:{}}`, after which the client becomes unusable.

## Source-confirmed activity failure

`HeroListCell.lua` sends MID234 for `xyd.Activities.HalfPriceSkill` immediately
before opening `hero_main`. `HalfPriceSkill` is activity table ID 1032.

`Activities:onLoadSingleActivity_()` treats the successful response itself as an
activity row. It reads `params.table_id`, removes the matching row if one exists,
and then inserts the response at the prior/current list position. With Stage 4A's
bootstrap MID229 `list=[]`, the insertion position can be zero. The old response
also omitted `table_id`.

After insertion, `checkHalfPriceOpen()` compares the 1032 row's `start_time` and
`end_time` against `ServerTime`. Therefore a safe inactive common envelope needs
at least:

```json
{
  "table_id": 1032,
  "is_open": 0,
  "start_time": 0,
  "end_time": 0,
  "days": 0,
  "details": {}
}
```

Stage 4A.1 keeps that inactive row in MID229 and returns the same common envelope
from MID234. This is compatibility state, not a claim that the historical event
was active. Full activity scheduling remains Stage 4G.

## Source-confirmed HeroMain hazard

`NormalHero:populate_()` leaves omitted dorm fields as nil.
`HeroMainWindow:updateFuncBtn()` then calls `hero:getHouseInfo()` and evaluates
`house_id > 0`. An omitted `house_id` can therefore fail synchronously even when
MID234 is corrected.

Stage 4A.1 normalizes an owned non-dorm hero with explicit zero/empty values for
`house_id`, `house_table_id`, `house_comfort`, `house_equips`,
`house_expand_lev`, favor/marriage fields, dynamic-card strings, collection-stage
fields and other source-consumed detail scalars. No new hero/table IDs are invented.

## Expected test

1. Login and stable lobby remain unchanged.
2. Girls list still opens.
3. Press Aquaris.
4. MID234 response should now include `table_id:1032`, `is_open:0`, and timing fields.
5. Aquaris `hero_main` should remain interactive.

If `hero_main` opens but a specific tab/button fails, capture that action as a new
narrow Stage 4A.x dependency rather than widening the whole Hero domain.
