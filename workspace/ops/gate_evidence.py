#!/usr/bin/env python3
"""Seal guard (audit A-012): does the gate evidence cover the backend HEAD?

  gate_evidence.py <backend> <STRICT_GATE.json | COMPOSITE_GATE.json>

A STRICT_GATE.json passes when its verdict is GREEN, its commit is HEAD, and it is a serial full gate. A
COMPOSITE_GATE.json (the user's composite evidence rule: last full gate plus impacted reruns) passes when its head is
HEAD, its full gate exists and is a serial full gate, and every rerun is GREEN or PARTIAL_GREEN at HEAD. A RED rerun
at HEAD still counts when every red line names a test in the evidence's `rerun_waivers` (user-approved, with a cause);
a waived test can never be one the evidence remediates. A full gate
(a direct report or a composite's `full_gate`) must have `mode` `serial` or absent, `selection` null and no
`packages`: a parallel or package-limited gate is foundation evidence, never the level 3 release gate
(ACCEPTANCE_V2_DESIGN.md). A PAIRED document {"head", "general_gate", "latency_gate"} passes when the general
report's general section and the separate `--section latency` report's latency section are GREEN at HEAD, from the
same gate tool and list hashes (GATE_LATENCY_SECTION_V1); a combined report still works.
Gate tiers (user 2026-11-21): a sub-phase or a phase whose serial certification already exists seals on a parallel
whole-tree gate. Its evidence (any form above) names `phase_serial_evidence`, the evidence file that sealed the phase's
serial run; that file must pass this check at its own head, must not itself lean on another certification, and its head
must be an ancestor of HEAD. `selection` and `packages` stay forbidden either way.
Exit 0 and print GATE_EVIDENCE OK, or exit 1 with the reason.
"""
import json
import pathlib
import subprocess
import sys

RERUN_VERDICTS = ("GREEN", "PARTIAL_GREEN")
REMEDIATION_BACKEND_MAX = 3  # D522: more minor backend fixes than this means a new serial run
REMEDIATION_CLASSES = ("tooling", "backend")


def condition_problems(path, latency):
    """A-097: a GREEN latency section must carry its host proof (GATE_LATENCY_SECTION_V1 amendment 4, 2026-11-18): the
    load and temperature readings before the run, the last one breach-free."""
    conditions = latency.get("conditions")
    if not isinstance(conditions, list) or not conditions or not all(isinstance(reading, dict) for reading in conditions):
        return [f"{path}: latency section has no host conditions record"]
    if any(not isinstance(reading.get("breaches"), list) for reading in conditions):
        return [f"{path}: a latency conditions reading has no breaches list"]
    if conditions[-1]["breaches"]:
        return [f"{path}: latency conditions lack a breach-free reading before the run"]
    return []


def section_problems(path, evidence):
    """GATE_LATENCY_SECTION_V1: both sections GREEN on the same commit; a latency section never passes as NOT_RUN."""
    sections = evidence.get("sections")
    if not isinstance(sections, dict):
        return [f"{path}: no sections; GATE_LATENCY_SECTION_V1 needs a general and a latency verdict"]
    found = []
    general = sections.get("general")
    if not isinstance(general, dict) or general.get("verdict") != "GREEN":
        found.append(f"{path}: general section {None if not isinstance(general, dict) else general.get('verdict')}, not GREEN")
    latency = sections.get("latency")
    if not isinstance(latency, dict):
        found.append(f"{path}: missing latency section")
    elif latency.get("verdict") != "GREEN":
        found.append(f"{path}: latency section {latency.get('verdict')}, not GREEN")
    else:
        found += condition_problems(path, latency)
    return found


def level3_problems(path, evidence, parallel_ok=False):
    """Level 3 of ACCEPTANCE_V2_DESIGN.md: only a whole-tree gate can back a seal, serial unless the phase is certified."""
    found = []
    if evidence.get("mode") not in ((None, "serial", "parallel") if parallel_ok else (None, "serial")):
        found.append(f"{path}: level 3 of ACCEPTANCE_V2_DESIGN.md needs a serial full gate, not mode {evidence.get('mode')}")
    if evidence.get("selection") is not None:
        found.append(f"{path}: level 3 of ACCEPTANCE_V2_DESIGN.md needs no selection, found {evidence.get('selection')}")
    if evidence.get("packages"):
        found.append(f"{path}: level 3 of ACCEPTANCE_V2_DESIGN.md needs the whole tree, not packages {evidence.get('packages')}")
    return found


def full_gate_problems(path, evidence, parallel_ok=False):
    return section_problems(path, evidence) + level3_problems(path, evidence, parallel_ok)


def separated_section_problems(path, evidence, section, parallel_ok=False):
    """One half of a paired evidence: its own section GREEN, run by a whole-tree gate."""
    sections = evidence.get("sections")
    if not isinstance(sections, dict) or not isinstance(sections.get(section), dict):
        return [f"{path}: no {section} section"]
    found = []
    verdict = sections[section].get("verdict")
    if verdict != "GREEN":
        found.append(f"{path}: {section} section {verdict}, not GREEN")
    elif section == "latency":
        found += condition_problems(path, sections[section])
    return found + level3_problems(path, evidence, parallel_ok)


def identity_problems(path, report, field):
    """A paired report must name its tooling and lists with sha256 values; a missing identity is never equal to another."""
    label = "gate tool hashes" if field == "tools" else "gate list hashes"
    identity = report.get(field)
    if not isinstance(identity, dict) or not identity:
        return [f"{path}: paired reports need non-empty {label} ({field})"]
    found = []
    for name, value in identity.items():
        if not isinstance(name, str) or not name:
            found.append(f"{path}: {label} ({field}) has an empty name")
        if not isinstance(value, str) or len(value) != 64 or any(character not in "0123456789abcdef" for character in value):
            found.append(f"{path}: {label} ({field}) {name} is not a 64-hex sha256")
    return found


def rerun_problems(rerun_path, rerun, evidence, head):
    if rerun.get("commit") != head:
        return [f"rerun {rerun_path}: {rerun.get('verdict')} at {rerun.get('commit')}"]
    if rerun.get("verdict") in RERUN_VERDICTS:
        return []
    waivers = evidence.get("rerun_waivers") or {}
    found = [f"rerun waiver of {key} needs a cause and approved_by" for key, record in sorted(waivers.items())
             if not isinstance(record, dict) or not record.get("cause") or not record.get("approved_by")]
    found += [f"rerun waiver of {key}: a remediated test must pass, never be waived"
              for key in sorted(set(waivers) & set(evidence.get("remediation") or {}))]
    unwaived = [line for line in rerun.get("red") or [] if line.partition(": ")[0] not in waivers]
    if unwaived or not rerun.get("red"):
        found.append(f"rerun {rerun_path}: {rerun.get('verdict')} at {rerun.get('commit')}; unwaived: {unwaived}")
    return found


def remediation_problems(path, report, evidence, head):
    """D522: a serial general section RED only on named tests counts as passed once each failure is classified, fixed
    and passes in a rerun at HEAD; a red line that names no failing test (a setup step, a population) never does."""
    remediation = evidence.get("remediation")
    if not isinstance(remediation, dict) or not remediation:
        return [f"{path}: remediation names no failing test"]
    failing = {key for key, test in (report.get("tests") or {}).items() if test.get("status") == "RED"}
    found = [f"{path}: red line names no failing test, so it cannot be remediated: {line}"
             for line in report.get("red") or [] if line.partition(": ")[0] not in failing]
    found += [f"{path}: failing test {key} is not in the remediation map" for key in sorted(failing - set(remediation))]
    for key, record in sorted(remediation.items()):
        if not isinstance(record, dict) or record.get("class") not in REMEDIATION_CLASSES or not record.get("fix"):
            found.append(f"{path}: remediation of {key} needs class tooling|backend and a fix commit")
    backend = [key for key, record in remediation.items() if isinstance(record, dict) and record.get("class") == "backend"]
    if len(backend) > REMEDIATION_BACKEND_MAX:
        found.append(f"{path}: {len(backend)} backend fixes exceed {REMEDIATION_BACKEND_MAX}: run the serial gate again")
    passed = set()
    for rerun_path in evidence.get("reruns") or []:
        rerun = json.loads(pathlib.Path(rerun_path).read_text(encoding="utf-8"))
        rerun_found = rerun_problems(rerun_path, rerun, evidence, head)
        if rerun_found:
            found += rerun_found
            continue
        passed |= {key for key, test in (rerun.get("tests") or {}).items() if test.get("status") == "PASS"}
    found += [f"{path}: remediated test {key} has no PASS in a rerun at HEAD" for key in sorted(failing - passed)]
    return found


def pair_problems(path, evidence, head, parallel_ok=False):
    """GATE_LATENCY_SECTION_V1 section 6: a general report and a separate --section latency report, same commit and tooling."""
    reports, found = {}, []
    for name in ("general_gate", "latency_gate"):
        report_path = evidence.get(name)
        if not report_path or not pathlib.Path(report_path).is_file():
            found.append(f"{path}: {name} {report_path} is missing")
            continue
        reports[name] = (pathlib.Path(report_path), json.loads(pathlib.Path(report_path).read_text(encoding="utf-8")))
    if found:
        return found
    general_path, general = reports["general_gate"]
    latency_path, latency = reports["latency_gate"]
    remediated = "remediation" in evidence
    general_found = separated_section_problems(general_path, general, "general", parallel_ok)
    if remediated and (general.get("sections") or {}).get("general", {}).get("verdict") == "RED":
        # D522: the serial run on the frozen head stays the full gate; its named failures are fixed and rerun at HEAD.
        general_found = level3_problems(general_path, general, parallel_ok) + remediation_problems(general_path, general, evidence, head)
    found += general_found
    found += separated_section_problems(latency_path, latency, "latency", parallel_ok)
    if evidence.get("head") != head:
        found.append(f"{path}: paired head {evidence.get('head')} is not HEAD {head}")
    general_commit = evidence.get("gate_head") if remediated else head
    if general.get("commit") != general_commit:
        found.append(f"{general_path}: gate commit {general.get('commit')} is not {general_commit}")
    if latency.get("commit") != head:
        found.append(f"{latency_path}: gate commit {latency.get('commit')} is not HEAD {head}")
    identities = []
    for report_path, report in (reports["general_gate"], reports["latency_gate"]):
        identities += identity_problems(report_path, report, "tools")
        identities += identity_problems(report_path, report, "lists")
    found += identities
    if not identities:
        tooling_fixed = remediated and any(isinstance(record, dict) and record.get("class") == "tooling"
                                           for record in (evidence.get("remediation") or {}).values())
        if general["tools"] != latency["tools"] and not tooling_fixed:
            found.append(f"{path}: gate tool hashes differ between the general and latency reports")
        # latency.json holds the tunable host limits (D524); its members are proven by the latency section's own record.
        if {**general["lists"], "latency": None} != {**latency["lists"], "latency": None}:
            found.append(f"{path}: gate list hashes differ between the general and latency reports")
    return found


def evidence_head(evidence):
    return evidence.get("head") if ("general_gate" in evidence or "full_gate" in evidence) else evidence.get("commit")


def certification_problems(path, evidence, head, is_ancestor):
    """The phase's sealed serial evidence: valid at its own head, serial itself, and an ancestor of HEAD."""
    certification_path = pathlib.Path(evidence["phase_serial_evidence"])
    if not certification_path.is_file():
        return [f"{path}: phase_serial_evidence {certification_path} is missing"]
    certification = json.loads(certification_path.read_text(encoding="utf-8"))
    if "phase_serial_evidence" in certification:
        return [f"{certification_path}: a phase serial certification cannot itself lean on another certification"]
    certified_head = evidence_head(certification)
    found = [f"phase serial certification: {line}" for line in problems(certified_head, certification_path, is_ancestor)]
    if certified_head and not is_ancestor(certified_head, head):
        found.append(f"{path}: certified head {certified_head} is not an ancestor of HEAD {head}")
    return found


def problems(head, evidence_path, is_ancestor=None):
    evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
    parallel_ok = "phase_serial_evidence" in evidence
    certified = certification_problems(evidence_path, evidence, head, is_ancestor) if parallel_ok else []
    return certified + gate_problems(head, evidence_path, evidence, parallel_ok)


def gate_problems(head, evidence_path, evidence, parallel_ok):
    if "general_gate" in evidence or "latency_gate" in evidence:
        return pair_problems(evidence_path, evidence, head, parallel_ok)
    if "full_gate" not in evidence:
        found = full_gate_problems(evidence_path, evidence, parallel_ok)
        if evidence.get("verdict") != "GREEN":
            found.append(f"{evidence_path}: verdict {evidence.get('verdict')}, not GREEN")
        if evidence.get("commit") != head:
            found.append(f"{evidence_path}: gate commit {evidence.get('commit')} is not HEAD {head}")
        return found
    found = [] if evidence.get("head") == head else [f"{evidence_path}: composite head {evidence.get('head')} is not HEAD {head}"]
    full_gate = pathlib.Path(evidence["full_gate"])
    if not full_gate.is_file():
        found.append(f"full gate {evidence['full_gate']} is missing")
    else:
        found += full_gate_problems(full_gate, json.loads(full_gate.read_text(encoding="utf-8")), parallel_ok)
    if not evidence.get("reruns"):
        found.append("a composite needs at least one rerun at HEAD")
    for rerun_path in evidence.get("reruns") or []:
        rerun = json.loads(pathlib.Path(rerun_path).read_text(encoding="utf-8"))
        found += rerun_problems(rerun_path, rerun, evidence, head)
    return found


def self_check():
    import tempfile
    with tempfile.TemporaryDirectory() as directory:
        root = pathlib.Path(directory)
        def write(name, data):
            (root / name).write_text(json.dumps(data))
            return root / name
        proof = [{"breaches": ["load average 3.00 >= 1.5"]}, {"breaches": []}]
        green_sections = {"general": {"verdict": "GREEN"}, "latency": {"verdict": "GREEN", "conditions": proof}}
        assert problems("h", write("g.json", {"verdict": "GREEN", "commit": "h", "sections": green_sections})) == []
        assert problems("h", write("r.json", {"verdict": "RED", "commit": "h", "sections": green_sections}))
        assert problems("h", write("o.json", {"verdict": "GREEN", "commit": "old", "sections": green_sections}))
        assert problems("h", write("s.json", {"verdict": "GREEN", "commit": "h", "mode": "serial", "selection": None,
                                             "packages": [], "sections": green_sections})) == []
        assert "level 3" in problems("h", write("p.json", {"verdict": "GREEN", "commit": "h", "mode": "parallel",
                                                           "sections": green_sections}))[0]
        assert "level 3" in problems("h", write("x.json", {"verdict": "GREEN", "commit": "h", "selection": ["a"],
                                                           "sections": green_sections}))[0]
        assert "level 3" in problems("h", write("k.json", {"verdict": "GREEN", "commit": "h", "packages": ["./internal/a"],
                                                           "sections": green_sections}))[0]
        assert "missing latency section" in problems("h", write("m.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "sections": {"general": {"verdict": "GREEN"}}}))[0]
        assert "latency section" in problems("h", write("n.json", {
            "verdict": "NOT_RUN", "commit": "h",
            "sections": {"general": {"verdict": "GREEN"}, "latency": {"verdict": "NOT_RUN", "conditions": []}}}))[0]
        assert "no sections" in problems("h", write("z.json", {"verdict": "GREEN", "commit": "h"}))[0]
        for conditions, reason in (([], "no host conditions"), ([{}], "no breaches list"),
                                   ([{"breaches": []}, {"breaches": ["load average 3.00 >= 1.5"]}], "breach-free")):
            unproved = {"general": {"verdict": "GREEN"}, "latency": {"verdict": "GREEN", "conditions": conditions}}
            found = problems("h", write("c.json", {"verdict": "GREEN", "commit": "h", "sections": unproved}))
            assert any(reason in problem for problem in found), (conditions, found)
        tool_hash, other_tool_hash, list_hash = "a" * 64, "b" * 64, "c" * 64
        pair_general = write("pair_general.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial", "selection": None, "packages": [],
            "sections": {"general": {"verdict": "GREEN"}},
            "lists": {"latency": list_hash}, "tools": {"strict_gate.py": tool_hash}})
        pair_latency = write("pair_latency.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial", "selection": None, "packages": [],
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}},
            "lists": {"latency": list_hash}, "tools": {"strict_gate.py": tool_hash}})
        assert problems("h", write("pair.json", {"head": "h", "general_gate": str(pair_general),
                                                 "latency_gate": str(pair_latency)})) == []
        for lists, differs in (({"latency": "d" * 64}, False), ({"latency": list_hash, "known_debt": "d" * 64}, True)):
            other = write("pair_lists.json", {**json.loads(pair_latency.read_text()), "lists": lists})
            found = problems("h", write("pair_l.json", {"head": "h", "general_gate": str(pair_general),
                                                        "latency_gate": str(other)}))
            assert any("list hashes differ" in problem for problem in found) == differs, (lists, found)
        def red_general(red, tests):
            return write(f"red_general_{len(red)}_{len(tests)}.json", {
                "verdict": "RED", "commit": "f", "mode": "serial", "selection": None, "packages": [],
                "sections": {"general": {"verdict": "RED"}}, "red": red, "tests": tests,
                "lists": {"latency": list_hash}, "tools": {"strict_gate.py": tool_hash}})
        failing = {f"pkg.Test{index}": {"status": "RED"} for index in range(4)}
        red_lines = [f"{key}: NEW_FAILURE in suite:postgres" for key in failing]
        passed_rerun = write("passed_rerun.json", {"verdict": "PARTIAL_GREEN", "commit": "h",
                                                   "tests": {key: {"status": "PASS"} for key in failing}})
        def remediated(general, remediation, reruns=(str(passed_rerun),)):
            return problems("h", write("remediated.json", {
                "head": "h", "gate_head": "f", "general_gate": str(general), "latency_gate": str(pair_latency),
                "remediation": remediation, "reruns": list(reruns)}))
        three = dict(list(failing.items())[:3])
        fixes = {key: {"class": "backend", "fix": "c"} for key in three}
        general = red_general(red_lines[:3], three)
        assert remediated(general, fixes) == [], remediated(general, fixes)
        assert "no PASS in a rerun" in " ".join(remediated(general, fixes, reruns=()))
        flaky_rerun = write("flaky_rerun.json", {"verdict": "RED", "commit": "h", "red": ["pkg.Flaky: NEW_FAILURE in suite:river"],
                                                 "tests": {**{key: {"status": "PASS"} for key in three}, "pkg.Flaky": {"status": "RED"}}})
        def waived(waivers, rerun=flaky_rerun):
            return problems("h", write("waived.json", {
                "head": "h", "gate_head": "f", "general_gate": str(general), "latency_gate": str(pair_latency),
                "remediation": fixes, "reruns": [str(rerun)], "rerun_waivers": waivers}))
        approved = {"cause": "host load", "approved_by": "user"}
        assert "unwaived" in " ".join(waived({}))
        assert waived({"pkg.Flaky": approved}) == [], waived({"pkg.Flaky": approved})
        assert "needs a cause" in " ".join(waived({"pkg.Flaky": {"cause": "host load"}}))
        assert "never be waived" in " ".join(waived({"pkg.Flaky": approved, "pkg.Test0": approved}))
        setup_rerun = write("setup_rerun.json", {"verdict": "RED", "commit": "h", "red": ["step cluster:start exited 1"], "tests": {}})
        assert "unwaived" in " ".join(waived({"pkg.Flaky": approved}, rerun=setup_rerun))
        assert "exceed 3" in " ".join(remediated(red_general(red_lines, failing),
                                                 {key: {"class": "backend", "fix": "c"} for key in failing}))
        tooling = {key: {"class": "tooling", "fix": "c"} for key in failing}
        assert remediated(red_general(red_lines, failing), tooling) == []
        setup = red_general(red_lines[:1] + ["step cluster:start exited 1"], dict(list(failing.items())[:1]))
        assert "names no failing test" in " ".join(remediated(setup, dict(list(tooling.items())[:1])))
        assert "not in the remediation map" in " ".join(remediated(general, dict(list(fixes.items())[:2])))
        assert problems("h", write("unremediated.json", {"head": "h", "general_gate": str(general),
                                                         "latency_gate": str(pair_latency)}))
        old_latency = write("pair_old_latency.json", {
            "verdict": "PARTIAL_GREEN", "commit": "old", "mode": "serial",
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}},
            "lists": {"latency": list_hash}, "tools": {"strict_gate.py": tool_hash}})
        assert problems("h", write("pair_commit.json", {"head": "h", "general_gate": str(pair_general),
                                                        "latency_gate": str(old_latency)}))
        other_tools = write("pair_other_tools.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}},
            "lists": {"latency": list_hash}, "tools": {"strict_gate.py": other_tool_hash}})
        assert "tool hashes" in problems("h", write("pair_tools.json", {"head": "h", "general_gate": str(pair_general),
                                                                         "latency_gate": str(other_tools)}))[0]
        no_tools = write("pair_no_tools.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}}, "lists": {"latency": list_hash}})
        assert "tool hashes" in problems("h", write("pair_missing_tools.json", {
            "head": "h", "general_gate": str(pair_general), "latency_gate": str(no_tools)}))[0]
        missing_lists_general = write("pair_missing_lists_general.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"general": {"verdict": "GREEN"}}, "tools": {"strict_gate.py": tool_hash}})
        missing_lists_latency = write("pair_missing_lists_latency.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}}, "tools": {"strict_gate.py": tool_hash}})
        assert "gate list hashes" in problems("h", write("pair_no_lists.json", {
            "head": "h", "general_gate": str(missing_lists_general),
            "latency_gate": str(missing_lists_latency)}))[0]
        empty_tools_general = write("pair_empty_tools_general.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"general": {"verdict": "GREEN"}}, "lists": {"latency": list_hash}, "tools": {}})
        empty_tools_latency = write("pair_empty_tools_latency.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}}, "lists": {"latency": list_hash}, "tools": {}})
        assert "gate tool hashes" in problems("h", write("pair_empty_tools_pair.json", {
            "head": "h", "general_gate": str(empty_tools_general), "latency_gate": str(empty_tools_latency)}))[0]
        empty_lists_general = write("pair_empty_lists_general.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"general": {"verdict": "GREEN"}}, "lists": {}, "tools": {"strict_gate.py": tool_hash}})
        empty_lists_latency = write("pair_empty_lists_latency.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}}, "lists": {}, "tools": {"strict_gate.py": tool_hash}})
        assert "gate list hashes" in problems("h", write("pair_empty_lists_pair.json", {
            "head": "h", "general_gate": str(empty_lists_general), "latency_gate": str(empty_lists_latency)}))[0]
        short_hash = write("pair_short_hash.json", {
            "verdict": "PARTIAL_GREEN", "commit": "h", "mode": "serial",
            "sections": {"latency": {"verdict": "GREEN", "conditions": proof}},
            "lists": {"latency": list_hash}, "tools": {"strict_gate.py": "a" * 63}})
        assert "64-hex" in problems("h", write("pair_short_hash_pair.json", {
            "head": "h", "general_gate": str(pair_general), "latency_gate": str(short_hash)}))[0]
        rerun = write("r.json", {"verdict": "PARTIAL_GREEN", "commit": "h"})
        full = write("f.json", {"verdict": "GREEN", "commit": "old", "sections": green_sections})
        assert problems("h", write("c.json", {"head": "h", "full_gate": str(full), "reruns": [str(rerun)]})) == []
        parallel_full = write("pf.json", {"verdict": "GREEN", "commit": "old", "mode": "parallel", "sections": green_sections})
        assert "level 3" in problems("h", write("c4.json", {"head": "h", "full_gate": str(parallel_full), "reruns": [str(rerun)]}))[0]
        assert problems("h", write("c2.json", {"head": "h", "full_gate": str(full), "reruns": []}))
        assert problems("h", write("c3.json", {"head": "x", "full_gate": str(full), "reruns": [str(rerun)]}))

        # Gate tiers: a parallel whole-tree gate seals a certified sub-phase; the certification must hold on its own.
        ancestors = {("s", "h")}
        def ancestor(old, new):
            return (old, new) in ancestors
        serial = write("cert.json", {"verdict": "GREEN", "commit": "s", "mode": "serial", "selection": None, "packages": [],
                                     "sections": green_sections})
        parallel = {"verdict": "GREEN", "commit": "h", "mode": "parallel", "selection": None, "packages": [],
                    "sections": green_sections}
        assert "level 3" in problems("h", write("t0.json", parallel), ancestor)[0]
        assert problems("h", write("t1.json", {**parallel, "phase_serial_evidence": str(serial)}), ancestor) == []
        assert any("ancestor" in line for line in problems("x", write("t2.json", {**parallel, "commit": "x",
                                                                                      "phase_serial_evidence": str(serial)}), ancestor))
        parallel_cert = write("pc.json", {**parallel, "commit": "s"})
        assert any("level 3" in line for line in problems("h", write("t3.json", {**parallel, "phase_serial_evidence": str(parallel_cert)}), ancestor))
        chained = write("cc.json", {**parallel, "commit": "s", "phase_serial_evidence": str(serial)})
        assert any("cannot itself lean" in line for line in problems("h", write("t4.json", {**parallel, "phase_serial_evidence": str(chained)}), ancestor))
        assert any("selection" in line for line in problems("h", write("t5.json", {**parallel, "selection": "^suite:x$",
                                                                                   "phase_serial_evidence": str(serial)}), ancestor))
        assert any("missing" in line for line in problems("h", write("t6.json", {**parallel, "phase_serial_evidence": str(root / "none.json")}), ancestor))


def main():
    if sys.argv[1:] == ["--check"]:
        self_check()
        print("gate_evidence self-check ok")
        return 0
    backend, evidence_path = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    head = subprocess.run(["git", "-C", str(backend), "rev-parse", "HEAD"], capture_output=True, text=True, check=True).stdout.strip()
    def is_ancestor(ancestor, descendant):
        return subprocess.run(["git", "-C", str(backend), "merge-base", "--is-ancestor", ancestor, descendant]).returncode == 0
    found = problems(head, evidence_path, is_ancestor)
    print("\n".join(found) or f"GATE_EVIDENCE OK {head}")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
