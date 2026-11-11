//go:build postgres

package playerdisplay_test

import (
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/domain/character"
	course "gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

func concurrentLibraryCommands(t *testing.T, actor identity.ActorContext, service stockruntime.LibraryPort, mid uint16, requests []map[string]any) []httpedge.Response {
	t.Helper()
	responses := make([]httpedge.Response, len(requests))
	start := make(chan struct{})
	var wait sync.WaitGroup
	wait.Add(len(requests))
	for index := range requests {
		go func(index int) {
			defer wait.Done()
			<-start
			responses[index] = libraryDispatchService(t, actor, service, mid, requests[index], op())
		}(index)
	}
	close(start)
	wait.Wait()
	return responses
}

func concurrentCourseCommands(t *testing.T, actor identity.ActorContext, service stockruntime.CoursePort, mid uint16, requests []map[string]any) []httpedge.Response {
	t.Helper()
	responses := make([]httpedge.Response, len(requests))
	start := make(chan struct{})
	var wait sync.WaitGroup
	wait.Add(len(requests))
	for index := range requests {
		go func(index int) {
			defer wait.Done()
			<-start
			responses[index] = courseDispatch(t, actor, service, mid, requests[index], op())
		}(index)
	}
	close(start)
	wait.Wait()
	return responses
}

func statusCounts(responses []httpedge.Response) (successes, refusals int) {
	for _, response := range responses {
		switch response.HTTPStatus {
		case 200:
			successes++
		case 409:
			refusals++
		}
	}
	return successes, refusals
}

func stackQuantityOrZero(t *testing.T, p *pg.Pool, player identity.PlayerID, itemID int64) int64 {
	t.Helper()
	var quantity int64
	if e := p.QueryRow(ctx, `SELECT COALESCE(max(quantity),0) FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(player), itemID).Scan(&quantity); e != nil {
		t.Fatal(e)
	}
	return quantity
}

func libraryHeroFavor(t *testing.T, p *pg.Pool, player identity.PlayerID, partner int64) int64 {
	t.Helper()
	facts, e := (librarystore.Store{}).ReadHeroTx(ctx, p, character.HeroRef{PlayerID: player, PartnerID: partner})
	if e != nil {
		t.Fatal(e)
	}
	return facts.Favor
}

func TestI9_10B839ConcurrentBuyersDebitOnce(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	service := libraryP5Service(p)
	const giftID = int64(50005011)
	const giftPrice = int64(50)
	exec(t, p, `UPDATE player_currency_balances SET amount=$2 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID), giftPrice)

	requests := []map[string]any{
		{"gift_id": giftID, "gift_num": int64(1)},
		{"gift_id": giftID, "gift_num": int64(1)},
	}
	responses := concurrentLibraryCommands(t, a, service, 839, requests)
	successes, refusals := statusCounts(responses)
	if successes != 1 || refusals != 1 {
		t.Fatalf("concurrent buyers successes=%d refusals=%d responses=%+v", successes, refusals, responses)
	}
	if got := p5CrystalBalance(t, p, a.PlayerID); got != 0 {
		t.Fatalf("crystal %d after one purchase", got)
	}
	if got := p5StackQuantity(t, p, a.PlayerID, giftID); got != 1 {
		t.Fatalf("owned gift %d after one purchase", got)
	}
}

func TestI9_10B840BusinessRefusalsSpendNothing(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	setLibraryFavor(t, p, a, 1, 100)
	service := libraryP5Service(p)
	spendNothing := func(label string) {
		t.Helper()
		if got := libraryHeroFavor(t, p, a.PlayerID, 1); got != 100 {
			t.Fatalf("%s changed favor to %d", label, got)
		}
		if got := p5CrystalBalance(t, p, a.PlayerID); got != 1000 {
			t.Fatalf("%s changed crystal to %d", label, got)
		}
	}

	invalid := libraryDispatchService(t, a, service, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50009999), "gift_num": int64(1)}, op())
	if invalid.HTTPStatus != 409 || invalid.Body["error_code"] != int64(35028) {
		t.Fatalf("invalid gift status %d body %+v", invalid.HTTPStatus, invalid.Body)
	}
	spendNothing("invalid gift")

	seedStack(t, p, a, rev, 50001112, 1)
	marriageGate := libraryDispatchService(t, a, service, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50001112), "gift_num": int64(1)}, op())
	if marriageGate.HTTPStatus != 409 || marriageGate.Body["error_code"] != int64(35028) {
		t.Fatalf("marriage gate status %d body %+v", marriageGate.HTTPStatus, marriageGate.Body)
	}
	if got := p5StackQuantity(t, p, a.PlayerID, 50001112); got != 1 {
		t.Fatalf("marriage gate debited ring to %d", got)
	}
	spendNothing("marriage gate")

	missingGift := libraryDispatchService(t, a, service, 840, map[string]any{"partner_id": int64(1), "gift_id": int64(50005011), "gift_num": int64(1)}, op())
	if missingGift.HTTPStatus != 409 || missingGift.Body["error_code"] != int64(35028) {
		t.Fatalf("missing gift stack status %d body %+v", missingGift.HTTPStatus, missingGift.Body)
	}
	if got := stackQuantityOrZero(t, p, a.PlayerID, 50005011); got != 0 {
		t.Fatalf("missing gift stack became %d", got)
	}
	spendNothing("missing gift stack")
}

func TestI9_10B840ConcurrentGiftStack(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	setLibraryFavor(t, p, a, 1, 100)
	service := libraryP5Service(p)
	const giftID = int64(50005011)
	seedStack(t, p, a, rev, giftID, 1)

	requests := []map[string]any{
		{"partner_id": int64(1), "gift_id": giftID, "gift_num": int64(1)},
		{"partner_id": int64(1), "gift_id": giftID, "gift_num": int64(1)},
	}
	responses := concurrentLibraryCommands(t, a, service, 840, requests)
	successes, refusals := statusCounts(responses)
	if successes != 1 || refusals != 1 {
		t.Fatalf("concurrent gifts successes=%d refusals=%d responses=%+v", successes, refusals, responses)
	}
	if got := stackQuantityOrZero(t, p, a.PlayerID, giftID); got != 0 {
		t.Fatalf("gift stack %d after one debit", got)
	}
	if got := libraryHeroFavor(t, p, a.PlayerID, 1); got != 113 {
		t.Fatalf("favor %d after one gift", got)
	}
}

func TestI9_10B856ConcurrentUnlockDebitsOnce(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	service := libraryP5Service(p)
	seedStack(t, p, a, rev, lib.BackgroundUnlockItemID, 1)

	requests := []map[string]any{{"bg_id": int64(3)}, {"bg_id": int64(3)}}
	responses := concurrentLibraryCommands(t, a, service, 856, requests)
	successes, refusals := statusCounts(responses)
	if successes != 1 || refusals != 1 {
		t.Fatalf("concurrent unlocks successes=%d refusals=%d responses=%+v", successes, refusals, responses)
	}
	if got := stackQuantityOrZero(t, p, a.PlayerID, lib.BackgroundUnlockItemID); got != 0 {
		t.Fatalf("unlock item %d after one unlock", got)
	}
	backgrounds, e := (librarystore.Store{}).ListBackgroundsTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	owned := 0
	for _, fact := range backgrounds {
		if fact.BgID == 3 {
			owned++
		}
	}
	if owned != 1 {
		t.Fatalf("background 3 ownership rows %d", owned)
	}
}

func TestI9_10B2141ConcurrentGiftBoxClaim(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := bornActor(t, p)
	service := courseService(p, p)

	requests := []map[string]any{
		{"item_id": course.DailyGiftBoxItemID},
		{"item_id": course.DailyGiftBoxItemID},
	}
	responses := concurrentCourseCommands(t, a, service, 2141, requests)
	successes, refusals := statusCounts(responses)
	if successes != 1 || refusals != 1 {
		t.Fatalf("concurrent gift box successes=%d refusals=%d responses=%+v", successes, refusals, responses)
	}
	root, e := (coursestore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	if root.GiftBoxDay != modes.Day(time.Now().UTC()) {
		t.Fatalf("gift box day %d want %d", root.GiftBoxDay, modes.Day(time.Now().UTC()))
	}
	granted := int64(0)
	for _, itemID := range []int64{50001420, 50001421, 50001422} {
		granted += courseGiftBoxStackCount(t, p, a.PlayerID, itemID)
	}
	if granted != 1 {
		t.Fatalf("daily gift box awards granted %d want 1", granted)
	}
	if body, e := service.Read(ctx, a, 2139, op()); e != nil || body["is_has_gift"] != int64(0) {
		t.Fatalf("2139 after claim body %+v error %v", body, e)
	}
}
