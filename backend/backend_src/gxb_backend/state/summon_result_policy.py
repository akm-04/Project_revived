"""Pass41.2 activation policy for typed Summon result rows."""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path

from .summon_result_plan import SummonResultKind, SummonResultPlan, SummonResultPlanUnavailable


@dataclass(frozen=True)
class SummonResultSemanticPolicy:
    semantic: str
    activation_status: str
    allowed_row_kinds: tuple[SummonResultKind, ...]
    expected_rows: int

    @property
    def active(self) -> bool:
        return self.activation_status in {"tutorial_deterministic_active", "private_policy_active"}


class SummonResultPolicyRegistry:
    DATA_FILE = "summon_result_policy.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load summon result policy {path}: {exc}") from exc
        policies = raw.get("semantic_policies") if isinstance(raw, dict) else None
        if not isinstance(policies, list):
            raise RuntimeError(f"invalid summon result policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self.duplicate_conversion = dict(raw.get("duplicate_conversion") or {})
        self._by_semantic: dict[str, SummonResultSemanticPolicy] = {}
        for row in policies:
            semantic = str(row.get("semantic") or "")
            if not semantic or semantic in self._by_semantic:
                raise RuntimeError(f"invalid/duplicate result semantic policy: {semantic!r}")
            kinds = tuple(SummonResultKind(str(value)) for value in row.get("allowed_row_kinds") or [])
            policy = SummonResultSemanticPolicy(
                semantic=semantic,
                activation_status=str(row.get("activation_status") or "unknown_fail_closed"),
                allowed_row_kinds=kinds,
                expected_rows=max(1, int(row.get("expected_rows") or 1)),
            )
            self._by_semantic[semantic] = policy
        duplicate_status = str(self.duplicate_conversion.get("activation_status") or "")
        supported_duplicate_statuses = {
            "unknown_fail_closed",
            "private_policy_active",
            "recovered_evidence_active",
        }
        if duplicate_status not in supported_duplicate_statuses:
            raise RuntimeError(f"unsupported duplicate-conversion activation status: {duplicate_status}")

        if duplicate_status == "unknown_fail_closed":
            if self.duplicate_conversion.get("quantity_policy") is not None:
                raise RuntimeError("fail-closed duplicate conversion may not install a quantity policy")
            if self.duplicate_conversion.get("quantity_by_initial_star"):
                raise RuntimeError("fail-closed duplicate conversion may not install active quantities")

        if duplicate_status == "private_policy_active":
            if not self.duplicate_conversion.get("quantity_policy"):
                raise RuntimeError("private duplicate conversion requires an explicit quantity policy")
            if not self.duplicate_conversion.get("quantity_by_initial_star"):
                raise RuntimeError("private duplicate conversion requires explicit quantities")

        if duplicate_status == "recovered_evidence_active":
            if not self.duplicate_conversion.get("policy_file"):
                raise RuntimeError("recovered duplicate conversion requires an evidence-backed policy file")
            if not self.duplicate_conversion.get("quantity_by_initial_star"):
                raise RuntimeError("recovered duplicate conversion requires explicit recovered quantities")

    def get(self, semantic: str) -> SummonResultSemanticPolicy | None:
        return self._by_semantic.get(str(semantic))

    def validate_active_plan(self, plan: SummonResultPlan) -> None:
        policy = self.get(plan.semantic)
        if policy is None or not policy.active:
            raise SummonResultPlanUnavailable(f"result semantic is not active: {plan.semantic}")
        if len(plan.rows) != policy.expected_rows:
            raise SummonResultPlanUnavailable("result plan row count differs from active policy")
        for row in plan.rows:
            if row.kind not in policy.allowed_row_kinds:
                raise SummonResultPlanUnavailable(
                    f"result row kind {row.kind.value} is not active for {plan.semantic}"
                )
