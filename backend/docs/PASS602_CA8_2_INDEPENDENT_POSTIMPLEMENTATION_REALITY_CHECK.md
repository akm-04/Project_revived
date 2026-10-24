# Pass602 CA8-2 Independent Postimplementation Reality Check

Result: **GREEN for local CA8-2 acceptance; exact/native aggregate proof remains deferred to CA8-9.**

## Contract trace

- I0 ownership preserved: CA2/CA3/CA4 remain durable owners; CA8 adds read/export contracts only.
- I1 semantics preserved: `tx.Scope.Options` exposes the already-selected Runner options; retry, commit, UNKNOWN-COMMIT, cleanup and receipt behavior are unchanged.
- I2 preserved: no MID/wire contract was added or changed.
- I3 preserved: OWNED/BORROWED/TRIAL/NPC_TEMPLATE remain distinct vocabulary; CA8-2 activates no borrowed/synthetic business behavior.
- I4 preserved: no realtime/publication authority added.
- I5 preserved: no foreign-owner SQL or economy mutation.
- I6 preserved: provider disposition is result-local metadata and does not replace content/capability authority.

## Predecessor trace

- CA2 Hero base state is read through canonical Hero storage; Hero kind is resolved against immutable `CreationContentRevision` through the caller Queryer.
- CA3 Pet base state includes CA3-owned skills/Birthday/IsShow and exact `StateVersion`.
- CA4 Pet export is completed as the previously deferred read adapter; it reads CA4-owned equipment/Fumo and pinned content only.
- CA4 Hero equipment capability validation is kept inside the caller coherent transaction.
- CA5/CA6/CA7 ownership and providers are untouched.

## Independent implementation review

The final diff contains no migration, schema, durable Character row, receipt, scheduler, MID, final battle-stat compiler, borrowed/rental policy, synthetic actor policy or dependency-pin change. The only foundation modification is the additive transaction-options witness frozen by CA8-1.

An initial over-constraint requiring the caller's Go `time.Location` pointer to be literally UTC was caught during review and corrected to normalize the same instant with `UTC()`; all final tests were rerun from a fresh disposable compatibility copy afterward.

## Evidence limitations

The environment cannot execute the canonical Go 1.27.1 toolchain. Whole-tree test/race/vet evidence is therefore `COMPATIBILITY_COPY_ONLY`; canonical static/architecture/source-oracle checks are GREEN. CA8-9 remains responsible for the accumulated exact/native PostgreSQL/concurrency gate. No stock-client/W2 claim is made.
