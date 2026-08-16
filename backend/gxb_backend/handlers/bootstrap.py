"""RETRIEVE_TOKEN and bootstrap detail hydration."""

from __future__ import annotations

from .context import HandlerContext


class BootstrapHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def retrieve_token(self, req: dict) -> dict:
        player = self.ctx.state.get_player()
        account = self.ctx.state.get_account()
        try:
            region = int(req.get("region", player.region))
        except Exception:
            region = player.region
        self.ctx.state.set_region(region)

        detail = self.build_detail()
        return {
            "token": account.token,
            "region": player.region,
            "log_url": "",
            "is_new": 0,
            "story_type": 0,
            "is_debug": 0,
            "is_old_top": 0,
            "uid": account.uid,
            "detail": detail,
        }

    def build_detail(self) -> dict[str, object]:
        player = self.ctx.state.get_player()
        # Conservative boot-safe hydration: source-confirmed first-entry state
        # plus safe empty fanout state. Missing optional detail entries are
        # guarded by the client; malformed entries are worse than absent ones.
        return {
            "17": player.player_info_payload(),
            "49": player.heroes_payload(),
            "81": player.backpack_payload(),
            "836": player.library_payload(),
            "56": player.summon_payload(),
            "176": player.friends_payload(),
            "229": player.activities_payload(),
            "2560": player.redmark_payload(),
        }
