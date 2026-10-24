#!/usr/bin/env python3
"""Static CA1 implementation-boundary guard."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errs: list[str] = []

partner = (ROOT / "internal/application/i5/partner_materializer.go").read_text()
lockplan = (ROOT / "internal/application/i5/grant_lock_plan.go").read_text()
service = (ROOT / "internal/application/i5/service.go").read_text()
material = (ROOT / "internal/application/i5/material_cost.go").read_text()
receipts = (ROOT / "internal/application/i5/grant_receipts.go").read_text()

# Architectural amendment and production non-activation.
if "CharacterAssetLockRankMin uint16 = 400" not in partner or "CharacterAssetLockRankMax uint16 = 599" not in partner:
    errs.append("Character Asset lock band is not frozen at 400..599")

for path in (ROOT / "cmd").glob("**/*.go"):
    if "PartnerEntities:" in path.read_text(errors="replace"):
        errs.append(f"production PartnerEntity provider activated in {path.relative_to(ROOT)}")

# CA1 owns no durable Character schema/migration. The exact Pass509 high-water
# remains authoritative; CA1 itself adds no production migration.
migrations = sorted((ROOT / "migrations").glob("*.sql"))
if not migrations or migrations[-1].name != "00013_i6c_guild_replay_repair.sql":
    errs.append("CA1 unexpectedly changed production migration high-water")

# PartnerEntity must branch outside fungible content and SpecializedDomain stays closed.
partner_branch = lockplan.find("if line.Kind == grant.PartnerEntity")
content_resolve = lockplan.find("s.Content.ResolveResourceTx", partner_branch)
if partner_branch < 0 or content_resolve < 0:
    errs.append("PartnerEntity/fungible preflight structure missing")
if "if line.Kind == grant.SpecializedDomain" not in lockplan or "return grantPreflight{}, ErrUnsupportedGrantDestination" not in lockplan:
    errs.append("SpecializedDomain is not fail-closed in Grant preflight")
if "case grant.SpecializedDomain:" not in service or "ErrUnsupportedGrantDestination" not in service:
    errs.append("SpecializedDomain is not fail-closed in Grant apply")

# Entity receipt extension must be additive while fungible v2 remains available.
if 'schema := "gxb.i5.grant.v2"' not in service or 'schema = "gxb.i5.grant.v3"' not in service:
    errs.append("conditional Grant v2/v3 receipt split missing")
if '"gxb.i5.grant.v1", "gxb.i5.grant.v2", "gxb.i5.grant.v3"' not in receipts:
    errs.append("Grant receipt decoder does not preserve v1/v2 and accept v3")

# Shared material debit remains scalar+stack and contains no SQL/transaction lifecycle.
for forbidden in ["grant.Temporal", "grant.PlayerExp", "grant.PartnerEntity", "grant.SpecializedDomain"]:
    # Allowed in comments describing the exclusion; reject operational switch/cost construction only.
    if re.search(rf"Kind:\s*{re.escape(forbidden)}", material):
        errs.append(f"material debit operationally includes forbidden kind {forbidden}")
for pattern, label in [
    (r"\.Begin\s*\(", "transaction begin"),
    (r"\.Commit\s*\(", "transaction commit"),
    (r"\.Rollback\s*\(", "transaction rollback"),
    (r"(?i)\b(?:SELECT|UPDATE|INSERT|DELETE)\b[^\n]*\b(?:FROM|INTO|SET)\b", "inline SQL"),
]:
    if re.search(pattern, material):
        errs.append(f"material debit contains forbidden {label}")

# Redeem R0 must force progression into the complete suffix before explicit eligibility read.
redeem_pos = service.find("CA1-R0: Redeem must acquire the complete lower-to-higher Grant")
forced = service.find("ForceProgression: true", redeem_pos)
acquire = service.find("s.acquireGrantLocksTx", forced)
progression = service.find("s.Store.LockProgressionTx", acquire)
if min(redeem_pos, forced, acquire, progression) < 0 or not (redeem_pos < forced < acquire < progression):
    errs.append("Redeem CA1-R0 complete-suffix ordering guard missing")

# No CA1 production bootstrap/MID1 registration should appear.
for path in list((ROOT / "cmd").glob("**/*.go")) + list((ROOT / "internal/adapters/stockruntime").glob("**/*.go")):
    text = path.read_text(errors="replace")
    if "PartnerEntityMaterializer" in text or "GrantMaterialization" in text:
        errs.append(f"CA1 entity seam leaked into stock/bootstrap runtime: {path.relative_to(ROOT)}")

if errs:
    print("CA1 STATIC BOUNDARY VALIDATION: FAIL")
    for err in errs:
        print(" -", err)
    raise SystemExit(1)

print("CA1 STATIC BOUNDARY VALIDATION: PASS")
print("no Character durable schema/provider activation; PartnerEntity typed seam + scalar/stack material debit + Redeem R0 remain bounded")
