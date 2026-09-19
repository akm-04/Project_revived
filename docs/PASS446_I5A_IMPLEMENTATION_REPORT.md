# Pass446 / I5-A Implementation Report

## Verdict
GREEN normal-chat implementation checkpoint. I5 is **not complete**; this pass establishes canonical ownership, typed domain mechanics, owner-scoped schema/query contracts, and atomic Player-Core bootstrap seeding. Transaction-heavy Grant/Mail/Objective/Redeem settlement remains the next I5 checkpoint.

## Implemented
- Canonical Player Core: profile, progression, story cursor, function unlock and guide-return typed state.
- TypedEconomy primitives: scalar, temporal and stack resources with explicit overflow behavior; no universal wallet.
- Grant orchestration identity derived from source business identity, never raw MID/client nonce.
- Durable Mail compound wire identity `(NORMAL|REGION, wire_id)`, boolean `is_region`, canonical MID370 batching.
- Objective committed-fact reducer with completion separate from claim.
- MID230 Redeem normalization/HMAC lookup/eligibility primitives with no Commerce authority.
- Forward-only migration `00005_i5_player_economy_mail_objective_redeem.sql` creating owner-scoped relational truth.
- New-character MID1 transaction now atomically seeds canonical Player Core rows alongside the player root and I4 directory projection.
- Owner-scoped `sql/i5` query catalog and external sqlc output contract.

## Source/oracle cross-check
Current packaged src_64 remained active authority. Rechecked SelfPlayer, StoryData, Backend/Task, Backpack/ItemTable, Mailbox/MailboxWindow, mid.lua and ExchangeCodeWindow. Key retained facts include boolean false/nil normal-mail semantics, compound MID369 identity, separate MID370 normal/region sets, sibling reward/task projection, `stack_exceed_mail`, and MID230 `{code, platform} -> awards[]`. Old-client ExchangeCodeWindow is byte-identical for this surface. Pass353 was corroborative/mechanism-only and no V1 private nonce/authority coupling was copied.

## Bounded unknowns preserved
No fabricated fresh-player nonzero currency/stamina/item rows; no guessed starter hero/gacha state; no invented hidden normal-vs-region mail meaning; no invented overflow-mail expiry; no invented redeem cardinality policy.

## Normal-chat evidence
- `go test ./...`: PASS under temporary Go 1.23.2 sandbox compatibility patch.
- `go vet ./...`: PASS under the same compatibility patch.
- new-domain race tests: PASS.
- architecture guard: PASS.
- `tools/validate_i5.py`: PASS.
- `tools/check_i5_oracle_player_core.py`: PASS.
- schema/query ownership and sqlc generation policy: PASS.
- exact PostgreSQL-tag compilation: NOT EXECUTED here because pgx v5 module bytes are not cached and outbound module download is blocked. This is not counted as PostgreSQL/River proof.

Authoritative `go 1.26.0` + `toolchain go1.27.1` pins are restored in the sealed source. Exact Go/sqlc and real PostgreSQL/River execution remains a Work/W2-class gate.

## Next
Continue I5 with transaction repositories/services, actor liveness inside write transactions, Grant settlement/overflow Mail, MID369/MID370 claim semantics, Objective fact receipts/claims, MID230 durable redemption and stock wire routing. Client acceptance remains deferred to W2.
