# Pass290 MID2 / Resource Updater Archaeology

Status: **RESEARCH COMPLETE / NO RUNTIME MUTATION IN PASS290**

## Source authority checked

- current `all-assest-rechecked-1.zip` `src_64/UpdateScene.lua`
- historical `gxb-old-client-v1.164.0-research-corpus.zip` `src/UpdateScene.lua`
- current `latest_apk-smali-full.zip` `AppActivity.smali`
- accepted Pass281 runtime MID2 trace and exact OTA1.631.24 package
- historical v1.164 `version.json` and persisted `.download_infos`

## Recovered stock protocol

MID2 `res` is an ordered list of logical update descriptors. `UpdateScene.update_()` downloads every descriptor, then unzips them in order, stores the **last descriptor version** as the installed resource version, and restarts.

Each descriptor has its own `volume=N`. `downloadVersion_()` requests:

`<resource>.001`, `<resource>.002`, ... `<resource>.NNN`

into one assembled `<version>.zip`. Descriptor `size` and `md5` describe the assembled ZIP, not an individual fragment. This is source-proven in both current and v1.164 clients.

`is_review` is top-level. It only controls whether `UPDATE_PROMPT` is skipped. Silent and loud updates enter the same `update_()` installer. Therefore a silent package that contains `version.json` can rewrite lazy-resource metadata exactly like a loud package.

## Current accepted silent baseline

The exact Pass281 OTA1.631.24 package is 2,409,878 bytes, MD5 `dd89797c446ed3562455f9929c0aad12`, SHA256 `9f9bcb3b118eea68ddc3dfc4e23cf8cd25aef7a9c0e4fe4db745137d9c727ec0`, contains 148 cumulative Lua/table override files, and contains **no `version.json`**. This is the correct permanent CODE_ONLY silent catch-up baseline.

Pass281 runtime evidence shows current stock Android sends MID2 with `app_v=1.631.0`, `platform=3`, `full=true`, and resource version (`v`) such as `1.631.23` then `1.631.24` after update.

## `full` is not a generation discriminator

Historical v1.164 hardcodes `full=true`, but current v1.631.0 runtime also sends `full=true`. Server-side semantics of `full` remain unrecovered. Pass291 scheduling must not use it to distinguish old-vs-new resource behavior.

## Historical bulk-resource reality

v1.164 already contains lazy infrastructure (`lazyFileManager`, `AssetDownload`) and a 30,699-row resource catalog: 9,401 force rows and 21,298 non-force/lazy rows representing ~651.63 MiB.

The supplied historical physical tree contains all 21,298 lazy objects with the expected historical MD5 when the old client's `/web/ -> /` physical alias is applied. This strongly corroborates the user's memory that historical installs ended up fully populated rather than relying heavily on per-click lazy downloads.

It does **not** prove which transport populated those bytes.

Both client generations also support an Android APK Expansion/OBB bootstrap. On clean Android install, `UpdateScene` calls Java `AppActivity.getAPKExpansionFile()`, which searches `/Android/obb/<package>/main.<versionCode>.<package>.obb`; Lua checks the OBB MD5 from `obbinfos.xml`, unzips it into `xyd.versionUpdatePath`, sets resource version to the APK version, then proceeds to MID2.

Therefore old ~1 GiB startup behavior could have been OBB bulk bootstrap, large/multiple MID2 packages, or a combination. No actual OBB, `obbinfos.xml`, multi-descriptor official MID2 response, or non-empty historical `.download_infos` survived in the supplied corpus. Source proves capability, not captured original-server use.

## Design consequences frozen for Pass291

1. Runtime update authority must become version-aware immutable release history, not one mutable latest manifest.
2. Exact update track gating must include `app_v` and platform. Historical v1.164 APK must never receive current v1.631.0 Lua packages.
3. CODE_ONLY is normally silent, cumulative, and structurally forbidden from carrying `version.json`.
4. CATALOG_MIGRATION is loud and acts as a sequencing barrier.
5. A MID2 response must be mode-homogeneous because one top-level `is_review` applies to all `res[]` descriptors.
6. Published package volumes are immutable; controller must never delete old published volumes.
7. Multi-volume `.001..NNN` support should be retained because stock client source explicitly supports it.
8. `full` remains unknown and must not drive scheduling.

## Future bulk resource delivery options

Three distinct stock/current-compatible directions are now known:

- **MID2 bulk resource bootstrap:** a loud multi-volume ZIP can place `res/...` directly into writable `versionUpdatePath`; this matches what current lazy initialization checks and is the strongest no-client-patch candidate for pre-populating the available ~1 GiB recovered resource tree.
- **OBB companion bootstrap:** current native/Lua code still supports main OBB discovery, MD5 verification, and unzip on clean install. Packaging/deployment needs separate design/recovery of `obbinfos.xml` semantics.
- **Fat APK:** Pass222 prep-APK can be extended to add `assets/res`, but simple embedding is not enough. Current lazy initialization tests non-force availability in **writable `versionUpdatePath`**, not packaged APK assets, so lazy keys could still be created and per-file downloads attempted. A fat APK would require additional bootstrap/client changes or force/catalog policy and is therefore not the preferred stock-compatible option today.
