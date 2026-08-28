# Pass192 — P1-I5 Runtime Reconciliation / Workshop Retest Preparation

## Scope
Pass192 reconciles the first stock-client P1-I5 smoke against Pass190 and effective `src_64`. It fixes only runtime-proven P1 compatibility defects and adds a sandbox-only QA material fixture needed to exercise the still-unclosed Workshop paths. P2 Awakening/Blood-Awakening remains deferred behind the existing HTTP409 fail-closed fence.

## Runtime observations
- Courses: stock client exercised first Study, Speed, four Continue/Speed cycles through 100%, Course proficiency items, binding, and later-login persistence.
- White Album: normal claim interactions and later-login persistence were exercised without a new Album Lua error; special claim remained unexercised.
- Common/Element Equipment: stock client equipped/levelled/swapped Element equipment and the later login retained state.
- Workshop: GET_BUILDING_LIST and GET_CABINET_INFO loaded, but building upgrade and Cabinet learn/speed/cancel/confirm could not be exercised because the sandbox lacked materials.
- Client produced two actionable Lua failures: Course `roomInfo.study_infos` nil on first Electives entry, and Shop `table index is nil` on Course bookstore load.
- Course proficiency runtime sent a legal final +50 item at 1650; Pass190 rejected the 1680-crossing action.

## Effective-src_64 feedback loop
- `SelfPlayer.loadGameStartInfoEvent_()` explicitly consumes bootstrap MID2137 `GET_STUDY_INFOS` and calls `Course:setStudyInfos()` before Course UI paths use `roomInfo.study_infos`.
- `Shop:onShopInfo_()` unconditionally indexes `shop_type`, `refresh_times`, `open_time`, `is_open`, `count_down`, `items`, `hot_hero`, `cost_stone`, and `is_awarded`; `ShopType.COURSE=29`.
- Course source maximum total proficiency is 1680. Exact original-server overflow semantics are unrecovered, but stock runtime demonstrates the client can submit a whole item crossing the cap.
- `FragmentMake.lua` hides quantity controls for `BOOK_FRAGMENT`, prevents composing when the target book is already owned, and sends MID83 with the target item id.
- Effective encoded `item.lua` gives Introduction book `130001001` compose requirement `140001001 x20`, zero Mana. Across the 54 Cabinet books, 40 have ordinary fragment compose recipes; the other 14 are left untouched rather than fabricated.
- Source Bookshelf rows 1..99 consume cumulative Magic EXP resource 14 = 51,390 to reach level 100.

## Bounded implementation
1. Add MID2137 `study_payload()` to stage3 bootstrap so stock Course model initializes `roomInfo.study_infos` before first Electives entry.
2. Make generic shop payload source-shaped enough for Course Shop type 29, preserving older aliases.
3. Course proficiency terminal compatibility policy: when current proficiency is below 1680, consume the whole submitted source item and cap durable proficiency at 1680. Already-max remains rejected. This is **COMPATIBILITY_POLICY / STRONG_INFERENCE**, not recovered original-server overflow truth.
4. Extend the generated Workshop source catalog with the 40 effective Cabinet book compose recipes from `item.lua`, and teach its generator to reproduce the catalog byte-identically.
5. MID83 gains only a Cabinet ordinary-book lane. It uses existing `PlayerUnitOfWork` + `MutationSettlementService` + inventory/economy owners for atomic fragment debit / optional Mana debit / book credit. Other MID83 families retain their historical compatibility stub.
6. Sandbox-only, one-shot QA seed raises missing `magic_exp` to 51,390 and starter fragment `140001001` to 20. It never changes Workshop levels/jobs, never replenishes consumed materials, and never applies to credential accounts.

## Preserved boundaries
- Course study completion +20 points capped 100 remains the pre-existing explicit compatibility policy, not source truth.
- Workshop cancellation ordinary-resource refund remains `floor(original_cost * remaining / total)` compatibility policy; exact original formula remains unknown.
- Exact original max_color schedule remains unknown; inherited compatibility value 5 remains unchanged.
- P2 Awakening/Blood-Awakening remains HTTP409 fail-closed.
- P1 is **not runtime closed** until the patched build is stock-client retested, especially Workshop Bookshelf/Cabinet mutations and the three corrected Course surfaces.
