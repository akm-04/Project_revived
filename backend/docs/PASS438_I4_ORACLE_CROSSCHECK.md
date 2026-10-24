# Pass438 I4 Current-Source / V1 Oracle Cross-Check

`tools/check_i4_oracle_wave_s.py` verifies the pinned current `src_64` archive before asserting stock-facing facts. It pins current `Backend.lua`, `mid.lua`, `SelfPlayer.lua`, `SelfGuild.lua` and `LoadingScene.lua`, then checks room discovery, TCP_LOGIN fields, room-entered heartbeat behavior, reconnect paths, MID1 sidebands, MID1304 length semantics, Lua truthiness, fresh-name lifecycle behavior, account/player identity separation and the initial avatar row.

The checker also mechanically extracts directly consumed MID17 fields from the current `SelfPlayer.onPlayerInfo_` function and fails if the I4 structural projection omits a non-optional startup key.

Pass353 is corroborative/differential only. The checker verifies its recovered MID192/TCP/bootstrap identity facts but does not import V1 private nonces, patched-client assumptions, synthetic server state, split authority or architectural coupling.

Current source remains active after I4: any later implementation fact that conflicts with a frozen design contract triggers targeted research before the contract is changed.
