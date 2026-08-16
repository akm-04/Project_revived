"""Player identity/state handlers."""

from __future__ import annotations

from .context import HandlerContext


class PlayerHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_player_info(self, req: dict) -> dict:
        region = req.get("region")
        if region is not None:
            try:
                self.ctx.state.set_region(int(region))
            except Exception:
                pass
        return self.ctx.state.get_player().player_info_payload()

    def first_main_touch(self, req: dict) -> dict:
        self.ctx.state.get_player().first_main_touch = 1
        self.ctx.state.save()
        return {}

    def save_story(self, req: dict) -> dict:
        """Persist the StoryData fields sent by MID 26.

        Pass 19 confirms the request contract is story_id, story_state, guide_id
        and the immediate caller consumes no response fields.
        """
        player = self.ctx.state.get_player()
        for request_key, attr in (
            ("story_id", "story_id"),
            ("story_state", "story_state"),
            ("guide_id", "guide_id"),
        ):
            if request_key in req:
                try:
                    setattr(player, attr, int(req[request_key]))
                except (TypeError, ValueError):
                    pass
        self.ctx.state.save()
        return {}

    def set_player_guide_function(self, req: dict) -> dict:
        player = self.ctx.state.get_player()
        guide_id = req.get("guide_function_id")
        if guide_id is not None:
            try:
                guide_id = int(guide_id)
                # Client code treats this collection as already-completed/skipped
                # special guides. Preserve it as a list for the server payload;
                # an empty default remains safe for established accounts.
                if guide_id not in player.guide_function_ids:
                    player.guide_function_ids.append(guide_id)
            except (TypeError, ValueError):
                pass
        self.ctx.state.save()
        return {
            "guide_function_ids": player.guide_function_ids,
            "guide_return_id": player.guide_return_id,
        }

    def set_player_return_id(self, req: dict) -> dict:
        player = self.ctx.state.get_player()
        if "guide_return_id" in req:
            try:
                player.guide_return_id = int(req["guide_return_id"])
            except (TypeError, ValueError):
                pass
        self.ctx.state.save()
        return {"guide_return_id": player.guide_return_id}
