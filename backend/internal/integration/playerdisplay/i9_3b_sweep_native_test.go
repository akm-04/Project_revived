//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"testing"

	app "gxb.local/backend/v2/internal/application/campaign"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type sweepFacts struct {
	app.Facts
	keys map[string]bool
}

func (f *sweepFacts) RecordTx(c context.Context, t tx.Tx, op operation.Context, facts ...objective.Fact) error {
	if err := f.Facts.RecordTx(c, t, op, facts...); err != nil {
		return err
	}
	for _, fact := range facts {
		f.keys[fact.SourceBusinessKey] = true
	}
	return nil
}

func TestI9_3BSweepReceiptCostsAndResetNative(t *testing.T) {
	p := pool(t)
	s := campaignMode(t, p)
	a, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	exec(t, p, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	compositeLevel(t, p, a, rev, 45)
	q := app.Sweep{CampaignID: 100001, Type: d.Normal, Count: 1, Kind: 1}
	if _, err := s.Sweep(ctx, a, q, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("unplayed sweep", err)
	}
	team := []int64{1, 0, 0, 0, 0}
	clear := func(id, kind int64) {
		t.Helper()
		if _, err := s.Fight(ctx, a, app.Fight{CampaignID: id, Type: kind, Formation: team}, op()); err != nil {
			t.Fatal(err)
		}
		tracked, _ := changes.Track(ctx)
		if _, err := s.Result(tracked, a, app.Result{CampaignID: id, Type: kind, Star: 3, Formation: team}, op()); err != nil {
			t.Fatal(err)
		}
	}
	clear(100001, d.Normal)
	if _, err := s.Sweep(ctx, a, q, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("no cards", err)
	}
	lines := []grant.Line{{Kind: grant.StackItem, ItemID: 50001013, Amount: 12}, {Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 1000}}
	if _, err := compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_3B_NATIVE", lines, opPinned(rev)); err != nil {
		t.Fatal(err)
	}
	read := func(sql string) int64 {
		t.Helper()
		var value int64
		if err := p.QueryRow(ctx, sql, int64(a.PlayerID)).Scan(&value); err != nil {
			t.Fatal(err)
		}
		return value
	}
	cardsSQL := `SELECT coalesce((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=50001013),0)`
	crystalSQL := `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`
	energySQL := `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='energy'`
	// A failed cost must roll back the already staged energy debit.
	beforeEnergy := read(energySQL)
	tooMany := q
	tooMany.Count = 10
	if _, err := s.Sweep(ctx, a, tooMany, op()); !errors.Is(err, d.ErrRefused) || read(energySQL) != beforeEnergy {
		t.Fatal("VIP refusal changed energy", err)
	}
	tracked, _ := changes.Track(ctx)
	firstOp := op()
	first, err := s.Sweep(tracked, a, q, firstOp)
	rewards := func(body map[string]any) int64 {
		var cards int64
		for _, row := range body["items"].([][]d.Item) {
			for _, item := range row {
				if item.ItemID == 50001013 {
					cards += item.Num
				}
			}
		}
		return cards
	}
	expectedCards := int64(11) + rewards(first)
	if err != nil || len(first["items"].([][]d.Item)) != 1 || read(cardsSQL) != expectedCards {
		t.Fatal("single sweep", first, err)
	}
	firstEnergy := read(energySQL)
	if firstEnergy != beforeEnergy-6 {
		t.Fatal("energy", firstEnergy, beforeEnergy)
	}
	reloaded := campaignMode(t, p)
	if _, err = reloaded.Sweep(ctx, a, q, firstOp); err != nil || read(cardsSQL) != expectedCards || read(energySQL) != firstEnergy {
		t.Fatal("receipt replay", err)
	}
	changed := q
	changed.Kind = 2
	var conflict *receipt.ConflictError
	if _, err = reloaded.Sweep(ctx, a, changed, firstOp); !errors.As(err, &conflict) {
		t.Fatal("conflicting retry", err)
	}
	if _, err = privilegeService(p, p).ImportManual(ctx, authority(), importQ(a, uuid().String(), maximumCharge), op()); err != nil {
		t.Fatal(err)
	}
	facts := &sweepFacts{Facts: s.Facts, keys: map[string]bool{}}
	s.Facts = facts
	tracked, _ = changes.Track(ctx)
	multi, e := s.Sweep(tracked, a, tooMany, op())
	err = e
	expectedCards = expectedCards - 10 + rewards(multi)
	if err != nil || read(cardsSQL) != expectedCards || len(facts.keys) != 11 {
		t.Fatal("multi item", err, len(facts.keys))
	}
	crystalBefore := read(crystalSQL)
	tooMany.Kind = 2
	tracked, _ = changes.Track(ctx)
	crystal, e := s.Sweep(tracked, a, tooMany, op())
	err = e
	expectedCards += rewards(crystal)
	if err != nil || read(cardsSQL) != expectedCards || read(crystalSQL) != crystalBefore-10 {
		t.Fatal("crystal sweep consumed cards/wrong cost", err)
	}
	// Spend all cards through the canonical cost owner, then prove a refused sweep rolls energy back.
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if _, e = s.Costs.DebitMaterialCostTx(ctx, tr, a.PlayerID, i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: 50001013, Amount: expectedCards}}}, opPinned(rev)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	expectedCards = 0
	tooMany.Kind = 1
	energyBefore := read(energySQL)
	crystalBefore = read(crystalSQL)
	if _, err = s.Sweep(ctx, a, tooMany, op()); !errors.Is(err, d.ErrRefused) || read(energySQL) != energyBefore || read(crystalSQL) != crystalBefore || read(cardsSQL) != expectedCards {
		t.Fatal("cost rollback", err)
	}
	clear(100019, d.Super)
	reset := app.Reset{CampaignID: 100019, Type: d.Super}
	if _, err = s.Reset(ctx, a, reset, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("early reset", err)
	}
	elite := app.Sweep{CampaignID: 100019, Type: d.Super, Count: 2, Kind: 2}
	tracked, _ = changes.Track(ctx)
	if _, err = s.Sweep(tracked, a, elite, op()); err != nil {
		t.Fatal("super sweep", err)
	}
	crystalBefore = read(crystalSQL)
	// Concurrent retries of the stock reset have no shared nonce: row postcondition must charge once.
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for range 2 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c, _ := changes.Track(ctx)
			body, e := campaignMode(t, p).Reset(c, a, reset, op())
			if e == nil && (fmt.Sprint(body["daily_limit"]) != "3" || fmt.Sprint(body["reset_count"]) != "1") {
				e = fmt.Errorf("bad reset %v", body)
			}
			errs <- e
		}()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("concurrent reset", e)
		}
	}
	if spent := crystalBefore - read(crystalSQL); spent != 20 {
		t.Fatal("reset price charged twice", spent)
	}

	// Two full-block sweeps race on the same remaining allowance: exactly one can settle.
	elite.Count = 3
	results := make(chan error, 2)
	crystalBefore = read(crystalSQL)
	for range 2 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			c, _ := changes.Track(ctx)
			_, e := campaignMode(t, p).Sweep(c, a, elite, op())
			results <- e
		}()
	}
	wg.Wait()
	close(results)
	successes, refusals := 0, 0
	for e := range results {
		if e == nil {
			successes++
		} else if errors.Is(e, d.ErrRefused) {
			refusals++
		} else {
			t.Fatal(e)
		}
	}
	if successes != 1 || refusals != 1 || read(crystalSQL) != crystalBefore-3 {
		t.Fatal("concurrent sweep overspent", successes, refusals)
	}
	// A real commit with a lost acknowledgement must resolve from its durable receipt.
	uncertain := campaignMode(t, p)
	uncertain.Timed.Runner.DB = metricCommitDB{Beginner: p, commit: true}
	paid := op()
	tracked, _ = changes.Track(ctx)
	before := read(crystalSQL)
	answer, e := uncertain.Sweep(tracked, a, changed, paid)
	if e != nil || answer["economy_"] == nil || read(crystalSQL) != before-1 {
		t.Fatal("unknown commit positive proof", answer, e)
	}
	if _, e = campaignMode(t, p).Sweep(ctx, a, changed, paid); e != nil || read(crystalSQL) != before-1 {
		t.Fatal("unknown commit retry", e)
	}
	uncertain.Timed.Runner.DB = metricCommitDB{Beginner: p, commit: false}
	if _, e = uncertain.Sweep(ctx, a, changed, op()); e == nil || read(crystalSQL) != before-1 {
		t.Fatal("missing receipt became success", e)
	}
	world, err := s.Load(ctx, a, op())
	if err != nil || fmt.Sprint(campaignRow(t, world["super"], 100019)["daily_limit"]) != "0" {
		t.Fatal("reload", world, err)
	}
}
