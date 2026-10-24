# Candidate identity contract

This contract separates four different identities that must not be conflated.

1. **Archive SHA-256** binds the delivered ZIP bytes. It includes `.git` when `.git` is intentionally shipped.
2. **`SNAPSHOT_MANIFEST.sha256`** binds every regular candidate file except `.git/**` and the manifest itself. It is regenerated only after candidate files are final.
3. **Product-tree digest** is external identity metadata computed by `tools/candidate_identity.py` using algorithm `gxb-candidate-tree-v1:path-nul-bytes-sorted-excluding-vcs-python-cache`: sort every regular file outside `.git/**`, `__pycache__/**`, `*.pyc`, and `*.pyo` by POSIX relative path, then feed `path UTF-8 || NUL || raw file bytes` into SHA-256. The digest therefore includes the final `SNAPSHOT_MANIFEST.sha256` and all shipped docs/evidence/metadata outside `.git`.
4. **Implementation revision** is the phase-specific semantic/product change identity defined by its own historical digest basis. It is not interchangeable with the complete candidate-tree digest.

`.git` and Python bytecode caches are explicitly excluded from product-tree and snapshot identities because they are mutable tooling provenance/ephemera rather than runtime product content. If a backend archive ships `.git`, the archive SHA-256 still binds those bytes. Go builds may use the repository metadata, while hermetic preseal copies may continue to use `-buildvcs=false`.

## Freeze sequence

1. Finalize source, tests, docs, evidence, and release metadata.
2. Regenerate `SNAPSHOT_MANIFEST.sha256` with `python3 tools/candidate_identity.py --write-snapshot`.
3. Verify it with `python3 tools/candidate_identity.py --verify-snapshot --json` and `python3 tools/check_connected_candidate.py`.
4. Compute the final product-tree digest from that exact frozen tree. Never pre-fill or hard-code a tree digest before this step.
5. Commit the frozen candidate if VCS provenance is being shipped. `.git` does not alter the product-tree digest.
6. Create the ZIP and compute its archive SHA-256.
7. Record the exact algorithm ID, product-tree digest, file count, snapshot-manifest SHA-256, archive SHA-256, and Git commit (when present) in external PassMap/handoff authority.

A mismatch between a reproducible exact archive and stale external tree metadata is an authority/identity defect, not evidence of a gameplay defect. It must be reconciled explicitly and the stale value marked superseded; product bytes must not be changed merely to force a stale digest.
