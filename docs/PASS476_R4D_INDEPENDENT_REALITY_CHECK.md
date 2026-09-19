# Pass476 independent R4D reality check

Method: this was performed after implementation/testing as a separate review by the same agent. It re-read PASS453/PASS467 and the R4 lifecycle/roadmap, inspected the produced code rather than inferring correctness from tests, rechecked exact current `src_64` evidence, and used frozen Pass353 V1 only as a differential/corroborative oracle. It is not a claim of a second reviewer or live PostgreSQL execution.

## Admission, replay and retry

**SOURCE_FACT:** PASS467 requires semantic-receipt replay before binding today's active content for genuinely new work, one immutable content revision set per operation, retention across retries/nested settlement, and Grant v2/v1 compatibility without making content revision part of the business entitlement identity.

**RUNTIME_OBSERVED:** `prepareGrantOperationTx` resolves v2 then legacy-v1 semantic receipts before `ActiveRevision`. For new work, `bindActiveContentTx` adds the `content` policy ref. `runGrant` retains that bound operation in the transaction-body closure. The transaction runner repeats the body only after definite abort; ambiguous COMMIT uses the operation resolver and receipt evidence rather than blind replay. Content is therefore not rebound to a later activation between safe retries.

**RUNTIME_OBSERVED:** Mail, Objective and Redeem nested Grant settlement carries the same bound operation. Receipt construction persists `OperationPolicyRefs` from that context.

Verdict: **PASS_NO_CONTRADICTION**.

## Consumption and ownership

**RUNTIME_OBSERVED:** operational I5 paths contain no `active=true` content/legacy-policy read. Content-owner SQL for `gxb_content_*` stays in `sql/content`/generated content queries/contentstore; I5 consumes the typed `ContentRuntime` port. No foreign-owner content SQL was introduced.

**RUNTIME_OBSERVED:** enabled scalar/qualified normal-stack Grant lines read exact revision-qualified definitions. Player EXP and immutable-content temporal resources fail closed at the R4D boundary and remain R5 work.

**RUNTIME_OBSERVED:** no outbound provider/network call was added inside gameplay transaction locks. The R4D content port is same-database/queryer infrastructure.

Verdict: **PASS_NO_CONTRADICTION**.

## Restart/reload and legacy compatibility

**SOURCE_FACT:** PASS467 freezes legacy temporal interpretation to the persisted `(resource_key, policy_version)` and legacy objective interpretation to the persisted `(program, objective, definition_revision)`, both without `active=true`; nonlegacy rows use exact persisted content revision.

**RUNTIME_OBSERVED:** temporal load/preflight and MID1 projection use exact persisted legacy policy version for `content_revision IS NULL`. Nonlegacy temporal reload is explicitly rejected because R5 has not implemented the temporal content mechanics.

**RUNTIME_OBSERVED:** legacy objective rows join the exact historical definition tuple and do not consult an active definition. Immutable-content objective rows resolve through the exact persisted content revision.

A legacy objective whose reward claim is genuinely new still binds the new settlement's active content once after resolving the historical objective definition. This matches PASS467: persisted objective interpretation and new-settlement execution policy are distinct facts; the stored objective is not rewritten through current activation.

Verdict: **PASS_NO_CONTRADICTION**.

## Source and stock-wire recheck

The current source archive identity remains SHA-256 `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`. Rechecked `src_64` source hashes include:

- ItemTable.lua `1f846972f29a55ee2dbb90f2cb9b0124eaeaa90646c3c66644ab66e231c37f00`
- PlayerTable.lua `9feedb4360090c1c7d5e20853ca2cdbdd85670cc276c3b56a2bb7a4a429b569f`
- Backpack.lua `953999f81fc43ecd00e587d884c88b6a1ba066e35ff75a20dd698b6cb950af7a`
- SelfPlayer.lua `163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4`
- data/tables/item.lua `59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc`
- data/tables/player.lua `1b6b6b0557b0d2cb33b34dc37c25e4a12ae4fbd71f1476d6ac463267a1278345`

**SOURCE_FACT:** MID161 mission reward requests carry `table_id`, with partner-task claims additionally carrying `hero_table_id`; MID230 carries `code` and `platform`; stock mail requests identify mail/region selections. No examined request carries a content-revision nonce. Therefore Zero Client Modification requires server-side revision binding/replay rather than a fabricated client field.

Verdict: **PASS_SUPPORTS_SERVER_SIDE_BINDING**.

## Frozen V1 differential/oracle recheck

**SOURCE_FACT:** frozen V1 mission/mail implementations replay committed semantic receipt state before repeat mutation and reject fingerprint conflicts. Its receipt primitive uses semantic identity plus SHA-256 request fingerprint and record-or-replay semantics.

**SOURCE_FACT:** no equivalent immutable-content revision or `operation_policy_refs` mechanism was found in frozen V1. Therefore V1 corroborates receipt/replay atomicity patterns only and is not evidence of original-server immutable revision semantics or the V2 implementation architecture.

Verdict: **CORROBORATIVE_ONLY_NO_CONTRADICTION**.

## Migration/restore/extension seam

**RUNTIME_OBSERVED:** migration00009 already supplies immutable content tables, receipt `operation_policy_refs`, nullable temporal `content_revision`, and nullable objective-instance `content_revision`. R4D adds no migration. migration00010 remains byte-identical and strictly repairs JSON-null manifest identity validation. Existing corrupt manifests must block upgrade for operator reconciliation; R4D does not rewrite them.

**STRONG_INFERENCE:** the legacy I5 resource registry is sufficient only for rows whose persisted legacy policy version remains represented; mismatch fails closed. Future immutable content is owned by `gxb_content_*`, so R4D does not need to turn the legacy registry into a historical multi-version content owner.

**IMPLEMENTATION_DECISION:** the typed content-owner port is the extension seam for R5. Temporal/progression policies can be implemented by the owner without rewriting Grant identity/replay or introducing foreign-owner SQL.

Verdict: **PASS_WITH_EXPLICIT_LIVE_LIMITATIONS**.

## Limitations and final verdict

Exact canonical Go 1.27.1 execution, sqlc 1.31.1 execution, native PostgreSQL 18.6/pgx/Goose, real lock/concurrency/crash behavior, DDL lock duration, migration00010 upgrade behavior and native backup/restore are not proven here. Compatibility-copy results do not promote any of those evidence levels.

Final R4D reality verdict: **GREEN_BOUNDED_LOCAL_NO_CONTRADICTION; END_R4_NATIVE_POSTGRESQL_GATE_REQUIRED_BEFORE_R5**.
