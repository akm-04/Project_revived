"""Backward-compatible import for the Stage 4A.4 EOL resource gateway."""

from gxb_backend.observability.resource_gateway import ResourceGateway

# Older route code/build notes used the diagnostic-only ResourceProbe name.
ResourceProbe = ResourceGateway

__all__ = ["ResourceGateway", "ResourceProbe"]
