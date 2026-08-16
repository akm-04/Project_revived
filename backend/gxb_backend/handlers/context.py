"""Shared handler context."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING

from gxb_backend.config import Settings
from gxb_backend.state.repository import StateRepository

if TYPE_CHECKING:
    from gxb_backend.observability.resource_gateway import ResourceGateway


@dataclass
class HandlerContext:
    state: StateRepository
    settings: Settings
    resource_gateway: "ResourceGateway | None" = None
