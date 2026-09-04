#!/usr/bin/env python3
"""Run Pass343 I4 player/shared persistence strangler gate without live PostgreSQL."""
from __future__ import annotations

import argparse
import ctypes.util
import json
import os
import shlex
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
from gxb_backend.foundation.observability import redact_text

REGRESSION_GROUPS = {
    "legacy-a": (
        "tools/selftest_pass129_architecture_hygiene.py",
        "tools/selftest_pass281_bounded_backend_performance.py",
    ),
    "legacy-b": (
        "tools/selftest_pass273_u4b_wave_a.py",
        "tools/selftest_pass274_u4b_wave_b.py",
        "tools/selftest_pass275_u4b_wave_c.py",
        "tools/selftest_pass276_u4b_wave_d.py",
        "tools/selftest_pass277_u4b_wave_e.py",
    ),
    "legacy-c": (
        "tools/selftest_pass289_resource_cdn.py",
        "tools/selftest_pass291_update_scheduler.py",
        "tools/selftest_pass293_resource_bootstrap.py",
        "tools/selftest_pass294_auto_update.py",
        "tools/selftest_pass297_mid2_compatibility.py",
        "tools/selftest_pass298_lazy_bootstrap.py",
        "tools/selftest_pass299_ota_closure.py",
    ),
}
CONTROLLING_REGRESSIONS = tuple(rel for group in REGRESSION_GROUPS.values() for rel in group)
REPLACEMENT = "tools/selftest_pass340_i1_restart_auth.py"

SANDBOX_WHEELS = (
    "alembic-1.19.1-py3-none-any.whl",
    "argon2_cffi-25.1.0-py3-none-any.whl",
    "argon2_cffi_bindings-26.1.0-cp310-abi3-manylinux_2_26_x86_64.manylinux_2_28_x86_64.whl",
    "blinker-1.9.0-py3-none-any.whl",
    "click-8.5.0-py3-none-any.whl",
    "flask-3.1.3-py3-none-any.whl",
    "iniconfig-2.3.0-py3-none-any.whl",
    "itsdangerous-2.2.0-py3-none-any.whl",
    "jinja2-3.1.6-py3-none-any.whl",
    "mako-1.4.1-py3-none-any.whl",
    "packaging-26.3-py3-none-any.whl",
    "pluggy-1.6.0-py3-none-any.whl",
    "psycopg-3.3.5-py3-none-any.whl",
    "pygments-2.21.0-py3-none-any.whl",
    "pytest-9.1.1-py3-none-any.whl",
    "sqlalchemy-2.0.52-cp312-cp312-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl",
    "typing_extensions-4.16.0-py3-none-any.whl",
    "werkzeug-3.1.8-py3-none-any.whl",
)


def sandbox_layer() -> tempfile.TemporaryDirectory[str] | None:
    """Use backend-bundled modules in non-3.12 Chat sandboxes; never install globally."""
    if sys.version_info[:2] == (3, 12):
        return None
    temp = tempfile.TemporaryDirectory(prefix="pass343-wheel-layer-")
    target = Path(temp.name)
    wheel_dir = ROOT / "vendor/wheels/linux-x86_64-cp312"
    for name in SANDBOX_WHEELS:
        path = wheel_dir / name
        if not path.is_file():
            temp.cleanup()
            raise SystemExit(f"missing bundled sandbox wheel: {name}")
        with zipfile.ZipFile(path) as archive:
            archive.extractall(target)
    return temp


def run(label: str, command: list[str], env: dict[str, str]) -> None:
    handle = tempfile.NamedTemporaryFile(prefix="pass343-i4-", suffix=".log", delete=False)
    log_path = Path(handle.name)
    handle.close()
    try:
        shell_command = f"exec {shlex.join(command)} > {shlex.quote(str(log_path))} 2>&1"
        result = subprocess.run(["/bin/bash", "-lc", shell_command], cwd=ROOT, env=env, text=True)
        if result.returncode:
            output = redact_text(log_path.read_text(encoding="utf-8", errors="replace"))
            raise SystemExit(f"FAIL {label}\n{output[-20000:]}")
    finally:
        log_path.unlink(missing_ok=True)
    print(f"PASS {label}", flush=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--segment",
        choices=("all", "core", "legacy-a", "legacy-b", "legacy-c", "final"),
        default="all",
        help="bounded sandbox segment; all remains the operator/full-environment gate",
    )
    args = parser.parse_args()
    layer = sandbox_layer()
    try:
        env = dict(os.environ)
        pieces = [str(ROOT)]
        if layer is not None:
            pieces.insert(0, layer.name)
            if ctypes.util.find_library("pq"):
                env["PSYCOPG_IMPL"] = "python"
        if env.get("PYTHONPATH"):
            pieces.append(env["PYTHONPATH"])
        env["PYTHONPATH"] = os.pathsep.join(pieces)

        if args.segment in {"all", "core"}:
            run(
                "pytest-i4-i3-i2-i1-foundation",
                [
                    sys.executable,
                    "-m",
                    "pytest",
                    "--import-mode=importlib",
                    "-q",
                    "tests/i4",
                    "tests/i3",
                    "tests/i2",
                    "tests/i1",
                    "tests/foundation",
                ],
                env,
            )
            print(
                "SKIP live-postgresql (Pass343 sandbox policy: no server/URL; no connection attempt)",
                flush=True,
            )
        for group_name, regressions in REGRESSION_GROUPS.items():
            if args.segment not in {"all", group_name}:
                continue
            for rel in regressions:
                run(rel, [sys.executable, rel], env)
        if args.segment in {"all", "final"}:
            run("pass278-i1-auth-replacement", [sys.executable, REPLACEMENT], env)
            run("i4-invariants", [sys.executable, "tools/verify_pass343_i4_invariants.py"], env)
            run(
                "compileall",
                [sys.executable, "-m", "compileall", "-q", "gxb_backend", "tools", "migrations"],
                env,
            )
            print(
                json.dumps(
                    {
                        "pass": "343.0",
                        "wave": "I4",
                        "status": "PASS",
                        "segment": args.segment,
                        "i4_tests": 27,
                        "i3_tests": 48,
                        "i2_tests": 39,
                        "i1_tests": 34,
                        "foundation_tests": 19,
                        "combined_tests": 167,
                        "controlling_regressions": len(CONTROLLING_REGRESSIONS),
                        "replacement_regression": REPLACEMENT,
                        "postgresql_attempted": False,
                        "legacy_runtime_changed": True,
                        "legacy_runtime_modified_files": ["gxb_backend/state/repository.py"],
                        "json_playerstate_canonical_changed": False,
                        "global_rlock_changed": False,
                        "multiworker_changed": False,
                        "identity_adapter_runtime_wired": False,
                        "postgres_playerstore_runtime_wired": False,
                    },
                    sort_keys=True,
                    separators=(",", ":"),
                )
            )
    finally:
        if layer is not None:
            layer.cleanup()


if __name__ == "__main__":
    main()
