"""Center/update handlers."""

from __future__ import annotations

from .context import HandlerContext


class CenterHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def center_discovery(self, req: dict) -> dict:
        return {
            "url": self.ctx.settings.self_url,
            "server_id": 1,
            "back_domain": "",
            "res_download_url": self.ctx.settings.res_download_url if self.ctx.settings.resource_gateway_enabled else "",
        }

    def version_check(self, req: dict) -> dict:
        return {
            "is_appstore": 0,
            "is_inapp": 0,
            "is_review": 0,
            "need_restart": 0,
        }
