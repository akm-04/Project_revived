//go:build postgres

package playerdisplay_test

import (
	"errors"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	cp "gxb.local/backend/v2/internal/application/commerceprivilege"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func chargeService(p *pg.Pool) cp.Charge {
	i5svc := compositeI5(p)
	return cp.Charge{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		Fresh:       p,
		Fence:       i5store.Store{Queryer: p},
		Facts:       i5.ObjectiveFacts{Owner: i5svc, Open: i5store.Store{Queryer: p}},
		Store:       ps.Store{},
		Content:     contentstore.Store{Queryer: p},
		Grants:      i5svc,
		Effects:     i5.PrivilegeTransitionOwner{Store: i5store.Store{}, Content: contentstore.Store{Queryer: p}},
		Directory:   i4store.DirectoryLevelProjection{},
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: p},
	}
}

func chargeTap(t *testing.T, p *pg.Pool, rev string, a identity.ActorContext, chargeID int64, intent string) map[string]any {
	t.Helper()
	body, e := chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: chargeID, IntentID: intent}, opPinned(rev))
	if e != nil {
		t.Fatal("tap", chargeID, intent, e)
	}
	return body
}

func segment(t *testing.T, body map[string]any) map[string]any {
	t.Helper()
	event, ok := body["recharge_event"].(map[string]any)
	if !ok {
		t.Fatalf("recharge_event missing: %#v", body)
	}
	params, ok := event["params"].(map[string]any)
	if !ok || number(t, event["mid"]) != 36857 {
		t.Fatalf("recharge params: %#v", event)
	}
	return params
}

func number(t *testing.T, value any) int64 {
	t.Helper()
	switch typed := value.(type) {
	case int64:
		return typed
	case int:
		return int64(typed)
	case float64:
		return int64(typed)
	default:
		t.Fatalf("not a number: %#v", value)
		return 0
	}
}

func awardRows(t *testing.T, value any) []map[string]any {
	t.Helper()
	switch typed := value.(type) {
	case []map[string]any:
		return typed
	case []any:
		out := make([]map[string]any, 0, len(typed))
		for _, row := range typed {
			out = append(out, row.(map[string]any))
		}
		return out
	default:
		t.Fatalf("not an award array: %#v", value)
		return nil
	}
}

func crystalBalance(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	var amount int64
	if e := p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); e != nil {
		t.Fatal(e)
	}
	return amount
}

func chargeStackQuantity(t *testing.T, p *pg.Pool, a identity.ActorContext, item int64) int64 {
	t.Helper()
	var quantity int64
	if e := p.QueryRow(ctx, `SELECT COALESCE(quantity,0) FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), item).Scan(&quantity); e != nil {
		t.Fatal(e)
	}
	return quantity
}

func TestI910GChargeFirstBuyBonusSecondWithoutAndReplay(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	start := crystalBalance(t, p, a)
	firstIntent := uuid().String()
	first := segment(t, chargeTap(t, p, rev, a, 80001002, firstIntent))
	if number(t, first["delta"]) != 20000 || number(t, first["total"]) != start+20000 || number(t, first["vip"]) != 7 {
		t.Fatalf("first buy params: %#v", first)
	}
	again, e := chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001002, IntentID: firstIntent}, opPinned(rev))
	if e != nil || number(t, segment(t, again)["delta"]) != 20000 || crystalBalance(t, p, a) != start+20000 {
		t.Fatalf("replay: %#v %v balance=%d", again, e, crystalBalance(t, p, a))
	}
	second := segment(t, chargeTap(t, p, rev, a, 80001002, uuid().String()))
	if number(t, second["delta"]) != 10000 {
		t.Fatalf("second buy lost-first-bonus drift: %#v", second)
	}
	root, ok, e := (ps.Store{}).ReadPrivilegeTx(ctx, p, a.PlayerID, false)
	if e != nil || !ok || root.Charge != 20000 || root.PolicyVersion != d.TapPolicy {
		t.Fatalf("root after buys: %+v %v", root, e)
	}
	if crystalBalance(t, p, a) != start+30000 {
		t.Fatalf("balance=%d", crystalBalance(t, p, a))
	}
}

func TestI910GChargeConflictingReplayAndNoRewardProduct(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	intent := uuid().String()
	chargeTap(t, p, rev, a, 80001007, intent)
	if _, e := chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001006, IntentID: intent}, opPinned(rev)); e == nil {
		t.Fatal("conflicting intent admitted")
	} else {
		var conflict *receipt.ConflictError
		if !errors.As(e, &conflict) {
			t.Fatalf("conflict type: %v", e)
		}
	}
	if _, e := chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001028, IntentID: uuid().String()}, opPinned(rev)); !errors.Is(e, d.ErrChargeRefused) {
		t.Fatalf("028 refusal: %v", e)
	}
	if _, e := chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001029, IntentID: uuid().String()}, opPinned(rev)); !errors.Is(e, d.ErrChargeRefused) {
		t.Fatalf("029 refusal: %v", e)
	}
	var count int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM commerce_charge_purchases WHERE player_id=$1`, int64(a.PlayerID)).Scan(&count); e != nil || count != 1 {
		t.Fatalf("purchase rows=%d %v", count, e)
	}
}

func TestI910GChargeCardsStackAndBootstrap(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	chargeTap(t, p, rev, a, 80001001, uuid().String())
	chargeTap(t, p, rev, a, 80001001, uuid().String())
	chargeTap(t, p, rev, a, 80001010, uuid().String())
	cards, e := (ps.Store{}).ReadCardsTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	if d.LeftDays(cards.MonthCardEnd, time.Now().UTC().Unix()) != 60 || d.LeftDays(cards.PrivilegeCardEnd, time.Now().UTC().Unix()) != 30 {
		t.Fatalf("cards=%+v", cards)
	}
	body := chargeTap(t, p, rev, a, 80001007, uuid().String())
	now := time.Now().UTC()
	if body["economy_"] == nil {
		t.Fatal("economy_ missing")
	}
	detail := map[string]any{"17": map[string]any{}}
	if e = (cp.BootstrapProjection{Provider: privilegeProvider(p)}).OverlayMID1(ctx, p, a, false, now, detail); e != nil {
		t.Fatal(e)
	}
	out := detail["17"].(map[string]any)
	if out["month_card_start"].(int64) == 0 || out["left_card_day"].(int64) != 60 || out["privilege_left_card_day"].(int64) != 30 || out["left_week_card_day"].(int64) != 0 || out["left_month_tili_day"].(int64) != 0 {
		t.Fatalf("bootstrap cards: %#v", out)
	}
	awards, ok := out["vip_awards"].([]int64)
	if !ok || len(awards) != 15 {
		t.Fatalf("vip_awards: %#v", out["vip_awards"])
	}
	for _, granted := range awards {
		if granted != 0 {
			t.Fatalf("unclaimed bootstrap award=%d", granted)
		}
	}
	if out["vip"].(int64) != 2 || out["charge"].(int64) != 600 {
		t.Fatalf("bootstrap privilege: %#v", out)
	}
}

func TestI910GChargeTuningDisabled(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	exec(t, p, `INSERT INTO commerce_recharge_tuning(singleton,payload,updated_at)VALUES(true,$1::jsonb,clock_timestamp()) ON CONFLICT(singleton)DO UPDATE SET payload=excluded.payload,updated_at=excluded.updated_at`, `{"version":1,"mode":"DISABLED","products":{}}`)
	t.Cleanup(func() { exec(t, p, `DELETE FROM commerce_recharge_tuning`) })
	if _, e := chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001007, IntentID: uuid().String()}, opPinned(rev)); !errors.Is(e, d.ErrChargeRefused) {
		t.Fatalf("disabled tuning: %v", e)
	}
	var count int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM commerce_charge_purchases WHERE player_id=$1`, int64(a.PlayerID)).Scan(&count); e != nil || count != 0 {
		t.Fatalf("disabled wrote a purchase: %d %v", count, e)
	}
}

func TestI910GChargeConcurrentIntentsSum(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	intents := []string{uuid().String(), uuid().String(), uuid().String()}
	var wg sync.WaitGroup
	errs := make(chan error, len(intents))
	for _, intent := range intents {
		wg.Add(1)
		go func(intent string) {
			defer wg.Done()
			_, e := chargeService(p).Tap(ctx, a, cp.TapRequest{ChargeID: 80001007, IntentID: intent}, opPinned(rev))
			errs <- e
		}(intent)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	root, ok, e := (ps.Store{}).ReadPrivilegeTx(ctx, p, a.PlayerID, false)
	if e != nil || !ok || root.Charge != 300 {
		t.Fatalf("concurrent root: %+v %v", root, e)
	}
	if _, e = (ps.Store{}).ReadPurchaseCountTx(ctx, p, a.PlayerID, 80001007); e != nil {
		t.Fatal(e)
	}
	purchases, e := (ps.Store{}).ReadPurchasesTx(ctx, p, a.PlayerID)
	if e != nil || len(purchases) != 1 || purchases[0].ChargeCount != 3 {
		t.Fatalf("purchases: %+v %v", purchases, e)
	}
}

func TestI910GChargeManualOriginRoundTrip(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	manualFirst := bornActor(t, p)
	if _, e := privilegeService(p, p).ImportManual(ctx, authority(), importQ(manualFirst, uuid().String(), 3000), op()); e != nil {
		t.Fatal(e)
	}
	chargeTap(t, p, rev, manualFirst, 80001007, uuid().String())
	root, _, e := (ps.Store{}).ReadPrivilegeTx(ctx, p, manualFirst.PlayerID, false)
	if e != nil || root.PolicyVersion != d.TapPolicy || root.OriginClass != d.TapClass {
		t.Fatalf("tap on manual root: %+v %v", root, e)
	}
	tapFirst := bornActor(t, p)
	chargeTap(t, p, rev, tapFirst, 80001007, uuid().String())
	if _, e = privilegeService(p, p).ImportManual(ctx, authority(), importQ(tapFirst, uuid().String(), 5000), op()); e != nil {
		t.Fatal(e)
	}
	root, _, e = (ps.Store{}).ReadPrivilegeTx(ctx, p, tapFirst.PlayerID, false)
	if e != nil || root.PolicyVersion != d.ManualPolicy || root.OriginClass != d.ManualClass || root.Charge != 5000 {
		t.Fatalf("manual import on tap root: %+v %v", root, e)
	}
}

func TestI910GVIPAwardClaimOnceAndBootstrapFlags(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	chargeTap(t, p, rev, a, 80001007, uuid().String())
	start := crystalBalance(t, p, a)
	body, e := chargeService(p).ClaimVIPAward(ctx, a, 1, opPinned(rev))
	if e != nil {
		t.Fatal(e)
	}
	awards := awardRows(t, body["awards"])
	if len(awards) != 4 {
		t.Fatalf("awards: %#v", body)
	}
	if number(t, awards[0]["table_id"]) != 50001009 || number(t, awards[0]["item_num"]) != 6 {
		t.Fatalf("first item: %#v", awards[0])
	}
	if number(t, awards[3]["table_id"]) != -1 || number(t, awards[3]["item_num"]) != 5 || number(t, awards[3]["crystal"]) != 5 {
		t.Fatalf("crystal award: %#v", awards[3])
	}
	if crystalBalance(t, p, a) != start+5 || chargeStackQuantity(t, p, a, 50001009) != 6 {
		t.Fatalf("grant missing: crystal=%d item=%d", crystalBalance(t, p, a), chargeStackQuantity(t, p, a, 50001009))
	}
	replay, e := chargeService(p).ClaimVIPAward(ctx, a, 1, opPinned(rev))
	if e != nil || len(awardRows(t, replay["awards"])) != 4 || crystalBalance(t, p, a) != start+5 {
		t.Fatalf("claim replay: %#v %v balance=%d", replay, e, crystalBalance(t, p, a))
	}
	if _, e = chargeService(p).ClaimVIPAward(ctx, a, 2, opPinned(rev)); !errors.Is(e, d.ErrChargeRefused) {
		t.Fatalf("level above VIP admitted: %v", e)
	}
	claimed, e := (ps.Store{}).ReadVIPClaimedTx(ctx, p, a.PlayerID)
	if e != nil || len(claimed) != 1 || claimed[0] != 1 {
		t.Fatalf("claimed=%v %v", claimed, e)
	}
	var retry int
	for i := 0; i < 2; i++ {
		if _, e = chargeService(p).ClaimVIPAward(ctx, a, 1, opPinned(rev)); e != nil {
			t.Fatal("deterministic replay", e)
		}
		retry++
	}
	if retry != 2 || crystalBalance(t, p, a) != start+5 {
		t.Fatal("replay granted twice")
	}
}

func TestI910GChargeQueryHistoryAndBoundedOtherRead(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	b := bornActor(t, p)
	chargeTap(t, p, rev, a, 80001007, uuid().String())
	reply, e := chargeService(p).Query(ctx, a, time.Unix(1700000000, 0))
	if e != nil {
		t.Fatal(e)
	}
	charges, ok := reply["charges"].([]d.Purchase)
	if !ok || len(charges) != 1 || charges[0].ChargeID != 80001007 || charges[0].ChargeCount != 1 || charges[0].LastBuyTime == 0 {
		t.Fatalf("354 charges: %#v", reply["charges"])
	}
	if reply["server_time"] != int64(1700000000) || reply["giftbags"] == nil {
		t.Fatalf("354 envelope: %#v", reply)
	}
	rows, e := (ps.Store{}).ReadBoundedChargesTx(ctx, p, a.LogicalServerID, []identity.PlayerID{a.PlayerID, b.PlayerID})
	if e != nil || len(rows) != 1 || rows[0].PlayerID != a.PlayerID || rows[0].Charge != 100 {
		t.Fatalf("bounded read: %+v %v", rows, e)
	}
	tooMany := make([]identity.PlayerID, 201)
	for i := range tooMany {
		tooMany[i] = identity.PlayerID(i + 1)
	}
	if _, e = (ps.Store{}).ReadBoundedChargesTx(ctx, p, a.LogicalServerID, tooMany); !errors.Is(e, d.ErrUnavailable) {
		t.Fatalf("201 ids admitted: %v", e)
	}
}

func TestI910GPrivilegeSnapshotSkillCapRisesAtVIPFive(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	before, e := privilegeProvider(p).SnapshotTx(ctx, p, a.PlayerID, time.Now().UTC())
	if e != nil || before.SkillPointNaturalCap != 10 || before.MonthCardActive || before.MonthlyPrivilegeActive {
		t.Fatalf("before: %+v %v", before, e)
	}
	chargeTap(t, p, rev, a, 80001005, uuid().String())
	chargeTap(t, p, rev, a, 80001005, uuid().String())
	chargeTap(t, p, rev, a, 80001005, uuid().String())
	after, e := privilegeProvider(p).SnapshotTx(ctx, p, a.PlayerID, time.Now().UTC())
	if e != nil || after.VIPLevel != 5 || after.SkillPointNaturalCap != 20 {
		t.Fatalf("after: %+v %v", after, e)
	}
	chargeTap(t, p, rev, a, 80001010, uuid().String())
	active, e := privilegeProvider(p).SnapshotTx(ctx, p, a.PlayerID, time.Now().UTC())
	if e != nil || !active.MonthlyPrivilegeActive || active.SkillPointNaturalCap != 30 {
		t.Fatalf("privilege card: %+v %v", active, e)
	}
}
