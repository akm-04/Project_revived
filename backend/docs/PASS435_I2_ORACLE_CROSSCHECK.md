# Pass435 I2 Oracle Cross-check

Current `src_64` was re-read from the expected all-assets archive, not from V1. Exact member hashes match Pass411/412 for `Backend.lua`, `mid.lua`, and `framework/functions.lua`. The current APK `QuickHTTPInterface.smali` hash also matches the frozen native trace.

The implementation generator derives the complete numeric catalog from current `mid.lua`: 1,213 source assignments and 1,211 unique numeric MIDs. The realtime/GM bitmask functions are source-derived. The special zlib list, MID1844 duplicate behavior, exactly-one Lua URL-decode boundary, client retry lifecycle, and source timeout constants are rechecked by `tools/check_i2_oracle_wire.py`.

Frozen Pass353 is used only as a differential oracle. `tools/generate_pass353_wire_fixtures.py` imports its frozen Python realtime codec from the verified archive and emits five byte-level fixtures. The Go project codec matches those frames exactly. No Pass353 server architecture, permissive HTTP decoder, private nonce, state authority, or Python runtime is copied.

`goAMF3` remains unapproved for runtime authority. The project-owned codec is deliberately narrower than generic AMF3 and rejects unsupported native markers/shapes.
