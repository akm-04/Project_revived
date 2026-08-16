"""Routes for the Java/Xinyd SDK compatibility surface."""

from __future__ import annotations

from flask import Blueprint, request

from gxb_backend.state.repository import StateRepository
from gxb_backend.transport.decoder import decode_sdk_body
from gxb_backend.transport.responses import json_response, sdk_success


SDK_BLUEPRINT = Blueprint("sdk", __name__)

IDENTITY_MIDS = {"65305", "65305.0", "65284", "65284.0", "65281", "65281.0", "65304", "65304.0"}
LOG_MIDS = {"65319", "65319.0"}
PAYMENT_NAMES = {"query_pay_method_amounts"}


class SDKRoutes:
    def __init__(self, state: StateRepository) -> None:
        self.state = state

    def handle(self):
        # Keep SDK identity/cookies sourced from the same editable player DB as
        # the engine-side account/session state.
        self.state.refresh()
        body = decode_sdk_body(request)
        if not isinstance(body, dict):
            print("[SDK] malformed/non-JSON request")
            return json_response(sdk_success())

        mid = str(body.get("mid", ""))
        print(f"[SDK] mid={mid!r} body={body!r}")

        if mid in IDENTITY_MIDS:
            account = self.state.get_account()
            identity = account.sdk_json()
            print("[SDK] setting session cookies: " + ", ".join(f"{k}={v}" for k, v in account.cookies().items()))
            return json_response(sdk_success(identity=identity), cookies=account.cookies())

        if mid in LOG_MIDS:
            return json_response(sdk_success())

        if mid in PAYMENT_NAMES:
            return json_response(sdk_success(data={"methods": [], "amounts": []}))

        return json_response(sdk_success())


def register_sdk_routes(app, state: StateRepository) -> None:
    routes = SDKRoutes(state)

    @app.route("/server/mobile_api_new/", methods=["POST"])
    @app.route("/server/mobile_api_new", methods=["POST"])
    def sdk_route():
        return routes.handle()

    @app.route("/home_api/upload_sdk_logs", methods=["POST"])
    @app.route("/home_api/upload_sdk_logs/", methods=["POST"])
    def sdk_upload():
        print("[SDK] upload_sdk_logs received")
        return json_response({"error_code": 0})
