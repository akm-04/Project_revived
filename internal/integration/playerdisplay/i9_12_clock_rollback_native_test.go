//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/dormhouse"
)

// A forwarded server clock left the Dorm root after the corrected decision
// time. The owner read settles the Lounge and must clamp the root write instead
// of failing until the wall clock catches up.
func TestI9_12DormOwnerReadClampsRootAfterBackwardClock(t *testing.T) {
	p := pool(t)
	a, _, _ := dormFixture(t, p)
	s := dormService(p, p)
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{1}})
	exec(t, p, `UPDATE player_dorm_roots SET created_at=clock_timestamp()+interval '8 hours',updated_at=clock_timestamp()+interval '8 hours' WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_dorm_rooms SET created_at=clock_timestamp()+interval '8 hours',updated_at=clock_timestamp()+interval '8 hours' WHERE player_id=$1`, int64(a.PlayerID))
	dispatcher := stockruntime.DormDispatcher{Authority: unpinnedDispatchAuthority{actor: a}, Service: s}
	response := dispatcher.Dispatch(ctx, unpinnedRequest(2514, a, time.Now().UTC(), map[string]any{"house_id": int64(1)}))
	if response.HTTPStatus != 200 {
		t.Fatalf("MID2514 after backward clock step: status %d body %#v cause %v", response.HTTPStatus, response.Body, response.Cause)
	}
	var created, updated time.Time
	if e := p.QueryRow(ctx, `SELECT created_at,updated_at FROM player_dorm_roots WHERE player_id=$1`, int64(a.PlayerID)).Scan(&created, &updated); e != nil {
		t.Fatal(e)
	}
	if updated.Before(created) {
		t.Fatalf("dorm root timestamps inverted: created=%v updated=%v", created, updated)
	}
}

// The membership plan writes the changed rooms. A forward-dated room must not
// make the Enter command refuse its own verified write.
func TestI9_12DormEnterClampsRoomAfterBackwardClock(t *testing.T) {
	p := pool(t)
	a, _, c := dormFixture(t, p)
	s := dormService(p, p)
	house := dormOpen(t, s, a, c, 2, 1)
	exec(t, p, `UPDATE player_dorm_roots SET created_at=clock_timestamp()+interval '8 hours',updated_at=clock_timestamp()+interval '8 hours' WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_dorm_rooms SET created_at=clock_timestamp()+interval '8 hours',updated_at=clock_timestamp()+interval '8 hours' WHERE player_id=$1`, int64(a.PlayerID))
	dispatcher := stockruntime.DormDispatcher{Authority: unpinnedDispatchAuthority{actor: a}, Service: s}
	response := dispatcher.Dispatch(ctx, unpinnedRequest(2517, a, time.Now().UTC(), map[string]any{"house_id": house, "partner_ids": []int64{1}}))
	if response.HTTPStatus != 200 {
		t.Fatalf("MID2517 after backward clock step: status %d body %#v cause %v", response.HTTPStatus, response.Body, response.Cause)
	}
	var created, updated time.Time
	if e := p.QueryRow(ctx, `SELECT created_at,updated_at FROM player_dorm_rooms WHERE player_id=$1 AND house_id=$2`, int64(a.PlayerID), house).Scan(&created, &updated); e != nil {
		t.Fatal(e)
	}
	if updated.Before(created) {
		t.Fatalf("dorm room timestamps inverted: created=%v updated=%v", created, updated)
	}
}

// A Lounge visit after a backward clock step must settle nothing and keep the
// later stored anchor instead of refusing the whole owner read.
func TestI9_12DormLoungeVisitSettlesZeroAfterBackwardClock(t *testing.T) {
	p := pool(t)
	a, _, _ := dormFixture(t, p)
	s := dormService(p, p)
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{1}})
	hero := skillRead(t, p, a, 1)
	before := hero.Exp
	exec(t, p, `UPDATE player_dorm_heroes SET lounge_anchor=clock_timestamp()+interval '8 hours',updated_at=clock_timestamp()+interval '8 hours' WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	storedFacts, e := s.Owner.ReadHeroTx(ctx, p, hero.Ref())
	if e != nil {
		t.Fatal(e)
	}
	dispatcher := stockruntime.DormDispatcher{Authority: unpinnedDispatchAuthority{actor: a}, Service: s}
	response := dispatcher.Dispatch(ctx, unpinnedRequest(2514, a, time.Now().UTC(), map[string]any{"house_id": int64(1)}))
	if response.HTTPStatus != 200 {
		t.Fatalf("MID2514 lounge visit after backward clock step: status %d body %#v cause %v", response.HTTPStatus, response.Body, response.Cause)
	}
	if rows, ok := response.Body["exp_partners"].([]any); !ok || len(rows) != 0 {
		t.Fatalf("backward step reported a lounge payout: %#v", response.Body["exp_partners"])
	}
	if after := skillRead(t, p, a, 1); after.Exp != before {
		t.Fatalf("backward step minted exp: %d -> %d", before, after.Exp)
	}
	settledFacts, e := s.Owner.ReadHeroTx(ctx, p, hero.Ref())
	if e != nil || !settledFacts.LoungeAnchor.Equal(storedFacts.LoungeAnchor) {
		t.Fatalf("backward step moved the anchor: %v -> %v (%v)", storedFacts.LoungeAnchor, settledFacts.LoungeAnchor, e)
	}
}
