"""Runtime configuration for the modular GXB backend."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    bind_host: str = os.getenv("GXB_BIND", "0.0.0.0")
    sdk_port: int = int(os.getenv("GXB_SDK_PORT", "5000"))
    engine_port: int = int(os.getenv("GXB_ENGINE_PORT", "9000"))
    chat_host: str = os.getenv("GXB_CHAT_HOST", "172.20.0.21")
    chat_port: int = int(os.getenv("GXB_CHAT_PORT", "9100"))
    self_url: str = os.getenv("GXB_SELF_URL", "http://172.20.0.21:9000/api/v1")
    # The Lua ErrorLogPoster uploads hidden engine/Lua/resource errors here.
    # Empty override derives /client-log from GXB_SELF_URL so custom hosts work.
    client_log_url_override: str = os.getenv("GXB_CLIENT_LOG_URL", "").strip()
    # Stage 3.1.3 diagnostic: expose the Lua AssetDownload requests that are
    # otherwise invisible when res_download_url is blank.
    resource_probe_enabled: bool = os.getenv("GXB_RESOURCE_PROBE", "0") not in {"0", "false", "False"}
    res_download_url_override: str = os.getenv("GXB_RES_DOWNLOAD_URL", "").strip()
    # Stage 3.1 canonical state is a human-editable JSON "text database".
    # The old state path is retained only as an automatic migration source.
    player_db_path: Path = Path(os.getenv("GXB_PLAYER_DB_PATH", "./data/player_db.json"))
    state_path: Path = Path(os.getenv("GXB_STATE_PATH", "./state/gxb_state.json"))
    enable_chat_stub: bool = os.getenv("GXB_ENABLE_CHAT_STUB", "1") not in {"0", "false", "False"}
    log_unknown_mids: bool = os.getenv("GXB_LOG_UNKNOWN_MIDS", "1") not in {"0", "false", "False"}
    runtime_log_dir: Path = Path(os.getenv("GXB_RUNTIME_LOG_DIR", "./runtime_logs"))
    log_all_requests: bool = os.getenv("GXB_LOG_ALL_REQUESTS", "1") not in {"0", "false", "False"}
    # Safe keeps the exact proven Stage 1 bootstrap detail set. Wide is useful
    # for later experiments, but it can trip source event listeners before lobby.
    bootstrap_detail_mode: str = os.getenv("GXB_BOOTSTRAP_DETAIL_MODE", "stage3").lower()
    # core keeps MainScene construction conservative. all restores every
    # source-derived FunctionID from Stage 2.2 for later experiments.
    func_mode: str = os.getenv("GXB_FUNC_MODE", "all").lower()
    profile: str = os.getenv("GXB_PROFILE", "established").lower()


    @property
    def res_download_url(self) -> str:
        if self.res_download_url_override:
            base = self.res_download_url_override
        else:
            base = self.self_url
            if base.endswith("/api/v1"):
                base = base[:-len("/api/v1")]
            base = base.rstrip("/") + "/res/"
        return base if base.endswith("/") else base + "/"

    @property
    def client_log_url(self) -> str:
        if self.client_log_url_override:
            return self.client_log_url_override
        base = self.self_url
        if base.endswith("/api/v1"):
            base = base[:-len("/api/v1")]
        return base.rstrip("/") + "/client-log"


SETTINGS = Settings()
