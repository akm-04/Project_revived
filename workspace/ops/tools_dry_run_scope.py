#!/usr/bin/env python3
"""Read-only dry run for CONTRACT_SCOPE_V1: compare the live ops contract_manifest with the staging copy on the real
I9-11 registry and backend tree. Prints, per system, the old row count and the new binding/index row counts. Run with
no arguments."""
import hashlib
import importlib
import pathlib
import subprocess
import sys

STAGING_OPS = pathlib.Path("/home/akm/Chatgpt/EOL_Game/work/i9/stages/I9-11/gate_v2/staging_tc/ops")
LIVE_OPS = pathlib.Path("/home/akm/Chatgpt/EOL_Game/ops")
REGISTRY = pathlib.Path("/home/akm/Chatgpt/EOL_Game/work/i9/stages/I9-11/REGISTRY")
TREE = pathlib.Path("/home/akm/Chatgpt/EOL_Game/work/backend_repair_combined")
SYSTEMS = ("combat", "achievement", "bookskill")


def import_manifest(ops_directory):
    for name in ("contract_manifest", "contract_registry"):
        sys.modules.pop(name, None)
    sys.path.insert(0, str(ops_directory))
    try:
        return importlib.import_module("contract_manifest")
    finally:
        sys.path.remove(str(ops_directory))


def sizes(manifest_module, system):
    manifest = manifest_module.build_manifest(REGISTRY, TREE, [system], f"dry-run-{system}")
    binding = sum(row["tier"] == "binding" for row in manifest["contracts"] if "tier" in row)
    index = sum(row["tier"] == "index" for row in manifest["contracts"] if "tier" in row)
    return len(manifest["contracts"]), binding, index


def status():
    return subprocess.run(["git", "-C", str(TREE), "status", "--short"], capture_output=True, text=True).stdout


def main():
    before_status = status()
    before_registry = hashlib.sha256((REGISTRY / "registry.json").read_bytes()).hexdigest()
    staging = import_manifest(STAGING_OPS)
    live = import_manifest(LIVE_OPS)
    print(f"{'system':<14} {'old rows':>8} {'new binding':>11} {'new index':>9}")
    for system in SYSTEMS:
        old_rows, _, _ = sizes(live, system)
        new_rows, binding, index = sizes(staging, system)
        assert new_rows == binding + index, f"{system}: {new_rows} rows do not split into {binding}+{index}"
        print(f"{system:<14} {old_rows:>8} {binding:>11} {index:>9}")
    assert status() == before_status, "the dry run changed the backend tree"
    assert hashlib.sha256((REGISTRY / "registry.json").read_bytes()).hexdigest() == before_registry, (
        "the dry run changed the registry")
    print("read-only: tree status and registry.json unchanged")


if __name__ == "__main__":
    main()
