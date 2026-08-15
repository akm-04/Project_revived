# Patch status — 2026-08-16

## Applied

1. `RETRIEVE_TOKEN.token` now uses the same `local_token` value already used by the SDK session cookies (`QQWTOKEN`) and SDK JSON identity. The previous backend used `local_admin_token` only for the engine token.
2. SDK smoke tests now assert all four session cookies are actually present in the HTTP response.

## Important device evidence

The supplied ADB log shows the main process `com.carolgames.gxb` reaching `xydSelectServer` successfully. No later engine HTTP request is visible in the capture. Therefore this backend patch is a consistency fix, not a verified fix for the post-`xydSelectServer` loading stall.

The log also contains a separate fatal exception in `com.carolgames.gxb:EmulatorCheckService`: its native `EmulatorChecker.isEmulator()` method has no implementation. A separate smali patch was prepared to default that check to `false` when the native method is unavailable.

## Still unverified

The exact line after `LoadingScene:selectServer()` that prevents the transition to `MainScene` cannot be proven from the supplied backend and ADB log alone. The Lua source itself is not included in the backend archive, and the ADB capture contains no `LUA ERROR` traceback from the main process.


## Additional boot fix: LOAD_BACKPACK bootstrap (2026-08-16)

The full `app-assets/output` trace shows `LoadingScene.login_()` loads
`MESSAGE_MANAGER` synchronously after `updateMeta_()` and before
`MainScene.new()`. `MessageManager.ctor()` calls
`SelfPlayer:getMyCurrentAvatarID()`. The current player payload sets
`avatar_id` to numeric `0`, which is truthy in Lua; that path calls
`getBackpack():getItemByID(...)`. Without a `LOAD_BACKPACK` bootstrap,
`getBackpack()` is nil and this is a synchronous failure before
`display.replaceScene(MainScene.new())`.

The RETRIEVE_TOKEN detail now supplies MID 81 (`LOAD_BACKPACK`) with an
empty but valid `{sort_type=0,list={},spirit_list={}}` payload.
