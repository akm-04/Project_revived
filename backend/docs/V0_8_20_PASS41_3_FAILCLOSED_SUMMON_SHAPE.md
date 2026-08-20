# v0.8.20 / Pass41.3 — Fail-Closed Summon Response-Shape Hotfix

Runtime evidence from 2026-08-19 showed two client Lua errors: `SelfPlayer.lua` line 2273 for a rejected paid MID50 and line 2373 for the unimplemented MID70 compatibility stub. `Backend.lua` treats HTTP status 200 as `xyd.error.OK` independently of the JSON `error_code`, so both wrappers still enter their success branch and call `pairs(response.result)`.

This revision changes only the no-op/fail-closed response shape:

- blocked MID50: `{error_code:1,result:[]}`
- unimplemented MID70: preserves the prior no-op `{error_code:0,awards:[]}` semantics and adds `result:[]` via `SummonHandlers.magic_summon_unimplemented`
- MID71 target-switch compatibility remains unchanged

No paid Vending/Magic operation is activated. No cost, reward, RNG, counter, pity, duplicate-conversion, timer, retry, or receipt behavior is added. The empty `result` is a local compatibility sentinel required by the recovered client consumer; it is not asserted to be the historical server's rejection payload.

The patch prevents the observed `pairs(nil)` exceptions. Because the stock web layer still classifies HTTP 200 as transport success, a client runtime retest is still required to characterize any empty-result-window/UI behavior; this revision does not claim to reconstruct the historical server rejection transport semantics.
