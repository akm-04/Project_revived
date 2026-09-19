#!/usr/bin/env python3
"""Generate the deterministic direct dependency candidate SPDX inventory.

This is intentionally not a transitive SBOM. Once the target toolchain can
resolve go.sum in a connected environment, I0/I1 require an additional
transitive SBOM and vulnerability/license gate.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "DEPENDENCIES.lock.json"
OUT = ROOT / "SBOM.spdx.json"


def build() -> dict:
    lock = json.loads(LOCK.read_text())
    pass_id = str(lock["pass"])
    generated = str(lock["generated"])
    packages = []
    for i, dep in enumerate(lock["dependencies"], 1):
        packages.append({
            "SPDXID": f"SPDXRef-{i}",
            "name": dep["name"],
            "versionInfo": dep["version"],
            "downloadLocation": "NOASSERTION",
            "licenseConcluded": dep["license"],
            "licenseDeclared": dep["license"],
            "supplier": "NOASSERTION",
            "filesAnalyzed": False,
        })
    safe = pass_id.lower().replace(".", "-")
    return {
        "spdxVersion": "SPDX-2.3",
        "dataLicense": "CC0-1.0",
        "SPDXID": "SPDXRef-DOCUMENT",
        "name": f"gxb-backend-v2-pass{safe}",
        "documentNamespace": f"https://local.invalid/gxb/backend/v2/pass/{safe}",
        "creationInfo": {
            "created": f"{generated}T00:00:00Z",
            "creators": ["Tool: GXB-V2-direct-SBOM-generator"],
        },
        "packages": packages,
        "annotations": [{
            "annotationType": "OTHER",
            "annotator": "Tool: GXB-V2-direct-SBOM-generator",
            "annotationDate": f"{generated}T00:00:00Z",
            "comment": "Direct pinned/candidate inventory only; transitive resolved SBOM remains a connected-environment gate until go.sum is available.",
        }],
    }


def rendered() -> str:
    return json.dumps(build(), indent=2, sort_keys=False) + "\n"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    want = rendered()
    if args.check:
        if not OUT.exists() or OUT.read_text() != want:
            raise SystemExit("DIRECT SBOM: FAIL (regenerate tools/generate_direct_sbom.py)")
        print("DIRECT SBOM: PASS")
        return 0
    OUT.write_text(want)
    print(OUT)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
