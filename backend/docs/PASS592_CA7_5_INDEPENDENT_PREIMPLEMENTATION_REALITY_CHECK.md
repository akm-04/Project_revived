# Pass591 CA7-5 Independent Preimplementation Reality Check R1

## Verdict

**GREEN — candidate-bound research closure.** The CA7-5 Pet home-style research contract is internally coherent with sealed Pass591 authority, exact accepted v0.83.0 backend architecture, current src_64, historical v1.164 caller evidence, CA7-1/CA7-2 parent appearance policy, D11 replay conventions, I5 ownership, and CA6 Pet Practice version fencing.

This verdict closes **research only**. It does not authorize or claim CA7-5 implementation, PostgreSQL/River aggregate proof, or physical stock-client proof.

## Exact candidate binding

- Pass591 unified PassMap SHA-256: `957ab9ef7e0570d3344bbc605b070a365fa13cdcf945467021e013c43b088b8b`
- Accepted backend SHA-256: `25e9958b956e5be6da45c0c327e457e9dbd096396e7be95cfe19de7d568511a8`
- Git HEAD: `5ba75ec17ba07b585c1fa67ef5b5fb74ef627ef3`
- Product-tree SHA-256: `fa5b89591d1d88f63f7013a0e399bd80a5192a483f488c3a23dfef53f8baf798`
- Current source oracle SHA-256: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`
- Historical v1.164 oracle SHA-256: `d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1`

The backend working tree was independently confirmed clean at the accepted HEAD. MIDs1893/1894/1895 and the proposed CA7-5 replay families are still absent from production code; research did not silently implement the feature.

## Independent checker

A direct checker derived from authority/source/backend invariants completed **41/41 GREEN**. It verified:

- PassMap/backend/Git identities and clean candidate state;
- exact current and old-client source file hashes;
- MIDs1893/1894/1895 identities and current stock caller fields;
- MID1893 local item removal and Backpack acquisition path;
- existing CA7-2 Pet style entitlement and active-style CAS primitives;
- effective stale-selector normalization to 0;
- strict numeric Pet parsing with no string coercion;
- existing Pet 400/404/409 transport families;
- accepted CA7-3/CA7-4 early + post-owner-lock receipt-check pattern;
- CA6 Practice `ActorStateVersion` stale check;
- absence of CA7-5 production routes/replay families;
- migration high-water still `00030_ca7_2_appearance_foundation.sql`;
- parse validity of the frozen R2 source oracle and acceptance matrix.

Checker log: `PASS591_CA7_5_PREIMPLEMENTATION_CHECK_R1.log`.

## Falsification results

### Acquisition versus selection

The grant+auto-activate hypothesis was rejected. Current and v1.164 protocol separates GET (1893) from USE (1894); current/old consumable descriptions describe obtaining/getting the cabin; Backpack can acquire independently of the current selector; parent A15/A16 separates ownership from selection. The least-invented compatible contract is therefore **grant-only, preserve the pre-operation effective active selector**.

This is classified STRONG_INFERENCE rather than original-server SOURCE_FACT because the server's exact returned `active_style` value on first acquisition is not directly captured.

### Stale raw selector

Using only `SavePetStyleEntitlementTx` is insufficient. CA7-2 effective projection maps an unowned/unqualified positive raw selector to effective 0. If a matching entitlement were inserted without rewriting the scalar, formerly stale raw state could suddenly become effective and silently auto-select the style.

Rejecting acquisition is also not a safe repair policy: reload already projects the selector as 0 and stock may expose no CANCEL path for invisible stale state. A narrow Pet-owned composite entitlement+selector persistence seam with **one** Pet CAS is therefore justified. It preserves the pre-operation effective selector and normalizes stale raw state atomically.

### Cancel-before-switch

Direct replacement of one active style with another was rejected. Both current and v1.164 reachable UI expose CANCEL while any style is active rather than another USE action. Accepted `PET_01` already freezes this behavior. MID1894 different-style direct switch must fail closed until MID1895 clears the selector.

### Replay and receipt ordering

Permanent payload deduplication was rejected because stock has no nonce and a fresh identical MID1893 may be a legitimate lost-response retry or current-state convergence.

The final contract retains server operation ID as same-attempt identity and current-state convergence for fresh packets. It also requires:

1. pre-transaction receipt lookup;
2. **early in-transaction** recheck before content-dependent owner discovery;
3. **post-Pet-lock** recheck before branch/effects.

This is consistent with accepted CA7-3/CA7-4 D11 implementation and is especially important for MID1893 because the Pet owner is discovered only after revision-qualified style-item→origin lookup.

### Stale second-client residual

There is an unavoidable stock cache residual. A stale second client may believe an already-owned style is unowned, send a fresh MID1893, receive correct no-debit convergence, and locally remove one item after success. The same wire packet is indistinguishable from a legitimate lost-response retry.

A second server debit would corrupt durable authority; an invented response discriminator would be unsupported protocol. The contract therefore preserves server-side no-double-debit convergence and records this as a bounded client-cache residual.

### Time contract

No duration/reset/expiry mechanic exists here. Introducing `TimedRunner` or gameplay `DecisionAt` would add unsupported semantics. Ordinary retry-stable `operation.Context.StartedAt` is sufficient for actor fencing, owner timestamps and receipt chronology.

### Error mapping

No Pet-home-style server numeric error codes were recovered. Local `HOME_STYLE_NO_PARTNER` / `HOME_STYLE_ALREADYHAVA` strings are prechecks, not server error identities. The contract therefore uses existing V2 Pet HTTP categories and deliberately avoids fabricating numeric stock errors.

## Ownership and transaction reality

Pet remains the sole durable owner. Existing CA7-2 storage already keeps keyed style entitlements plus scalar `active_style`. `SavePetStyleEntitlementTx` and `SavePetActiveStyleTx` each independently advance Pet `state_version`, proving why acquisition+normalization needs one narrow composite owner seam rather than sequential calls.

All consumptive MID1893 effects remain Pet430→I5. MID1894/1895 never acquire Economy ownership. No foreign-owner SQL, new aggregate or schema migration is justified.

## CA6 Practice reality

Pet Practice proposals persist `ActorStateVersion`; SAVE locks Pet and rejects a mismatched current owner version. Consequently every actual CA7-5 Pet appearance mutation must stale a pending proposal, while a semantic no-op must preserve version and proposal validity. This is an explicit future acceptance row, not an inferred side effect left untested.

## Concurrency reality

The frozen matrix is serializable and deterministic:

- same-item acquisition consumes once;
- UNKNOWN-COMMIT recovers receipt without re-debit;
- acquisition while another valid style is active preserves it;
- stale-selector acquisition normalizes in the same one-CAS mutation;
- same-style concurrent selection bumps at most once;
- different-style concurrent selection yields one winner plus one conflict;
- cancel/select ordering follows lock order;
- select-before-acquire rejects unowned while acquire-before-select may enable it;
- cross-Pet acquisition preserves separate Pet locks and Pet-before-I5 ordering.

No competing source-supported mechanic was found.

## Remaining bounded unknowns / deferrals

- original-server numeric Pet-home-style errors remain UNKNOWN;
- W2 physical stock-client proof remains deferred;
- exact accumulated PostgreSQL/River CA7 proof remains mandatory at CA7-7;
- stale second-client local item removal remains a documented stock-cache residual.

None requires inventing gameplay mechanics or blocks a narrowly scoped later implementation.

## Conclusion

No source, accepted-contract or backend-architecture contradiction remains that requires reopening CA7-5 research. `PASS591_CA7_5_PREIMPLEMENTATION_CONTRACT_R2.md`, `PASS591_CA7_5_ACCEPTANCE_MATRIX_R2.json` and `PASS591_CA7_5_SOURCE_ORACLE_R2.json` form one coherent candidate-bound implementation contract.

**Research gate: GREEN. Implementation: NOT STARTED / NOT AUTHORIZED BY THIS RECORD.**
