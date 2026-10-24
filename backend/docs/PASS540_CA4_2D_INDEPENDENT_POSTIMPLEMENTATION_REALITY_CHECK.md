# Pass540 CA4-2D / CA4-2 Aggregate Independent Postimplementation Reality Check

Status: **GREEN — CA4-2 LOCAL ACCEPTANCE CANDIDATE / COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; NATIVE AGGREGATE GATE DEFERRED**

Authority parent: sealed Pass536 CA4-2 research/implementation contract and design checkpoint, plus the user's explicit staged CA4-2A→B→C→D authorization. Immediate implementation parent: immutable Pass539 CA4-2C archive SHA-256 `1c2d1d7f1caf2bd1b96d37a1711a056ce5159f0239575676ddad62f6e8427a32`.

## Independent reread scope

This check reread the hash-verified current `src_64` NormalHero, SuperHero, HeroMainWindow and Backend mechanics, the sealed Pass536 CA4-2 contract, the CA4-1 equipment/content seams, the complete produced CA4-2A/B/C/D code, and the exact C→D diff. It did not treat frozen V1 as original-server truth and did not promote compatibility-copy execution to exact-toolchain/PostgreSQL/River or physical stock-client proof.

Direct source hashes rechecked from the verified current-source archive:

- `NormalHero.lua` `125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9` — MID62 sends only `partner_id`; MID54 sends `partner_id + equip_index`; HTTP-200 `error_code=30001` follows the same local equip reconciliation path.
- `SuperHero.lua` `b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622` — same shared MID54/MID62 methods, preserving the CA4-5 activation dependency.
- `HeroMainWindow.lua` `473b72ec14a81d01d6dbdaa19f92c3d78900f40ca34fa5c8cf46585b76d65414` — one-click source planner uses slots 1→6, recursive reservation/composition, cumulative Mana and max EXP shortfall; callback applies predicted inventory/EXP mutations.
- `Backend.lua` `95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840` — `economy_` is applied through the shared response projection path.

## Findings

1. **CA4-2A durable ownership remains correct.** Six Hero-owned nonnegative equipment values persist/reload through CharacterHero storage. Normal-Hero CA4-2 logic enforces 0/1 while persistence remains future-compatible with Super enhancement values >1. No equipment-instance aggregate or historical per-color ledger was introduced.
2. **Content remains exact-source and revision-bound.** The Hero equipment mapping independently regenerates from the exact current source to 53,280 positions (50,504 ordinary, 1,646 special, 1,130 zero), and all ordinary resources remain within CA4-1/I5 qualified primitives.
3. **CA4-2B preserves I5 ownership and D01.** CharacterHero never writes I5 SQL. The combined prepared resource seam owns canonical Economy→Progression→Mana→sorted Stack locking and Apply performs only prepared writes without new reads/locks/content lookup.
4. **CA4-2C planner/service remains source-shaped.** The server planner matches all 15 sealed adversarial vectors, including duplicate ordered recipe edges, shared reservations, exact Mana boundaries, depth-6 recursion, max-not-sum EXP and potion overshoot. MID54 remains direct-item only. MID62 composes through I5 and performs one cohesive Hero CAS.
5. **Receipts remain semantic and replay-safe.** Effectful and zero-effect outcomes are receipted. Same-operation replay does not duplicate I5/Hero effects. MID54 already-equipped remains a no-debit semantic outcome suitable for wire `30001`; MID62 no-work remains a valid recorded semantic outcome.
6. **D dispatcher wire projection is bounded.** MID54 accepts only `partner_id/equip_index`, returns an empty body on ordinary success, and HTTP 200 with only `error_code=30001` on already-equipped reconciliation. It does not invent Fumo/restoration fields.
7. **MID62 wire projection is canonical.** The dispatcher accepts only `partner_id`, returns the six canonical equipment values, and layers authoritative current `economy_.mana` through the existing I5 `ScalarProjector` after the semantic service operation, including no-work/replay success. Transient Mana is not stored in the semantic receipt.
8. **Production activation remains correctly deferred.** Diagnostic dispatcher cases 54 and 62 exist, but the production Hero registry remains exactly `{49,52,55,63,67,89}`. This is required because Super shares those wires and CA4-5 owns the Super equipment branch. No CA4-5 mechanics were pulled forward.
9. **C→D delta is narrow.** Product changes are limited to production dependency composition plus HeroDispatcher interface/cases/error mapping; new tests/archguard/validator/evidence support that delta. CA4-2A/B/C mechanics were not rewritten during D.
10. **Ownership remains clean.** Independent scans find no I5 storage/content-table SQL markers inside CharacterHero equipment implementation. Response projection is not gameplay authority.
11. **Canonical pins remain pristine.** `.go-version`, `go.mod` and `go.sum` retain the exact Pass535 hashes. The exact canonical executable attempt is blocked only because the sandbox cannot download pinned Go 1.27.1.
12. **Historical guards were not weakened.** Snapshot-era CA3-3/R5/R6 standalone validators correctly reject later compiler/migration state. The cumulative current-candidate validator runs historical R6 in its explicit cumulative mode and is GREEN. No historical validator was edited to hide forward evolution.
13. **Bounded activation caveat remains explicit.** MID62's Mana response is a separate postcommit projection. If infrastructure fails after semantic commit but before projection, a generic failure response is not stock-safe. CA4-2 exposes no such production route, so this is not a current stock-client defect; CA4-5's explicit shared-route activation reconciliation must revisit the failure mode before registration.
14. **No unrelated CA4 family work leaked in.** No Fumo MID58, promotion/reset MID51/MID57, pet equipment, Super enhancement/MID304, or durable Spirit/Horcrux lifecycle was implemented.

## Test/evidence classification

- Exact canonical Go 1.27.1 attempt: **ENVIRONMENT_BLOCKED** at toolchain download/DNS; canonical files unchanged.
- Canonical static/source proof: CA4-2D validator GREEN; exact current-source CA4-1 and CA4-2A oracles GREEN; immutable content regeneration GREEN; query-text/schema/sqlc/dependency/current-candidate checks GREEN.
- Fresh disposable compatibility clone: focused tests GREEN; focused race GREEN; `go vet ./...` GREEN; archguard GREEN; planner vectors **15/15 GREEN**; CA4-2 dispatcher tests GREEN; bounded package-by-package **92/92 go test + go vet GREEN**.
- Real PostgreSQL/River/native aggregate proof: **NOT RUN / DEFERRED by sealed lifecycle to `CA4_AGGREGATE_PRE_CA4_E_NATIVE_WORK_GATE`**.
- Physical unmodified stock-client proof: **NOT RUN / W2 lifecycle obligation remains open**.

## Verdict

**GREEN for CA4-2 local phase acceptance under compatibility-copy executable constraints, provided production MID54/MID62 registration remains disabled.** No product defect, ownership contradiction, content mismatch or stage leakage was found. CA4-2 can be sealed locally and the next internal frontier may advance to **CA4-3A Hero Fumo research/reconciliation**. The accumulated native PostgreSQL/River/exact-toolchain gate remains mandatory at the previously sealed pre-CA4-E point and is not satisfied by this result.
