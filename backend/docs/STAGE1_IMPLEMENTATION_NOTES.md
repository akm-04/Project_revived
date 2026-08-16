# Stage 1 Implementation Notes

## Decision

Static analysis passes stop at the Pass 19 baseline. The backend is now implemented as a modular Stage 1 server instead of continuing toward impossible static completeness.

## Source baseline used

The code was built from the accumulated Pass 19 documentation, especially:

- `docs/memory.md`
- `PLAYER_BOOT_PROTOCOL.md`
- `MAINSCENE_FIRST_ENTRY_PROTOCOL_PASS13.md`
- `TRANSPORT_MATRIX_PASS18.md`
- `DOMAIN_REWRITE_GATE_PASS19.md`

The old flat backend was used as a reference for confirmed cookie and payload behavior only.

## Implemented Stage 1 surfaces

### SDK/native compatibility

- `/server/mobile_api_new/`
- `/home_api/upload_sdk_logs`
- SDK identity/cookie behavior using `QQWSID`, `QQWUID`, `QQWUNAME`, `QQWTOKEN`
- empty successful payment-method payload for `query_pay_method_amounts`

### Center/update/engine HTTP

- `20480` center discovery
- `2` version/update check
- `18` user region list
- `7` announce
- `3` server time
- `2864` player group scalar response `"A"`

### Login/bootstrap

- `1` `RETRIEVE_TOKEN`
- `17` player info
- `49` heroes
- `81` backpack
- `836` library/background
- `56` summon info
- `176` friends/social
- `229` activities
- `2560` redmark list
- `2784` album-special collect info

### First MainScene / lobby

- `192` chat-room HTTP discovery
- `1344` illusion info
- `2754` check game stat
- `1864` first main touch
- `612` self guild
- `780` pets get

### Early optional/fanout APIs

- `1537` board info
- `234` load single activity
- `231` activity reward
- `352` sign info
- `353` sign
- `354` charge query
- `8193` picture notice
- `289` arena fight records
- `2485` peak records
- `2736` task load by type
- `161` take mission award

### Transport compatibility

- ordinary form `payload` JSON
- URL-decoded JSON variants
- zlib JSON variants
- multipart `payload` for form-data/battle-result paths
- chat-bit-range MIDs are classified as TCP/chat-routed, not semantic Flask endpoints

## Canonical state rule

All handlers serialize from `state.PlayerState` and `state.AccountIdentity` where possible. `RETRIEVE_TOKEN.detail["17"]`, standalone `LOAD_PLAYER_INFO`, MessageManager identity, library background, summon state, friends state, and redmark state therefore remain consistent.

## Runtime testing boundary

Only syntax checks were performed. Client/APK testing is intentionally left to the user environment.
