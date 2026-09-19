# Pass484 prepared R5 native Work-gate plan

Status: **READY FOR NATIVE R5 WORK GATE AFTER PACKAGE HASH/PassMap BINDING**. The exact source/oracle/generator rerun is green. This document is a test plan only, not native evidence.

Candidate prerequisites before entering Work:
1. Exact Pass484 backend ZIP hash matches PassMap/additional-materials.
2. Canonical Go pins are pristine (`go 1.26.0`, `toolchain go1.27.1`, `.go-version 1.27.1`).
3. **SATISFIED** — exact external oracles satisfy `INPUTS.json` SHA256 identities.
4. **SATISFIED** — normal-chat static/source-oracle/generator gate is green; Go execution evidence remains separately labeled `COMPATIBILITY_COPY_ONLY` because exact Go1.27.1 is environment-blocked here.

Native environment target: PostgreSQL18.6, Goose, pgx, River0.47.0, Go1.27.1.

Required native cases:
- fresh migration chain through 00011 and accepted 00009/00010 hash preservation;
- legacy DB upgrade to 00011; prove migration/activation alone leaves temporal policy identity legacy;
- explicit legacy->immutable temporal rebind materializes old policy at operation time then binds exact caller revision;
- same semantic rebind repeat, reconnect/service restart replay, stale-state CAS, missing policy, immutable-without-receipt failure;
- concurrent same-identity and conflicting target-revision rebind under real PostgreSQL SERIALIZABLE semantics;
- injected ambiguous COMMIT/reconciliation: no blind value replay, later receipt recovery;
- D01 PlayerExp rollback if Energy/function/directory leg fails; lock-order/concurrency contention across scalar/stack/PlayerExp and outer Mail/Objective/Redeem paths;
- historical v1 receipt replay remains terminal and does not synthesize R5 side effects;
- canonical MID1 reload after rebind/restart retains persisted content revision and stock numeric-0 anchor shape;
- River adapter/startup compatibility without making River job state gameplay authority;
- backup, restore and reconnect/replay from restored database; verify receipt/temporal/content identity survives;
- collect exact commands, DB version/extensions, migration status, candidate hash, race/fault conditions, logs and limitations.

Return rule: package Work evidence and return to normal chat. Do not seal R5 or start R6 in Work.
