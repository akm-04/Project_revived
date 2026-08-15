# GXB boot fix — 2026-08-16

The captured run reaches `xydSelectServer` successfully, so the failure is after `LoadingScene:selectServer()`. The bootstrap response previously contained only `detail["17"]`.

Two concrete client-state dependencies were verified in the decompiled Lua:

- `SelfPlayer:onPlayerInfo_()` calls `getAlbumAttrInfo()`. Its async callback calls `calculateWhiteAlbumAttr()`, which iterates `self.heros_`. `Player:herosEvent_()` initializes `heros_` only when `LOAD_HEROS` is processed. Therefore bootstrap now includes `detail["49"]` with an empty hero map.
- `MainScene:setupBackground()` immediately reads `Library.bgMain`. `Library.bgMain` is initialized only by `Library:updateLibraryInfos()`. Therefore bootstrap now includes `detail["836"]` with a valid empty library payload and `bg_main=1`, `bg_room=2`.

The existing `detail["17"]` and root `uid` fixes remain. This is a targeted bootstrap correction; it does not claim every game MID is fully implemented yet.
