"""Shop/market domain handlers."""
from __future__ import annotations
from .context import HandlerContext

class ShopHandlers:
    def __init__(self, ctx: HandlerContext) -> None:
        self.ctx = ctx

    def load_shop(self, req: dict) -> dict:
        return self.ctx.state.get_player().shop_payload(req.get("shop_type") or req.get("type"))

    def load_shop_list(self, req: dict) -> dict:
        return self.ctx.state.get_player().shop_list_payload()

    def buy_shop(self, req: dict) -> dict:
        return {"awards": [], "items": []}

    def refresh_shop(self, req: dict) -> dict:
        return self.load_shop(req)

    def close_shop(self, req: dict) -> dict:
        return {}

    def market_buy(self, req: dict) -> dict:
        return {"awards": []}

    def load_magic_shop(self, req: dict) -> dict:
        return {"left_time": self.ctx.state.get_player().now() + 3600, "items": []}

    def market_cart(self, req: dict) -> dict:
        return {"list": [], "cart": [], "items": [], "total_price": 0}

    def market_cart_mutation(self, req: dict) -> dict:
        return self.market_cart(req)

    def skin_shop_info(self, req: dict) -> dict:
        return {"list": [], "items": [], "refresh_time": self.ctx.state.get_player().now() + 86400}
