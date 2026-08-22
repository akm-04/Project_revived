from __future__ import annotations

import copy
import json
from pathlib import Path

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.state.mutation_plan import (
    ActorRef,
    IdempotencySpec,
    MutationOrigin,
    MutationPlan,
    ResourceMutation,
    StackMutation,
)
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.projection_profiles import ProjectionProfileRegistry
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.response_projector import ResponseProjector
from gxb_backend.state.unit_of_work import OperationContext

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
TEST_ITEM_ID = 130001020


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def make_services() -> tuple[PlayerState, RequestServices, list[int]]:
    player = PlayerState(player_id="990700", account_uid="990700", player_name="Pass70")
    player.mana = 1000
    player.crystal = 100
    player.guild_coin = 50
    player.backpack_items = [{"table_id": TEST_ITEM_ID, "item_num": 1, "time": 0}]
    commits: list[int] = []

    def commit() -> None:
        commits.append(int(player.persistence_state.get("state_version", -1)))

    return player, RequestServices(player, DATA, commit, catalog=CATALOG), commits


def settle_resource_stack(services: RequestServices, *, plan_id: str, operations) -> None:
    plan = MutationPlan(
        schema_version=1,
        plan_id=plan_id,
        origin=MutationOrigin("selftest", plan_id, protocol_mid=33),
        actor=ActorRef(str(services.player.player_id), str(services.player.account_uid)),
        expected_state_version=services.uow.current_state_version,
        idempotency=IdempotencySpec(mode="NONE"),
        preconditions=(),
        operations=tuple(operations),
    )
    with services.uow.transaction(OperationContext(
        actor_player_id=str(services.player.player_id),
        domain="selftest",
        operation_name=plan_id,
        protocol_mid=33,
    )):
        services.mutation_settlement.apply(plan)


def main() -> None:
    player, services, commits = make_services()
    profiles = ProjectionProfileRegistry.load(DATA / "projection_profile_registry.json")
    require(len(profiles.all()) == 8, "frozen projection profile count drift")
    require(profiles.resolve(mid=33, label="BUY_SHOP", transport="engine_web").profile_id == "SHOP", "SHOP profile resolution failed")
    require(profiles.resolve(mid=817, label="PET_CAMPAIGN_SWEEP", transport="engine_web").profile_id == "PET_CAMPAIGN", "PetCampaign profile resolution failed")
    require(profiles.resolve(mid=36857, label="RECHARGE", transport="tcp_chat_or_push").profile_id == "RECHARGE_PUSH", "Recharge profile resolution failed")
    require(profiles.resolve(mid=82, label="SELL_ITEM", transport="engine_web").profile_id == "WEB_GLOBAL_ENVELOPE", "default web profile resolution failed")

    # 1) Journal RESOURCE is primary and projects a non-legacy scalar key.
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    settle_resource_stack(
        services,
        plan_id="journal_primary",
        operations=(ResourceMutation("guild_coin", "CREDIT", 7),),
    )
    # Pass69 semantic bus remains present as a compatibility bridge. Deliberately
    # corrupt its cumulative value to prove the committed journal wins.
    payload = services.apply_semantic_deltas({"economy_": {"guild_coin": -999}})
    journal = services.uow.consume_journal()
    result = projector.project(
        payload,
        player,
        committed_journal=journal,
        profile=profiles.resolve(mid=82, label="SELL_ITEM", transport="engine_web"),
    )
    require(result["economy_"] == {"guild_coin": 57}, "journal did not win cumulative scalar projection")
    require(len(result["economy_"]) == 1, "projector fabricated untocuhed economy fields")

    # 2) Journal STACK credits never become generic awards. SHOP explicitly has
    # local Backpack reconciliation in current Lua.
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    settle_resource_stack(
        services,
        plan_id="shop_stack_credit",
        operations=(
            ResourceMutation("mana", "DEBIT", 25),
            StackMutation(TEST_ITEM_ID, "CREDIT", 2),
        ),
    )
    payload = services.apply_semantic_deltas({"shop_type": 1, "index": 2, "buy_times": 1})
    journal = services.uow.consume_journal()
    shop_profile = profiles.resolve(mid=33, label="BUY_SHOP", transport="engine_web")
    result = projector.project(payload, player, committed_journal=journal, profile=shop_profile)
    require(result["economy_"]["mana"] == 975, "SHOP cumulative Mana projection incorrect")
    require("awards" not in result, "SHOP journal stack credit was incorrectly synthesized as awards")
    require(result["shop_type"] == 1 and result["buy_times"] == 1, "profile stripped legacy handler body")
    require(shop_profile.local_inventory_reconciliation, "SHOP local reconciliation flag missing")

    # 3) Rollback journal is silent and canonical state is restored.
    state_before = copy.deepcopy(vars(player))
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    try:
        plan = MutationPlan(
            schema_version=1,
            plan_id="rollback_silent",
            origin=MutationOrigin("selftest", "rollback_silent"),
            actor=ActorRef(str(player.player_id), str(player.account_uid)),
            expected_state_version=services.uow.current_state_version,
            idempotency=IdempotencySpec(mode="NONE"),
            preconditions=(),
            operations=(ResourceMutation("mana", "CREDIT", 123),),
        )
        with services.uow.transaction(OperationContext(
            actor_player_id=str(player.player_id), domain="selftest", operation_name="rollback_silent"
        )):
            services.mutation_settlement.apply(plan)
            raise RuntimeError("force rollback")
    except RuntimeError:
        pass
    require(vars(player) == state_before, "rollback failed to restore player")
    require(services.uow.consume_journal() == [], "rolled-back journal leaked")
    require(services.uow.consume_semantic() == {}, "rolled-back semantic bridge leaked")
    result = projector.project({}, player, committed_journal=[], profile=profiles.get("WEB_GLOBAL_ENVELOPE"))
    require("economy_" not in result, "rollback fabricated economy response")

    # 4) Legacy fallback remains for an unmigrated temporal field, cumulative not delta.
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    player.energy = int(player.energy) - 3
    result = projector.project({}, player, committed_journal=[], profile=profiles.get("WEB_GLOBAL_ENVELOPE"))
    require(result.get("economy_", {}).get("energy") == int(player.energy), "legacy energy fallback lost")
    require(len(result["economy_"]) == 1, "legacy fallback fabricated a full economy envelope")

    # 5) RECHARGE_PUSH suppresses automatic ordinary-web journal projection but
    # preserves an already-domain-owned nested body untouched.
    recharge_profile = profiles.get("RECHARGE_PUSH")
    fake_journal = [{
        "seq": 1,
        "owner": "EconomyLedger",
        "category": "RESOURCE",
        "subject": {"resource_key": "crystal"},
        "action": "CREDIT",
        "before": 100,
        "after": 200,
        "delta": 100,
        "projection_tags": ["economy_"],
    }]
    nested = {"params": {"params": {"total": 200, "vip": 1, "charge": 6}}}
    result = projector.project(nested, player, committed_journal=fake_journal, profile=recharge_profile)
    require(result == nested, "RECHARGE_PUSH was forced into ordinary web projection")
    require("economy_" not in result, "RECHARGE_PUSH leaked ordinary economy_ envelope")

    # 6) Explicit legacy economy field is normalized, and journal collision wins.
    projector = ResponseProjector.capture(player, resource_registry=services.resource_registry)
    settle_resource_stack(
        services,
        plan_id="collision",
        operations=(ResourceMutation("mana", "CREDIT", 5),),
    )
    services.apply_semantic_deltas({})  # consume bridge; journal remains primary input
    journal = services.uow.consume_journal()
    result = projector.project(
        {"economy_": {"mana": -5}},
        player,
        committed_journal=journal,
        profile=profiles.get("WEB_GLOBAL_ENVELOPE"),
    )
    require(result["economy_"]["mana"] == int(player.mana), "collision did not resolve to canonical post-commit Mana")

    summary = {
        "pass": "70.0",
        "status": "PASS",
        "profiles": len(profiles.all()),
        "journal_primary": True,
        "nonlegacy_scalar_journal_projection": True,
        "cumulative_not_delta": True,
        "zero_filled_47_field_envelope": False,
        "stack_awards_synthesized": False,
        "shop_local_reconciliation_protected": True,
        "rollback_journal_silent": True,
        "legacy_five_field_fallback_preserved": True,
        "recharge_nested_profile_preserved": True,
        "commit_callbacks": len(commits),
        "state_version": services.uow.current_state_version,
    }
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
