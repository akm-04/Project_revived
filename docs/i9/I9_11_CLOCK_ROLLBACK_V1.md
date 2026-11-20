# I9_11_CLOCK_ROLLBACK_V1

Lead contract, 2026-11-19, for Sol T33 A-151 (login fails after the server clock moves backwards). Owner: Foundation time (`internal/application/generation`) for the helper; each guard's owner for its call site; `commerceprivilege` for the reproduced site. Evidence: /home/akm/Chatgpt/EOL_Game/tmp/reality_11t33/clock-rollback-REPORT.md and time_guard_inventory.json (fleet_11t33c, tree 0b793627).

## Rules

K1. Helper: one pure function in internal/application/generation, `EffectiveObservation(now time.Time, stored ...time.Time) time.Time`, returning the latest of now and the stored times. No table, no migration, a read never writes.
K2. Read guards: every future-read guard in time_guard_inventory.json (a read that refuses because a stored UpdatedAt/ObservedAt is after the decision time) uses the effective observation instead of the raw decision time. First the login-blocking set (commerceprivilege/observation.go:52-63, domain/privilege/privilege.go:123, domain/economy/daily_floor.go:39,47, playerdisplay/facts.go:114-138 and the roster overlays), then the rest of the class. Intrinsic guards (UpdatedAt < CreatedAt, journal order) stay refusals.
K3. Write clamps: writers store UpdatedAt = max(at, previous UpdatedAt, CreatedAt), as tap.go:298 already does (extend to manual.go:220 and the other producers in the inventory). Stored forward timestamps are never rewritten.
K4. Time-driven windows (daily reset, weekly, expiry) keep using the real decision time; only the guard comparison moves. A rollback does not grant a second daily reset.
K5. ErrConflict maps to 409/35028 in failure.go (today 500/35028 at failure.go:286-288, a D5 violation). A genuinely malformed row is a 409 refusal, never 500.
K6. Each guard changed is listed in the build report with file:line; any guard left unchanged has a one-line reason.

## Tests

Native, with an injected time authority (no clock mutation): privilege root with UpdatedAt = T+8h, login at T -> MID 1 200 with details 17 and 160; then a privilege write keeps UpdatedAt >= T+8h and CreatedAt <= UpdatedAt; a malformed root (UpdatedAt < CreatedAt) -> 409, not 500; one regression per fixed overlay (book, dorm, spirit at least) with a forward-dated row. Unit test of EffectiveObservation. failure.go mapping test for ErrConflict.

## Amendment 1 (lead, 2026-11-19 ~07:10 UTC, after reviewing build 07cf4408)

K2 as first written produced tautologies. With E = EffectiveObservation(at, stored), `stored.After(E)` and `E.Before(stored)` are always false (dead code), and `at.Before(E)` equals `at.Before(stored)` (the original refusal, unchanged). Build 07cf4408 used the second form at 74 sites and reported them as changed. Binding clarifications:

K2'. A future-read guard is removed outright: delete the `stored after decision` comparison, keep every other condition in the same `if`. Any later use of the decision time as an observation (a value stored in a snapshot, compared for equality or passed on as ObservedAt) uses E. EffectiveObservation is never compared against one of its own inputs.
K3'. A write site that refuses because the stored UpdatedAt is after the decision time is a write guard: it stops refusing and stores UpdatedAt = max(at, previous UpdatedAt, CreatedAt) (K3). Row locks, state versions and compare-and-set checks are the concurrency guards and stay unchanged; a time comparison is never a concurrency guard.
K7. No tautologies: `git grep` for `Before(gen.EffectiveObservation`, `Before(generation.EffectiveObservation`, `After(gen.EffectiveObservation`, `After(generation.EffectiveObservation`, `EffectiveObservation(...).Before(` and the hand-written domain clamps followed by the same comparison finds none. A unit test per owner package proves that a decision time one hour before the stored UpdatedAt is accepted (read returns the row, write commits with UpdatedAt equal to the stored value).
K6'. The report lists each guard as REMOVED (read), CLAMPED (write) or KEPT (intrinsic/window, with a reason), file:line.
