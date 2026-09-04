#!/usr/bin/env python3
"""Pass205 Stage A source/protocol reality guard.

Verifies the exact effective src_64 corpus and all Pass204 planning sources that
constrain the Stage A foundation. It also regenerates the source-fact catalog in
memory and asserts byte-equivalent JSON content to the shipped artifact.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from build_awakening_source_catalog import build

EXPECTED_FILE_COUNT = 4370
EXPECTED = {
    "app/model/Task.lua": "d454ae7cb1e28d95d366aae30ba88d83432c974415f263991af6c4190d54bee5",
    "app/windows/TaskAwakeCell.lua": "ff133e4afc528f2c5a31e2ec51a88f3ac9e1d3ab6b137f8ddbdff3dec7671ff6",
    "app/model/NormalHero.lua": "125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9",
    "app/model/SelfPlayer.lua": "163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4",
    "app/common/network/Backend.lua": "95378e2b0be8180df6de27e9e430c630bcfe46c080e1f91ef5f6d74bdbb1b840",
    "app/common/network/mid.lua": "026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af",
    "app/windows/SweepWindow.lua": "8548611ec6bb778433a234f3bdecf452fcde1522c64e8ca9eac5d9a84579fce5",
    "app/windows/NewMapDetailWindow.lua": "88b97be8577828f478360c25fd51674e2ed8291b2a590976b3530c91396d07bf",
    "app/windows/SelectTeamNewWindow.lua": "0fabc7b70c2acf48765c41b414e3cae7504f567cb6fbe344b0f98456ed18667a",
    "app/scenes/BattleCreate.lua": "bb9ae19c20ec165eeb7ba5b81a4ce85b6b7fea3a3a7eb278123bb8c0af0bbef9",
    "app/windows/AwakeTwiceSelectTeamWindow.lua": "5c860b0211739fb80163b2fe174c60117bd178d824fc3a4755c792b629ba19c8",
    "app/scenes/BattleUnlimit.lua": "18379155319fee810eb645bccf0ec299c4fe720ae0380e6c222f596a452dc6be",
    "app/model/Occult.lua": "748c6b2606fdbd0ee434f87b6761a8391df9c5236ccee110e302281651ab2b47",
    "app/windows/OccultWindow.lua": "b26e7a420045e5e2ad3ebf1c7464fe312ce10b9813199367dd6b517f2a2e78d7",
    "app/windows/SkillTipsWindow.lua": "0424173f752e7aacaddf7865459f225bfea784cc2121400b2bf33c892db08f66",
    "app/windows/BackpackWindow.lua": "48b18493fed4186541fc989a8ef60d6338d444c4e8a0fc986903a57e52ff19c1",
    "data/tables/awaken_mission.lua": "fdbcaf96386a7aa775c23b071bfe9952ef6acfc57982d17300b8308417fdb123",
    "data/tables/bloodline_mission.lua": "b773cd8ebb0936c76c7ad0727a5d9efa67e87b748f508c3cd66147f075b81299",
    "data/tables/campaign.lua": "7a58e878a7171839342a856cd74b512037528438259d036009a7249472504683",
    "data/tables/campaign_dropbox.lua": "374b6b13bae56e2f5ac8d6b884821d2fb448d239871d1992b84bcf365e90404e",
    "data/tables/creats_chapter_select.lua": "c4134b5ee3a9861d75f76f6c704e16345c0cb61d6b49adefcdf1f90549d26e3d",
    "data/tables/incubus_mission.lua": "e20084a592aece694376803974377fca17bac2186f83aedb43fdbc85aaa4904e",
    "data/tables/bloodline_incubus.lua": "f94ddd675f3ba1d45f20d8c9df3e9ade37e5bc0bec50c30b66a033ffa1c79b10",
    "data/tables/item.lua": "59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc",
    "data/tables/misc.lua": "058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a",
    "data/tables/zhuge_shop_item.lua": "23d0ad3df95954ffa7b81833e9b2047666200316831b59ecf2006debe95e57e7",
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src-root", required=True, type=Path)
    ap.add_argument("--catalog", type=Path, default=Path(__file__).resolve().parents[1] / "data" / "awakening_source_catalog.json")
    args = ap.parse_args()
    root = args.src_root.resolve()
    census = sum(1 for p in root.rglob("*") if p.is_file())
    if census != EXPECTED_FILE_COUNT:
        raise SystemExit(f"src_64 census drift: {census} != {EXPECTED_FILE_COUNT}")
    checked = []
    for rel, expected in EXPECTED.items():
        path = root / rel
        actual = sha256(path)
        if actual != expected:
            raise SystemExit(f"source hash drift: {rel} {actual} != {expected}")
        checked.append(rel)
    generated = build(root)
    shipped_text = args.catalog.read_text(encoding="utf-8")
    shipped = json.loads(shipped_text)
    generated_text = json.dumps(generated, indent=2, sort_keys=True, ensure_ascii=False) + "\n"
    if generated_text != shipped_text:
        raise SystemExit("awakening_source_catalog.json is not byte-reproducible from effective src_64")
    print(json.dumps({
        "pass": "205.0",
        "stage": "P2-A",
        "status": "PASS",
        "src64_file_count": census,
        "verified_source_files": len(checked),
        "catalog_reproducible": True,
        "route_counts": shipped["counts"],
    }, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
