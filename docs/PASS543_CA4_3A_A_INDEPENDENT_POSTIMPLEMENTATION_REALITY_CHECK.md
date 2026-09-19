# Pass543 — CA4-3A-A independent postimplementation reality check

## Result

**GREEN — 46/46 independent checks.** This is a same-agent independent reread/check, not evidence of a second human or model reviewer.

## Re-derived facts

- The generated `HERO_FUMO_CA4_3A` capability still reproduces the sealed Pass542 current-source oracle: **359 Fumo targets** and **516 stock-reachable Hero-Fumo materials**.
- Sparse and fractional stat rows remain exact source facts: 40 reachable sparse rows and 14 fractional values are preserved as exact decimal strings. Type-8 Pet equipment remains excluded from Hero-Fumo materials.
- `00021_ca4_3a_hero_fumo.sql` is forward-only, adds the two content tables and exactly six nonnegative Hero raw-Fumo columns, and is registered as the cumulative migration high-water.
- Character/Hero is the sole durable owner of the six raw Fumo totals. No durable `fumo_level` field was introduced.
- `SaveHeroStateTx` persists star/level/exp/equipment/raw-Fumo through one Hero CAS.
- `RawEquipmentStateTx` now accepts valid collected special/Awakening mappings and exposes Hero-owned `RawFumo`; it does not become final stat authority.
- General stock Hero reload emits durable `fumos` and intentionally does not invent/persist `fumo_levels`.

## Ownership / stage-boundary reread

- New Fumo content tables remain owned only by the existing content registry.
- CA4-3A-A contains no I5 gameplay mutation changes.
- No MID58 dispatcher branch, service, or production registration exists in A. MID29, MID51, MID57 and later Pet/Super/battle-stat mechanics remain untouched.
- Canonical `.go-version`, `go.mod`, and `go.sum` are byte-identical to the accepted parent pins.

## Execution evidence

The exact unmodified candidate was attempted first; it is **ENVIRONMENT_BLOCKED** at the pinned Go 1.27.1 toolchain download because the sandbox cannot reach `proxy.golang.org`. No canonical toolchain/dependency file was changed.

A fresh disposable compatibility copy, with only the minimum local Go/toolchain accommodation, passed focused tests, focused race, `go vet ./...`, archguard, source/query/schema/sqlc checks and the bounded **92/92 package regression**. These results are `COMPATIBILITY_COPY_ONLY` and are not promoted to exact-toolchain/PostgreSQL/River proof.

## Verdict

CA4-3A-A is locally accepted for its bounded content/durability/projection scope. The next permitted implementation stage is CA4-3A-B from an immutable A checkpoint.
