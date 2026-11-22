//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// TestI9_9ATeaSXWishUsesSourceClassification proves 1809 sizes a wish from
// the source partner is_sx flag, not the compiled hero kind: Guan Yin
// (10001032) is hero_kind NORMAL but partner is_sx=1, so her wish needs two
// scrolls and a third donor is refused without a debit. A normal girl keeps
// the three-scroll need.
func TestI9_9ATeaSXWishUsesSourceClassification(t *testing.T) {
	p := pool(t)
	defer p.Close()
	revision := installed(t, p)
	receiver := bornActor(t, p)
	donors := []identity.ActorContext{bornActor(t, p), bornActor(t, p), bornActor(t, p)}
	normal := bornActor(t, p)
	members := append(append([]identity.ActorContext{}, donors...), normal)
	guildFixture(t, p, receiver, members...)

	const sxTable, normalTable = int64(10001032), int64(10001001)
	sxScroll := scrollForHero(t, p, revision, sxTable)
	if sxScroll != 40001032 {
		t.Fatalf("Guan Yin scroll=%d", sxScroll)
	}
	normalScroll := scrollForHero(t, p, revision, normalTable)
	bornHero(t, p, receiver, revision, sxTable, 1)
	bornHero(t, p, normal, revision, normalTable, 1)
	for _, donor := range donors {
		exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(donor.PlayerID), sxScroll)
	}

	authority := teaAuthority{"receiver": receiver, "normal": normal}
	for index, donor := range donors {
		authority[fmt.Sprintf("donor%d", index)] = donor
	}
	dispatcher := stockruntime.GuildTeaDispatcher{Authority: authority, Service: teaService(p)}
	op := contentOp(t, p, revision)
	call := func(token string, mid uint16, params map[string]any) httpedge.Response {
		return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{Operation: op, MID: mid, Params: params,
			Claims: wire.CredentialClaims{Token: token, Region: int64(receiver.LogicalServerID)}, ReceivedAt: time.Now().UTC()}})
	}

	if got := call("receiver", 1809, map[string]any{"item_id": sxScroll}); got.HTTPStatus != 200 {
		t.Fatalf("SX wish=%+v", got)
	}
	if need := scalar(t, p, `SELECT need_num FROM guild_tea_wishes WHERE player_id=$1`, int64(receiver.PlayerID)); need != 2 {
		t.Fatalf("SX wish need_num=%d, want 2 from partner.is_sx", need)
	}
	if got := call("normal", 1809, map[string]any{"item_id": normalScroll}); got.HTTPStatus != 200 {
		t.Fatalf("normal wish=%+v", got)
	}
	if need := scalar(t, p, `SELECT need_num FROM guild_tea_wishes WHERE player_id=$1`, int64(normal.PlayerID)); need != 3 {
		t.Fatalf("normal wish need_num=%d, want 3", need)
	}

	for index := 0; index < 2; index++ {
		if got := call(fmt.Sprintf("donor%d", index), 1810, map[string]any{"player_id": int64(receiver.PlayerID)}); got.HTTPStatus != 200 {
			t.Fatalf("SX donation %d=%+v", index, got)
		}
	}
	if current := scalar(t, p, `SELECT current_num FROM guild_tea_wishes WHERE player_id=$1`, int64(receiver.PlayerID)); current != 2 {
		t.Fatalf("SX wish current_num=%d", current)
	}
	if got := call("donor2", 1810, map[string]any{"player_id": int64(receiver.PlayerID)}); got.HTTPStatus != 409 || got.Body["error_code"] != int64(35028) {
		t.Fatalf("third SX donor=%+v", got)
	}
	if left := scalar(t, p, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(donors[2].PlayerID), sxScroll); left != 1 {
		t.Fatalf("refused third donor scroll=%d", left)
	}
	if gifts := scalar(t, p, `SELECT COUNT(*) FROM guild_tea_gifts WHERE donor_id=$1`, int64(donors[2].PlayerID)); gifts != 0 {
		t.Fatalf("refused third donor gifts=%d", gifts)
	}
}
