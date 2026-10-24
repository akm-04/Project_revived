package realtime

import (
	"gxb.local/backend/v2/internal/protocol/amf3"
	"math"
	"strings"
	"testing"
)

func chatObj(message string, extra ...amf3.Property) *amf3.Object {
	return &amf3.Object{Properties: append([]amf3.Property{{Name: "message", Value: message}, {Name: "channel", Value: float64(0)}}, extra...)}
}
func TestChannelChatStrictInputAndUnicode(t *testing.T) {
	for _, message := range []string{" ", "[face:1] 中文🙂", strings.Repeat("🙂", 140)} {
		r, e := ParseChannelChat(chatObj(message))
		if e != nil || r.Message != message {
			t.Fatal(r, e)
		}
	}
	for _, o := range []*amf3.Object{chatObj(""), chatObj(strings.Repeat("🙂", 141)), chatObj(string([]byte{0xff})), chatObj("x", amf3.Property{Name: "message", Value: "duplicate"}), chatObj("x", amf3.Property{Name: "player_id", Value: 1.0}), chatObj("x", amf3.Property{Name: "type", Value: math.NaN()}), chatObj("x", amf3.Property{Name: "type", Value: 0.5}), chatObj("x", amf3.Property{Name: "type", Value: 9.0}), chatObj("x", amf3.Property{Name: "region", Value: math.Inf(1)}), chatObj("x", amf3.Property{Name: "token", Value: 1.0})} {
		if _, e := ParseChannelChat(o); e == nil {
			t.Fatal("accepted malformed", o)
		}
	}
	for n := 0; n <= 8; n++ {
		r, e := ParseChannelChat(chatObj("x", amf3.Property{Name: "type", Value: float64(n)}, amf3.Property{Name: "token", Value: "legacy"}))
		if e != nil || r.Type != int64(n) {
			t.Fatal(n, r, e)
		}
	}
}
func TestOrdinaryChannelChatPayloadRejectsForgedNP(t *testing.T) {
	o := &amf3.Object{Properties: []amf3.Property{{Name: "player_id", Value: 1.0}, {Name: "player_name", Value: "sender"}, {Name: "message", Value: "x"}, {Name: "player_type", Value: -17.0}, {Name: "type", Value: 0.0}, {Name: "avatar_id", Value: 0.0}, {Name: "avatar_frame_id", Value: 0.0}, {Name: "lev", Value: 1.0}, {Name: "np_info", Value: `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":0}`}}}
	if e := ValidateOrdinaryChannelChat(o); e != nil {
		t.Fatal(e)
	}
	for _, bad := range []string{`{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":0,"extra":0}`, `{"title_info":"@@@@","title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":0}`, `{"title_info":"vip","bubble_info":"10001@0","conquer_lev":0,"conquer_loop_id":0}`, `{"title_info":"@@@@","bubble_info":"10001@0","conquer_lev":0.5,"conquer_loop_id":0}`} {
		o.Properties[8].Value = bad
		if e := ValidateOrdinaryChannelChat(o); e == nil {
			t.Fatal(bad)
		}
	}
	o.Properties[0].Value = float64(1 << 53)
	if e := ValidateOrdinaryChannelChat(o); e == nil {
		t.Fatal("unsafeinteger")
	}
}
