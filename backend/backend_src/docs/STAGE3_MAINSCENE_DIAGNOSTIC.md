# Stage 3 MainScene Diagnostic Invariant

User Stage 2.3 result: lobby renders and the visible character can be changed, but most primary UI remains absent/inert.

Source path:

`MainScene:onEnterTransitionFinish()` opens:

1. `main_scene_left`
2. `main_scene_middle`
3. `main_scene_bottom`
4. `main_scene_touch`
5. `main_scene_top`

`MainSceneBottomWindow:onEnterAction()` and `MainSceneMiddleWindow:onEnterAction()` explicitly disable major controls during entry. They restore touch in their `MAIN_SCENE_ACTION_END` listeners.

`MainSceneTopWindow:willOpen()` executes:

`addEcoBar -> regLeftButtons -> updatePlayerInfo -> initActList -> onEnterAction -> checkGameStat`

`checkGameStat()` sends MID `2754 CHECK_GAME_STAT`.

The Stage 2.3 server trace never receives MID 2754. Therefore the strongest current source-based diagnostic is that MainScene top-window initialization does not reach the end of `willOpen()`. If that happens, `MAIN_SCENE_ACTION_END` may never be dispatched and the rest of MainScene can remain touch-disabled.

Stage 3 does not invent a server-side workaround for this local UI event. It initializes more of the models consumed by MainScene (world/trial/adventure/battle-pass/mail/invite/world-boss/roster/etc.) and uses an established FunctionID profile so the client can execute its intended path.
