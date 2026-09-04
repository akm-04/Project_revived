# Pass129.0 Technical Changelog — Behavior-neutral architecture hygiene

## Why this pass exists
Pass128.4 found a healthy acyclic strangler architecture, but two concrete drift risks: RequestServices and PlayerMaintenanceServices duplicated Campaign construction, and WorldRepository could silently create missing Campaign collaborators. Pass128.5 then runtime-accepted the Campaign wire fix, allowing the user-approved behavior-neutral hygiene pass to proceed.

## Source feedback loop
Effective `src_64` was rechecked before code modification. The client still treats LOAD_WORLD_MAP rows/cursors, Function31-triggered map reload, Normal-vs-Super entry gating, and stock MID113/MID114 request/result shapes as observable contracts. None of those contracts prescribe Python module layout, so Pass129 changes construction only.

## Implementation
Added `CampaignComposition`, a frozen construction bundle that creates one Challenge/Super collaborator graph and validates object identity. Request and maintenance roots now use the same builder, while retaining their intentional transaction difference: request projection/coordinator receive the request UoW; maintenance receives no UoW.

Both live roots now inject Challenge and Super collaborators explicitly into WorldRepository and enable `strict_campaign_collaborators`. Strict mode fails fast if any Campaign collaborator is missing or belongs to a parallel graph. Legacy direct callers retain the pre-Pass129 fallback path when strict mode is not requested, preserving the facade during incremental strangling.

No Campaign policy, response serializer, reward plan, battle session, sweep settlement, player schema, UoW contract, Lua or OTA bytes were changed. The four Super modules remain separate authorities.

## Validation
Pass129 identity/acyclicity suite passes 5/5. Pass128 Super progression 12/12, Pass128.2 MID112 4/4, Pass123 manual battle 6/6, Pass122 Challenge 5/5, Pass121 MID117, Pass94 progression, Pass92 reset and Pass96 economy/VIP all pass. Python compileall passes. Known old `selftest_campaign_economy.py` and `selftest_multiuser.py` failures reproduce unchanged on frozen Pass128.2 and are not Pass129 regressions.

## Remaining strangler debt
WorldRepository remains the main orchestration hotspot. Do not extract MID113 and MID114 separately: a later facade-preserving `CampaignBattleService` should move them together with `active_campaign_battle` invariants intact. MID117 should move into a sweep use-case boundary when Campaign EXP/Mana reconciliation begins. MID112 reconcile/pure serialization remains a later dedicated pass because Pass128.2 wire self-heal is runtime-sensitive.

## Runtime gate and roadmap
Before entering gameplay-semantic work, run one client smoke/reconciliation on this candidate. After runtime acceptance, resume the accepted roadmap with Campaign Player EXP + Mana sweep economy, then RNG closure, Generated/Unique, Girls/Equipment, and deferred verticals.
