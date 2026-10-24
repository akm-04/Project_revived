# Pass631 I7A-4A independent postimplementation reality check

## Result

**GREEN for local I7A-4A implementation completeness and external exact-runtime gating. I7A-4A exit acceptance is not yet claimed.**

I independently re-read the sealed Pass630 I7A-4 contract pack, exact Pass629 accepted parent identity, the committed 4A diff, ownership metadata, migration 00033, lock ranks/creation-fence law, I4 discovery seam, and the route registration surface. No superseded Pass619 Social topology or historical MID182 naming was used as current authority.

## Architecture/ownership reality

- `00033_i7a4a_social_foundation.sql` is forward-only Goose-managed schema. It creates no synthetic Social facts, does not activate MID23/name editing, and adds no player-name uniqueness.
- SocialRelation is the sole durable owner of SocialRoot, friendship, request, block and request-epoch facts. SocialInbox solely owns notice lifecycle/identity and its bigint sequence. The I4 directory remains the sole profile/discovery SQL owner.
- Selected ranks remain total and collision-free: I4 PlayerRoot 315; Guild Audit 350; SocialRoot 360; Friendship 361; Request 362; Block 363; RequestEpoch 364; Notice 370. Missing-child creation still relies on an already-held canonical parent/root plus uniqueness; absent-row `FOR UPDATE` is not treated as protection.
- The additive `playerdirectory.DiscoveryReader` contains selection only: exact-name reads plus deterministic PlayerID bounds/paging. It contains no Social exclusions/recommendation policy and Social packages contain no direct `player_directory_profiles` SQL.
- No stock Social route becomes newly authoritative in 4A. MID176 remains the prior lobby compatibility facade and MIDs177-190 remain unregistered.

## Implementation corrections made before freeze

1. An early architecture test incorrectly treated stable uniqueness-constraint names used by the accepted I0 `CreationFence` contract as forbidden schema coupling. The **test** was corrected; no ownership law was weakened.
2. An early notice schema required `notice_time >= created_at`. That would block a later typed SocialInbox provider from materializing an older source event. The overconstraint was removed while preserving `dismissed_at >= notice_time` and `updated_at >= created_at`.

Neither diagnostic tree was copied into canonical wholesale; subsequent qualification used fresh disposable compatibility copies.

## Foundation impact reality

Canonical-tree current/cumulative validation is green through R0-R4D and I1-I5, with hash-bound I2/I3/I4/I5/I6A/I6B/I6C source-oracle checks green. The historical R5/R6 snapshot-pin reds remain the already-authorized pre-existing modern-metadata exception and were not used to roll metadata backward.

The exact candidate's Go/toolchain pins remain byte-identical to the accepted parent. Exact Go1.27.1 execution is environment-blocked in this sandbox. Fresh Go1.23.2 disposable compatibility copies pass focused tests, focused race, `go vet ./...`, and full `go test ./...`; these are diagnostic only.

Real PostgreSQL/Goose binaries are unavailable locally. Therefore fresh `00001 -> 00033`, populated exact `00032 -> 00033`, and restore/sequence semantics remain mandatory external evidence before I7A-4A exit can be accepted.

## Verdict

No product defect or contract contradiction remains from local review. Freeze the exact candidate, send it through the external I7A-4A real-PostgreSQL/Goose gate, and independently adjudicate returned evidence before authorizing I7A-4B. Do not activate Social routes and do not advance I7A-4B merely from local/compatibility evidence.
