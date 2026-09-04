# Pass74.0 Client Test Plan

- Login as anonymous debug UID `13371337`; verify normal preserved Hero/inventory state.
- Emblem Dissolve: dissolve one known emblem. For `160500603`, verify emblem count -1 and cumulative `patent_cer` +1,420; relog and confirm persistence.
- Quick Enchant: use once. Verify 20 Crystals consumed, Fumo +150 or remaining amount to cap, and no client freeze.
- Quick Enchant daily limit: second same-day attempt must not create a second Crystal debit or Fumo grant.
- Manual Enchant regression: perform one ordinary/manual Fumo enchant and confirm it still works.
- Ordinary Awakening open: press Awakening gear on an eligible Girl; confirm an Awaken Task appears in Lobby -> Missions -> Awaken Task.
- Ordinary stage 1: claim the gear/objective stage; confirm stage 2 appears.
- Wrong Campaign negative probe if practical: clearing a different Campaign stage must not complete the Awakening mission.
- Correct Campaign Awakening proof: clear the exact required stage with the required Girl and satisfy the special objective; confirm the Awaken Task completes.
- Final ordinary claim: claim the completed task; verify the Girl changes to awakened state/skill and remains awakened after relog.
- Blood Awakening, only if a naturally eligible Girl is available: open, claim stage 1, win the dedicated special battle, claim final task, and verify stage 3/completed state persists.
- Give-up: if practical, open a disposable Awakening/Blood task and give it up; verify the task row becomes inactive/reopenable and Blood state resets when applicable.
- Stone Evolution regression: perform one valid stone add/stage operation. Rejected requests should no longer crash from nil `evo_info`; a rare rejected MID2608 may show a temporary local cost-item count mismatch until Backpack refresh, while server state remains unchanged.
- Persistence: record Mana, Crystals, inscription certificate balance, and relevant Hero state before close; relog and verify exact server persistence.
- Bag-cap warning from the 1,225-item debug seed is not a Pass74 failure.
- Campaign's missing 6-Energy settlement is still deferred to Campaign ownership and is not a Pass74 acceptance criterion.
