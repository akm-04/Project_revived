//go:build postgres

package stockruntime

import (
	"context"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyresetstore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	"gxb.local/backend/v2/internal/application/dailyreset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

// 04:59:59 and 05:00:00 GMT+8: the two sides of the canonical game-day boundary (modes.Day).
var (
	gameDayBefore = time.Date(2026, 12, 1, 20, 59, 59, 0, time.UTC)
	gameDayAfter  = time.Date(2026, 12, 1, 21, 0, 0, 0, time.UTC)
)

func dailyResetService(t *testing.T) (dailyreset.Service, *pg.Pool) {
	t.Helper()
	pool := broadcastPool(t)
	return dailyreset.Service{Markers: dailyresetstore.Store{Queryer: pool}, Counters: dailyreset.ZeroCounters{}}, pool
}

// markerPlayer clears any row left by an earlier run so the fixed instants stay reproducible.
func markerPlayer(t *testing.T, pool *pg.Pool, player identity.PlayerID) identity.PlayerID {
	t.Helper()
	broadcastExec(t, pool, `DELETE FROM player_daily_reset_marks WHERE player_id=$1`, int64(player))
	return player
}

func resetReply(t *testing.T, service dailyreset.Service, player identity.PlayerID, at time.Time, body map[string]any, status int) httpedge.Response {
	t.Helper()
	dispatcher := Decorated{DailyReset: service, Next: httpedge.DispatcherFunc(func(context.Context, httpedge.DispatchRequest) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: body}
	})}
	return dispatcher.Dispatch(resetContext(player), httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{ReceivedAt: at, MID: 1856}})
}

func carriedReset(response httpedge.Response) bool {
	economy, _ := response.Body["economy_"].(map[string]any)
	return economy["daily_updates"] == int64(1)
}

func TestDailyResetSignalAtTheGameDayBoundary(t *testing.T) {
	service, pool := dailyResetService(t)
	player := markerPlayer(t, pool, identity.PlayerID(99000001))
	if !carriedReset(resetReply(t, service, player, gameDayBefore, map[string]any{}, 200)) {
		t.Fatal("first reply of the day did not carry the reset signal")
	}
	if carriedReset(resetReply(t, service, player, gameDayBefore.Add(-time.Minute), map[string]any{}, 200)) {
		t.Fatal("second reply of the same game day carried the signal again")
	}
	across := resetReply(t, service, player, gameDayAfter, map[string]any{}, 200)
	if !carriedReset(across) {
		t.Fatal("first reply after 05:00 GMT+8 did not carry the reset signal")
	}
	if updates := dailyUpdates(t, across); len(updates) != 3 {
		t.Fatalf("updates %#v", updates)
	}
	if carriedReset(resetReply(t, service, player, gameDayAfter.Add(time.Minute), map[string]any{}, 200)) {
		t.Fatal("later reply of the new game day carried the signal again")
	}
}

func TestDailyResetSignalRefusalDoesNotConsumeTheDay(t *testing.T) {
	service, pool := dailyResetService(t)
	player := markerPlayer(t, pool, identity.PlayerID(99000002))
	refusal := resetReply(t, service, player, gameDayAfter, map[string]any{"error_code": int64(34008)}, 200)
	if _, present := refusal.Body["economy_"]; present {
		t.Fatal("refusal was decorated")
	}
	if !carriedReset(resetReply(t, service, player, gameDayAfter, map[string]any{}, 200)) {
		t.Fatal("a refusal consumed the day's signal")
	}
	if carriedReset(resetReply(t, service, player, gameDayAfter, map[string]any{}, 200)) {
		t.Fatal("the signal repeated after delivery")
	}
}

func TestDailyResetSignalIsDeliveredExactlyOnceUnderConcurrency(t *testing.T) {
	service, pool := dailyResetService(t)
	player := markerPlayer(t, pool, identity.PlayerID(99000003))
	if !carriedReset(resetReply(t, service, player, gameDayBefore, map[string]any{}, 200)) {
		t.Fatal("seed reply did not carry the reset signal")
	}
	var wait sync.WaitGroup
	delivered := make(chan bool, 2)
	for range 2 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			delivered <- carriedReset(resetReply(t, service, player, gameDayAfter, map[string]any{}, 200))
		}()
	}
	wait.Wait()
	close(delivered)
	count := 0
	for carried := range delivered {
		if carried {
			count++
		}
	}
	if count != 1 {
		t.Fatalf("concurrent replies carried the reset %d times, want exactly 1", count)
	}
}

func TestLoginMarksTheDaySoTheFirstReplyDoesNotRepeatTheSignal(t *testing.T) {
	pool := broadcastPool(t)
	service := dailyreset.Service{Markers: dailyresetstore.Store{Queryer: pool}, Counters: dailyreset.ZeroCounters{}}
	player := markerPlayer(t, pool, identity.PlayerID(99000004))
	login := BootstrapDispatcher{Bootstrap: fakeBootstrap{mid1: appboot.MID1Result{Token: "bearer", Region: 1, UID: identity.AccountUID("20000007"), Detail: map[string]any{}, Player: logicalserver.PlayerRoot{PlayerID: player}}}, DailyReset: service}
	request := env(1, nil, gameDayAfter)
	request.Envelope.Operation = operation.Context{StartedAt: gameDayAfter}
	request.Envelope.Params = map[string]any{"sid": "s", "login_token": "l", "region": int64(1)}
	if got := login.Dispatch(context.Background(), request); got.HTTPStatus != 200 {
		t.Fatalf("MID1 %d %#v", got.HTTPStatus, got.Body)
	}
	if carriedReset(resetReply(t, service, player, gameDayAfter.Add(time.Minute), map[string]any{}, 200)) {
		t.Fatal("a reply after login repeated the signal for a day login already served")
	}
	if !carriedReset(resetReply(t, service, player, gameDayAfter.Add(24*time.Hour), map[string]any{}, 200)) {
		t.Fatal("the next game day after login did not carry the signal")
	}
}
