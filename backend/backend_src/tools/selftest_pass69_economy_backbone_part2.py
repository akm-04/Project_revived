from __future__ import annotations

import copy
import json
from pathlib import Path

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.state.economy_ledger import InsufficientScalarBalance
from gxb_backend.state.mutation_plan import (
    ActorRef,
    IdempotencySpec,
    MutationOrigin,
    MutationPlan,
    ResourceMutation,
    StackMutation,
)
from gxb_backend.state.mutation_settlement_service import MutationSettlementService
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.reward_transaction_service import (
    EconomyGrant,
    InventoryGrant,
    RewardOrigin,
    RewardPlan,
)
from gxb_backend.state.unit_of_work import OperationContext

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
TEST_ITEM_ID = 130001020


def require(cond: bool, message: str) -> None:
    if not cond:
        raise AssertionError(message)


def make_services() -> tuple[PlayerState, RequestServices, list[int]]:
    player = PlayerState(player_id="990069", account_uid="990069", player_name="Pass69")
    player.mana = 1000
    player.crystal = 100
    player.guild_coin = 50
    player.magic_dust = 3
    player.backpack_items = [{"table_id": TEST_ITEM_ID, "item_num": 2, "time": 0}]
    commits: list[int] = []

    def commit() -> None:
        commits.append(int(player.persistence_state.get("state_version", -1)))

    services = RequestServices(player, DATA, commit, catalog=CATALOG)
    return player, services, commits


def main() -> None:
    player, services, commits = make_services()
    registry = services.resource_registry
    require(len(registry.scalar_keys()) == 30, "ResourceRegistry scalar count drift")
    require(services.economy_ledger.balance("mana") == 1000, "ledger mana read failed")
    require(services.economy_ledger.balance("guild_coin") == 50, "ledger guild coin read failed")

    # 1) Generalized scalar ledger: all 30 descriptors can be credited through
    # one owner without inventing caps or mutating non-scalar resources.
    before_all = services.economy_ledger.snapshot()
    with services.uow.transaction(OperationContext(
        actor_player_id=str(player.player_id),
        domain="selftest",
        operation_name="all_scalar_credit",
        protocol_mid=None,
    )):
        records = services.economy_ledger.apply_deltas({key: 1 for key in registry.scalar_keys()})
        require(len(records) == 30, "not all scalar descriptors mutated")
    require(player.persistence_state["state_version"] == 1, "scalar UoW did not increment state_version once")
    require(player.persistence_state["slice_revisions"].get("scalar_economy") == 1, "scalar slice revision missing")
    for key, old in before_all.items():
        require(services.economy_ledger.balance(key) == old + 1, f"scalar credit failed for {key}")

    # 2) Full preflight: a mixed debit that would overdraw one resource changes
    # nothing and cannot request a durable commit.
    state_before_fail = copy.deepcopy(vars(player))
    commit_count_before = len(commits)
    try:
        with services.uow.transaction(OperationContext(
            actor_player_id=str(player.player_id), domain="selftest", operation_name="insufficient_scalar"
        )):
            services.economy_ledger.apply_deltas({"mana": -1, "guild_coin": -10_000})
        raise AssertionError("insufficient scalar debit unexpectedly succeeded")
    except InsufficientScalarBalance:
        pass
    require(vars(player) == state_before_fail, "insufficient scalar validation mutated player")
    require(len(commits) == commit_count_before, "failed scalar validation committed")

    # 3) Frozen MutationPlan RESOURCE+STACK families settle atomically under one
    # UoW and journal post-state values.
    version_before = services.uow.current_state_version
    plan = MutationPlan(
        schema_version=1,
        plan_id="pass69:selftest:mixed",
        origin=MutationOrigin("selftest", "mixed_debit_credit"),
        actor=ActorRef(str(player.player_id), str(player.account_uid)),
        expected_state_version=version_before,
        idempotency=IdempotencySpec(mode="NONE"),
        preconditions=(),
        operations=(
            ResourceMutation("mana", "DEBIT", 25),
            ResourceMutation("guild_coin", "CREDIT", 7),
            StackMutation(TEST_ITEM_ID, "DEBIT", 1),
        ),
    )
    with services.uow.transaction(OperationContext(
        actor_player_id=str(player.player_id), domain="selftest", operation_name="mixed_settlement"
    )):
        draft = services.mutation_settlement.apply(plan)
        require(len(draft.journal) == 3, "mixed settlement journal size mismatch")
        require(draft.projection.economy["mana"] == player.mana, "cumulative mana projection mismatch")
        require(draft.projection.economy["guild_coin"] == player.guild_coin, "cumulative guild projection mismatch")
    require(services.uow.current_state_version == version_before + 1, "mixed settlement version increment mismatch")
    require(services.inventory.get_item_num(TEST_ITEM_ID) == 1, "stack debit did not persist")
    revisions = player.persistence_state["slice_revisions"]
    require(revisions.get("scalar_economy") == 2, "scalar slice revision did not advance")
    require(revisions.get("backpack_stacks") == 1, "backpack slice revision missing")

    # 4) Legacy RewardPlan adapter now uses MutationPlan for scalar + stack grants
    # while preserving its old return shape.
    version_before_reward = services.uow.current_state_version
    with services.uow.transaction(OperationContext(
        actor_player_id=str(player.player_id), domain="selftest", operation_name="reward_adapter"
    )):
        result = services.rewards.apply(RewardPlan(
            origin=RewardOrigin("selftest", "reward_adapter"),
            economy=(EconomyGrant("mana", 11), EconomyGrant("summon_coin", 4)),
            inventory=(InventoryGrant(ContentRef(CatalogNamespace.ITEM, TEST_ITEM_ID), 3),),
        ))
        require(result.mutation_plan_id is not None, "RewardPlan was not adapted to MutationPlan")
        require(len(result.mutation_journal) == 3, "RewardPlan mutation journal mismatch")
        require(result.economy["mana"] == player.mana, "RewardPlan mana projection mismatch")
        require(result.economy["summon_coin"] == player.summon_coin, "RewardPlan scalar projection mismatch")
        require(result.inventory_awards == [{"item_id": TEST_ITEM_ID, "item_num": 3}], "RewardPlan stack award mismatch")
    require(services.uow.current_state_version == version_before_reward + 1, "RewardPlan did not commit once")
    require(services.inventory.get_item_num(TEST_ITEM_ID) == 4, "RewardPlan inventory grant not committed")

    # 5) Compatibility facade still exposes old Mana/Crystal APIs, but those
    # values are physically owned by the new scalar ledger.
    version_before_facade = services.uow.current_state_version
    old_mana = player.mana
    old_crystal = player.crystal
    with services.uow.transaction(OperationContext(
        actor_player_id=str(player.player_id), domain="selftest", operation_name="legacy_facade"
    )):
        require(services.economy.spend_mana(9, persist=False), "legacy spend_mana failed")
        services.economy.grant_crystal(5, persist=False)
    require(player.mana == old_mana - 9, "legacy Mana facade did not delegate")
    require(player.crystal == old_crystal + 5, "legacy Crystal facade did not delegate")
    require(services.economy_ledger.balance("mana") == player.mana, "ledger/facade Mana divergence")
    require(services.economy_ledger.balance("crystal") == player.crystal, "ledger/facade Crystal divergence")
    require(services.uow.current_state_version == version_before_facade + 1, "legacy facade committed more/less than once")

    mutation_journal = services.uow.consume_journal()
    require(len(mutation_journal) >= 6, "committed mutation journal was not staged")
    require(all("after" in row for row in mutation_journal if isinstance(row, dict)), "journal lacks post-state")

    summary = {
        "pass": "69.0",
        "status": "PASS",
        "resource_registry": {"descriptors": len(registry.keys()), "scalar": len(registry.scalar_keys())},
        "economy_ledger": {
            "all_30_scalar_credit": True,
            "insufficient_multi_resource_atomic": True,
            "legacy_mana_crystal_facade": True,
        },
        "stack_inventory": {
            "typed_debit": True,
            "typed_credit": True,
            "slice_revision": player.persistence_state["slice_revisions"].get("backpack_stacks"),
        },
        "mutation_plan": {
            "resource_stack_settlement": True,
            "reward_plan_adapter": True,
            "committed_journal_rows_seen": len(mutation_journal),
        },
        "state_version": services.uow.current_state_version,
        "commit_callbacks": len(commits),
    }
    print(json.dumps(summary, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
