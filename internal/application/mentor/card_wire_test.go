package mentor

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/playerpresentation"
)

// A-201: the accepted class relation card is inserted into the stock friend
// list, which reads is_sent and recalling_friend without a nil guard.
func TestCardWireCarriesFriendRecallFields(t *testing.T) {
	row := cardWire(playerpresentation.Projected{Minimal: playerpresentation.Minimal{PlayerID: 200001, Name: "peer", Level: 9, AvatarID: 4, AvatarFrameID: 5}}, time.Unix(1000, 0).UTC())
	if isSent, present := row["is_sent"]; !present || isSent != false {
		t.Fatalf("is_sent = %#v, present %v", isSent, present)
	}
	if recalling, present := row["recalling_friend"]; !present || recalling != int64(0) {
		t.Fatalf("recalling_friend = %#v, present %v", recalling, present)
	}
	if row["player_id"] != int64(200001) {
		t.Fatalf("card identity changed: %#v", row)
	}
}
