//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	combat "gxb.local/backend/v2/internal/application/combat"
	app "gxb.local/backend/v2/internal/application/workplace"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/workplace"
)

func workplaceManaBalance(t *testing.T, p *pg.Pool, a identity.ActorContext) int64 {
	t.Helper()
	b, ok, err := (i5store.Store{}).ReadScalarTx(ctx, p, a.PlayerID, "mana")
	if err != nil {
		t.Fatal("mana", err)
	}
	if !ok {
		return 0
	}
	return b.Amount
}

// workplaceRivalFixture dispatches one due rival job whose combat worker is the
// given fake, so the claim's resolver outcome is deterministic.
func workplaceRivalFixture(t *testing.T, p *pg.Pool, clock *workplaceTime, worker combat.Worker) (app.Mode, identity.ActorContext, int64, d.Occurrence) {
	t.Helper()
	a, revision := bornActor(t, p), installed(t, p)
	s := workplaceMode(t, p, clock)
	s.Timed.Binder.Time = clock
	fight := combatService(t, p)
	fight.Worker = worker
	s.Combat = fight
	// The first admission initializes the I5 observation roots the level-up
	// eligibility reconcile needs; at level 1 it refuses the function gate.
	if _, err := s.Load(ctx, a, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("function gate", err)
	}
	compositeLevel(t, p, a, revision, 100)
	h := bornHero(t, p, a, revision, 10001001, 1)
	cat, err := (contentstore.Store{}).WorkplaceCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	crew, ok := cat.Girl(h.OriginTableID)
	if !ok {
		t.Fatal("crew origin", h.OriginTableID)
	}
	location, _ := cat.Location(crew.Location)
	job, _ := cat.Job(location.Jobs[0])
	if job.Product != 1 {
		t.Fatal("fixture requires mana", job)
	}
	quote, err := d.Calculate(location, job, []d.Worker{{PartnerID: h.PartnerID, BaseID: h.OriginTableID, Level: h.Level, Color: h.Color, Star: h.Star, Trait: crew.Trait}}, cat.VIP[0], cat.Formula)
	if err != nil {
		t.Fatal(err)
	}
	// The level-up writes the function-9 gate at the real clock, so re-anchor
	// this mode's decision time after it before the admitting read.
	clock.at = time.Now().UTC().Add(time.Second)
	if _, err = s.Load(ctx, a, op()); err != nil {
		t.Fatal("load", err)
	}
	request := app.Dispatch{Team: location.ID, Job: job.ID, Partners: []int64{h.PartnerID}, SP: quote.SP}
	if _, err = s.Dispatch(ctx, a, request, workplaceOperation(quote, len(job.Chests), true, 1)); err != nil {
		t.Fatal("dispatch rival job", err)
	}
	occurrence := workplaceRecord(t, p, a).Slots[location.ID]
	if occurrence == nil || occurrence.Attempt == "" {
		t.Fatal("rival attempt absent", occurrence)
	}
	clock.at = time.Unix(occurrence.Start+occurrence.Quote.Seconds+1, 0).UTC()
	return s, a, location.ID, *occurrence
}

func TestI9_5BWorkplaceUnresolvedRivalNative(t *testing.T) {
	p := pool(t)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Second)}
	s, a, team, occurrence := workplaceRivalFixture(t, p, clock, permanentWorker{})
	before := workplaceManaBalance(t, p, a)
	if _, err := s.Claim(ctx, a, team, op()); err != nil {
		t.Fatal("claim after permanent resolver failure", err)
	}
	record := workplaceRecord(t, p, a)
	if record.Slots[team] != nil {
		t.Fatal("job still occupies its slot", record.Slots[team])
	}
	if record.Busy(occurrence.Workers[0].PartnerID) {
		t.Fatal("hero still busy after unresolved claim")
	}
	if len(record.Diary) != 1 {
		t.Fatal("claim diary", record.Diary)
	}
	entry := record.Diary[0]
	if fmt.Sprint(entry["with_battle"]) != "1" || fmt.Sprint(entry["is_win"]) != "0" {
		t.Fatal("unresolved rival diary", entry)
	}
	award, ok := entry["award"].(map[string]any)
	if !ok {
		t.Fatal("diary award", entry)
	}
	if battle, ok := award["battle_award"].(map[string]any); !ok || len(battle) != 0 {
		t.Fatal("rival bonus granted without a result", battle)
	}
	if delta := workplaceManaBalance(t, p, a) - before; delta != occurrence.Quote.Quantity {
		t.Fatal("base lines not granted once", delta, occurrence.Quote.Quantity)
	}
	var state, kind string
	if err := p.QueryRow(ctx, `SELECT state, terminal_kind FROM combat_attempts WHERE attempt_id=$1`, occurrence.Attempt).Scan(&state, &kind); err != nil {
		t.Fatal(err)
	}
	if state != "TERMINAL" || kind != "WORKPLACE_JOB_CLOSED" {
		t.Fatal("attempt not closed", state, kind)
	}
	claimed := workplaceManaBalance(t, p, a)
	if _, err := s.Claim(ctx, a, team, op()); err != nil {
		t.Fatal("second claim", err)
	}
	if workplaceManaBalance(t, p, a) != claimed {
		t.Fatal("second claim granted again")
	}
	if len(workplaceRecord(t, p, a).Diary) != 1 {
		t.Fatal("second claim wrote a diary entry")
	}
}

func TestI9_5BWorkplaceRetryableRivalNative(t *testing.T) {
	p := pool(t)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Second)}
	s, a, team, occurrence := workplaceRivalFixture(t, p, clock, failingWorker{})
	before := workplaceManaBalance(t, p, a)
	if _, err := s.Claim(ctx, a, team, op()); !errors.Is(err, cd.ErrResolverRetryable) {
		t.Fatal("retryable resolver failure", err)
	}
	record := workplaceRecord(t, p, a)
	slot := record.Slots[team]
	if slot == nil || slot.ID != occurrence.ID || slot.Attempt != occurrence.Attempt {
		t.Fatal("retryable failure changed the job", slot)
	}
	if !record.Busy(occurrence.Workers[0].PartnerID) {
		t.Fatal("retryable failure freed the heroes")
	}
	if workplaceManaBalance(t, p, a) != before || len(record.Diary) != 0 {
		t.Fatal("retryable failure settled the job")
	}
	var state string
	if err := p.QueryRow(ctx, `SELECT state FROM combat_attempts WHERE attempt_id=$1`, occurrence.Attempt).Scan(&state); err != nil {
		t.Fatal(err)
	}
	if state == "TERMINAL" {
		t.Fatal("retryable failure closed the attempt")
	}
}
