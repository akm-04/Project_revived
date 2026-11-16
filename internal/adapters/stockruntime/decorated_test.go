package stockruntime

import (
	"context"
	"reflect"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/application/dailyreset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/observability"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"gxb.local/backend/v2/internal/protocol/wire"
)

func decorate(body map[string]any, status int) httpedge.Response {
	return Decorated{Next: httpedge.DispatcherFunc(func(ctx context.Context, _ httpedge.DispatchRequest) httpedge.Response {
		changes.Balance(ctx, "crystal", 90)
		changes.Balance(ctx, "mana", 7)
		changes.FunctionOpened(ctx, 12)
		changes.FunctionOpened(ctx, 3)
		return httpedge.Response{HTTPStatus: status, Body: body}
	})}.Dispatch(context.Background(), httpedge.DispatchRequest{})
}

func TestDecoratedMergesCommittedChanges(t *testing.T) {
	got := decorate(map[string]any{"economy_": map[string]int64{"mana": 5}, "new_funcs_": []int64{3, 40}}, 200).Body
	if !reflect.DeepEqual(got["economy_"], map[string]any{"crystal": int64(90), "mana": int64(5)}) {
		t.Fatalf("economy_ %v", got["economy_"])
	}
	if !reflect.DeepEqual(got["new_funcs_"], []int64{3, 12, 40}) {
		t.Fatalf("new_funcs_ %v", got["new_funcs_"])
	}
}

func TestDecoratedLeavesRefusalsAlone(t *testing.T) {
	for _, response := range []httpedge.Response{decorate(map[string]any{"error_code": 1}, 200), decorate(map[string]any{"error": "x"}, 503)} {
		if _, has := response.Body["economy_"]; has {
			t.Fatalf("decorated a refusal: %v", response.Body)
		}
	}
	if got := decorate(map[string]any{"error_code": 0}, 200).Body; got["economy_"] == nil {
		t.Fatal("error_code 0 is not a refusal")
	}
}

type memoryMarkers struct {
	mutex sync.Mutex
	days  map[identity.PlayerID]int64
}

func (m *memoryMarkers) Advance(_ context.Context, player identity.PlayerID, day int64) (bool, error) {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	if m.days == nil {
		m.days = map[identity.PlayerID]int64{}
	}
	if m.days[player] >= day {
		return false, nil
	}
	m.days[player] = day
	return true, nil
}

func (m *memoryMarkers) Set(_ context.Context, player identity.PlayerID, day int64) error {
	m.mutex.Lock()
	defer m.mutex.Unlock()
	if m.days == nil {
		m.days = map[identity.PlayerID]int64{}
	}
	m.days[player] = day
	return nil
}

func resetContext(player identity.PlayerID) context.Context {
	ctx, _ := observability.WithRequestNote(context.Background())
	observability.NoteActor(ctx, observability.RequestActor{PlayerID: int64(player)})
	return ctx
}

func dispatchReset(t *testing.T, markers *memoryMarkers, at time.Time, ctx context.Context, status int, body map[string]any) httpedge.Response {
	t.Helper()
	service := dailyreset.Service{Markers: markers, Counters: dailyreset.ZeroCounters{}}
	dispatcher := Decorated{DailyReset: service, Next: httpedge.DispatcherFunc(func(context.Context, httpedge.DispatchRequest) httpedge.Response {
		return httpedge.Response{HTTPStatus: status, Body: body}
	})}
	return dispatcher.Dispatch(ctx, httpedge.DispatchRequest{Envelope: wire.RequestEnvelope{ReceivedAt: at, MID: 1856}})
}

func dailyUpdates(t *testing.T, response httpedge.Response) map[string]any {
	t.Helper()
	economy, _ := response.Body["economy_"].(map[string]any)
	updates, _ := economy["updates"].(map[string]any)
	return updates
}

// The client dispatches ECONOMY only when economy_ exists (Backend.lua:716-740), so the decorator must create it.
func TestDecoratedAddsTheDailyResetSignalOncePerGameDay(t *testing.T) {
	markers := &memoryMarkers{}
	player := identity.PlayerID(1000001)
	at := time.Date(2026, 11, 11, 21, 0, 0, 0, time.UTC) // 05:00:00 GMT+8
	first := dispatchReset(t, markers, at, resetContext(player), 200, map[string]any{})
	if first.Body["economy_"].(map[string]any)["daily_updates"] != int64(1) {
		t.Fatalf("first reply economy_ %#v", first.Body["economy_"])
	}
	if got := dailyUpdates(t, first); !reflect.DeepEqual(got, map[string]any{"buy_mana_times": int64(0), "buy_energy_times": int64(0), "buy_skill_times": int64(0)}) {
		t.Fatalf("updates %#v", got)
	}
	second := dispatchReset(t, markers, at.Add(time.Minute), resetContext(player), 200, map[string]any{})
	if _, present := second.Body["economy_"]; present {
		t.Fatalf("second reply of the day carried a reset: %#v", second.Body)
	}
	next := dispatchReset(t, markers, at.Add(24*time.Hour), resetContext(player), 200, map[string]any{})
	if next.Body["economy_"].(map[string]any)["daily_updates"] != int64(1) {
		t.Fatalf("next game day economy_ %#v", next.Body["economy_"])
	}
}

func TestDecoratedResetKeepsAWrittenEconomyAndFollowsTheRefusalGate(t *testing.T) {
	markers := &memoryMarkers{}
	player := identity.PlayerID(1000002)
	at := time.Date(2026, 11, 11, 21, 0, 0, 0, time.UTC)
	for _, untouched := range []httpedge.Response{
		dispatchReset(t, markers, at, resetContext(player), 200, map[string]any{"error_code": int64(1)}),
		dispatchReset(t, markers, at, resetContext(player), 503, map[string]any{"error": "down"}),
	} {
		if _, present := untouched.Body["economy_"]; present {
			t.Fatalf("refusal or failure was decorated: %#v", untouched.Body)
		}
	}
	merged := dispatchReset(t, markers, at, resetContext(player), 200, map[string]any{"economy_": map[string]int64{"mana": 7}})
	economy := merged.Body["economy_"].(map[string]any)
	if economy["mana"] != int64(7) || economy["daily_updates"] != int64(1) {
		t.Fatalf("merged economy_ %#v", economy)
	}
}

// MF5: keys the dispatcher wrote itself win over the decorator's reset additions.
func TestDecoratedDailyResetKeepsDispatcherWrittenKeys(t *testing.T) {
	markers := &memoryMarkers{}
	player := identity.PlayerID(1000003)
	at := time.Date(2026, 11, 11, 21, 0, 0, 0, time.UTC)
	response := dispatchReset(t, markers, at, resetContext(player), 200, map[string]any{"economy_": map[string]any{"daily_updates": int64(5), "updates": map[string]any{"custom": int64(1)}}})
	economy := response.Body["economy_"].(map[string]any)
	if economy["daily_updates"] != int64(5) || economy["updates"].(map[string]any)["custom"] != int64(1) {
		t.Fatalf("dispatcher-written reset keys were overwritten: %#v", economy)
	}
}
