# Pass225 — Blood MID54 Runtime Reconciliation + Modular Operator Logging

## Runtime evidence

Fresh Pass224 clean-data smoke accepted ordinary Awakening, then opened Blood Awakening mission `2200001`. MID2738 returned the Blood mission plus `extra_drops_` item `50002078`. No Blood MID54 followed. Later MID2736 returned mission `2200001` with `count=0,is_complete=0`, matching the client's "craft/equip exclusive gear" gate.

Pass224 caused this regression: `NormalHero.getEquipByIndexShow()` treated the already-collected ordinary Awakening slot as proof that the newly substituted Blood item was collected. The Girl UI therefore looked auto-equipped and prevented the real Blood equip transaction.

## Client correction

`NormalHero.lua` is rebased onto effective current src_64 and keeps only a bounded Blood cache fix:

- Blood substitute is **not** marked collected merely because the ordinary slot is collected.
- successful MID54 sets an in-memory `__eolBloodEquipCollected_[slot]` marker for the Blood substitute;
- the displayed Blood item ID is removed from the local Backpack cache on success;
- durable `twice_awake_stage_` remains server-owned and is not advanced by the UI fix.

This restores the intended sequence: grant -> explicit equip/MID54 -> stage-one completion -> MID161 claim.

## Operator logging

Added `gxb_backend.observability.console_runtime` and `server.py::DEBUG_VERBOSE`:

1. basic/gameplay + errors + missing resources/404
2. + client window/resource probe events
3. + successful resource/update HTTP download traffic
4. all console/access/debug output

`server.py` automatically tees the filtered human-facing console into `runtime_logs/server.txt`. Structured JSONL observability remains unfiltered, so low console verbosity does not destroy forensic evidence. New code can use named `console_emit(category, message)` categories; legacy print/Werkzeug lines pass through a compatibility classifier.

## Root cleanup

Historical top-level `PASS*.json` artifacts were moved to `docs/json/`. `VERSION.json` intentionally remains at root as operational release metadata.
