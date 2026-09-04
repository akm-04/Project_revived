# Pass241 — Emblem I0 Foundation Implementation Report

## Status

**PASS — foundation implemented; no public Emblem route behavior changed.**

Executable base is the accepted Pass232 v0.35.3 backend. Pass241 promotes the backend artifact version to **0.37.0** while retaining OTA **1.631.22** because no client/Lua/resource payload changed.

## Current-source authority

All newly packaged Emblem/Inscription Lua evidence is byte-copied from `all-assest-rechecked-1.zip` effective `app-assets/output/assets/src_64`. Historical v1.164 remains evidence-only and is not consumed by the runtime catalog builder.

The deterministic catalog builder reproduces the sealed Pass236 census: 23 forge rows, 254 concrete medals, 210 ordinary candidates, 30 Scholarship pieces, 14 Honor non-forge artifacts, 30 Scholarship dynamic positions, and 12 exact sets.

## Architecture implemented

- `EmblemSourceCatalog`: immutable current-source operational facts with strict relationship/census validation.
- `EmblemPolicyRegistry`: versioned compatibility-policy registry (`emblem-v1`). The unrecovered outer Scholarship rate is represented only as planned compatibility policy and remains disabled in I0.
- `EmblemOutcomePlanner`: source-relative deterministic draw topology over the existing request-scoped `RandomOutcomeService`; outer Scholarship gate raises while disabled and consumes no entropy.
- `EmblemStateRepository`: complete server-only domain aggregate for policy version, proposal generation, latest pending rebuild and independent Forge/Reforge counters. Mutations require the existing active `PlayerUnitOfWork`.
- `EmblemService`: cohesive protocol owner skeleton wired to the existing inventory, Hero mutation, settlement and UoW graph.

`player.domains.emblem_state` is a canonical-replacement persistence path so clearing pending nested state cannot resurrect values through extension-preserving merge semantics. Equipped medals remain exclusively represented by Hero `inscript_items`.

## Public behavior fence

I0 intentionally does **not** reroute Inscription protocol:

- MID1402/1403/1404/1407 remain on the accepted Pass232 deterministic owner.
- MID1400/1401/1405/1406 remain the same fail-closed public path.
- No Function45/Heart/equipment reconciliation is activated yet; those belong to I1/I2.
- No client payload changed.

## Validation

Green gates: compileall, Pass241 I0 self-test, Pass129 architecture hygiene (5/5), Pass212 P2 Stage-G, Pass227 Blood MID867 wire, Pass230 dev cleanup, Pass231 forward no-popup correction, and Pass232 event recovery/log rollover.

## Next wave

**I1 deterministic ownership reconciliation:** move MID1402/1403/1404/1407 under `EmblemService`, use the current-source concrete position resolver (including Scholarship pieces), preserve accepted dissolve/Star-exchange wire/economy semantics, and keep public RNG MIDs fenced.
