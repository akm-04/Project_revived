package stockruntime

import (
	"encoding/json"
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
)

func TestIllusionMessageFollowsPlayerSeatsAndReady(t *testing.T) {
	teamInfo, err := json.Marshal(map[string]any{
		"room_id": int64(9), "status": int64(1),
		"master_id": int64(1), "master_id_info": map[string]any{"player_id": int64(1), "player_name": "p1"},
		"master_status": int64(1), "master_partner": "101", "master_partner_detail": []map[string]any{{"table_id": int64(101)}},
		"master_pet": int64(55), "master_pet_detail": map[string]any{"pet_id": int64(55)},
		"mate_1": int64(2), "mate_1_info": map[string]any{"player_id": int64(2), "player_name": "p2"},
		"mate_1_status": int64(1), "mate_1_partner": "201|202", "mate_1_partner_detail": []map[string]any{{"table_id": int64(201)}},
		"mate_2": int64(3), "mate_2_info": map[string]any{"player_id": int64(3), "player_name": "p3"},
		"mate_2_status": int64(0), "mate_2_partner": "301", "mate_2_partner_detail": []map[string]any{{"table_id": int64(301)}},
	})
	if err != nil {
		t.Fatal(err)
	}
	view := IllusionRoomNotice{RoomID: 9, Status: 1, Seated: []identity.PlayerID{1, 3},
		Ready: map[identity.PlayerID]bool{1: true, 3: false}, TeamInfo: teamInfo}
	message, err := illusionMessage(view)
	if err != nil {
		t.Fatal(err)
	}
	if message["status"] != float64(1) {
		t.Fatalf("room status changed %#v", message["status"])
	}
	if message["master_id"] != int64(1) || message["master_status"] != int64(1) || message["mate_1"] != int64(3) ||
		message["mate_1_status"] != int64(0) || message["mate_2"] != int64(0) || message["mate_2_status"] != int64(0) {
		t.Fatalf("seats %#v", message)
	}
	mateInfo, ok := message["mate_1_info"].(map[string]any)
	if !ok || mateInfo["player_id"] != float64(3) || message["mate_1_partner"] != "301" {
		t.Fatalf("mate one kept another player's row %#v", message)
	}
	detail, ok := message["mate_1_partner_detail"].([]any)
	if !ok || len(detail) != 1 {
		t.Fatalf("mate one detail %#v", message["mate_1_partner_detail"])
	}
	if row, ok := detail[0].(map[string]any); !ok || row["table_id"] != float64(301) {
		t.Fatalf("mate one detail row %#v", detail[0])
	}
	if message["mate_2_info"] != int64(0) || message["mate_2_partner"] != "" {
		t.Fatalf("vacated mate two not zeroed %#v", message)
	}
	if detail, ok := message["mate_2_partner_detail"].([]any); !ok || len(detail) != 0 {
		t.Fatalf("vacated mate two detail %#v", message["mate_2_partner_detail"])
	}
	if message["master_pet"] != float64(55) {
		t.Fatalf("master pet lost %#v", message["master_pet"])
	}
	var cached map[string]any
	if err = json.Unmarshal(teamInfo, &cached); err != nil {
		t.Fatal(err)
	}
	delete(cached, "master_pet")
	withoutPet, err := json.Marshal(cached)
	if err != nil {
		t.Fatal(err)
	}
	view.TeamInfo = withoutPet
	message, err = illusionMessage(view)
	if err != nil {
		t.Fatal(err)
	}
	if message["master_pet"] != int64(0) {
		t.Fatalf("a mate promoted to master sent a null pet %#v", message["master_pet"])
	}
}
