"""Request-scoped projection of canonical state changes into Lua response envelopes.

Pass 30 extends the narrow, source-backed global response projector for the Phase-1
Economy/progression spine. It projects established cumulative semantics for
Mana, Crystal, Energy, player EXP/level, Hero EXP, and newly added FunctionIDs.

The projector snapshots canonical state before a handler runs, compares the
same player after the handler finishes, and merges only changed cumulative
values into ``economy_`` / ``exps``. Existing explicit handler projections are
preserved and normalized to the current canonical values.

This is deliberately narrower than SelfPlayer:economySyncEvent_()'s full field
set. In particular, skill_point is excluded because the known MID90 runtime
path must not be forced through a global ECONOMY event until its envelope is
confirmed.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .player_state import PlayerState


@dataclass(frozen=True)
class _PlayerSnapshot:
    player_id: str
    economy: dict[str, int]
    hero_exp: dict[int, int]
    func_ids: tuple[int, ...]


class ResponseProjector:
    """Project changed canonical cumulative state onto an endpoint payload."""

    ECONOMY_FIELDS = ("mana", "crystal", "energy", "exp", "lev")

    def __init__(self, before: _PlayerSnapshot | None) -> None:
        self.before = before

    @classmethod
    def capture(cls, player: PlayerState | None) -> "ResponseProjector":
        if player is None:
            return cls(None)
        economy = {field: cls._int(getattr(player, field, 0)) for field in cls.ECONOMY_FIELDS}
        return cls(_PlayerSnapshot(
            player_id=str(player.player_id),
            economy=economy,
            hero_exp=cls._hero_exp_map(player),
            func_ids=cls._func_ids(player),
        ))

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default


    @classmethod
    def _func_ids(cls, player: PlayerState) -> tuple[int, ...]:
        raw = player.func_ids if isinstance(player.func_ids, list) else []
        values = {cls._int(value) for value in raw if cls._int(value) > 0}
        return tuple(sorted(values))

    @classmethod
    def _hero_exp_map(cls, player: PlayerState) -> dict[int, int]:
        heroes = player.heroes if isinstance(player.heroes, dict) else {}
        if isinstance(heroes.get("heroes"), dict):
            heroes = heroes["heroes"]
        out: dict[int, int] = {}
        for raw_key, raw_hero in heroes.items():
            if not isinstance(raw_hero, dict):
                continue
            partner_id = cls._int(raw_hero.get("partner_id", raw_key), 0)
            if partner_id <= 0:
                continue
            out[partner_id] = max(0, cls._int(raw_hero.get("exp"), 0))
        return out

    def project(self, payload: Any, player: PlayerState | None) -> Any:
        """Merge changed cumulative state into a dictionary response.

        Projection is disabled when there was no request-bound player before the
        handler or when the handler switched to another player (for example MID1
        account-region resolution). That avoids treating bootstrap hydration as a
        mutation diff.
        """
        if not isinstance(payload, dict) or self.before is None or player is None:
            return payload
        if str(player.player_id) != self.before.player_id:
            return payload

        result = dict(payload)
        current_economy = {
            field: self._int(getattr(player, field, 0))
            for field in self.ECONOMY_FIELDS
        }
        changed_economy = {
            field: current_economy[field]
            for field in self.ECONOMY_FIELDS
            if current_economy[field] != self.before.economy.get(field)
        }

        explicit_economy = result.get("economy_")
        if isinstance(explicit_economy, dict):
            merged = dict(explicit_economy)
            # Any Phase-1 field explicitly projected by an older handler is
            # normalized to canonical cumulative state.
            for field in self.ECONOMY_FIELDS:
                if field in merged:
                    merged[field] = current_economy[field]
            merged.update(changed_economy)
            if merged:
                result["economy_"] = merged
        elif changed_economy:
            result["economy_"] = changed_economy

        before_funcs = set(self.before.func_ids)
        current_funcs = set(self._func_ids(player))
        added_funcs = sorted(current_funcs - before_funcs)
        explicit_funcs = result.get("new_funcs_")
        merged_funcs: set[int] = set(added_funcs)
        if isinstance(explicit_funcs, list):
            merged_funcs.update(self._int(value) for value in explicit_funcs if self._int(value) > 0)
        if merged_funcs:
            result["new_funcs_"] = sorted(merged_funcs)

        before_hero_exp = self.before.hero_exp
        current_hero_exp = self._hero_exp_map(player)
        changed_hero_exp = {
            partner_id: exp
            for partner_id, exp in current_hero_exp.items()
            if partner_id in before_hero_exp and exp != before_hero_exp[partner_id]
        }

        explicit_exps = result.get("exps")
        merged_exps: dict[int, dict[str, int]] = {}
        if isinstance(explicit_exps, list):
            for row in explicit_exps:
                if not isinstance(row, dict):
                    continue
                partner_id = self._int(row.get("partner_id"), 0)
                if partner_id <= 0:
                    continue
                merged_exps[partner_id] = {
                    "partner_id": partner_id,
                    "exp": current_hero_exp.get(partner_id, max(0, self._int(row.get("exp"), 0))),
                }
        for partner_id, exp in changed_hero_exp.items():
            merged_exps[partner_id] = {"partner_id": partner_id, "exp": exp}
        if merged_exps:
            result["exps"] = [merged_exps[key] for key in sorted(merged_exps)]

        return result
