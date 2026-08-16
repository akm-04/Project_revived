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
    state_path: Path = Path(os.getenv("GXB_STATE_PATH", "./state/gxb_state.json"))
    enable_chat_stub: bool = os.getenv("GXB_ENABLE_CHAT_STUB", "1") not in {"0", "false", "False"}
    log_unknown_mids: bool = os.getenv("GXB_LOG_UNKNOWN_MIDS", "1") not in {"0", "false", "False"}


SETTINGS = Settings()
