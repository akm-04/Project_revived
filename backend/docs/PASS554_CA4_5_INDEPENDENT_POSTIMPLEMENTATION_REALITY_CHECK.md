# Pass554 CA4-5 Independent Postimplementation Reality Check

Status: **GREEN — CA4-5 LOCAL ACCEPTANCE / COMPATIBILITY_COPY_ONLY EXECUTABLE PROOF; ACCUMULATED CA4 NATIVE GATE REMAINS OPEN**

Authority parent: sealed Pass553 CA4-5 research closure, implementation contract, A01–A38 acceptance matrix, and explicit user authorization for I1–I4. Product parent is accepted Pass552 v0.72.0 SHA-256 `755393ce3f0b31f3a5141d74ffd3fa70ae55402359a517ee93b711eb2a28d0c6`.

No separate human reviewer participated. “Independent” here means the postimplementation check reread the frozen current source evidence and Pass553 acceptance contract, inspected the complete Pass552→CA4-5 product diff, recovery/concurrency paths, content ownership and final execution evidence rather than treating prior implementation notes as proof.

## A01–A38 reality matrix

| ID | Result | Independent finding |
|---|---|---|
| A01 | **GREEN** | Stock dispatcher tests enforce exact MID54/MID62/MID304 shapes and reject missing, invalid, or extra gameplay fields. |
| A02 | **GREEN** | Generated SUPER_EQUIPMENT_CA4_5 catalog is deterministic at revision 6ba22017… with 14 templates, 84 positions, and 12 unique base items. |
| A03 | **GREEN** | Super MID54 resolves the fixed slot to the existing CA4-1 primitive, enforces required level 89, and debits exactly one finished base item. |
| A04 | **GREEN** | Super MID54 uses direct stack debit only; aggregate validator proves no recipe-edge traversal, recursive composition, or Mana scalar debit in EquipItem. |
| A05 | **GREEN** | Existing Normal MID54 behavior/replay/stock-wire tests remain GREEN in focused and full regression. |
| A06 | **GREEN** | Receipt decoder keeps Normal v1 ValidateNormal() semantics while Super v2 accepts nonnegative enhancement values with family=SUPER. |
| A07 | **GREEN** | Family mismatch, invalid partner/equipment values, and malformed Super receipt payloads fail closed. |
| A08 | **GREEN** | Super MID54 performs only selected raw-slot 0→1; explicit test proves unrelated enhanced slots plus star/level/exp/color/Fumo/origin remain unchanged. |
| A09 | **GREEN** | Already-equipped Super MID54 is zero-effect, performs no debit/CAS, and stock dispatcher preserves error_code 30001 compatibility. |
| A10 | **GREEN** | Same-operation Super MID54 replay returns the committed receipt without a second debit or Hero save. |
| A11 | **GREEN** | Super MID54 ambiguous COMMIT reconciles through matching outer receipt; absent receipt returns UNKNOWN with no blind replay. |
| A12 | **GREEN** | Normal MID62 production registration reuses accepted CA4-2 path; existing projection/Mana/no-work tests remain GREEN. |
| A13 | **GREEN** | Super family reaches validateNormalHeroForEquipment and fails closed; no current-source-hidden Super MID62 activation was added. |
| A14 | **GREEN** | MID304 rejects non-Super templates before resource mutation. |
| A15 | **GREEN** | MID304 wire/service reject slots outside 1..6, raw0/uncollected, enhance_times<=0, and effective-client-inactive star9+ before debit. |
| A16 | **GREEN** | Tests prove exact effective caps: stars1–5=10, star6=20, star7=30, star8=40. |
| A17 | **GREEN** | Cap crossing is rejected before debit/save; explicit tests assert zero mutation. |
| A18 | **GREEN** | Single-level tests at reachable tier boundaries prove one duplicate mapped base item per enhancement level. |
| A19 | **GREEN** | Cross-tier multi-level test 9→31 proves debit count equals enhance_times across 10/20/30 boundaries. |
| A20 | **GREEN** | MID304 uses stack-only MaterialCost; source/product guards prove no Mana/scalar debit and no recipe-component consumption. |
| A21 | **GREEN** | MID304 increments only the selected raw slot by enhance_times; unrelated raw slots survive unchanged. |
| A22 | **GREEN** | MID304 dispatcher returns exact empty success body; no economy/state fields are invented. |
| A23 | **GREEN** | Same-operation MID304 receipt replay is exact-once with no second debit/CAS. |
| A24 | **GREEN** | Late outer-receipt failure test rolls Hero state and stack debit back together. |
| A25 | **GREEN** | Ambiguous COMMIT returns committed result only through matching outer receipt; receipt absence yields UnknownCommit/no blind retry. |
| A26 | **GREEN** | Race-clean concurrent MID54+MID304 and concurrent MID304 tests serialize same-Hero updates without lost slots. |
| A27 | **GREEN** | Stock projection already preserves arbitrary nonnegative raw equipment values; new MID49 reconnect test proves enhanced Super values 1/2/11/21/31/40 survive roster projection. |
| A28 | **GREEN** | Only immutable gxb_content_super_equipment_* tables were added; ownership/query guards are GREEN and no new player Super state table/foreign-owner SQL exists. |
| A29 | **GREEN** | Whole-diff/source guard finds no Spirit/Horcrux read/write/allocation/lock/enhance path in CA4-5 production code. |
| A30 | **GREEN** | Generated caps retain physical stars9/10 as effective_client_reachable=false; MaxHeroStar remains 8 and star9 service test rejects before debit. |
| A31 | **GREEN** | Deterministic current-source guard pins source archive/member hashes, MID54/62/304 identities, raw encoding, enhancement tier behavior, and catalog revision. |
| A32 | **GREEN** | Old client remains non-discriminating for MID304 and V1 Horcrux evidence is checked only as bounded corroborative architecture evidence. |
| A33 | **GREEN** | Operation entropy foundation is unchanged; static guards prove no .Derive() or random draw in MID54/MID304 CA4-5 paths. |
| A34 | **GREEN** | Focused behavior/recovery/projection tests, critical race, vet/static, ownership/query, generator, and source-oracle checks are GREEN where executable. |
| A35 | **GREEN** | Fresh compatibility copy passed go test ./internal/..., go vet ./internal/... ./cmd/..., and go test ./cmd/... . |
| A36 | **GREEN** | Unmodified canonical candidate was attempted first and is ENVIRONMENT_BLOCKED solely by unavailable Go1.27.1 toolchain download; adapted execution is COMPATIBILITY_COPY_ONLY. |
| A37 | **GREEN_DEFERRED_GATE_PRESERVED** | Exact Go1.27.1 + real PostgreSQL/River accumulated CA4 gate remains OPEN and mandatory before CA4-E. |
| A38 | **GREEN_DEFERRED_GATE_PRESERVED** | W2 physical stock-client proof and I8_TECH Spirit/Horcrux remain explicitly OPEN/deferred and are not marked passed. |

## Whole-diff reality findings

1. The CA4-5 product delta adds immutable Super equipment content plus shared CharacterHero orchestration only. CharacterHero remains the sole player-state owner; no parallel durable Super aggregate or foreign-owner SQL was introduced.
2. MID54 now resolves family after locking CharacterHero. Normal stays on the existing color-qualified CA4-2 path; Super uses fixed topology and one finished-item debit. Receipt validation is family-qualified rather than globally weakened.
3. MID62 is production-registered for the already-qualified Normal behavior and deliberately fails closed for Super because recovered current UI hides that path.
4. MID304 is deterministic Super-only enhancement: fixed mapped base item, effective star≤8 cap policy, duplicate stack debit only, cohesive Hero CAS, empty success projection and outer semantic receipt/recovery. No Mana, recipe composition, RNG, Spirit or Horcrux lifecycle is present.
5. Current `src_64` is the discriminating source. The old v1.164 client lacks MID304 discrimination; Frozen V1 Horcrux remains bounded corroborative/compatibility evidence and does not become original-server truth.
6. Reconnect/roster projection preserves the six raw Super equipment integers including values >1; no new wire authority is introduced.

## Final execution/evidence boundary

1. Exact candidate execution was attempted first and is **ENVIRONMENT_BLOCKED** because this sandbox cannot resolve/download pinned Go 1.27.1. Canonical toolchain/dependency pins are unchanged.
2. A fresh compatibility copy is GREEN for focused behavior/recovery/projection, critical race, full `./internal/...` regression, full vet and `./cmd/...`.
3. Exact builtin-content regeneration reproduces content revision `6ba22017fab270d38fbb68ab30bea0afe61442a979f74084fd7f5027a184e116`; character/content query generation and schema/query ownership are GREEN.
4. The deterministic CA4-5 source guard is GREEN against exact current, old-client and Frozen V1 archive identities. It explicitly checks no Mana/RNG/Horcrux leakage in the product path.
5. Cumulative migration lock was advanced through `00027_ca4_5_super_equipment_content.sql`; cumulative and connected-candidate validators are GREEN.
6. Exact Go1.27.1 + real PostgreSQL/River accumulated CA4 proof remains **OPEN**. W2 stock proof and I8_TECH Spirit/Horcrux also remain open.

## Verdict

**GREEN for CA4-5 local acceptance under COMPATIBILITY_COPY_ONLY executable constraints.** I1–I4 are complete locally, no acceptance-matrix defect remains, and CA4-5 can close locally. Parent CA4 remains open pending the mandatory Work Mode end-to-end exact Go/PostgreSQL/River aggregate gate before CA4-E.
