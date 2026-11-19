//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/campaign"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/protocol/replyconformance"
)

// trialSweepClock pins the decision day to the one weekday that runs the
// prophecy group this test sweeps (group 16 is scheduled when day%6 == 0).
type trialSweepClock struct{ at time.Time }

func (c trialSweepClock) Now(context.Context) (time.Time, error) { return c.at, nil }

func prophecyDay(at time.Time) time.Time {
	day := modes.Day(at)
	day += (6 - ((day%6)+6)%6) % 6
	return modes.DayBegins(day).Add(6 * time.Hour)
}

func trialSweepActor(t *testing.T, p *pg.Pool, s app.Mode, at time.Time) (identity.ActorContext, string) {
	t.Helper()
	a, revision := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	compositeLevel(t, p, a, revision, 90)
	exec(t, p, `UPDATE player_directory_profiles SET lev=90 WHERE player_id=$1`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_heroes SET color=7 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,7,$2,'function.lua:7:1|11',$3) ON CONFLICT DO NOTHING`, int64(a.PlayerID), revision, at.Add(-time.Hour))
	team := []int64{1, 0, 0, 0, 0}
	if _, err := s.Fight(ctx, a, app.Fight{CampaignID: 16001, Type: 16, Formation: team}, op()); err != nil {
		t.Fatal("trial fight", err)
	}
	tracked, _ := changes.Track(ctx)
	if _, err := s.Result(tracked, a, app.Result{CampaignID: 16001, Type: 16, Star: 3, Formation: team}, op()); err != nil {
		t.Fatal("trial clear", err)
	}
	return a, revision
}

func trialUsed(t *testing.T, p *pg.Pool, player identity.PlayerID) int64 {
	t.Helper()
	var raw string
	if err := p.QueryRow(ctx, `SELECT trial_wins::text FROM campaign_players WHERE player_id=$1`, int64(player)).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	var wins map[string]struct{ Used int64 }
	if err := json.Unmarshal([]byte(raw), &wins); err != nil {
		t.Fatal(err)
	}
	return wins["16"].Used
}

func TestI9_11TrialSweepTicketsCrystalsAndReplayNative(t *testing.T) {
	p := pool(t)
	s := campaignMode(t, p)
	at := prophecyDay(time.Now())
	s.Timed.Binder.Time = trialSweepClock{at: at}
	read := func(sql string, player identity.PlayerID) int64 {
		t.Helper()
		var value int64
		if err := p.QueryRow(ctx, sql, int64(player)).Scan(&value); err != nil {
			t.Fatal(err)
		}
		return value
	}
	energySQL := `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`
	ticketSQL := `SELECT coalesce((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001013),0)`
	crystalSQL := `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`

	tickets, revision := trialSweepActor(t, p, s, at)
	lines := []grant.Line{{Kind: grant.StackItem, ItemID: 50001013, Amount: 5}}
	if _, err := compositeI5(p).AdminGrant(ctx, authority().Operator, tickets.PlayerID, uuid().String(), "I9_11TS_NATIVE", lines, opPinned(revision)); err != nil {
		t.Fatal(err)
	}
	q := app.Sweep{CampaignID: 16001, Type: 16, Count: 1, Kind: 1}
	energyBefore := read(energySQL, tickets.PlayerID)
	tracked, _ := changes.Track(ctx)
	firstOp := op()
	first, err := s.Sweep(tracked, tickets, q, firstOp)
	if err != nil {
		t.Fatal("ticket sweep", err)
	}
	replyconformance.Check(t, 117, first)
	if len(first["items"].([][]d.Item)) != 1 || fmt.Sprint(first["challenge"].(map[string]any)["id"]) != "16" || fmt.Sprint(first["challenge"].(map[string]any)["left_times"]) != "0" {
		t.Fatalf("ticket reply %#v", first)
	}
	if read(energySQL, tickets.PlayerID) != energyBefore-6 || read(ticketSQL, tickets.PlayerID) != 4 || trialUsed(t, p, tickets.PlayerID) != 2 {
		t.Fatalf("ticket debits energy=%d tickets=%d uses=%d", read(energySQL, tickets.PlayerID), read(ticketSQL, tickets.PlayerID), trialUsed(t, p, tickets.PlayerID))
	}
	replay, err := s.Sweep(ctx, tickets, q, firstOp)
	if err != nil || fmt.Sprint(replay["challenge"].(map[string]any)["left_times"]) != "0" || read(ticketSQL, tickets.PlayerID) != 4 || read(energySQL, tickets.PlayerID) != energyBefore-6 {
		t.Fatalf("ticket replay %v %v", replay, err)
	}
	changed := q
	changed.Kind = 2
	var conflict *receipt.ConflictError
	if _, err = s.Sweep(ctx, tickets, changed, firstOp); !errors.As(err, &conflict) {
		t.Fatal("conflicting retry", err)
	}

	crystals, _ := trialSweepActor(t, p, s, at)
	crystalBefore := read(crystalSQL, crystals.PlayerID)
	energyBefore = read(energySQL, crystals.PlayerID)
	tracked, _ = changes.Track(ctx)
	second, err := s.Sweep(tracked, crystals, changed, op())
	if err != nil {
		t.Fatal("crystal sweep", err)
	}
	replyconformance.Check(t, 117, second)
	if fmt.Sprint(second["challenge"].(map[string]any)["id"]) != "16" {
		t.Fatalf("crystal reply %#v", second)
	}
	if read(crystalSQL, crystals.PlayerID) != crystalBefore-1 || read(energySQL, crystals.PlayerID) != energyBefore-6 || trialUsed(t, p, crystals.PlayerID) != 2 {
		t.Fatalf("crystal debits crystal=%d energy=%d uses=%d", read(crystalSQL, crystals.PlayerID), read(energySQL, crystals.PlayerID), trialUsed(t, p, crystals.PlayerID))
	}
}
