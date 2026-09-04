#!/usr/bin/env python3
from __future__ import annotations

import ast
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"
PKG = ROOT / "gxb_backend"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.campaign_composition import CampaignComposition
from gxb_backend.state.maintenance_services import PlayerMaintenanceServices
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.world_repository import WorldRepository

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def player(pid: str) -> PlayerState:
    p = PlayerState(player_id=pid, account_uid=pid, player_name="Pass129", vip=0)
    p.lev = 1
    p.max_lev = 100
    p.world_map = {
        "normal": [],
        "super": [],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 0,
            "normal_campaign_id": 0,
            "super_chapter_id": 0,
            "super_campaign_id": 0,
            "normal_stars": 0,
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
        },
    }
    return p


def assert_world_identity(root, *, request_uow) -> None:
    world = root.world
    require(world.challenge_catalog is root.challenge_campaign_catalog, "World Challenge catalog drift")
    require(world.challenge_projection is root.challenge_campaign_projection, "World Challenge projection drift")
    require(world.challenge_projection.catalog is world.challenge_catalog, "Challenge projection/catalog split")
    require(world.super_catalog is root.super_campaign_catalog, "World Super catalog drift")
    require(world.super_projection is root.super_campaign_projection, "World Super projection drift")
    require(world.super_access_policy is root.super_campaign_access, "World Super access drift")
    require(world.elite_campaign_unlock is root.elite_campaign_unlock, "World Elite coordinator drift")
    require(world.super_projection.catalog is world.super_catalog, "Super projection/catalog split")
    require(world.super_access_policy.catalog is world.super_catalog, "Super access/catalog split")
    require(
        world.super_access_policy.function_state is root.function_state,
        "Super access/function-state split",
    )
    require(
        world.elite_campaign_unlock.function_state is root.function_state,
        "Elite coordinator/function-state split",
    )
    require(
        world.elite_campaign_unlock.projection is world.super_projection,
        "Elite coordinator/projection split",
    )
    require(world.super_projection.uow is request_uow, "Super projection/UoW mismatch")
    require(world.elite_campaign_unlock.uow is request_uow, "Elite coordinator/UoW mismatch")


def test_request_graph_identity() -> None:
    p = player("9912901")
    commits: list[int] = []
    root = RequestServices(p, DATA, lambda: commits.append(1), catalog=GAME)
    root.campaign_composition.validate(p, root.function_state, uow=root.uow)
    assert_world_identity(root, request_uow=root.uow)
    require(commits == [], "construction unexpectedly persisted request state")


def test_maintenance_graph_identity_and_no_uow() -> None:
    p = player("9912902")
    root = PlayerMaintenanceServices(p, DATA)
    root.campaign_composition.validate(p, root.function_state, uow=None)
    assert_world_identity(root, request_uow=None)


def test_world_strict_mode_rejects_hidden_fallbacks() -> None:
    p = player("9912903")
    try:
        WorldRepository(p, DATA, strict_campaign_collaborators=True)
    except ValueError as exc:
        require("missing collaborators" in str(exc), f"unexpected strict error: {exc}")
    else:
        raise AssertionError("strict WorldRepository silently constructed Campaign collaborators")


def test_world_strict_mode_rejects_parallel_owner_graph() -> None:
    p = player("9912904")
    root = RequestServices(p, DATA, lambda: None, catalog=GAME)
    parallel = CampaignComposition.build(p, DATA, root.function_state, uow=root.uow)
    try:
        WorldRepository(
            p,
            DATA,
            inventory=root.inventory,
            economy=root.economy,
            hero_progression=root.hero_progression,
            catalog=root.catalog,
            challenge_catalog=root.challenge_campaign_catalog,
            challenge_projection=parallel.challenge_projection,
            super_catalog=root.super_campaign_catalog,
            super_access_policy=root.super_campaign_access,
            super_projection=root.super_campaign_projection,
            elite_campaign_unlock=root.elite_campaign_unlock,
            uow=root.uow,
            strict_campaign_collaborators=True,
        )
    except ValueError as exc:
        require("identity mismatch" in str(exc), f"unexpected parallel-owner error: {exc}")
    else:
        raise AssertionError("strict WorldRepository accepted a parallel Challenge owner graph")


def _module_name(path: Path) -> str:
    relative = path.relative_to(ROOT).with_suffix("")
    parts = list(relative.parts)
    if parts[-1] == "__init__":
        parts = parts[:-1]
    return ".".join(parts)


def _resolve_from(current: str, level: int, module: str | None) -> str:
    package = current.rsplit(".", 1)[0] if "." in current else current
    parts = package.split(".") if package else []
    if level:
        trim = max(0, level - 1)
        if trim:
            parts = parts[:-trim]
    if module:
        parts.extend(module.split("."))
    return ".".join(parts)


def _internal_import_graph() -> dict[str, set[str]]:
    files = sorted(PKG.rglob("*.py"))
    modules = {_module_name(path): path for path in files}
    graph = {name: set() for name in modules}
    for name, path in modules.items():
        tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    target = alias.name
                    while target and target not in modules and "." in target:
                        target = target.rsplit(".", 1)[0]
                    if target in modules and target != name:
                        graph[name].add(target)
            elif isinstance(node, ast.ImportFrom):
                target = _resolve_from(name, node.level, node.module)
                candidates = [target]
                for alias in node.names:
                    if alias.name != "*":
                        candidates.append(f"{target}.{alias.name}" if target else alias.name)
                for candidate in candidates:
                    if candidate in modules and candidate != name:
                        graph[name].add(candidate)
    return graph


def _cycles(graph: dict[str, set[str]]) -> list[list[str]]:
    state: dict[str, int] = {}
    stack: list[str] = []
    found: set[tuple[str, ...]] = set()

    def visit(node: str) -> None:
        state[node] = 1
        stack.append(node)
        for nxt in graph[node]:
            if state.get(nxt, 0) == 0:
                visit(nxt)
            elif state.get(nxt) == 1:
                idx = stack.index(nxt)
                cyc = stack[idx:] + [nxt]
                core = cyc[:-1]
                rotations = [tuple(core[i:] + core[:i]) for i in range(len(core))]
                found.add(min(rotations))
        stack.pop()
        state[node] = 2

    for node in graph:
        if state.get(node, 0) == 0:
            visit(node)
    return [list(cycle) for cycle in sorted(found)]


def test_internal_import_graph_remains_acyclic() -> None:
    graph = _internal_import_graph()
    cycles = _cycles(graph)
    require(not cycles, f"internal import cycles introduced: {cycles[:3]}")


def main() -> None:
    tests = [
        test_request_graph_identity,
        test_maintenance_graph_identity_and_no_uow,
        test_world_strict_mode_rejects_hidden_fallbacks,
        test_world_strict_mode_rejects_parallel_owner_graph,
        test_internal_import_graph_remains_acyclic,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS Pass129 architecture hygiene ({len(tests)} tests)")


if __name__ == "__main__":
    main()
