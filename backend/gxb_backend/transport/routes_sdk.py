"""Routes for the Java/Xinyd SDK compatibility surface."""

from __future__ import annotations

from typing import Any

from flask import Blueprint, request

from gxb_backend.state.repository import StateRepository
from gxb_backend.transport.decoder import decode_sdk_body
from gxb_backend.transport.responses import json_response, sdk_success


SDK_BLUEPRINT = Blueprint("sdk", __name__)

LOG_MIDS = {"65319", "65319.0"}
PAYMENT_NAMES = {"query_pay_method_amounts"}

REGISTER_MIDS = {"65282", "65282.0"}
LOGIN_MIDS = {"65281", "65281.0"}
ANONYMOUS_MIDS = {"65284", "65284.0"}
PACKAGE_INFO_MIDS = {"65305", "65305.0"}


def _sdk_error(message: str, code: int = 1) -> dict[str, Any]:
    """Return a local-compatibility SDK error envelope.

    Exact historical Xinyd duplicate/wrong-password numeric codes were not
    recovered.  The client consumes nonzero ``error_code`` plus ``error_msg``;
    code 1 is therefore a documented local-server policy, not an official code.
    """
    return {
        "status": 0,
        "code": 0,
        "error_code": int(code),
        "error_msg": str(message),
        "msg": str(message),
        "data": {},
        "package_info": {},
    }


def _device_metadata(payload: dict[str, Any]) -> dict[str, Any]:
    keys = (
        "device_id", "sub_device_id", "device_type", "device_abi", "os_type",
        "os_version", "client_id", "advertising_id", "appsflyer_id",
    )
    return {key: payload.get(key) for key in keys if payload.get(key) not in (None, "")}


class SDKRoutes:
    def __init__(self, state: StateRepository) -> None:
        self.state = state

    def handle(self):
        body = decode_sdk_body(request)
        if not isinstance(body, dict):
            print("[SDK] malformed/non-JSON request")
            return json_response(sdk_success())

        mid = str(body.get("mid", ""))
        payload = body.get("payload") if isinstance(body.get("payload"), dict) else {}
        print(f"[SDK] mid={mid!r} body={body!r}")

        if mid in REGISTER_MIDS:
            login = str(payload.get("login_email", ""))
            password = str(payload.get("password", ""))
            repassword = str(payload.get("repassword", ""))
            if not login or not password or password != repassword:
                return json_response(_sdk_error("Invalid registration request"))
            record, status = self.state.sdk_register(login, password)
            if record is None:
                print(f"[SDK AUTH] register conflict login={login!r}")
                return json_response(_sdk_error("Account already exists"))
            print(f"[SDK AUTH] register {status} login={login!r} uid={record['uid']}")
            # Pass21 Smali: both uid and login_email are required with getString.
            return json_response(sdk_success(identity={
                "uid": str(record["uid"]),
                "login_email": str(record.get("login") or login),
            }))

        if mid in LOGIN_MIDS:
            login = str(payload.get("login_email", ""))
            password = str(payload.get("password", ""))
            identity = self.state.sdk_login(login, password, device=_device_metadata(payload))
            if identity is None:
                print(f"[SDK AUTH] login rejected login={login!r}")
                return json_response(_sdk_error("Invalid account or password"))
            print(
                "[SDK AUTH] login success "
                f"login={login!r} uid={identity.uid} sid={identity.sid} token={identity.token}"
            )
            return json_response(
                sdk_success(identity={
                    **identity.sdk_json(),
                    "login_email": login,
                }),
                cookies=identity.cookies(),
            )

        if mid in ANONYMOUS_MIDS:
            identity = self.state.sdk_anonymous_identity(device=_device_metadata(payload))
            print("[SDK] anonymous sandbox cookies: " + ", ".join(f"{k}={v}" for k, v in identity.cookies().items()))
            return json_response(sdk_success(identity=identity.sdk_json()), cookies=identity.cookies())

        if mid in PACKAGE_INFO_MIDS:
            # Preserve the proven startup behavior: the SDK receives a usable
            # anonymous session before it later emits MID65284 explicitly.
            sid_cookie = request.cookies.get("QQWSID")
            identity = self.state.sdk_identity_from_sid(sid_cookie) if sid_cookie else None
            identity = identity or self.state.sdk_anonymous_identity(device=_device_metadata(payload))
            print("[SDK] package-info session cookies: " + ", ".join(f"{k}={v}" for k, v in identity.cookies().items()))
            return json_response(sdk_success(identity=identity.sdk_json()), cookies=identity.cookies())

        if mid in LOG_MIDS:
            return json_response(sdk_success())

        if mid in PAYMENT_NAMES:
            return json_response(sdk_success(data={"methods": [], "amounts": []}))

        # Auxiliary/string SDK APIs remain compatibility-success only until a
        # source/live slice needs their semantics. Payment remains out of scope.
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
