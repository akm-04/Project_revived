"""System, time, announce, and generic status handlers."""

from __future__ import annotations

import json
import time

from .context import HandlerContext


class SystemHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def query_server_time(self, req: dict) -> dict:
        return {"server_time": int(time.time())}

    def load_user_regions(self, req: dict) -> dict:
        regions = [{"region_id": i, "name": f"Local-{i}", "status": 1} for i in range(1, 11)]
        return {"regions": regions, "players": {}}

    def load_announce(self, req: dict) -> dict:
        # LoginWindow json-decodes this field, so it must be a string.
        return {"contents": json.dumps({})}

    def get_player_group_by_key(self, req: dict) -> str:
        # Callback stores the response itself as a group value.
        return "A"

    def check_game_stat(self, req: dict) -> dict:
        return {}

    def get_pic_notice_info(self, req: dict) -> dict:
        return {"list": []}

    def query_charge_data(self, req: dict) -> dict:
        return {"charges": [], "first_pay": 0}

    def status_only(self, req: dict) -> dict:
        return {}
