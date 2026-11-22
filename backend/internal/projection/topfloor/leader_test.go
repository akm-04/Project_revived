package topfloor

import (
	"testing"

	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
)

// TestFormationHeroRowsCarryTaskLeader proves the stock client's ArenaWindow
// line 413 condition (heros[i].is_leader > 0) is served for the task-mode
// leader and only for that hero, including in the robot-shaped row copy where
// partner_id is rewritten to table_id.
func TestFormationHeroRowsCarryTaskLeader(t *testing.T) {
	leaderPartner, otherPartner := int64(7001), int64(7002)
	for _, testCase := range []struct {
		name   string
		player identity.PlayerID
	}{
		{name: "robot shaped row", player: identity.PlayerID(100001)},
		{name: "plain row", player: identity.PlayerID(130001)},
	} {
		t.Run(testCase.name, func(t *testing.T) {
			view := d.Display{
				Occupant: d.Occupant{Player: testCase.player},
				Leader:   leaderPartner,
				Heroes: []map[string]any{
					{"partner_id": leaderPartner, "table_id": int64(10001001)},
					{"partner_id": otherPartner, "table_id": int64(10001002)},
				},
			}
			row := Formation(view)
			heroes, ok := row["heros"].([]map[string]any)
			if !ok || len(heroes) != 2 {
				t.Fatalf("formation heroes %#v", row["heros"])
			}
			if heroes[0]["is_leader"] != int64(1) {
				t.Fatalf("leader hero row is_leader = %#v", heroes[0]["is_leader"])
			}
			if _, present := heroes[1]["is_leader"]; present {
				t.Fatalf("non-leader hero row carries is_leader: %#v", heroes[1])
			}
		})
	}
}
