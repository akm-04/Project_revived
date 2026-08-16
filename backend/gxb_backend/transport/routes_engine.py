"""Routes for center discovery and engine/game API traffic."""

from __future__ import annotations

from flask import make_response, request

from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.observability.client_error_capture import ClientErrorCapture
from gxb_backend.observability.resource_probe import ResourceProbe
from gxb_backend.config import Settings
from gxb_backend.transport.decoder import decode_payload, extract_engine_payload
from gxb_backend.transport.responses import engine_ok, json_response


def _handle_engine_request(dispatcher: EngineDispatcher, label: str):
    raw, source = extract_engine_payload(request)
    req_data, method = decode_payload(raw)
    print(f"[{label}] source={source} decode={method}")
    if not req_data:
        print(f"[{label}] could not decode payload; returning generic OK")
        return json_response(engine_ok())
    response = dispatcher.dispatch(req_data)
    return json_response(response)


def register_engine_routes(app, dispatcher: EngineDispatcher, settings: Settings) -> None:
    client_errors = ClientErrorCapture(settings)
    resource_probe = ResourceProbe(settings)
    @app.route("/center/v1", methods=["POST"])
    def center_route():
        return _handle_engine_request(dispatcher, "CENTER")

    @app.route("/api/v1", methods=["POST"])
    def api_route():
        return _handle_engine_request(dispatcher, "API")

    @app.route("/client-log", methods=["POST"])
    def client_log_route():
        # Backend.log() only checks HTTP status 200; response body is ignored.
        client_errors.capture(request)
        return make_response("", 200)

    @app.route("/res/<path:asset>", methods=["GET", "POST"])
    def resource_probe_route(asset: str):
        return resource_probe.capture(request, asset)

    @app.route("/", methods=["GET", "POST"])
    @app.route("/<path:path>", methods=["GET", "POST"])
    def catch_all(path=""):
        port = request.environ.get("SERVER_PORT")
        print(f"[HTTP] unmatched path=/{path} port={port}")
        raw, _source = extract_engine_payload(request)
        req_data, method = decode_payload(raw)
        if req_data:
            print(f"[HTTP] catch-all decode={method}")
            return json_response(dispatcher.dispatch(req_data))
        return json_response(engine_ok())
