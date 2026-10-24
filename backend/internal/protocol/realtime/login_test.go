package realtime

import (
	"errors"
	"testing"

	"gxb.local/backend/v2/internal/protocol/amf3"
	"gxb.local/backend/v2/internal/protocol/mids"
)

func TestParseTCPLoginStrictClaims(t *testing.T) {
	f := Frame{MID: mids.MIDTCPLogin, Params: &amf3.Object{Properties: []amf3.Property{
		{Name: "token", Value: "bearer"}, {Name: "region", Value: 2.0}, {Name: "room_id", Value: int32(99999)},
	}}}
	got, err := ParseTCPLogin(f)
	if err != nil {
		t.Fatal(err)
	}
	if got.Token != "bearer" || got.Region != 2 || got.RoomID != 99999 {
		t.Fatalf("got=%+v", got)
	}
}
func TestParseTCPLoginRejectsDuplicateFractionalAndMissing(t *testing.T) {
	cases := []*amf3.Object{
		{Properties: []amf3.Property{{Name: "token", Value: "x"}, {Name: "token", Value: "y"}, {Name: "region", Value: 2.0}, {Name: "room_id", Value: 2.0}}},
		{Properties: []amf3.Property{{Name: "token", Value: "x"}, {Name: "region", Value: 2.5}, {Name: "room_id", Value: 2.0}}},
		{Properties: []amf3.Property{{Name: "region", Value: 2.0}, {Name: "room_id", Value: 2.0}}},
	}
	for i, o := range cases {
		if _, err := ParseTCPLogin(Frame{MID: mids.MIDTCPLogin, Params: o}); !errors.Is(err, ErrMalformedTCPLogin) {
			t.Fatalf("case %d err=%v", i, err)
		}
	}
}
