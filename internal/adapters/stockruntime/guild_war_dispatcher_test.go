package stockruntime

import (
	"context"
	"slices"
	"testing"
)

func TestGuildWarRedPointStaysLive(t *testing.T) {
	d := GuildWarRedPointDispatcher{Authority: httpAuthority{actorForHTTP(t)}}
	got := d.Dispatch(context.Background(), heroReq(t, GuildWarRedPointMID, map[string]any{}))
	if got.HTTPStatus != 200 || got.Body["is_enroll"] != false {
		t.Fatalf("%+v", got)
	}
	if slices.Contains(InactiveModeMIDs, GuildWarRedPointMID) {
		t.Fatal("1152 must not answer through the inactive dispatcher")
	}
}

func TestDrinkAndGuildWarAreInactive(t *testing.T) {
	for _, mid := range []uint16{590, 591, 592, 617, 596, 622, 1136, 1137, 1138, 1139, 1140, 1141, 1142, 1143, 1144, 1145, 1153, 1154} {
		if !slices.Contains(InactiveModeMIDs, mid) {
			t.Fatalf("%d must answer through the inactive dispatcher", mid)
		}
	}
}
