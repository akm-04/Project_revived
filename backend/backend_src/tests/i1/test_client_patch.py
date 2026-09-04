from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def _text(arch: str, relative: str) -> str:
    return (ROOT / "local_assets" / arch / relative).read_text(encoding="utf-8-sig")


def test_sparse_patch_is_architecture_symmetric() -> None:
    files = (
        "app/common/network/Backend.lua",
        "app/common/network/mid.lua",
        "app/scenes/LoadingScene.lua",
        "app/windows/SwitchItem.lua",
    )
    for relative in files:
        assert (ROOT / "local_assets/src_32" / relative).read_bytes() == (
            ROOT / "local_assets/src_64" / relative
        ).read_bytes()


def test_context_epoch_fence_precedes_global_response_processing() -> None:
    text = _text("src_64", "app/common/network/Backend.lua")
    assert "contextEpoch_ = 0" in text
    assert "contextReady_ = false" in text
    assert 'token_ = ""' in text
    assert "region_ = 0" in text
    assert "pendingRequests = {}" in text
    web = text.index("function var_0_1.webRequest_")
    capture = text.index("local var_23_epoch = arg_23_0.contextEpoch_ or 0", web)
    stale = text.index("if var_23_epoch ~= (arg_23_0.contextEpoch_ or 0) then", capture)
    global_check = text.index("arg_23_0:extraWebResponseCheck_", stale)
    assert capture < stale < global_check
    completion = text.index("arg_23_0:destoryRequest_(var_23_5)", web)
    completion_stale = text.index("if var_23_epoch ~= (arg_23_0.contextEpoch_ or 0) then", completion)
    retry = text.index("arg_23_0:shouldRetry_", completion)
    assert completion < completion_stale < retry


def test_retry_records_epoch_and_reuses_original_parameter_table_and_operation_id() -> None:
    text = _text("src_64", "app/common/network/Backend.lua")
    assert "client_op_id = arg_11_0:nextClientOpID_()" in text
    assert "epoch = var_23_epoch" in text
    assert "iter_30_1.epoch == (arg_23_0.contextEpoch_ or 0)" in text
    assert "arg_23_0:webRequest_(iter_30_1.mid, iter_30_1.params" in text
    web = text[text.index("function var_0_1.webRequest_"):]
    # A retry enters webRequest_ directly, so it must not mint a second logical ID.
    assert "nextClientOpID_" not in web


def test_context_not_ready_blocks_selected_player_emission_but_allows_account_bootstrap() -> None:
    text = _text("src_64", "app/common/network/Backend.lua")
    gate = text.index("if not arg_11_0.contextReady_")
    call = text.index("arg_11_0:webRequest_", gate)
    assert gate < call
    helper = text[text.index("function var_0_1.isContextBootstrapMid_"):text.index("function var_0_1.beginContextTransition")]
    for marker in ("xyd.mid.RETRIEVE_TOKEN", "xyd.mid.LOAD_USER_REGIONS", "xyd.mid.LOAD_ANNOUNCE", "xyd.mid.GET_PLAYER_GROUP_BY_KEY"):
        assert marker in helper
    # MID2 and 20480 are UpdateScene bootstrap/update traffic sent through its
    # separate webRequest_ path, not Backend.request(), so they do not belong
    # in this selected-context bypass helper.
    assert "arg_3_1 == 2" not in helper
    assert "20480" not in helper


def test_mid1_success_is_the_context_ready_boundary() -> None:
    text = _text("src_64", "app/common/network/Backend.lua")
    token_case = text.index("if arg_23_1 == xyd.mid.RETRIEVE_TOKEN then")
    ready = text.index("arg_23_0.contextReady_ = true", token_case)
    callback = text.index("var_23_2(arg_27_0, arg_27_1)", ready)
    assert token_case < ready < callback


def test_loading_scene_mid1_is_single_flight() -> None:
    text = _text("src_64", "app/scenes/LoadingScene.lua")
    check = text.index("if arg_29_0.isLoggingIn_ then")
    set_true = text.index("arg_29_0.isLoggingIn_ = true", check)
    request = text.index("xyd.Backend.get():request(xyd.mid.RETRIEVE_TOKEN", set_true)
    set_false = text.index("arg_29_0.isLoggingIn_ = false", request)
    branch = text.index("if arg_30_0 == xyd.error.OK then", set_false)
    assert check < set_true < request < set_false < branch


def test_manual_switch_increments_epoch_before_listener_and_model_reset() -> None:
    text = _text("src_64", "app/windows/SwitchItem.lua")
    transition = text.index('beginContextTransition("manual_server_switch")')
    listeners = text.index("removeAllEventListeners", transition)
    models = text.index("xyd.ModelManager.get():reset()", transition)
    server_time = text.index("xyd.ServerTime.get():reset()", transition)
    assert transition < listeners < models < server_time


def test_private_realtime_control_is_reserved_and_predispatched() -> None:
    mid = _text("src_64", "app/common/network/mid.lua")
    assert "xyd.mid.PRIVATE_SERVER_CONTROL = 65000" in mid
    text = _text("src_64", "app/common/network/Backend.lua")
    handler = text.index("if arg_47_2 == xyd.mid.PRIVATE_SERVER_CONTROL then")
    generic = text.index("if arg_47_1 == arg_47_0.socket_ then", handler)
    assert handler < generic
    assert 'var_10_0 == "CONNECTION_SUPERSEDED"' in text
    assert 'var_10_0 == "ROOM_INVALIDATED"' in text
    assert 'var_10_0 == "AUTH_CONTEXT_INVALIDATED"' in text
    assert "if not var_43_intentional then" in text


def test_current_selected_player_auth_failure_rebootstraps_but_account_scope_does_not_recurse() -> None:
    text = _text("src_64", "app/common/network/Backend.lua")
    helper = text[text.index("function var_0_1.handleWebAuthFailure_"):text.index("function var_0_1.handlePrivateServerControl_")]
    assert "isContextBootstrapMid_" in helper
    assert 'arg_9_2.error_class ~= "auth"' in helper
    assert "beginContextTransition" in helper
    assert "enterContextRebootstrap_" in helper
    non200 = text.index("if var_31_1 ~= 200 then")
    auth = text.index("handleWebAuthFailure_", non200)
    complete = text.index("return var_23_3(var_31_3, xyd.error.ERROR)", auth)
    assert non200 < auth < complete
