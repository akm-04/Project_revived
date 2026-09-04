"""Flask app construction."""

from __future__ import annotations

from flask import Flask

from gxb_backend.config import SETTINGS, Settings
from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.observability.resource_gateway import ResourceGateway
from gxb_backend.realtime import RealtimeRuntime
from gxb_backend.state.repository import StateRepository
from gxb_backend.transport.routes_engine import register_engine_routes
from gxb_backend.transport.routes_commerce import register_commerce_routes
from gxb_backend.transport.routes_sdk import register_sdk_routes
from gxb_backend.runtime.authority import assert_legacy_json_start_allowed


def create_app(settings: Settings = SETTINGS, state: StateRepository | None = None) -> Flask:
    app = Flask(__name__)
    app.config["JSON_SORT_KEYS"] = False
    if state is None:
        assert_legacy_json_start_allowed()
    repo = state or StateRepository(
        settings.player_db_path,
        profile=settings.profile,
        legacy_path=settings.state_path,
        multiuser_root=settings.multiuser_root,
    )
    resource_gateway = ResourceGateway(settings)
    # U4B realtime foundation: construct one app-scoped transient runtime without
    # listening. Wave E also binds its typed post-commit sink and MID192 room
    # directory; run.main still owns listener start/stop after graph validation.
    realtime_runtime = RealtimeRuntime(settings.chat_host, settings.chat_port, repo)
    dispatcher = EngineDispatcher(
        repo, settings, resource_gateway,
        post_commit_sink=realtime_runtime.handle_post_commit,
        realtime_runtime=realtime_runtime,
    )
    register_sdk_routes(app, repo)
    register_commerce_routes(app, repo)
    register_engine_routes(app, dispatcher, settings, resource_gateway)
    app.extensions["gxb_state"] = repo
    app.extensions["gxb_dispatcher"] = dispatcher
    app.extensions["gxb_resource_gateway"] = resource_gateway
    app.extensions["gxb_realtime_runtime"] = realtime_runtime
    return app
