"""Player identity/state handlers."""

from __future__ import annotations

from gxb_backend.protocol.mids import MID
from gxb_backend.state.unit_of_work import OperationContext

from .context import HandlerContext


class PlayerHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_player_info(self, req: dict) -> dict:
        # Request-scoped identity already selects self by authenticated
        # session/account/region. Do not mutate a credential player's region
        # based on a projection request. Cross-player MID17 projection is a
        # later explicit slice and must not leak private self-state.
        return self.ctx.state.get_player().player_info_payload()

    def first_main_touch(self, req: dict) -> dict:
        self.ctx.state.get_player().first_main_touch = 1
        self.ctx.state.save()
        return {}

    def save_story(self, req: dict) -> dict:
        """Persist client-attested StoryData continuity only.

        Pass33 proves story_id/story_state/guide_id can be promoted from local
        device storage and therefore cannot authorize rewards, deterministic
        tutorial mutations, or Function announcements.  Server-authoritative
        tutorial policy is driven by canonical domain milestones instead.
        """
        services = self.ctx.state.get_services()
        player = services.player
        context = OperationContext(
            actor_player_id=str(player.player_id),
            protocol_mid=MID.SAVE_STORY,
            domain="story",
            operation_name="save_story",
        )
        with services.uow.transaction(context):
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
                # xyd.checkFirstInGuide() indexes this collection with
                # tostring(guide_id), so the wire/persisted shape is a map.
                if not isinstance(player.guide_function_ids, dict):
                    player.guide_function_ids = {}
                player.guide_function_ids[str(guide_id)] = 1
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
