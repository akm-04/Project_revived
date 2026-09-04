#!/usr/bin/env python3
"""Run the Pass339 I0 foundation gate and controlling Pass299 regressions."""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from gxb_backend.foundation.observability import redact_text


CONTROLLING_REGRESSIONS = (
    "tools/selftest_pass129_architecture_hygiene.py",
    "tools/selftest_pass273_u4b_wave_a.py",
    "tools/selftest_pass274_u4b_wave_b.py",
    "tools/selftest_pass275_u4b_wave_c.py",
    "tools/selftest_pass276_u4b_wave_d.py",
    "tools/selftest_pass277_u4b_wave_e.py",
    "tools/selftest_pass278_u4b_wave_f.py",
    # Pass280 is intentionally omitted: Pass281 formally reverted/superseded it.
    "tools/selftest_pass281_bounded_backend_performance.py",
    "tools/selftest_pass289_resource_cdn.py",
    "tools/selftest_pass291_update_scheduler.py",
    "tools/selftest_pass293_resource_bootstrap.py",
    "tools/selftest_pass294_auto_update.py",
    "tools/selftest_pass297_mid2_compatibility.py",
    "tools/selftest_pass298_lazy_bootstrap.py",
    "tools/selftest_pass299_ota_closure.py",
)


def run(label: str, command: list[str], env: dict[str, str]) -> None:
    result = subprocess.run(
        command,
        cwd=ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if result.returncode:
        output = redact_text(result.stdout or "")
        raise SystemExit(f"FAIL {label}\n{output[-12000:]}")
    print(f"PASS {label}")


def main() -> None:
    env = dict(os.environ)
    env["PYTHONPATH"] = str(ROOT) + os.pathsep + env.get("PYTHONPATH", "")

    run("pytest-foundation", [sys.executable, "-m", "pytest", "-q", "tests/foundation"], env)
    if env.get("GXB_TEST_DATABASE_URL"):
        run(
            "pytest-postgresql",
            [sys.executable, "-m", "pytest", "-q", "-m", "postgresql", "tests/integration"],
            env,
        )
    else:
        print("SKIP pytest-postgresql (GXB_TEST_DATABASE_URL not set)")

    for relative in CONTROLLING_REGRESSIONS:
        run(relative, [sys.executable, relative], env)
    run(
        "runtime-invariant-manifest",
        [sys.executable, "tools/verify_pass339_runtime_invariants.py"],
        env,
    )
    run("compileall", [sys.executable, "-m", "compileall", "-q", "gxb_backend", "tools", "migrations"], env)
    print(
        json.dumps(
            {
                "pass": "339.0",
                "wave": "I0",
                "status": "PASS",
                "foundation": True,
                "postgresql_integration": bool(env.get("GXB_TEST_DATABASE_URL")),
                "controlling_regressions": len(CONTROLLING_REGRESSIONS),
                "client_changed": False,
                "gameplay_behavior_changed": False,
            },
            sort_keys=True,
            separators=(",", ":"),
        )
    )


if __name__ == "__main__":
    main()
