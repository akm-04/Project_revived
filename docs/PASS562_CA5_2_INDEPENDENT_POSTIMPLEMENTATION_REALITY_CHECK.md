# Pass562 — CA5-2 Independent Postimplementation Reality Check

## Candidate and authority

The inspected product tree is the CA5-2 implementation descended from exact Pass560 v0.73.0. Sealed Pass561 is the implementation contract/acceptance authority. This review is independent of the test summary: it rereads the produced migration, normalized owner, store/projection/import seams, CA5-1 reference contracts, D01/D04/D13 expectations and successor boundaries.

## Ownership and schema reality

Migration 00028 creates one player-scoped saved-preset root plus ordered lane and Hero-reference rows. The root owns one aggregate revision and is backfilled for existing V2 players. The schema intentionally has no foreign key to Hero/Pet owner tables; typed owner ports remain the cross-owner validation boundary. Known future reverse-reference indexes are present without turning them into gameplay authority. No recovered client-only capacity/name policy has been promoted into schema truth.

## Root lifecycle

The required SavedPresetBootstrapContributor is wired into the existing caller-owned character bootstrap transaction. The migration backfill covers already-existing V2 players. The legacy import adapter calls EnsureSavedPresetRootTx after the target player exists, covering fresh Pass425-style imports whose schema is applied before players are imported. Exact transaction rollback semantics require real PostgreSQL and remain deferred to the mandatory aggregate gate.

## Store and concurrency boundary

CA5-2 exposes aggregate read, root lock, root ensure and whole-aggregate replacement/CAS only. Replace deletes/inserts child state and advances the root version inside the caller transaction; stale CAS returns a typed error, requiring caller rollback. CA5-3 is not allowed to discover locks inside Replace: contracts expose reference collection/union/coverage so it can pre-read old state, plan old∪desired Hero/Pet keys plus rank 440, acquire 410→430→440, reread under root lock and abort/retry if the locked state contains an unplanned reference. This remains compatible with D01.

## MID1 and wire reality

The bootstrap detail contributor claims exactly 17.save_team, 17.save_team_name and 17.save_pet and reads canonical aggregate state. Projection derives the three positional strings from one ordered lane model and emits aligned zero Pet sentinels. 17.formation is not claimed. No MID1793 write route is introduced.

## Legacy migration reality

The anti-corruption adapter parses legacy raw state, requires explicit CA2/CA3 identity mappers, validates mapped typed refs through CA5-1 owner seams, quarantines unresolved/malformed/nonprojectable aggregate state and refuses a conflicting non-empty target. It does not assume source numeric IDs equal V2 IDs and does not perform foreign-owner SQL.

## Successor and negative reality

Stockruntime/replay routing remains unchanged for MID1793/208/209. CA5-2 does not activate reverse removal guards, MID66, I9 mode ownership or the CA8 composite snapshot. These remain later-stage concerns.

## Testing/evidence classification

Canonical static validators are GREEN. Exact canonical Go execution is ENVIRONMENT_BLOCKED by the unavailable pinned toolchain. A fresh disposable copy differing only in go.mod/.go-version toolchain declarations passes focused tests, focused race, focused vet, full go test ./... and full go vet ./.... These are COMPATIBILITY_COPY_ONLY. Real PostgreSQL and exact/native accumulated CA5 proof remain explicitly deferred and mandatory immediately before CA5-E per user direction.

## Verdict

GREEN_LOCAL_CA5_2_ACCEPTED_COMPATIBILITY_COPY_ONLY_NATIVE_AGGREGATE_DEFERRED_PRE_CA5_E. This is a CA5-2 local checkpoint, not CA5 parent acceptance. The next permitted product activity after Pass562 seal is CA5-3 preimplementation research/reconciliation; CA5-3 implementation is not authorized by this record.
