"""Source-mapped tutorial summon state for v0.8.1.

This repository intentionally implements only the deterministic fresh-account
summons mapped in Pass 23.  General paid/free gacha, pity, base/super-pool
selection, duplicate conversion, and banner rotation remain unsupported until
their server algorithm is reconstructed.
"""

from __future__ import annotations

import json
import time
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .hero_repository import HeroRepository
from .player_state import PlayerState


SANDBOX_UID = "13371337"


class SummonRepository:
    """Own MID56 state and the two deterministic tutorial MID50 pulls."""

    META_FILE = "tutorial_summon_meta.json"

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path | None = None,
        save_callback: Callable[[], None] | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir or "data")
        self._save_callback = save_callback
        self.meta = self._load_meta()

    def _load_meta(self) -> dict[str, Any]:
        path = self.data_dir / self.META_FILE
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                return data
        except Exception as exc:
            raise RuntimeError(f"cannot load source-derived summon metadata {path}: {exc}") from exc
        raise RuntimeError(f"invalid source-derived summon metadata: {path}")

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _positive_ids(value: Any, minimum: int) -> bool:
        return (
            isinstance(value, list)
            and len(value) >= minimum
            and all(SummonRepository._int(item, 0) > 0 for item in value[:minimum])
        )

    def _is_credential_tutorial_player(self) -> bool:
        uid = str(getattr(self.player, "account_uid", "") or "")
        if not uid or uid == SANDBOX_UID:
            return False
        guide_end = self._int(self.meta.get("guide_ids", {}).get("summon_end"), 100109)
        guide_id = self._int(getattr(self.player, "guide_id", 0), 0)
        # v0.8.0 credential characters can already be stuck inside this guide.
        # After the summon guide is complete we do not retroactively seed it.
        return guide_id <= guide_end

    def _hero_repo(self) -> HeroRepository:
        return HeroRepository(self.player, data_dir=self.data_dir)

    def _ensure_aquaris(self) -> bool:
        """Ensure the fresh tutorial's canonical partner_id=1 Aquaris.

        Do not overwrite a conflicting owned partner.  That would silently
        corrupt an already-established character; fresh v0.8.0 credentials have
        no heroes, so the intended migration path is conflict-free.
        """
        hero_meta = self.meta["heroes"]["aquaris"]
        repo = self._hero_repo()
        repo.normalize()
        wanted_pid = self._int(hero_meta["partner_id"])
        wanted_tid = self._int(hero_meta["table_id"])
        existing = repo.get(wanted_pid)
        if existing is not None:
            return False
        # If Aquaris already exists under a different partner id, do not mint a
        # duplicate. The tutorial requires ID 1, but such a state is outside the
        # v0.8.0 fresh-character migration we are repairing.
        for hero in self.player.heroes.values():
            if self._int(hero.get("table_id"), 0) == wanted_tid:
                return False
        repo.add_owned_hero(
            {
                "partner_id": wanted_pid,
                "table_id": wanted_tid,
                "star": self._int(hero_meta["star"], 1),
                "lev": 1,
                "exp": 0,
                "color": 1,
                "skills": [1, 1, 1, 1, 1, 1],
                "equips": [0, 0, 0, 0, 0, 0],
                "fumos": [0, 0, 0, 0, 0, 0],
                "is_board": 1,
                "board_card": 1,
            },
            persist=False,
        )
        return True

    def normalize(self, *, fresh_credential: bool | None = None) -> bool:
        """Normalize MID56 state and migrate v0.8 tutorial credentials."""
        changed = False
        if not isinstance(self.player.summon, dict):
            self.player.summon = {}
            changed = True
        state = self.player.summon
        display = self.meta["display_policy"]

        for key in ("mana_id", "partner_id", "pet_id"):
            if self._int(state.get(key), 0) <= 0:
                state[key] = self._int(display[key])
                changed = True

        if not self._positive_ids(state.get("main_ids"), 2):
            state["main_ids"] = [self._int(v) for v in display["main_ids"]]
            changed = True
        if not self._positive_ids(state.get("second_ids"), 3):
            state["second_ids"] = [self._int(v) for v in display["second_ids"]]
            changed = True

        tutorial = self._is_credential_tutorial_player() if fresh_credential is None else bool(fresh_credential)
        if tutorial:
            if self._int(state.get("tutorial_seed_version"), 0) < 1:
                state["tutorial_seed_version"] = 1
                state["tutorial_enabled"] = 1
                changed = True
            if "mana_free_time" not in state or self._int(state.get("mana_free_time"), -1) < 0:
                state["mana_free_time"] = 0
                changed = True
            # v0.8.0 wrote future placeholder timestamps. Before either mapped
            # tutorial pull has happened, reset them to source "free ready".
            if not state.get("tutorial_mana_done") and not self._has_expected_hero("lavia"):
                if self._int(state.get("mana_free_time"), 0) != 0:
                    state["mana_free_time"] = 0
                    changed = True
            if "crystal_free_time" not in state or self._int(state.get("crystal_free_time"), -1) < 0:
                state["crystal_free_time"] = 0
                changed = True
            if not state.get("tutorial_crystal_done") and not self._has_expected_hero("pandaria"):
                if self._int(state.get("crystal_free_time"), 0) != 0:
                    state["crystal_free_time"] = 0
                    changed = True
            if "mana_free_num" not in state:
                state["mana_free_num"] = self._int(self.meta["free_state"]["mana_initial_count"], 5)
                changed = True
            if self._ensure_aquaris():
                changed = True
        else:
            now = int(time.time())
            if "mana_free_time" not in state:
                state["mana_free_time"] = now
                changed = True
            if "crystal_free_time" not in state:
                state["crystal_free_time"] = now
                changed = True
            if "mana_free_num" not in state:
                state["mana_free_num"] = 0
                changed = True

        return changed

    def payload(self) -> dict[str, Any]:
        changed = self.normalize()
        if changed:
            self._save()
        state = self.player.summon
        payload: dict[str, Any] = {
            "mana_free_time": self._int(state.get("mana_free_time"), 0),
            "crystal_free_time": self._int(state.get("crystal_free_time"), 0),
            "second_ids": [self._int(v) for v in state.get("second_ids", [])],
            "main_ids": [self._int(v) for v in state.get("main_ids", [])],
            "mana_id": self._int(state.get("mana_id"), 0),
            "pet_id": self._int(state.get("pet_id"), 0),
            "partner_id": self._int(state.get("partner_id"), 0),
            "mana_free_num": max(0, self._int(state.get("mana_free_num"), 0)),
        }
        if self._int(state.get("directional_show_id"), 0) > 0:
            payload["directional_show_id"] = self._int(state["directional_show_id"])
        return payload

    def _has_expected_hero(self, name: str) -> bool:
        meta = self.meta["heroes"][name]
        pid = self._int(meta["partner_id"])
        tid = self._int(meta["table_id"])
        hero = self.player.heroes.get(str(pid)) if isinstance(self.player.heroes, dict) else None
        return isinstance(hero, dict) and self._int(hero.get("table_id"), 0) == tid

    def _hero_result(self, name: str) -> dict[str, Any]:
        meta = self.meta["heroes"][name]
        hero = self._hero_repo().get(self._int(meta["partner_id"]))
        if not isinstance(hero, dict):
            raise RuntimeError(f"tutorial hero {name} is missing after summon mutation")
        result = dict(hero)
        result["is_partner"] = True
        return result

    def _create_expected_hero(self, name: str) -> dict[str, Any]:
        meta = self.meta["heroes"][name]
        repo = self._hero_repo()
        hero = repo.get(self._int(meta["partner_id"]))
        if hero is not None:
            if self._int(hero.get("table_id"), 0) != self._int(meta["table_id"]):
                raise RuntimeError(f"tutorial partner_id conflict for {name}")
            return hero
        return repo.add_owned_hero(
            {
                "partner_id": self._int(meta["partner_id"]),
                "table_id": self._int(meta["table_id"]),
                "star": self._int(meta["star"], 1),
                "lev": 1,
                "exp": 0,
                "color": 1,
                "skills": [1, 1, 1, 1, 1, 1],
                "equips": [0, 0, 0, 0, 0, 0],
                "fumos": [0, 0, 0, 0, 0, 0],
            },
            persist=False,
        )

    def summon_hero(self, req: dict[str, Any]) -> dict[str, Any]:
        """Handle only the two Pass-23 deterministic tutorial pulls."""
        if self.normalize():
            self._save()
        state = self.player.summon
        if self._int(state.get("tutorial_enabled"), 0) != 1:
            return {"error_code": 1}

        summon_type = self._int(req.get("summon_type"), -1)
        summon_index = self._int(req.get("summon_index"), -1)
        if summon_index != 1:
            return {"error_code": 1}
        if summon_type == self._int(self.meta["tutorial_pulls"]["mana"]["summon_type"]):
            return self._tutorial_mana()
        if summon_type == self._int(self.meta["tutorial_pulls"]["crystal"]["summon_type"]):
            return self._tutorial_crystal()
        return {"error_code": 1}

    def _tutorial_mana(self) -> dict[str, Any]:
        state = self.player.summon
        guide_after = self._int(self.meta["guide_ids"]["mana_three"], 100105)
        has_lavia = self._has_expected_hero("lavia")

        # Recovery/idempotency window: if the mutation was persisted but the
        # response/callback was interrupted, return the same owned Hero until
        # the client has persisted the post-summon guide checkpoint.
        if has_lavia:
            if self._int(self.player.guide_id, 0) < guide_after:
                return {
                    "result": [self._hero_result("lavia")],
                    "summon_info": self.payload(),
                }
            return {"error_code": 1}

        if self._int(self.player.guide_id, 0) >= guide_after:
            return {"error_code": 1}
        if self._int(state.get("mana_free_time"), 0) >= 1:
            return {"error_code": 1}
        if self._int(state.get("mana_free_num"), 0) <= 0:
            return {"error_code": 1}

        self._create_expected_hero("lavia")
        now = int(time.time())
        state["mana_free_time"] = now
        state["mana_free_num"] = max(0, self._int(state.get("mana_free_num"), 0) - 1)
        state["tutorial_mana_done"] = 1
        state["tutorial_mana_claimed_at"] = now
        self._save()
        return {
            "result": [self._hero_result("lavia")],
            "summon_info": self.payload(),
        }

    def _tutorial_crystal(self) -> dict[str, Any]:
        state = self.player.summon
        guide_after = self._int(self.meta["guide_ids"]["crystal_three"], 100108)
        has_pandaria = self._has_expected_hero("pandaria")

        if has_pandaria:
            if self._int(self.player.guide_id, 0) < guide_after:
                return {
                    "result": [self._hero_result("pandaria")],
                    "summon_info": self.payload(),
                }
            return {"error_code": 1}

        if self._int(self.player.guide_id, 0) >= guide_after:
            return {"error_code": 1}
        if not (state.get("tutorial_mana_done") or self._has_expected_hero("lavia")):
            return {"error_code": 1}
        if self._int(state.get("crystal_free_time"), 0) >= 1:
            return {"error_code": 1}

        self._create_expected_hero("pandaria")
        now = int(time.time())
        state["crystal_free_time"] = now
        state["tutorial_crystal_done"] = 1
        state["tutorial_crystal_claimed_at"] = now
        self._save()
        return {
            "result": [self._hero_result("pandaria")],
            "summon_info": self.payload(),
        }

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
