from pathlib import Path
import hashlib
import os
import subprocess
import sys
import time
from types import SimpleNamespace

import pytest

from gxb_backend.realtime.gateway import RealtimeGateway, RealtimeGatewaySettings
from gxb_backend.runtime.authority import CutoverEvidence, RuntimeAuthorityError, RuntimeAuthorityRepository
from gxb_backend.runtime.config import ProductionRuntimeSettings, RuntimeConfigurationError
from gxb_backend.runtime.maintenance import MaintenanceGate, MaintenanceGatedSchedulerProcess

ROOT = Path(__file__).resolve().parents[2]


def evidence(**overrides):
    values = dict(
        source_archive_sha256="a"*64, migration_report_sha256="b"*64,
        backup_restore_report_sha256="c"*64, client_readiness_report_sha256="d"*64,
        immutable_json_archive_path="/var/lib/gxb/archive/server-state.tar.gz",
    )
    values.update(overrides)
    return CutoverEvidence(**values)


def test_cutover_evidence_requires_every_frozen_i8_gate():
    assert evidence().validated()["worker_count"] == 1
    with pytest.raises(RuntimeAuthorityError): evidence(worker_count=2).validated()
    with pytest.raises(RuntimeAuthorityError): evidence(json_writes_stopped=False).validated()
    with pytest.raises(RuntimeAuthorityError): evidence(src64_crosschecked=False).validated()


def test_runtime_config_preserves_one_worker_default_after_i9_widening():
    base = {"GXB_DATABASE_URL":"postgresql+psycopg://u:p@localhost/gxb"}
    assert ProductionRuntimeSettings.from_env(base).http_workers == 1


def test_deployment_keeps_bounded_workers_and_three_processes():
    gunicorn = (ROOT/"deploy/gunicorn.conf.py").read_text()
    assert 'GXB_HTTP_WORKERS", "1"' in gunicorn
    assert "workers not in (1, 2, 4)" in gunicorn and 'worker_class = "gthread"' in gunicorn
    assert "unix:/run/gxb/http.sock" in gunicorn and "preload_app = False" in gunicorn
    for name in ("gxb-http.service", "gxb-realtime.service", "gxb-scheduler.service"):
        assert (ROOT/"deploy/systemd"/name).is_file()
    assert (ROOT/"deploy/systemd/gxb.target").is_file()
    nginx = (ROOT/"deploy/nginx/gxb.conf").read_text()
    assert "unix:/run/gxb/http.sock" in nginx
    assert "-f /run/gxb/maintenance" in nginx and "return 503" in nginx


def test_json_archive_is_deterministic(tmp_path):
    source=tmp_path/"state"; source.mkdir(); (source/"a.json").write_text('{"x":1}\n')
    outputs=[]
    for name in ("one.tar.gz","two.tar.gz"):
        out=tmp_path/name
        subprocess.run([sys.executable,str(ROOT/"tools/pass347_i8_cutover.py"),"seal-json-archive","--source-root",str(source),"--output",str(out)],check=True,capture_output=True,text=True)
        outputs.append(hashlib.sha256(out.read_bytes()).hexdigest())
    assert outputs[0] == outputs[1]


def test_runtime_adapter_never_constructs_legacy_json_authority():
    text=(ROOT/"gxb_backend/runtime/state_repository.py").read_text()
    assert "MultiUserDatabase" not in text
    assert "del self._lock" in text and "with self._lock" not in text
    assert "TransactionBoundPostgresPlayerStateStore" in text


def test_prepared_start_requires_physical_maintenance_gate():
    repository = RuntimeAuthorityRepository()

    class Connection:
        def execute(self, statement):
            del statement
            return SimpleNamespace(mappings=lambda: SimpleNamespace(first=lambda: {"authority": "PREPARED"}))

    with pytest.raises(RuntimeAuthorityError):
        repository.require_service_start(Connection(), maintenance_active=False)
    assert repository.require_service_start(Connection(), maintenance_active=True)["authority"] == "PREPARED"


def test_maintenance_marker_is_idempotent_and_scheduler_pauses(tmp_path):
    gate = MaintenanceGate(tmp_path / "runtime" / "maintenance")
    gate.enable()
    gate.enable()
    assert gate.active() and gate.path.read_text().startswith("GXB MAINTENANCE")

    class Delegate:
        settings = SimpleNamespace(poll_interval_seconds=0.001)
        scheduler = object()
        projections = object()
        sleep = staticmethod(lambda seconds: None)
        def recover_startup(self): raise AssertionError("must remain paused")
        def run_once(self): raise AssertionError("must remain paused")

    process = MaintenanceGatedSchedulerProcess(Delegate(), gate)
    assert process.recover_startup() == 0
    assert process.run_once() == (0, 0)
    gate.disable()
    assert not gate.active()


def test_realtime_listener_starts_but_durable_work_waits_for_gate(tmp_path):
    gate = MaintenanceGate(tmp_path / "maintenance")
    gate.enable()
    calls = []

    class Server:
        def start(self): calls.append("server-start")
        def stop(self): calls.append("server-stop")
    class Dispatcher:
        def recover_stale_claims(self, **kwargs): calls.append("recover")
        def poll_once(self): calls.append("poll")
    class Sweeper:
        def sweep_once(self): calls.append("sweep")

    gateway = RealtimeGateway(
        Server(), Dispatcher(), Sweeper(), paused=gate.active,
        settings=RealtimeGatewaySettings(poll_interval_seconds=0.01, liveness_interval_seconds=0.01),
    )
    gateway.start()
    time.sleep(0.03)
    assert "server-start" in calls and "recover" not in calls and "poll" not in calls and "sweep" not in calls
    gate.disable()
    time.sleep(0.04)
    gateway.stop()
    assert "recover" in calls and "poll" in calls and "server-stop" in calls


def test_operator_open_keeps_gate_until_separate_verified_release():
    script = (ROOT / "tools/pass347_i8_cutover.py").read_text()
    open_branch = script[script.index('else:\n                if not gate.active()'):]
    assert "gate.disable()" not in open_branch
    assert "require_postgresql(connection)" in script
