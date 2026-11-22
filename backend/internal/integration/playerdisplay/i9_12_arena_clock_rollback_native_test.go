//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	app "gxb.local/backend/v2/internal/application/arena"
	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
)

// BUGS #108 family: a forward-stamped competition root met a decision time
// behind it. The casual match worker wrote the earlier decision time into
// UpdatedAt, SaveCompetitionTx refused its own root as a conflict, and the
// next match cycle failed instead of settling.
func TestI9_12CasualMatchClampsCompetitionAfterBackwardClock(t *testing.T) {
	database := pool(t)
	service := arenaService(t, database)
	server := rankingServer(t, database)
	first, _ := oneOnOnePlayer(t, database, server)
	second, _ := oneOnOnePlayer(t, database, server)

	period := d.CasualPeriodAt(time.Now().UTC())
	if !period.OpensAt.After(time.Now().UTC()) {
		period = d.CasualPeriodAt(period.OpensAt.Add(7 * 24 * time.Hour))
	}
	clock := &workplaceTime{at: period.OpensAt.Add(time.Minute)}
	service.Timed.Binder.Time = clock
	for _, actor := range []identity.ActorContext{first, second} {
		exec(t, database, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, actor.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
		arena := stockruntime.ArenaDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: service}
		if response := arena.Dispatch(ctx, unpinnedRequest(768, actor, clock.at, map[string]any{})); response.HTTPStatus != 200 {
			t.Fatalf("MID 768 arena info: %d %#v %v", response.HTTPStatus, response.Body, response.Cause)
		}
	}
	for _, actor := range []identity.ActorContext{first, second} {
		tournament := stockruntime.TournamentDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: service}
		if response := tournament.Dispatch(ctx, unpinnedRequest(1875, actor, clock.at, map[string]any{})); response.HTTPStatus != 200 {
			t.Fatalf("MID 1875 casual queue: %d %#v %v", response.HTTPStatus, response.Body, response.Cause)
		}
	}
	exec(t, database, `UPDATE arena_competitions SET created_at=$2::timestamptz+interval '8 hours',updated_at=$2::timestamptz+interval '8 hours' WHERE competition_id=$1`, d.CompetitionID, clock.at)

	decision, err := gen.NewTimedOperation(op(), clock.at)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := (app.Reconciler{Service: service}).Reconcile(ctx, decision, 10); err != nil {
		t.Fatalf("casual match after backward clock step: %v", err)
	}
	var created, updated time.Time
	if err := database.QueryRow(ctx, `SELECT created_at,updated_at FROM arena_competitions WHERE competition_id=$1`, d.CompetitionID).Scan(&created, &updated); err != nil {
		t.Fatal(err)
	}
	if !updated.Equal(clock.at.Add(8 * time.Hour)) {
		t.Fatalf("competition UpdatedAt rewritten backwards: created=%v updated=%v", created, updated)
	}
	root, found, err := (arenastore.Store{}).ReadCompetitionTx(ctx, database, false)
	if err != nil || !found || root.UpdatedAt.Before(root.CreatedAt) {
		t.Fatalf("durable competition: %+v found=%v err=%v", root, found, err)
	}
}
