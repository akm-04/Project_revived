# Pass212 — P2 Awakening/Blood Stock-Client Smoke Plan

## Purpose
This is the final runtime acceptance gate for P2. The server-side Stage-G release candidate is sealed only after automated verification; **P2 runtime acceptance remains pending until this stock-client smoke is completed and logs are reviewed**.

Capture `server.txt`/backend logs, client Lua errors, screenshots of relevant inventory/equipment/task state before and after each path, and relog results. Do not clear client data between a path and its relog check unless specifically testing a fresh-account bootstrap.

## A. Login / bootstrap baseline
1. Start with an account that has no active Awake/Blood task. Login and open the Awakening task surfaces.
2. Confirm no stale `awake_mission_` / `twice_awake_mission_` appears.
3. Relog once and confirm state is stable.
4. If possible, separately test an account saved with a v1 Awakening-state fixture and confirm active task state survives migration/relog.

**Pass:** no Lua error, HTTP 5xx, restart popup, stale generic mission shadow, or task duplication.

## B. Ordinary Campaign Awakening — full lifecycle
Use one ordinary Campaign-route Girl.
1. Activate stage 1; confirm mission starts incomplete.
2. Acquire fragments through at least one manual Campaign battle (MID113→MID114).
3. Acquire fragments through Campaign sweep (MID117). Repeat the same operation UUID/retry if your proxy/debug tooling supports it; frozen awards must replay rather than reroll.
4. Compose intermediate material and exclusive gear through the normal Backpack/compose UI.
5. Equip the Awakening gear (MID54); confirm stage 1 completes.
6. Claim stage 1 (MID161); confirm stage 2 becomes active.
7. Complete the final Campaign trial. Prefer at least one representative of each objective family across the entire smoke campaign: all-party-survive, required-Girl final kill, solo, required damage.
8. Claim terminal ordinary Awakening (MID161); confirm the Hero transforms.
9. Relog and verify transformed Hero, skills/equipment, and no stale active ordinary task.

**Pass:** no duplicate special fragments, no lost first-clear fragment, no stale task after terminal claim, replay/lost-response does not duplicate settlement.

## C. Ordinary event/no-navigation Awakening
Test two cases if possible.

### C1. Normal event compatibility route
1. Activate one of the 11 ordinary event/no-navigation routes other than Odin.
2. Confirm activation persists exactly one mission-specific intermediate entitlement and normal successful HTTP delivery displays it through `extra_drops_`.
3. Give Up and reopen repeatedly.

**Pass:** no farming; at most one live economic entitlement exists for that mission, and no final gear is granted directly.

### C2. Odin 1258001 restorative edge
1. Activate Odin and verify one fallback intermediate.
2. Give Up; stock client should delete the source-specified full matching stack.
3. Reopen the mission.

**Pass:** server restores exactly one live fallback entitlement when progression has not already consumed/derived it; repeated Give Up/reopen cannot farm extras.

## D. Wish Bottle — MID171
Use an eligible active ordinary stage-one mission whose intermediate is not blacklisted and place at least two Wish Bottles (`50005037`) in Backpack.
1. Use one Wish Bottle through stock UI.
2. Observe Backpack immediately after callback.
3. Use a second bottle as a separate legitimate action.
4. Relog.

**Pass:** each action removes exactly one bottle and grants exactly one eligible intermediate; no duplicate local inventory mutation, no extra generic award application, no HTTP409/restart popup. The second identical request is allowed because MID171 has no nonce. Event-only blacklisted materials must not be resolved through Wish Bottle.

## E. Ordinary Occult Awakening dependency
Use one of the 22 Occult-route ordinary missions in chapters 2/3/4.
1. Activate the mission and open Occult info (MID2362).
2. Verify sweep is unlocked only for the active mission's chapter via positive `max_points`.
3. Spend stamina through normal server-settled gameplay. If controlled fixtures are available: verify 2,999 accumulated stamina gives no Scroll, crossing 3,000 gives one Scroll, and held count caps at two.
4. While holding two Scrolls, spend more stamina and verify progress does not bank farmable overflow.
5. Sweep the active Occult chapter (MID2385).
6. Relog and verify Scroll/progress/fragment state.

**Pass:** one Scroll is consumed and exactly one matching active Awakening fragment is granted per sweep. Manual/co-op Occult is intentionally **not** part of this P2 acceptance test and remains fenced.

## F. Blood Campaign Awakening — full lifecycle
Use a Girl who has completed ordinary Awakening and has a Blood Campaign route.
1. Activate Blood stage 1.
2. Acquire Blood fragments by manual Campaign battle and by sweep.
3. Compose Blood intermediate/gear and equip via MID54.
4. **Immediately inspect Backpack and equipment before any relog.** This is the known Stage-C reconciliation risk: stock local cache may transiently resolve/remove ordinary Awake gear rather than the newly consumed Blood gear.
5. Relog and inspect durable server state again.
6. Claim MID161 into Blood stage 2.
7. Run the Blood ritual/final path: MID866 start, complete all 20 waves, MID867 terminal result, then MID161 terminal Blood claim to stage 3.
8. Relog and confirm `twice_awake_stage=3` representation/state.

**Pass:** server durable inventory/equipment remains correct, terminal ritual has 20 waves and no duplicated completion, and any immediate-cache discrepancy either does not occur or reconciles correctly on relog. If the immediate Blood MID54 cache issue is visible, preserve full client/server logs and screenshots for a surgical reconciliation pass before P2 acceptance.

## G. Blood event/special Awakening
Use one of the seven Blood event/special stage-one routes.
1. Activate it and observe the one-live-intermediate compatibility entitlement.
2. Give Up/reopen repeatedly.
3. Continue through Blood gear, MID54, MID161, ritual, and terminal claim if practical.

**Pass:** entitlement is not farmable and final Blood state persists through relog.

## H. KongMing ordinary terminal / MID2144
1. Complete KongMing's ordinary final Awakening.
2. Verify one of each missing Book-V ownership token is granted and already-owned tokens are not duplicated.
3. Open the stock Awake skill picker. Current stock UI is expected to expose **three** choices (Wind/Dark/Water), even though five skill/book mappings are source-valid server-side.
4. Switch an exposed skill with MID2144.
5. Verify no Book-V token is consumed.
6. Relog and verify raw selected skill persists.

## I. Give-Up anomaly spot checks
Automated Stage G covers all 245 roots; client smoke only needs representative UI checks unless convenient to do more.
- One ordinary no-delete route.
- One Blood no-delete route.
- One anomalous delete-list route; Nikita mission 1125001 is especially useful because source order is `[50001452, 20001291]`.

**Pass:** stock full-stack deletion behavior matches source and server durable state/reopen logic remains coherent.

## J. Promotion regression — MID51 / MID57
With a Hero carrying source-special Awakening/Blood equipment and relevant Fumo:
1. Perform normal promotion/power-up paths that use MID51/MID57.
2. Observe equipment before/after and relog.

**Pass:** special Awakening/Blood slot and special Fumo are preserved under the sealed Stage-C promotion policy; ordinary slots reset according to existing semantics. There must be no `awakening_equipment_promotion_deferred` HTTP409 behavior.

## K. Retry / transport-loss matrix
If a proxy/debug harness can drop responses without dropping requests, prioritize:
- MID113→MID114 manual Campaign settlement: retry must replay frozen outcome, not reroll/regrant.
- MID117 with same operation UUID: frozen receipt/awards must replay.
- MID866/MID867: generation-bound replay must not cross a reactivated mission generation.
- MID161 stage claims/terminal claims: replay must return the stored transition rather than apply twice.
- MID2738/MID2737 open/Give Up: repeated transport replay remains stable.

For MID83, MID171 and MID2385, **do not grade wire-identical repeats as universal exactly-once**: these endpoints have no nonce and a legitimate second user action can be indistinguishable from a retry.

## L. Final acceptance checklist
P2 client smoke is accepted only if:
- no unexpected HTTP409/5xx/restart popup occurs on the tested P2 paths;
- no Lua exception occurs in the relevant callbacks;
- durable inventory/Hero/Awakening state survives relog;
- Campaign special rewards do not reroll or duplicate on replay;
- event entitlements do not farm;
- Wish Bottle does not double-mutate Backpack;
- Occult minimal dependency behaves as specified while full Occult remains fenced;
- Blood ritual/terminal state reaches and preserves stage 3;
- MID51/MID57 no longer produce the obsolete deferred-promotion transport behavior;
- the Blood MID54 immediate cache risk is either absent or fully characterized with logs for a surgical fix.

Return the complete debug/log bundle after the run. If all results are clean, the next pass should record **P2 runtime acceptance/fence closure** and then move the roadmap to Emblem forge/reforge. If a client-only reconciliation issue appears, fix only that bounded issue and rerun the affected smoke path before accepting P2.
