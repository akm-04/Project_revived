# RULING I9-12: seal carry sync (I9_12_CARRY_V1 registered at the seal)

Date 2026-11-22. Lead ruling under the amend-on-evidence policy, from the I9-12 seal audits
(tmp/seal_i912_audit/AUDIT_03.md, AUDIT_04.md). Logged for user review. I9_12_CARRY_V1 was drafted before the I9-11
seal and built on i9-12, but was never registered; it is registered with this ruling, which records where the merged
code and the draft text differ.

## 1. Girls Log lock order (amends I9_11_GIRLS_LOG_V1 G2)

G2 "the counter row lock is taken last" yields to I9_12_CARRY_V1 R7 (A-206: the partner mission port is called last in
the settling transaction). In march settle (internal/application/march/settle.go:96-107) the Girls Log counter lock
comes before the partner mission write. March is the only flow that takes both rows and always in this order, so no
lock cycle exists.

## 2. Mission 1002 counts per duel (I9_12_CARRY_V1 R7 stands)

R7 says one advance per friend-fight duel; arena advances once per settled round (tournament_combat.go:285-293). With
the pinned catalog (mission 1002 required 1) the result is identical. The text stands; the code is a repair-lane item.

## 3. March mission timestamps after a clock rollback (I9_11_CLOCK_ROLLBACK_V1 K3' stands)

A march win after a backward clock step stores the raw decision time as the mission row's updated_at
(librarystore/facets.go:93) instead of max(at, previous). K3' stands; the code is a repair-lane item.
