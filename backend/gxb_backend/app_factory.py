"""Flask app construction."""

from __future__ import annotations

from flask import Flask

from gxb_backend.config import SETTINGS, Settings
from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.state.repository import StateRepository
from gxb_backend.transport.routes_engine import register_engine_routes
from gxb_backend.transport.routes_sdk import register_sdk_routes


def create_app(settings: Settings = SETTINGS, state: StateRepository | None = None) -> Flask:
    app = Flask(__name__)
    app.config["JSON_SORT_KEYS"] = False
    repo = state or StateRepository(
        settings.player_db_path,
        profile=settings.profile,
        legacy_path=settings.state_path,
    )
    dispatcher = EngineDispatcher(repo, settings)
    register_sdk_routes(app, repo)
    register_engine_routes(app, dispatcher, settings)
    app.extensions["gxb_state"] = repo
    app.extensions["gxb_dispatcher"] = dispatcher
    return app
