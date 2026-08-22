"""Read-only projection of committed canonical state into Lua response envelopes.

Pass70 makes the committed PlayerUnitOfWork mutation journal the primary source
for migrated RESOURCE projection. Pass71 extends the same contract to TEMPORAL
resource-owner journal rows while preserving the earlier five-field
before/after projector as a compatibility fallback for unmigrated handlers.
Projection is constrained by a per-MID/transport ProjectionProfile: journal
facts describe *what committed*, while the profile owns *what may be emitted*.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Iterable, Mapping

from .player_state import PlayerState
from .projection_profiles import ProjectionProfile
from .resource_registry import ResourceRegistry


@dataclass(frozen=True)
class _PlayerSnapshot:
    player_id: str
    economy: dict[str, int]
    hero_exp: dict[int, int]


class ResponseProjector:
    """Project committed cumulative state onto one endpoint payload.

    Journal RESOURCE entries win on collision.  Legacy diff projection remains
    intentionally narrow and is used only for the historical five fields until
    their owning migrations are completed.  No STACK journal row is converted
    into generic ``awards`` by this class.
    """

    LEGACY_DIFF_ECONOMY_FIELDS = ("mana", "crystal", "energy", "exp", "lev")

    def __init__(
        self,
        before: _PlayerSnapshot | None,
        *,
        resource_registry: ResourceRegistry | None = None,
    ) -> None:
        self.before = before
        self.resource_registry = resource_registry

    @classmethod
    def capture(
        cls,
        player: PlayerState | None,
        *,
        resource_registry: ResourceRegistry | None = None,
    ) -> "ResponseProjector":
        if player is None:
            return cls(None, resource_registry=resource_registry)
        economy = {
            field: cls._int(getattr(player, field, 0))
            for field in cls.LEGACY_DIFF_ECONOMY_FIELDS
        }
        return cls(
            _PlayerSnapshot(
                player_id=str(player.player_id),
                economy=economy,
                hero_exp=cls._hero_exp_map(player),
            ),
            resource_registry=resource_registry,
        )

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

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

    def _journal_economy(
        self,
        journal: Iterable[Mapping[str, Any]] | None,
        player: PlayerState,
        profile: ProjectionProfile | None,
    ) -> dict[str, int]:
        if not journal or (profile is not None and not profile.allows_economy):
            return {}
        projected: dict[str, int] = {}
        for row in journal:
            if not isinstance(row, Mapping):
                continue
            category = str(row.get("category") or "").upper()
            if category not in {"RESOURCE", "TEMPORAL"}:
                continue
            tags = row.get("projection_tags")
            if isinstance(tags, str):
                tag_values = {tags}
            elif isinstance(tags, (list, tuple, set, frozenset)):
                tag_values = {str(v) for v in tags}
            else:
                tag_values = set()
            if "economy_" not in tag_values:
                continue
            subject = row.get("subject")
            if not isinstance(subject, Mapping):
                continue
            key = str(subject.get("resource_key") or "").strip()
            if not key:
                continue
            if self.resource_registry is not None:
                desc = self.resource_registry.get(key)
                if desc is None:
                    continue
                if str(desc.projection_strategy) != "ECONOMY_CUMULATIVE_POST_COMMIT_VALUE":
                    continue
                if str(desc.projection_path) != f"economy_.{key}":
                    continue
            # Canonical PlayerState wins over a stale/forged row when the
            # registered storage attribute is directly materialized there.
            after = row.get("after")
            fallback_after = after.get("balance", 0) if isinstance(after, Mapping) else after
            if hasattr(player, key):
                value = self._int(getattr(player, key), self._int(fallback_after, 0))
            else:
                value = self._int(fallback_after, 0)
            projected[key] = max(0, value)
        return projected

    def _legacy_changed_economy(self, player: PlayerState) -> dict[str, int]:
        if self.before is None or str(player.player_id) != self.before.player_id:
            return {}
        current = {
            field: self._int(getattr(player, field, 0))
            for field in self.LEGACY_DIFF_ECONOMY_FIELDS
        }
        return {
            field: current[field]
            for field in self.LEGACY_DIFF_ECONOMY_FIELDS
            if current[field] != self.before.economy.get(field)
        }

    def project(
        self,
        payload: Any,
        player: PlayerState | None,
        *,
        committed_journal: Iterable[Mapping[str, Any]] | None = None,
        profile: ProjectionProfile | None = None,
    ) -> Any:
        """Merge only source/profile-authorized cumulative state into payload.

        Existing handler fields are preserved.  The projector adds only touched
        journal/diff keys, so it can never fabricate a zero-filled 47-key
        ``economy_`` envelope.  Journal values are applied last and therefore
        supersede legacy handler/diff values on collision.
        """
        if not isinstance(payload, dict) or player is None:
            return payload
        if self.before is not None and str(player.player_id) != self.before.player_id:
            # Account/region bootstrap switched canonical players. Do not treat
            # hydration of the new player as a mutation diff.
            return payload

        result = dict(payload)
        profile_allows_economy = profile is None or "economy_" in profile.global_fields
        journal_economy = self._journal_economy(committed_journal, player, profile)
        legacy_changed = self._legacy_changed_economy(player) if profile_allows_economy else {}

        explicit_economy = result.get("economy_")
        merged_economy: dict[str, Any] = (
            dict(explicit_economy) if isinstance(explicit_economy, dict) else {}
        )
        if profile_allows_economy:
            # Preserve the historical compatibility behavior: an older handler
            # explicitly naming one of the five fields gets normalized to the
            # canonical cumulative value.
            for field in self.LEGACY_DIFF_ECONOMY_FIELDS:
                if field in merged_economy:
                    merged_economy[field] = self._int(getattr(player, field, 0))
            for key, value in legacy_changed.items():
                merged_economy.setdefault(key, value)
            # Primary migrated semantics: committed journal wins on collision.
            merged_economy.update(journal_economy)
            if merged_economy:
                result["economy_"] = merged_economy
        # A profile can suppress *automatic* ordinary-web economy projection
        # (RECHARGE_PUSH). Existing domain output is preserved by design.

        if self.before is not None:
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
                        "exp": current_hero_exp.get(
                            partner_id, max(0, self._int(row.get("exp"), 0))
                        ),
                    }
            for partner_id, exp in changed_hero_exp.items():
                merged_exps[partner_id] = {"partner_id": partner_id, "exp": exp}
            if merged_exps:
                result["exps"] = [merged_exps[key] for key in sorted(merged_exps)]

        return result
