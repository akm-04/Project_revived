# Pass110.0 Technical Changelog — RNG Backbone Stage 3 Phase A

## Scope

Pass110 implements only the RNG foundation frozen in Pass109. It does not change Summon, Campaign, event, world-mode, shop, practice, generated-instance, or other domain policy.

## New production module

`gxb_backend/state/random_outcome_service.py`

- `EntropyDrawRequest`: frozen mechanical draw coordinate (`namespace`, request-local `ordinal`, `upper_exclusive`).
- `EntropyProvider`: minimal `draw(request) -> int` protocol.
- `SystemEntropyProvider`: production OS entropy through `secrets.randbelow()`.
- `RandomOutcomeService`: request-scoped mechanics with:
  - `randbelow(namespace, upper_exclusive)`;
  - `choose_index(namespace, size)`;
  - `weighted_index(namespace, weights)`.
- `NamespacedRandbelowAdapter`: exposes the existing `randbelow(upper)` shape while binding one frozen namespace.

### Validation invariants

Namespaces must match the frozen lowercase dot-separated grammar. Bounds must be exact positive integers; booleans are rejected. Weighted selection accepts only a nonempty sequence of exact nonnegative integer weights, requires at least one positive value, preserves caller order, and consumes exactly one bounded draw.

Request-local namespace ordinals advance only after a provider result has been validated as an integer within the requested range. Input validation failure or invalid provider output therefore does not silently consume an ordinal.

No pool construction, rate/pity/guarantee policy, eligibility, cost, mutation, receipt, persistence, authentication entropy, UUID generation, seed API, shuffle, or sampling policy lives in this service.

## Deterministic test support

`gxb_backend/testing/scripted_entropy.py`

- `ScriptedEntropyDraw` declares the exact expected namespace, ordinal, bound and returned value.
- `ScriptedEntropyProvider` fails loudly for unexpected draws, bound mismatches, out-of-range scripted values and duplicate script keys.
- `assert_exhausted()` makes skipped expected draws fail explicitly.

This turns accidental draw-topology changes into deterministic test failures rather than silently changing gacha behavior.

## Request-scoped wiring

`RequestServices` now accepts an optional `entropy_provider` and creates exactly one `self.random_outcomes = RandomOutcomeService(entropy_provider)` for that request-scoped service graph.

This is intentionally inert in Pass110. `ClassicVendingPrivatePlanner`, `CampaignDropPlanner`, and all other existing gameplay planners retain their previous random-source dependencies. The new service is available for later bounded migrations only.

## Version

Backend version is bumped from `0.13.1` to `0.14.0` because this pass introduces the shared RNG infrastructure layer. Pass version is `110.0`.

## Next bounded implementation

Recommended Pass111: MID50 source-native per-click UUID bridge + durable `PlayerUnitOfWork` receipt/replay migration + namespaced entropy adapter injection, preserving existing Summon probability/pool/pity policy unchanged. Campaign MID117 remains after MID50.
