# v0.8.11 / Pass 33.1 — Tutorial Authority Trust-Boundary Fix

Pass33.1 is the narrow implementation revision approved after the clean-app-data Pass33 control run. It keeps the Pass32.5/32.6 restructure and changes only tutorial authority/orchestration.

## Runtime evidence entering this revision

A mandatory Clear App Data fresh-account trace on v0.8.10/Pass32.8 removed the earlier stale local `guide_id=100262` contamination and restored the intended early tutorial sequence. The run reached the canonical normal tutorial spine through Campaign `100007`, with Mission80001 claim, Lightin MID59, promotion and prior Campaign transactions working. At the committed MID114 result for Campaign100007 the backend emitted ordinary `new_funcs_:[68]` but did not announce Function33. The client therefore continued Campaign guidance. Only after the user deliberately pressed Skip and MID26 later submitted `guide_id=100262` did the old Pass32.6 `guide_id >= 100197` gate emit `new_funcs_:[33]`.

Client source independently establishes that MID26 `story_id`, `story_state`, and `guide_id` are locally persisted presentation continuity: `StoryData.updateDataFromStorage()` may promote the server-loaded guide to a higher local value. They cannot authorize server rewards, deterministic tutorial mutations, or Function announcements.

## Pass33.1 implementation

- Adds `TutorialMilestoneRepository`, a narrow server-authored tutorial-policy boundary in the existing request-scoped service graph. It stores only milestones emitted by canonical domain commits; it does not advance `StoryData` or own Campaign business rules.
- Adds persisted `PlayerState.tutorial_state` for those authoritative milestones.
- A successful canonical Normal Campaign MID113->MID114 transaction for Campaign `100007` records `normal_pre_skill_terminal_fight_committed`. This is the clean-runtime/source-supported local compatibility anchor for the terminal pre-Skill fight spine. It is explicitly **not** claimed as proof of the historical server's hidden release algorithm.
- When that milestone is recorded, `FunctionStateRepository` may explicitly announce already-eligible Function33 and stage semantic `new_funcs_:[33]` through the same UnitOfWork. The committed MID114 receipt also retains the semantic field so idempotent MID114 retries do not lose the transition.
- MID26 `SAVE_STORY` is restored to persistence-only behavior. It has no Function release authority.
- Persisted eligible/unannounced Function33 pending state migrates from the Pass32.6 raw guide-checkpoint policy to a tutorial-milestone policy.

## Deliberate boundaries

- No Campaign reward/RNG/stamina/sweep formula changes.
- No Mission chain expansion.
- No MID59/MID39 semantic change.
- No MID90 response-channel fix yet; the clean run reproduced the known consumable synchronization issue and it remains the next targeted follow-up after natural Skill-guide validation.
- Tutorial Summon still contains older pre-restructure guide-cursor trust debt. It worked in the clean control run and is intentionally not changed in this revision so regression attribution remains narrow.
- Activity1032, MID55 EXP-juice economy, MID31 bird/`CLICK_CRAB`, Guild/PvP and payment remain outside this revision.
- No protocol MID renumbering. A future source-backed symbolic MID-label cleanup is tracked separately; numeric MID values remain canonical protocol identity.

## Expected device checkpoint

With **Clear App Data** performed first, a fresh tutorial should reach Campaign100007. Its committed successful result should now include Function33 in `new_funcs_`, allowing the client special-function handler to start `GUIDE_SKILL_START=100198` without relying on a later MID26 guide cursor or the Skip button. The natural Skill tutorial should then exercise the already-implemented atomic MID39 Mana/Skill Point transaction.

## Validation policy

Assistant validation is Python syntax/AST, static constructor/call-shape review, JSON validation, unchanged-data/compatibility hashes, and ZIP integrity only. No Flask/HTTP integration, selftests, ADB/emulator, APK or gameplay execution is performed by the assistant. User-device testing remains authoritative.
