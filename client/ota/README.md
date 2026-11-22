# OTA client tree (I11A_OTA_RELEASE_V1 ruling 8)

- `src/<client path>`: whole replacement files, written under both `src_32/` and `src_64/` by `ota build`.
- `patches/<name>/`: a patch of one stock file. `patch.json` pins the stock file's sha256 (the build refuses any
  other input) and names a Go patch kind implemented in `internal/application/otabuild`; the directory holds the
  patch's overlay and its own tests.

Patch kinds: `insert_before_final_return` substitutes the overlay placeholders and inserts it before the stock
file's single final `return` anchor line. The retired Python generator's output is pinned as
`internal/application/otabuild/testdata/backend_http_poll_golden.lua`; `TestOptInStockBaselineGolden` compares the
Go build against it when `GXB_STOCK_BASELINE` names the stock zip or extracted tree.

The Lua test stays. Run it from the repository root with the stock file and the overlay:

```sh
GXB_STOCK_BACKEND=<stock tree>/app/common/network/Backend.lua \
GXB_HTTP_POLL_OVERLAY=client/ota/patches/backend_http_poll/backend_http_poll_overlay.lua \
go run client/ota/patches/backend_http_poll/tests/cjson_runner.go \
  client/ota/patches/backend_http_poll/tests/test_backend_http_poll.lua
```

No symlinks (Windows). The stock tree the build starts from is the operator's configured stock baseline.
