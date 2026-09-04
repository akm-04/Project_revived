"""Pass187 source-bounded White Album persistence owner (MID72/2784/2785).

Effective src_64 keeps normal Album stat calculation client-side. The server
owns only eligibility validation plus durable monotonic claim stages and the
23-slot special-collection claim vector. All effective special rows are type1
stat collections, so no reward RNG or award settlement is introduced here.
"""
from __future__ import annotations
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.white_album_source_catalog import WhiteAlbumSourceCatalog
from .hero_entity_mutation_service import HeroEntityMutationService, HeroEntityMutationError
from .hero_repository import HeroRepository
from .mutation_plan import EntityMutation
from .player_state import PlayerState
from .unit_of_work import OperationContext, PlayerUnitOfWork


class WhiteAlbumService:
    HERO_SLICE = "heroes"
    STATE_SLICE = "white_album_state"

    def __init__(
        self,
        player: PlayerState,
        source: WhiteAlbumSourceCatalog,
        game_data: GameDataCatalog,
        heroes: HeroRepository,
        hero_entities: HeroEntityMutationService,
        uow: PlayerUnitOfWork,
    ) -> None:
        self.player = player
        self.source = source
        self.game_data = game_data
        self.heroes = heroes
        self.hero_entities = hero_entities
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _origin_table_id(self, table_id: Any) -> int:
        tid = self._int(table_id)
        if tid <= 0:
            return 0
        row = self.game_data.maybe_get(ContentRef(CatalogNamespace.PARTNER, tid))
        # Effective utils.getOriginHeroId() only rewrites awakened Normal Girls.
        # Super IDs remain themselves; not every Super row is present in the
        # ordinary PARTNER catalog used by this backend.
        if row is None:
            return tid
        first = self._int(row.get("first_table_id"), 0)
        return first if first > 0 else tid

    def _owned_origins(self) -> set[int]:
        self.heroes.normalize()
        out: set[int] = set()
        for hero in self.player.heroes.values():
            if not isinstance(hero, dict):
                continue
            origin = self._origin_table_id(hero.get("table_id"))
            if origin > 0:
                out.add(origin)
        return out

    def _normal_targets(self, hero: dict[str, Any], origin_id: int) -> tuple[int, int] | None:
        row = self.source.origin(origin_id)
        if row is None:
            return None
        quality = self.source.quality_stages(origin_id)
        stars = self.source.star_stages(origin_id)
        color = max(0, self._int(hero.get("color"), 0))
        star = max(0, self._int(hero.get("star"), 0))
        quality_stage = sum(1 for threshold in quality if color >= threshold)
        star_stage = sum(1 for threshold in stars if star >= threshold)
        return quality_stage, star_stage

    def claim_normal(self, partner_id: Any) -> dict[str, Any]:
        hero = self.heroes.get(partner_id)
        if hero is None:
            return {"error_code": 1, "msg": "white_album_hero_not_owned"}
        origin = self._origin_table_id(hero.get("table_id"))
        targets = self._normal_targets(hero, origin)
        if targets is None:
            return {"error_code": 1, "msg": "white_album_hero_not_catalogued"}
        target_quality, target_star = targets
        current_quality = max(0, self._int(hero.get("collect_quality_stage"), 0))
        current_star = max(0, self._int(hero.get("collect_star_stage"), 0))
        # State-based idempotency: a duplicate response retry is a successful no-op.
        if target_quality <= current_quality and target_star <= current_star:
            return {}
        ctx = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="white_album",
            operation_name="claim_normal",
            protocol_mid=72,
        )
        try:
            with self.uow.transaction(ctx):
                self.hero_entities.apply(EntityMutation(
                    "HERO",
                    self._int(hero.get("partner_id"), self._int(partner_id)),
                    "WHITE_ALBUM_SET_STAGES",
                    counts=(max(current_quality, target_quality), max(current_star, target_star)),
                ))
        except HeroEntityMutationError:
            return {"error_code": 1, "msg": "white_album_stage_mutation_rejected"}
        return {}

    def special_info(self) -> dict[str, Any]:
        raw = self.player.white_album_state if isinstance(self.player.white_album_state, dict) else {}
        claims = raw.get("special_claims") if isinstance(raw.get("special_claims"), dict) else {}
        return {
            "is_award": [1 if self._int(claims.get(str(sid), claims.get(sid, 0)), 0) > 0 else 0
                         for sid in range(1, 24)]
        }

    def claim_special(self, set_id: Any) -> dict[str, Any]:
        sid = self._int(set_id)
        row = self.source.special_set(sid)
        if row is None:
            return {"error_code": 1, "msg": "white_album_special_unknown"}
        # Effective corpus is type1-only; keep the dormant type2 server-award lane fail-closed.
        if self._int(row.get("type"), 0) != 1:
            return {"error_code": 1, "msg": "white_album_special_type_unresolved"}
        raw = self.player.white_album_state if isinstance(self.player.white_album_state, dict) else {}
        claims = raw.get("special_claims") if isinstance(raw.get("special_claims"), dict) else {}
        if self._int(claims.get(str(sid), claims.get(sid, 0)), 0) > 0:
            return {}
        required = set(self.source.special_partner_ids(sid))
        if not required or not required.issubset(self._owned_origins()):
            return {"error_code": 1, "msg": "white_album_special_requirements_not_met"}
        ctx = OperationContext(
            actor_player_id=str(self.player.player_id),
            domain="white_album",
            operation_name="claim_special",
            protocol_mid=2785,
        )
        with self.uow.transaction(ctx):
            state = dict(self.player.white_album_state) if isinstance(self.player.white_album_state, dict) else {}
            next_claims = dict(state.get("special_claims")) if isinstance(state.get("special_claims"), dict) else {}
            next_claims[str(sid)] = 1
            state["special_claims"] = next_claims
            self.player.white_album_state = state
            self.uow.mark_changed(self.STATE_SLICE)
        # Type1 callback consumes no server award payload; stats are updated client-side.
        return {}
