//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/marchstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/march"
	"gxb.local/backend/v2/internal/application/missioninputs"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
	"strconv"
	"testing"
	"time"
)

func marchMode(t *testing.T, p *pg.Pool) app.Mode {
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	fight := combatService(t, p)
	owner := compositeI5(p)
	owner.MissionFresh = p
	owner.MissionTime = pg.AuthoritativeTime{Queryer: p}
	owner.Missions = &i5.MissionMaterializer{Store: values, Catalog: content, Activity: content, Observations: missioninputs.Reader{Spending: values, Heroes: characterstore.Store{Queryer: p}, Progression: values, Campaigns: campaignstore.Store{}, Privileges: privilegeProvider(p), Books: bookService(p, p)}}
	return app.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Fresh: p, Store: marchstore.Store{}, Content: content, Fence: values, Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: ownerSummoner(p), HeroLocks: characterstore.MarchHeroPort{Store: characterstore.Store{Queryer: p}}, Roster: fight.Inputs.Heroes, HeroWire: heroproj.StockHero, Opponents: topFloorService(t, p), Combat: fight, Facts: i5.ObjectiveFacts{Owner: owner, Open: values}, Grants: owner, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
func marchRecord(t *testing.T, p *pg.Pool, a identity.ActorContext) d.Run {
	t.Helper()
	r, ok, err := (marchstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil || !ok {
		t.Fatal(ok, err)
	}
	return r
}
func marchReport(r d.Run, pid int64, formation []int64, win bool) app.Result {
	q := app.Result{Report: cd.Report{Win: win, Formation: formation, Allies: []cd.ActorStatus{}, Enemies: []cd.ActorStatus{}}}
	for _, id := range formation {
		if id > 0 {
			q.Report.Allies = append(q.Report.Allies, cd.ActorStatus{Player: pid, Identity: id, HP: 1, MP: 345})
		}
	}
	for key, row := range r.Enemies[r.Passed].Heroes {
		if fmt.Sprint(row["health"]) == "2" {
			continue
		}
		id, _ := strconv.ParseInt(key, 10, 64)
		hp := float64(0)
		if !win {
			hp = 3
		}
		q.Report.Enemies = append(q.Report.Enemies, cd.ActorStatus{Identity: id, HP: hp, MP: 100})
	}
	return q
}
func TestI9_5AMarchNativeRunCarryChestAndReset(t *testing.T) {
	p := pool(t)
	a, revision := bornActor(t, p), installed(t, p)
	s := marchMode(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	if _, err := s.Load(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("locked Champion", err)
	}
	compositeLevel(t, p, a, revision, 30)
	loaded, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal("load", err)
	}
	r := marchRecord(t, p, a)
	if len(r.Enemies) != 15 || len(r.Enemies[0].Heroes) == 0 {
		t.Fatal("source opponents absent", r)
	}
	first, _ := json.Marshal(r.Enemies)
	if _, err = s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	again, _ := json.Marshal(marchRecord(t, p, a).Enemies)
	if string(first) != string(again) {
		t.Fatal("reload rerolled opponents")
	}
	detail := map[string]any{}
	if err = s.OverlayMID1(ctx, p, a, false, time.Now(), detail); err != nil || fmt.Sprint(detail["336"]) != fmt.Sprint(loaded) {
		t.Fatal("MID1/load divergence", err)
	}
	team := []int64{1, 0, 0, 0, 0}
	start := op()
	if _, err = s.Start(ctx, a, app.Fight{Formation: team}, start); err != nil {
		t.Fatal("start", err)
	}
	pending := marchRecord(t, p, a).Pending
	if _, err = s.Start(ctx, a, app.Fight{Formation: team}, start); err != nil || marchRecord(t, p, a).Pending != pending {
		t.Fatal("START transport retry", err)
	}
	if _, err = s.Start(ctx, a, app.Fight{Formation: team}, op()); err != nil || marchRecord(t, p, a).Pending != pending {
		t.Fatal("START semantic retry", err)
	}
	r = marchRecord(t, p, a)
	q := marchReport(r, int64(a.PlayerID), team, false)
	if _, err = s.Result(ctx, a, q, op()); err != nil {
		t.Fatal("loss", err)
	}
	r = marchRecord(t, p, a)
	if r.Heroes["1"].HP != 1 || r.Heroes["1"].MP != 345 || r.Won {
		t.Fatal("HP/SP not carried", r)
	}
	if _, err = s.Chest(ctx, a, 1, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("loss chest", err)
	}
	if _, err = s.Start(ctx, a, app.Fight{Formation: team}, op()); err != nil {
		t.Fatal("retry partial enemy", err)
	}
	r = marchRecord(t, p, a)
	q = marchReport(r, int64(a.PlayerID), team, true)
	if _, err = s.Result(ctx, a, q, op()); err != nil {
		t.Fatal("win", err)
	}
	if _, err = s.Chest(ctx, a, 2, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("future chest", err)
	}
	claim := op()
	awards, err := s.Chest(ctx, a, 1, claim)
	if err != nil {
		t.Fatal("chest", err)
	}
	replay, err := s.Chest(ctx, a, 1, claim)
	originalJSON, _ := json.Marshal(awards)
	replayJSON, _ := json.Marshal(replay)
	if err != nil || string(originalJSON) != string(replayJSON) {
		t.Fatal("chest retry", err, string(originalJSON), string(replayJSON))
	}
	if _, err = s.Chest(ctx, a, 1, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("duplicate chest", err)
	}
	if _, err = s.Extra(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("early Mystic chest", err)
	}
	reset := op()
	if _, err = s.Reset(ctx, a, reset); err != nil {
		t.Fatal("reset", err)
	}
	if _, err = s.Reset(ctx, a, reset); err != nil {
		t.Fatal("reset retry", err)
	}
	if _, err = s.Reset(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("reset allowance", err)
	}
	r = marchRecord(t, p, a)
	if r.Passed != 0 || !r.ResetUsed || len(r.Heroes) != 0 || r.LifetimeChests != 1 {
		t.Fatal("reset state", r)
	}
}

type marchTestTime struct{ at time.Time }

func (f marchTestTime) Now(context.Context) (time.Time, error) { return f.at, nil }
func marchJSON(v any) string {
	raw, _ := json.Marshal(v)
	var normalized any
	decoder := json.NewDecoder(bytes.NewReader(raw))
	decoder.UseNumber()
	if err := decoder.Decode(&normalized); err != nil {
		panic(err)
	}
	raw, _ = json.Marshal(normalized)
	return string(raw)
}
func marchProgress(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	rows, err := (i5store.Store{}).ListMissionInstancesTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	for _, r := range rows {
		if r.ObjectiveID == 10016 {
			return r.Progress
		}
	}
	t.Fatal("March daily mission absent")
	return -1
}
func marchPair(t *testing.T, call func() (map[string]any, error)) (int, int) {
	t.Helper()
	ch := make(chan error, 2)
	for i := 0; i < 2; i++ {
		go func() { _, err := call(); ch <- err }()
	}
	good, bad := 0, 0
	for i := 0; i < 2; i++ {
		err := <-ch
		if err == nil {
			good++
		} else if errors.Is(err, d.ErrRefused) {
			bad++
		} else {
			t.Fatal("concurrent mutation", err)
		}
	}
	return good, bad
}
func TestI9_5AMarchNativeAllStagesExtraAndConcurrentValue(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	s := marchMode(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	compositeLevel(t, p, a, rev, 30)
	team := []int64{1, 0, 0, 0, 0}
	for stage := int64(1); stage <= 15; stage++ {
		if _, err := s.Start(ctx, a, app.Fight{Formation: team}, op()); err != nil {
			t.Fatal(stage, "start", err)
		}
		report := marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true)
		if stage == 1 {
			report.Report.Formation = nil
		} // Current BattleCreateReport omits formation.
		resultOp := op()
		body, err := s.Result(ctx, a, report, resultOp)
		if err != nil {
			t.Fatal(stage, "result", err)
		}
		again, err := s.Result(ctx, a, report, resultOp)
		if err != nil || marchJSON(body) != marchJSON(again) {
			t.Fatal("RESULT exact retry", err, marchJSON(body), marchJSON(again))
		}
		if stage == 1 {
			late, err := s.Result(ctx, a, report, op())
			if err != nil || fmt.Sprint(late["error_code"]) != "30005" {
				t.Fatal("RESULT semantic retry", late, err)
			}
			if marchProgress(t, p, a) != 1 {
				t.Fatal("March producer did not advance daily mission")
			}
			good, bad := marchPair(t, func() (map[string]any, error) { return s.Chest(ctx, a, stage, op()) })
			if good != 1 || bad != 1 {
				t.Fatal("chest double spend", good, bad)
			}
		} else {
			if _, err = s.Chest(ctx, a, stage, op()); err != nil {
				t.Fatal(stage, "chest", err)
			}
		}
		if stage == 9 {
			var before, after int64
			if err = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&before); err != nil {
				t.Fatal(err)
			}
			good, bad := marchPair(t, func() (map[string]any, error) { return s.Extra(ctx, a, op()) })
			if good != 1 || bad != 1 {
				t.Fatal("Mystic double spend", good, bad)
			}
			if err = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&after); err != nil || before-after != 50 {
				t.Fatal("Mystic cost", before, after, err)
			}
		}
	}
	if marchRecord(t, p, a).Passed != 15 {
		t.Fatal("map incomplete")
	}
	if _, err := s.Start(ctx, a, app.Fight{Formation: team}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("battle after final stage", err)
	}
	if _, err := s.Chest(ctx, a, 15, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("duplicate final chest", err)
	}
	// Extra exact retry on another genuine run, without fixture-authoring eligibility.
	if _, err := s.Reset(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	for stage := int64(1); stage <= 9; stage++ {
		if _, err := s.Start(ctx, a, app.Fight{Formation: team}, op()); err != nil {
			t.Fatal(err)
		}
		if _, err := s.Result(ctx, a, marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true), op()); err != nil {
			t.Fatal(err)
		}
		if _, err := s.Chest(ctx, a, stage, op()); err != nil {
			t.Fatal(err)
		}
	}
	claim := op()
	first, err := s.Extra(ctx, a, claim)
	if err != nil {
		t.Fatal(err)
	}
	retry, err := s.Extra(ctx, a, claim)
	if err != nil || marchJSON(first) != marchJSON(retry) {
		t.Fatal("Mystic retry", err)
	}
}

type marchFailFacts struct{ app.Facts }

func (f marchFailFacts) RecordTx(context.Context, tx.Tx, operation.Context, ...objective.Fact) error {
	return errors.New("injected March fact failure")
}
func TestI9_5AMarchNativeReportsDeathRollbackAndDailyManualReset(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	s := marchMode(t, p)
	bornHero(t, p, a, rev, 10001001, 1)
	bornHero(t, p, a, rev, 10001002, 2)
	compositeLevel(t, p, a, rev, 30)
	team := []int64{1, 2, 0, 0, 0}
	if _, err := s.Start(ctx, a, app.Fight{Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	// One omitted enemy must consume the rejected attempt without accepting state or a mission fact.
	q := marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true)
	q.Report.Enemies = q.Report.Enemies[:len(q.Report.Enemies)-1]
	body, err := s.Result(ctx, a, q, op())
	if err != nil || fmt.Sprint(body["error_code"]) != "1" || len(marchRecord(t, p, a).Heroes) != 0 {
		t.Fatal("incomplete report", body, err)
	}
	if _, err = s.Start(ctx, a, app.Fight{Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	q = marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true)
	q.Report.Allies[0].HP = 0
	bad := s
	bad.Facts = marchFailFacts{s.Facts}
	attempt := marchRecord(t, p, a).Pending
	if _, err = bad.Result(ctx, a, q, op()); err == nil || marchRecord(t, p, a).Pending != attempt || len(marchRecord(t, p, a).Heroes) != 0 {
		t.Fatal("failed fact did not roll back combat and carry", err)
	}
	if _, err = s.Result(ctx, a, q, op()); err != nil {
		t.Fatal(err)
	}
	if marchRecord(t, p, a).Alive(1) || !marchRecord(t, p, a).Alive(2) {
		t.Fatal("one survivor win/death")
	}
	if _, err = s.Chest(ctx, a, 1, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Start(ctx, a, app.Fight{Formation: team}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("dead girl selected", err)
	}
	survivor := []int64{2, 0, 0, 0, 0}
	if _, err = s.Start(ctx, a, app.Fight{Formation: survivor}, op()); err != nil {
		t.Fatal("survivor rejected", err)
	}
	q = marchReport(marchRecord(t, p, a), int64(a.PlayerID), survivor, false)
	q.Report.Allies[0].HP = 0
	if _, err = s.Result(ctx, a, q, op()); err != nil {
		t.Fatal(err)
	}
	before := marchRecord(t, p, a)
	future := s
	future.Timed.Binder.Time = marchTestTime{time.Now().UTC().Add(24 * time.Hour)}
	if _, err = future.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	after := marchRecord(t, p, a)
	if after.Passed != before.Passed || after.Alive(1) || after.Alive(2) || after.Occurrence != before.Occurrence {
		t.Fatal("daily boundary discarded run/resurrected girls")
	}
	claim := op()
	first, err := future.Reset(ctx, a, claim)
	if err != nil {
		t.Fatal(err)
	}
	again, err := future.Reset(ctx, a, claim)
	if err != nil || marchJSON(first) != marchJSON(again) {
		t.Fatal("Reset retry", err, marchJSON(first), marchJSON(again))
	}
	if _, err = future.Reset(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("daily Reset allowance", err)
	}
	after = marchRecord(t, p, a)
	if !after.Alive(1) || !after.Alive(2) || after.Passed != 0 {
		t.Fatal("manual reset failed", after)
	}
}
func TestI9_5AMarchNativeVanguardSacrificeAndCanonicalForce(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	s := marchMode(t, p)
	compositeLevel(t, p, a, rev, 65)
	for i := int64(1); i <= 6; i++ {
		h := bornHero(t, p, a, rev, 10001000+i, i)
		h.Level = 65
		h.StateVersion++
		tr, err := p.Begin(ctx, tx.Options{})
		if err != nil {
			t.Fatal(err)
		}
		err = (characterstore.Store{}).SaveHeroProgressionTx(ctx, tr, h, h.StateVersion-1)
		if err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	invalid := app.Fight{Formation: []int64{1, 2, 3, 4}, Force: 9999999999999}
	if _, err := s.Advance(ctx, a, invalid, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("four-girl Vanguard", err)
	}
	team := []int64{1, 2, 3, 4, 5}
	q := app.Fight{Formation: team, Force: 9999999999999}
	claim := op()
	first, err := s.Advance(ctx, a, q, claim)
	if err != nil {
		t.Fatal("Vanguard", err)
	}
	r := marchRecord(t, p, a)
	if r.Passed < 1 || r.Passed > 14 || r.Drinks != r.Passed || !r.Advanced || !r.Alive(6) {
		t.Fatal("Vanguard prefix/reagents", r)
	}
	for _, id := range team {
		if r.Alive(id) {
			t.Fatal("sacrificed girl survived", id)
		}
	}
	again, err := s.Advance(ctx, a, q, claim)
	if err != nil || marchJSON(first) != marchJSON(again) {
		t.Fatal("Vanguard retry", err, marchJSON(first), marchJSON(again))
	}
	if _, err = s.Advance(ctx, a, q, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("second Vanguard", err)
	}
	if _, err = s.Start(ctx, a, app.Fight{Formation: []int64{6, 0, 0, 0, 0}}, op()); err != nil {
		t.Fatal("non-sacrificed girl unusable", err)
	}
	if _, err = s.Advance(ctx, a, q, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("Vanguard after manual battle", err)
	}
}

func TestI9_5AMarchNativeRealDefenseSnapshotsDoNotMutateOpponent(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, b := bornActor(t, p), bornActor(t, p)
	for _, actor := range []identity.ActorContext{a, b} {
		bornHero(t, p, actor, rev, 10001001, 1)
		compositeLevel(t, p, actor, rev, 30)
	}
	ladder := topFloorService(t, p)
	if _, err := ladder.Load(ctx, b, op()); err != nil {
		t.Fatal("opponent ladder entry", err)
	}
	if err := ladder.SaveDefense(ctx, b, []int64{1}, 0, op()); err != nil {
		t.Fatal("opponent defense", err)
	}
	s := marchMode(t, p)
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	r := marchRecord(t, p, a)
	for _, enemy := range r.Enemies {
		if enemy.Player <= 0 || enemy.Player == int64(a.PlayerID) || enemy.Robot != 0 || enemy.Heroes["1"] == nil {
			t.Fatal("same-server real defense not matched", enemy)
		}
	}
	sourcePlayer := identity.PlayerID(r.Enemies[0].Player)
	before, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, sourcePlayer, 1)
	if err != nil {
		t.Fatal(err)
	}
	team := []int64{1, 0, 0, 0, 0}
	if _, err = s.Start(ctx, a, app.Fight{Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Result(ctx, a, marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true), op()); err != nil {
		t.Fatal(err)
	}
	after, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, sourcePlayer, 1)
	if err != nil || marchJSON(before) != marchJSON(after) {
		t.Fatal("opponent changed", err)
	}
	if number := marchRecord(t, p, a).Enemies[1].Heroes["1"]["health"]; fmt.Sprint(number) != "0" {
		t.Fatal("stage snapshots alias each other", number)
	}
}
