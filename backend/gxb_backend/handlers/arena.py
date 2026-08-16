"""Arena domain handlers built around canonical Stage 3 state."""
from __future__ import annotations
from .context import HandlerContext

class ArenaHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_arena(self, req: dict) -> dict:
        return self.ctx.state.get_player().arena_payload()

    def player_list(self, req: dict) -> dict:
        return {"list": [], "enemies": [], "server_time": self.ctx.state.get_player().now()}

    def refresh(self, req: dict) -> dict:
        return self.player_list(req)

    def rank(self, req: dict) -> dict:
        return self.ctx.state.get_player().arena_rank_payload()

    def defense(self, req: dict) -> dict:
        return {"defense": [], "pet_id": 0, "set_formation_time": 0}

    def save_defense(self, req: dict) -> dict:
        return self.defense(req)

    def start_fight(self, req: dict) -> dict:
        return {"battle_id": 1, "seed": 1, "enemy_info": {}, "report": {}}

    def buy_ticket(self, req: dict) -> dict:
        return {"buy_num": 0, "left_time": 0}

    def mode_info(self, req: dict) -> dict:
        return self.ctx.state.get_player().arena_mode_payload()

    def mode_enemy_list(self, req: dict) -> dict:
        return {"enemies": []}

    def query_formation(self, req: dict) -> dict:
        return self.ctx.state.get_player().arena_formation_payload()

    def record_detail(self, req: dict) -> dict:
        return {"report": {}, "record": {}, "players": []}

    def load_arena_fight_records(self, req: dict) -> dict:
        return self.ctx.state.get_player().arena_records_payload()

    def load_arena_fight_report(self, req: dict) -> dict:
        return {"report": {}, "record": {}}

    def peak_records(self, req: dict) -> dict:
        return self.ctx.state.get_player().peak_records_payload()

    def get_auction_info_by_type(self, req: dict) -> dict:
        return self.ctx.state.get_player().auction_payload(req.get("auction_type"))

    def arena_rank_list(self, req: dict) -> dict:
        return self.rank(req)

    def empty_list(self, req: dict) -> dict:
        return {"list": []}
