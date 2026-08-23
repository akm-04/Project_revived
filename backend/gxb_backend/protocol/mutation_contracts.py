"""Pass104 source-contract firewall for explicitly routed mutation MIDs."""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping

from gxb_backend.transport.result import EngineTransportResult


@dataclass(frozen=True)
class MutationContract:
    mid: int
    name: str
    domain: str
    source_effect_class: str
    risk_tier: str
    required_capability: str
    backend_capability: str
    enforcement: str
    firewall_fallback: str
    source_evidence: str
    notes: str = ""

    @property
    def phase1_blocked(self) -> bool:
        return self.enforcement == "BLOCK_PHASE1"

    @property
    def phase2_blocked(self) -> bool:
        return self.enforcement == "BLOCK_PHASE2"

    @property
    def firewall_blocked(self) -> bool:
        return self.enforcement in {"BLOCK_PHASE1", "BLOCK_PHASE2"}

    @property
    def is_session(self) -> bool:
        return self.source_effect_class.startswith("SESSION_")


class MutationContractRegistry:
    def __init__(self, contracts: Mapping[int, MutationContract], canonical_block: Mapping[str, Any]) -> None:
        self._contracts = dict(contracts)
        self.canonical_block = dict(canonical_block)

    @classmethod
    def load(cls, path: Path) -> "MutationContractRegistry":
        payload = json.loads(Path(path).read_text(encoding="utf-8"))
        rows = payload.get("contracts")
        block = payload.get("canonical_block")
        if not isinstance(rows, list) or not isinstance(block, dict):
            raise ValueError("mutation contract registry requires contracts[] and canonical_block")
        contracts: dict[int, MutationContract] = {}
        for raw in rows:
            row = MutationContract(**raw)
            previous = contracts.get(row.mid)
            if previous is not None and previous.name != row.name:
                raise ValueError(f"duplicate numeric MID contract {row.mid}: {previous.name}/{row.name}")
            contracts[row.mid] = row
        if int(block.get("http_status", 0)) != 409 or int(block.get("error_code", 0)) != 1:
            raise ValueError("canonical mutation block must remain HTTP409/error_code=1")
        if "error_msg" not in (block.get("forbidden_fields") or []):
            raise ValueError("canonical mutation block must forbid error_msg")
        return cls(contracts, block)

    def contract(self, mid: int) -> MutationContract | None:
        return self._contracts.get(int(mid))

    def values(self):
        return self._contracts.values()


class MutationSafetyFirewall:
    def __init__(self, registry: MutationContractRegistry) -> None:
        self.registry = registry

    def validate_routes(self, handlers: Mapping[int, Any], label_lookup) -> None:
        errors: list[str] = []
        for contract in self.registry.values():
            if contract.mid not in handlers:
                errors.append(f"audited contract is not routed: {contract.name} ({contract.mid})")
                continue
            actual = str(label_lookup(contract.mid))
            if actual != contract.name:
                errors.append(f"MID label drift {contract.mid}: registry={contract.name} runtime={actual}")
            if contract.phase1_blocked and contract.backend_capability != "EXPLICIT_FAIL_CLOSED":
                errors.append(f"phase1 mutation not fail-closed: {contract.name}")
            if contract.phase2_blocked:
                if contract.backend_capability != "EXPLICIT_FAIL_CLOSED":
                    errors.append(f"phase2 session not fail-closed: {contract.name}")
                if contract.source_effect_class not in {"SESSION_PREFLIGHT", "SESSION_START"}:
                    errors.append(f"phase2 block applied outside session entry: {contract.name}")
            if contract.enforcement == "DEFER_TERMINAL" and contract.backend_capability != "SESSION_TERMINAL_PENDING":
                errors.append(f"terminal session capability drift: {contract.name}")
        if errors:
            raise RuntimeError("MutationContractRegistry validation failed:\n- " + "\n- ".join(errors))

    def evaluate(self, mid: int, name: str) -> EngineTransportResult | None:
        contract = self.registry.contract(mid)
        if contract is None or not contract.firewall_blocked:
            return None
        body = {
            "error_code": int(self.registry.canonical_block["error_code"]),
            "msg": str(self.registry.canonical_block["msg"]),
            "blocked_mid": int(mid),
            "blocked_name": str(name),
        }
        return EngineTransportResult(body=body, status_code=int(self.registry.canonical_block["http_status"]))
