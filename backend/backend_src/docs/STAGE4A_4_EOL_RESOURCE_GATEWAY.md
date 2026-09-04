# Stage 4A.4 — EOL lazy-resource gateway

## Why this exists

The official resource host is gone. The supplied client still has its original lazy-resource downloader and local metadata, so missing battle/window assets can block on `NewLoadingWindow` even when the game API response is correct.

The authoritative `src_64` path is:

1. `UpdateScene_64.lua` receives `res_download_url` from center discovery and stores it as `xyd.resDownloadUrl`.
2. `UpdateScene_64.lua` uses `version.json` to populate `lazyFile.json` entries for non-force resources that are absent or fail local MD5 validation.
3. `AssetDownload:isFileExist()` treats the presence of a `__lazy__...` entry as “needs download”.
4. `AssetDownload:getDownloadVersionInfo()` retrieves that entry.
5. `AssetDownload:getDownloadInfo_()` constructs the actual URL as:

   ```text
   xyd.resDownloadUrl .. basename .. "." .. expected_md5
   ```

   The directory is intentionally absent from the HTTP request.
6. `FileDownloader` writes `<original path>.asset_tmp` under the writable update directory.
7. The completion callback verifies `MD5File(temp) == expected_md5` before renaming the file into place and deleting the lazy entry.
8. On failure or MD5 mismatch, the original client requeues the same resource.

The backend therefore needs a reverse index from `basename.md5` back to the original catalog path.

## Supplied metadata snapshot

The user-supplied EOL runtime metadata contained:

- `.revision`: `267088`
- `version.json`: 43,764 total rows
- `version.json`: 29,936 `res/web/...` non-force/resource rows with real MD5s
- `lazyFile.json`: 10,014 current lazy/missing entries
- `.download_infos`: empty plist at capture time

Stage 4A.4 packages `data/resource_catalog/resource_catalog.json`, generated from the supplied `version.json` plus the current lazy snapshot. It contains 29,936 catalog entries and is metadata only; no large asset payloads are bundled.

## Gateway behavior

Center discovery now advertises the backend `/res/` URL by default.

For a request such as:

```text
GET /res/example.png.<32-char-md5>
```

the gateway:

1. reverses the request through the packaged catalog;
2. records the original catalog path(s);
3. checks configured local asset roots only for those exact paths;
4. if a candidate exists, computes/caches its MD5;
5. serves it only when the MD5 equals the client's expected MD5;
6. otherwise returns 404 and logs the missing/mismatch state.

There is no 1.5 GB startup scan and no full-tree hashing.

## Asset-root layouts

Set one large local tree with:

```bash
GXB_ASSET_ROOT=/path/to/full/assets python3 server.py
```

The root may be any of these common shapes:

```text
/path/to/full/assets/res/web/...
/path/to/full/res/web/...
/path/to/full/web/...
```

In other words it may point at a directory containing `res/`, directly at `res/`, or directly at `res/web/`.

Multiple roots are supported with the platform path separator. On Linux:

```bash
GXB_ASSET_ROOTS=/archive/one:/archive/two python3 server.py
```

If no root is configured, Stage 4A.4 is still useful as a probe/logger. The client request reaches the backend, the catalog reveals the original path, and the gateway returns 404.

Optional zero-config local names are also checked when present:

```text
./asset_store
./assets
./res
```

A symlink is sufficient; assets do not need to be copied into the backend package.

## Runtime logs

The gateway writes:

```text
runtime_logs/resource_requests.jsonl
runtime_logs/resource_gateway_summary.json
```

The records distinguish at least:

```text
served
catalog_miss
asset_roots_unconfigured
local_file_missing
md5_mismatch
```

For a catalog hit, the log includes the client's requested `basename.md5`, expected MD5, original catalog path(s), candidate local path(s), selected path when served, and retry count.

Repeated native retries are de-duplicated; first request, status changes and retry milestones are appended while the JSON summary keeps current counts.

## Hot repair while the backend stays running

A missing resource is looked up on every retry. Therefore this workflow is supported:

1. reproduce the jellyfish/loading stall;
2. inspect `resource_gateway_summary.json`;
3. locate the exact `catalog_paths` file in the large archive;
4. copy or symlink it under the configured asset root preserving the catalog-relative path;
5. leave the APK/backend running;
6. the next native retry can be served immediately if its MD5 matches.

## Why a dummy PNG is not the default fallback

The supplied `AssetDownload.lua` checks the downloaded file's MD5 against the expected catalog MD5 before installation. A fabricated PNG, JSON, atlas, CSB, audio file, etc. will have a different MD5 and is requeued forever.

So a backend-only dummy response cannot advance this source-confirmed lazy-download path. A future dummy/placeholder mode would require one of:

- a controlled client patch that disables/changes lazy MD5 validation; or
- a controlled rewrite of the client's expected metadata to the placeholder's MD5, with format-specific placeholders.

That is a separate client-resource-reconstruction task and is intentionally not silently enabled here.

## Configuration

```text
GXB_RESOURCE_SERVICE=1|0
GXB_RES_DOWNLOAD_URL=http://host:port/res/
GXB_RESOURCE_CATALOG=/path/to/resource_catalog.json
GXB_ASSET_ROOT=/path/to/assets
GXB_ASSET_ROOTS=/path/one:/path/two
GXB_RESOURCE_VERIFY_MD5=1|0
```

MD5 verification defaults to enabled and should normally remain enabled.

The older `GXB_RESOURCE_PROBE=1` switch remains a compatibility alias that also enables advertising the resource gateway.

## Rebuilding the catalog locally

A metadata-only helper is included:

```bash
python3 tools/build_resource_catalog.py /path/to/version.json \
  --lazy /path/to/lazyFile.json \
  --out data/resource_catalog/resource_catalog.json
```

It does not scan the asset tree.
