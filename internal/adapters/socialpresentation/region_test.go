package socialpresentation

import (
	"encoding/json"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerpresentation"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	"gxb.local/backend/v2/internal/domain/identity"
)

func projected(pid identity.PlayerID) playerpresentation.Projected {
	return playerpresentation.Projected{Minimal: playerpresentation.Minimal{PlayerID: pid, Name: "peer", Level: 9, AvatarID: 110001001}}
}

func TestMapBaseFriendRowsCarryLogicalServerRegion(t *testing.T) {
	result := sp.Result{ObservedAt: time.Unix(1000, 0).UTC(), Friends: []sp.Player{{Presentation: projected(100001)}, {Presentation: projected(200002)}}}
	body, err := json.Marshal(MapBase(result))
	if err != nil {
		t.Fatal(err)
	}
	var decoded struct {
		Friends []struct {
			PlayerID int64 `json:"player_id"`
			Region   int64 `json:"region"`
		} `json:"friend_list"`
		List []struct {
			PlayerID int64 `json:"player_id"`
			Region   int64 `json:"region"`
		} `json:"list"`
	}
	if err = json.Unmarshal(body, &decoded); err != nil {
		t.Fatal(err)
	}
	if len(decoded.Friends) != 2 || decoded.Friends[0].Region != 1 || decoded.Friends[1].Region != 2 {
		t.Fatalf("friend_list regions %#v", decoded.Friends)
	}
	if len(decoded.List) != 2 || decoded.List[0].Region != 1 || decoded.List[1].Region != 2 {
		t.Fatalf("list regions %#v", decoded.List)
	}
}
