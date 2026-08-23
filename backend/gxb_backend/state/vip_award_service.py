"""VIP1..VIP15 one-time privilege gift lifecycle (MID657, Pass91)."""
from __future__ import annotations

from typing import Any

from gxb_backend.content.game_data_catalog import CatalogNamespace, ContentRef
from gxb_backend.content.vip_award_catalog import VipAwardCatalogError, VipAwardSourceCatalog

from .player_state import PlayerState
from .reward_transaction_service import (
    EconomyGrant,
    InventoryGrant,
    RewardOrigin,
    RewardPlan,
    RewardTransactionService,
    RewardValidationError,
)
from .unit_of_work import OperationContext, PlayerUnitOfWork
from .vip_policy import VipPrivilegeResolver


class VipAwardError(ValueError):
    pass


class VipAwardService:
    MID = 657
    MIN_LEVEL = 1
    MAX_LEVEL = 15
    CLAIM_SLICE = "vip_awards"

    def __init__(
        self,
        player: PlayerState,
        source: VipAwardSourceCatalog,
        privileges: VipPrivilegeResolver,
        rewards: RewardTransactionService,
        uow: PlayerUnitOfWork,
    ) -> None:
        self.player = player
        self.source = source
        self.privileges = privileges
        self.rewards = rewards
        self.uow = uow

    @classmethod
    def normalized_claim_vector(cls, raw: Any) -> list[int]:
        """Return source-shaped VIP1..VIP15 0/1 state without mutating input."""
        out = [0] * cls.MAX_LEVEL
        if isinstance(raw, list):
            for idx, value in enumerate(raw[: cls.MAX_LEVEL]):
                try:
                    out[idx] = 1 if int(value) == 1 else 0
                except (TypeError, ValueError):
                    out[idx] = 0
        elif isinstance(raw, dict):
            # Defensive migration for hand-edited/legacy object forms.  Lua uses
            # one-based numeric VIP indices; preserve only explicit claimed=1.
            for level in range(cls.MIN_LEVEL, cls.MAX_LEVEL + 1):
                value = raw.get(str(level), raw.get(level, 0))
                try:
                    out[level - 1] = 1 if int(value) == 1 else 0
                except (TypeError, ValueError):
                    pass
        return out

    @classmethod
    def normalize_player_claims(cls, player: PlayerState) -> bool:
        raw = getattr(player, "vip_awards", None)
        normalized = cls.normalized_claim_vector(raw)
        canonical = (
            isinstance(raw, list)
            and len(raw) == cls.MAX_LEVEL
            and all(type(value) is int and value in (0, 1) for value in raw)
        )
        if canonical and raw == normalized:
            return False
        player.vip_awards = normalized
        return True

    @staticmethod
    def _level(value: Any) -> int | None:
        try:
            level = int(value)
        except (TypeError, ValueError):
            return None
        return level if 1 <= level <= 15 else None

    def claim(self, requested_level: Any) -> dict[str, Any]:
        level = self._level(requested_level)
        if level is None:
            return {"error_code": 1, "msg": "invalid_vip_award_level", "awards": []}
        if not self.privileges.meets_level(level):
            return {"error_code": 1, "msg": "vip_award_level_not_reached", "awards": []}

        claims = self.normalized_claim_vector(self.player.vip_awards)
        if claims[level - 1] == 1:
            # Natural durable claim-marker idempotency.  The source has no
            # operation ID; a lost-response retry must never grant twice.
            return {"awards": []}

        try:
            tier = self.source.tier(level)
        except VipAwardCatalogError as exc:
            return {"error_code": 1, "msg": str(exc), "awards": []}

        economy = (EconomyGrant("crystal", tier.crystal),) if tier.crystal > 0 else ()
        inventory = tuple(
            InventoryGrant(ContentRef(CatalogNamespace.ITEM, item_id), item_num)
            for item_id, item_num in tier.items
        )
        plan = RewardPlan(
            origin=RewardOrigin(
                "vip",
                "claim_vip_award",
                protocol_mid=self.MID,
                source_table="data/tables/vip.lua -> data/tables/gift.lua",
                source_id=level,
                field_path="reward_item",
            ),
            economy=economy,
            inventory=inventory,
        )
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=self.MID,
            domain="vip",
            operation_name="claim_vip_award",
            idempotency_key=f"vip_award:{level}",
        )

        try:
            with self.uow.transaction(context):
                # Normalize/migrate claim state *inside* the same rollback scope
                # as the gift.  This prevents a partial legacy-state rewrite if
                # the durable reward commit fails.
                self.player.vip_awards = claims
                reward_result = self.rewards.apply(plan)
                self.player.vip_awards[level - 1] = 1
                self.uow.mark_changed(self.CLAIM_SLICE)
                return {"awards": tier.response_awards()}
        except (RewardValidationError, ValueError) as exc:
            return {"error_code": 1, "msg": str(exc), "awards": []}
