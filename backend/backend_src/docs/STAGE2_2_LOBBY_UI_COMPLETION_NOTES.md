# Stage 2.2 Lobby UI Completion Notes

Stage 2.1 restored the login/lobby path but the live client reached the lobby with the top HUD/buttons not usable. The request log showed no unknown or fallback MIDs and no `CHECK_GAME_STAT` request, which points to the MainScene top-window path not completing rather than a missing HTTP MID.

Stage 2.2 therefore keeps the safe bootstrap detail and adds two conservative client-facing fixes:

- `PlayerState` now advertises source-derived `xyd.FunctionID` values by default, so common lobby buttons/windows are considered open by the Lua client instead of silently behaving as locked/inert.
- The default avatar is now a known source table avatar (`110001001`) instead of `0`, avoiding missing-avatar behavior while MainSceneTopWindow builds the player header.
- `LOAD_ACHIEVEMENT_INFO` and `GET_ACHIEVEMENT_AWARD` are now mapped, because MainSceneTopWindow calls achievement loading during `didOpen`.

Payment remains intentionally ignored. TCP chat remains a minimal acceptor only; repeated chat-room discovery should be logged but is not treated as a Stage 2 blocker unless it prevents UI interaction.

Only syntax checks were run.
