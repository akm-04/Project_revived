"""Global evidence-backed Summon duplicate-conversion policy.

Pass41.7 moves duplicate fragment quantities out of the private RNG policy because
new historical gameplay evidence recovered native-star quantities shared by Vending.
"""
from __future__ import annotations

import json
from pathlib import Path


class SummonDuplicateConversionPolicy:
    DATA_FILE = "summon_duplicate_conversion_policy.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load summon duplicate conversion policy {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid summon duplicate conversion policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self.activation_condition = str(raw.get("activation_condition") or "")
        self.fragment_id_source = str(raw.get("fragment_id_source") or "")
        quantities = raw.get("quantity_by_initial_star")
        if not isinstance(quantities, dict):
            raise RuntimeError("summon duplicate quantity map missing")
        self._quantity_by_initial_star = {int(k): int(v) for k, v in quantities.items()}
        if any(star <= 0 or qty <= 0 for star, qty in self._quantity_by_initial_star.items()):
            raise RuntimeError("summon duplicate quantity map contains invalid values")
        self.unsupported_behavior = str(raw.get("unsupported_initial_star_behavior") or "fail_closed")
        if self.unsupported_behavior != "fail_closed":
            raise RuntimeError(f"unsupported duplicate conversion fallback: {self.unsupported_behavior}")

    def quantity_for_initial_star(self, initial_star: int) -> int:
        qty = self._quantity_by_initial_star.get(int(initial_star))
        if qty is None or qty <= 0:
            raise RuntimeError(
                f"duplicate conversion quantity is not recovered for native star {initial_star}"
            )
        return qty
