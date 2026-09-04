#!/usr/bin/env python3
"""Run the reproducible offline Pass346 test and regression gate."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEGACY = (
    "tools/selftest_pass129_architecture_hygiene.py",
    "tools/selftest_pass281_bounded_backend_performance.py",
    "tools/selftest_pass273_u4b_wave_a.py", "tools/selftest_pass274_u4b_wave_b.py",
    "tools/selftest_pass275_u4b_wave_c.py", "tools/selftest_pass276_u4b_wave_d.py",
    "tools/selftest_pass277_u4b_wave_e.py", "tools/selftest_pass289_resource_cdn.py",
    "tools/selftest_pass291_update_scheduler.py", "tools/selftest_pass293_resource_bootstrap.py",
    "tools/selftest_pass294_auto_update.py", "tools/selftest_pass297_mid2_compatibility.py",
    "tools/selftest_pass298_lazy_bootstrap.py", "tools/selftest_pass299_ota_closure.py",
)


def run(label: str, command: list[str], env: dict[str, str]) -> None:
    result = subprocess.run(command, cwd=ROOT, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result.returncode:
        raise SystemExit(f"FAIL {label}\n{result.stdout[-20000:]}")
    print(f"PASS {label}", flush=True)


def main() -> None:
    env = dict(os.environ)
    env["PYTHONPATH"] = str(ROOT) + (os.pathsep + env["PYTHONPATH"] if env.get("PYTHONPATH") else "")
    run("pytest-273-offline", [sys.executable, "-m", "pytest", "--import-mode=importlib", "-q"], env)
    for rel in LEGACY:
        run(rel, [sys.executable, rel], env)
    run("pass346-invariants", [sys.executable, "tools/verify_pass346_i7_invariants.py"], env)
    run("compileall", [sys.executable, "-m", "compileall", "-q", "gxb_backend", "tools", "migrations"], env)
    print(json.dumps({
        "pass": "346.0", "wave": "I7", "status": "PASS",
        "offline_tests": 273, "live_postgresql_tests_separate": 2,
        "controlling_regressions": len(LEGACY), "traffic_open": False,
        "json_canonical_changed": False, "global_rlock_changed": False,
        "multiworker_changed": False,
    }, sort_keys=True, separators=(",", ":")))


if __name__ == "__main__":
    main()
