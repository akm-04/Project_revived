"""Center/update handlers."""

from __future__ import annotations

from .context import HandlerContext
from gxb_backend.updates.local_update import version_check_payload


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
        return version_check_payload(self.ctx.settings, req)
