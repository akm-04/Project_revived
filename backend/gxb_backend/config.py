"""Runtime configuration for the modular GXB backend."""

from __future__ import annotations

import os
import socket
from dataclasses import dataclass
from pathlib import Path


_PROJECT_ROOT = Path(__file__).resolve().parent.parent


def _detect_advertise_host() -> str:
    """Return a likely device-reachable local IPv4 address.

    No LAN address and no external probe address is hard-coded. On Linux we
    read the default-route interface from /proc/net/route and ask the kernel for
    that interface's IPv4 address. Portable hostname/address enumeration is the
    fallback. GXB_ADVERTISE_HOST remains an explicit override for unusual
    multi-interface setups.
    """
    override = os.getenv("GXB_ADVERTISE_HOST", "").strip()
    if override:
        return override

    # Linux/RHEL path: discover the interface used by the default route without
    # sending any packet to an arbitrary public IP.
    try:
        import fcntl
        import struct

        default_iface = ""
        with open("/proc/net/route", "r", encoding="utf-8") as fh:
            next(fh, None)
            for line in fh:
                fields = line.split()
                if len(fields) >= 4 and fields[1] == "00000000":
                    flags = int(fields[3], 16)
                    if flags & 0x1:  # RTF_UP
                        default_iface = fields[0]
                        break
        if default_iface:
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            try:
                packed = struct.pack("256s", default_iface[:15].encode("utf-8"))
                result = fcntl.ioctl(sock.fileno(), 0x8915, packed)  # SIOCGIFADDR
                host = socket.inet_ntoa(result[20:24]).strip()
                if host and not host.startswith("127."):
                    return host
            finally:
                sock.close()
    except Exception:
        pass

    # Portable fallback: enumerate this host's own resolved IPv4 addresses and
    # prefer a non-loopback private address.
    candidates: list[str] = []
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            host = str(info[4][0]).strip()
            if host and host not in candidates:
                candidates.append(host)
    except OSError:
        pass

    for host in candidates:
        if not host.startswith("127."):
            return host
    return "127.0.0.1"


_DEFAULT_ADVERTISE_HOST = _detect_advertise_host()
_DEFAULT_ENGINE_PORT = int(os.getenv("GXB_ENGINE_PORT", "9000"))
_DEFAULT_STATIC_ASSET_ROOT = _PROJECT_ROOT / "local_assets"


@dataclass(frozen=True)
class Settings:
    bind_host: str = os.getenv("GXB_BIND", "0.0.0.0")
    advertise_host: str = _DEFAULT_ADVERTISE_HOST
    sdk_port: int = int(os.getenv("GXB_SDK_PORT", "5000"))
    engine_port: int = _DEFAULT_ENGINE_PORT
    chat_host: str = os.getenv("GXB_CHAT_HOST", "").strip() or _DEFAULT_ADVERTISE_HOST
    chat_port: int = int(os.getenv("GXB_CHAT_PORT", "9100"))
    self_url: str = (
        os.getenv("GXB_SELF_URL", "").strip()
        or f"http://{_DEFAULT_ADVERTISE_HOST}:{_DEFAULT_ENGINE_PORT}/api/v1"
    )
    # The Lua ErrorLogPoster uploads hidden engine/Lua/resource errors here.
    # Empty override derives /client-log from GXB_SELF_URL so custom hosts work.
    client_log_url_override: str = os.getenv("GXB_CLIENT_LOG_URL", "").strip()
    # EOL resource gateway. The original client only attempts lazy downloads
    # when center discovery supplies res_download_url.
    resource_probe_enabled: bool = os.getenv("GXB_RESOURCE_PROBE", "0") not in {"0", "false", "False"}
    resource_service_enabled: bool = os.getenv("GXB_RESOURCE_SERVICE", "1") not in {"0", "false", "False"}
    res_download_url_override: str = os.getenv("GXB_RES_DOWNLOAD_URL", "").strip()
    resource_catalog_path: Path = Path(os.getenv(
        "GXB_RESOURCE_CATALOG",
        str(_PROJECT_ROOT / "data/resource_catalog/resource_catalog.json"),
    ))
    resource_verify_md5: bool = os.getenv("GXB_RESOURCE_VERIFY_MD5", "1") not in {"0", "false", "False"}
    # Normal deployment is now deterministic: put recovered assets under
    # <backend>/local_assets/res.  Environment roots remain optional overrides
    # for diagnostics/backwards compatibility, not a requirement.
    static_asset_root: Path = Path(os.getenv(
        "GXB_STATIC_ASSET_ROOT",
        str(_DEFAULT_STATIC_ASSET_ROOT),
    )).expanduser()
    asset_root_spec: str = (
        os.getenv("GXB_ASSET_ROOTS", "").strip()
        or os.getenv("GXB_ASSET_ROOT", "").strip()
    )
    asset_discovery_depth: int = int(os.getenv("GXB_ASSET_DISCOVERY_DEPTH", "10"))
    campaign_asset_requirements_path: Path = Path(os.getenv(
        "GXB_CAMPAIGN_ASSET_REQUIREMENTS",
        str(_PROJECT_ROOT / "data/campaign_asset_requirements.json"),
    ))
    player_db_path: Path = Path(os.getenv("GXB_PLAYER_DB_PATH", str(_PROJECT_ROOT / "data/player_db.json")))
    state_path: Path = Path(os.getenv("GXB_STATE_PATH", str(_PROJECT_ROOT / "state/gxb_state.json")))
    enable_chat_stub: bool = os.getenv("GXB_ENABLE_CHAT_STUB", "1") not in {"0", "false", "False"}
    log_unknown_mids: bool = os.getenv("GXB_LOG_UNKNOWN_MIDS", "1") not in {"0", "false", "False"}
    runtime_log_dir: Path = Path(os.getenv("GXB_RUNTIME_LOG_DIR", str(_PROJECT_ROOT / "runtime_logs")))
    log_all_requests: bool = os.getenv("GXB_LOG_ALL_REQUESTS", "1") not in {"0", "false", "False"}
    bootstrap_detail_mode: str = os.getenv("GXB_BOOTSTRAP_DETAIL_MODE", "stage3").lower()
    func_mode: str = os.getenv("GXB_FUNC_MODE", "all").lower()
    profile: str = os.getenv("GXB_PROFILE", "established").lower()

    @property
    def asset_roots(self) -> tuple[Path, ...]:
        roots: list[Path] = []
        if self.asset_root_spec:
            # os.pathsep lets Linux users pass /a:/b while remaining portable.
            for raw in self.asset_root_spec.split(os.pathsep):
                raw = raw.strip()
                if raw:
                    roots.append(Path(raw).expanduser())
        else:
            # Fixed normal path. It is returned even when absent so startup can
            # clearly report exactly where the operator should place assets.
            roots.append(self.static_asset_root)
        return tuple(roots)

    @property
    def asset_root_mode(self) -> str:
        return "environment override" if self.asset_root_spec else "backend-local static store"

    @property
    def resource_gateway_enabled(self) -> bool:
        return self.resource_service_enabled or self.resource_probe_enabled

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
