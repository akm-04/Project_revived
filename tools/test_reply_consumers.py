"""Regression checks for the stock-client reply-consumer extractor."""
import json
import os
from pathlib import Path
import re
import unittest
import zipfile

import reply_consumers

ARCHIVE_ENV = "GXB_REPLY_CONSUMERS_SOURCE_ARCHIVE"
DEFAULT_ARCHIVE = Path(__file__).resolve().parents[1] / "inputs/assets/Older/all-assest-rechecked-1.zip"
ACCESS_NAME = re.compile(r"\.\s*([A-Za-z_][A-Za-z0-9_]*)|\[\s*[\"']([A-Za-z_][A-Za-z0-9_]*)[\"']\s*\]")


def archive_path():
    return Path(os.environ.get(ARCHIVE_ENV) or DEFAULT_ARCHIVE)


def required_paths(payload, mid):
    return {
        reply_consumers.path_name(entry)
        for entry in payload["mids"][str(mid)]["paths"]
        if reply_consumers.path_requirement(entry) == "REQUIRED"
    }


def obligation_map(payload):
    return {
        mid: {
            "paths": {reply_consumers.path_name(entry): reply_consumers.path_requirement(entry) for entry in record["paths"]},
            "branches": {
                key: {
                    value: {
                        reply_consumers.path_name(entry): reply_consumers.path_requirement(entry)
                        for entry in branch["paths"]
                    }
                    for value, branch in values.items()
                }
                for key, values in record.get("branches", {}).items()
            },
        }
        for mid, record in payload["mids"].items()
    }


def branch_requirements(payload, mid, discriminator, value):
    branch = payload["mids"][str(mid)]["branches"][discriminator][value]
    return {reply_consumers.path_name(entry): reply_consumers.path_requirement(entry) for entry in branch["paths"]}


def repeated_segment_names(path):
    names = [part for part in path.replace("[]", "").split(".") if part]
    seen: set[str] = set()
    repeated: list[str] = []
    for name in names:
        if name in seen and name not in repeated:
            repeated.append(name)
        seen.add(name)
    return repeated


def path_prefixes(path):
    segments = path.split(".")
    return {".".join(segments[:end]) for end in range(1, len(segments) + 1)}


def normalised_access_names(line):
    return {
        (first or second).replace("_", "").lower()
        for first, second in ACCESS_NAME.findall(line)
    }


def fixture_payload():
    blobs = {
        "app/common/network/mid.lua": "xyd.mid.LOOP_FIXTURE = 9001\n",
        "app/common/enums.lua": "",
        "data/tables/model_define.lua": "",
        "app/common/network/Backend.lua": "",
        "app/model/LoopFixture.lua": (
            'local var_0_0 = class("LoopFixture")\n'
            "\n"
            "function var_0_0.load(arg_1_0)\n"
            "\txyd.Backend.get():request(xyd.mid.LOOP_FIXTURE, {}, function(arg_2_0, arg_2_1)\n"
            "\t\targ_1_0.info = arg_2_1\n"
            "\t\targ_1_0.send_gift_count = arg_2_1.send_gift_count\n"
            "\t\targ_1_0:updateDetail(arg_2_1.detail)\n"
            "\tend)\n"
            "end\n"
            "\n"
            "function var_0_0.updateDetail(arg_3_0, arg_3_1)\n"
            "\targ_3_0.team = arg_3_1\n"
            "end\n"
            "\n"
            "function var_0_0.bump(arg_4_0)\n"
            "\targ_4_0.info.send_gift_count[1] = arg_4_0.info.send_gift_count[1] + 1\n"
            "\targ_4_0.team.challenge_times[1] = arg_4_0.team.challenge_times[1] + 1\n"
            "end\n"
        ),
    }
    return reply_consumers.build(blobs, collapse=False)


def event_consumer_blobs(*, callback=True):
    callback_argument = (
        ", function(arg_3_0, arg_3_1)\n"
        "\t\tprint(arg_3_1.callback_only)\n"
        "\tend"
    ) if callback else ""
    return {
        "app/common/network/mid.lua": "xyd.mid.EVENTED = 9001\n",
        "app/common/enums.lua": "",
        "data/tables/model_define.lua": "",
        "app/common/network/Backend.lua": (
            "function var_0_1.setupMidToEventNameMappings_(arg_19_0)\n"
            "\targ_19_0.mid2EventNames_[xyd.mid.EVENTED] = xyd.event.EVENTED\n"
            "end\n"
        ),
        "app/model/Evented.lua": (
            'local var_0_0 = class("Evented")\n'
            "function var_0_0.onRegister(arg_1_0)\n"
            "\targ_1_0:registerEvent(xyd.event.EVENTED, handler(arg_1_0, arg_1_0.onEvented_))\n"
            "end\n"
            "function var_0_0.onEvented_(arg_2_0, arg_2_1)\n"
            "\targ_2_0.value = arg_2_1.params.event_only\n"
            "\targ_2_0.userdata = arg_2_1.userdata\n"
            "end\n"
        ),
        "app/model/Caller.lua": (
            'local var_0_0 = class("Caller")\n'
            "function var_0_0.load(arg_4_0)\n"
            f"\txyd.Backend.get():request(xyd.mid.EVENTED, {{}}{callback_argument})\n"
            "end\n"
        ),
    }


class EventConsumerTests(unittest.TestCase):
    def test_the_mapped_event_is_a_consumer_even_with_an_explicit_callback(self):
        with_callback = reply_consumers.build(event_consumer_blobs(), collapse=False)
        self.assertEqual({"event_only", "callback_only"}, required_paths(with_callback, 9001))
        without_callback = reply_consumers.build(event_consumer_blobs(callback=False), collapse=False)
        self.assertEqual({"event_only"}, required_paths(without_callback, 9001))

    def test_the_event_userdata_is_not_a_reply_path(self):
        payload = reply_consumers.build(event_consumer_blobs(), collapse=False)
        self.assertNotIn("userdata", required_paths(payload, 9001))


def wrapper_owner_blobs(*, extra_window_call="", import_beta=True):
    beta_import = 'local beta = import("app.model.Beta")\n' if import_beta else ""
    return {
        "app/common/network/mid.lua": "xyd.mid.ALPHA = 9001\nxyd.mid.BETA = 9002\n",
        "app/common/enums.lua": "",
        "data/tables/model_define.lua": "",
        "app/common/network/Backend.lua": "",
        "app/model/Alpha.lua": (
            'local var_0_0 = class("Alpha")\n'
            "function var_0_0.loadInfo(arg_1_0, arg_1_1)\n"
            "\txyd.Backend.get():request(xyd.mid.ALPHA, {}, function(arg_2_0, arg_2_1)\n"
            "\t\targ_1_1(arg_2_0, arg_2_1)\n"
            "\tend)\n"
            "end\n"
        ),
        "app/model/Beta.lua": (
            'local var_0_0 = class("Beta")\n'
            "function var_0_0.loadInfo(arg_1_0, arg_1_1)\n"
            "\txyd.Backend.get():request(xyd.mid.BETA, {}, function(arg_2_0, arg_2_1)\n"
            "\t\targ_1_1(arg_2_0, arg_2_1)\n"
            "\tend)\n"
            "end\n"
        ),
        "app/windows/Probe.lua": (
            'local var_0_0 = class("Probe")\n'
            'local alpha = import("app.model.Alpha")\n'
            f"{beta_import}"
            "function var_0_0.show(arg_1_0)\n"
            "\talpha:loadInfo(function(arg_2_0, arg_2_1)\n"
            "\t\tprint(arg_2_1.alpha_only)\n"
            "\tend)\n"
            f"{extra_window_call}"
            "end\n"
        ),
    }


class WrapperOwnerIdentityTests(unittest.TestCase):
    def test_two_models_with_one_wrapper_method_name_keep_their_own_replies(self):
        blobs = wrapper_owner_blobs(
            extra_window_call=(
                "\tbeta:loadInfo(function(arg_3_0, arg_3_1)\n"
                "\t\tprint(arg_3_1.beta_only)\n"
                "\tend)\n"
            )
        )
        payload = reply_consumers.build(blobs, collapse=False)
        self.assertEqual({"alpha_only"}, required_paths(payload, 9001))
        self.assertEqual({"beta_only"}, required_paths(payload, 9002))

    def test_same_owner_forwarding_still_contributes_its_reply(self):
        payload = reply_consumers.build(wrapper_owner_blobs(import_beta=False), collapse=False)
        self.assertEqual({"alpha_only"}, required_paths(payload, 9001))

    def test_inline_load_model_receiver_resolves_to_the_wrapper_owner(self):
        blobs = wrapper_owner_blobs(import_beta=False)
        blobs["app/common/enums.lua"] = "xyd.ModelType.ALPHA = 7\n"
        blobs["data/tables/model_define.lua"] = '"7", "Alpha"\n'
        blobs["app/windows/Probe.lua"] = (
            'local var_0_0 = class("Probe")\n'
            "function var_0_0.show(arg_1_0)\n"
            "\txyd.ModelManager.get():loadModel(xyd.ModelType.ALPHA):loadInfo(function(arg_2_0, arg_2_1)\n"
            "\t\tprint(arg_2_1.alpha_only)\n"
            "\tend)\n"
            "end\n"
        )
        payload = reply_consumers.build(blobs, collapse=False)
        self.assertEqual({"alpha_only"}, required_paths(payload, 9001))

    def test_unresolved_receiver_is_unknown_and_contributes_no_paths(self):
        blobs = wrapper_owner_blobs(
            import_beta=False,
            extra_window_call=(
                "\tlocal outsider = getModel()\n"
                "\toutsider:loadInfo(function(arg_3_0, arg_3_1)\n"
                "\t\tprint(arg_3_1.rogue_only)\n"
                "\tend)\n"
            ),
        )
        payload = reply_consumers.build(blobs, collapse=False)
        self.assertNotIn("rogue_only", required_paths(payload, 9001))
        unknown = [callback for callback in payload["mids"]["9001"]["callbacks"] if callback["status"] == "UNKNOWN"]
        self.assertTrue(any("unresolved" in callback.get("reason", "") for callback in unknown))


def guarded_item_blobs():
    return {
        "app/common/network/mid.lua": "xyd.mid.NOTICES = 9001\n",
        "app/common/enums.lua": "",
        "data/tables/model_define.lua": "",
        "app/common/network/Backend.lua": "",
        "app/model/Notices.lua": (
            'local var_0_0 = class("Notices")\n'
            "function var_0_0.load(arg_1_0)\n"
            "\txyd.Backend.get():request(xyd.mid.NOTICES, {}, function(arg_2_0, arg_2_1)\n"
            "\t\tfor iter_2_0, iter_2_1 in ipairs(arg_2_1.list) do\n"
            "\t\t\tprint(iter_2_1.player_info)\n"
            "\t\t\tif iter_2_1.kind == xyd.NoticeType.GIFT then\n"
            "\t\t\t\tprint(iter_2_1.fund_id)\n"
            "\t\t\telseif iter_2_1.kind == 2 or iter_2_1.kind == 3 then\n"
            "\t\t\t\tprint(iter_2_1.chapter_id)\n"
            "\t\t\telse\n"
            "\t\t\t\tprint(iter_2_1.table_id)\n"
            "\t\t\tend\n"
            "\t\t\tif iter_2_1.room_id then\n"
            "\t\t\t\tprint(iter_2_1.room_id)\n"
            "\t\t\tend\n"
            "\t\tend\n"
            "\t\targ_1_0.info = arg_2_1\n"
            "\t\targ_1_0.teams[arg_2_1.team.team_id] = arg_2_1.team\n"
            "\t\targ_1_0.single = arg_2_1.one\n"
            "\t\tlocal function var_2_9(arg_9_0)\n"
            "\t\t\treturn arg_9_0.helper_only\n"
            "\t\tend\n"
            "\t\tif arg_2_1.stage == 0 then\n"
            "\t\t\tprint(arg_2_1.stage_only)\n"
            "\t\tend\n"
            "\t\tif arg_1_0.flag then\n"
            "\t\t\tprint(arg_2_1.flag)\n"
            "\t\tend\n"
            "\t\tif arg_1_0.mode == 1 then\n"
            "\t\t\tprint(arg_2_1.mode_only)\n"
            "\t\tend\n"
            "\tend)\n"
            "end\n"
            "function var_0_0.keep(arg_5_0, arg_5_1)\n"
            "\tif arg_5_1.saved then\n"
            "\t\targ_5_0.info.saved = arg_5_1.saved\n"
            "\tend\n"
            "end\n"
            "function var_0_0.cell(arg_4_0, arg_4_1)\n"
            "\tlocal var_4_0 = arg_4_0.teams[arg_4_1]\n"
            "\tif var_4_0.need_time == 0 then\n"
            "\t\tprint(var_4_0.idle_only)\n"
            "\telse\n"
            "\t\tprint(var_4_0.award)\n"
            "\tend\n"
            "\tif arg_4_0.single.need_time == 0 then\n"
            "\t\tprint(arg_4_0.single.award)\n"
            "\tend\n"
            "end\n"
            "function var_0_0.show(arg_3_0)\n"
            "\tif arg_3_0.info.dialog then\n"
            "\t\tprint(arg_3_0.info.dialog)\n"
            "\tend\n"
            "end\n"
        ),
    }


def condition_read_blobs():
    return {
        "app/common/network/mid.lua": "xyd.mid.CONDITIONS = 9001\n",
        "app/common/enums.lua": "",
        "data/tables/model_define.lua": "",
        "app/common/network/Backend.lua": "",
        "app/model/Conditions.lua": (
            'local var_0_0 = class("Conditions")\n'
            "function var_0_0.load(arg_1_0)\n"
            "\txyd.Backend.get():request(xyd.mid.CONDITIONS, {}, function(arg_2_0, arg_2_1)\n"
            "\t\tif arg_2_1.compared == 1 then\n"
            "\t\t\tprint(arg_2_0.compared)\n"
            "\t\tend\n"
            "\t\tif arg_2_1.left and arg_2_1.right then\n"
            "\t\t\tprint(arg_2_0.left)\n"
            "\t\tend\n"
            "\t\tif not arg_2_1.negated then\n"
            "\t\t\tprint(arg_2_0.negated)\n"
            "\t\tend\n"
            "\t\tif (arg_2_1.nested or arg_2_1.alternate) then\n"
            "\t\t\tprint(arg_2_0.nested)\n"
            "\t\tend\n"
            "\tend)\n"
            "end\n"
        ),
    }


class ConditionReadTests(unittest.TestCase):
    def test_a_field_read_only_in_a_condition_is_a_consumer(self):
        paths = {
            reply_consumers.path_name(entry)
            for entry in reply_consumers.build(condition_read_blobs(), collapse=False)["mids"]["9001"]["paths"]
        }
        for field in ("compared", "left", "right", "negated", "nested", "alternate"):
            self.assertIn(field, paths, field)


class GuardResolutionTests(unittest.TestCase):
    def setUp(self):
        self.requirements = obligation_map(reply_consumers.build(guarded_item_blobs(), collapse=False))["9001"]["paths"]

    def test_a_nil_guard_on_an_item_guards_the_item_path(self):
        self.assertEqual("OPTIONAL", self.requirements["list[].room_id"])

    def test_reads_under_a_reply_value_branch_are_optional(self):
        for path in ("list[].fund_id", "list[].chapter_id", "list[].table_id"):
            self.assertEqual("OPTIONAL", self.requirements[path], path)
        self.assertEqual("REQUIRED", self.requirements["list[].player_info"])

    def test_a_nil_guard_on_a_stored_reply_guards_the_read(self):
        self.assertEqual("OPTIONAL", self.requirements["dialog"])

    def test_writing_a_stored_field_is_not_a_read(self):
        self.assertNotEqual("REQUIRED", self.requirements.get("saved"))

    def test_a_named_local_helper_parameter_is_not_the_reply(self):
        self.assertNotIn("helper_only", self.requirements)

    def test_a_top_level_value_branch_keeps_its_reads_required(self):
        self.assertEqual("REQUIRED", self.requirements["stage_only"])

    def test_a_value_branch_on_a_keyed_stored_record_is_optional(self):
        # TreasureWindow stores each team_info reply as teams[team_id] and reads award only when need_time ~= 0.
        for path in ("team.idle_only", "team.award"):
            self.assertEqual("OPTIONAL", self.requirements[path], path)
        self.assertEqual("REQUIRED", self.requirements["one.award"])

    def test_a_guard_on_a_non_reply_value_guards_nothing(self):
        self.assertEqual("REQUIRED", self.requirements["flag"])
        self.assertEqual("REQUIRED", self.requirements["mode_only"])


def window_state_blobs():
    # SocialSystemWindow: self.data holds a different reply list per windowState, and the cell builder dispatches on it.
    return {
        "app/common/network/mid.lua": "xyd.mid.SOCIAL = 9001\n",
        "app/common/enums.lua": "",
        "data/tables/model_define.lua": "",
        "app/common/network/Backend.lua": "",
        "app/model/Social.lua": (
            'local var_0_0 = class("Social")\n'
            "local var_0_4 = {FriendList = 1, NoticeMsg = 2}\n"
            "function var_0_0.load(arg_1_0)\n"
            "\txyd.Backend.get():request(xyd.mid.SOCIAL, {}, function(arg_2_0, arg_2_1)\n"
            "\t\targ_1_0.friendlist = arg_2_1.friend_list\n"
            "\t\targ_1_0.noticelist = arg_2_1.notice_list\n"
            "\tend)\n"
            "end\n"
            "function var_0_0.initData(arg_3_0)\n"
            "\tif arg_3_0.windowState == var_0_4.FriendList then\n"
            "\t\targ_3_0.data = arg_3_0.friendlist\n"
            "\telseif arg_3_0.windowState == var_0_4.NoticeMsg then\n"
            "\t\targ_3_0.data = arg_3_0.noticelist\n"
            "\tend\n"
            "end\n"
            "function var_0_0.cell(arg_4_0, arg_4_1)\n"
            "\tif arg_4_0.windowState == var_0_4.FriendList then\n"
            "\t\targ_4_0:friendItem(arg_4_0.data[arg_4_1])\n"
            "\telseif arg_4_0.windowState == var_0_4.NoticeMsg then\n"
            "\t\targ_4_0:noticeItem(arg_4_0.data[arg_4_1])\n"
            "\tend\n"
            "end\n"
            "function var_0_0.friendItem(arg_5_0, arg_5_1)\n"
            "\tprint(arg_5_1.name)\n"
            "end\n"
            "function var_0_0.noticeItem(arg_6_0, arg_6_1)\n"
            "\tprint(arg_6_1.player_info)\n"
            "end\n"
        ),
    }


class StateBranchTests(unittest.TestCase):
    def test_a_stored_value_reaches_only_the_branch_of_its_own_state(self):
        requirements = obligation_map(reply_consumers.build(window_state_blobs(), collapse=False))["9001"]["paths"]
        self.assertEqual("REQUIRED", requirements["notice_list[].player_info"])
        self.assertEqual("REQUIRED", requirements["friend_list[].name"])
        self.assertNotIn("friend_list[].player_info", requirements)
        self.assertNotIn("notice_list[].name", requirements)


class StorageBindingCycleTests(unittest.TestCase):
    def test_a_storage_binding_is_followed_at_most_once_per_path(self):
        payload = fixture_payload()
        paths = [reply_consumers.path_name(entry) for entry in payload["mids"]["9001"]["paths"]]
        repeated = [path for path in paths if repeated_segment_names(path)]
        self.assertEqual([], repeated)
        self.assertIn("send_gift_count", paths)
        self.assertIn("send_gift_count[]", paths)
        self.assertIn("detail.challenge_times[]", paths)


class ReplyConsumerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        archive = archive_path()
        if not archive.exists():
            raise unittest.SkipTest(f"source archive not supplied: {archive}")
        with zipfile.ZipFile(archive) as bundle:
            cls.blobs = reply_consumers.lua_blobs(bundle)
        cls.uncollapsed = reply_consumers.build(cls.blobs, collapse=False)
        cls.payload = reply_consumers.compact_payload(reply_consumers.collapse_sites(cls.uncollapsed))

    def test_r1_crash_class_is_required(self):
        self.assertIn("award", required_paths(self.payload, 532))
        self.assertIn("comment_list[].from_player_info", required_paths(self.payload, 1839))
        self.assertIn("A_pet_info", required_paths(self.payload, 1292))
        self.assertIn("B_pet_info", required_paths(self.payload, 1292))
        self.assertIn("pre_info", required_paths(self.payload, 628))
        self.assertIn("count", required_paths(self.payload, 176))
        self.assertIn("list", required_paths(self.payload, 176))
        self.assertIn("player_id", required_paths(self.payload, 177))
        self.assertTrue({"player_info"} <= required_paths(self.payload, 185) or "list[].player_info" in required_paths(self.payload, 185))

    def test_the_live_activities_event_requires_its_list(self):
        self.assertIn("list", required_paths(self.payload, 229))
        self.assertNotIn("params.list", required_paths(self.payload, 229))

    def test_activity_obligations_are_split_by_the_selected_table_id(self):
        record = self.payload["mids"]["234"]
        self.assertEqual("table_id", next(iter(record["branches"])))
        unconditional = required_paths(self.payload, 234)
        self.assertNotIn("details.server_support", unconditional)
        self.assertEqual("REQUIRED", branch_requirements(self.payload, 234, "table_id", "1129")["details.server_support"])
        self.assertNotIn("1129", [path for path in unconditional])
        unknown = record["branches"]["table_id"]["unknown"]
        self.assertEqual("UNKNOWN", unknown["status"])
        self.assertTrue(unknown["reason"])
        self.assertTrue(unknown["paths"])

    def test_every_mid_split_across_activity_windows_is_covered(self):
        self.assertEqual([], reply_consumers.branch_coverage_problems(self.payload))
        self.assertIn(234, reply_consumers.BRANCH_POLICIES)
        self.assertIn(231, reply_consumers.BRANCH_POLICY_EXEMPTIONS)

    def test_branch_sites_are_the_activity_window_selected_by_the_client(self):
        branch = self.payload["mids"]["234"]["branches"]["table_id"]["1129"]
        entry = next(entry for entry in branch["paths"] if reply_consumers.path_name(entry) == "details.server_support")
        files = {self.payload["site_files"][site[0]] for site in entry[2]}
        self.assertEqual({"app/windows/activities/Activity1129.lua"}, files)

    def test_site_collapse_keeps_every_obligation_and_output_under_five_megabytes(self):
        self.assertEqual(obligation_map(self.uncollapsed), obligation_map(self.payload))
        size = len(json.dumps(self.payload, sort_keys=True, separators=(",", ":")).encode())
        self.assertLess(size, 5 * 1024 * 1024, f"REPLY_CONSUMERS.json is {size} bytes")

    def test_site_collapse_merges_one_entry_per_file_and_line(self):
        for record in self.payload["mids"].values():
            for entry in record["paths"]:
                keys = [(site[0], site[1]) for site in entry[2]]
                self.assertEqual(len(keys), len(set(keys)))

    def test_every_sent_mid_has_a_callback_record(self):
        for mid in ("118", "176", "185", "532", "628", "1292", "1839"):
            self.assertIn(mid, self.payload["mids"])
            callbacks = self.payload["mids"][mid]["callbacks"]
            self.assertTrue(callbacks, mid)
            for callback in callbacks:
                self.assertIn(callback["status"], {"CHECKED", "UNKNOWN"}, mid)

    def test_write_outputs_carry_the_embedded_copy(self):
        outputs = reply_consumers.written_outputs(self.payload)
        self.assertEqual(
            set(outputs),
            {reply_consumers.CONSUMERS_PATH, reply_consumers.EMBED_PATH},
        )
        self.assertEqual(outputs[reply_consumers.EMBED_PATH], reply_consumers.serialise(self.payload))

    def test_generation_is_deterministic(self):
        again = reply_consumers.build(self.blobs)
        self.assertEqual(
            json.dumps(self.payload, sort_keys=True),
            json.dumps(again, sort_keys=True),
        )

    def test_every_repeated_segment_is_read_at_a_cited_site(self):
        for mid, record in self.payload["mids"].items():
            entries = {reply_consumers.path_name(entry): entry for entry in record["paths"]}
            for path in entries:
                repeated = repeated_segment_names(path)
                if not repeated:
                    continue
                # A repeated segment can be read on the line that reads its
                # parent path, so the prefix entries are evidence too.
                lines = [
                    self.blobs[self.payload["site_files"][site[0]]].splitlines()[site[1] - 1]
                    for prefix in path_prefixes(path)
                    for site in entries.get(prefix, (None, None, []))[2]
                ]
                accessed = set()
                for line in lines:
                    accessed |= normalised_access_names(line)
                for name in repeated:
                    self.assertIn(
                        name.replace("_", "").lower(),
                        accessed,
                        f"MID {mid} path {path} repeats {name} but no site line reads it: {lines}",
                    )

    def test_waiver_needs_reason_and_client_site(self):
        payload = {
            "mids": {
                "532": {
                    "paths": [
                        {"path": "award", "requirement": "REQUIRED"},
                    ]
                }
            }
        }
        problems = reply_consumers.validate_waivers(
            {"waivers": [{"mid": 532, "path": "award", "reason": "", "client": "app/windows/TreasureWindow.lua:561"}]},
            payload,
            self.blobs,
        )
        self.assertTrue(any("reason" in problem for problem in problems))
        problems = reply_consumers.validate_waivers(
            {"waivers": [{"mid": 532, "path": "award", "reason": "guarded at the call", "client": "missing.lua:1"}]},
            payload,
            self.blobs,
        )
        self.assertTrue(any("client" in problem for problem in problems))

    def test_waiver_marks_a_required_path_waived(self):
        payload = {
            "mids": {
                "532": {"paths": [{"path": "award", "requirement": "REQUIRED"}]}
            }
        }
        waived = reply_consumers.apply_waivers(
            {"waivers": [{"mid": 532, "path": "award", "reason": "guarded at the call", "client": "app/windows/TreasureWindow.lua:561"}]},
            payload,
        )
        self.assertEqual(waived["mids"]["532"]["paths"][0]["requirement"], "WAIVED")


if __name__ == "__main__":
    unittest.main()
