"""Physical maintenance gate shared by HTTP, realtime, scheduler and operator tooling."""
from __future__ import annotations
import os
from dataclasses import dataclass
from pathlib import Path

class MaintenanceGateError(RuntimeError): pass

@dataclass(frozen=True, slots=True)
class MaintenanceGate:
    path: Path
    def active(self) -> bool: return self.path.is_file()
    def enable(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True, mode=0o750)
        temporary=self.path.with_name(f".{self.path.name}.{os.getpid()}.tmp")
        try:
            descriptor=os.open(temporary,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o640)
            with os.fdopen(descriptor,"w",encoding="utf-8") as stream:
                stream.write("GXB MAINTENANCE: PUBLIC ADMISSIONS CLOSED\n"); stream.flush(); os.fsync(stream.fileno())
            os.replace(temporary,self.path)
        finally: temporary.unlink(missing_ok=True)
    def disable(self) -> None:
        try: self.path.unlink(missing_ok=True)
        except OSError as exc: raise MaintenanceGateError("PostgreSQL may already be canonical; maintenance remains closed because marker removal failed") from exc

class MaintenanceGatedSchedulerProcess:
    def __init__(self,delegate,gate:MaintenanceGate)->None: self.delegate=delegate; self.gate=gate; self._recovered=False
    @property
    def scheduler(self): return self.delegate.scheduler
    @property
    def projections(self): return self.delegate.projections
    def recover_startup(self)->int:
        if self.gate.active(): return 0
        self._recovered=True; return int(self.delegate.recover_startup())
    def run_once(self)->tuple[int,int]:
        if self.gate.active(): return 0,0
        if not self._recovered: self.recover_startup()
        return self.delegate.run_once()
    def run_forever(self,*,stop=lambda:False)->None:
        while not stop():
            scheduled,projected=self.run_once()
            if scheduled==0 and projected==0: self.delegate.sleep(self.delegate.settings.poll_interval_seconds)
