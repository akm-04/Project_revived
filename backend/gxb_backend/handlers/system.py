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
        """Return MID18 regions plus only the authenticated account's players.

        Pass22 establishes MID18 as the account→region character directory.
        Region catalog rows remain shared; player briefs are account-scoped.
        """
        owned_players = self.ctx.state.list_account_players()

        regions = []
        for i in range(1, 201):
            regions.append({
                "region_id": i,
                "name": self.ctx.state.region_name(i),
                "status": 1,
                # RegionWindow compares these numerically. Exact official
                # capacity counters were not recovered, so max stays a local
                # compatibility sentinel while cur_id reflects local population.
                "cur_id": self.ctx.state.region_player_count(i),
                "max_player_id": 999999999,
            })

        players = []
        for player in owned_players:
            try:
                player_numeric_id = int(player.player_id)
            except (TypeError, ValueError):
                player_numeric_id = 0
            players.append({
                "id": player_numeric_id,
                "player_id": player_numeric_id,
                "name": str(player.player_name or ""),
                "region": int(player.region),
                "lev": int(player.lev),
                "vip": int(player.vip),
                "avatar_id": int(player.avatar_id),
                "avatar_frame_id": int(player.avatar_frame_id),
                "conquer_lev": int(player.conquer_lev),
                "conquer_loop_id": int(player.conquer_loop_id),
            })

        account = self.ctx.state.get_account()
        print(
            "[REGIONS] "
            f"sid={req.get('sid')!r} uid={account.uid} regions={len(regions)} "
            f"owned_players={len(players)}"
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
        # Source abtest.lua says MTSPY: A uses the extra weak/function guide,
        # B disables it. The shipped strong story guide is active for fresh
        # tutorial players, and v0.8.3 runtime proved hard-coded A can overlay
        # guide_new on that path at level 7. Use local compatibility arm B for
        # mtspy only; keep the previous A behavior for unrelated experiments.
        key = str(req.get("unique_key") or "").strip().lower()
        return "B" if key == "mtspy" else "A"

    def check_game_stat(self, req: dict) -> dict:
        return {}

    def get_pic_notice_info(self, req: dict) -> dict:
        # MainScene's ordered popup chain reads has_read + contents directly.
        # Established-profile default: nothing unread, so do not open a modal.
        return {"has_read": 1, "contents": []}

    def query_charge_data(self, req: dict) -> dict:
        return {"charges": [], "first_pay": 0, "list": []}

    def generate_player_name(self, req: dict) -> dict:
        # EditPlayerName:onGeneratePlayerName_ requires player_name_list. These
        # values are source entries from data/tables/random_name.lua; exact old
        # live-server sampling policy is not recovered, so keep deterministic.
        return {
            "player_name_list": [
                "Hoper", "In Rui", "Trypan", "Huai", "Bao", "Bi",
                "Zhao", "Zena", "Chang", "Cheng", "Dinge", "Feng",
            ]
        }

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
