"""HTTP realtime room discovery (MID192).

MID192 remains ordinary authenticated HTTP. Chat-bit-range MIDs such as
SEND_CHAT_MESSAGE are routed by the Lua client to TCP and must not become
normal Flask handlers.
"""

from __future__ import annotations

from gxb_backend.realtime.admission import RealtimeRoomDirectory
from gxb_backend.transport.result import EngineTransportResult

from .context import HandlerContext


class ChatHandlers:
    def __init__(
        self,
        ctx: HandlerContext,
        *,
        room_directory: RealtimeRoomDirectory | None = None,
    ) -> None:
        self.ctx = ctx
        self.room_directory = room_directory

    def load_chat_room_info(self, req: dict) -> dict | EngineTransportResult:
        try:
            room_id = int(req.get("room_id", 0))
        except Exception:
            room_id = 0

        directory = self.room_directory
        identity = self.ctx.state.current_realtime_identity()
        try:
            request_region = int(req.get("region", 0) or 0)
        except (TypeError, ValueError):
            request_region = 0
        if (
            directory is None
            or identity is None
            or request_region <= 0
            or int(identity.region) != request_region
        ):
            return EngineTransportResult(body={"error_code": 1}, status_code=409)
        payload = directory.describe(identity, room_id)
        if payload is None:
            # Current source uses HTTP status to decide callback success. Do not
            # invent an unrecovered realtime/login error packet or popup text.
            return EngineTransportResult(body={"error_code": 1}, status_code=409)
        return payload
