"""Canonical MessagePush preference owner (Wave C)."""
from __future__ import annotations

from .unit_of_work import OperationContext, PlayerUnitOfWork


class MessagePushPreferenceService:
    def __init__(self, player, catalogs, uow: PlayerUnitOfWork, server_clock) -> None:
        self.player = player
        self.catalogs = catalogs
        self.uow = uow
        self.server_clock = server_clock

    def enabled(self) -> list[int]:
        return sorted({int(v) for v in self.player.message_pushes if self.catalogs.message_push_type(int(v)) is not None})

    def enable(self, message_type) -> dict:
        return self._set(message_type, True, mid=1025, operation="enable")

    def disable(self, message_type) -> dict:
        return self._set(message_type, False, mid=1026, operation="disable")

    def _set(self, raw, enabled: bool, *, mid: int, operation: str) -> dict:
        try: message_type = int(raw)
        except (TypeError, ValueError): message_type = 0
        if self.catalogs.message_push_type(message_type) is None:
            return {"error_code": 1, "msg": "unsupported_message_push_type"}
        current = set(self.enabled())
        target = set(current)
        if enabled: target.add(message_type)
        else: target.discard(message_type)
        if target == current:
            return {}
        context = OperationContext(
            actor_player_id=str(self.player.player_id), domain="message_push_preferences",
            operation_name=operation, protocol_mid=mid, server_time=int(self.server_clock.now()),
        )
        with self.uow.transaction(context):
            self.player.message_pushes = sorted(target)
            self.uow.touch_slice("message_push_preferences")
            self.uow.request_save()
        return {}
