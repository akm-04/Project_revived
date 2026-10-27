//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"

	"gxb.local/backend/v2/internal/adapters/postgres/workplacestore"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/workplace"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/workplace"
	"gxb.local/backend/v2/internal/foundation/operation"
	"sync"
	"testing"
	"time"
)

type workplaceTime struct{ at time.Time }

func (f *workplaceTime) Now(_ context.Context) (time.Time, error) { return f.at, nil }
func workplaceMode(t *testing.T, p *pg.Pool, clock *workplaceTime) app.Mode {
	m := marchMode(t, p)
	owner := m.Grants.(i5.Service)
	return app.Mode{Timed: m.Timed, Fresh: p, Store: workplacestore.Store{}, Content: contentstore.Store{Queryer: p}, Fence: m.Fence, Functions: m.Functions, Directory: m.Directory, Campaigns: campaignstore.Store{}, Heroes: m.Heroes, HeroLocks: characterstore.WorkplaceHeroPort{Store: characterstore.Store{Queryer: p}}, HeroWire: m.HeroWire, Opponents: topFloorService(t, p), Combat: combatService(t, p), Stats: m.Stats, Values: owner, Privileges: owner.Privileges, Facts: m.Facts, Receipts: m.Receipts, ReceiptRead: m.ReceiptRead}
}
func workplaceRecord(t *testing.T, p *pg.Pool, a identity.ActorContext) d.State {
	t.Helper()
	r, ok, e := (workplacestore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if e != nil || !ok {
		t.Fatal(ok, e)
	}
	return r
}
func workplaceOperation(q d.Quote, chests int, rival bool, ordinal uint64) operation.Context {
	for {
		operation := op()
		rng := cd.NewStream(operation.Derive("workplace.job-reward/v1", ordinal))
		if q.ChestPercent > int64(rng.Uniform(100)) && chests > 0 {
			rng.Uniform(uint64(chests))
		}
		hit := q.RivalPercent > int64(rng.Uniform(100))
		if hit == rival {
			return operation
		}
	}
}
func TestI9_5BWorkplaceNativeLifecycle(t *testing.T) {
	p := pool(t)
	a, revision := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Second)}
	s := workplaceMode(t, p, clock)
	s.Timed.Binder.Time = clock
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
	if _, err = s.Load(ctx, a, op()); err != nil {
		t.Fatal("load", err)
	}
	request := app.Dispatch{Team: location.ID, Job: job.ID, Partners: []int64{h.PartnerID}, SP: quote.SP}
	forged := request
	forged.SP++
	if _, err = s.Dispatch(ctx, a, forged, op()); !errors.Is(err, d.ErrInvalid) {
		t.Fatal("forged cost", err)
	}
	bad := request
	bad.Partners = []int64{9999999}
	if _, err = s.Dispatch(ctx, a, bad, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("foreign/missing hero", err)
	}
	// Drain via the real I5 owner; an unaffordable dispatch must roll back all job effects.
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	spend := opPinned(revision)
	spend.StartedAt = clock.at
	if _, err = s.Values.DebitTemporalTx(ctx, tr, a.PlayerID, i5.WorkplaceSPKey, 50, spend); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Dispatch(ctx, a, request, op()); !errors.Is(err, economy.ErrInsufficientBalance) {
		t.Fatal("insufficient SP", err)
	}
	if workplaceRecord(t, p, a).Sequence != 0 {
		t.Fatal("failed dispatch committed occurrence")
	}
	clock.at = clock.at.Add(1200*time.Second - time.Second)
	sp0, err := s.SP(ctx, a, op())
	if err != nil || fmt.Sprint(sp0["sp"]) != "0" {
		t.Fatal("SP before interval", sp0, err)
	}
	clock.at = clock.at.Add(time.Second)
	sp1, err := s.SP(ctx, a, op())
	if err != nil || fmt.Sprint(sp1["sp"]) != "1" {
		t.Fatal("SP interval", sp1, err)
	}
	clock.at = clock.at.Add(49 * 1200 * time.Second)
	if _, err = s.SP(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	// Search only the production entropy stream, never forge a job or reward.
	start := workplaceOperation(quote, len(job.Chests), false, 1)
	for {
		rng := cd.NewStream(start.Derive("workplace.job-reward/v1", 1))
		if quote.ChestPercent > int64(rng.Uniform(100)) {
			break
		}
		start = workplaceOperation(quote, len(job.Chests), false, 1)
	}
	if _, err = s.Dispatch(ctx, a, request, start); err != nil {
		t.Fatal("dispatch", err)
	}
	first := workplaceRecord(t, p, a).Slots[location.ID]
	if first == nil || first.Attempt != "" {
		t.Fatal("dispatch snapshot", first)
	}
	if _, err = s.Dispatch(ctx, a, request, start); err != nil {
		t.Fatal("exact dispatch retry", err)
	}
	rows, err := (i5store.Store{}).ListMissionInstancesTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	mission := int64(-1)
	for _, row := range rows {
		if row.ObjectiveID == 10017 {
			mission = row.Progress
		}
	}
	if mission != 1 {
		t.Fatal("dispatch mission115", mission)
	}
	chest := first.Lines[len(first.Lines)-1]
	if chest.Kind != grant.StackItem {
		t.Fatal("expected frozen source chest", first.Lines)
	}
	rp, err := (contentstore.Store{}).ResolveResourceTx(ctx, p, revision, chest)
	if err != nil || rp.Stack == nil {
		t.Fatal("source chest policy", err)
	}
	grantGenuine(t, p, a, revision, "workplace-fill-chest", []grant.Line{{Kind: grant.StackItem, ItemID: chest.ItemID, Amount: rp.Stack.StackCap}})
	mails := func() int64 {
		return leagueScalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID))
	}
	mailBefore := mails()
	if _, err = s.Dispatch(ctx, a, request, op()); err != nil {
		t.Fatal("semantic dispatch retry", err)
	}
	if workplaceRecord(t, p, a).Sequence != 1 {
		t.Fatal("duplicate occurrence")
	}
	if _, err = s.SP(ctx, a, op()); err != nil {
		t.Fatal("SP read", err)
	}
	if _, err = s.Log(ctx, a, op()); err != nil {
		t.Fatal("log read", err)
	}
	clock.at = time.Unix(first.Start+first.Quote.Seconds-1, 0).UTC()
	if _, err = s.Claim(ctx, a, location.ID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("due-1", err)
	}
	clock.at = clock.at.Add(time.Second)
	if _, err = s.Claim(ctx, a, location.ID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("due equality", err)
	}
	clock.at = clock.at.Add(time.Second)
	balance := func() int64 {
		b, ok, err := (i5store.Store{}).ReadScalarTx(ctx, p, a.PlayerID, "mana")
		if err != nil {
			t.Fatal("mana", err)
		}
		if !ok {
			return 0
		}
		return b.Amount
	}
	before := balance()
	claim := op()
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	wg.Add(2)
	for _, call := range []operation.Context{claim, op()} {
		go func(call operation.Context) { defer wg.Done(); _, e := s.Claim(ctx, a, location.ID, call); errs <- e }(call)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("concurrent distinct receipts", e)
		}
	}
	after := workplaceRecord(t, p, a)
	if after.Slots[location.ID] != nil || len(after.Diary) != 1 {
		t.Fatal("claim not once", after)
	}
	if balance() != before+first.Quote.Quantity {
		t.Fatal("concurrent duplicate or missing mana grant", before, balance(), first.Quote.Quantity)
	}
	if mails() != mailBefore+1 {
		t.Fatal("overflow Mail not once", mailBefore, mails())
	}
	second := workplaceOperation(quote, len(job.Chests), true, 2)
	if _, err = s.Dispatch(ctx, a, request, second); err != nil {
		t.Fatal("second occurrence", err)
	}
	next := workplaceRecord(t, p, a).Slots[location.ID]
	if next == nil || next.Attempt == "" || next.ID == first.ID {
		t.Fatal("rival attempt absent", next)
	}
	if _, err = s.Claim(ctx, a, location.ID, claim); err != nil {
		t.Fatal("old exact claim replay", err)
	}
	if workplaceRecord(t, p, a).Slots[location.ID].ID != next.ID {
		t.Fatal("old transport replay claimed new slot")
	}
	if _, err = s.Claim(ctx, a, location.ID, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("new slot early claim", err)
	}
	frozen := *next
	clock.at = time.Unix(next.Start+next.Quote.Seconds+1, 0).UTC().Add(48 * time.Hour)
	if _, err = s.Load(ctx, a, op()); err != nil {
		t.Fatal("offline cross-day load", err)
	}
	crossed := workplaceRecord(t, p, a)
	if crossed.Day != modes.Day(clock.at) || crossed.Slots[location.ID].Start != frozen.Start || crossed.Slots[location.ID].Quote != frozen.Quote {
		t.Fatal("daily reset mutated accepted job", crossed)
	}
	sp, err := s.SP(ctx, a, op())
	if err != nil || fmt.Sprint(sp["sp"]) != "50" {
		t.Fatal("offline SP cap", sp, err)
	}
	clock.at = clock.at.Add(-time.Hour)
	if _, err = s.Load(ctx, a, op()); err != nil {
		t.Fatal("backward clock read", err)
	}
	if workplaceRecord(t, p, a).Day != crossed.Day {
		t.Fatal("daily generation rolled back")
	}
	clock.at = clock.at.Add(time.Hour)
	if _, err = s.Claim(ctx, a, location.ID, op()); err != nil {
		t.Fatal("automatic rival claim", err)
	}
	final := workplaceRecord(t, p, a)
	if len(final.Diary) != 2 || fmt.Sprint(final.Diary[0]["with_battle"]) != "1" {
		t.Fatal("rival diary", final.Diary)
	}
	if _, err = s.Load(ctx, a, op()); err != nil {
		t.Fatal("reload", err)
	}
	t.Log("source crew", h.OriginTableID, "team", location.ID, "automatic result", final.Diary[0]["is_win"])
	// Prior owned roster fixtures only; the job, real battle and rival reward are still earned.
	roster := []d.Worker{{PartnerID: h.PartnerID, BaseID: h.OriginTableID, Level: h.Level, Star: h.Star, Color: h.Color, Trait: crew.Trait}}
	request.Partners = []int64{h.PartnerID}
	for i, base := range []int64{10001006, 10001013, 10001018, 10001023} {
		hero := bornHero(t, p, a, revision, base, int64(i+2))
		metadata, _ := cat.Girl(base)
		request.Partners = append(request.Partners, hero.PartnerID)
		roster = append(roster, d.Worker{PartnerID: hero.PartnerID, BaseID: base, Level: hero.Level, Star: hero.Star, Color: hero.Color, Trait: metadata.Trait})
	}
	strongQuote, err := d.Calculate(location, job, roster, cat.VIP[0], cat.Formula)
	if err != nil {
		t.Fatal(err)
	}
	request.SP = strongQuote.SP
	if _, err = s.Dispatch(ctx, a, request, workplaceOperation(strongQuote, len(job.Chests), true, 3)); err != nil {
		t.Fatal("full crew rival", err)
	}
	third := workplaceRecord(t, p, a).Slots[location.ID]
	clock.at = time.Unix(third.Start+third.Quote.Seconds+1, 0).UTC()
	if _, err = s.Claim(ctx, a, location.ID, op()); err != nil {
		t.Fatal("full crew real claim", err)
	}
	won := workplaceRecord(t, p, a).Diary[0]
	if fmt.Sprint(won["is_win"]) != "1" {
		t.Fatal("full crew fixture did not win real resolver", won)
	}
	if award, ok := won["award"].(map[string]any); !ok || len(award["battle_award"].(map[string]any)) == 0 {
		t.Fatal("real win missing reward", won)
	}
}

func TestI9_5BWorkplaceBonusUnlockSameDay(t *testing.T) {
	p := pool(t)
	a, rev := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Minute)}
	s := workplaceMode(t, p, clock)
	s.Timed.Binder.Time = clock
	compositeLevel(t, p, a, rev, 40)
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	before := workplaceRecord(t, p, a)
	if before.BonusLocation != 0 {
		t.Fatal("bonus before level42", before)
	}
	rule, err := (contentstore.Store{}).ResolveProgressionPolicyTx(ctx, p, rev)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_5B_BONUS_UNLOCK", []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[40].TotalExp - rule.Rows[38].TotalExp}}, opPinned(rev)); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	after := workplaceRecord(t, p, a)
	if after.Day != before.Day || after.BonusLocation == 0 {
		t.Fatal("unlock lost until next day", after)
	}
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	again := workplaceRecord(t, p, a)
	if again.BonusLocation != after.BonusLocation || again.BonusBase != after.BonusBase {
		t.Fatal("load rerolled bonus")
	}
}
