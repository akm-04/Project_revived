# OTA client tree (I11A_OTA_RELEASE_V1 ruling 8)

- `src/<client path>`: whole replacement files, written under both `src_32/` and `src_64/` by `ota build`.
- `patches/<name>/`: a patch of one stock file. `patch.json` pins the sha256 of the **decompiled** stock Lua
  source, not of the APK's `src_32`/`src_64` LuaJIT bytecode (those differ by ABI). agent.json's `stock_source`
  names the decompiled source tree, with files at their client paths; the build reads and hashes that tree and
  refuses any other input. The directory holds the patch's overlay and its own tests.

Patch kinds: `insert_before_final_return` substitutes the overlay placeholders and inserts it before the stock
file's single final `return` anchor line. The retired Python generator's output is pinned as
`internal/application/otabuild/testdata/backend_http_poll_golden.lua`; `TestOptInStockBaselineGolden` compares the
Go build against it when `GXB_STOCK_BASELINE` names the stock zip or extracted tree and `GXB_STOCK_SOURCE` names the
decompiled source tree.

The Lua test stays. Run it from the repository root with the stock file and the overlay:

```sh
GXB_STOCK_BACKEND=<stock source>/app/common/network/Backend.lua \
GXB_HTTP_POLL_OVERLAY=client/ota/patches/backend_http_poll/backend_http_poll_overlay.lua \
go run client/ota/patches/backend_http_poll/tests/cjson_runner.go \
  client/ota/patches/backend_http_poll/tests/test_backend_http_poll.lua
```

No symlinks (Windows). `stock_baseline` still feeds the catalogue and the origin carriers; `stock_source` is the
decompiled Lua tree every patch is pinned to.
