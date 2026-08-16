# MainScene first-entry protocol — Pass 13

The normal MainScene entry is now separated from optional retained-window and user-interaction APIs.

## Before MainScene

`RETRIEVE_TOKEN (1)` -> synchronous detail hydration -> `ALBUM_SPECIAL_COLLECT_INFO (2784)` -> `xydSelectServer` -> local StoryData restore -> MessageManager -> MainScene.

## Immediately during MainScene entry

1. MessageManager starts 2 or 3 `LOAD_CHAT_ROOM_INFO (192)` discovery requests.
2. `MainSceneLeftWindow` has no automatic HTTP request found in its open path.
3. `MainSceneMiddleWindow:didOpen()` sends `LOAD_SUMMON_INFO` and `ILLUSION_LOAD_INFO`.
4. `MainSceneBottomWindow:willOpen()` sends `LOAD_FRIENDS`, and conditionally `GET_SELF_GUILD` and `PETS_GET`.
5. `MainSceneTouchWindow` sends no automatic HTTP request; `FIRST_MAIN_TOUCH` is gesture-triggered.
6. `MainSceneTopWindow:willOpen()` sends `CHECK_GAME_STAT`.

## Optional post-entry chain

Depending on guide state, `MainScene` can call `openWindowInOrder()`, which can invoke `GET_PIC_NOTICE_INFO`, `LOAD_SIGN_INFO`, `SIGN`, and activity APIs. These should not be conflated with the unconditional first-entry graph.

## Backend priority

For first-scene compatibility, the strongest source-confirmed response contracts from this pass are:
- 192 room discovery
- LOAD_SUMMON_INFO
- ILLUSION_LOAD_INFO
- LOAD_FRIENDS
- GET_SELF_GUILD when guild is enabled
- PETS_GET when pet function is enabled
- CHECK_GAME_STAT status-only compatibility

No claim is made here that implementing only these endpoints is sufficient for all later gameplay.
