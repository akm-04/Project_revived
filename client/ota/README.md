# OTA client tree (I11A_OTA_RELEASE_V1 ruling 8)

- `src/<client path>`: whole replacement files, written under both `src_32/` and `src_64/` by `ota build`.
- `patches/<name>/`: a patch of one stock file. `patch.json` pins the stock file's sha256 (the build refuses any
  other input) and says how the patch applies; the directory holds the patch's own tests.

No symlinks (Windows). The stock tree the build starts from is the operator's configured stock baseline.
