# Pass70.0 — Economy Backbone Part 3: Response Projection

**Status:** static/offline accepted; runtime client smoke pending.

## Scope

Pass70 is a foundation-only Strangler Fig migration. It changes response projection, not gameplay authority. Campaign, Vows, Workshop, Pet feature implementation, Temporal Resources, Hero/Girls Gear progression, and physical storage migration remain deferred.

## Python changes

1. **Journal-aware `ResponseProjector`**
   - Accepts committed `PlayerUnitOfWork` journal rows as its primary migrated input.
   - Projects `RESOURCE` journal entries tagged `economy_` using canonical post-commit values.
   - Validates journal resource keys against the exact 47-key `ResourceRegistry` projection metadata.
   - Emits only touched keys; no 47-field zero envelope is synthesized.
   - Journal values win on collision with older handler/semantic projection values.
   - The historical five-field diff path (`mana`, `crystal`, `energy`, `exp`, `lev`) remains only as a compatibility fallback.
   - Hero EXP fallback behavior is retained.
   - STACK journal credits are never automatically converted into `awards`.

2. **`ProjectionProfileRegistry`**
   - Added a read-only registry with the exact eight Pass67-frozen profile IDs:
     `WEB_GLOBAL_ENVELOPE`, `CAMPAIGN_RESULT`, `SKY_CITY_COUNTER`, `PET_CAMPAIGN`, `ILLUSION_SOLO`, `ILLUSION_TEAM`, `SHOP`, `RECHARGE_PUSH`.
   - Resolution is MID-first, then protocol label, then `WEB_GLOBAL_ENVELOPE` default.
   - Profiles constrain only fields the generic projector may add; they do **not** strip or rewrite legacy handler bodies.
   - SHOP and PET_CAMPAIGN are marked for client-local inventory reconciliation, so journal STACK credits remain silent.
   - RECHARGE suppresses ordinary web journal projection and preserves nested native/server-event semantics.

3. **Dispatcher integration**
   - `EngineDispatcher` loads `ResourceRegistry` and `ProjectionProfileRegistry` once at composition time.
   - After the handler returns, committed explicit semantic events are applied as the compatibility bridge.
   - The dispatcher then consumes the committed UoW journal and invokes `ResponseProjector`; journal values therefore have final precedence.
   - Rolled-back/staged journal rows remain invisible because `PlayerUnitOfWork.consume_journal()` publishes only post-persistence rows.

4. **Configuration and validation**
   - Added `GXB_RESOURCE_REGISTRY` and `GXB_PROJECTION_PROFILE_REGISTRY` path settings.
   - Added `tools/selftest_pass70_response_projection.py`.
   - Projection-profile load failure uses a conservative compatibility fallback that never synthesizes STACK awards; normal packaged operation uses the frozen JSON registry.

## Deliberately unchanged

- SDK HTTP 5000, Engine HTTP 9000, Chat TCP 9100.
- MID192 HTTP chat-room discovery behavior.
- UID/SID/UNAME/TOKEN and QQW* compatibility semantics.
- 47-key ResourceRegistry classification and 30-key EconomyLedger ownership.
- PlayerUnitOfWork remains one-player-only.
- Physical PlayerState/JSON persistence shape.
- Reward/domain body formats already emitted by handlers.
- No generic `awards` generation from mutation journals.

## Static acceptance

Passed: `compileall`, Pass42.12 validator, Pass42.14 validator, Pass68 foundation self-test, Pass68.1 Medium-free self-test, Pass69 Economy Backbone Part2 self-test, Pass69.1 item-sale self-test, and the new Pass70 response-projection self-test.

Known old standalone characterization scripts with stale sandbox expectations remain outside the required gate exactly as documented in Pass69; Pass70 introduces no new failure there.
