# v0.8.16 / Pass40.1 — Campaign Drop Planner Skeleton

## Implemented
- immutable generated `CampaignDropSourceCatalog` preserving ordered `init_dropbox`/repeat `dropbox` rows and raw source rates;
- editable/versioned `CampaignDropPolicyRegistry`;
- injectable `RandomSource` seam with no repeat-RNG use in this pass;
- pure `CampaignDropPlanner`;
- MID113-only planner invocation and persisted occurrence/source/policy metadata;
- MID114 commit of the frozen aggregate only;
- exact migration of the prior deterministic `increase_rate == 10000` first-clear behavior.

## Explicitly deferred
- repeat Campaign RNG/formulas;
- reinterpreting `increase_rate` as probability;
- Super/Challenge progression semantics beyond catalog availability;
- Campaign stamina/defeat/sweep RNG changes;
- Summon/Vending/MID50 work;
- Ghost Item repair.

## Response contract
MID113 continues to return battle-visible `items`. MID114 continues to return result-only `items: []` under the Pass36.1 ownership split.
