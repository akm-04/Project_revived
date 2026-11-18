//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	ach "gxb.local/backend/v2/internal/application/achievement"
	d "gxb.local/backend/v2/internal/domain/achievement"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
)

func greatCustomerRow(t *testing.T, s ach.Service, a identity.ActorContext) (int64, [3]int64) {
	t.Helper()
	response := (stockruntime.AchievementDispatcher{Authority: playtestAuthority{a}, Service: s}).Dispatch(ctx, playtestRequest(a, 1302, map[string]any{}))
	if response.HTTPStatus != 200 {
		t.Fatalf("1302 HTTP %d %#v", response.HTTPStatus, response.Body)
	}
	rows, ok := response.Body["achieve_list"].([]map[string]any)
	if !ok {
		t.Fatalf("achieve_list type %T", response.Body["achieve_list"])
	}
	for _, row := range rows {
		if row["achieve_id"] != d.GreatCustomerID {
			continue
		}
		progress, ok := row["progress"].(int64)
		if !ok {
			t.Fatalf("progress type %T", row["progress"])
		}
		times, ok := row["complete_time"].([]int64)
		if !ok || len(times) != 3 {
			t.Fatalf("complete_time type %T", row["complete_time"])
		}
		return progress, [3]int64{times[0], times[1], times[2]}
	}
	t.Fatalf("100011 missing from 1302")
	return 0, [3]int64{}
}

func greatCustomerDaily(t *testing.T, p *pg.Pool, a identity.ActorContext) (int64, int64) {
	t.Helper()
	var count, day int64
	if e := p.QueryRow(ctx, `SELECT count,day-DATE '1970-01-01' FROM achievement_daily_counts WHERE player_id=$1 AND achievement_id=$2`, int64(a.PlayerID), d.GreatCustomerID).Scan(&count, &day); e != nil {
		t.Fatal(e)
	}
	return count, day
}

func greatCustomerStreak(t *testing.T, p *pg.Pool, a identity.ActorContext) (int64, time.Time) {
	t.Helper()
	var current int64
	var updated time.Time
	if e := p.QueryRow(ctx, `SELECT current,updated_at FROM achievement_streaks WHERE player_id=$1 AND achievement_id=$2`, int64(a.PlayerID), d.GreatCustomerID).Scan(&current, &updated); e != nil {
		t.Fatal(e)
	}
	return current, updated
}

// TestI9_11E_GreatCustomerThroughTheShopDispatcher drives MIDs 33/34/2982
// through the production shop composition: one accepted request counts once,
// a 3-slot multi-buy counts once, a refresh, refusal and receipt replay count
// nothing, ten buys earn tier 1 once, and the 05:00 GMT+8 roll lowers the view
// to 0 without writing while the earned tier stays.
func TestI9_11E_GreatCustomerThroughTheShopDispatcher(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	a := i911cPlayer(t, p, revision)
	at := time.Now().UTC().Add(time.Hour).Truncate(time.Second)
	clock := &i911cFixedClock{at: at}
	i911cScalar(t, p, a, "mana", 1_000_000)
	i911cScalar(t, p, a, "crystal", 1_000_000)
	dispatcher := i911cCompositionAt(p, a, clock).Dispatcher
	achievements := catalogAchievements(p, fixedCounts{})
	achievements.Runtime.Timed.Binder.Time = clock
	progress := func() int64 {
		t.Helper()
		value, _ := greatCustomerRow(t, achievements, a)
		return value
	}

	if _, e := achievements.Load(ctx, a, op()); e != nil {
		t.Fatalf("1302 load: %v", e)
	}
	if got := progress(); got != 0 {
		t.Fatalf("100011 starts at %d", got)
	}
	items := i911cLoad(t, dispatcher, a, 1, at, 1)

	first := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": items[0]["index"]}, at, 2)
	if first.HTTPStatus != 200 || progress() != 1 {
		t.Fatalf("one accepted buy: HTTP %d count %d", first.HTTPStatus, progress())
	}
	refused := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": items[0]["index"]}, at, 3)
	if refused.HTTPStatus != 409 || refused.Body["error_code"] != int64(35028) || progress() != 1 {
		t.Fatalf("refused buy counted: %+v count %d", refused, progress())
	}

	replayRequest := playtestRequest(a, 33, map[string]any{"shop_type": int64(1), "index": items[1]["index"]})
	replayRequest.Envelope.Operation = i911cFixedOperation(at, 4)
	if accepted := dispatcher.Dispatch(ctx, replayRequest); accepted.HTTPStatus != 200 {
		t.Fatalf("replayed-buy first send: %+v", accepted)
	}
	if replayed := dispatcher.Dispatch(ctx, replayRequest); replayed.HTTPStatus != 200 || progress() != 2 {
		t.Fatalf("receipt replay counted: HTTP %d count %d", replayed.HTTPStatus, progress())
	}

	multi := i911cDispatchAt(t, dispatcher, a, 2982, map[string]any{"shop_type": int64(1), "list": []any{items[2]["index"], items[3]["index"], items[4]["index"]}, "client_prices": map[string]any{}, "nums": map[string]any{}}, at, 5)
	if multi.HTTPStatus != 200 || progress() != 3 {
		t.Fatalf("3-slot multi-buy: HTTP %d count %d", multi.HTTPStatus, progress())
	}

	refresh := i911cDispatchAt(t, dispatcher, a, 34, map[string]any{"shop_type": int64(1)}, at, 6)
	if refresh.HTTPStatus != 200 || progress() != 3 {
		t.Fatalf("refresh counted: HTTP %d count %d", refresh.HTTPStatus, progress())
	}
	bought := 0
	for _, item := range i911cItems(t, refresh) {
		if bought == 7 {
			break
		}
		response := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": item["index"]}, at, byte(10+bought))
		if response.HTTPStatus != 200 {
			t.Fatalf("buy %d after refresh: %+v", bought, response)
		}
		bought++
	}
	value, complete := greatCustomerRow(t, achievements, a)
	if value != 10 || complete[0] == 0 || complete[1] != 0 {
		t.Fatalf("ten buys: progress %d tiers %v", value, complete)
	}
	tierOne := complete[0]
	notices, err := achievements.TakeNotices(ctx, a.PlayerID, opPinned(revision))
	if err != nil || len(notices) != 1 || notices[0].AchievementID != d.GreatCustomerID || notices[0].CompleteTimes[0] == 0 {
		t.Fatalf("notice after tier 1: %+v %v", notices, err)
	}
	if again, err := achievements.TakeNotices(ctx, a.PlayerID, opPinned(revision)); err != nil || len(again) != 0 {
		t.Fatalf("tier 1 pushed twice: %+v %v", again, err)
	}

	countBefore, dayBefore := greatCustomerDaily(t, p, a)
	currentBefore, updatedBefore := greatCustomerStreak(t, p, a)
	next := modes.DayBegins(modes.Day(at) + 1)
	clock.Set(next)
	value, complete = greatCustomerRow(t, achievements, a)
	if value != 0 || complete[0] != tierOne {
		t.Fatalf("after the roll: progress %d tiers %v", value, complete)
	}
	if countAfter, dayAfter := greatCustomerDaily(t, p, a); countAfter != countBefore || dayAfter != dayBefore {
		t.Fatalf("the read wrote the counter: %d/%d -> %d/%d", countBefore, dayBefore, countAfter, dayAfter)
	}
	if currentAfter, updatedAfter := greatCustomerStreak(t, p, a); currentAfter != currentBefore || !updatedAfter.Equal(updatedBefore) {
		t.Fatalf("the read wrote the streak: %d/%v -> %d/%v", currentBefore, updatedBefore, currentAfter, updatedAfter)
	}

	items = i911cLoad(t, dispatcher, a, 1, next, 20)
	buy := i911cDispatchAt(t, dispatcher, a, 33, map[string]any{"shop_type": int64(1), "index": items[0]["index"]}, next, 21)
	value, complete = greatCustomerRow(t, achievements, a)
	if buy.HTTPStatus != 200 || value != 1 || complete[0] != tierOne {
		t.Fatalf("first buy of the next day: HTTP %d progress %d tiers %v", buy.HTTPStatus, value, complete)
	}
}
