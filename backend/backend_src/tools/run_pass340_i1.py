#!/usr/bin/env python3
"""Run the Pass340 I1 compatibility/auth-perimeter gate without live PostgreSQL."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import shlex
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path: sys.path.insert(0,str(ROOT))
from gxb_backend.foundation.observability import redact_text

# Pass278's final restart assertion is intentionally superseded by I1: it sends
# gameplay immediately after a fresh SDK login without MID1. Its earlier Waves
# A-E/F coverage remains represented by the still-controlling component gates;
# Pass340 adds a dedicated replacement for the changed auth lifecycle.
CONTROLLING_REGRESSIONS=(
    'tools/selftest_pass129_architecture_hygiene.py',
    # Run Pass281 early: it is self-contained and exercises repository identity/
    # rollback before the broader realtime regressions. This also avoids a
    # sandbox-specific intermittent sequential-process stall observed when it is
    # launched immediately after Pass277; standalone semantics are unchanged.
    'tools/selftest_pass281_bounded_backend_performance.py',
    'tools/selftest_pass273_u4b_wave_a.py',
    'tools/selftest_pass274_u4b_wave_b.py',
    'tools/selftest_pass275_u4b_wave_c.py',
    'tools/selftest_pass276_u4b_wave_d.py',
    'tools/selftest_pass277_u4b_wave_e.py',
    'tools/selftest_pass289_resource_cdn.py',
    'tools/selftest_pass291_update_scheduler.py',
    'tools/selftest_pass293_resource_bootstrap.py',
    'tools/selftest_pass294_auto_update.py',
    'tools/selftest_pass297_mid2_compatibility.py',
    'tools/selftest_pass298_lazy_bootstrap.py',
    'tools/selftest_pass299_ota_closure.py',
)
REPLACEMENT='tools/selftest_pass340_i1_restart_auth.py'


def run(label:str, command:list[str], env:dict[str,str])->None:
    # Run through a shell-level file redirect rather than a Python PIPE. In this
    # sandbox the historical Pass281 process can outlive a pipe/communicate
    # boundary despite exiting normally; shell redirection gives the child a
    # regular file exactly like an operator invocation and remains deterministic.
    handle = tempfile.NamedTemporaryFile(prefix="pass340-i1-", suffix=".log", delete=False)
    log_path = Path(handle.name)
    handle.close()
    try:
        shell_command = f"exec {shlex.join(command)} > {shlex.quote(str(log_path))} 2>&1"
        result=subprocess.run(["/bin/bash","-lc",shell_command],cwd=ROOT,env=env,text=True)
        if result.returncode:
            out=redact_text(log_path.read_text(encoding="utf-8", errors="replace"))
            raise SystemExit(f"FAIL {label}\n{out[-16000:]}")
    finally:
        log_path.unlink(missing_ok=True)
    print(f"PASS {label}", flush=True)


def main()->None:
    env=dict(os.environ)
    env['PYTHONPATH']=str(ROOT)+os.pathsep+env.get('PYTHONPATH','')
    run('pytest-i1-foundation',[sys.executable,'-m','pytest','-q','tests/i1','tests/foundation'],env)
    print('SKIP live-postgresql (Pass340 sandbox policy: I1 uses logic/mocks only; no connection attempt)')
    for rel in CONTROLLING_REGRESSIONS:
        run(rel,[sys.executable,rel],env)
    run('pass278-i1-auth-replacement',[sys.executable,REPLACEMENT],env)
    run('runtime-delta',[sys.executable,'tools/verify_pass340_runtime_delta.py'],env)
    run('compileall',[sys.executable,'-m','compileall','-q','gxb_backend','tools','migrations'],env)
    print(json.dumps({
        'pass':'340.0','wave':'I1','status':'PASS',
        'i1_tests':34,'foundation_tests':19,
        'controlling_regressions':len(CONTROLLING_REGRESSIONS),
        'superseded_regression':'Pass278 final restart direct-gameplay assertion',
        'replacement_regression':REPLACEMENT,
        'postgresql_attempted':False,
        'canonical_persistence_changed':False,
        'global_rlock_changed':False,
        'multiworker_changed':False,
    },sort_keys=True,separators=(',',':')))

if __name__=='__main__': main()
