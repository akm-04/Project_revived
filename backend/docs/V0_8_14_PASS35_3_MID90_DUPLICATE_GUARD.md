# v0.8.14 / Pass 35.3 — MID90 Duplicate/Insufficient Guard

## Runtime evidence

The clean Pass35.2 device run earned one Skill Point consumable (`50001538 x1`) from Campaign100004. Later the client submitted two MID90 requests in the same second.

- request 1: canonical item existed; backend consumed it and returned `economy_.skill_point = 10`; visible Skill Point synchronization worked.
- request 2: canonical item count was zero; backend performed no mutation and emitted no semantic projection, but v0.8.13 returned an empty dict which the dispatcher wrapped as `error_code=0`.

`SelfPlayer:useSkillPointItem()` removes the client Backpack item only when the callback receives `xyd.error.OK`. Therefore success on a no-op request is unsafe.

## Source contract

`app/common/error.lua` defines:

- `xyd.error.OK = 0`
- `xyd.error.ERROR = 1`

`BuyTiLiWindow.lua` supports both single taps and batching/long-press. It accumulates a positive `item_num` and submits one MID90 request. Nothing in the client imposes the natural Skill Point regeneration maximum as an absolute storage cap.

## Backend change

`HeroProgressionRepository.use_skill_point_item()` now returns `{"error_code": 1}` when:

- item count is non-positive;
- effective item metadata does not define a positive Skill Point grant;
- canonical Backpack quantity is insufficient;
- the consume step cannot complete after pre-validation.

Successful requests retain the Pass35.2 path: consume exact canonical quantity -> add `per_item * item_num` Skill Points -> normalize timer -> one UoW commit -> explicit cumulative `economy_.skill_point` projection.

## Explicit non-changes

- no absolute Skill Point cap was added or changed;
- no Campaign reward changed;
- item `50001538` remains 10 Skill Points;
- no generic Skill Point diff projection was enabled;
- no new error codes were invented; code 1 is the client source's generic ERROR constant;
- Pass29 unknown-MID compatibility boundary is unchanged.
