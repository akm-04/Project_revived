package arena

import (
	"encoding/json"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/foundation/ids"
	"strconv"
	"strings"
	"testing"
)

func TestReplayIndexesOnlyActualBattlesAndUsesJSONStringContent(t *testing.T) {
	identifier, _ := ids.NewUUID()
	room := d.TournamentRoom{Identifier: identifier, Status: d.RoomSettled, Attempts: []ids.UUID{{}, identifier, {}}, RoundResults: [3]int{d.RoundFirstWin, d.RoundSecondWin, d.RoundBothEmpty}, Selection: d.SelectionRoom{Team: 3}}
	room.Selection.Teams[0][1] = d.SelectedFormation{Heroes: []int64{17}}
	room.Selection.Teams[1][1] = d.SelectedFormation{Heroes: []int64{22}}
	row := TournamentRecord(room)
	if row["battle_count"] != 1 || row["team_1"] != "17|22" || row["team_2"] != "" {
		t.Fatal(row)
	}
	reply := TournamentReport(d.TournamentRoomView{Room: room, Report: []byte(`{"frame":1}`)})
	if reply["report"].([]map[string]any)[0]["content"] != `{"frame":1}` {
		t.Fatal("report content was not a JSON string")
	}
}

func TestReadyNoticeUsesStockPreparedFieldNames(t *testing.T) {
	view := d.TournamentRoomView{Room: d.TournamentRoom{Ready: [2]bool{true, false}, Selection: d.SelectionRoom{Team: 1}}}
	body := TournamentRoom(view)
	if body["A_prepared"] != int64(1) || body["B_prepared"] != int64(0) {
		t.Fatal(body)
	}
	if _, exists := body["A_is_prepared"]; exists {
		t.Fatal("non-source prepared alias")
	}
}

func TestTournamentRoomOmitsMissingPetAndSendsObjects(t *testing.T) {
	room := d.TournamentRoom{Selection: d.SelectionRoom{Team: 1, Turn: 7}}
	body := TournamentRoom(d.TournamentRoomView{Room: room})
	for _, key := range []string{"A_pet_info", "B_pet_info"} {
		if _, present := body[key]; present {
			t.Fatalf("%s present for a side with no pet: %#v", key, body[key])
		}
	}
	for _, key := range []string{"A_partners_info", "B_partners_info"} {
		if rows, ok := body[key].(map[string]map[string]any); !ok || rows == nil {
			t.Fatalf("%s is not an object: %#v", key, body[key])
		}
	}
	raw, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), `"A_pet_info":null`) || strings.Contains(string(raw), `"A_partners_info":null`) {
		t.Fatal(string(raw))
	}

	petID := int64(40001001)
	room.Selection.Teams[1][0] = d.SelectedFormation{Pet: petID}
	pet := map[string]any{"table_id": petID}
	body = TournamentRoom(d.TournamentRoomView{Room: room, Pets: [2]map[string]map[string]any{{}, {strconv.FormatInt(petID, 10): pet}}})
	if _, present := body["A_pet_info"]; present {
		t.Fatalf("empty side sent a pet: %#v", body["A_pet_info"])
	}
	if body["B_pet_info"].(map[string]any)["table_id"] != petID {
		t.Fatalf("selected pet missing: %#v", body["B_pet_info"])
	}

	report := TournamentReport(d.TournamentRoomView{Room: room})
	for _, key := range []string{"A_pet_info", "B_pet_info"} {
		if rows, ok := report[key].(map[string]map[string]any); !ok || rows == nil {
			t.Fatalf("report %s is not an object: %#v", key, report[key])
		}
	}
}
