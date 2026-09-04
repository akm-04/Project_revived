# Pass244 — Emblem I3 RNG / Policy / Pending-Proposal Foundation

## Status

**PASS — I3 internal foundation implemented/static-regression accepted; public MID1400/MID1401/MID1405/MID1406 remain fail-closed.**

Executable base is Pass243 v0.37.2. Pass244 promotes the backend to **v0.37.3** and keeps OTA **1.631.22** because no client/Lua/resource payload changed and no public Emblem RNG route is opened in I3.

## Current-source reality check

Current `src_64` remains authority. `inscription_rate.lua` is rechecked directly from the packaged current-source evidence and still contains only the two rows `(rate_suit=0, rate_step=0.1, max_num=1000)` and `(0,1,100)`. A fresh literal caller scan finds no current Lua reference to `inscription_rate`, `rate_suit`, or `rate_step`. Therefore the sealed Pass240 epistemic boundary remains unchanged: the outer Lv7 Scholarship formula is **not recovered official-server math** and is implemented only as versioned `emblem-v1` compatibility policy.

Current source-owned RNG facts remain separate: ordinary `rand` vectors are relative integer weights, Lv7 special-family split is 70/30, and special-family concrete candidate rows use their own current-source weights. Current reforge UI/wire still has no proposal nonce/ID; MID1405 sends only the selected candidate item, supporting the sealed latest-proposal-wins state model.

## I3 implementation

- `EmblemPolicyRegistry` now internally activates the versioned `emblem-v1` outer Scholarship policy while retaining its explicit compatibility classification and negative claim.
- Fixed-point denominator is 10,000 basis points. For an eligible Lv7 draw: `attempt = misses_since_special + 1`; `chance_bp = min(10000, rate_suit_bp + attempt * rate_step_bp)`; `attempt >= max_num` is a deterministic hard special.
- Forge and Reforge use independent durable miss counters already stored in `player.domains.emblem_state.scholarship_rng`.
- A hard ceiling consumes **no Scholarship-gate entropy draw**. Non-hard gates consume exactly one `randbelow(...,10000)` draw.
- `EmblemOutcomePlanner.generated_candidate()` validates every ordinary/special candidate pool before entropy. Lv1-6 never touch Scholarship gate/counter state. Lv7 processes outer gate first, then source 70/30 family + source special item weights on hit, or source ordinary weights on miss.
- Reforge ordinary outcomes exclude exactly the current concrete source medal under the sealed source-shaped compatibility policy while preserving all remaining source relative weights. Independent 10x results may duplicate one another.
- `EmblemStateRepository.apply_scholarship_result()` applies an already-generated gate result only when its `misses_before` still matches durable state, preventing stale outcome application.
- Pending-proposal normalization is stricter: frozen candidates must be source-valid generation outputs for the original tier. Cross-tier candidates are scrubbed; Scholarship candidates are valid only for Lv7 origins. Frozen older `policy_version` values remain preserved so later policy upgrades do not reroll old proposals.
- `EmblemService` gains internal-only generated-candidate and rebuild-proposal helpers. They require an active `PlayerUnitOfWork`, update Lv7 counters sequentially, and persist latest proposal generation/candidates. They deliberately perform no protocol cost settlement in I3; I4/I5 will call them only after authoritative cost preflight.
- Latest proposal replacement increments `proposal_generation` and atomically replaces the prior frozen proposal. Pending state remains durable across restart via the existing canonical `emblem_state` persistence owner.

## Deterministic topology validation

The dedicated Pass244 self-test covers:

- exact Forge/Reforge fixed-point ladders and hard ceilings;
- ordinary Lv1 source-weight draw with no Scholarship entropy;
- Lv7 miss -> ordinary branch;
- Lv7 hit -> 70/30 family -> special concrete item;
- hard special with no gate draw;
- reforge current-item exclusion;
- invalid plan validation consuming zero entropy;
- full 10x Lv7 sequence from Reforge miss counter 98: miss(attempt99) -> hard special(attempt100, no gate draw) -> immediate special after reset -> seven misses, ending durable counter at 7;
- latest proposal generation 1 -> generation 2 replacement;
- persistence roundtrip with frozen old proposal policy version;
- malformed cross-tier proposal repair;
- stale counter-result rejection and UoW rollback;
- public MID1400/1401/1405/1406 fences consuming zero entropy.

## Regression boundary

- Pass243 I2: 8/8 PASS.
- Pass242 I1: 7/7 PASS.
- Pass129 architecture hygiene: 5/5 PASS.
- Pass110 RandomOutcomeService: PASS.
- Pass212 P2 Stage-G: PASS.
- Pass227 Blood MID867/stage3: PASS.
- Pass230 sandbox smoke cleanup: PASS.
- Pass231 forward popup correction: PASS.
- Pass232 event recovery/log rollover: PASS.

The old Pass241 I0 test intentionally asserts that the outer Scholarship policy is disabled. That assertion is superseded by the authorized I3 wave and is no longer a controlling regression; I1/I2/public fences remain controlling.

## Guarded later waves

MID1400 Forge, MID1401 Reforge, MID1405 Save and MID1406 Abandon remain fail-closed. I3 creates no public cost, inventory, proposal-save, or medal-generation behavior. Next is **I4 — MID1400 Forge release**, using the now-tested internal candidate/counter machinery only after complete certificate/Heart cost preflight inside the same UoW.
