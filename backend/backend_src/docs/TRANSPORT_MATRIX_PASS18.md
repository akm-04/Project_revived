# Transport Matrix Pass 18

Source files inspected:

- `app/common/network/Backend.lua`
- `app/common/network/mid.lua`

## Routing rules
`Backend:request(mid, ...)` first checks route class:

```lua
if xyd.isChatRoomMessage(mid) then
    tcpRequest_
elseif xyd.isGMOperation(mid) then
    GMRequest_
else
    webRequest_
end
```

`mid.lua` defines the bitmask checks:

```lua
xyd.isChatRoomMessage(mid) => bit.band(mid, 36864) == 32768
xyd.isGMOperation(mid)   => bit.band(mid, 36864) == 36864
```

## Audited request transport counts

| Transport class | Audited request records |
| --- | --- |
| dynamic/unresolved | 50 |
| http-upload-multipart | 1 |
| http-urlencoded-payload | 1268 |
| http-zlib-form-payload | 7 |
| tcp/chat-routed | 19 |

## HTTP zlib/form payload MIDs
`Backend:sendAsFormData_()` sends these as zlib-deflated JSON in a form `payload`, not ordinary URL-encoded JSON.

| MID name | MID value | Route class |
| --- | --- | --- |
| ARENA_FIGHT_RESULT | 279 | http-zlib-form-payload |
| PEAK_START_FIGHT | 2484 | http-zlib-form-payload |
| TREASURE_SAVE_BATTLE_RESULT | 535 | http-zlib-form-payload |
| REARENA_END_FIGHT | 774 | http-zlib-form-payload |
| REGION_FIGHT_RESULT | 1412 | http-zlib-form-payload |
| CONQUER_SCHOOL_FIGHT_RESULT | 1570 | http-zlib-form-payload |
| SAVE_FURNITURES | 2515 | http-zlib-form-payload |

## HTTP upload MID
`Backend:isUpload()` currently recognizes MID `1844`. The exact symbolic name needs a source lookup before semantic implementation.

## TCP/chat-routed MID definitions
These are **not** normal Flask HTTP game endpoints when sent through `Backend:request()`. Some are socket receive/event messages; `LOAD_CHAT_ROOM_INFO` remains HTTP because its MID is `192`, not in the chat bit range.

| MID name | MID value | Route class |
| --- | --- | --- |
| TCP_LOGIN | 32771 | tcp/chat-routed |
| CHAT_ROOM_ENTERED | 32779 | tcp/chat-routed |
| SEND_CHAT_MESSAGE | 32782 | tcp/chat-routed |
| CHAT_MESSAGE | 32783 | tcp/chat-routed |
| WORLD_NOTICE | 32784 | tcp/chat-routed |
| SOCKET_HEARTBEAT | 32797 | tcp/chat-routed |
| DIRNK_NOTIF | 36852 | tcp/chat-routed |
| GUILD_FIGHT_NOTICE | 36853 | tcp/chat-routed |
| PLAYER_NOTICE | 36854 | tcp/chat-routed |
| FORCE_RELOAD | 36855 | tcp/chat-routed |
| GM_BROADCAST | 36856 | tcp/chat-routed |
| RECHARGE | 36857 | tcp/chat-routed |
| SECRET_DUNGEON_MESSAGE | 36858 | tcp/chat-routed |
| HERO_EVOLVE_MESSAGE | 36859 | tcp/chat-routed |
| HERO_SUMMON_MESSAGE | 36860 | tcp/chat-routed |
| RUNE_MAX_MESSAGE | 36861 | tcp/chat-routed |
| GIFTBOX_MESSAGE | 36862 | tcp/chat-routed |
| GUILD_BROADCAST | 36863 | tcp/chat-routed |

## Backend rewrite consequence
The rewritten backend should have explicit transport modules:

```text
sdk_http
center_http
engine_http_urlencoded
engine_http_zlib_payload
engine_http_upload
chat_tcp_or_stub_boundary
gm_boundary
```

Do not expose chat bit-range MIDs as ordinary Flask `/api/v1` handlers unless we are deliberately creating compatibility diagnostics.
