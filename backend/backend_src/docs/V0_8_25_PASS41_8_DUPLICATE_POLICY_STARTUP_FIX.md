# Pass41.8 / v0.8.25 — duplicate policy startup fix

## Regression
Pass41.7 changed `data/summon_result_policy.json` duplicate-conversion `activation_status` to `recovered_evidence_active` when the historical 1★/2★/3★ = 7/14/30 fragment table replaced the provisional private values. The Python registry's startup validator still enumerated only the old fail-closed/private states.

During `StateRepository` construction, legacy/multiuser player normalization instantiates `SummonRepository`, which constructs `SummonResultPolicyRegistry`; the stale enum guard therefore raised before Flask could start.

## Fix
`SummonResultPolicyRegistry` now accepts exactly three statuses:
- `unknown_fail_closed`
- `private_policy_active`
- `recovered_evidence_active`

Recovered-evidence activation additionally requires both a `policy_file` and a non-empty `quantity_by_initial_star` map. No probability, quantity, cost, counter, or mutation semantics were changed.

## Persistence note
The canonical multi-user runtime state root is `data/server_state/`. `data/player_db.json` remains the legacy anonymous-sandbox migration source. Because `data/` also contains release-owned catalogs/policies, account carry-forward should merge/copy runtime state rather than overwrite the full new `data/` tree with an older release.
