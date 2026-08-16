"""Core formation/battle-session compatibility domain."""
from __future__ import annotations
from .context import HandlerContext

class BattleHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_formation(self, req: dict) -> dict:
        return self.ctx.state.get_player().battle_formation_payload()

    def set_formation(self, req: dict) -> dict:
        player = self.ctx.state.get_player()
        formation = req.get("formation") or req.get("partners") or req.get("heros")
        if formation is not None:
            player.battle_formation = formation if isinstance(formation, dict) else {"list": formation}
            self.ctx.state.save()
        return player.battle_formation_payload()

    def enter_battle(self, req: dict) -> dict:
        return {"battle_id": 1, "seed": 1, "report": {}, "enemy_info": {}, "awards": []}

    def friend_rep_heros(self, req: dict) -> dict:
        return {"heros": [], "list": []}

    def end_battle(self, req: dict) -> dict:
        return {"awards": [], "is_win": 1, "result": 1}
