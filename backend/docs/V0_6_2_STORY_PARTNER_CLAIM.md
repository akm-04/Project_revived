# v0.6.2 — Campaign special-story partner claim

Date: 2026-08-17

## Live blocker

After the v0.6.1 packaged resource probe made Campaign `200002`'s runtime downloads
observable, the user completed the battle and reached `BattleSpecialStory`. Selecting
either offered girl repeatedly produced:

```text
MID2064 GET_STORY_DROP_PARTNER
story_drop_partner=10001005 or 10001008
campaign_id=200002
campaign_type=1
```

The v0.6.1 backend had no semantic MID2064 handler and returned only:

```json
{"error_code": 0}
```

No MID114 followed because the client was still inside the special-story sequence.

## Source contract

Authoritative `src_64/app/windows/BattleSpecialStory.lua` constructs MID2064 with:

```text
campaign_id
story_drop_partner
campaign_type
```

Its callback advances only when all of the following are true:

```text
code == OK
response exists and is non-empty
response.story_drop_awards exists
response.story_drop_awards is non-empty
```

The callback then calls:

```text
SelfPlayer:handleRewards(response.story_drop_awards, callback)
```

and only that completion callback advances the story.

Pass 19 independently identifies `story_drop_awards` as the immediate MID2064 response
field consumed by this sole audited callsite.

## Source-defined choices

Authoritative `src_64/data/tables/campaign.lua` row `200002` has:

```text
story_drop_partner = 10001005|10001008
```

No other supplied Campaign row has a non-zero `story_drop_partner` field.

Authoritative encoded `src_64/data/tables/partner.lua` gives:

```text
10001005  ini_star=1
10001008  ini_star=1
```

The current English source names are Geisha and Joan respectively; names are not used
as protocol keys by the backend.

These values are generated into `data/campaign_story_drop_meta.json`. The handler does
not hard-code a numeric choice or star.

## Why the award must be a Hero payload

`SelfPlayer:handleRewardsWithoutShow()` treats each award with `is_partner == true` as
a Hero reward:

1. it creates a `NormalHero`;
2. calls `NormalHero:populate(reward)`;
3. adds it to the local player's Hero collection;
4. `handleRewards()` opens `summonHeroWnd` using `reward.table_id`;
5. after the Summon Hero window closes, the supplied callback continues the special
   story.

Therefore v0.6.2 returns the canonical normalized Hero record produced by
`HeroRepository`, augmented with:

```json
{"is_partner": true}
```

The backend-generated `partner_id` is a local owned-Hero instance ID; the selected
`table_id` and its initial star are source-derived.

## Persistence and replay guard

The source checks `worldMaps_[campaignID].is_partner_drop` before enabling the special
partner-drop story. MID114 later consumes returned Campaign rows and stores their
`is_partner_drop` field.

MID2064 occurs before MID114, so v0.6.2 performs one atomic state commit at claim time:

```text
HeroRepository new owned hero
+
world row is_partner_drop=1
+
pending MID113 story_drop_claim {table_id, partner_id}
```

The pending claim makes an identical MID2064 retry idempotent: the server reuses the
same canonical Hero record instead of creating another persistent copy. A different
choice after the first accepted claim is rejected with an empty award list.

MID114 then preserves/returns the already-marked world row and clears the pending
battle session as usual.

## Validation guards

A new claim is accepted only when:

- the Campaign is present in the source story-drop metadata;
- the selected `story_drop_partner` is one of that Campaign's source options;
- the Campaign exists in the current unlocked world map;
- `active_campaign_battle.campaign_id` matches;
- the pending Campaign type matches the MID2064 request;
- `is_partner_drop` has not already been committed;
- the selected partner has a source `ini_star`.

No new error code is invented for an invalid/manual request; the source-consumed field
is returned empty instead.

## Runtime test

With the progressed player DB:

```text
Campaign 200002
→ finish battle
→ special-story girl choice
→ choose one candidate
```

Expected server sequence:

```text
MID2064
OUT story_drop_awards=[owned Hero payload]
...
MID114
```

Expected client/state results:

- Summon Hero presentation opens for the selected table ID;
- story continues after that presentation closes;
- MID114 completes Campaign progression;
- selected girl appears in Girls immediately;
- selected girl persists after relog;
- the Campaign world row persists `is_partner_drop=1`;
- replay should not re-offer the one-time special partner choice.
