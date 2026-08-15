# GXB private server — protocol notes (consolidated)

**This file replaces the previous three READMEs** (`GXB_PRIVATE_SERVER_BACKEND_README.md`,
`PROTOCOL_NOTES.md`, `README_CORRECTIONS.md`). Everything from all three is
preserved here — current/trusted findings up top, the original detailed
subsystem writeup (battle formats, Arena, March, Treasure, chat/TCP, etc.,
none of which has been touched or re-verified this session) kept as an
appendix at the bottom. **If anything conflicts, trust the top of this file
over the appendix** — the appendix predates the fixes below.

For the session-by-session history of what changed and why, see
`AGENT_HANDOFF.md` in this same directory — that's the one to read first if
you're a new agent (human or AI) picking this project up.

---

## 0. Current status (as of this session, 2026-08-16)

Guest login succeeds, the client makes it through the whole boot chain
(center discovery → version check → SDK login → `RETRIEVE_TOKEN` →
`LOAD_USER_REGIONS` → `LOAD_ANNOUNCE` → `GET_PLAYER_GROUP_BY_KEY` →
`LOAD_PLAYER_INFO`, all confirmed reaching the server and returning HTTP
200 per the supplied logs), and then the client hangs on a loading spinner
forever with no further engine requests.

**Root cause identified and fixed this session** — see §1. Not yet
confirmed against a real device (this fix is untested on hardware as of
writing; that's the immediate next step for whoever picks this up).

## 1. THE bug: `RETRIEVE_TOKEN`'s response needs a `"detail"` field

This is the finding that (probably) explains the stuck loading spinner,
and it was missed by both previous passes.

**`app/model/SelfPlayer.lua`** registers a listener on `xyd.event.TOKEN`:

```lua
-- SelfPlayer.lua:32
arg_2_0:registerEvent(xyd.event.TOKEN, handler(arg_2_0, arg_2_0.loginEvent_))
```

`xyd.event.TOKEN` is dispatched by **`Backend.lua`**'s response handler
(`var_23_2`, the shared success-path function every engine request goes
through) *before* it invokes the caller's own inline callback — see
`Backend.lua` around line 396-450:

```lua
local function var_23_2(arg_25_0, arg_25_1)          -- arg_25_0 = decoded response body
    if arg_25_1 == xyd.error.OK then
        arg_23_0:extraWebResponseCheck_(arg_25_0)
        if var_23_0 ~= nil then                       -- var_23_0 = event name for this mid
            xyd.EventDispatcher.get():dispatchEvent({
                name = var_23_0,                       -- xyd.event.TOKEN for RETRIEVE_TOKEN
                params = arg_25_0,
                userdata = arg_23_4
            })
        end
    end
    ...
    if arg_23_3 ~= nil then
        arg_23_3(arg_25_1, arg_25_0, arg_23_4)          -- THEN the caller's own callback runs
        ...
```

The caller's own callback — in **`app/scenes/LoadingScene.lua:login_`**, the
actual `xyd.Backend.get():request(xyd.mid.RETRIEVE_TOKEN, ...)` call site —
is what eventually does `display.replaceScene(xyd.MainScene.new())`. That
only runs *after* the event dispatch above returns.

`SelfPlayer.lua`'s `loginEvent_` (the TOKEN listener) immediately calls
`loadGameStartInfoEvent_`:

```lua
-- SelfPlayer.lua:3684
function var_0_0.loginEvent_(arg_215_0, arg_215_1)
    arg_215_0.uid = arg_215_1.params.uid
    arg_215_0:loadGameStartInfoEvent_(arg_215_1)
end

-- SelfPlayer.lua:3874
function var_0_0.loadGameStartInfoEvent_(arg_221_0, arg_221_1)
    local var_221_0 = arg_221_1.params.detail        -- <-- reads response.detail
    local var_221_1 = {}
    for iter_221_0, iter_221_1 in pairs(var_221_0) do -- <-- pairs(nil) if detail is missing
        table.insert(var_221_1, tonumber(iter_221_0))
    end
    ...
```

If the `RETRIEVE_TOKEN` response has no `"detail"` field, `arg_221_1.params.detail`
is `nil`, and `pairs(nil)` throws immediately. Nothing in the surrounding
code (`Backend.lua`'s `var_23_2`, `xyd.EventDispatcher:dispatchEvent`) is
visibly wrapped in `pcall` in the decompiled source, so this error almost
certainly propagates up and aborts `var_23_2` — meaning the *rest* of that
function, including the `arg_23_3(...)` call that eventually reaches
`display.replaceScene(xyd.MainScene.new())`, never runs. No crash dialog,
no further requests, no visible error in a generic logcat grep — just a
spinner that spins forever. This matches the observed symptom exactly.

### The fix

`RETRIEVE_TOKEN`'s response must always include `"detail"` as at least an
**empty dict**. `loadGameStartInfoEvent_` treats every individual key as
optional (`if var_221_0[tostring(mid)] and not ... then`, a safe no-op if
absent) — only the *container itself* being absent is fatal.

`detail` is a dict keyed by **stringified MID**, batching together the
post-login bootstrap payloads. Full list of ~30 MIDs it looks for, with
line numbers, in `app/model/SelfPlayer.lua:loadGameStartInfoEvent_`
(roughly lines 3874-4224): `LOAD_PLAYER_INFO` (17), `PETS_GET` (780),
`LOAD_HEROS` (49), `LOAD_BACKPACK` (81), `LOAD_WORLD_MAP` (112),
`LOAD_TRIAL_INFOS` (115), `AWAKE_MISSION_LIST` (2561), `ACTIVITIES` (229),
`LOAD_ARENA_FIGHT_RECORDS` (289), `LOAD_MARCH` (336), `LOAD_SIGN_INFO`
(352), `LOAD_INVITE_INFOS` (384), `PEAK_RECORDS` (2485),
`REGION_GET_ARENA_INFO` (1408), `LOAD_MAIL_LIST` (368), `LOAD_SUMMON_INFO`
(56), `WORLD_BOSS` (624), `GET_SELF_GUILD` (612), `PET_CAMPAIGN_RED_POINT`
(822), `TREASURE_LOAD_INFO` (530), `GET_BUILDING_LIST` (1056),
`GUILD_WAR_RED_POINT` (1152), `GET_TEA_TALK_INFO` (1808),
`GET_OFFLINE_INFO` (1304), `GET_CLASS_INFO` (1856), `GET_LIBRARY_INFOS`
(836), `GET_STUDY_INFOS` (2137), `GET_GIFT_BOX_INFO` (2139),
`GET_ADVENTURE_LIST` (2416), `GET_HERO_RECOMMEND_SCORES` (2501),
`RED_POINT` (2560), `BATTLE_PASS_GET_INFO` (2984),
`HUNQI_START_GAME_GET_INFO` (3101).

**What's implemented now** (`game_logic.py:handle_retrieve_token`):
- `detail` is always present.
- `detail["17"]` (`LOAD_PLAYER_INFO`) is pre-populated, reusing
  `handle_load_player_info()` verbatim — same shape, already modeled and
  tested (see §3.3 below / the original PROTOCOL_NOTES content).
- Everything else in the ~30-entry list is **deliberately left out** —
  absent is the verified-safe default. Guessing the other ~29 payload
  shapes blind risks trading this crash for a *different* one inside
  `herosEvent_` / `onBackpackEvent_` / `worldMapLoginEvent_` / etc., none
  of which have been read yet this session.
- Also added: `"uid"` at the response root (`loginEvent_` does
  `arg_215_0.uid = arg_215_1.params.uid` — harmless if absent, but cheap
  to include correctly).

### What to check next (in order)

1. **Confirm the fix on real hardware.** Capture logcat through the full
   boot sequence this time (don't stop at the payment-init warning — that
   part is a red herring, see §7 Addendum 2 below). Watch specifically for
   whether `MainScene` actually renders, or whether it still hangs (which
   would mean this theory is wrong or incomplete, and the *actual*
   assertion is that `xyd.EventDispatcher` *does* pcall listeners somewhere
   not yet found — in which case, go find `EventDispatcher.lua` and read
   `dispatchEvent` directly rather than trusting this document).
2. If it gets past the spinner: expect a mostly-empty `MainScene` (no
   heroes, no backpack, no world map — those 29 keys were left out of
   `detail` on purpose, see above). Check whether the client falls back to
   individual `Backend:request()` calls for the missing pieces on its own,
   or whether `MainScene`'s own init code needs them synchronously and
   nil-indexes. Either outcome is useful signal for what to implement next
   — log it in `AGENT_HANDOFF.md`.
3. Use `tools/MID_CATALOG.md` (§6 below) to look up each MID as it comes
   up, rather than guessing.

---

## 2. Three request surfaces, not one

| Surface | Who | Talks to | Body | Response envelope |
|---|---|---|---|---|
| SDK (Java) | `com.xyd.platform.android.*` | URL in `Constant.smali` (patched → your box, port 5000) | plain JSON | `{status, code, error_code, msg, data:{...}, package_info}` |
| Center discovery | `UpdateScene.lua` (`requestServerUrl_`) | hardcoded `.../center/v1`, port 9000 | form field `payload` = JSON | **flat** JSON, no wrapper |
| Engine/game API | `Backend.lua` (`webRequest_`), used for every in-game MID | `xyd.serverUrl` (set from the center response's `url` field) or the `misc.lua` default | form field `payload` = JSON (single- or double-urlencoded — see below) or zlib+multipart for a few battle-result MIDs | **flat** JSON, no wrapper |

The SDK layer and the engine layer are two different Lua/Java stacks that
happen to both call themselves "the backend" — that caused real confusion
in earlier passes between the `data`-wrapped response (SDK layer) and
everything else (flat).

There's also a genuine raw-TCP layer (`xyd.TCPSocket`, `Backend.lua`'s
`tcpRequest_`/`onSocketMessage_`), used only for **chat rooms** (guild
chat, world chat, GM/service chat), connected to lazily via
`LOAD_CHAT_ROOM_INFO` (host/port supplied by that HTTP response). Not
needed to get the game booted and playable — see the appendix (§27 in the
original numbering) for what's known about it.

### The redirect trick this server relies on

`UpdateScene.lua` sends MID **20480** to whatever center URL it started
with, then does `xyd.serverUrl = response.url` and uses that URL for
*every later request*, including MID **2** (version check) and all of
`Backend.lua`'s traffic. So the client only needs to reach this server
**once**, for MID 20480 — the response's `"url"` field takes over from
there. That's `SELF_URL` in `server.py`.

To land that first MID 20480 request at all, the client needs to resolve
`xuemeien.carolgames.com` (hosts-file override) **and/or** reach
`119.81.215.217:9000` (the hardcoded IP fallback used if the hostname
request fails — hosts-file entries don't help here; needs an
iptables/nft `DNAT` rule redirecting that IP to the local server). Also
worth pointing `misc.lua`'s `203.74.199.17:9000` fallback at yourself the
same way, though it should never get used once MID 20480 succeeds.

## 3. Response contract

### 3.1 Engine layer is flat JSON, not `{"data": {...}}`

Confirmed directly from `Backend.lua`'s response dispatch
(`var_23_2(json.decode(response_body), xyd.error.OK)` hands the callback
the decoded body **directly**, no unwrapping) and cross-checked against
consumers: `app/model/SelfPlayer.lua:onPlayerInfo_` reads
`event.params.<field>` where `params` is the raw decoded body, and
`LoginWindow.lua` reads `response.regions` / `response.players` /
`response.contents` directly off the root. This envelope is real, but only
for the **SDK/Java layer** — applying it to the engine layer means every
field the Lua side reads comes back nil, and specifically breaks MID
20480's redirect (`xyd.serverUrl = response.url` reads nil, client falls
back to a dead hardcoded host and escapes the whole scheme).

Every engine response should include `error_code: 0` (`xyd.error.OK == 0`,
confirmed in `app/common/error.lua`). Some optional top-level fields
`Backend.lua` checks for and acts on if present — don't include them
unless you mean to trigger the behavior:
- `v_` → client thinks it's out of date and forces a restart prompt. Never set this.
- `economy_`, `flag_`, `redmarks_`, `new_funcs_`, `act_item_change_`, `extra_drops_`, `twice_awake_stage_` → various UI/model side-effects, all optional.
- `gm_url` → updates the GM-chat URL.
- `server_time` → resyncs the client clock.

### 3.2 Payload encoding is genuinely inconsistent in the client

- `UpdateScene.lua webRequest_`: `addFormContents`/`addPOSTValue("payload", json.encode(t))` — **no** manual urlencode.
- `Backend.lua webRequest_` (default, non-form-data path): `addPOSTValue("payload", string.urlencode(json.encode(t)))` — manual urlencode **before** handing to a POST-value setter that may itself urlencode form values.

Whether that's single- or double-encoded on the wire depends on what
cocos2d-x's `addPOSTValue` does internally. Rather than resolve that ahead
of time, `server.py`'s `decode_payload()` tries, in order: plain JSON →
single-urldecode-then-JSON → double-urldecode-then-JSON → zlib-inflate →
zlib-inflate-after-urldecode, and logs which one worked via the printed
`[CENTER]`/`[API] source=... decode=...` lines.

A handful of MIDs (`ARENA_FIGHT_RESULT`, `PEAK_START_FIGHT`,
`TREASURE_SAVE_BATTLE_RESULT`, `REARENA_END_FIGHT`, `REGION_FIGHT_RESULT`,
`CONQUER_SCHOOL_FIGHT_RESULT`, `SAVE_FURNITURES` — see `FORM_DATA_MIDS` in
`server.py`) are sent zlib-deflated as real multipart file parts instead
of a `payload` form value. Already handled.

### 3.3 Specific confirmed contracts

- **MID 20480 (center discovery)**: request has `area`, `mid`, `app_v`,
  `platform`, `type`. Response: flat `{url, server_id, back_domain,
  res_download_url}`. `url` becomes `xyd.serverUrl`.
- **MID 2 (version check)**: request has `v`, `mid`, `app_v`, `platform`,
  `clean`, `full`. `checkUpdate_`'s callback reads `is_appstore`,
  `is_inapp`, `need_restart`, `is_review` — flat, off the root. (An
  earlier draft used `is_update`/`force_update`/`has_new`/`maintenance`
  under `data` — wrong field names *and* wrong envelope.)
- **MID 1 (`RETRIEVE_TOKEN`)**: see §1 above for the full contract,
  including the `detail` requirement discovered this session.
  `LoadingScene.lua:login_`'s inline callback also reads `is_new`,
  `story_type`, `is_debug`, `is_old_top` off the root.
- **MID 18 (`LOAD_USER_REGIONS`)**: response `{regions: [...], players:
  {}}`. `LoginWindow.lua` sorts the region list and indexes into it —
  the decompiler doesn't reproduce this control flow reliably (noted in
  the original recovery session too, re: `Backend.lua`/
  `ErrorLogPoster.lua`), so neither "index 4" nor "index 7" claimed by
  earlier passes should be trusted precisely. Current server returns 10
  regions (defensive, not exact) rather than gambling on one exact index.
  Empty `players` is intentional — `LoginWindow` then dispatches
  `xyd.event.LOGIN` immediately instead of opening an account/region
  picker.
- **MID 7 (`LOAD_ANNOUNCE`)**: `LoginWindow.lua:requestAnnounce_` does
  `json.decode(response.contents)` — `contents` must be a **JSON-encoded
  string** (`json.dumps({})`, i.e. the literal string `"{}"`), not a raw
  object.
- **MID 3 (`QUERY_SERVER_TIME`)**: `{server_time: <unix ts>}`.
- **MID 17 (`LOAD_PLAYER_INFO`)**: flat player fields at root — see
  `game_logic.py:handle_load_player_info` for the current full field set,
  derived from what `SelfPlayer.lua` UI-model code reads.
- **MID 2864 (`GET_PLAYER_GROUP_BY_KEY`)**: `SelfPlayer:getAbtestGroupByKey()`
  assigns the **raw response body itself** as the AB-test group value —
  this must be a bare JSON scalar (`"A"`), not an object, and not wrapped
  in `error_code` at all (`server.py` special-cases this mid to skip the
  usual `engine_ok()` wrapper).
- **`ACTIVITY_1124_AWARD` / `ACTIVITY_1149_AWARD` / `ACTIVITY_1231_AWARD`**:
  `3105` / `3106` / `3109`.

## 4. SDK (Java) layer — separate MID namespace, separate bugs

The Java `Xinyd`/`xydSDK` layer has its **own internal MID catalog**,
completely separate from `xyd.mid`/`mid.lua` — the numbers observed
(65305, 65319, 65284, 65281, 65304) aren't in `mid.lua` at all, and this
layer's smali/dex source isn't in the available assets, only what logcat
reveals empirically.

Known SDK-layer mids, from live traffic:

| mid | when it fires | notes |
|---|---|---|
| 65305 | app boot | device init/register |
| 65319 | shortly after 65305 | log-upload registration; empty `data` is fine |
| 65284 | tapping Guest Login | `payload.tp_code == "anonymous"` |
| 65281 | tapping Login with email/password | `payload.login_email` / `payload.password` |
| 65304 | during guest-login handshake | seen retried (`try_times: first_try` then `last_try`) — appears to be a normal idempotent session-refresh retry, not itself an error |
| `query_pay_method_amounts` (string, not numeric) | after login, payment SDK init | see below — non-fatal |

**Both 65284 and 65281 hard-throw client-side if `uid` is missing from the
response.** Confirmed from two different exception shapes:
- 65284: `com.xyd.platform.android.exception.XinydLoginException: No value for uid` (wrapped, doesn't say where it read from).
- 65281: bare `org.json.JSONException: No value for uid` at
  `org.json.JSONObject.getString(JSONObject.java:559)` inside
  `LoginManager$5.run` — **unambiguous**: `LoginManager` calls
  `.getString("uid")` directly on the response object, so `uid` (and by
  extension the rest of the identity fields) must sit at the **top
  level**, sibling to `status`/`code`/`data`/`error_code`/`msg` — not only
  inside `data`. (An earlier fix put `uid` only inside `data` and it kept
  failing.)

Current `server.py` sends every identity field (`uid`/`sid`/`access_token`/
`token`/`username`/`nickname`/`is_new`) in **both** places — root and
`data` — plus uppercase aliases (`UID`/`SID`/`UNAME`/`TOKEN`), since
different call sites may read from either and the exact per-mid Java
contract isn't fully known without the smali.

### The payment-init warning is very likely a red herring

Right after login, logcat shows:

```
xydSDK: query_pay_method_amounts: {"code":1,"data":{"amounts":[...],"methods":[{"id":1,"name":"google",...}]},...}
xydSDK: 支付系统初始化失败，请重启游戏     ("Payment system init failed, please restart the game")
```

This is a Toast, not a fatal crash — most SDKs of this vintage just
disable the shop/IAP UI and continue. **Do not stop a logcat capture right
after this line** (an earlier capture this session did exactly that, and
it's unclear whether the run was actually stuck there or just under-
captured) — keep it running through to either `MainScene` rendering or a
clearly repeated failure loop.

## 5. What's implemented in `server.py` / `game_logic.py` right now

Boot-critical path, enough to reach the main menu without a nil-index
crash on the Lua side, **as currently understood**:

1. SDK login (mid 65305, 65284, 65281, 65304, 65319 — port 5000)
2. Payment query stub (`query_pay_method_amounts`) — empty methods/amounts,
   safe non-crashing response (see §4 — the actual init failure appears to
   be non-fatal regardless of what's returned here)
3. Center discovery (mid 20480) → hands back `SELF_URL`
4. Version check (mid 2) → reports no update needed
5. `RETRIEVE_TOKEN` (mid 1) → **now includes `detail` (§1 fix) and `uid`**
6. `LOAD_USER_REGIONS` (mid 18) → 10 regions, empty `players` map
7. `LOAD_ANNOUNCE` (mid 7) → empty contents, no popup
8. `QUERY_SERVER_TIME` (mid 3)
9. `LOAD_PLAYER_INFO` (mid 17) → flat fields, also pre-populated into
   `RETRIEVE_TOKEN`'s `detail["17"]`
10. `GET_PLAYER_GROUP_BY_KEY` (mid 2864) → bare scalar `"A"`
11. `ACTIVITY_1124_AWARD` / `1149` / `1231`

Everything else — **1,210 catalogued MIDs total**, see `mids.py` and
`tools/MID_CATALOG.md` — falls through to a generic `{"error_code": 0}`
stub. That's enough for most of them not to hang the client, but none of
them carry real state; the client will render empty lists / zeroed-out
screens for anything past the main menu, *if* it gets there at all (still
unconfirmed as of this session — see §1).

## 6. `tools/` — for figuring out what to implement next

- **`tools/audit_api.py`** — AST-based static analyzer (uses the
  `luaparser` PyPI package) that walks the whole decompiled Lua tree and
  finds every `Backend:request(mid, params, callback)` call site,
  resolving the MID name/number and extracting (best-effort) the request
  field names and the response field names the callback reads directly.
  Run it against a merged source tree (base APK + hot-updated files
  overlaid — see `AGENT_HANDOFF.md` for how that tree was built) if the
  client gets updated and this needs regenerating:
  ```
  python3 tools/audit_api.py /path/to/merged_lua_src tools/api_audit.json
  ```
  Skips `data/tables/*` (static config, some files 30MB+, zero
  `request()` calls, and parsing them is what caused the first attempt at
  this to blow past a time limit) and anything not containing the literal
  substring `:request(`.
- **`tools/api_audit.json`** — the output of the above: 1,345 call sites,
  1,125 unique MID expressions, ~96% resolved to numeric MIDs (the
  remainder are either MID names not present in this build's `mid.lua`
  — likely later-version features like Pet/Dungeon/MagicShop systems —
  or MIDs held in a local variable requiring dataflow tracing to resolve,
  not done here).
- **`tools/MID_CATALOG.md`** — human-readable version of the above,
  grouped by MID, generated for quick lookup: "I see `no handler for
  mid=1234` in the server log — what does the client send/expect for
  1234, and which file/line calls it?" This is a **lower bound** —
  static analysis only, not execution; fields read via computed/bracket
  keys or copied into other tables before use won't show up.

## 7. Addendum: corrections to earlier drafts (kept for audit trail)

Two earlier passes got progressively closer; both had real, confirmed
mistakes, corrected in the version described above. Read directly from
source rather than taking either version's word for it:

- **Engine-layer response envelope** — an early draft wrapped every
  engine-layer response in `{"status":1,"code":1,"error_code":0,
  "data":{...}}`, with a comment claiming this was "confirmed" against
  the Lua source. It wasn't — see §3.1. That envelope is real, but only
  for the SDK/Java layer.
- **MID 20480 response shape** — same root cause. That draft nested a
  `server_list` array with per-entry `url`/`host`/`port` under `data`.
  Actual client code reads `url`/`server_id`/`back_domain`/
  `res_download_url` flat off the body.
- **MID 2 (version check)** — same root cause, different field names too
  (`is_update`/`force_update`/`has_new`/`maintenance` vs. the real
  `is_appstore`/`is_inapp`/`need_restart`/`is_review`).
- **`LOAD_USER_REGIONS` needing more than one region** — worth keeping as
  a design note even though the exact index (`[4]` vs `[7]`) isn't
  trustworthy from decompiled control flow alone.
- **`ACTIVITY_1124_AWARD` / `1149` / `1231`** — an early draft left these
  as unresolved (`None`) citing a missing `mid.lua` in that pass's asset
  bundle. Resolved (values above) once the full asset archive was
  available.
- **`LOAD_ANNOUNCE` `contents` as a JSON string** — confirmed correct in
  every pass, unchanged.

The SDK-layer identity-field findings in §4 (uid at root, not just
`data`; the 65281 vs 65284 exception-shape distinction) were found via a
live-device logcat capture partway through this corrections process — see
`AGENT_HANDOFF.md` for the session where that happened.

---

## 8. Appendix: detailed subsystem protocol reference (original reconstruction pass)

*The following ~1,700 lines are preserved from the original
`GXB_PRIVATE_SERVER_BACKEND_README.md`, produced by a first-pass full
read of the client source (network layer, MID catalog, player models,
login flow, battle/report code, Arena/Peak/Region Arena/March/Treasure
flows). It has **not been re-verified** in this session — none of it
touches the current boot-sequence bug. Sections 1-9 covering
boot/envelope/SDK-vs-engine are superseded by §§0-5 above where they
conflict (they mostly don't — this was a solid piece of work, just
incomplete on the `detail` field, which nothing in either prior pass
caught). Battle-system sections (Arena, March, Treasure, Conquer School,
chat/TCP, error handling, architecture recommendations) are novel content
not covered elsewhere in this document and are the best current reference
for that work once the client actually reaches `MainScene`.*

*The original's own "Complete MID catalog" section has been dropped here
— superseded by `tools/MID_CATALOG.md`, which is generated from actual
call-site analysis (request fields + response fields the callback reads)
rather than a name/number listing alone.*

# GXB Private Server — Backend Reconstruction & Protocol Documentation

> **Purpose:** reconstruct the game's backend from the supplied client asset archive, document what the Lua/Java client actually sends and consumes, and provide a ground-up implementation blueprint for a compatible private server.
>
> **Source of truth:** the attached `all-assest-rechecked.zip` archive plus the supplied `PROTOCOL_NOTES.md`. This document deliberately distinguishes **confirmed client behavior** from **inference/unknowns**. It does not invent server behavior where the client does not reveal it.

---

## 1. Executive summary

The client is **not** a single-protocol application.

There are three important request surfaces:

| Surface | Entry point | Destination | Encoding | Response |
|---|---|---|---|---|
| SDK / Java | `com.xyd.platform.android.*` | URL from SDK constants | plain JSON body | SDK envelope such as `{status, code, error_code, msg, data, package_info}`; observed login mids may also require identity fields at the JSON root |
| Center discovery | `UpdateScene.lua:webRequest_` | `.../center/v1` | POST form field `payload` containing JSON | flat JSON |
| Engine/game | `Backend.lua:webRequest_` | `xyd.serverUrl` or `misc.web_api_url` | normal POST `payload`, zlib multipart for selected MIDs, file multipart for MID 1844 | flat JSON |
| GM | `Backend.lua:GMRequest_` | `GMURL_` | URL-encoded JSON in POST `payload` | flat JSON |
| Chat | `Backend.lua:tcpRequest_` | host/port returned by `LOAD_CHAT_ROOM_INFO` | raw TCP | chat-specific protocol; separate from HTTP |


The most important architectural fact is the **center redirect**:

1. `UpdateScene.lua` sends **MID 20480** to the center URL.
2. The response is expected to be a **flat JSON object**.
3. The client reads `response.url` and assigns it to `xyd.serverUrl`.
4. `Backend.lua` subsequently sends normal game traffic to that URL.
5. Therefore a private server can bootstrap the client by making the first center request return its own API base URL.

The supplied protocol notes also confirm that the `:9000` endpoint is HTTP, not a separate raw TCP game protocol. The genuine raw-TCP subsystem is primarily chat.

---

## 2. Asset inventory

The archive contains:

- **8,995 total archive entries**
- **8,864 Lua files**
- **4,370 Lua files under `src_32`**
- **4,370 Lua files under `src_64`**
- **4,370 unique canonical 32-bit Lua paths**
- **1,210 unique `xyd.mid` definitions** in the canonical `mid.lua` examined
- **1,058 distinct MID names with a direct `Backend.get():request(...)` callsite in `src_32`**

The 32-bit and 64-bit trees are parallel client builds. For protocol documentation, the 32-bit tree is used as the canonical source and the 64-bit tree should be treated as a parity check unless a platform-specific difference is found.

### Directory roles

| Directory | Files in `src_32` | Role |
|---|---:|---|
| `app/common` | 697 | network, tables, utilities, shared services, constants, event system |
| `app/model` | 118 | persistent/client-side domain state and API orchestration |
| `app/windows` | 1,410 | UI controllers; many direct API callsites |
| `app/scenes` | 16 | scene lifecycle and battle/result processing |
| `app/modules` | 13 | modular feature/game systems |
| `app/utils` | 0 | helper code |
| other/root | 2,116 | bootstrap/config/generated/decompiler support code |

---

# 3. Startup and server discovery

## 3.1 Hardcoded bootstrap URLs

`UpdateScene.lua` contains:

- Center IP: `http://119.81.215.217:9000/center/v1`
- API IP fallback: `http://119.81.215.217:9000/api/v1`
- Hostname center: `http://xuemeien.carolgames.com:9000/center/v1`

`data/tables/misc.lua` also contains:

- `web_api_url = http://203.74.199.17:9000/api/v1`

The normal Android/non-Apple flow starts from the center hostname; the client has an IP fallback.

## 3.2 MID 20480 — center discovery

`UpdateScene.lua:requestServerUrl_()` creates:

```json
{
  "mid": 20480,
  "area": "tw",
  "type": "<packageInfos.mode>",
  "app_v": "<client version>",
  "platform": <cocos platform integer>
}
```

The request is sent using the update scene's HTTP helper.

The response is decoded directly and consumed as:

```text
response.url
response.server_id
response.back_domain
response.res_download_url
```

Then:

```text
xyd.serverUrl      = response.url
xyd.serverID       = response.server_id
xyd.back_domain    = response.back_domain
xyd.resDownloadUrl = response.res_download_url
```

### Minimal compatible 20480 response

```json
{
  "url": "http://YOUR-SERVER:9000/api/v1",
  "server_id": 1,
  "back_domain": "",
  "res_download_url": ""
}
```

**Important:** this response is **not** wrapped in `data`.

A response like:

```json
{"data":{"url":"..."}}
```

will not work because the Lua client reads `response.url` directly.

---

# 4. Version check — MID 2

After successful center discovery, `UpdateScene:checkUpdate_()` sends MID 2 to `xyd.serverUrl`.

Request:

```json
{
  "mid": 2,
  "platform": <platform>,
  "app_v": "<application version>",
  "v": "<resource version>",
  "clean": <boolean>,
  "full": <boolean>
}
```

The callback reads these **top-level** fields:

- `is_appstore`
- `is_inapp`
- `need_restart`
- `is_review`

For a private server whose goal is to keep the current client running, the safe baseline is generally:

```json
{
  "is_appstore": 0,
  "is_inapp": 0,
  "need_restart": 0,
  "is_review": 0
}
```

The exact update/download behavior is controlled by additional version/update structures in `UpdateScene.lua`; this document does not claim a complete resource-update server contract where the client does not expose one.

---

# 5. Engine HTTP transport — `Backend.lua`

## 5.1 Request entry point

The public dispatcher is conceptually:

```text
Backend:request(mid, params, callback, userdata, skipRetryPromptOnFailure, showLoading)
```

Routing:

```text
isChatRoomMessage(mid) -> tcpRequest_
isGMOperation(mid)     -> GMRequest_
otherwise              -> webRequest_
```

Therefore a private server should not treat every MID as HTTP without checking these predicates.

## 5.2 Common fields automatically added

Before serializing the engine request, `Backend.lua` mutates the parameter table with:

```json
{
  "mid": <numeric MID>,
  "token": "<current token>",
  "region": <current region>,
  "v_": "<numeric/internal client version>",
  "app_v": "<application version>",
  "platform": <Cocos platform integer>
}
```

`region` is filled from the request if supplied; otherwise `Backend.region_` is used.

`token` is taken from `Backend.token_`.

## 5.3 Normal engine request

For ordinary MIDs:

1. `json.encode(params)`
2. `string.urlencode(json)`
3. `addPOSTValue("payload", encoded_json)`
4. HTTP `POST`
5. response body must be JSON
6. status code `200` is treated as success
7. decoded JSON object is passed directly to the callback

So the conceptual request is:

```http
POST /api/v1
Content-Type: application/x-www-form-urlencoded

payload=<urlencoded-json>
```

### Important encoding ambiguity

The Lua code explicitly URL-encodes the JSON before passing it to `addPOSTValue`.

Whether Cocos additionally URL-encodes the value on the wire depends on the implementation of `addPOSTValue`.

The supplied protocol notes therefore recommend accepting:

1. plain JSON,
2. one URL decode then JSON,
3. zlib inflate then JSON,

until a real engine-layer packet capture establishes the exact wire representation.

---

# 6. Compressed multipart battle requests

`Backend:sendAsFormData_()` returns true for these MIDs:

- `ARENA_FIGHT_RESULT`
- `PEAK_START_FIGHT`
- `TREASURE_SAVE_BATTLE_RESULT`
- `REARENA_END_FIGHT`
- `REGION_FIGHT_RESULT`
- `CONQUER_SCHOOL_FIGHT_RESULT`
- `SAVE_FURNITURES`

For these:

1. JSON is generated.
2. JSON is zlib-deflated.
3. The compressed bytes are attached as a multipart form field named `payload`.

This is **not** the same as the ordinary URL-encoded `payload` request.

A compatible server should detect `multipart/form-data`, extract the `payload` part, zlib-inflate it, then JSON-decode it.

---

# 7. File-upload API

`Backend:isUpload()` currently identifies numeric MID **1844** as a file-upload operation.

The client expects these parameters:

- `form_name`
- `file_path`
- `file_name`

It verifies that `file_path` exists locally, attaches it with `addFormFile`, adds form contents, and explicitly sends:

- `mid`
- `token`
- `region`
- `v_`

A private implementation should preserve the multipart behavior for this MID rather than trying to parse it as a normal `payload` field.

---

# 8. Response contract

## 8.1 Engine layer is flat JSON

The Lua engine does:

```text
json.decode(response_body)
```

and passes that decoded object directly to callbacks/events.

Therefore:

```json
{
  "error_code": 0,
  "token": "...",
  "regions": { },
  "contents": "{}"
}
```

is structurally correct.

This is **not**:

```json
{
  "status": 1,
  "code": 1,
  "data": {
    "error_code": 0
  }
}
```

for engine traffic.

## 8.2 Generic success

`xyd.error.OK == 0`.

A safe baseline response is:

```json
{
  "error_code": 0
}
```

but that only works for operations whose consumers do not read additional fields.

## 8.3 Optional top-level side effects

`Backend.lua:extraWebResponseCheck_()` recognizes optional response fields including:

- `v_` — can make the client consider itself out of date / require restart
- `economy_`
- `flag_`
- `redmarks_`
- `new_funcs_`
- `act_item_change_`
- `extra_drops_`
- `twice_awake_stage_`
- `gm_url`
- `server_time`

Do not emit these casually. They are behavior triggers, not harmless metadata.

---

# 9. Boot-critical engine MIDs

The supplied reconstruction identifies this practical startup sequence:

| Order | MID | Name | Purpose |
|---:|---:|---|---|
| 1 | 20480 | center discovery | choose game API URL |
| 2 | 2 | version check | update/restart decision |
| 3 | 1 | `RETRIEVE_TOKEN` | obtain game token/region |
| 4 | 18 | `LOAD_USER_REGIONS` | load account regions/characters |
| 5 | 7 | `LOAD_ANNOUNCE` | announcement data |
| 6 | 3 | `QUERY_SERVER_TIME` | synchronize clock |
| 7 | 17 | `LOAD_PLAYER_INFO` | populate player model |

The supplied private-server implementation notes report that this path is enough to reach the main menu when the response shapes are correct.

---

# 10. Authentication / SDK layer

The Java SDK has a **separate MID namespace** from `app/common/network/mid.lua`.

Known SDK-layer observations from live traffic in the supplied notes:

| SDK MID | Observed operation | Evidence |
|---:|---|---|
| 65305 | device init/register | observed at app boot |
| 65319 | log-upload registration | observed shortly after 65305 |
| 65284 | guest login | `payload.tp_code == "anonymous"` |
| 65281 | email/password login | `payload.login_email`, `payload.password` |

The SDK response envelope observed is:

```json
{
  "status": 1,
  "code": 1,
  "error_code": 0,
  "msg": "ok",
  "data": { },
  "package_info": { }
}
```

### Critical login detail

The supplied live-log analysis established that login code reads `uid` from the **root JSON object** for at least MID 65281.

Therefore the compatibility response should expose identity fields at the root, and the merged implementation described in the notes also mirrors them inside `data` for compatibility:

```json
{
  "status": 1,
  "code": 1,
  "error_code": 0,
  "msg": "ok",
  "uid": "1000001",
  "sid": "1",
  "access_token": "...",
  "token": "...",
  "username": "...",
  "nickname": "...",
  "is_new": 0,
  "data": {
    "uid": "1000001",
    "sid": "1",
    "access_token": "...",
    "token": "...",
    "username": "...",
    "nickname": "...",
    "is_new": 0
  }
}
```

The exact SDK contract for every SDK MID is **not fully recoverable from the supplied Lua assets**, because the relevant Java/dex implementation was not present in the available source bundle. Treat unobserved SDK behavior as an open reverse-engineering task.

---

# 11. `RETRIEVE_TOKEN` — MID 1

`Backend.lua` has special handling for this operation.

On success it stores:

```text
response.token    -> Backend.token_
response.region   -> Backend.region_
response.log_url  -> Backend.logURL_
```

The response is then delivered normally.

Minimum useful response:

```json
{
  "error_code": 0,
  "token": "PLAYER_TOKEN",
  "region": 1,
  "log_url": ""
}
```

The token becomes the automatically-added `token` field on later engine requests.

---

# 12. `LOAD_USER_REGIONS` — MID 18

This is consumed by the login/region UI.

The important response structure is:

```text
regions
players
```

The client expects enough region data for its UI/decompiled control flow. The supplied notes specifically warn against assuming a single region is always safe; the merged server defensively returns multiple region entries.

For a private server, implement a deterministic region list and make the region referenced by the player's token/account valid.

---

# 13. `LOAD_ANNOUNCE` — MID 7

The announcement response contains:

```text
contents
```

**Important:** `contents` is expected to be a **JSON-encoded string**, because `LoginWindow.lua` calls `json.decode(response.contents)`.

Correct empty response:

```json
{
  "error_code": 0,
  "contents": "{}"
}
```

Not:

```json
{
  "error_code": 0,
  "contents": {}
}
```

---

# 14. `QUERY_SERVER_TIME` — MID 3

Used to synchronize the client clock.

The generic response can be:

```json
{
  "error_code": 0,
  "server_time": 1770000000
}
```

The exact expected time unit should be validated against the client utility/model consuming it before implementing persistence-sensitive systems.

---

# 15. `LOAD_PLAYER_INFO` — MID 17

This is one of the most important responses in the entire backend.

`SelfPlayer:onPlayerInfo_()` consumes the callback's raw parameter object.

Fields therefore belong at the **top level**.

The response must not be wrapped under `player_info` unless the client callsite explicitly expects that.

The supplied reconstruction specifically corrected a previous implementation that returned:

```json
{
  "error_code": 0,
  "player_info": { ... }
}
```

because this causes the player's fields to remain nil/empty.

The exact required fields should be derived from `SelfPlayer:onPlayerInfo_()` and then implemented incrementally. At minimum, the client uses fields such as:

- `token`
- `regions`
- `contents`
- `exp`
- `lev`
- `func_ids`

plus a large amount of player progression/state data.

---

# 16. Battle architecture — crucial distinction

The battle system is **not simply “server sends a battle result.”**

For many modes:

1. The client chooses a formation.
2. The client sends a **battle-start / fight** MID.
3. The server may return enemy formation, battle report and/or awards.
4. The client constructs/runs the battle scene.
5. `BattleCreateReport.lua` extracts the local battle result.
6. A mode-specific **result MID** sends the result back to the server.
7. The server returns progression/award/state updates.
8. The client emits `BATTLE_REPORT_CREATE` and/or updates models.

This means a private server must implement **both halves**:
- start/preparation endpoints,
- result/commit endpoints.

Returning only `error_code: 0` from the result endpoint is not sufficient for progression-heavy modes.

---

# 17. Normal campaign battle — MID 113 `FIGHT`

The main campaign battle request is generated in `SelectTeamNewWindow.lua`.

A representative request is:

```json
{
  "campaign_id": <campaign id>,
  "campaign_type": <campaign type>,
  "formation": "<encoded formation>"
}
```

Optional additions include:

```json
{
  "pet_id": <pet id>,
  "rent_pet_player_id": <player id>,
  "rent_pet_id": "<pet id>"
}
```

The exact formation encoding is produced by the client's `getFormationStr()` / related helpers and should be copied exactly rather than invented.

The client also constructs enemy heroes locally from the static battle tables:

```text
xyd.tables.battle:monsters(battleID)
```

This is a major private-server simplification: for ordinary campaign battles, the static asset tables contain substantial enemy definition information.

### `FIGHT` response

The response is consumed primarily for:

```text
items[]
  item_id
  item_num
```

Those are converted into client-side drops.

The battle scene is then populated with locally available campaign/battle data.

A minimal useful response is therefore:

```json
{
  "error_code": 0,
  "items": []
}
```

---

# 18. Normal campaign battle end — MID 114 `FIGHT_RESULT`

`BattleCreateReport.lua` builds:

```json
{
  "campaign_id": <id>,
  "star": <battle star>,
  "campaign_type": <type>,
  "formation": "<hero ids separated by |>",
  "pet_id": <pet id>
}
```

The server's response is then consumed for progression.

Known response fields:

### `chapter_info`

```json
{
  "normal_chapter_id": ...,
  "normal_campaign_id": ...,
  "super_chapter_id": ...,
  "super_campaign_id": ...,
  "super_stars": ...,
  "normal_stars": ...
}
```

### `campaigns`

Each entry may contain:

```json
{
  "campaign_id": ...,
  "star": ...,
  "daily_limit": ...,
  "reset_count": ...
}
```

### `trial`

When applicable, trial progression data is consumed.

A useful compatibility response therefore looks conceptually like:

```json
{
  "error_code": 0,
  "chapter_info": {
    "normal_chapter_id": 1,
    "normal_campaign_id": 1,
    "super_chapter_id": 0,
    "super_campaign_id": 0,
    "normal_stars": 0,
    "super_stars": 0
  },
  "campaigns": {}
}
```

The actual values must be consistent with the player's current progression.

---

# 19. Arena battle start — MID 280 `START_FIGHT`

`ArenaSelectTeamNewWindow.lua` calls:

```text
START_FIGHT
```

The response is one of the richest battle-start responses observed.

## Response fields consumed

### `formation`

If present and non-empty, it is converted into hero objects for the player's side.

### `battle_report`

The client accepts two forms:

```text
battle_report[1].content
```

or the report object/list directly.

If present, it is placed into the battle scene.

### `partner_favor`

Copied to battle scene state.

### `award_crystal`

Copied to battle scene state.

### `is_win`

Copied to battle scene state.

### `enemy_formation`

This is heavily consumed.

Relevant fields include:

- `is_robot`
- `player_name`
- `guild_id`
- `guild_name`
- enemy formation hero data
- pet data where applicable

### `items`

Each item is converted into an award:

```json
{
  "table_id": <item_id>,
  "item_num": <item_num>
}
```

### Empty report behavior

If:

```text
battle_report == nil
```

or effectively empty, the client schedules another `START_FIGHT` call after a delay.

This means the server should normally return a complete report if it expects the client to enter the battle immediately.

---

# 20. Arena battle end — MID 279 `ARENA_FIGHT_RESULT`

The battle-result producer creates:

```json
{
  "hero_data": {
    "<hero_table_id>": [<damage>, <kill_count>]
  },
  "formation": <formation>,
  "campaign_type": <campaign_type>,
  "star": <star>,
  "fighter_info": <fighter metadata>,
  "report": <battle report>,
  "report_invalid": <validation result>,
  "is_avenge": <flag>,
  "lib_mission_formations": <formation library>
}
```

The endpoint is sent as **zlib-compressed multipart form data**.

The client accepts success if:

```text
error_code == 0
```

or if the response contains the known "fight already exists" error ID.

The response is then dispatched as `BATTLE_REPORT_CREATE`.

---

# 21. Peak / Super Arena

Important MIDs:

- `LOAD_PEAK_ARENA`
- `GET_PEAK_INFO`
- `MATCH_ENEMIES`
- `GET_ENEMY_TEAM`
- `PEAK_START_FIGHT`
- `PEAK_FIGHT_RESULT`
- `PEAK_RECORDS`
- `PEAK_RECORDS_LIST`
- `PEAK_RECORDS_DETAIL`

`PeakArena.lua` shows the orchestration.

### Start

`PEAK_START_FIGHT` receives a mode-specific parameter object and on success reads:

```text
rank_info
base_info
```

### Result

`BattleCreateReport.lua` sends:

```json
{
  "hero_data": ...,
  "team1": ...,
  "team2": ...,
  "team3": ...,
  "pet1": ...,
  "pet2": ...,
  "pet3": ...,
  "campaign_type": ...,
  "stars": ...,
  "enemy_id": ...,
  "reports": ...,
  "report_invalids": ...,
  "lib_mission_formations": ...
}
```

`PEAK_FIGHT_RESULT` is one of the compressed multipart endpoints.

---

# 22. Region Arena

`RegionArena.lua` exposes a clean mode API:

| Operation | MID |
|---|---|
| get info | `GET_REARENA_INFO` |
| modify defense | `REARENA_MODIFY_DEFENCE` |
| match enemy | `REARENA_MATCH_ENEMY` |
| start fight | `REARENA_START_FIGHT` |
| fight | `REARENA_FIGHT` |
| ranks | `REARENA_LOAD_RANKS` |
| end fight | `REARENA_END_FIGHT` |
| partners | `GET_REARENA_PARTNERS` |
| records | `REARENA_FIGHT_RECORDS` |
| report | `REARENA_FIGHT_REPORT` |

### `REARENA_MATCH_ENEMY`

Request:

```json
{
  "is_practice": <flag>
}
```

### `REARENA_START_FIGHT`

Request:

```json
{}
```

### `REARENA_FIGHT`

Request is mode-specific and forwarded from the caller.

### `REARENA_END_FIGHT` — result

The result producer sends:

```json
{
  "battle_result": {
    "report_hero_data": {
      "<hero_table_id>": [<damage>, <kill_count>]
    },
    "battle_report": <serialized report>,
    "star": <battle star>,
    "lib_mission_formations": <formation library>
  },
  "enemy_id": <enemy player id>
}
```

This endpoint is compressed multipart.

On success, the client reads:

```text
response.arena_info.star
```

and stores the updated star.

---

# 23. March

Relevant MIDs:

- `LOAD_MARCH`
- `RESTART_MARCH`
- `MARCH_START_FIGHT`
- `MARCH_FIGHT_RESULT`
- `MARCH_OPEN_BOX`
- `MARCH_OPEN_EXTRA_CHEST`
- `MARCH_ADVANCE_SWEEP`

### `MARCH_START_FIGHT`

Request observed:

```json
{
  "campaign_type": <type>,
  "formation": "<encoded formation>"
}
```

Optional rental parameters may also be injected by `handleRentParams()`.

The client expects success and then transitions into the battle scene.

### `MARCH_FIGHT_RESULT`

The client sends:

```json
{
  "is_reborn": 0,
  "win": true,
  "hero_status": [
    {
      "hero_id": ...,
      "hp": ...,
      "mp": ...,
      "is_reborn": ...
    }
  ],
  "enemy_status": [
    {
      "hero_id": ...,
      "hp": ...,
      "mp": ...,
      "is_reborn": ...
    }
  ]
}
```

This endpoint is compressed multipart.

---

# 24. Treasure battle result

`TREASURE_SAVE_BATTLE_RESULT` is compressed multipart.

The request contains:

```json
{
  "hero_status": [
    {
      "hero_id": ...,
      "hp": ...,
      "mp": ...,
      "is_reborn": ...
    }
  ],
  "enemy_status": [
    {
      "hero_id": ...,
      "hp": ...,
      "mp": ...,
      "is_reborn": ...
    }
  ]
}
```

The battle scene updates treasure hero status locally and then commits the result.

---

# 25. Conquer School

`ConquerSchool.lua` exposes:

- `GET_CONQUER_SCHOOL_INFO`
- `START_CONQUER_SCHOOL_FIGHT`
- `BUY_CONQUER_TIMES`
- `CONQUER_SCHOOL_FIGHT_RESULT`
- `GET_CONQUER_SCHOOL_REPORT_LIST`
- `GET_CONQUER_SCHOOL_REPORT`
- `RESET_CONQUER_SCHOOL`

Start request is a mode-specific object.

On successful start, the client decrements `leftTimes`.

Result request is compressed multipart.

The response may contain:

```text
is_promote
conquer_lev
```

which update the mode's progression.

---

# 26. Battle report format

The exact battle report serializer is in `BattleCreateReport.lua:writeReport()` and related functions.

The report is **client-generated** from the battle simulation rather than a simple server-provided string.

This is important for server reconstruction:

- The server does not necessarily need to reproduce every animation/event if the client can generate the battle.
- The server does need to accept the resulting report format and validate or store it consistently enough for subsequent UI/state.
- For private-server development, an initial implementation can treat reports as opaque blobs while preserving the surrounding JSON schema.
- Later, implement report validation if anti-cheat/server-authoritative behavior becomes a goal.

---

# 27. Chat — the actual raw TCP subsystem

The supplied protocol correction is explicit:

> The `:9000` game endpoints are HTTP. Raw TCP is used for chat.

`Backend.lua` has:

```text
tcpRequest_
onSocketMessage_
```

Chat is connected lazily after:

```text
LOAD_CHAT_ROOM_INFO
```

The HTTP response supplies the chat host/port.

Known chat-related MIDs include:

- `TCP_LOGIN = 32771`
- `CHAT_ROOM_ENTERED = 32779`
- `SEND_CHAT_MESSAGE = 32782`
- `CHAT_MESSAGE = 32783`
- `SOCKET_HEARTBEAT = 32797`

The private server should postpone this subsystem until the HTTP game loop is functional.

---

# 28. Error handling

The generic callback contract is:

```text
callback(error_code, response, userdata)
```

The client considers:

```text
xyd.error.OK == 0
```

to be success.

Response-level `error_code` is additionally used for game-specific failures.

The client can display an error message from:

```text
error_msg
```

or resolve a localized message using the numeric error code.

### Important retry behavior

Network failures can be queued into `pendingRequests`.

Most MIDs are retryable.

`LOAD_CHAT_ROOM_INFO` is explicitly excluded from the normal retry policy.

A private server should return HTTP 200 with a valid JSON error object for game-level failures whenever possible; returning malformed JSON or a non-200 response can trigger a different client path.

---

# 29. Server implementation architecture

A clean ground-up server should be divided into these layers:

```text
                 ┌────────────────────┐
                 │  SDK compatibility │
                 │   /login endpoint  │
                 └─────────┬──────────┘
                           │
                    account/session
                           │
                 ┌─────────▼──────────┐
                 │ Center / discovery │
                 │      MID 20480     │
                 └─────────┬──────────┘
                           │ url
                 ┌─────────▼──────────┐
                 │   Engine router   │
                 │     /api/v1       │
                 └─────────┬──────────┘
                           │
       ┌───────────────────┼─────────────────────┐
       │                   │                     │
   player/state         battles              social
       │                   │                     │
  SelfPlayer etc.     start/result          guild/friends
                           │
                    ┌──────▼──────┐
                    │ Chat TCP    │
                    │ last phase  │
                    └─────────────┘
```

## Recommended internal modules

```text
server/
  app.py / server.py
  protocol/
    payload.py
    response.py
    mids.py
    errors.py
  auth/
    sdk.py
    sessions.py
  center/
    discovery.py
    version.py
  player/
    player.py
    inventory.py
    heroes.py
    progression.py
  battle/
    campaign.py
    arena.py
    peak.py
    region_arena.py
    march.py
    treasure.py
    reports.py
  social/
    guild.py
    friends.py
  chat/
    tcp_server.py
```

---

# 30. Generic MID router

Do not write 1,200 independent HTTP handlers on day one.

Start with:

```python
HANDLERS = {
    1: retrieve_token,
    2: version_check,
    3: server_time,
    7: load_announce,
    17: load_player_info,
    18: load_user_regions,
    113: fight,
    114: fight_result,
    279: arena_fight_result,
    280: start_arena_fight,
    # ...
}
```

Unknown MIDs can initially return:

```json
{"error_code": 0}
```

but every screen you want to make functional must eventually receive the fields its Lua consumer expects.

The supplied notes report **1,210 catalogued MIDs total** in the original generated implementation; the current `mid.lua` extraction contains **1,210 unique definitions** because aliases/extra entries can make counts differ depending on how the table is enumerated.

---

# 31. How to reverse-engineer the next endpoint

For every `no handler for mid=X`:

1. Find the symbolic name in `mid.lua`.
2. Search all Lua files for `xyd.mid.NAME`.
3. Find the nearest `Backend.get():request(...)`.
4. Record the request table immediately before the call.
5. Inspect the callback:
   - fields read from `response`
   - nested objects
   - arrays
   - error codes
   - events dispatched
6. Search for the corresponding event consumer.
7. Implement only the fields actually consumed.
8. Run the client again.
9. Repeat.

This is much more reliable than guessing a conventional REST schema.

---

# 32. Important distinction: static data vs backend state

The asset dump contains extensive static tables.

For example, ordinary campaign battle construction uses:

```text
xyd.tables.battle
xyd.tables.campaign
xyd.tables.battleConfig
```

The client can therefore derive many things locally:

- enemy definitions
- battle configuration
- campaign metadata
- item/hero table IDs
- UI/static progression definitions

The backend primarily needs to maintain mutable state:

- account identity
- token/session
- player level/experience
- currencies
- inventory
- hero state
- progression
- campaign stars/limits
- arena state
- guild/social state
- event state

Do not duplicate static client tables into the database unless needed.

---

# 33. Flat response rule — examples

### Correct

```json
{
  "error_code": 0,
  "lev": 1,
  "exp": 0,
  "func_ids": [],
  "regions": [],
  "contents": "{}"
}
```

### Incorrect for engine layer

```json
{
  "error_code": 0,
  "data": {
    "lev": 1
  }
}
```

### Correct SDK-style envelope

```json
{
  "status": 1,
  "code": 1,
  "error_code": 0,
  "msg": "ok",
  "data": {},
  "uid": "1000001"
}
```

The SDK and engine layers must not be conflated.

---

# 34. Security/compatibility implications

This client/server protocol has several trust boundaries that matter for a private implementation.

## Client-generated battle results

The client submits:

- stars
- damage
- kill counts
- HP/MP
- battle reports
- formations

Therefore a naive server is inherently client-authoritative.

For a private server, that may be acceptable initially.

For a robust authoritative implementation, the server would need to validate:

- formation legality
- hero ownership
- energy/HP constraints
- campaign availability
- battle outcome
- reward eligibility
- duplicate result submission
- replay/report consistency

## Duplicate result handling

The client explicitly tolerates a known "fight already exists" result condition in several battle result handlers.

This implies the backend should make result commits **idempotent**.

A practical database key is:

```text
(player_id, battle_instance_id)
```

where the instance ID is generated/returned by the battle-start operation if the protocol exposes one; otherwise the implementation can derive a deterministic request fingerprint until a stronger identifier is found.

---

# 35. State machine for an ordinary campaign battle

```text
IDLE
  │
  │ FIGHT(campaign_id, formation, ...)
  ▼
BATTLE_PREPARED
  │
  │ client runs battle locally
  ▼
BATTLE_FINISHED
  │
  │ FIGHT_RESULT(campaign_id, star, formation, pet_id)
  ▼
RESULT_COMMITTED
  │
  ├── update campaign stars
  ├── update chapter progression
  ├── update trial state
  ├── grant rewards
  └── return updated state
  ▼
IDLE
```

Arena/Peak/Region Arena use the same broad pattern but with additional matchmaking and mode-specific state.

---

# 36. Practical implementation milestones

## Phase 1 — boot

Implement:

- SDK MID 65305
- SDK MID 65284 guest login
- SDK MID 65281 credential login if needed
- center MID 20480
- version MID 2
- token MID 1
- region MID 18
- announcement MID 7
- server time MID 3
- player info MID 17

Goal:

> reach the main menu without a Lua nil-index/client exception.

## Phase 2 — static/basic player

Implement:

- hero load
- inventory/backpack
- world map
- basic configuration/state
- save/load player state

## Phase 3 — ordinary campaign battle

Implement:

- MID 113 `FIGHT`
- MID 114 `FIGHT_RESULT`
- campaign progression
- rewards

Goal:

> start a campaign battle, finish it, and see the star/progression persist.

## Phase 4 — Arena

Implement:

- arena load
- opponent list
- `START_FIGHT`
- `ARENA_FIGHT_RESULT`
- ranks/records

## Phase 5 — special battle modes

Implement:

- Peak
- Region Arena
- March
- Treasure
- Conquer School

## Phase 6 — social

Implement:

- friends
- guild
- chat-room discovery
- TCP chat

---

# 37. High-value Lua module map

- **`UpdateScene.lua`** — Bootstrap/update scene. Performs center discovery (MID 20480), installs xyd.serverUrl from the response, then runs version checking (MID 2).
- **`app/common/network/Backend.lua`** — Primary in-game HTTP dispatcher. Adds common fields, token/region, serializes payloads, chooses normal form POST vs zlib multipart vs file upload, parses flat JSON responses, dispatches events, handles retries and side effects.
- **`app/common/network/mid.lua`** — Canonical engine-layer MID catalog. 1,200+ symbolic operation names mapped to numeric message IDs.
- **`app/model/SelfPlayer.lua`** — Central player-state model. Calls many load/mutation MIDs and consumes the flat LOAD_PLAYER_INFO response.
- **`app/windows/LoginWindow.lua`** — Region/account entry UI. Consumes LOAD_USER_REGIONS and LOAD_ANNOUNCE and decides region/login flow.
- **`app/scenes/BattleCreateReport.lua`** — Battle result producer. Converts the locally simulated battle state into the result payload for campaign, arena, peak, region arena, treasure, and march endpoints.
- **`app/windows/ArenaSelectTeamNewWindow.lua`** — Arena battle-start consumer. START_FIGHT response is converted into battle scene data, including formation, battle_report, enemy metadata and awards.
- **`app/windows/SelectTeamNewWindow.lua`** — General battle-start UI for campaign/march and many event modes. Sends FIGHT or specialized START_FIGHT MIDs with formation/campaign parameters.
- **`app/model/PeakArena.lua`** — Peak/super-arena orchestration: load, match, start fight, report.
- **`app/model/RegionArena.lua`** — Region arena orchestration: match, start, fight, rank, and end-fight result.
- **`app/model/ConquerSchool.lua`** — Conquer School mode state and start/result APIs.

---

# 38. What is confirmed vs unknown

## Confirmed from client source

- Engine API uses POST.
- Engine payload is a JSON object carried in a `payload` field.
- Common `mid/token/region/v_/app_v/platform` fields are injected by `Backend.lua`.
- Selected battle/result MIDs use zlib-compressed multipart `payload`.
- MID 20480 is HTTP center discovery.
- MID 20480 response is flat and contains `url`.
- `xyd.serverUrl` is taken from that `url`.
- Engine responses are flat JSON objects.
- `error_code: 0` is the generic success code.
- `LOAD_ANNOUNCE.contents` is a JSON string.
- `LOAD_PLAYER_INFO` fields are consumed at response root.
- Ordinary campaign `FIGHT` is MID 113.
- Ordinary campaign `FIGHT_RESULT` is MID 114.
- Arena `START_FIGHT` is MID 280.
- Arena result is MID 279.
- Peak/Region/Treasure/March result endpoints have mode-specific payloads.
- Raw TCP is used for chat.

## Not fully known from the supplied assets

- Complete SDK Java MID contracts for every SDK operation.
- Exact server-side battle validation algorithm.
- Exact production database schema.
- Exact server-side reward RNG/anti-cheat logic.
- Complete semantic meaning of every one of the 1,200+ MIDs.
- Exact on-wire double-encoding behavior of ordinary engine `payload` without a real engine-layer packet capture.
- Full chat TCP packet schema.
- Production matchmaking/ranking algorithms.

These should be treated as reverse-engineering tasks, not facts.

---

# 39. Recommended packet logging format

For every request, log:

```text
timestamp
remote_ip
surface = sdk|center|engine|gm|tcp
http_path
mid
decoded_payload
token_hash
region
response_error_code
response_keys
response_size
```

Do **not** log raw passwords or access tokens in persistent logs.

For battle traffic additionally log:

```text
battle_mode
start_mid
result_mid
campaign_id / enemy_id
request keys
response keys
report size
```

This gives enough information to turn unknown MIDs into implementation tickets without retaining sensitive credentials.

---

# 40. API compatibility checklist

For every handler:

- [ ] numeric MID is correct
- [ ] request is accepted in the correct transport form
- [ ] `payload` decoding accepts URL-encoded JSON
- [ ] zlib multipart is accepted where required
- [ ] file multipart is accepted for upload MID 1844
- [ ] response HTTP status is 200 for normal game errors
- [ ] response is valid JSON
- [ ] `error_code` is present
- [ ] response fields are at the correct nesting level
- [ ] arrays/objects use the exact field names expected by Lua
- [ ] result commits are idempotent
- [ ] player state is persisted
- [ ] rewards are not duplicated on retries

---

# 42. Source paths used for the core protocol reconstruction

```text
app-assets/output/assets/src_32/UpdateScene.lua
app-assets/output/assets/src_32/app/common/network/Backend.lua
app-assets/output/assets/src_32/app/common/network/mid.lua
app-assets/output/assets/src_32/app/common/error.lua
app-assets/output/assets/src_32/app/model/SelfPlayer.lua
app-assets/output/assets/src_32/app/windows/LoginWindow.lua
app-assets/output/assets/src_32/app/windows/SelectTeamNewWindow.lua
app-assets/output/assets/src_32/app/windows/ArenaSelectTeamNewWindow.lua
app-assets/output/assets/src_32/app/scenes/BattleCreateReport.lua
app-assets/output/assets/src_32/app/model/PeakArena.lua
app-assets/output/assets/src_32/app/model/RegionArena.lua
app-assets/output/assets/src_32/app/model/ConquerSchool.lua
app-assets/output/assets/src_32/data/tables/misc.lua
```

---

# 43. Notes carried forward from `PROTOCOL_NOTES.md`

The supplied protocol notes explicitly correct several earlier assumptions:

- `119.81.215.217:9000` is an HTTP server, not the game's raw TCP game protocol.
- `203.74.199.17:9000/api/v1` is another HTTP API base.
- Raw TCP is used for chat.
- Engine responses are flat rather than SDK-style `data`-wrapped.
- MID 20480 must return `url` at the root.
- `LOAD_ANNOUNCE.contents` is a JSON string.
- The Java SDK has its own MID namespace.
- Guest login was observed as SDK MID 65284.
- Credential login was observed as SDK MID 65281.
- SDK login identity fields were found to be required at the response root for at least MID 65281.

These corrections are treated as protocol evidence rather than assumptions.

---

# 44. Final reconstruction strategy

The fastest route to a usable private server is **not** to implement all MIDs.

Implement the dependency graph:

```text
SDK identity
   ↓
20480 center redirect
   ↓
2 version
   ↓
1 token
   ↓
18 regions
   ↓
7 announcements
   ↓
3 server time
   ↓
17 player info
   ↓
main menu
   ↓
feature load MIDs
   ↓
113 FIGHT
   ↓
114 FIGHT_RESULT
   ↓
Arena / Peak / Region / March / Treasure
   ↓
social + TCP chat
```

Use the Lua client as the specification for every response:

> **The field a consumer reads is the field the server must return.**

Do not design a generic REST schema first and try to adapt the client afterward. The decompiled Lua code is already the effective protocol specification.

---

## Appendix: core battle endpoint cheat sheet

| Mode | Start / prep | Result / commit | Transport |
|---|---|---|---|
| Campaign | `FIGHT` 113 | `FIGHT_RESULT` 114 | normal POST |
| Arena | `START_FIGHT` 280 | `ARENA_FIGHT_RESULT` 279 | result is zlib multipart |
| Peak | `PEAK_START_FIGHT` | `PEAK_FIGHT_RESULT` | result is zlib multipart |
| Region Arena | `REARENA_START_FIGHT` / `REARENA_FIGHT` | `REARENA_END_FIGHT` | result is zlib multipart |
| March | `MARCH_START_FIGHT` | `MARCH_FIGHT_RESULT` | result is zlib multipart |
| Treasure | `TREASURE_START_FIGHT` | `TREASURE_SAVE_BATTLE_RESULT` | result is zlib multipart |
| Conquer School | `START_CONQUER_SCHOOL_FIGHT` | `CONQUER_SCHOOL_FIGHT_RESULT` | result is zlib multipart |

---

**Document status:** protocol reconstruction based on the supplied asset archive and supplied protocol notes. This is a living reverse-engineering document; unknown contracts should be updated when additional client traces, Java SDK sources, or real engine-layer packet captures become available.
