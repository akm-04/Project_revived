"""MessagePush preference routes (not realtime transport)."""
from __future__ import annotations
from .context import HandlerContext


class MessagePushHandlers:
    def __init__(self, ctx: HandlerContext) -> None: self.ctx = ctx
    def add(self, req: dict) -> dict: return self.ctx.state.get_services().message_push_preferences.enable(req.get("message_type"))
    def remove(self, req: dict) -> dict: return self.ctx.state.get_services().message_push_preferences.disable(req.get("message_type"))
