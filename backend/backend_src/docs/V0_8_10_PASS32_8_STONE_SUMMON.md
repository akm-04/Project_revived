# v0.8.10 / Pass 32.8 — MID59 Lightin Stone Summon

## Runtime evidence

The user supplied `server1.txt` and `server2.txt` plus captured client Lua errors. The successful fresh tutorial run reaches Campaign100004, completes and claims Story Mission80001, and receives the canonical `15,000` Mana plus `40001004 x10` reward. The guide then sends MID59:

`{table_id=10001004, stone=40001004, stone_num=10}`

The v0.8.9 backend routed MID59 to `RewardHandlers.awards_empty`, returning `{awards=[]}`. `SelfPlayer:stoneSummonHero()` treats the whole successful response as a NormalHero payload. The client error therefore occurs in `NormalHero:populate()` / `HeroTable:getPracticeNeeds()` because the placeholder has no Hero `table_id`.

## Source contract

- `NormalHero:getSuiPianID()` resolves the Hero's source `stone_id`.
- `NormalHero:canSummon()` requires Backpack count >= `xyd.TotalStarSuipian[star]`.
- `NormalHero:stoneSummonHero()` sends `table_id`, `stone`, `stone_num`.
- `SelfPlayer:stoneSummonHero()` constructs NormalHero from the response, adds it to the roster, and removes the submitted stone count locally.
- `xyd.TotalStarSuipian = {10,30,80,180,330}` for stars1..5.
- Catalog rows already prove Lightin Partner `10001004` has `stone_id=40001004`, while Item `40001004` is type3 and explicitly references `partner_id=10001004`.

## Backend implementation

`SummonRepository.stone_summon_hero()` now uses the request-scoped `GameDataCatalog`, `InventoryRepository`, `HeroRepository`, and `UnitOfWork`. It validates typed namespace membership, both cross-reference directions, source star threshold, non-ownership, and Backpack balance. It then consumes the contracts and creates the Hero in one UoW commit and returns the full normalized Hero record itself.

Invalid/malformed MID59 mutations fail closed using the existing Pass29 private-server nonzero compatibility sentinel rather than receiving fake OK. No historical GXB error-code assignment is asserted.

## Separate server1 guide finding

The first run did not fail in backend code. It persisted `guide_id=100262` almost immediately and then emitted no normal tutorial fight/summon progression. The next fresh run began at `guide_id=100001` and progressed normally. Source `LoadingScene.login_()` calls `StoryData.updateDataFromStorage()` after successful MID1; that method replaces the backend guide with a higher locally persisted `xyd.db.storyGuideData.guideID`. Source also identifies `100262` as `GUIDE_TREASURE_END`. This makes stale local guide state a plausible contamination path for a new server character.

Because exact original account-scoping/reset behavior is unresolved, this revision records the evidence but does not add a speculative server-side guide-ID clamp.

## Validation

Static/syntax/AST/JSON/archive only. No Flask/HTTP/selftests/ADB/emulator/gameplay execution by the assistant.
