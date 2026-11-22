"""Regression checks for the popup catalogue extractor."""
import unittest

import popup_catalog


MESSAGE_TABLE = """return {
	keys = {"id", "name", "content", "type"},
	rows = {
		{"20005", "no diamond", "Not enough diamonds", "2"},
		{"20009", "busy", "Already busy", "2"},
		{"20099", "unused", "Never produced", "2"},
	}
}
"""

BACKEND_LUA = """
local var_0_0 = class("Backend")
function var_0_0.setupMidToEventNameMappings_(arg_1_0)
	arg_1_0.mid2EventNames_ = {}
	arg_1_0.mid2EventNames_[xyd.mid.PET_UPDATE_TRIGGER] = xyd.event.PET_UPDATE
end
"""

MID_LUA = "xyd.mid.SWEEP = 117\nxyd.mid.PET_UPDATE_TRIGGER = 118\n"

EVENT_LUA = 'xyd.event.PET_UPDATE = "__event_pet_update__"\n'


def sweep_lua(callback_body: str, request_callback: str = "function(arg_0, arg_1)") -> str:
    return f"""local var_0_0 = class("SweepWindow")

function var_0_0.start(arg_2_0)
	xyd.Backend.get():request(xyd.mid.SWEEP, {{}}, {request_callback}
{callback_body}
	end)
end
"""


def blobs(sweep: str) -> dict[str, str]:
    return {
        "app/common/network/mid.lua": MID_LUA,
        "app/common/network/Backend.lua": BACKEND_LUA,
        "app/common/event.lua": EVENT_LUA,
        "app/windows/SweepWindow.lua": sweep,
        "app/model/PetModel.lua": """local var_0_0 = class("PetModel")

function var_0_0.ctor(arg_3_0)
	arg_3_0:registerEvent(xyd.event.PET_UPDATE, handler(arg_3_0, arg_3_0.onPet_))
end

function var_0_0.onPet_(arg_4_0, arg_4_1)
	xyd.WindowManager.get():openWindow("pet_campaign_award", {})
end
""",
        "data/tables/message.lua": MESSAGE_TABLE,
    }


BACKEND_GO = """package stockruntime

const (
	unprovenRefusalCode     int64 = 35028
	insufficientDiamondCode int64 = 20005
	insufficientCoinCode    int64 = 20006
	insufficientStaminaCode int64 = 20007
	alreadyBusyCode         int64 = 20009
)

type failureRow struct {
	match   error
	class   failureClass
	code    int64
	detail  string
	balance bool
}

var sweepFailureRows = []failureRow{
	{match: errSweep, class: failureRefusal, balance: true},
}

func failSweep(err error) httpedge.Response {
	return failureFromRows(sweepFailureRows, err)
}

func (o SweepDispatcher) Dispatch(ctx context.Context, req httpedge.Request) httpedge.Response {
	switch req.Envelope.MID {
	case 117:
		if err := o.Service.Sweep(ctx); err != nil {
			return failSweep(err)
		}
	case 118:
		return failureReply(refusal(alreadyBusyCode))
	}
	return failureReply(defect(nil))
}
"""

INDEX_DOCUMENT = {"lookups": {"mid_to_system": {"117": "campaign", "118": "pet"}}}
MID_CLASSES = {"mids": [{"mid": 117, "system": "campaign"}, {"mid": 118, "system": "pet"}]}
MODE_SURFACE = {"mids": [
    {"mid": 900, "disposition": "LATER", "target": "I10"},
    {"mid": 117, "disposition": "LATER", "target": "I10"},
]}


def build(sweep: str, reviewed=None, waivers=None, go_files=None, index=None, mid_classes=None) -> dict:
    return popup_catalog.build_catalog(
        blobs(sweep),
        go_files if go_files is not None else {"internal/adapters/stockruntime/fixture.go": BACKEND_GO},
        index or INDEX_DOCUMENT,
        mid_classes or MID_CLASSES,
        MODE_SURFACE,
        reviewed or {"entries": {}},
        waivers or {"entries": {}},
        "fixture-sha",
    )


def rows_by_window(payload: dict, window: str) -> list[dict]:
    return [row for row in payload["rows"]
            if row["kind"] != "ERROR_TOAST" and row["popup"].get("window") == window]


class PopupCatalogueTests(unittest.TestCase):
    def test_code_guard_with_producer_is_produced(self):
        payload = build(sweep_lua("""		if arg_1.error_code == 20005 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("NO_DIAMOND"), nil)
		end"""))
        row = rows_by_window(payload, "CommonAlertWindow")[0]
        self.assertEqual(row["kind"], "REPLY")
        self.assertEqual(row["status"], "PRODUCED")
        self.assertEqual(row["trigger"]["mids"], [117])
        self.assertEqual(row["trigger"]["guard"]["type"], "code")
        self.assertEqual(row["trigger"]["guard"]["code"], 20005)
        self.assertTrue(any("insufficientDiamondCode" in item["via"] or "shared" in item["via"]
                            for item in row["producers"]))

    def test_code_guard_without_producer_is_gap(self):
        payload = build(sweep_lua("""		if arg_1.error_code == 20099 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("UNUSED"), nil)
		end"""))
        row = rows_by_window(payload, "CommonAlertWindow")[0]
        self.assertEqual(row["status"], "GAP")
        self.assertIn("20099", row["reason"])

    def test_field_empty_guard_is_produced_unproven(self):
        payload = build(sweep_lua("""		if arg_1.award and arg_1.award ~= nil then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end"""))
        row = rows_by_window(payload, "alert_award")[0]
        self.assertEqual(row["status"], "PRODUCED_UNPROVEN")
        self.assertEqual(row["trigger"]["guard"]["type"], "field")

    def test_helper_indirect_popup_is_attributed(self):
        payload = build(sweep_lua("""		if arg_1.awards then
			showAwards(arg_1.awards)
		end
	end)
end

local function showAwards(arg_9_0)
	xyd.WindowManager.get():openWindow("new_item_tips", {})
end

local function trailing_"""))
        row = rows_by_window(payload, "new_item_tips")[0]
        self.assertEqual(row["kind"], "REPLY")
        self.assertEqual(row["trigger"]["mids"], [117])

    def test_push_handler_popup_is_push(self):
        payload = build(sweep_lua("""		if arg_0 == xyd.error.OK then
			return
		end"""))
        row = rows_by_window(payload, "pet_campaign_award")[0]
        self.assertEqual(row["kind"], "PUSH")
        self.assertEqual(row["trigger"]["events"], ["PET_UPDATE"])
        self.assertEqual(row["trigger"]["mids"], [118])
        self.assertEqual(row["owner"], "pet")

    def test_unresolved_callback_is_unknown(self):
        payload = build(sweep_lua("		return", request_callback="notAFunction"))
        row = next(row for row in payload["rows"] if row["popup"]["window"] == "<unresolved>")
        self.assertEqual(row["kind"], "REPLY")
        self.assertEqual(row["status"], "UNKNOWN")
        self.assertIn("notAFunction", row["reason"])

    def test_unserved_mid_is_unbuilt_with_phase(self):
        payload = build(sweep_lua("""		if arg_1.award then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end"""), index={"lookups": {"mid_to_system": {"118": "pet"}}},
            mid_classes={"mids": [{"mid": 118, "system": "pet"}]})
        row = rows_by_window(payload, "alert_award")[0]
        self.assertEqual(row["status"], "UNBUILT")
        self.assertEqual(row["owner"], "I10")

    def test_message_table_rows_and_producers(self):
        messages = popup_catalog.parse_messages(MESSAGE_TABLE)
        self.assertEqual([message["code"] for message in messages], [20005, 20009, 20099])
        payload = build(sweep_lua("		return"))
        by_code = {row["popup"]["code"]: row for row in payload["rows"] if row["kind"] == "ERROR_TOAST"}
        self.assertEqual(by_code[20005]["status"], "PRODUCED")
        self.assertEqual(by_code[20009]["status"], "PRODUCED")
        self.assertEqual(by_code[20099]["status"], "UNPRODUCED")
        self.assertEqual(by_code[20005]["owner"], "campaign")

    def test_message_code_compared_by_is_listed(self):
        payload = build(sweep_lua("""		if arg_1.error_code == 20099 then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end"""))
        row = next(row for row in payload["rows"] if row["popup"].get("code") == 20099)
        self.assertEqual(row["compared_by"][0]["mid"], 117)

    def test_reviewed_reachable_with_test_becomes_produced(self):
        base = build(sweep_lua("""		if arg_1.award then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end"""))
        identifier = rows_by_window(base, "alert_award")[0]["id"]
        payload = build(
            sweep_lua("""		if arg_1.award then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end"""),
            reviewed={"entries": {identifier: {"status": "REACHABLE", "finding": "A-1",
                                               "evidence": ["src_64/app/windows/SweepWindow.lua:1"], "test": "TestAward"}}},
        )
        self.assertEqual(rows_by_window(payload, "alert_award")[0]["status"], "PRODUCED")

    def test_waiver_applies_and_stale_waiver_is_reported(self):
        sweep = sweep_lua("""		if arg_1.error_code == 20099 then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end""")
        base = build(sweep)
        identifier = rows_by_window(base, "alert_award")[0]["id"]
        entry = {"reason": "deferred", "client": "app/windows/SweepWindow.lua:1", "owner_phase": "I10"}
        payload = build(sweep, waivers={"entries": {identifier: entry}})
        self.assertEqual(rows_by_window(payload, "alert_award")[0]["status"], "WAIVED")
        problems = popup_catalog.validate_inputs(payload["rows"], blobs(sweep),
                                                 {"entries": {identifier: entry}}, {"entries": {}})
        self.assertEqual(problems, [])
        stale = popup_catalog.validate_inputs(payload["rows"], blobs(sweep), {"entries": {}},
                                               {"entries": {}})
        self.assertEqual(stale, [])

    def test_waiver_on_produced_row_is_stale(self):
        sweep = sweep_lua("""		if arg_1.error_code == 20005 then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end""")
        payload = build(sweep)
        identifier = rows_by_window(payload, "alert_award")[0]["id"]
        entry = {"reason": "deferred", "client": "app/windows/SweepWindow.lua:1", "owner_phase": "I10"}
        problems = popup_catalog.validate_inputs(payload["rows"], blobs(sweep),
                                                 {"entries": {identifier: entry}}, {"entries": {}})
        self.assertTrue(any("no longer needs it" in problem for problem in problems))

    def test_waiver_for_missing_popup_is_reported(self):
        problems = popup_catalog.validate_inputs([], {}, {"entries": {"REPLY:a.lua:1": {
            "reason": "x", "client": "a.lua:1", "owner_phase": "I10"}}}, {"entries": {}})
        self.assertIn("popup id no longer exists", problems[0])

    def test_generated_output_is_deterministic(self):
        sweep = sweep_lua("""		if arg_1.error_code == 20005 then
			xyd.WindowManager.get():openWindow("alert_award", {})
		end""")
        first = popup_catalog.serialise(build(sweep))
        second = popup_catalog.serialise(build(sweep))
        self.assertEqual(first, second)

    def test_local_popup_is_client_only(self):
        payload = build("""local var_0_0 = class("SweepWindow")

function var_0_0.uiOnly(arg_1_0)
	xyd.WindowManager.get():openWindow("toast", {message = "hello"})
end
""")
        row = rows_by_window(payload, "toast")[0]
        self.assertEqual(row["kind"], "LOCAL")
        self.assertEqual(row["status"], "CLIENT_ONLY")


if __name__ == "__main__":
    unittest.main()
