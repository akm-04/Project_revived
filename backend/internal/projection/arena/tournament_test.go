package arena

import (
	"encoding/json"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"reflect"
	"strconv"
	"strings"
	"testing"
)

func TestPlayoffsInfoReportsViewerDeclarationState(t *testing.T) {
	viewer := identity.PlayerID(41)
	view := d.TournamentView{Viewer: viewer, Period: d.TournamentPeriod{Entrants: []d.TournamentEntrant{{TournamentEnrollment: d.TournamentEnrollment{PlayerID: viewer}}}}}
	info := PlayoffsInfo(view)["player_info"].(map[string]any)
	if info["have_dec_flag"] != int64(0) {
		t.Fatalf("undeclared viewer have_dec_flag = %#v", info["have_dec_flag"])
	}
	view.Period.Entrants[0].Declaration = "Compete hard"
	info = PlayoffsInfo(view)["player_info"].(map[string]any)
	if info["have_dec_flag"] != int64(1) {
		t.Fatalf("declared viewer have_dec_flag = %#v", info["have_dec_flag"])
	}
}

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

func TestPlayoffsInfoListsOnlyDecidedRealQualifiers(t *testing.T) {
	period := d.TournamentPeriod{RosterLocked: true, Contests: []d.TournamentContest{{Stage: 3, Complete: true, Winner: 11}}}
	period.Groups[0] = [4]identity.PlayerID{11, 22, 0, 0}
	period.Groups[1] = [4]identity.PlayerID{33, 0, 0, 0}
	period.Entrants = []d.TournamentEntrant{
		{TournamentEnrollment: d.TournamentEnrollment{PlayerID: 11, PreviousSeasonRank: 1, RegistrationSequence: 1}, Group: 1},
		{TournamentEnrollment: d.TournamentEnrollment{PlayerID: 22, PreviousSeasonRank: 2, RegistrationSequence: 2}, Group: 1},
		{TournamentEnrollment: d.TournamentEnrollment{PlayerID: 33, PreviousSeasonRank: 3, RegistrationSequence: 3}, Group: 2},
	}
	status := PlayoffsInfo(d.TournamentView{Period: period})["battle_status"].(map[string]any)
	if rows, ok := status["3"].([]int64); !ok || !reflect.DeepEqual(rows, []int64{11, 22, 33}) {
		t.Fatalf("qualified quarterfinalists = %#v", status["3"])
	}
	period.Contests = append(period.Contests, d.TournamentContest{Stage: 3})
	status = PlayoffsInfo(d.TournamentView{Period: period})["battle_status"].(map[string]any)
	if rows, ok := status["3"].([]int64); !ok || len(rows) != 0 {
		t.Fatalf("undecided group play listed qualifiers: %#v", status["3"])
	}
}

func TestPlayoffsGroupAddsTheDisplayOnlyByeRow(t *testing.T) {
	period := d.TournamentPeriod{RosterLocked: true}
	period.Groups[0] = [4]identity.PlayerID{11, 22, 0, 0}
	period.Entrants = []d.TournamentEntrant{
		{TournamentEnrollment: d.TournamentEnrollment{PlayerID: 11}, Group: 1},
		{TournamentEnrollment: d.TournamentEnrollment{PlayerID: 22}, Group: 1},
	}
	group := PlayoffsGroup(d.TournamentView{Period: period}, 1)
	bye, ok := group["0"].(map[string]any)
	if !ok || bye["player_id"] != int64(0) || bye["fans"] != int64(0) || bye["win_times"] != int64(0) {
		t.Fatalf("sparse group BYE row = %#v", group["0"])
	}
	if group["11"] == nil || group["22"] == nil {
		t.Fatalf("sparse group lost its real seats: %#v", group)
	}

	full := d.TournamentPeriod{RosterLocked: true}
	full.Groups[0] = [4]identity.PlayerID{11, 22, 33, 44}
	if _, present := PlayoffsGroup(d.TournamentView{Period: full}, 1)["0"]; present {
		t.Fatal("full group served a BYE row")
	}
	unlocked := d.TournamentPeriod{}
	unlocked.Groups[0] = [4]identity.PlayerID{11, 22, 0, 0}
	if _, present := PlayoffsGroup(d.TournamentView{Period: unlocked}, 1)["0"]; present {
		t.Fatal("unlocked group served a BYE row")
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
