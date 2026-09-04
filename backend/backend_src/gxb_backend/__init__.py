"""Girls X Battle local backend package.

Keep state/repository imports independent from Flask. ``create_app`` remains a
backwards-compatible lazy export for callers that import it from the package.
"""

from __future__ import annotations

from .version import BACKEND_VERSION as __version__

__all__ = ["create_app", "__version__"]


def __getattr__(name: str):
    if name == "create_app":
        from .app_factory import create_app
        return create_app
    raise AttributeError(name)
