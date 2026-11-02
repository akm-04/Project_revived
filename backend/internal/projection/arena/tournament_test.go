package arena

import (
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/foundation/ids"
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
