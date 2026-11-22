#!/usr/bin/env python3
"""The one place worker models are pinned. Usage:
  fleet_models.py                              show the pins
  fleet_models.py check [route]                probe pins, default all
  fleet_models.py set <route> <provider> <model>   probe, then write the pin
Change a pin only on the user's word."""
import argparse
import json
import os
import pathlib
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
PINS = pathlib.Path(__file__).resolve().parent / "fleet_models.json"
TRANSCRIPTS = pathlib.Path.home() / ".claude" / "projects" / str(ROOT).replace("/", "-").replace("_", "-")
# primary/fallback are DeepSeek Flash (OpenCode Go, official API); codex/codex-strong draw on the ChatGPT login.
ROUTES = ("primary", "fallback", "codex", "codex-strong")
# OpenCode's contributor models train on prompts, and its free models keep them.
REFUSED_MODEL_WORDS = ("contributor", "free")
# Claude Code writes this name on messages it makes itself, such as an API error.
LOCAL_MESSAGE_MODEL = "<synthetic>"


def validate(pin):
    """Optional keys: "peak" (default true: wait out DeepSeek peak), "pool" (slot pool, default the provider),
    "limit_wait_hours" (default 0: on RATE_LIMITED keep retrying the task this long, for windowed plans)."""
    provider, model = pin.get("provider"), pin.get("model")
    if not provider or not model:
        raise ValueError(f"pin needs a provider and a model: {pin}")
    refused = [word for word in REFUSED_MODEL_WORDS if word in model.lower()]
    if refused:
        raise ValueError(f"{model} refused: {refused[0]} models may not receive project source")
    return pin


def load():
    pins = json.loads(PINS.read_text(encoding="utf-8"))
    return {route: validate(pins[route]) for route in ROUTES}


def pool(pin):
    return pin.get("pool", pin["provider"])


def served_name(model):
    return model.removesuffix("[1m]")


def foreign_models(transcript, model, start_line=0):
    """Models that answered in a transcript other than the pinned one: a silent alias change."""
    lines = transcript.read_text(encoding="utf-8").splitlines() if transcript.exists() else []
    answered = {entry["message"].get("model") for entry in map(json.loads, lines[start_line:]) if entry.get("type") == "assistant"}
    return sorted(str(name) for name in answered - {served_name(model), LOCAL_MESSAGE_MODEL})


def probe(pin):
    command = ["cc-fleet", "subagent", pin["provider"], "--model", pin["model"], "--profile", "slim-ro",
               "--prompt", "Reply exactly READY. Do not use tools.", "--max-turns", "3", "--timeout", "60s", "--json"]
    completed = subprocess.run(command, capture_output=True, text=True, cwd=ROOT)
    try:
        envelope = json.loads(completed.stdout)
    except json.JSONDecodeError:
        return f"no envelope: {completed.stderr.strip()[-300:]}"
    if not envelope.get("ok"):
        return f"failed: {envelope.get('error_code')}"
    foreign = foreign_models(TRANSCRIPTS / (envelope["session_id"] + ".jsonl"), pin["model"])
    return f"answered by {foreign}" if foreign else None


def write_pin(route, pin):
    pins = json.loads(PINS.read_text(encoding="utf-8"))
    pins[route] = {**pins.get(route, {}), **pin}
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", dir=PINS.parent, delete=False) as temporary:
        temporary.write(json.dumps(pins, indent=2) + "\n")
    os.replace(temporary.name, PINS)


def self_check():
    assert served_name("deepseek-v4.1-flash[1m]") == "deepseek-v4.1-flash"
    assert pool({"provider": "OpenCode", "pool": "deepseek"}) == "deepseek" and pool({"provider": "codex"}) == "codex"
    for name in ("iceman-contributor-free", "beam-free", "muse-spark-1.3-contributor"):
        try:
            validate({"provider": "OpenCode", "model": name})
        except ValueError:
            continue
        raise AssertionError(name)
    with tempfile.TemporaryDirectory() as directory:
        transcript = pathlib.Path(directory) / "t.jsonl"
        rows = [{"type": "assistant", "message": {"model": "old"}}, {"type": "user", "message": {}},
                {"type": "assistant", "message": {"model": "pin"}}, {"type": "assistant", "message": {"model": LOCAL_MESSAGE_MODEL}}]
        transcript.write_text("".join(json.dumps(row) + "\n" for row in rows))
        assert foreign_models(transcript, "pin[1m]") == ["old"]
        assert foreign_models(transcript, "pin[1m]", 1) == []


def main():
    self_check()
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command")
    check = commands.add_parser("check")
    check.add_argument("route", nargs="?", choices=ROUTES)
    change = commands.add_parser("set")
    change.add_argument("route", choices=ROUTES)
    change.add_argument("provider")
    change.add_argument("model")
    arguments = parser.parse_args()
    if arguments.command == "set":
        pin = validate({"provider": arguments.provider, "model": arguments.model})
        problem = probe(pin)
        if problem:
            print(f"not pinned: {problem}")
            return 1
        write_pin(arguments.route, pin)
    pins = load()
    if arguments.command == "check":
        problems = {route: probe(pins[route]) for route in ([arguments.route] if arguments.route else ROUTES)}
        print(json.dumps(problems))
        return 1 if any(problems.values()) else 0
    print(json.dumps(pins, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
