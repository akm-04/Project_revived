# I7C-5A combat input, attempt and result foundation

Contract: `C5A_COMBAT_INPUT_ATTEMPT_RESULT_FOUNDATION_V1` (`I7C5A_POLICY.json`), plan `I7C5A_PLAN.json`, amendments `I7C5A_PLAN_AMENDMENTS.json`, acceptance rows `I7C5A_ACCEPTANCE_MATRIX.json`.

Implemented:

- `tools/generate_combat_corpus.py` compiles 778 exact Lua modules and 45 decoded source tables from archive `c7e98789…` into `internal/content/combatcorpus/generated`; `tools/check_i7c5a_source_oracle.py` re-derives it byte-exactly and pins the design source facts.
- `internal/domain/combat`: snapshot (OWNED_SELF/OWNED_FOREIGN/TEMPLATE actors, per-player collection attr and exclusive book quantities), canonical encoding/hash, Pass418 attempt envelope and transitions, HMAC counter entropy with the Lua `random` mapping, resolution record. Combat attempt lock rank 609.
- `internal/adapters/combatresolver` + `cmd/gxb-combat-worker`: the pinned source `BattleCreateReport` engine in GopherLua v1.1.2 with `SNAPSHOT_ONLY_ADAPTERS_V1`; no database, network, filesystem, subprocess or wall clock.
- `internal/adapters/combatworker`: one worker process per resolution with empty environment and cwd, RLIMIT_AS/CPU/NOFILE/FSIZE/CORE, process-group wall deadline kill, bounded output and retryable/permanent classification.
- `internal/application/combat`: `StartTx` (caller transaction, locator lock, same-fingerprint replay, typed conflict, freeze through existing owner reads), `Resolve` (outside locks, persist once, idempotent duplicate, integrity on mismatch, positive-evidence unknown COMMIT), `TerminalTx` (caller transaction, settles once, replays recorded result).
- `migrations/00064_i7c5a_combat_foundation.sql` + `internal/adapters/postgres/combatstore`: locator roots, append-only snapshots/resolutions/report blobs, attempt guard trigger.

Not in scope and not qualified here: every combat mode (5B–5F), stock-client end-to-end, original RNG parity, mode locators/costs/rewards/retention, BORROWED and CLIENT_ATTESTED profiles, full I7C-4 gates.
