# Pass81.0 Technical Changelog

Backend: `gxb-backend-v0.9.10-pass81.0`

## Scope

Pass81 is a correction-only pass for the two defects diagnosed in Pass80. It does not implement MID116/117/118 or any new Task/Activities domain.

## Persistence ownership correction

`JsonPlayerDatabase.merge_preserving_extensions()` now tracks a serialized path while recursively merging dictionaries. Most dictionaries retain the existing extension-preserving merge behavior, but explicitly registered domain-owned paths use canonical replacement semantics.

Current replacement paths are:

- `player.domains.daily_consume_state.counts`
- `player.lobby.mission_state.daily_cache`
- `player.heroes.heroes.*.evo_attr_points` (retains the earlier Stone Evolution clear contract without a global key-name special case)

This means authoritative `{}` values are real clears at those paths, while unknown sibling or unrelated extension dictionaries remain preserved.

## Super Campaign remaining-attempt ownership

For wire `campaign_type = 2` only:

- MID113 now refuses to stage a battle when the unlocked Super row has `daily_limit <= 0`.
- A successful canonical MID114 (`star > 0` with the matching pending MID113 session) requires a positive remaining count and decrements `daily_limit` once before constructing the response.
- The response therefore carries the new remaining count (`3 -> 2 -> 1 -> 0`) in the touched campaign row, matching `BattleCreate.lua` authority.
- Duplicate MID114 retries are intercepted by the existing committed-response receipt before a new transaction/decrement, so exactly-once settlement remains intact.
- Normal Campaign does not use this decrement/zero guard.
- Super `reset_count` is not modified by ordinary fights. Pass79 daily rollover remains responsible for restoring the source maximum and `reset_count = 0`.
- `star = 0` attempt consumption remains deliberately unchanged pending evidence.

## Validation

Focused Pass81 self-test proves:

- old Quick Enchant counts do not resurrect after authoritative `{}` persistence;
- Task daily-cache `{}` does not resurrect;
- unrelated/future extension dictionaries survive;
- Super success sequence is `3 -> 2 -> 1 -> 0`;
- duplicate MID114 does not consume again or advance state version;
- a fourth Super MID113 is fail-closed at zero;
- the Pass79 Campaign daily reset participant restores `0 -> 3` and `reset_count -> 0`;
- Normal Campaign remains unaffected.

Relevant Pass68 through Pass79 regression self-tests are rerun after the patch and remain green.
