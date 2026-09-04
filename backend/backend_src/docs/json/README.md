# Archived pass JSON artifacts

Historical `PASS*.json` validation/release/delta records live here so the backend root remains operator-friendly.
`VERSION.json` stays at repository root because runtime/tools treat it as operational release metadata.
New pass JSON evidence should be written here unless a runtime contract explicitly requires another location.

Top-level `PASS*.md` / `PASS*.txt` reports are archived under
`docs/pass-reports/`. Validation tools resolve the historical paths through
`tools/pass_artifact_resolver.py`, so historical manifests remain byte-stable.
