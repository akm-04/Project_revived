"""Activity and reward handlers.

Stage 1 returns structurally safe empty/default activity state. This keeps the
boot fan-out and optional popup chain stable without claiming event-complete
server logic.
"""

from __future__ import annotations

from .context import HandlerContext


class ActivityHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def activities(self, req: dict) -> dict:
        return self.ctx.state.get_player().activities_payload()

    def get_board_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().board_payload()

    def load_single_activity(self, req: dict) -> dict:
        # The client inserts this response into Activities.activities and does
        # not wrap it itself.  Preserve the requested activity id as table_id
        # and provide the common timing/open fields even for an inactive event.
        return self.ctx.state.get_player().single_activity_payload(req.get("activity_id"))

    def get_activity_reward(self, req: dict) -> dict:
        return {"awards": [], "exchange_stone_num": 0}

    def load_sign_info(self, req: dict) -> dict:
        return {
            "awards": [],
            "is_signed": 1,
            "partner_id": 0,
            "sign_times": 0,
            "month": 1,
            "is_skin": 0,
        }

    def sign(self, req: dict) -> dict:
        return {"awards": []}

    def daily_consume_load(self, req: dict) -> dict:
        return {"awards": [], "point": 0, "items": []}

    def daily_consume(self, req: dict) -> dict:
        return {"awards": []}
