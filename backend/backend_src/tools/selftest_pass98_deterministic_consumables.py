from __future__ import annotations

import json
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from types import SimpleNamespace

from gxb_backend.content import GameDataCatalog
from gxb_backend.handlers.inventory import InventoryHandlers
from gxb_backend.handlers.practice import PracticeHandlers
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
ITEM_SHA = "59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


class _State:
    def __init__(self, services: RequestServices) -> None:
        self.services = services

    def get_services(self) -> RequestServices:
        return self.services

    def get_player(self) -> PlayerState:
        return self.services.player


def services(items: dict[int, int]) -> tuple[PlayerState, RequestServices, list[int]]:
    player = PlayerState(player_id="9898001", account_uid="9898001", player_name="Pass98")
    player.lev = 100
    player.max_lev = 100
    player.energy = 100
    player.max_energy = 160
    player.energy_time = 0
    player.backpack_items = [
        {"table_id": int(item_id), "item_num": int(count), "time": 0}
        for item_id, count in items.items()
    ]
    commits: list[int] = []
    svc = RequestServices(
        player,
        DATA,
        lambda: commits.append(int(player.persistence_state.get("state_version", 0))),
        catalog=CATALOG,
    )
    return player, svc, commits


def main() -> None:
    raw = json.loads((DATA / "consumable_effect_meta.json").read_text(encoding="utf-8"))
    meta = raw["_meta"]
    require(meta["source_sha256"] == ITEM_SHA, "consumable source hash drift")
    require(meta["source_item_rows"] == 5838, "item row count drift")
    require(meta["consumable_rows"] == 2034, "consumable row count drift")
    require(meta["energy_item_count"] == 22, "Energy consumable count drift")
    require(meta["magic_item_count"] == 12, "Magic consumable count drift")

    # The Pass97 bug was catalog provenance drift: generic catalog had Kanto=0.
    require(int(CATALOG.row("item", 50001015).get("energy", 0) or 0) == 0, "baseline Kanto drift unexpectedly disappeared")

    player, svc, commits = services({
        50001015: 3,  # Kanto Food = +18 Energy
        50001016: 2,  # Tonkatsu = +30 Energy
        50001120: 4,  # +20 Magic Energy
        50001124: 5,  # +2000 Magic Dust
        50001128: 3,  # +2000 Magic Liquid
        160200111: 2, # missing Pass97 Honor Inscription variant
    })
    ctx = SimpleNamespace(state=_State(svc))
    inventory = InventoryHandlers(ctx)

    require(svc.consumable_effects.energy_effect(50001015) == 18, "Kanto source effect missing")
    require(svc.consumable_effects.energy_effect(50001016) == 30, "Tonkatsu source effect missing")

    # MID27: deterministic STACK debit + TEMPORAL credit in one UoW.
    result = inventory.use_energy_item({"item_id": 50001015, "item_num": 2})
    require(result == {}, "Kanto MID27 rejected")
    require(svc.stack_inventory.quantity(50001015) == 1, "Kanto stack debit wrong")
    require(player.energy == 136, "Kanto Energy credit wrong")
    journal = svc.uow.consume_journal()
    require(any(row.get("category") == "STACK" and row.get("subject", {}).get("item_id") == 50001015 for row in journal), "MID27 STACK journal missing")
    require(any(row.get("category") == "TEMPORAL" and row.get("subject", {}).get("resource_key") == "energy" for row in journal), "MID27 TEMPORAL journal missing")

    # Source Energy credit can exceed natural regen cap; cap is not a hard max.
    result = inventory.use_energy_item({"item_id": 50001016, "item_num": 1})
    require(result == {}, "Tonkatsu MID27 rejected")
    require(player.energy == 166, "Energy consumable overflow semantics wrong")
    require(svc.temporal.state("energy").natural_cap == 160, "Energy natural cap drift")
    svc.uow.consume_journal()

    # MID87: mixed magic items settle all stacks/resources atomically.
    before_magic = (player.magic_energy, player.magic_dust, player.magic_liquid)
    result = inventory.use_magic_items({"items": [
        {"item_id": 50001120, "item_num": 2},
        {"item_id": 50001124, "item_num": 3},
        {"item_id": 50001128, "item_num": 1},
    ]})
    require(result == {}, "MID87 valid magic settlement rejected")
    require((player.magic_energy, player.magic_dust, player.magic_liquid) == (before_magic[0] + 40, before_magic[1] + 6000, before_magic[2] + 2000), "MID87 resource credits wrong")
    require(svc.stack_inventory.quantity(50001120) == 2, "Magic Energy item debit wrong")
    require(svc.stack_inventory.quantity(50001124) == 2, "Magic Dust item debit wrong")
    require(svc.stack_inventory.quantity(50001128) == 2, "Magic Liquid item debit wrong")
    journal = svc.uow.consume_journal()
    resource_keys = {row.get("subject", {}).get("resource_key") for row in journal if row.get("category") == "RESOURCE"}
    require({"magic_energy", "magic_dust", "magic_liquid"}.issubset(resource_keys), "MID87 RESOURCE journals missing")

    # A mixed invalid MID87 request must not partially debit/grant anything.
    snap = (
        svc.stack_inventory.quantity(50001120), svc.stack_inventory.quantity(50001015),
        player.magic_energy, player.magic_dust, player.magic_liquid,
    )
    result = inventory.use_magic_items({"items": [
        {"item_id": 50001120, "item_num": 1},
        {"item_id": 50001015, "item_num": 1},
    ]})
    require(result.get("error_code") == 1, "MID87 accepted non-magic item")
    require(snap == (
        svc.stack_inventory.quantity(50001120), svc.stack_inventory.quantity(50001015),
        player.magic_energy, player.magic_dust, player.magic_liquid,
    ), "MID87 invalid request partially mutated state")
    require(svc.uow.consume_journal() == [], "MID87 invalid request emitted journal")

    # Pass98 item.lua.inscript_id completion: Honor ...111/112 variants now resolve.
    adv = json.loads((DATA / "hero_advanced_progression_meta.json").read_text(encoding="utf-8"))
    require(len(adv["inscription_item_to_type"]) == 254, "complete Inscription item mapping count wrong")
    require(adv["inscription_item_to_type"].get("160200111") == 20001, "Honor 160200111 mapping missing")
    before_grad = player.graduate_cer
    result = svc.hero_advanced.inscription_resolve({"item_id": 160200111, "resolve_num": 1})
    require(result == {}, "source-valid Honor Inscription resolve rejected")
    require(svc.stack_inventory.quantity(160200111) == 1, "Honor Inscription debit wrong")
    require(player.graduate_cer == before_grad + 90, "Honor Inscription certificate credit wrong")
    svc.uow.consume_journal()

    # MID134 must no longer acknowledge a mutation it cannot persist.
    practice = PracticeHandlers(ctx)
    pet_before = list(player.backpack_items)
    result = practice.pet_use_exp_items_fail_closed({"pet_id": 1, "items": [{"item_id": 50001015, "item_num": 1}]})
    require(result.get("error_code") == 1, "MID134 false-success hazard remains")
    require(player.backpack_items == pet_before, "MID134 fail-close mutated Backpack")

    # MID241 remains outside the audited empty-ACK list and therefore continues
    # through compat.blocked_unknown until RandomOutcomeService/gift policy exists.
    safe = json.loads((DATA / "compatibility_safe_mids.json").read_text(encoding="utf-8"))["safe_empty_ack_mids"]
    require("241" not in safe, "MID241 accidentally became safe-empty-ACK")

    require(len(commits) >= 4, "expected committed deterministic transactions missing")
    print(json.dumps({
        "pass": "98.0",
        "status": "PASS",
        "source_authoritative_consumable_catalog": True,
        "mid27_energy_items": 22,
        "mid87_magic_items": 12,
        "mid1404_item_mapping": 254,
        "mid134_fail_closed": True,
        "mid241_random_gifts_fail_closed": True,
    }, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
