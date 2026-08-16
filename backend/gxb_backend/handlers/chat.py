"""HTTP chat room discovery.

MID 192 is ordinary HTTP. Chat-bit-range MIDs such as SEND_CHAT_MESSAGE are
routed by the Lua client to TCP and should not become normal Flask handlers.
"""

from __future__ import annotations

from .context import HandlerContext


class ChatHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_chat_room_info(self, req: dict) -> dict:
        try:
            room_id = int(req.get("room_id", 0))
        except Exception:
            room_id = 0
        return {
            "host": self.ctx.settings.chat_host,
            "port": int(self.ctx.settings.chat_port),
            "room_id": room_id,
        }
