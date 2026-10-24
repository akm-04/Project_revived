# PASS476 — R4D PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION

## Gate

**R4D PRE_IMPLEMENTATION_RESEARCH_RECONCILIATION = GREEN_CANDIDATE_BOUND.**

This checkpoint is bound to backend `v0.54.4 Pass474` archive SHA-256 `f78c71bee86244f9efa656cb7f13e965bb9fea575677d874cf0e7c64d8e0b71d`, base lineage commit `76d4b71d205cb5a2b40945be2de06bc3fabd147b`, implementation revision `12193054e2cb312820406176a708c26947de48734eab4df3179a0ca741892ea9`, and built-in content revision `77d0b329b0e4c6199fe8484837e025923ca89bf7dc8ebcdd96efa361bbea98b1`.

Pass475 is design/memory authority only; it does not supersede Pass474 backend code. Pass474 migration `00010_r4b_content_revision_manifest_constraint_repair.sql` is preserved and `00009_r4_immutable_content_revisions.sql` remains historical/unchanged.

## Inputs and authority

- HOT/CURRENT PassMap SHA-verified through the supplied Pass475 package. COLD is provenance/restore only.
- Additional materials `INPUTS.json` matches every supplied R4D-relevant artifact by SHA-256, regardless of filename suffix.
- The only declared input not attached is `pass443-loginwindow-zcm-exception-overlay.zip` SHA-256 `f6d8884c202a9c10c30f105df1b62dcc7fdc13c8bab4802a26acb919ef6def2a`; it is marked superseded diagnostic-only and is not required for R4D.
- Current packaged src_64 authority hashes remain exactly those frozen by the R4 contract: ItemTable `1f846972f29a55ee2dbb90f2cb9b0124eaeaa90646c3c66644ab66e231c37f00`, PlayerTable `9feedb4360090c1c7d5e20853ca2cdbdd85670cc276c3b56a2bb7a4a429b569f`, Backpack `953999f81fc43ecd00e587d884c88b6a1ba066e35ff75a20dd698b6cb950af7a`, SelfPlayer `163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4`, item.lua `59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc`, player.lua `1b6b6b0557b0d2cb33b34dc37c25e4a12ae4fbd71f1476d6ac463267a1278345`.
- Frozen V1 Pass353 is differential/corroborative evidence only, never original-server truth or V2 runtime authority.

## Candidate-bound findings

1. **SOURCE_FACT / candidate code:** `operation.Context.Policies` already exists and is copied into durable receipts. `tx.Runner.Run` receives the same operation value on every definite-abort retry. This is the correct carrier; no new global retry state is required.
2. **SOURCE_FACT / candidate code:** HTTP edge currently constructs operations from a static handler policy set, and production wiring supplies no R4 content ref. Pass467 explicitly forbids using this global/static policy as the R4 active resolver.
3. **SOURCE_FACT / candidate code:** I5 `ResolveResourceTx` currently queries `i5_resource_registry ... active=true`. Objective list/claim queries join `objective_definitions ... active=true`. These are exactly the R4D defects; activation must not be consulted after binding and legacy persisted rows must not be reinterpreted through current activity.
4. **SOURCE_FACT / ownership:** content tables are owned by the content-registry adapter. I5 must consume them through a typed port; moving `gxb_content_*` SQL into `i5store` would violate the one-owner rule.
5. **SOURCE_FACT / Grant identity:** current `SourceIdentity.SemanticKey` hashes `Domain, Operation, BusinessKey, Occurrence, PolicyVersion` (legacy v1). Pass467 freezes canonical v2 as the first four fields only, lookup order v2 then v1, new writes v2 only, same historical business-plan fingerprint, contradictory dual receipts fail closed.
6. **SOURCE_FACT / nested settlement:** ClaimMail, ClaimMailBatch, objective claim, redeem and operator grant already call `SettleGrantTx` inside the caller-owned transaction with the same operation value. The R4D change must bind once in the owning command and carry that bound copy through nested Grant rather than opening a nested transaction.
7. **SOURCE_FACT / replay:** all affected owning commands perform semantic receipt lookup before their first business mutation inside the transaction. R4D can preserve replay-first semantics by binding content only after this lookup and before new mutation. A closure-held bound operation can survive Runner retry attempts without querying activation again.
8. **SOURCE_FACT / temporal restart:** migration00009 added nullable `player_temporal_resources.content_revision`; NULL explicitly means legacy exact semantics. Legacy policy resolution must use `(resource_key, persisted policy_version)` without `active=true`. Non-NULL rows use their exact immutable content revision. R5 still owns dynamic cap/rebase/bootstrap semantics and temporal definitions are `R5_REQUIRED` or fail-closed, so R4D must not activate new temporal mechanics.
9. **SOURCE_FACT / objective restart:** migration00009 added nullable `player_mission_instances.content_revision`; NULL explicitly means legacy exact `(program, objective, definition_revision)` without `active=true`. Built-in objective catalog remains empty. Non-NULL rows, if present, must resolve through the exact content revision; R4D must not invent objective creation/mapping.
10. **SOURCE_FACT / stock client:** current src_64 MID161 request carries mission table identity (and optional hero identity), MID230 carries code/platform, and mail claim MIDs carry mail identity. No current stock request carries an immutable content revision. Server-side binding/replay evidence is therefore required; content revision cannot be treated as a new client nonce.
11. **SOURCE_FACT / Work Place time:** PASS465_WORKPLACE_TIME_CONTRACT is not an R4 prerequisite. It forbids interpreting UI timers or +8/05:00 observations as a universal authoritative clock/reset rule. R4D makes no Work Place/timed-gameplay mechanics change.
12. **SOURCE_FACT / current environment:** exact Go 1.27.1, PostgreSQL 18.6, sqlc 1.31.1, Goose, staticcheck, Docker/Podman are unavailable here. Installed Go is 1.23.2 and PostgreSQL client metadata is 17.10 with no server binaries. Exact native PG/River/live proof therefore remains unavailable in normal chat.

## Frozen implementation decisions for R4D

- **IMPLEMENTATION_DECISION:** add a typed I5 content runtime port implemented by the content-registry-owned PostgreSQL adapter. It reads the active revision only at the owning-command binding point and performs all later resource/objective reads by explicit revision.
- **IMPLEMENTATION_DECISION:** bind `policy.Ref{Name:"content",Version:<revision>}` after semantic-receipt replay and before the first new business mutation. Once bound, never re-read activation for that operation; retry attempts and nested Grant reuse the same bound `operation.Context`.
- **IMPLEMENTATION_DECISION:** scalar Mana/Crystal and qualified ordinary stack definitions are the only R4 content-backed Grant destinations enabled. Player EXP remains R5-gated; temporal new-content settlement remains R5-gated; specialized/owner-required rows fail closed.
- **IMPLEMENTATION_DECISION:** preserve legacy temporal functionality only through exact persisted legacy policy lookup; do not rewrite or relabel rows to the active content revision.
- **IMPLEMENTATION_DECISION:** objective reads split by persisted `content_revision`: NULL uses the legacy objective table exact key with no active filter; non-NULL uses the typed content runtime port with that exact revision. No built-in objective creation is enabled.
- **IMPLEMENTATION_DECISION:** Grant canonical v2 identity excludes `PolicyVersion`; legacy v1 remains reconstructable. Dual lookup occurs before mutation; only canonical v2 is written for new settlement. Unknown-COMMIT reconciliation checks both identities and never resolves current content merely to classify an old commit.
- **IMPLEMENTATION_DECISION:** overflow-mail source identity receives an explicit v2 derivation while legacy v1 derivation remains reconstructable for compatibility; old receipt replay short-circuits before new overflow creation.
- **IMPLEMENTATION_DECISION:** Pass475 AUDIT-MID-01 does not gate this implementation because R4D does not edit MID catalog/mapping metadata. If such metadata changes become necessary, the audit gate must be reopened before activation.

## Gate decision

No consequential contradiction remains. **Next permitted action: R4D IMPLEMENTATION on the exact Pass474 candidate.**

Post-implementation gates remain mandatory: focused/static/race/query/source-oracle tests on a disposable exact copy (or minimal compatibility copy labeled `COMPATIBILITY_COPY_ONLY`), separate same-agent reality review, evidence classification, HOT+COLD synchronization/seal, then the targeted native PostgreSQL end-R4 gate including migration00010 before R5. Native PostgreSQL unavailability must remain an explicit blocker rather than being substituted by WASM or compatibility-copy evidence.
