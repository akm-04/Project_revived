# Split artifacts

GitHub refuses files over 100 MB, so each artifact is split into 90 MB parts in `parts/`. `MANIFEST.sha256` holds the
checksum of every whole artifact. Rejoin, verify and unzip with:

    tools/assemble.sh <destination dir> [artifact name ...]     # EXTRACT=0 only rejoins

| Artifact | What | Goes to (workspace W=/home/akm/Chatgpt/EOL_Game) |
|---|---|---|
| `gxb-backend-v2-e2e-tools-r4-go1.27.3-linux-amd64.zip` | portable toolchain: Python 3.12, Go 1.27.3, PostgreSQL, goose, LuaJIT, zig cc | `$W/work/toolchain/r4` and `$W/tmp/tools_r4_accept` (inputs/RECOVERY.md step 1) |
| `gxb-virtual-client-kit-p771-8aaa782.zip` | virtual client binaries at backend 8aaa782, its Go module cache, test scripts, TESTING_GUIDE.md | `$W/tmp/virtualclient/bin`; offline VC builds |
| `gxb-android-emulator-i8.5-7.zip` | Android SDK (emulator 37.2.12, android-30 x86_64 image), AVD gxb30 definition, emulator APK, README | `$W/tmp/android` (unzip `android/*` into `$W/tmp`) |
| `base-apk-apktool-decoded-unmodified.zip` | that APK decoded by apktool | `$W/inputs/client_baseline` (virtual client `apk/res`) |
| `base-apk-lua-decompiled-plaintext.zip` | its Lua decompiled to plaintext (redoing it needs Wine) | `$W/inputs/client_baseline` (virtual client `src_64`) |

Not here, by design: the stock APK (download Girls X Battle 1.631.0 yourself into `app_repack/app/`), the lazy asset tarball (`gxb1_lazy_unified_assets_verified_*.tar.zst`, game data, not repo material), the OpenResty source (v1 harnesses only) and the PassMap memory bank.
New artifact: `split -b 90M -d -a 3 <file> parts/<name>.part-`, add its sha256 line to MANIFEST.sha256, commit in batches
under 2 GB (GitHub's push limit), and push commit by commit if a push is refused.
