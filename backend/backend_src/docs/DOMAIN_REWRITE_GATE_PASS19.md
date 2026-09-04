# Domain Rewrite Gate Pass 19

Pass 19 does not close the frontend mapping effort. It improves the rewrite plan by turning dynamic request records into domain families.

## Backend rewrite should be domain-owned

The eventual backend should avoid one Python function per source call site. Use canonical state owners:

| Domain | Owns | Pass 19 evidence |
| --- | --- | --- |
| `practice` | hero/pet practice state, lock/ticket/auto wash, practice attrs | dynamic wash branches resolve to MIDs 124–133 |
| `arena` | arena formations, record summaries, replay reports, pre-fight gates | dynamic arena/rank/record branches resolve to MIDs 285/290/291/293/294/295/298/299/1364/2803 |
| `activity` | activity details, star awards, map sweeps, fishing equipment | activity base/fishing/sweep dynamic branches are campaign-dependent |
| `social` | friends, requests, recommend lists, social sends | several symbolic source gaps still lack numeric MID values |
| `chat` | room discovery HTTP and TCP/chat messages | HTTP 192 mapped; TCP/chat payload still incomplete |
| `battle_result` | zlib/form-data/result submissions and report creation | `PEAK_FIGHT_RESULT` is undefined and uses special request flags |

## Current gate result

A backend rewrite is still premature if the goal is “complete client functional and happy.” A focused boot/first-entry backend can be coded now, but the full backend structure should wait for at least one more domain pass over:

1. activity-specific `details` payloads and `LOAD_SINGLE_ACTIVITY`;
2. battle/result submission MIDs and compressed/form-data paths;
3. social/friends undefined-symbol APIs and any alternate numeric definitions in assets/captures;
4. shop/market/magic-shop source gaps;
5. guild/chat TCP details if guild/social UI must work.
