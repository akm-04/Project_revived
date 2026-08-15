# Agent handoff notes

Read this first if you're picking up this project fresh (human or AI). It's
a running log of sessions, what changed, what's confirmed vs. guessed, and
what to do next. Deep protocol/architecture reference lives in
`PROTOCOL_NOTES.md` — this file is the *narrative*, that one's the *spec*.

If you're an AI agent: this project rewards reading the actual decompiled
Lua source over pattern-matching to "how REST APIs usually work." Every
claim below cites a file:line. If you're about to guess a response shape,
grep for the call site first — `tools/MID_CATALOG.md` is built for exactly
this.

---

## Session N (2026-08-16, this session)

**Starting point:** a ChatGPT-produced backend (`server.py`, `game_logic.py`,
`mids.py`, `test_backend.py`) plus two READMEs (`PROTOCOL_NOTES.md`,
`README_CORRECTIONS.md`) and a 2,946-line first-pass reconstruction doc
(`GXB_PRIVATE_SERVER_BACKEND_README.md`). Reported symptom: guest login
succeeds, then a loading spinner appears and never resolves. Two artifacts
provided: an `adb logcat` capture and a full ChatGPT conversation
transcript of the debugging session that produced the current backend.

**What I did:**

1. Read the logcat capture. It only covers the Java `xydSDK` login layer
   (device init → guest login → payment-SDK init warning) and cuts off
   right after that, before any Lua-engine (`Backend.lua`/port 9000)
   traffic appears at all. Cross-referencing the chat transcript, an
   *earlier* run in the same debugging session had gotten further (engine
   MIDs 20480, 2, 2864, 18, 7, 1 all reaching the server per the
   transcript's own log excerpts) — so this particular logcat capture
   looks under-captured (stopped too early), not necessarily a regression.
   Flagged this explicitly in `PROTOCOL_NOTES.md` §4 so the next capture
   doesn't get cut short at the same point.

2. Independently re-derived the engine-layer flat-envelope finding
   (`PROTOCOL_NOTES.md` §3.1) directly from `Backend.lua` before reading
   the supplied `PROTOCOL_NOTES.md` — it turned out the ChatGPT session
   had already found and fixed the same thing. Good cross-check; gave me
   confidence the rest of that document's methodology was sound.

3. Traced the actual post-`RETRIEVE_TOKEN` control flow end to end:
   `Backend.lua` dispatches the `xyd.event.TOKEN` event *before* calling
   the request's own inline callback → `SelfPlayer.lua:loginEvent_` (the
   TOKEN listener) → `loadGameStartInfoEvent_`, which does
   `pairs(response.detail)` unconditionally. The existing backend never
   sent a `detail` field. This is a plausible root cause for the exact
   symptom reported (silent hang, no further requests, no obvious error)
   assuming Lua event dispatch here isn't `pcall`-wrapped (no evidence
   found that it is, in the decompiled source available). Full writeup
   with line numbers: `PROTOCOL_NOTES.md` §1.

   **This is the headline fix from this session** — not yet confirmed
   against real hardware.

4. Also noticed `loginEvent_` reads `response.uid` and the previous
   backend didn't send it — added, low-risk, done alongside the `detail`
   fix.

5. Patched `game_logic.py:handle_retrieve_token` to always send `detail`
   (populated with `LOAD_PLAYER_INFO` only — see the code comment there
   for why the other ~29 possible keys were deliberately left out rather
   than guessed), added a regression test to `test_backend.py`, all
   existing + new tests pass.

6. Separately (before reading the ChatGPT-produced files, as parallel
   work): built an AST-based static analyzer (`tools/audit_api.py`, uses
   the `luaparser` PyPI package) that walks the whole decompiled Lua tree
   and catalogues every `Backend:request()` call site — MID, request
   fields, and response fields the callback reads. 1,345 call sites,
   1,125 unique MID expressions, 96% resolved to numeric MIDs against a
   freshly-regenerated complete `mids.py` (1,210 entries, mechanically
   parsed from `mid.lua` — matches the ChatGPT session's own `mids.py`
   almost exactly, another good cross-check). Output: `tools/api_audit.json`
   (raw) and `tools/MID_CATALOG.md` (human-readable, grouped by MID).
   This is the tool for "what does MID 1234 need" once you see it show up
   as unhandled in the server log — grep it in `MID_CATALOG.md`, which
   gives you a file:line to go read directly instead of guessing.

7. Consolidated all three READMEs plus this session's findings into one
   `PROTOCOL_NOTES.md`. The original 2,946-line reconstruction doc's
   qualitative sections (battle formats, Arena/March/Treasure/Conquer
   School, chat/TCP, architecture recommendations — none of which
   overlaps with the boot-sequence work above) are preserved verbatim as
   an appendix; its raw MID-catalog listing was dropped in favor of
   `tools/MID_CATALOG.md`, which carries strictly more information
   (request/response field names, not just names/numbers).

**What I did NOT do** (be aware before assuming more works than it does):

- Did not test against real hardware. The `detail`-field theory is
  well-evidenced (direct source trace, precise line numbers, matches the
  symptom exactly) but unconfirmed. If the client still hangs after this
  fix, the next place to look is whether `xyd.EventDispatcher:dispatchEvent`
  (find `EventDispatcher.lua`, not yet read this session) actually does
  wrap listener calls in `pcall` somewhere not obvious from the call
  sites read so far — that would mean the hang has a different cause and
  this fix, while probably still correct/necessary, isn't sufficient.
- Did not populate the other ~29 `detail` keys (`PETS_GET`, `LOAD_HEROS`,
  `LOAD_BACKPACK`, `LOAD_WORLD_MAP`, etc.) — see the code comment in
  `game_logic.py` for the reasoning (avoiding new guessed-shape crashes).
  This is very likely the *next* piece of work once #1 above is confirmed.
- Did not re-verify the battle-system appendix content (Arena, March,
  Treasure, Conquer School protocol details) — carried forward as-is from
  the first ChatGPT pass. Treat it as a good starting point, not gospel,
  when that work starts.
- Did not investigate the `xydSDK` payment-init failure beyond flagging it
  as probably-non-fatal (§4 in `PROTOCOL_NOTES.md`). If it turns out to
  actually matter, that's Java/smali-side (no source available, only
  logcat), and would need the same kind of live-capture-driven
  investigation as the 65281 vs 65284 `uid` bug was.

**Next step for whoever runs this on hardware next:** run the server,
clear logcat, launch the app, do a *full* login attempt without stopping
the capture early, and check specifically whether `MainScene` renders.
Either outcome (works, or still hangs with new evidence) should get
logged as the next entry in this file.

---

## Earlier sessions (ChatGPT, prior to this one — summarized from the
## supplied transcript, not independently re-verified except where noted)

1. **First pass**: produced the original 2,946-line
   `GXB_PRIVATE_SERVER_BACKEND_README.md` from a full read of the client
   Lua source — architecture, MID catalog, battle/report formats, etc.
   Generated an initial `server.py`/`game_logic.py` skeleton from it.

2. **Second pass**: given a logcat capture, found the server was getting
   further than before (through `LOAD_USER_REGIONS`/`RETRIEVE_TOKEN`) but
   suspected the engine-layer response envelope was wrong. Produced a
   corrected `server.py`/`game_logic.py` — this is the version whose
   accuracy is confirmed in `PROTOCOL_NOTES.md` §3.1/§7 above (the flat
   envelope fix was real and correctly diagnosed).

3. **Bug found via live logcat**: Guest Login button did nothing when
   tapped — no error, just silence. Traced to the SDK-layer `uid` field
   being absent from mid 65284's response, causing a client-side
   `XinydLoginException` swallowed silently by the UI. Fixed by widening
   every SDK-layer response to include identity fields.

4. **Correction to #3**: the first attempt at that fix put `uid` only
   inside `data`, which didn't work — both 65284 and 65281 kept failing.
   A second live capture pinned it exactly: mid 65281's exception is a
   bare `org.json.JSONException: No value for uid` at
   `JSONObject.getString(JSONObject.java:559)`, unambiguous proof `uid`
   must be at the response **root**, not just `data`. Fixed by sending
   identity fields in both places.

5. **MID 2864 bug**: `GET_PLAYER_GROUP_BY_KEY`'s response was being
   treated like every other engine response (`{"error_code": 0}`
   wrapped), but `SelfPlayer:getAbtestGroupByKey()` assigns the *raw
   response body* directly as the AB-test group value — needs to be a
   bare scalar (`"A"`), unwrapped. Fixed.

6. **Where the transcript leaves off**: after the MID 2864 fix, a test run
   reached `RETRIEVE_TOKEN` (mid 1) — server received it, responded HTTP
   200 — but no further engine request appeared in the capture. The
   transcript's own hypothesis was "the Lua callback isn't firing," and it
   was about to go read `Backend.lua`'s exact callback-invocation code to
   find out why, when the conversation ended. **This session picked up
   exactly there** and found the actual cause (§1 above / `detail` field)
   — the callback most likely *is* invoked, but a sibling event listener
   throws first and aborts the shared response handler before the
   callback's own scene-transition code runs.

---

## A note for future agents

This codebase rewards patience over pattern-matching. Every "obvious"
assumption carried forward from typical REST-API experience has been
wrong at least once here: the response envelope, the region index, the
SDK identity field location, and now the post-login batch-loader
contract. The thing that has reliably worked is: find the exact call
site in the decompiled Lua, read the consumer function completely (not
just the first field access), and cite line numbers. `tools/MID_CATALOG.md`
and `tools/audit_api.py` exist to make that fast instead of tedious — use
them before guessing a response shape from scratch.

Also: the decompiler (`luajit-decompiler-v2`, invoked via
`decompile_and_patch.sh`/`patch_game.sh` in the toolkit) does not
reliably reproduce control flow for every function — it's been noted
independently in at least two sessions now (this one and the original
recovery session, re: `Backend.lua`/`ErrorLogPoster.lua`/`LoginWindow.lua`'s
region-index logic). When something looks structurally odd (like an
`elseif` chain that doesn't quite make sense), consider that the
decompiler may have mangled it before assuming the game logic is actually
that weird.
