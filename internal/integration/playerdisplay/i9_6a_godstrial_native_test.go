//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/godstrialstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/spiritstore"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	app "gxb.local/backend/v2/internal/application/godstrial"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/godstrial"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/changes"
	"sync"
	"testing"
	"time"
)

func godsTrialMode(t *testing.T, p *pg.Pool, clock *workplaceTime) app.Mode {
	m := marchMode(t, p)
	owner := m.Grants.(i5.Service)
	owner.Spirits = spiritService(p, p)
	fight := combatService(t, p)
	values := i5store.Store{Queryer: p}
	s := app.Mode{Spirit: spiritService(p, p), Progression: values, Mail: values, Energy: owner, Timed: m.Timed, Fresh: p, Store: godstrialstore.Store{}, Content: contentstore.Store{Queryer: p}, Fence: m.Fence, Functions: m.Functions, Heroes: m.Heroes, HeroLocks: characterstore.GodsTrialHeroPort{Store: characterstore.Store{Queryer: p}}, Pets: pet.Service{Store: characterstore.Store{Queryer: p}}, Combat: fight, Rules: fight.Rules, Values: owner, Facts: i5.ObjectiveFacts{Owner: owner, Open: values}, Receipts: m.Receipts, ReceiptRead: m.ReceiptRead}
	s.Timed.Binder.Time = clock
	return s
}
func TestI9_6AGodsTrialNative(t *testing.T) {
	p := pool(t)
	a, rev := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	s := godsTrialMode(t, p, clock)
	if _, e := s.Info(ctx, a, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("gate", e)
	}
	compositeLevel(t, p, a, rev, 100)
	bornHero(t, p, a, rev, 10001001, 1)
	exec(t, p, `UPDATE player_temporal_resources SET stored_amount=180,regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='spirit_energy'`, int64(a.PlayerID))
	day := d.Weekday(modes.Day(clock.at))
	cid := day*1000 + 1
	info, e := s.Info(ctx, a, op())
	if e != nil {
		t.Fatal("info", e)
	}
	if fmt.Sprint(info["day"]) != fmt.Sprint(day) {
		t.Fatal(info)
	}
	q := app.Result{Campaign: cid, Star: 1, Formation: []int64{1}}
	if _, e = s.Result(ctx, a, q, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("no START", e)
	}
	if _, e = s.BeginAuto(ctx, a, cid, 1, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("unwon auto", e)
	}
	wrong := cid + 1000
	if wrong > 7006 {
		wrong -= 7000
	}
	if _, e = s.Start(ctx, a, app.Fight{Campaign: wrong, Formation: []int64{1}}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("weekday", e)
	}
	startOp := op()
	if _, e = s.Start(ctx, a, app.Fight{Campaign: cid, Formation: []int64{1}}, startOp); e != nil {
		t.Fatal("START", e)
	}
	r, _, e := (godstrialstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if e != nil || r.Fight == nil {
		t.Fatal(r, e)
	}
	firstID := r.Fight.ID
	if _, e = s.Start(ctx, a, app.Fight{Campaign: cid, Formation: []int64{1}}, op()); e != nil {
		t.Fatal("same START", e)
	}
	r, _, _ = (godstrialstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if r.Fight.ID != firstID {
		t.Fatal("redrawn start")
	}
	bad := q
	bad.Formation = []int64{99}
	if _, e = s.Result(ctx, a, bad, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("changed formation", e)
	}
	balance := func() int64 {
		var n int64
		if e := p.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='spirit_energy'`, int64(a.PlayerID)).Scan(&n); e != nil {
			t.Fatal(e)
		}
		return n
	}
	before := balance()
	settleOp := op()
	tracked, _ := changes.Track(ctx)
	out, e := s.Result(tracked, a, q, settleOp)
	if e != nil {
		t.Fatal("RESULT", e)
	}
	if len(out["spirit_items"].([]map[string]any)) == 0 {
		t.Fatal(out)
	}
	root, e := (spiritstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || len(root.Facts.Instances) != len(out["spirit_items"].([]map[string]any)) {
		t.Fatal("canonical mint count", root, e)
	}
	minted := len(root.Facts.Instances)
	var progress int64
	if e = p.QueryRow(ctx, `SELECT progress FROM player_mission_instances WHERE player_id=$1 AND objective_id=10037 AND definition_revision='I9_MISSIONS_V1'`, int64(a.PlayerID)).Scan(&progress); e != nil || progress != 1 {
		t.Fatal("committed clear mission", progress, e)
	}
	after := balance()
	if before != 180 || after != 160 {
		t.Fatal("no cost", before, after)
	}
	if _, e = s.Result(ctx, a, q, settleOp); e != nil {
		t.Fatal("exact RESULT", e)
	}
	retry, e := s.Result(ctx, a, q, op())
	if e != nil || fmt.Sprint(retry["error_code"]) != "30005" || balance() != after {
		t.Fatal("terminal replay", retry, e)
	}
	root, e = (spiritstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || len(root.Facts.Instances) != minted {
		t.Fatal("retry reminted", root, e)
	}
	loss := q
	loss.Star = 0
	if _, e = s.Start(ctx, a, app.Fight{Campaign: cid, Formation: []int64{1}}, op()); e != nil {
		t.Fatal("loss START", e)
	}
	if _, e = s.Result(ctx, a, loss, op()); e != nil || balance() != 158 {
		t.Fatal("loss cost", balance(), e)
	}
	r, _, _ = (godstrialstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if r.Wins[cid] != 1 {
		t.Fatal("loss progressed")
	}
	var attempts int64
	if e = p.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE actor_player_id=$1`, int64(a.PlayerID)).Scan(&attempts); e != nil {
		t.Fatal(e)
	}
	autoOp := op()
	if _, e = s.BeginAuto(ctx, a, cid, 1, autoOp); e != nil {
		t.Fatal("auto START", e)
	}
	charged := balance()
	if charged != 138 {
		t.Fatal("auto charge", charged)
	}
	if _, e = s.BeginAuto(ctx, a, cid, 2, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("conflicting auto", e)
	}
	if _, e = s.BeginAuto(ctx, a, cid, 1, op()); e != nil || balance() != charged {
		t.Fatal("auto retry", e)
	}
	early, e := s.CollectAuto(ctx, a, op())
	if e != nil || early["error_code"] != int64(1) || early["base_info"] == nil || balance() != charged {
		t.Fatal("early collect keeps the projection the stock callback reads", early, e)
	}
	// A new service and next weekday must still collect the prepaid frozen job.
	clock.at = clock.at.Add(24 * time.Hour)
	s = godsTrialMode(t, p, clock)
	wg := sync.WaitGroup{}
	errs := make(chan error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.CollectAuto(ctx, a, op()); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("concurrent collection", e)
		}
	}
	r, _, e = (godstrialstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if e != nil || r.Auto != nil || r.Wins[cid] != 2 {
		t.Fatal("progress", r, e)
	}
	var count int64
	if e = p.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE actor_player_id=$1`, int64(a.PlayerID)).Scan(&count); e != nil || count != attempts {
		t.Fatal("auto simulated combat", count, attempts, e)
	}
	if _, e = s.CollectAuto(ctx, a, op()); e != nil || balance() != charged {
		t.Fatal("collection retry", e)
	}
	root, e = (spiritstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || len(root.Facts.Instances) <= minted {
		t.Fatal("auto did not mint", root, e)
	}
	if _, e = s.Detail(ctx, a, op()); e != nil {
		t.Fatal("reload", e)
	}
}

func TestI9_6AGodsTrialNativeRefusalsAndExpiredAttempt(t *testing.T) {
	p := pool(t)
	a, rev := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	s := godsTrialMode(t, p, clock)
	compositeLevel(t, p, a, rev, 100)
	bornHero(t, p, a, rev, 10001001, 1)
	cid := d.Weekday(modes.Day(clock.at))*1000 + 1
	for _, q := range []app.Fight{{Campaign: cid, Formation: []int64{999}}, {Campaign: cid + 1, Formation: []int64{1}}, {Campaign: cid, Formation: []int64{1}, Pet: 999}} {
		if _, e := s.Start(ctx, a, q, op()); e == nil {
			t.Fatal("invalid owner/prerequisite admitted", q)
		}
	}
	exec(t, p, `UPDATE player_temporal_resources SET stored_amount=0,regen_anchor_at=$2 WHERE player_id=$1 AND resource_key='spirit_energy'`, int64(a.PlayerID), clock.at)
	if _, e := s.Start(ctx, a, app.Fight{Campaign: cid, Formation: []int64{1}}, op()); e == nil {
		t.Fatal("energy admission")
	}
	var attempts int
	if e := p.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE actor_player_id=$1`, int64(a.PlayerID)).Scan(&attempts); e != nil || attempts != 0 {
		t.Fatal("refused START persisted attempt", attempts, e)
	}
	exec(t, p, `UPDATE player_temporal_resources SET stored_amount=180,regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='spirit_energy'`, int64(a.PlayerID))
	if _, e := s.Start(ctx, a, app.Fight{Campaign: cid, Formation: []int64{1}}, op()); e != nil {
		t.Fatal(e)
	}
	clock.at = clock.at.Add(61 * time.Minute)
	out, e := s.Result(ctx, a, app.Result{Campaign: cid, Star: 1, Formation: []int64{1}}, op())
	if e != nil || fmt.Sprint(out["error_code"]) != "30005" {
		t.Fatal("expired result", out, e)
	}
	r, _, e := (godstrialstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if e != nil || r.Fight != nil || r.Wins[cid] != 0 {
		t.Fatal("expired attempt progressed", r, e)
	}
	root, e := (spiritstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || len(root.Facts.Instances) != 0 {
		t.Fatal("expired attempt minted", root, e)
	}
}
