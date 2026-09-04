"""Ingress authentication-scope contracts introduced by Pass340 I1."""

from .perimeter import (
    AuthDecision,
    AuthScope,
    AuthScopeRegistry,
    LegacyAuthPerimeter,
)

__all__ = [
    "AuthDecision",
    "AuthScope",
    "AuthScopeRegistry",
    "LegacyAuthPerimeter",
]
