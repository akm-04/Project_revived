package realtime

import (
	"gxb.local/backend/v2/internal/protocol/amf3"
	"testing"
)

func Test6CQualifiedCosmeticMetadataGrammar(t *testing.T) {
	obj := func(np string) *amf3.Object {
		return &amf3.Object{Properties: []amf3.Property{{Name: "player_id", Value: 1.0}, {Name: "player_name", Value: "A"}, {Name: "message", Value: "x"}, {Name: "player_type", Value: 0.0}, {Name: "type", Value: 0.0}, {Name: "avatar_id", Value: 1.0}, {Name: "avatar_frame_id", Value: 0.0}, {Name: "lev", Value: 1.0}, {Name: "np_info", Value: np}}}
	}
	for _, np := range []string{`{"title_info":"1001@0@0","bubble_info":"10002@1700000010","conquer_lev":0,"conquer_loop_id":0}`, `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":0}`} {
		if e := ValidateChannelChat(obj(np)); e != nil {
			t.Fatal(np, e)
		}
	}
	for _, np := range []string{`{"title_info":"1001@0","bubble_info":"10002@0","conquer_lev":0,"conquer_loop_id":0}`, `{"title_info":"@@@@","bubble_info":"10002@-1","conquer_lev":0,"conquer_loop_id":0}`, `{"title_info":"@@@@","bubble_info":"9007199254740992@0","conquer_lev":0,"conquer_loop_id":0}`} {
		if ValidateChannelChat(obj(np)) == nil {
			t.Fatal("accepted malformed metadata", np)
		}
	}
}
