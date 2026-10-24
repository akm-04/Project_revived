package realtime

import (
	"gxb.local/backend/v2/internal/protocol/amf3"
	"testing"
)

func TestValidateGeneralDMRequiresMirroredPlayerType(t *testing.T) {
	o := &amf3.Object{Properties: []amf3.Property{{Name: "message", Value: "hello"}, {Name: "from_player_id", Value: int64(1)}, {Name: "from_player_name", Value: "A"}, {Name: "from_player_type", Value: int64(2)}, {Name: "player_type", Value: int64(2)}, {Name: "from_player_avatar_id", Value: int64(10001)}, {Name: "from_player_avatar_frame_id", Value: int64(1)}, {Name: "from_player_lev", Value: int64(10)}, {Name: "type", Value: int64(0)}, {Name: "np_info", Value: `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":1,"conquer_loop_id":0}`}}}
	if err := ValidateGeneralDM(o); err != nil {
		t.Fatal(err)
	}
	o.Properties[4].Value = int64(3)
	if err := ValidateGeneralDM(o); err == nil {
		t.Fatal("accepted unequal alias")
	}
}
