# Pass581 CA6-6 identity/provenance repair candidate

Status: **RETEST PENDING / NOT ACCEPTED**.

The Pass580 CA6-6 exact/native run returned 33/34 matrix rows green. The only red row was ID01: PassMap/handoff asserted product-tree digest `f8c0db62554de2e860df9d85d41b8595fc7c18871f7e61db6670cbecae2fd993`, while the exact frozen Pass579 archive's checked-in tree-digest procedure reproducibly returned `9c4a80134ebc6986394a1e2d2ede9edd7352577db51f43345759d7a4204ff1ba` on both fresh pre/post-test extractions with 1,431 regular files excluding `.git`. Archive SHA, snapshot manifest, canonical Go pins, second extraction, and all substantive CA6-6 runtime gates were green.

## Foundation/contract impact review

The exact Luna run revalidated I1-I5 validators, I6A/I6B/I6C source-oracle gates, cumulative foundation trace, schema/query ownership, dependency/SBOM policy, sqlc policy, current-candidate validation, CA6 source oracles, and full exact Go/race/static gates. Real PostgreSQL/native CA6-6 proof also passed receipt replay/conflict, UNKNOWN-COMMIT recovery, concurrency/deadlock, migrations/upgrade/restore, daily epoch/free timer clock behavior, AUTO convergence and MID124-134 routing. No gameplay/runtime defect was found.

Therefore this repair is bounded to candidate identity/provenance tooling and release metadata. It does **not** alter Go gameplay source, migrations, SQL ownership, protocol routing, content, Practice policy, transaction/lock semantics, receipt behavior, or time semantics. Parent I0-I6 and CA6 contracts remain controlling and unchanged.

## Root cause

Pass579 acceptance tooling copied a precomputed product-tree digest into PassMap authority without recording an algorithm identifier or recomputing that value from the final frozen archive. The checked-in candidate verifier had an independently implemented whole-tree algorithm. The final exact archive is reproducible, but the external Pass579 `f8c0...` assertion is not reproducible from it. This is the same class of stale handoff metadata previously handled explicitly at Pass532; it is not legitimate to mutate gameplay bytes to manufacture the obsolete digest.

## Repair

- Add `tools/candidate_identity.py` as the one canonical complete-tree identity implementation.
- Make `tools/check_connected_candidate.py` consume that implementation and fail closed on snapshot-manifest drift.
- Add `docs/CANDIDATE_IDENTITY_CONTRACT.md` specifying archive, snapshot, tree and implementation identities plus freeze order.
- Refresh release metadata to a distinct v0.80.1 Pass581 **repair candidate**, still unaccepted until exact Luna retest.
- Ship a Git repository with an exact Pass579 baseline commit followed by this repair commit. `.git` is intentionally excluded from product-tree/snapshot identity but included in archive SHA-256.
- External Pass581 authority must record the final computed tree digest and mark Pass579 `f8c0...` as superseded metadata rather than silently overwriting history.

The CA6-6 aggregate gate must be rerun against this exact candidate. CA6-E remains blocked until that retest is green and independently adjudicated.
