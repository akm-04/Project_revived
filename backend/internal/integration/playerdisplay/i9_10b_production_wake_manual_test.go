//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
)

const productionWakeGiftID = int64(50005011)

var productionWakeGifts = []int64{productionWakeGiftID, 50005017}

const productionWakeGiftStack = int64(600)

// This is a manual probe, never an ordinary CI test: the source Adventure
// 10002 trigger is 1%, so an ordinary test would be flaky. It is enabled only
// with GXB_I9_10B_PRODUCTION_WAKE_PROBE=1 and a clean candidate API binary.
func TestI9_10BProductionWakeManualProbe(t *testing.T) {
	if os.Getenv("GXB_I9_10B_PRODUCTION_WAKE_PROBE") != "1" {
		t.Skip("manual production wake probe disabled")
	}
	p := pool(t)
	revision := installed(t, p)
	actor := bornActor(t, p)
	const partners = int64(7)
	partnerTables := []int64{10001001, 10001002, 10001003, 10001004, 10001005, 10001006, 10001007}
	for index, table := range partnerTables {
		bornHero(t, p, actor, revision, table, int64(index)+1)
	}
	for _, gift := range productionWakeGifts {
		seedStack(t, p, actor, revision, gift, productionWakeGiftStack)
	}
	api := startI9Process(t, p, actor)

	listener, e := p.Raw().Acquire(ctx)
	if e != nil {
		t.Fatal(e)
	}
	t.Cleanup(listener.Release)
	if _, e = listener.Exec(ctx, `LISTEN `+pg.RealtimeWakeupChannel); e != nil {
		t.Fatal(e)
	}
	listenCtx, cancelListen := context.WithCancel(ctx)
	t.Cleanup(cancelListen)
	wakePayloads := make(chan string, 1)
	wakeDone := make(chan struct{})
	go func() {
		defer close(wakeDone)
		notification, err := listener.Conn().WaitForNotification(listenCtx)
		if err != nil || notification.Channel != pg.RealtimeWakeupChannel {
			return
		}
		wakePayloads <- notification.Payload
	}()

	const maxCommands = 1000
	favor := make(map[int64]int64, partners)
	commands := 0
	payload := ""
	for commands < maxCommands && payload == "" {
		partner := int64(commands)%partners + 1
		gift := productionWakeGifts[int64(commands)/productionWakeGiftStack]
		code, body := api.post(840, map[string]any{"partner_id": partner, "gift_id": gift, "gift_num": int64(1)})
		commands++
		if code != 200 {
			t.Fatalf("command %d partner %d status %d body %+v", commands, partner, code, body)
		}
		got := i9Number(t, body["favor_degree"])
		if got <= favor[partner] {
			t.Fatalf("command %d partner %d favor %d did not rise from %d (fixture must stay below the cap)", commands, partner, got, favor[partner])
		}
		favor[partner] = got
		select {
		case payload = <-wakePayloads:
		case <-time.After(30 * time.Millisecond):
		}
	}
	t.Logf("PROBE_COMMANDS=%d", commands)
	if payload == "" {
		t.Fatalf("NOT_OBSERVED: no Adventure 10002 wake within %d valid favor-changing commands", commands)
	}
	cancelListen()
	<-wakeDone

	envelope, e := appwakeup.Decode([]byte(payload))
	if e != nil || envelope.Validate() != nil {
		t.Fatalf("wake envelope %q decode %v", payload, e)
	}
	if envelope.Version != appwakeup.EnvelopeVersion || envelope.Route != appadventure.NoticeRoute || envelope.Ref != strconv.FormatInt(int64(actor.PlayerID), 10) {
		t.Fatalf("wake envelope %+v want version %d route %q ref %d", envelope, appwakeup.EnvelopeVersion, appadventure.NoticeRoute, actor.PlayerID)
	}
	t.Logf("WAKE version=%d route=%q ref=%q commands=%d", envelope.Version, envelope.Route, envelope.Ref, commands)

	var occurredAt, endTime time.Time
	var sourceKey string
	var finished *time.Time
	row := p.Raw().QueryRow(ctx, `SELECT occurred_at,end_time,source_key,finished_at FROM adventure_occurrences WHERE player_id=$1 AND event_type=10002`, int64(actor.PlayerID))
	if e = row.Scan(&occurredAt, &endTime, &sourceKey, &finished); e != nil {
		t.Fatalf("persisted occurrence %v", e)
	}
	if finished != nil || sourceKey == "" || !endTime.Equal(occurredAt.Add(time.Hour)) {
		t.Fatalf("occurrence occurred=%v end=%v source=%q finished=%v", occurredAt, endTime, sourceKey, finished)
	}
	t.Logf("OCCURRENCE event=10002 source=%q end_occurred=%s finished=%v", sourceKey, endTime.Sub(occurredAt), finished != nil)

	// Observation only, not deterministic guard proof: in this one run a second
	// successful favor fact produced no duplicate wake while the first
	// occurrence was active. The observer unit covers suppression deterministically.
	factsBefore := i9IntimacyFacts(t, p, actor)
	partner := int64(commands)%partners + 1
	gift := productionWakeGifts[int64(commands)/productionWakeGiftStack]
	code, body := api.post(840, map[string]any{"partner_id": partner, "gift_id": gift, "gift_num": int64(1)})
	if code != 200 || i9Number(t, body["favor_degree"]) <= favor[partner] {
		t.Fatalf("suppression command status %d body %+v", code, body)
	}
	if factsAfter := i9IntimacyFacts(t, p, actor); factsAfter != factsBefore+1 {
		t.Fatalf("suppression favor fact count %d want %d", factsAfter, factsBefore+1)
	}
	duplicateCtx, cancelDuplicate := context.WithTimeout(ctx, 500*time.Millisecond)
	duplicate, duplicateErr := listener.Conn().WaitForNotification(duplicateCtx)
	cancelDuplicate()
	if duplicateErr == nil {
		t.Fatalf("duplicate wake while occurrence active: %q", duplicate.Payload)
	}
	if !errors.Is(duplicateErr, context.DeadlineExceeded) {
		t.Fatalf("duplicate wake wait %v", duplicateErr)
	}
	var occurrences int64
	if e = p.Raw().QueryRow(ctx, `SELECT count(*) FROM adventure_occurrences WHERE player_id=$1 AND event_type=10002`, int64(actor.PlayerID)).Scan(&occurrences); e != nil || occurrences != 1 {
		t.Fatalf("occurrence count %d err %v want 1", occurrences, e)
	}
	t.Logf("SUPPRESSION_OBSERVED fact=%d occurrences=%d duplicate_wake=false", factsBefore+1, occurrences)

	api.stop()
	assertI9Journal(t, p, actor, []int{840})
}
