"""Response builders for SDK and engine routes."""

from __future__ import annotations

from typing import Any

from flask import jsonify, make_response


def engine_ok(data: Any | None = None) -> Any:
    """Return the flat JSON shape consumed by Backend.lua.

    Scalar exceptions such as GET_PLAYER_GROUP_BY_KEY are handled by the
    dispatcher and should not be wrapped with this helper.
    """
    out: dict[str, Any] = {"error_code": 0}
    if isinstance(data, dict):
        out.update(data)
    elif data is not None:
        out["data"] = data
    return out


def engine_error(code: int = 1, message: str = "error") -> dict[str, Any]:
    return {"error_code": int(code), "msg": str(message)}


def sdk_success(*, identity: dict[str, Any] | None = None, data: dict[str, Any] | None = None) -> dict[str, Any]:
    body: dict[str, Any] = {
        "status": 1,
        "code": 1,
        "error_code": 0,
        "msg": "success",
        "data": dict(data or {}),
        "package_info": {},
    }
    if identity:
        body.update(identity)
        body["data"].update(identity)
    return body


def json_response(data: Any, cookies: dict[str, str] | None = None):
    response = make_response(jsonify(data))
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["Cache-Control"] = "no-cache, no-store"
    response.headers["Connection"] = "keep-alive"
    if cookies:
        for name, value in cookies.items():
            response.set_cookie(
                name,
                str(value),
                path="/",
                httponly=False,
                secure=False,
                samesite=None,
            )
    return response
