# Update notes — v0.16.2 / Pass141.0

- Added sandbox-only Pass141 Phase4 MID241 QA seed: all 100 supported random source packages + Orange/Purple/Optional deterministic boxes, target 20 each and source-stack bounded.
- Seed is one-shot/non-replenishing after marker `pass141_debug_mid241_qa_seed_v1`.
- Added exact 100-operation → 96-pool / 134-occurrence QA mapping and click-by-click Phase4 plan.
- Fresh `src_64` route map: MID70 is the Magic Vending Machine (Summon machine4); `gift.equip` packs are Backpack consumable gift packages, not a separate equipment menu.
- No gameplay policy, ROS, settlement, Pet lifecycle, generated Horcrux, `gift.equip`, or OTA behavior changed.

---

- Completed Phase 3: activated 100 ordinary random MID241 operations / 100 source items / 134 ordered draw occurrences.
- Fresh effective `src_64` feedback loop reconfirmed the catalog byte-for-byte before modification.
- Added request-scoped `GiftRandomOutcomeAdapter` namespace `gift.open`; ROS remains policy-free entropy mechanics.
- Compatibility policy: positive raw `drop_rate` = relative integer weight; zero-weight candidates cannot win; all-zero pools fail before draw; repeated `gift.drops` occurrences are not deduplicated; `num` repeats the gift operation and aggregates awards.
- Preflight rejects invalid/insufficient/unsupported operations before entropy or mutation; post-RNG settlement failures roll back the player UoW.
- Reused existing Gift Opening, StackInventory, RewardTransactionService, MutationSettlementService, Economy/Progression owners and PlayerUnitOfWork.
- 199 `gift.equip` rows stay fail-closed and are deferred into Girls/Equipment Economy Closure; generated/unique lanes also remain deferred.
- No MID241 UUID/receipt and no Lua/OTA modification. OTA remains **1.631.8**.
- Next: Phase 4 client smoke/debug and runtime acceptance.
