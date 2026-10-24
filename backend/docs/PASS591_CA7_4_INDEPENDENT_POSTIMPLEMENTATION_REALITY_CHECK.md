# Pass591 — CA7-4 Independent Postimplementation Reality Check

## Authority and candidate binding

This review is bound to sealed Pass590 authority and its accepted CA7-3 parent backend `gxb-backend-v2-v0.82.0-pass590-ca7-3-local-accepted.zip` (SHA-256 `bdbb3c2ec795036e3ec4f97d33d57257133249f73c4f0aa2828de0540adbc9af`, Git parent `1b40629950996ade1ff0da841c5a53910080a22f`). CA7-4 research was frozen before coding in `PASS590_CA7_4_PREIMPLEMENTATION_CONTRACT_R1.md`, its candidate-bound acceptance matrix/source oracle and the independent preimplementation reality check. The user then explicitly authorized implementation. This postimplementation review rereads the produced code and source-bound contract rather than accepting the stage from test results alone.

## Ownership, persistence and transaction composition reality

Hero remains the sole durable owner of paid LIVE entitlement/show-state. No schema migration, new aggregate, foreign-owner SQL, or positional-array persistence was introduced. CA7-4 reuses the accepted keyed `player_hero_live_entitlements` storage and `SaveHeroLIVEEntitlementTx`: one child upsert and one Hero `state_version` CAS in the caller-owned Character transaction. Actual LIVE mutations therefore produce exactly one Hero owner transition; semantic no-ops produce none.

MID68 and MID69 run in the ordinary Serializable Character transaction profile with bounded definite-abort retry. They bind one immutable `CHARACTER_APPEARANCE_CA7` revision, fence the actor, check same-operation D11 receipts, validate the bound revision, lock Hero, recheck the receipt under the owner lock, resolve the Hero against content, and only then evaluate paid-LIVE state. CA7-4 has no expiry/reset mechanic and therefore does not invent a `DecisionAt`/TimedRunner contract.

For MID68 the Hero lock is acquired before any I5 debit. I5 remains sole Economy/stack owner through the typed `MaterialCosts` seam; Character never writes Economy tables. Only an absent qualified paid-LIVE entitlement reaches the debit path. Existing ownership is current-state convergence: no Crystal/item debit, no child write and no Hero version bump.

## MID68 acquisition/convergence reality

MID68 accepts a qualified Normal-Hero paid type-2 LIVE model from the pinned appearance revision and requires its `HeroOriginTableID` to match the resolved Hero origin. It does not require the model to be the currently selected ordinary skin and therefore does not couple durable paid-LIVE lifetime to ordinary/timed skin entitlement.

First acquisition debits the content-defined Crystal cost plus activation item/count through I5, creates the keyed LIVE entitlement with the frozen initial `is_show=true` compatibility policy, advances Hero `state_version` exactly once, rebuilds effective appearance through the accepted CA7-2 projection seam, and stores the semantic D11 receipt in the same transaction. A fresh identical request after ownership exists preserves the existing show bit and converges without a second debit or version change. Same-operation replay/UNKNOWN-COMMIT uses the semantic receipt and does not rerun the mutation.

The semantic receipt intentionally stores LIVE state rather than current Economy balances. After semantic success the stock dispatcher independently projects the current `crystal` through the accepted Economy scalar projection port and emits it in generic `economy_`. This means a lost committed response followed by a fresh stock retry can converge without a second debit while still repairing the client's Crystal cache. The stock response contains only the canonical aligned `unlocked_dynamic_card`, `dynamic_card_state`, and `economy_.crystal`; no unsupported item balance, `remove_item`, cost, `server_time`, or bespoke top-level Crystal field was invented.

One researched residual remains bounded rather than hidden: a stale second client that still renders an already-owned LIVE as locked can send a fresh MID68 and locally subtract its activation item after a correct no-debit convergence response. No recovered stock discriminator safely fixes that case without breaking the lost-response path. Server durable ownership/no-double-debit remains authoritative.

## MID69 desired-state assignment reality

MID69 is an explicit desired-state assignment, never a server-side toggle. The external stock wire requires an actual JSON numeric integer exactly `0` or `1`; booleans, strings, fractions and other integers fail closed. Standard stock envelope metadata remains tolerated by the shared envelope layer while invented gameplay fields are rejected.

The target must be an already-owned effective qualified paid LIVE for a Normal Hero. A changed desired state writes one LIVE row and advances Hero version once. An already-equal desired state stores a terminal same-operation receipt but performs no persistence write and no Hero-version transition. MID69 has no I5/MaterialCosts dependency. Its stock success body is the source-supported empty object; the client applies its requested desired bit locally.

## Projection, malformed state and lifetime independence reality

CA7-4 reuses `BuildEffectiveHeroAppearanceTx` rather than duplicating LIVE qualification. Durable LIVE authority is keyed `(player, partner, model)`; duplicate keyed rows are structurally excluded by the accepted schema. Projection filters unqualified/wrong-origin rows, sorts qualified models deterministically, and the dispatcher serializes the same ordered rows into positionally aligned `unlocked_dynamic_card` and `dynamic_card_state` strings. Those strings are never ingested as canonical mutation state, so malformed legacy/client arrays cannot corrupt server authority and CA7-4 does not invent an array-repair mutation.

Paid LIVE lifetime remains independent of ordinary skin expiry. A focused retained projection test demonstrates that a paid LIVE entitlement stays effective when a timed ordinary skin crosses expiry and the ordinary selector normalizes to base. This preserves the frozen CA7-1 lifetime contract.

## Receipts, replay and concurrency reality

D11 families are registered as `ca7.hero-live-unlock` (`CURRENT_STATE_CONVERGENCE`, consumptive) and `ca7.hero-live-show` (`PARAMETER_STATE_SET`). Receipt identity uses the server operation ID; request fingerprints bind semantic parameters. Same-operation parameter changes conflict rather than silently replaying another result.

Concurrency tests exercise same-model MID68 acquisition (exactly one debit/write/version transition), different-model acquisitions (each model may independently debit/write while serializing on Hero), MID68 versus MID69 ordering, concurrent identical MID69 assignments (at most one mutation), and opposite MID69 assignments (serial desired-state transitions). UNKNOWN-COMMIT reconciliation proves one committed debit/write for MID68. All actual CA7-4 Hero mutations advance `state_version`, preserving CA6 Practice stale-proposal invalidation; fresh semantic no-ops leave the version unchanged.

## Production scope and retained fences

Production registration adds only Hero MIDs 68 and 69 for CA7-4. CA7-3 MIDs 60/61/2979 remain retained and their source/architecture guards were evolved narrowly to permit the newly accepted stage rather than weakened. Dedicated CA7-4 source and structural guards pin the current-client translation and keep CA7-5 Pet-style MIDs 1893/1894/1895 absent. No CA7-5 implementation was introduced.

## Test and environment reality

The unmodified canonical candidate is always attempted first. Canonical pins remain `.go-version` Go1.27.1 and `go.mod` Go1.26/toolchain Go1.27.1. This sandbox cannot obtain Go1.27.1 from `proxy.golang.org`, so exact executable Go proof is `ENVIRONMENT_BLOCKED`, not failed, and canonical dependency/toolchain files were never adapted.

A fresh disposable compatibility copy changed only `.go-version` and the Go language/toolchain declarations to locally installed Go1.23.2. An initial disposable clone exposed a test-fixture type mistake; that defect was fixed separately in canonical, the clone was discarded, and all proof continued from fresh adapted copies. The final compatibility copy passes focused CA7-4/CA7-3/postgres/dispatcher/replay/archguard tests, focused race, focused vet, full `go test ./...`, full `go vet ./...`, and bounded package-by-package regression 94/94 GREEN. Retained historical validators and the current cumulative candidate validator are GREEN under explicit compatibility-scratch classification. Long combined validator invocations that hit the execution timeout were not counted as results; the unfinished validators were rerun individually to completion.

Canonical static checks are GREEN for dependency policy, content/sqlc generation policy, schema/query ownership, foundation trace, query-text generators, exact oracle identities, retained CA7-3 guards, new CA7-4 source oracle and CA7-4 structural validation. Real PostgreSQL/River and exact canonical-toolchain accumulated proof remain the documented CA7-7 mandatory gate; physical unmodified-stock-client proof remains W2-deferred.

## Verdict

`GREEN_LOCAL_CA7_4_ACCEPTED_COMPATIBILITY_COPY_ONLY_NATIVE_AGGREGATE_DEFERRED_TO_CA7_7`.

No demonstrated product defect, ownership conflict, source contradiction or parent-contract violation requires reopening CA7-1 through CA7-3. CA7-4 may close locally once release identity and connected-candidate integrity are regenerated for these exact bytes. This verdict does not mark CA7-7 exact/native aggregate proof or W2 physical stock-client proof as passed.
