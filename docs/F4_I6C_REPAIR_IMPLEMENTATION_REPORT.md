# F4 bounded I6C post-acceptance repair implementation report

Status: IMPLEMENTATION_COMPLETE; F5 local/bounded regression pending; F6 exact native PostgreSQL requalification mandatory.

## Bound authority

- Base backend: exact Pass502 `e5bb29ddd61ffd9fccfc761f7727f46b1de938144e05f27a1aabb6e1756a4322`.
- Memory authority: Pass503-F3 `c4f9708612d88241e3c71a8aa35ca0df464e33f9882d9f45710714e102366ade`.
- F1/F2 contracts are implemented without expanding into I6D.

## F01

Membership incarnation is derived from the latest append-only `guild_membership_events.event_id`; the event must be the same-player/same-Guild JOIN for the current membership. Leave, kick, and role receipts use v2 identities containing incarnation. `membership_version` remains mutable current-row/role state. No fallback to v1 collision-prone identities is permitted.

## F02

MID580 is current-state convergent. Current locked `apply_type` chooses application/immediate/closed behavior. In application mode, an existing current application converges before creation-only mutable capacity gates. A missing row creates a fresh `application_generation` and branch-specific v2 receipt for same-attempt/UNKNOWN-COMMIT proof. Immediate join converges from current membership and clears outgoing applications. Guild Create now clears outgoing applications atomically as well.

Migration `00013_i6c_guild_replay_repair.sql` is forward data-cleanup only: it removes application rows for players who already have canonical GuildMembership. Migrations 00001-00012 remain byte-identical.

## F06/F07 maintenance

The resolved SBOM is regenerated from current BUILD_INFO/dependency lock. Historical R6 validation remains strict by default; cumulative mode permits later researched migrations/dependency closure, and an explicit compatibility-scratch mode exists only for disposable diagnostic copies. `tools/check.sh` now includes I6A/I6B/I6C source-oracle checks and the cumulative candidate validator. The replay catalog now classifies all routed Guild mutations, including membership-incarnation-bound and current-state-convergent families plus the paid-rename residual ambiguity. Historical R4D/R5 validators also retain strict canonical toolchain checks by default while skipping only those toolchain assertions in explicit `GXB_COMPAT_SCRATCH=1` diagnostic copies; all of their semantic and migration invariants still execute.

## Local evidence

Canonical static/source validation is GREEN. A fresh Go 1.23.2 disposable clone with only the required toolchain accommodation passed focused Guild/store/replay/architecture tests + vet and the applicable cumulative/static/source checks. This evidence is explicitly COMPATIBILITY_COPY_ONLY and is not Go 1.27.1/PostgreSQL/River proof.

## Next

F5 must run a fresh-clone bounded/full regression on the packaged F4 candidate. F6 must then run exact native Go 1.27.1 + PostgreSQL repair requalification including concurrency, UNKNOWN COMMIT, 00012->00013 upgrade, retained receipts, restart, and pg_dump/restore. I6D stays suspended until repair reality check/seal/rebind.
