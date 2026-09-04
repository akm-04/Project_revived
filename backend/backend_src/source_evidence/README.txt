GXB immutable source-evidence store

This tree contains byte-identical recovered source files used by backend catalog
builders and source-contract regression tests. It is NOT an OTA override root.

Rules:
- source_evidence/src_64 mirrors effective recovered src_64 bytes only.
- local_assets/src_32 and local_assets/src_64 are reserved for intentional
  cumulative client hot-update overrides and are packaged by
  tools/build_local_lua_update.py.
- Backend gameplay must consume generated catalogs/data or explicit source
  adapters, never treat this evidence tree as mutable player state.
