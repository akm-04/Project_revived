//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/petcampaignstore"
	campaign "gxb.local/backend/v2/internal/application/campaign"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/petcampaign"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	d "gxb.local/backend/v2/internal/domain/petcampaign"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func petCampaignMode(t *testing.T, p *pg.Pool, clock *workplaceTime) app.Mode {
	m := marchMode(t, p)
	owner := m.Grants.(i5.Service)
	awake, _ := i94AwakeningOwners(p)
	owner.Awakening = awake.Awakening
	owner.Missions.Awakening = i5store.Store{Queryer: p}
	fight := combatService(t, p)
	mode := app.Mode{Directory: i4store.PlayerDirectoryReader{}, Timed: m.Timed, Fresh: p, Store: petcampaignstore.Store{}, Content: contentstore.Store{Queryer: p}, Fence: m.Fence, Functions: m.Functions, Heroes: m.Heroes, HeroLocks: m.HeroLocks, Pets: pet.Service{Store: characterstore.Store{Queryer: p}}, Combat: fight, Rules: fight.Rules, Values: owner, Costs: m.Costs, Privileges: owner.Privileges, Facts: i5.ObjectiveFacts{Owner: owner, Open: i5store.Store{Queryer: p}}, Awakening: owner, Receipts: m.Receipts, ReceiptRead: m.ReceiptRead}
	mode.Timed.Binder.Time = clock
	return mode
}
func petCampaignRecord(t *testing.T, p *pg.Pool, a identity.ActorContext) d.State {
	t.Helper()
	r, ok, e := (petcampaignstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if e != nil || !ok {
		t.Fatal(ok, e)
	}
	return r
}
func TestI9_5CTowerNativeProgressAndTimedSweep(t *testing.T) {
	p := pool(t)
	a, rev := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	s := petCampaignMode(t, p, clock)
	if _, e := s.Load(ctx, a, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("gate", e)
	}
	compositeLevel(t, p, a, rev, 100)
	bornHero(t, p, a, rev, 10001001, 1)
	if _, e := s.Load(ctx, a, op()); e != nil {
		t.Fatal("load", e)
	}
	if _, e := s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: 1}, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("without start", e)
	}
	exec(t, p, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	cat, e := (contentstore.Store{}).PetCampaignCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	for n := int64(1); n <= 77; n++ {
		f, _ := cat.Floor(1, n)
		q := app.Fight{Campaign: f.ID, Formation: []int64{1, 0, 0, 0, 0}}
		start := op()
		if _, e = s.Start(ctx, a, q, start); e != nil {
			t.Fatalf("start%d %v", n, e)
		}
		if n == 1 {
			if _, e = s.Start(ctx, a, q, start); e != nil {
				t.Fatal("start retry", e)
			}
			if _, e = s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: 2}, op()); !errors.Is(e, d.ErrRefused) {
				t.Fatal("wrong floor", e)
			}
		}
		result := op()
		out, e := s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: n}, result)
		if e != nil {
			t.Fatalf("win%d %v", n, e)
		}
		if n == 1 {
			again, e := s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: n}, result)
			x, _ := json.Marshal(out)
			y, _ := json.Marshal(again)
			if e != nil || string(x) != string(y) {
				t.Fatal("exact result replay", e)
			}
		}
	}
	r := petCampaignRecord(t, p, a)
	if r.Current != 77 || r.Max != 77 {
		t.Fatal(r)
	}
	if _, e = s.Reset(ctx, a, op()); e != nil {
		t.Fatal("reset", e)
	}
	var attemptsBefore, attemptsAfter int64
	if e = p.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE actor_player_id=$1`, int64(a.PlayerID)).Scan(&attemptsBefore); e != nil {
		t.Fatal(e)
	}
	begin := op()
	if _, e = s.BeginSweep(ctx, a, begin); e != nil {
		t.Fatal("begin", e)
	}
	r = petCampaignRecord(t, p, a)
	if r.Sweep == nil || r.Sweep.From != 1 || r.Sweep.To != 77 || r.Sweep.Due-r.Sweep.Start != 77*60 {
		t.Fatal(r)
	}
	if _, e = s.BeginSweep(ctx, a, op()); e != nil {
		t.Fatal("semantic begin retry", e)
	}
	if _, e = s.Reset(ctx, a, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("reset pending", e)
	}
	if _, e = s.FinishSweep(ctx, a, clock.at.Add(100*time.Hour).Unix(), op()); e == nil {
		t.Fatal("forged finish must not avoid crystal requirement")
	}
	clock.at = time.Unix(r.Sweep.Due, 0).UTC()
	if _, e = s.Detail(ctx, a, op()); e != nil {
		t.Fatal("redpoint", e)
	}
	before := petCampaignRecord(t, p, a)
	if before.Current != 0 || before.Sweep == nil {
		t.Fatal("preview granted")
	}
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	expected := int64(0)
	for _, line := range r.Sweep.Lines {
		if line.Kind == grant.StackItem && line.ItemID == 50001090 {
			expected += line.Amount
		}
	}
	quantity := stackQuantity(t, p, a.PlayerID, 50001090)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.FinishSweep(ctx, a, 0, op()); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("concurrent claim", e)
		}
	}
	if n := stackQuantity(t, p, a.PlayerID, 50001090); n != quantity+expected {
		t.Fatal("concurrent double grant", quantity, expected, n)
	}
	claim := op()
	out, e := s.FinishSweep(ctx, a, 0, claim)
	if e != nil {
		t.Fatal("due claim", e)
	}
	again, e := s.FinishSweep(ctx, a, 0, op())
	if e != nil {
		t.Fatal("semantic claim retry", e)
	}
	x, _ := json.Marshal(out)
	y, _ := json.Marshal(again)
	if string(x) != string(y) {
		t.Fatal("changed receipt", string(x), string(y))
	}
	if e = p.QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE actor_player_id=$1`, int64(a.PlayerID)).Scan(&attemptsAfter); e != nil || attemptsAfter != attemptsBefore {
		t.Fatal("timed sweep must not invoke Combat", attemptsBefore, attemptsAfter, e)
	}
	r = petCampaignRecord(t, p, a)
	if r.Current != 77 || r.Max != 77 || r.Sweep != nil {
		t.Fatal("77 must leave78", r)
	}
	f, _ := cat.Floor(1, 78)
	if _, e = s.Start(ctx, a, app.Fight{Campaign: f.ID, Formation: []int64{1, 0, 0, 0, 0}}, op()); e != nil {
		t.Fatal("next78", e)
	}
	if _, e = s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: 78}, op()); e != nil {
		t.Fatal(e)
	}
	// A backwards clock must not regenerate counters or advance a pending operation.
	clock.at = clock.at.Add(-time.Second)
	if _, e = s.Load(ctx, a, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("backward", e)
	}
	t.Log(fmt.Sprintf("genuine77 victories -> reset ->4620s durable sweep -> next78, revision%s", rev))
}

func seedTowerProgress(t *testing.T, p *pg.Pool, a identity.ActorContext, r d.State, at time.Time) {
	t.Helper()
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	store := petcampaignstore.Store{}
	if _, e = store.LockTx(ctx, tr, a.PlayerID, at); e != nil {
		t.Fatal(e)
	}
	if e = store.SaveTx(ctx, tr, a.PlayerID, r, at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}
func TestI9_5CEliteAndPetMaterialOrigins(t *testing.T) {
	p := pool(t)
	a, rev := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	s := petCampaignMode(t, p, clock)
	compositeLevel(t, p, a, rev, 100)
	bornHero(t, p, a, rev, 10001001, 1)
	if _, e := s.Load(ctx, a, op()); e != nil {
		t.Fatal(e)
	}
	owner := s.Awakening.(i5.Service)
	if _, e := owner.ReadMissions(ctx, a, 1, op()); e != nil {
		t.Fatal("prior lobby mission materialization", e)
	}
	pets := genuinePetService(p)
	content := contentstore.Store{Queryer: p}
	definition, e := content.PetAcquisitionTx(ctx, p, rev, 10010001)
	if e != nil {
		t.Fatal(e)
	}
	grantGenuine(t, p, a, rev, "prior pet egg and premium currency", []grant.Line{{Kind: grant.StackItem, ItemID: definition.EggItemID, Amount: 1}, {Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 10000}})
	ricky := must(pets.Summon(ctx, a, 10010001, op()))(t, "Ricky canonical summon")
	must(pets.CleanCD(ctx, a, ricky.PetID, op()))(t, "Ricky hatch")
	exec(t, p, `UPDATE player_pets SET level=90,color=15,is_show=true WHERE player_id=$1 AND pet_id=$2`, int64(a.PlayerID), ricky.PetID)
	if _, e := owner.ChangeAwakening(ctx, a, "open", 10001001, 3, op()); e != nil {
		t.Fatal("open pet mission", e)
	}
	r := petCampaignRecord(t, p, a)
	r.Max = 79
	r.Current = 79
	seedTowerProgress(t, p, a, r, clock.at) // Declared prior79 clears; tested floor80 must use genuine START/RESULT.
	if _, e := s.Start(ctx, a, app.Fight{Campaign: 30080, Formation: []int64{1}}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: 80}, op()); e != nil {
		t.Fatal(e)
	}
	if n := stackQuantity(t, p, a.PlayerID, 100001036); n != 1 {
		t.Fatal("source normal80 pet fragment", n)
	}
	// Freeze an active occurrence, cancel/reopen it, then accept its old terminal: no stale fragment may transfer.
	r = petCampaignRecord(t, p, a)
	r.Current = 79
	seedTowerProgress(t, p, a, r, clock.at)
	if _, e := s.Start(ctx, a, app.Fight{Campaign: 30080, Formation: []int64{1}}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := owner.ChangeAwakening(ctx, a, "cancel", 10001001, 3, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := owner.ChangeAwakening(ctx, a, "open", 10001001, 3, op()); e != nil {
		t.Fatal(e)
	}
	before := stackQuantity(t, p, a.PlayerID, 100001036)
	if _, e := s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: 80}, op()); e != nil {
		t.Fatal(e)
	}
	if n := stackQuantity(t, p, a.PlayerID, 100001036); n != before {
		t.Fatal("stale occurrence leaked", before, n)
	}
	r = petCampaignRecord(t, p, a)
	if _, e := s.Reset(ctx, a, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := s.BeginSweep(ctx, a, op()); e != nil {
		t.Fatal(e)
	}
	job := petCampaignRecord(t, p, a).Sweep
	clock.at = time.Unix(job.Due, 0).UTC()
	if _, e := s.FinishSweep(ctx, a, 0, op()); e != nil {
		t.Fatal(e)
	}
	if n := stackQuantity(t, p, a.PlayerID, 100001036); n != 1 {
		t.Fatal("reopened occurrence sweep fragment", n)
	}
	for n := 0; n < 16; n++ {
		call := op()
		if _, e := s.AwakeSweep(ctx, a, 80, call); e != nil {
			t.Fatal("paid awakening fragment", n, e)
		}
		if _, e := s.AwakeSweep(ctx, a, 80, call); e != nil {
			t.Fatal("exact material retry", e)
		}
	}
	if _, e := s.AwakeSweep(ctx, a, 80, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("17th awakening raid", e)
	}
	if n := stackQuantity(t, p, a.PlayerID, 100001036); n != 17 {
		t.Fatal("one fragment per paid material action", n)
	}
	r = petCampaignRecord(t, p, a)
	r.Max = 99
	r.Current = 99
	seedTowerProgress(t, p, a, r, clock.at) // Prior progress fixture; actual unlock is a new accepted floor100 terminal.
	if _, e := s.Start(ctx, a, app.Fight{Campaign: 30100, Formation: []int64{1}}, op()); e != nil {
		t.Fatal(e)
	}
	if _, e := s.Result(ctx, a, app.Result{Win: true, Kind: 1, Floor: 100}, op()); e != nil {
		t.Fatal(e)
	}
	tickets := stackQuantity(t, p, a.PlayerID, 50001328)
	if tickets != 15 {
		t.Fatal("explicit5 plus policy-extra10", tickets)
	}
	grantGenuine(t, p, a, rev, "practice prior resource fixture", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 100000}})
	if _, e := s.Start(ctx, a, app.Fight{Campaign: 230001, Formation: []int64{1}, Practice: true}, op()); e != nil {
		t.Fatal("practice", e)
	}
	if stackQuantity(t, p, a.PlayerID, 50001328) != tickets {
		t.Fatal("practice ticket")
	}
	if _, e := s.EliteSweep(ctx, a, 230001, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("uncleared raid", e)
	}
	start := op()
	if _, e := s.Start(ctx, a, app.Fight{Campaign: 230001, Formation: []int64{1}}, start); e != nil {
		t.Fatal(e)
	}
	if _, e := s.Start(ctx, a, app.Fight{Campaign: 230001, Formation: []int64{1}}, start); e != nil {
		t.Fatal(e)
	}
	if stackQuantity(t, p, a.PlayerID, 50001328) != tickets-1 {
		t.Fatal("exact START double charged")
	}
	if _, e := s.Result(ctx, a, app.Result{Win: true, Kind: 2, Floor: 1}, op()); e != nil {
		t.Fatal(e)
	}
	for i := 0; i < 3; i++ {
		call := op()
		if _, e := s.EliteSweep(ctx, a, 230001, call); e != nil {
			t.Fatal("raid", i, e)
		}
		if _, e := s.EliteSweep(ctx, a, 230001, call); e != nil {
			t.Fatal("exact elite retry", e)
		}
	}
	if _, e := s.EliteSweep(ctx, a, 230001, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("fourth free raid", e)
	}
	buy := op()
	if _, e := s.BuyElite(ctx, a, 1, buy); e != nil {
		t.Fatal("buy3", e)
	}
	if _, e := s.BuyElite(ctx, a, 1, buy); e != nil {
		t.Fatal("exact buy retry", e)
	}
	if _, e := s.BuyElite(ctx, a, 1, op()); !errors.Is(e, d.ErrRefused) {
		t.Fatal("buy while full", e)
	}
	if _, e := s.SaveElite(ctx, a, 0, 2, op()); e != nil {
		t.Fatal(e)
	}
	reloaded, e := s.Load(ctx, a, op())
	if e != nil || reloaded["super"].(map[string]any)["max_floor"] != int64(1) {
		t.Fatal(reloaded, e)
	}

	// Stage1 equipment is an explicit prior-crafting fixture, not a claim that this test earned30 fragments.
	// The new source producer above earns real fragments; the final challenge below must use real Cloud START/RESULT.
	pets.Awakening = characterstore.Store{Queryer: p}
	pets.AwakeningEquipment = &owner
	owner.Awakening.Pets = pets
	grantGenuine(t, p, a, rev, "prior crafted unique gear", []grant.Line{{Kind: grant.StackItem, ItemID: 80001073, Amount: 1}})
	var slot int64
	for n := int64(1); n <= character.PetEquipmentSlotCount; n++ {
		position, e := content.PetEquipmentPositionTx(ctx, p, rev, 10010001, 15, n)
		if e != nil {
			t.Fatal(e)
		}
		if int64(position.ItemID) == 80001073 {
			slot = n
		}
	}
	if slot == 0 {
		t.Fatal("Ricky awakening gear source missing")
	}
	if _, e := pets.EquipItem(ctx, a, ricky.PetID, slot, op()); e != nil {
		t.Fatal("real gear completion", e)
	}
	if _, e := owner.ChangeAwakening(ctx, a, "claim", 10001001, 3, op()); e != nil {
		t.Fatal("stage1 claim", e)
	}
	cloud := campaignMode(t, p)
	cloud.Awakening = owner
	cloud.PetAwakening = owner
	cc, e := content.CampaignCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	group, ok := cc.Group(41)
	if !ok {
		t.Fatal("Avenue missing")
	}
	day := modes.Day(clock.at)
	for !group.Scheduled(cc, day) {
		day++
	}
	cloudAt := modes.DayBegins(day).Add(8 * time.Hour)
	if cloudAt.Before(clock.at) {
		cloudAt = clock.at
	}
	cloud.Timed.Binder.Time = &leagueClock{at: cloudAt}
	for _, id := range []int64{41001, 41002} {
		if _, e := cloud.Fight(ctx, a, campaign.Fight{CampaignID: id, Type: 41, PetFormation: []int64{ricky.PetID}}, op()); e != nil {
			t.Fatal("Cloud start", id, e)
		}
		marker := int64(0)
		if id == 41002 {
			marker = 10001002
		}
		if _, e := cloud.Result(ctx, a, campaign.Result{CampaignID: id, Type: 41, Star: 1, PetAwakeMission: marker}, op()); e != nil {
			t.Fatal("Cloud accepted pet goal", id, e)
		}
	}
	root, e := (i5store.Store{}).ReadAwakeningTx(ctx, p, a.PlayerID)
	if e != nil || !root.Active[2].Complete {
		t.Fatal("genuine final missing", root, e)
	}
	if _, e := owner.ChangeAwakening(ctx, a, "claim", 10001002, 3, op()); e != nil {
		t.Fatal("pet final claim", e)
	}
	actual, e := (characterstore.Store{}).ReadPetByIDTx(ctx, p, a.PlayerID, ricky.PetID)
	if e != nil || actual.TableID != 110010001 {
		t.Fatal("same pet awakening persisted", actual, e)
	}
	board, e := s.RankList(ctx, a, op())
	if e != nil || len(board["rank_list"].([]map[string]any)) != 1 {
		t.Fatal("rank22", board, e)
	}
}

func TestI9_5CTimedPaidFinishUsesServerClock(t *testing.T) {
	ctx, _ := changes.Track(ctx)
	p := pool(t)
	a, rev := bornActor(t, p), installed(t, p)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	s := petCampaignMode(t, p, clock)
	compositeLevel(t, p, a, rev, 100)
	if _, e := s.Load(ctx, a, op()); e != nil {
		t.Fatal(e)
	}
	r := petCampaignRecord(t, p, a)
	r.Max = 2
	seedTowerProgress(t, p, a, r, clock.at) // Declared prior best; this test covers paid collection only.
	owner := s.Values.(i5.Service)
	if _, e := owner.ReadMissions(ctx, a, 1, op()); e != nil {
		t.Fatal("stock mission precondition", e)
	}
	grantGenuine(t, p, a, rev, "prior paid finish balance", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 100}})
	balance := func() int64 {
		return leagueScalar(t, p, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	}
	before := balance()
	begin := op()
	if _, e := s.BeginSweep(ctx, a, begin); e != nil {
		t.Fatal(e)
	}
	if _, e := s.BeginSweep(ctx, a, begin); e != nil {
		t.Fatal("begin retry", e)
	}
	exec(t, p, `DELETE FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID))
	if _, e := s.FinishSweep(ctx, a, 0, op()); !errors.Is(e, economy.ErrInsufficientBalance) {
		t.Fatal("missing qualified currency is zero", e)
	}
	grantGenuine(t, p, a, rev, "restore paid finish balance", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: before}})
	claim := op()
	if _, e := s.FinishSweep(ctx, a, clock.at.Add(24*time.Hour).Unix(), claim); e != nil {
		t.Fatal(e)
	}
	if _, e := s.FinishSweep(ctx, a, clock.at.Add(24*time.Hour).Unix(), claim); e != nil {
		t.Fatal("exact paid retry", e)
	}
	if before-balance() != 20 || petCampaignRecord(t, p, a).Current != 2 {
		t.Fatal("server clock price or duplicate debit", before, balance())
	}
}
