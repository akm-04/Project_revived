"""Request-scoped entropy mechanics for server-authoritative gameplay outcomes.

Pass110 foundation only: this module deliberately owns no game-domain policy.
Pools, rates, pity, guarantees, costs, mutation, receipts, and persistence remain
with their existing domain owners.  The service keeps only ephemeral per-request
namespace ordinals so deterministic tests can detect draw-topology drift.
"""
from __future__ import annotations

from dataclasses import dataclass
import re
import secrets
from typing import Protocol, Sequence


_NAMESPACE_RE = re.compile(r"^[a-z0-9][a-z0-9_-]*(?:\.[a-z0-9][a-z0-9_-]*)*$")


def _require_namespace(namespace: str) -> str:
    if not isinstance(namespace, str) or not _NAMESPACE_RE.fullmatch(namespace):
        raise ValueError(
            "namespace must be lowercase dot-separated tokens matching "
            "^[a-z0-9][a-z0-9_-]*(?:\\.[a-z0-9][a-z0-9_-]*)*$"
        )
    return namespace


def _require_positive_int(value: int, *, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValueError(f"{field} must be a positive integer")
    return value


def _require_nonnegative_int(value: int, *, field: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        raise ValueError(f"{field} must be a nonnegative integer")
    return value


@dataclass(frozen=True)
class EntropyDrawRequest:
    """One validated bounded draw request sent to an ``EntropyProvider``."""

    namespace: str
    ordinal: int
    upper_exclusive: int


class EntropyProvider(Protocol):
    """Mechanical entropy provider; domain policy must not live here."""

    def draw(self, request: EntropyDrawRequest) -> int:
        """Return one integer in ``[0, request.upper_exclusive)``."""


class SystemEntropyProvider:
    """Production entropy backed by the operating system through ``secrets``."""

    def draw(self, request: EntropyDrawRequest) -> int:
        return secrets.randbelow(request.upper_exclusive)


class RandomOutcomeService:
    """Policy-free request-scoped random draw mechanics.

    Namespace ordinals are intentionally ephemeral.  A successful validated draw
    consumes one ordinal for its namespace; validation failures and invalid
    provider results consume none.  Durable exactly-once authority belongs to the
    existing PlayerUnitOfWork receipt system, not to this object.
    """

    def __init__(self, entropy: EntropyProvider | None = None) -> None:
        self._entropy = entropy if entropy is not None else SystemEntropyProvider()
        self._ordinals: dict[str, int] = {}

    def randbelow(self, namespace: str, upper_exclusive: int) -> int:
        namespace = _require_namespace(namespace)
        upper_exclusive = _require_positive_int(
            upper_exclusive, field="upper_exclusive"
        )
        ordinal = self._ordinals.get(namespace, 0)
        request = EntropyDrawRequest(
            namespace=namespace,
            ordinal=ordinal,
            upper_exclusive=upper_exclusive,
        )
        value = self._entropy.draw(request)
        if isinstance(value, bool) or not isinstance(value, int):
            raise ValueError("entropy provider must return an integer")
        if value < 0 or value >= upper_exclusive:
            raise ValueError(
                "entropy provider returned value outside requested range: "
                f"{value} not in [0, {upper_exclusive})"
            )
        self._ordinals[namespace] = ordinal + 1
        return value

    def choose_index(self, namespace: str, size: int) -> int:
        """Choose one index from ``range(size)`` using exactly one draw."""

        return self.randbelow(namespace, _require_positive_int(size, field="size"))

    def weighted_index(self, namespace: str, weights: Sequence[int]) -> int:
        """Choose one index by nonnegative integer weights using one draw.

        Weights are evaluated in caller-supplied order.  Zero weights are legal,
        while empty/all-zero sequences and non-integer values fail before entropy
        is consumed.
        """

        _require_namespace(namespace)
        if isinstance(weights, (str, bytes)) or not isinstance(weights, Sequence):
            raise ValueError("weights must be a nonempty sequence of integers")
        if len(weights) == 0:
            raise ValueError("weights must be nonempty")

        normalized: list[int] = []
        for index, weight in enumerate(weights):
            normalized.append(
                _require_nonnegative_int(weight, field=f"weights[{index}]")
            )
        total = sum(normalized)
        if total <= 0:
            raise ValueError("weights must contain at least one positive value")

        roll = self.randbelow(namespace, total)
        cursor = 0
        for index, weight in enumerate(normalized):
            cursor += weight
            if roll < cursor:
                return index
        raise RuntimeError("weighted selection overflow")


class NamespacedRandbelowAdapter:
    """Compatibility adapter for existing ``randbelow(upper)`` policy seams."""

    def __init__(self, service: RandomOutcomeService, namespace: str) -> None:
        if not isinstance(service, RandomOutcomeService):
            raise TypeError("service must be a RandomOutcomeService")
        self._service = service
        self._namespace = _require_namespace(namespace)

    def randbelow(self, upper: int) -> int:
        return self._service.randbelow(self._namespace, upper)
