#!/usr/bin/env python3
"""I7C-5A source oracle: re-derive the embedded combat corpus from the pinned
archive and confirm the source facts the combat foundation design relies on."""
import hashlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "app-assets/output/assets/src_64/"
EXPECTED = {
    "app/model/NormalHero.lua": "125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9",
    "app/model/SuperHero.lua": "b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622",
    "app/model/Hero.lua": "3e296d4d6dcf71c10ac7391e4ad228ca84c2ee856b7ff2d3c02a3595cf68f2e0",
    "app/model/Item.lua": "af46a18cad788aa903464237821262ffc51fc73db5bb666287407c90922248f5",
    "app/scenes/BattleCreateReport.lua": "397ab8c281fd713050c93592f1b37b35a5702fed45c61fc47f0bc0420d0f0326",
    "lib/battle/battleConfig.lua": "5f89b765bd7326ebd2600a5a3feb4e593aa2bfa4cd283c8918eb593e21053727",
    "lib/battle/requireServer.lua": "b5d6398960e1b67f7806456f7571f5855689aeb3739b73df1e70275b8560f721",
    "lib/battle/BaseFighter.lua": "b1936373a0404049f100de1ab639661d245c9f2a317ae6fbd443b71b45d538dc",
    "app/common/tables/TableParser.lua": "98f70cc1337278f2338d6d2ed6049b2c3b0b26b247ded0a2dd044b6cc62d0586",
    "app/common/tables/HeroTable.lua": "5293207486e52a8dad959b48ea0c90680a335e9144c362d5e9b342b9fd6cef60",
    "lib/battle/fighters/Fenlier.lua": "0b60f74bac2e3fc7cd3b1d10d238f50d055d9b10e41630aa9a1ba38ada7b185d",
    "lib/battle/fighters/Fazheng_Awaken.lua": "d53b827e108eb9b7bbdc8902445eb0cd7c859502a62171aa58689cae14c74991",
}
FACTS = [
    ("app/model/NormalHero.lua", r'if isClient then\s+arg_1_0\.selfPlayer = ', "server branch leaves NormalHero.selfPlayer nil"),
    ("app/model/NormalHero.lua", r'require\("lib\.player\.backpack"\):new\(arg_65_0\.playerID_\)', "server Zhuge book count reads lib.player.backpack"),
    ("app/model/NormalHero.lua", r'hero_collect_attr\[tostring\(arg_111_0\.playerID_\)\]', "replay reads per-player hero_collect_attr"),
    ("app/model/NormalHero.lua", r'arg_3_0\.awakeTwiceStage_ = tonumber\(arg_3_1\.twice_awake_stage\) or 0', "twice_awake_stage defaults to 0 when absent"),
    ("app/model/NormalHero.lua", r'conquer_lev = arg_6_0\.conquerSchoolLev', "toParams emits conquer_lev"),
    ("app/model/SuperHero.lua", r'return arg_108_0:getEquipEnhanceAttr\(arg_108_1\)', "Super equipment uses enhance attributes"),
    ("app/model/Item.lua", r'tables\.superEquipEnhance:getRate', "enhanced Super equipment reads superEquipEnhance"),
    ("lib/battle/requireServer.lua", r'"lib\.battle\.fighters\."', "server fighters resolve under lib.battle.fighters"),
    ("lib/battle/BaseFighter.lua", r'if var_0_2\.BattleType\.CreateReport == var_0_1\.ctx\.battle\.battleType or arg_158_2 < 1 then\s+return', "shake returns before tables.shake in CreateReport"),
    ("app/common/tables/TableParser.lua", r'\["monster\.lua"\] = true', "monster table is a per-row indexed table"),
    ("app/common/tables/HeroTable.lua", r'lib\.battle\.app\.common\.tables\.TableParser"\)\.parse\("monster", var_0_0\.handler\(arg_1_0, arg_1_0\.serverParseMonster\)\)', "server HeroTable parses monster rows through the missing server TableParser"),
    ("app/scenes/BattleCreateReport.lua", r'arg_43_0\.report_\.star = arg_43_0:getBattleStar\(\)', "writeReport records the battle star"),
    ("lib/battle/fighters/Fenlier.lua", r'function var_0_3\.init\(arg_1_0\)\s+var_0_3\.super\.init\(arg_1_0\)\s+arg_1_0\.angerCount = 0\s+arg_1_0:initAngerProgress\(\)', "Fenlier init reaches client UI unconditionally"),
]


def main() -> int:
    archive = Path(sys.argv[1])
    with archive.open("rb") as f:
        if hashlib.file_digest(f, "sha256").hexdigest() != "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf":
            print("I7C5A SOURCE ORACLE: FAIL archive identity")
            return 1
    with zipfile.ZipFile(archive) as z:
        for name, digest in EXPECTED.items():
            if hashlib.sha256(z.read(PREFIX + name)).hexdigest() != digest:
                print("I7C5A SOURCE ORACLE: FAIL member", name)
                return 1
        for name, pattern, fact in FACTS:
            if not re.search(pattern, z.read(PREFIX + name).decode("utf-8-sig")):
                print("I7C5A SOURCE ORACLE: FAIL fact", fact)
                return 1
    corpus = subprocess.run([sys.executable, "-I", str(ROOT / "tools/generate_combat_corpus.py"), "--check", "--source-archive", str(archive)], capture_output=True, text=True)
    print(corpus.stdout.strip())
    if corpus.returncode != 0:
        print(corpus.stderr.strip())
        print("I7C5A SOURCE ORACLE: FAIL corpus re-derivation")
        return 1
    print(f"I7C5A SOURCE ORACLE: PASS exact{len(EXPECTED)} members; {len(FACTS)} design facts; corpus re-derived from archive")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
