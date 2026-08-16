"""JSONL runtime logging for APK-driven protocol discovery.

Stage 2 keeps compatibility fallbacks, but every unknown or fallback response is
recorded with enough context to promote it into a semantic handler later.
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

from gxb_backend.config import Settings


def infer_domain(mid: int) -> str:
    ranges = (
        (20, 47, "player_economy"), (48, 79, "hero_summon"),
        (80, 111, "inventory"), (112, 159, "world_practice"),
        (160, 175, "missions"), (176, 207, "social_chat"),
        (208, 227, "battle_formation"), (228, 271, "activities"),
        (272, 335, "arena"), (336, 367, "march_sign"),
        (368, 575, "mail_social_misc"), (576, 655, "guild_team"),
        (656, 767, "player_region"), (768, 835, "arena_pet"),
    )
    for lo, hi, name in ranges:
        if lo <= mid <= hi:
            return name
    if 2400 <= mid <= 3199:
        return "late_game_activity"
    if mid >= 32768:
        return "tcp_or_special"
    return "unclassified"


class RuntimeLogger:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.root: Path = settings.runtime_log_dir
        self.root.mkdir(parents=True, exist_ok=True)

    def _append(self, filename: str, payload: dict[str, Any]) -> None:
        try:
            self.root.mkdir(parents=True, exist_ok=True)
            payload = {"ts": int(time.time()), **payload}
            with (self.root / filename).open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(payload, ensure_ascii=False, default=str, separators=(",", ":")) + "\n")
        except Exception as exc:
            print(f"[RUNTIME_LOG] failed writing {filename}: {exc}")

    @staticmethod
    def _response_keys(response: Any) -> list[str] | str:
        if isinstance(response, dict):
            return sorted(str(k) for k in response.keys())
        if isinstance(response, list):
            return "list"
        return type(response).__name__

    def request(self, *, mid: int, name: str, route: str, req: dict[str, Any], handler: str, response: Any, fallback: bool) -> None:
        if not self.settings.log_all_requests and not fallback:
            return
        payload = {
            "mid": mid,
            "name": name,
            "route": route,
            "handler": handler,
            "fallback": fallback,
            "request": req,
            "response_keys": self._response_keys(response),
            "domain": infer_domain(mid),
        }
        self._append("all_requests.jsonl", payload)
        if fallback:
            self._append("fallback_responses.jsonl", payload)
            self._append("unknown_mids.jsonl", payload)
            self._append("domain_gaps.jsonl", payload)
