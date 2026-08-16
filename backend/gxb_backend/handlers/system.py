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
        """Return the complete RegionWindow-safe MID18 shape.

        LoginWindow itself only reads ``regions``/``players``, which is why the
        earlier Pass 19 surface map stopped there.  RegionWindow consumes more:
        ``recall_regions`` must be a table, each region needs ``max_player_id``
        and ``cur_id`` for the full/hot/new indicator, and ``players`` is sorted
        as an array of per-region character records.

        The field names are source-confirmed.  Capacity values for unobserved
        official regions are compatibility defaults, not recovered live data.
        """
        player = self.ctx.state.get_player()

        regions = []
        for i in range(1, 201):
            regions.append({
                "region_id": i,
                "name": "Deep Valley" if i == 125 else f"Local-{i}",
                "status": 1,
                # RegionWindow.lua compares these numerically before rendering.
                # Exact official counts were not present in the supplied dumps.
                "cur_id": 1 if i == int(player.region) else 0,
                "max_player_id": 999999999,
            })

        try:
            player_numeric_id = int(player.player_id)
        except (TypeError, ValueError):
            player_numeric_id = 0

        players = [{
            "id": player_numeric_id,
            "player_id": player_numeric_id,
            "name": player.player_name,
            "region": int(player.region),
            "lev": int(player.lev),
            "vip": int(player.vip),
            "avatar_id": int(player.avatar_id),
            "avatar_frame_id": int(player.avatar_frame_id),
            "conquer_lev": int(player.conquer_lev),
            "conquer_loop_id": int(player.conquer_loop_id),
        }]

        print(
            "[REGIONS] "
            f"sid={req.get('sid')!r} regions={len(regions)} "
            f"players={len(players)} current={player.region}/{player.player_name}"
        )
        return {
            "regions": regions,
            "players": players,
            "recall_regions": [],
        }

    def load_announce(self, req: dict) -> dict:
        # LoginWindow json-decodes this field, so it must be a string.
        return {"contents": json.dumps({})}

    def get_player_group_by_key(self, req: dict) -> str:
        # Callback stores the response itself as a group value.
        return "A"

    def check_game_stat(self, req: dict) -> dict:
        return {}

    def get_pic_notice_info(self, req: dict) -> dict:
        # MainScene's ordered popup chain reads has_read + contents directly.
        # Established-profile default: nothing unread, so do not open a modal.
        return {"has_read": 1, "contents": []}

    def query_charge_data(self, req: dict) -> dict:
        return {"charges": [], "first_pay": 0, "list": []}

    def generate_player_name(self, req: dict) -> dict:
        return {"name": self.ctx.state.get_player().player_name}

    def edit_player_name(self, req: dict) -> dict:
        name = req.get("player_name") or req.get("name")
        if name:
            self.ctx.state.get_player().player_name = str(name)
            self.ctx.state.save()
        return {"player_name": self.ctx.state.get_player().player_name}

    def set_avatar_id(self, req: dict) -> dict:
        try:
            self.ctx.state.get_player().avatar_id = int(req.get("avatar_id", self.ctx.state.get_player().avatar_id))
            self.ctx.state.save()
        except Exception:
            pass
        return {}

    def edit_avatar_frame(self, req: dict) -> dict:
        try:
            self.ctx.state.get_player().avatar_frame_id = int(req.get("avatar_frame_id", self.ctx.state.get_player().avatar_frame_id))
            self.ctx.state.save()
        except Exception:
            pass
        return {}

    def get_comment_award(self, req: dict) -> dict:
        return {"awards": []}

    def get_maxlevel(self, req: dict) -> dict:
        return {"max_lev": self.ctx.state.get_player().max_lev, "max_color": self.ctx.state.get_player().max_color}

    def status_only(self, req: dict) -> dict:
        return {}
