"""Source-defined EventCentre.getUpgradeCost finite-job Crystal curve."""
from __future__ import annotations
import math
from typing import Any

class EventCentreAccelerationPolicy:
    @staticmethod
    def _seconds(value:Any)->int:
        try:return max(0,int(value))
        except (TypeError,ValueError):return 0

    def crystal_cost(self, remaining_seconds:Any)->int:
        seconds=self._seconds(remaining_seconds)
        if seconds < 14400:
            raw=seconds/72
        elif seconds < 43200:
            raw=(seconds-14400)/144+200
        else:
            raw=(seconds-43200)/432+400
        return max(math.ceil(raw),1)
