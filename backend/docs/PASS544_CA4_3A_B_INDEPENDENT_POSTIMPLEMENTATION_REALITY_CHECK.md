# Pass544 CA4-3A-B / Aggregate CA4-3A Independent Postimplementation Reality Check

Status: **GREEN — CA4-3A LOCAL ACCEPTANCE CANDIDATE / COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; NATIVE AGGREGATE GATE DEFERRED**

Authority parent: sealed Pass542 CA4-3A research/design plus the user's explicit authorization to implement CA4-3A-A then CA4-3A-B. Immediate implementation parent: immutable Pass543 CA4-3A-A archive SHA-256 `49594fba218171fd936e7bb9b60f062bf7f5fb9e3477cebd9a6ddda9cbe6512f`.

## Independent reread scope

This check reread the sealed Pass542 Fumo source oracle, MID58 adversarial vectors, implementation contract and acceptance matrix; the complete produced CA4-3A-A/B code; the exact Pass543→Pass544 delta; and the relevant current Hero/I5/content/dispatcher ownership seams. Frozen V1 remains differential/corroborative evidence only. Compatibility-copy execution is not promoted to exact-toolchain/PostgreSQL/River or physical stock-client proof.

## Findings

1. **CA4-3A-A durability remains correct.** Hero owns exactly six nonnegative raw Fumo totals. No independent durable `fumo_levels` authority or Fumo aggregate was introduced. The existing cohesive Hero CAS carries Fumo with level/EXP/equipment state.
2. **Content remains exact-source and revision-bound.** `HERO_FUMO_CA4_3A` still regenerates at content revision `aa89ed03a9315a9faf8392b9beb4141594ad911033483659ea0c31674a79dc83`, preserving 359 mapped Hero Fumo targets, 516 stock-reachable Hero-Fumo materials, sparse/fractional stage deltas, and the sealed source oracle SHA-256 `42c10c67be67278d83e81512403b0b3318d30ae9f957e878dbc1c9ee0596dbd0`.
3. **MID58 wire is strict and stock-shaped.** Dispatcher accepts only `partner_id`, `equip_index`, and `materials`; duplicate material occurrences remain meaningful. No nonce, expected-old-Fumo, reroll/lock field or later-stage parameter was invented.
4. **Target validation is bounded.** FeedFumo requires a Normal Hero, collected current slot, valid mapped item and active Fumo target policy. Unsupported/Super/non-Fumo/maxed targets reject without Hero/I5 mutation.
5. **Material accounting matches the sealed contract.** Raw supply is `sum(moneng * occurrence_count)`. Duplicate requested copies are counted individually. Every requested occurrence is debited on success, including overfeed value that is not credited.
6. **Credit and Mana semantics are correct.** Credited gain is capped at remaining target capacity. Mana debit is computed from credited Fumo only (`credited * fumo_mana`), matching current/old-client display semantics and frozen-V1 differential behavior.
7. **I5 ownership and lock composition remain clean.** CharacterHero reuses the accepted CA4-2B prepared-resource seam; no foreign-owner inventory/Mana SQL or new transaction framework was added. I5 owns canonical stack/Mana reads and writes.
8. **Hero mutation remains cohesive.** Only the target slot's raw Fumo changes; one Hero state CAS persists the result. Fumo level is derived from raw state and immutable thresholds for response projection rather than persisted separately.
9. **Semantic receipts remain same-operation exactly-once.** Effectful MID58 outcomes are receipted. Replay with the same operation identity and fingerprint returns the recorded Fumo/level result without a second material/Mana debit or Hero save.
10. **Cross-request lost-response ambiguity is preserved rather than fabricated away.** A new HTTP retry receives a new server operation identity. Because stock MID58 has no reusable client nonce or expected-old-Fumo value, an identical retry can be observationally identical to an intentional second feed. No parameter-hash or time-window dedupe was invented.
11. **Stock response projection is bounded.** Successful MID58 returns the new target raw `fumo`, six derived `fumo_lev` values, and authoritative current `economy_.mana`. The generic postcommit Mana read is projection only and is not gameplay authority.
12. **MID58 production activation is qualified.** The production Hero registry is exactly `{49,52,55,58,63,67,89}`. Current Super base equipment is Fumo-ineligible, and direct unsupported-family rejection is stock-safe because the current MID58 callback mutates local state only on OK.
13. **Later routes remain correctly inactive.** MID29, MID51, MID57, MID54 and MID62 are not production-registered by this stage. Quick Fumo, promotion/reset, Pet/Super Fumo gameplay and final battle-stat materialization were not pulled forward.
14. **Special/Awakening compatibility remains intact.** Slot-owned raw Fumo and RawEquipmentState permit valid current special mappings, preserving the future CA4-3B rule that qualifying special/Awakening state can survive transitions while ordinary slots may be cleared.
15. **The Pass543→Pass544 delta is narrow.** Product changes are limited to MID58 application service, Fumo content adapter lookup qualification, dispatcher/interface/production registration, tests/archguard/stage validator, and production dependency composition. CA4-3A-A content/persistence design was not rewritten during B.
16. **Sealed adversarial evidence is unchanged.** The embedded 17-vector fixture is byte-identical to sealed Pass542 SHA-256 `063c8b17d72f423b62533d00b4e18453d0b159d1fa1927fc4ef40313ce34b3e7`; focused tests execute the success/rejection cases and dedicated receipt/protocol-limit tests cover the remaining contract cases.
17. **Canonical pins remain pristine.** `.go-version`, `go.mod` and `go.sum` retain their accepted hashes; the exact canonical executable attempt is blocked only because the sandbox cannot fetch pinned Go 1.27.1.
18. **Independent aggregate checker is GREEN.** A fresh 59-assertion check revalidated source/vector hashes, durable-state shape, MID58 formulas, I5 reuse, receipt behavior, route activation, out-of-scope exclusions, canonical pins and normal-chat evidence: **59/59 GREEN**.

## Test/evidence classification

- Exact canonical Go 1.27.1 attempt: **ENVIRONMENT_BLOCKED** at toolchain download/DNS; canonical files unchanged.
- Canonical static/source proof: CA4-3A-B validator GREEN; sealed Pass542 Fumo source oracle GREEN; immutable content regeneration GREEN; content/character query-text freshness GREEN; schema/query ownership GREEN; sqlc-generation policy GREEN; dependency policy GREEN.
- Fresh disposable compatibility clone: focused tests GREEN; focused race GREEN; `go vet ./...` GREEN; archguard GREEN; sealed MID58 fixture identity GREEN; bounded package-by-package **92/92 go test GREEN**.
- Independent aggregate reread/check: **59/59 GREEN**.
- Real PostgreSQL/River/native aggregate proof: **NOT RUN / DEFERRED by sealed lifecycle to `CA4_AGGREGATE_PRE_CA4_E_NATIVE_WORK_GATE`**.
- Physical unmodified stock-client proof: **NOT RUN / W2 lifecycle obligation remains open**.

## Verdict

**GREEN for CA4-3A local phase acceptance under compatibility-copy executable constraints.** No product defect, ownership contradiction, source/content mismatch or stage leakage was found. MID58 may remain production-registered under the bounded stock-protocol lost-response limitation documented above. CA4-3A can be sealed locally and the next internal frontier may advance to **CA4-3B Hero Promotion/Reset MID51/MID57 research/reconciliation**. The accumulated native PostgreSQL/River/exact-toolchain gate remains mandatory at the previously sealed pre-CA4-E point and is not satisfied by this result.
