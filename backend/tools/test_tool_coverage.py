#!/usr/bin/env python3
"""Prove every guard tool is either run by tools/check.sh or explicitly retired.

Law C (PROVENANCE_AND_COVERAGE_V1): the population is derived from the tree,
never from the list check.sh happens to name. A member is a tools/validate_*.py
script or a tools/*.py script that declares a --check option. Any member that
check.sh never invokes must appear in UNWIRED with a reason; a retirement also
names the file:line that replaced it, and that citation must resolve.
"""

import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / "tools"
CHECK = TOOLS / "check.sh"
SELF = "tools/test_tool_coverage.py"

# Lead triage 2026-11-16: these validators assert one frozen stage's exact tree
# (its migration high-water, toolchain pin, content revision and that stage's
# text markers). Later stages moved all of those by design, so each fails on
# the current tree without a live defect; the cited line is the validator's
# own frozen pin, and the stage's acceptance is recorded in its sealed PassMap.
HISTORICAL = "historical stage snapshot; fails on any later tree by design"

# Unwired members. Reason first, then the path:line that justifies leaving it
# unwired: the replacement guard, or for HISTORICAL the validator's own pin.
UNWIRED = {
    "tools/validate_ca1.py": (HISTORICAL, "tools/validate_ca1.py:26"),
    "tools/validate_ca2_1.py": (HISTORICAL, "tools/validate_ca2_1.py:10"),
    "tools/validate_ca2_2.py": (HISTORICAL, "tools/validate_ca2_2.py:8"),
    "tools/validate_ca2_3.py": (HISTORICAL, "tools/validate_ca2_3.py:8"),
    "tools/validate_ca3_1.py": (HISTORICAL, "tools/validate_ca3_1.py:43"),
    "tools/validate_ca3_2.py": (HISTORICAL, "tools/validate_ca3_2.py:74"),
    "tools/validate_ca4_2a.py": (HISTORICAL, "tools/validate_ca4_2a.py:17"),
    "tools/validate_ca4_2b.py": (HISTORICAL, "tools/validate_ca4_2b.py:43"),
    "tools/validate_ca4_2c.py": (HISTORICAL, "tools/validate_ca4_2c.py:38"),
    "tools/validate_ca4_2d.py": (HISTORICAL, "tools/validate_ca4_2d.py:46"),
    "tools/validate_ca4_3a_a.py": (HISTORICAL, "tools/validate_ca4_3a_a.py:21"),
    "tools/validate_ca4_3a_b.py": (HISTORICAL, "tools/validate_ca4_3a_b.py:55"),
    "tools/validate_ca4_3b.py": (HISTORICAL, "tools/validate_ca4_3b.py:18"),
    "tools/validate_ca4_3b_stage_c.py": (HISTORICAL, "tools/validate_ca4_3b_stage_c.py:18"),
    "tools/validate_ca4_3b_stage_d.py": (HISTORICAL, "tools/validate_ca4_3b_stage_d.py:34"),
    "tools/validate_ca4_4a.py": (HISTORICAL, "tools/validate_ca4_4a.py:13"),
    "tools/validate_ca4_4a_i1.py": (HISTORICAL, "tools/validate_ca4_4a_i1.py:16"),
    "tools/validate_ca4_4a_i2.py": (HISTORICAL, "tools/validate_ca4_4a_i2.py:16"),
    "tools/validate_ca4_5.py": (HISTORICAL, "tools/validate_ca4_5.py:13"),
    "tools/validate_ca5_2.py": (HISTORICAL, "tools/validate_ca5_2.py:16"),
    "tools/validate_ca5_3.py": (HISTORICAL, "tools/validate_ca5_3.py:29"),
    "tools/validate_ca5_4.py": (HISTORICAL, "tools/validate_ca5_4.py:33"),
    "tools/validate_i7a4a.py": (HISTORICAL, "tools/validate_i7a4a.py:9"),
    "tools/validate_i7a4b.py": (HISTORICAL, "tools/validate_i7a4b.py:9"),
    "tools/validate_r6.py": (HISTORICAL, "tools/validate_r6.py:32"),
    "tools/build_i6c_guild_policy.py": (
        "needs the pinned oracle archive; the embedded policy is validated at load",
        "internal/content/guildpolicy/policy_test.go:5",
    ),
    "tools/generate_builtin_content.py": (
        "reached by the wired source oracle",
        "tools/check_ca4_1_source_oracle.py:117",
    ),
    "tools/generate_combat_corpus.py": (
        "embedded corpus manifest is verified by its package test",
        "internal/content/combatcorpus/corpus_test.go:11",
    ),
    "tools/generate_direct_sbom.py": (
        "superseded by the resolved SBOM generator, which check.sh runs",
        "tools/generate_resolved_sbom.py:5",
    ),
    "tools/guild_campaign_catalog.py": (
        "needs the pinned archive; the embedded catalog is validated at load",
        "internal/content/guildcampaigncatalog/catalog.go:74",
    ),
    "tools/guild_campaign_policy.py": (
        "needs the pinned archive; the embedded policy is validated at load",
        "internal/content/guildcampaignpolicy/policy_test.go:5",
    ),
    "tools/guild_rental_policy.py": (
        "needs the pinned archive; the embedded policy is validated at load",
        "internal/content/guildrentalpolicy/policy_test.go:5",
    ),
    "tools/guild_tea_policy.py": (
        "needs the pinned archive; the embedded policy is loaded by the native suite",
        "internal/integration/playerdisplay/i9_9a_activity_native_test.go:356",
    ),
    "tools/payload_inventory.py": (
        "needs a live database; merge and --check rules are unit-tested",
        "tools/test_payload_inventory.py:5",
    ),
    "tools/player_data_manifest.py": (
        "needs a live database; exercised by the postgres-tagged native test",
        "internal/integration/datacontract/manifest_native_test.go:31",
    ),
    "tools/player_restore_plan.py": (
        "needs a live database; exercised by the postgres-tagged native test",
        "internal/integration/datacontract/manifest_native_test.go:35",
    ),
    "tools/retention_references.py": (
        "needs a live database; exercised by the postgres-tagged native test",
        "internal/integration/datacontract/retention_references_native_test.go:18",
    ),
}

CHECK_OPTION = re.compile(r"add_argument\([^)]*['\"]--check['\"]")
INVOCATION = re.compile(r"python3\s+(tools/[\w./-]+\.py)")


def check_invocations():
    return set(INVOCATION.findall(CHECK.read_text(encoding="utf-8")))


def population():
    members = set()
    for path in TOOLS.glob("*.py"):
        if path.name.startswith("test_"):
            continue
        relative = "tools/" + path.name
        if path.name.startswith("validate_"):
            members.add(relative)
            continue
        if CHECK_OPTION.search(path.read_text(encoding="utf-8")):
            members.add(relative)
    return members


def citation_problem(citation):
    path_text, _, line_text = citation.rpartition(":")
    path = ROOT / path_text
    if not path_text or not line_text.isdigit() or not path.is_file():
        return "replacement citation %r does not name an existing file:line" % citation
    if int(line_text) > len(path.read_text(encoding="utf-8").splitlines()):
        return "replacement citation %r is past the end of %s" % (citation, path_text)
    return None


class ToolCoverageTest(unittest.TestCase):
    def test_self_is_wired(self):
        self.assertIn(SELF, check_invocations(), "%s must run from tools/check.sh" % SELF)

    def test_every_tool_is_wired_or_retired(self):
        invoked = check_invocations()
        problems = []
        members = population()
        self.assertTrue(members, "no tool population derived")
        for member in sorted(members - invoked):
            if member not in UNWIRED:
                problems.append("%s is not run by tools/check.sh and is not recorded in UNWIRED" % member)
                continue
            reason, citation = UNWIRED[member]
            if not reason:
                problems.append("%s has an empty UNWIRED reason" % member)
            problem = citation_problem(citation)
            if problem:
                problems.append("%s: %s" % (member, problem))
        for member in sorted(UNWIRED):
            if member not in members:
                problems.append("UNWIRED names %s, which is not a guard tool any more" % member)
            elif member in invoked:
                problems.append("UNWIRED names %s, but tools/check.sh now runs it" % member)
        self.assertEqual(problems, [])


if __name__ == "__main__":
    unittest.main()
