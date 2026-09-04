"""Pass88 preservation PurchaseIntent bridge.

This route replaces the unavailable native store callback boundary for the
private server. It is *not* a historical game MID endpoint.
"""
from __future__ import annotations

from typing import Any

from flask import jsonify, make_response, request

from gxb_backend.state.commerce_purchase import CommercePurchaseError
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.multiuser_database import SANDBOX_SID, SANDBOX_TOKEN, SANDBOX_UID


def _json(data: dict[str, Any], status: int = 200):
    response = make_response(jsonify(data), int(status))
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    response.headers["Cache-Control"] = "no-cache, no-store"
    return response


def _payload() -> dict[str, Any]:
    raw = request.get_json(silent=True)
    if isinstance(raw, dict):
        return dict(raw)
    if request.form:
        return {key: request.form.get(key) for key in request.form.keys()}
    return {}


def register_commerce_routes(app, state: StateRepository) -> None:
    @app.route("/preservation/v1/purchase-intents", methods=["POST"])
    def purchase_intent_route():
        body = _payload()
        token = body.get("token") or body.get("access_token") or request.cookies.get("QQWTOKEN")
        sid = body.get("sid") or request.cookies.get("QQWSID")
        try:
            region = int(body.get("region") or 0)
        except (TypeError, ValueError):
            region = 0
        if region <= 0:
            return _json({"ok": 0, "error": "INVALID_REGION"}, 400)
        if not token and not sid:
            return _json({"ok": 0, "error": "AUTH_REQUIRED"}, 401)

        # Pass89 safety rule: the historical compatibility token `local_token`
        # is a real credential for the fixed legacy sandbox account uid 13371337,
        # not a wildcard meaning "whichever client is active".  A money-like
        # preservation endpoint must never silently use that account because a
        # manual test copied an old example token.  Explicit opt-in preserves
        # established-profile testing while normal/OTA clients use their actual
        # SDK session token automatically.
        allow_legacy = str(body.get("allow_legacy_sandbox") or "").strip().lower() in {
            "1", "true", "yes", "on"
        }
        legacy_credential = str(token or "") == SANDBOX_TOKEN or str(sid or "") == SANDBOX_SID
        if legacy_credential and not allow_legacy:
            return _json({
                "ok": 0,
                "error": "LEGACY_SANDBOX_EXPLICIT_OPT_IN_REQUIRED",
                "legacy_account_uid": SANDBOX_UID,
                "message": "local_token/legacy SID belongs to legacy sandbox account uid 13371337; use the current SDK token/SID or set allow_legacy_sandbox=1 intentionally.",
            }, 409)

        bind = {"mid": 36857, "region": region}
        if token:
            bind["token"] = str(token)
        if sid:
            bind["sid"] = str(sid)
        with state.request_scope(bind):
            if not state.has_authenticated_session() or state.current_player_or_none() is None:
                return _json({"ok": 0, "error": "AUTH_OR_PLAYER_NOT_FOUND"}, 401)
            bound = state.current_player_or_none()
            expected_player_id = str(body.get("expected_player_id") or "").strip()
            if expected_player_id and expected_player_id != str(getattr(bound, "player_id", "")):
                return _json({
                    "ok": 0,
                    "error": "AUTH_PLAYER_MISMATCH",
                    "expected_player_id": expected_player_id,
                    "resolved_player_id": str(getattr(bound, "player_id", "")),
                }, 409)
            session = state.current_session() or {}
            print(
                "[COMMERCE AUTH] "
                f"uid={session.get('uid')} player={getattr(bound, 'player_id', None)} "
                f"region={region} legacy={int(legacy_credential)}"
            )
            # PurchaseIntent is a state-mutating player entrypoint outside the
            # normal EngineDispatcher, so it must honor the same day-boundary
            # materialization rule before performing domain work.
            if state.evaluate_daily_reset(trigger_mid=36857) is None:
                return _json({"ok": 0, "error": "DAILY_RESET_UNDECIDED"}, 503)
            services = state.get_services()
            try:
                result = services.commerce_settlement.settle(body)
            except CommercePurchaseError as exc:
                return _json({"ok": 0, "error": exc.code, "message": str(exc)}, 400)
            except Exception as exc:
                print(f"[COMMERCE] purchase intent rollback error={exc}")
                return _json({"ok": 0, "error": "COMMERCE_INTERNAL_ERROR"}, 500)
            print(
                "[COMMERCE] purchase "
                f"player={services.player.player_id} intent={result.intent_id} "
                f"status={result.status} charge_id={result.settlement.get('charge_id')} "
                f"crystal_delta={result.settlement.get('crystal_delta')} "
                f"vip={services.player.vip} charge={services.player.charge}"
            )
            return _json(result.to_bridge_payload(), 200)
