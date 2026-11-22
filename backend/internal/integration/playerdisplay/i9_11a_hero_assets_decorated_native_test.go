//go:build postgres

package playerdisplay_test

import (
	"context"
	"net/http"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyresetstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/dailyreset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func TestI9I11ANativeSkillLevel53ThroughHeroDispatcher(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	actor := heroSkillLevelFixture(t, database, revision, 1000000, 10, time.Now().UTC().Add(-time.Hour))
	dispatcher := stockruntime.HeroDispatcher{
		Authority:   playtestAuthority{actor},
		Service:     i911aHeroService(database),
		SkillLevels: i911aHeroSkillService(database, i911aMissionFacts(database)),
	}
	upgrade := i911aDispatch(t, dispatcher, actor, 53, map[string]any{"partner_id": int64(1), "skill_index": int64(1)}, op())
	i911aExpect(t, upgrade, http.StatusOK, 0)
	if upgrade.Body["skill_point"] != int64(9) {
		t.Fatalf("MID 53 success body %#v", upgrade.Body)
	}
	exec(t, database, `UPDATE player_heroes SET updated_at=clock_timestamp()+interval '1 hour' WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	var forwardStamp time.Time
	if err := database.QueryRow(ctx, `SELECT updated_at FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID)).Scan(&forwardStamp); err != nil {
		t.Fatal(err)
	}
	// K3: a decision before the stored hero write is clamped, not refused.
	forward := i911aDispatch(t, dispatcher, actor, 53, map[string]any{"partner_id": int64(1), "skill_index": int64(2)}, op())
	i911aExpect(t, forward, http.StatusOK, 0)
	if forward.Body["skill_point"] != int64(8) {
		t.Fatalf("MID 53 forward body %#v", forward.Body)
	}
	var clamped time.Time
	if err := database.QueryRow(ctx, `SELECT updated_at FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID)).Scan(&clamped); err != nil {
		t.Fatal(err)
	}
	if !clamped.Equal(forwardStamp) {
		t.Fatalf("MID 53 forward clamp %v want %v", clamped, forwardStamp)
	}
}

func i911aDecorated(database *postgres.Pool, composition stockruntime.HeroAssetsComposition) httpedge.Dispatcher {
	reset := dailyreset.Service{Markers: dailyresetstore.Store{Queryer: database}, Counters: dailyreset.ZeroCounters{}}
	return stockruntime.Decorated{Next: composition.Dispatcher, DailyReset: reset}
}

func i911aTracked(actor identity.ActorContext) context.Context {
	tracked, _ := observability.WithRequestNote(ctx)
	observability.NoteActor(tracked, observability.RequestActor{PlayerID: int64(actor.PlayerID)})
	return tracked
}

func i911aDispatchTracked(t *testing.T, tracked context.Context, dispatcher httpedge.Dispatcher, actor identity.ActorContext, mid uint16, params map[string]any, o operation.Context) httpedge.Response {
	t.Helper()
	request := playtestRequest(actor, mid, params)
	request.Envelope.Operation = o
	return dispatcher.Dispatch(tracked, request)
}

func TestI9I11ANativeHeroAssetsRepliesCarryEconomyAndDailyUpdates(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	vip := privilegeActor(t, database, revision)
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(vip, uuid().String(), 300), op()); err != nil {
		t.Fatal(err)
	}
	i911aSetScalar(t, database, vip, "crystal", 100000)
	i911aSetSkillPoint(t, database, vip, 10)
	buy := i911aDispatchTracked(t, i911aTracked(vip), i911aDecorated(database, i911aComposition(database, vip)), vip, 99, map[string]any{}, op())
	i911aExpect(t, buy, http.StatusOK, 0)

	item := privilegeActor(t, database, revision)
	i911aStack(t, database, item, 50001538, 2)
	use := i911aDispatchTracked(t, i911aTracked(item), i911aDecorated(database, i911aComposition(database, item)), item, 90, map[string]any{"item_id": int64(50001538), "item_num": int64(1)}, op())
	i911aExpect(t, use, http.StatusOK, 0)

	for name, response := range map[string]httpedge.Response{"99": buy, "90": use} {
		economy, ok := response.Body["economy_"].(map[string]any)
		if !ok || economy["daily_updates"] != int64(1) {
			t.Fatalf("MID %s economy_ %#v", name, response.Body)
		}
		if _, ok := economy["skill_point"]; !ok {
			t.Fatalf("MID %s economy_ lacks skill_point %#v", name, economy)
		}
	}
	if economy, _ := buy.Body["economy_"].(map[string]any); economy["crystal"] != int64(99990) {
		t.Fatalf("MID 99 economy_ crystal %#v", buy.Body)
	}
}
