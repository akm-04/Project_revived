# Pass441 — I4 Repair Current-Source / V1 Oracle Cross-Check

Pass441 preserves the implementation-research rule: PassMap supplies frozen design authority, while current `src_64` remains an active implementation oracle during coding. A source conflict is not suppressed merely because a design is frozen; it triggers targeted research before contract change. Pass353 remains differential/corroborative only.

After the Pass439 runtime repairs and Pass440 reproducibility hardening, the full oracle gate was rerun with the pinned archives:

- current `src_64` archive: `c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf`
- frozen Pass353 archive: `31729d5c5e4509c2c89eaa1e8203cf1570afe87e18ed2610b944e457a9946b15`

Results:
- I2 wire/source differential: PASS
- I3 identity/bootstrap differential: PASS
- I4 Wave-S/source + Pass353 differential: PASS

The W1 repair changes do not alter stock MID payload truth, account/player identity separation, blank-name lifecycle, MID1304 array semantics, Guild War boolean semantics, MID1 hydration/sidebands, or realtime room/authentication semantics. The new JSONL tracker is evidence-only and optional; it is not client protocol authority.

No new source fact requires design reopening before the W1 retest.
