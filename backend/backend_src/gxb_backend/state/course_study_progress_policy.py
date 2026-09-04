"""Replaceable EOL compatibility policy for Course study completion progress.

SOURCE FACT: the client treats the server response as authoritative and exposes
``object_classroom_knowledge = 0.2`` but does not calculate progress locally.
The original server formula is therefore unrecovered.  Pass185 froze +20
percentage points per completed eight-hour job as an explicit private-server
compatibility policy, never as source truth.
"""
from __future__ import annotations
from typing import Any


class CourseStudyProgressPolicy:
    INCREMENT = 20

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def complete(self, current_progress: Any) -> int:
        current = max(0, min(100, self._int(current_progress)))
        return min(100, current + self.INCREMENT)
