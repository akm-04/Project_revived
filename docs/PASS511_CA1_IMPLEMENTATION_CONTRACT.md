# Pass511 — CA1 Implementation Contract (UNSEALED CANDIDATE)

Date: 2026-09-11
Parent semantic authority: sealed Pass509 HOT/CURRENT
Parent backend: `gxb-backend-v2-v0.60.0-pass509-i6-parent-accepted-profile1-roadmap-ready.zip`
Parent backend SHA-256: `be1bbf9f4119c859bfc0dc679142a2c5ceb367ba3ccf1387bc6f984309570dbb`
Parent accepted implementation revision: `46b9ea5d54c80f022449833d594d84c5f48b18304cd2a33c9e53b560ce070b26`

## Status

`CA1_IMPLEMENTED_LOCAL_GREEN_NATIVE_AND_REAL_POSTGRESQL_PENDING`

This document records the implemented CA1 contract after the user-approved Pass510/Pass511 pre-implementation reconciliation. It is not a HOT/COLD seal and does not supersede Pass509 semantic authority. CA1 acceptance remains blocked on exact pinned-toolchain/native and real PostgreSQL gates.

## Evidence classifications

- **SOURCE_FACT** — Pass463 D01 requires complete pre-mutation typed effect/lock planning, one caller-owned transaction, no nested owner transactions, global lock order, and no foreign-owner SQL.
- **SOURCE_FACT** — Pass475 D03 requires typed caller-transaction-aware asset materializers keyed by semantic Grant plus stable line identity; replay returns original created persistent IDs; owner-specific allocation/duplicate policy remains deferred.
- **SOURCE_FACT** — exact current `src_64` and old v1.164 `ItemTable.lua` keep `partner_id`, `pet_id`, and `style_pet` as distinct mappings; Pet appearance state/MIDs are separately represented.
- **SOURCE_FACT** — accepted I5 Grant supports caller-owned `SettleGrantTx`, uses lock ranks 610/700/710/720/721/722/730/740, and Pass509 intentionally fails `PartnerEntity`/`SpecializedDomain` closed.
- **STRONG_INFERENCE** — Pass509 Redeem's old `progression(710) -> Grant economy(700)` sequence exposed a latent lock-order inversion. CA1-R0 repairs the ordering without changing eligibility semantics.
- **IMPLEMENTATION_DECISION** — reserve Character Asset lock ranks 400–599; leaf ranks remain deferred to CA2+ owner-specific research.
- **IMPLEMENTATION_DECISION** — only `grant.PartnerEntity` gets the CA1 typed external materializer seam. `SpecializedDomain` stays unsupported. CA1 does not infer Hero/Pet family from ItemID.
- **IMPLEMENTATION_DECISION** — shared scalar+stack material debit composition belongs in CA1 as an I5-owned caller-transaction port; Temporal/PlayerExp/entity debits are excluded.

## Implemented boundaries

### 1. Typed PartnerEntity materialization

`internal/application/i5/partner_materializer.go` adds:

- Character lock band constants 400–599;
- stable `GrantSemanticKey + LineOrdinal` line identity;
- batch preflight so aggregate capacity/owner constraints can be checked by a future provider;
- provider-declared Character lock keys merged into I5's canonical Grant lock plan;
- locked validation and caller-owned transaction apply stages;
- typed result envelope preserved in Grant receipts without a generic `entity_id`.

CA1 registers no production provider. `PartnerEntity` therefore remains fail-closed in the shipping runtime until a later qualified owner phase deliberately wires a provider.

### 2. Grant planning and replay

`PartnerEntity` branches before fungible I5 `ContentRuntime.ResolveResourceTx`. This is required because the accepted fungible resource catalog has no authoritative `PARTNER_ENTITY` resource class.

A successful materializing Grant writes `gxb.i5.grant.v3`; fungible-only Grants retain `gxb.i5.grant.v2`. Decoder compatibility remains v1/v2/v3. Typed replay reads the durable receipt before provider preflight/apply.

A defensive post-lock receipt lookup is also retained before mutation. Exact PostgreSQL visibility/retry behavior remains part of the native real-DB gate and is not inferred from fake/local transactions.

### 3. CA1-R0 Redeem ordering repair

Redeem now prepares the inner Grant plan and forces Progression into the complete Grant suffix before reading level eligibility. The intended order is:

`source Redeem rows/fence -> Character 400–599 if present -> Mail 610 if needed -> Economy 700 -> Progression 710 -> remaining I5 locks`.

Eligibility still uses the same canonical progression row and same accepted `redeem.Eligible` logic. The repair changes synchronization order, not recovered gameplay mechanics.

### 4. Shared material debit port

`internal/application/i5/material_cost.go` adds `TxMaterialCostDebiter` / `MaterialCostDebiter` with:

- caller-owned transaction only;
- exact bound content revision;
- immutable policy resolution before gameplay mutation;
- scalar+stack costs only;
- canonical lock order Economy 700 -> Scalar 720 -> Stack 722;
- complete balance calculation before first intentional write;
- zero stack deletion using accepted I5 semantics;
- imported over-cap stack spend-down using accepted `StackState.Adjust` behavior;
- no receipt ownership, no transaction lifecycle, no SQL, no foreign Store exposure.

### 5. Explicit non-scope

CA1 does **not** add:

- Hero/Pet canonical tables or migrations;
- Hero/Pet allocation, capacity, duplicate-conversion, starter or progression mechanics;
- equipment/Fumo, formation, Practice/Wash, appearance entitlement or selected-style mechanics;
- stock award projection for entity grants;
- bootstrap or MID1 Character contributor registration;
- production Character provider wiring;
- Gacha outcome selection;
- `SpecializedDomain` support;
- River jobs or queue-owned gameplay state.

## Required acceptance gates

Local compatibility-copy results are diagnostic only. CA1 cannot be accepted or sealed until the exact candidate passes:

1. unmodified Go 1.27.1/native tests and race/vet/static checks;
2. generated-query/sqlc policy with sqlc 1.31.1;
3. PostgreSQL 18.6 real-database tests for caller-owned transaction rollback, concurrency and lock order;
4. exact Redeem-vs-Grant contention reproducer showing no 710->700 deadlock pattern after CA1-R0;
5. concurrent same-semantic entity Grant fixture showing one durable materialization/result under retry/replay;
6. late provider failure proving provider fixture + I5 writes + receipt roll back atomically;
7. mixed entity/scalar/stack settlement and replay;
8. existing `-tags postgres` and `-tags "postgres river"` repository regression, with River classified as regression coverage rather than a new CA1 behavior gate;
9. post-native independent reality check against D01/D03/src_64 and exact produced code;
10. evidence classification followed by HOT/COLD sync/seal only after all mandatory gates are green.

## Next permitted action

`CA1 / NATIVE_EXACT_TOOLCHAIN_AND_REAL_POSTGRESQL_TEST_GATE`.

Do not start CA2 implementation until CA1 is accepted and sealed.
