"""Shared handler context."""

from __future__ import annotations

from dataclasses import dataclass

from gxb_backend.config import Settings
from gxb_backend.state.repository import StateRepository


@dataclass
class HandlerContext:
    state: StateRepository
    settings: Settings
