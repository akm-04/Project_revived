"""Strict deterministic entropy provider used by RNG topology self-tests."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

from gxb_backend.state.random_outcome_service import EntropyDrawRequest


@dataclass(frozen=True)
class ScriptedEntropyDraw:
    namespace: str
    ordinal: int
    upper_exclusive: int
    value: int


class ScriptedEntropyProvider:
    """Replay an exact expected draw script and fail loudly on topology drift."""

    def __init__(self, expected: Iterable[ScriptedEntropyDraw]) -> None:
        self._expected: dict[tuple[str, int], ScriptedEntropyDraw] = {}
        self._consumed: list[tuple[str, int]] = []
        for row in expected:
            if not isinstance(row, ScriptedEntropyDraw):
                raise TypeError("expected rows must be ScriptedEntropyDraw instances")
            key = (row.namespace, row.ordinal)
            if key in self._expected:
                raise ValueError(
                    f"duplicate scripted entropy draw for {row.namespace}#{row.ordinal}"
                )
            self._expected[key] = row

    @property
    def consumed(self) -> tuple[tuple[str, int], ...]:
        return tuple(self._consumed)

    def draw(self, request: EntropyDrawRequest) -> int:
        key = (request.namespace, request.ordinal)
        row = self._expected.get(key)
        if row is None:
            raise AssertionError(
                "unexpected entropy draw: "
                f"{request.namespace}#{request.ordinal} upper={request.upper_exclusive}"
            )
        if row.upper_exclusive != request.upper_exclusive:
            raise AssertionError(
                "entropy upper_exclusive mismatch for "
                f"{request.namespace}#{request.ordinal}: "
                f"expected {row.upper_exclusive}, got {request.upper_exclusive}"
            )
        if isinstance(row.value, bool) or not isinstance(row.value, int):
            raise AssertionError(
                f"scripted entropy value must be an integer for {row.namespace}#{row.ordinal}"
            )
        if row.value < 0 or row.value >= request.upper_exclusive:
            raise AssertionError(
                "scripted entropy value out of range for "
                f"{row.namespace}#{row.ordinal}: {row.value} not in "
                f"[0, {request.upper_exclusive})"
            )
        del self._expected[key]
        self._consumed.append(key)
        return row.value

    def assert_exhausted(self) -> None:
        if not self._expected:
            return
        pending = ", ".join(
            f"{namespace}#{ordinal}"
            for namespace, ordinal in sorted(self._expected)
        )
        raise AssertionError(f"missing expected entropy draws: {pending}")
