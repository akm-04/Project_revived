//go:build postgres

package playerdisplay_test

import (
	"testing"

	app "gxb.local/backend/v2/internal/application/dormhouse"
)

// A Lounge settlement that accrues nothing must not report a partner row: the
// stock client animates every exp_partners row as a flat "+100".
func TestI912LoungeReportsOnlySettledGain(t *testing.T) {
	p := pool(t)
	a, _, _ := dormFixture(t, p)
	s := dormService(p, p)
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{1}})
	before := skillRead(t, p, a, 1).Exp
	body, e := s.Read(ctx, a, op(), 2514, 0, 1)
	if e != nil {
		t.Fatal(e)
	}
	if rows, ok := body["exp_partners"].([]any); !ok || len(rows) != 0 {
		t.Fatalf("zero-gain settlement reported partners: %v", body["exp_partners"])
	}
	if after := skillRead(t, p, a, 1).Exp; after != before {
		t.Fatalf("zero-gain settlement changed exp: %d -> %d", before, after)
	}

	exec(t, p, `UPDATE player_dorm_heroes SET lounge_anchor=clock_timestamp()-interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	body, e = s.Read(ctx, a, op(), 2514, 0, 1)
	if e != nil {
		t.Fatal(e)
	}
	rows, ok := body["exp_partners"].([]any)
	if !ok || len(rows) != 1 {
		t.Fatalf("accrued settlement reported no partner: %v", body["exp_partners"])
	}
	if gained := skillRead(t, p, a, 1).Exp; gained <= before {
		t.Fatalf("accrued settlement paid nothing: %d -> %d", before, gained)
	}
}
