//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	appboot "gxb.local/backend/v2/internal/application/bootstrap"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	gen "gxb.local/backend/v2/internal/application/generation"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func dormService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	hs := characterstore.Store{Queryer: p}
	owner := dormstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: app.FurnitureUsage{Owner: owner, Content: cs}}
	runner := tx.Runner{DB: db}
	exchange := i5.Service{Runner: runner, Store: values, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c2c-fixture-redeem-key-000000000")}
	exp := hero.Service{ProgressionStore: hs, Progression: cs}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Reads: tx.Runner{DB: p}, Heroes: characterstore.LibraryHeroPort{Store: hs}, Owner: owner, Content: cs, Players: i4store.PlayerRootLocker{}, Fence: values, Costs: i5.MaterialCostDebiter{Store: values, Content: cs}, Values: values, EXP: exp, Exchange: exchange, Receipts: kernelstore.Store{}}
}

// Explicit canonical prerequisite fixtures qualify Dorm conditional behavior,
// not Campaign progression or the unresolved production HeroCapacity policy.
func dormFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, dorm.Catalog) {
	t.Helper()
	rev := installed(t, p)
	a := actor(t, p)
	h := skillHero(t, p, a, rev, 10001001, 1)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	owner := dormstore.Store{}
	at := time.Now().UTC().Add(-time.Hour)
	if e = owner.EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	if e = owner.InitFreshHeroTx(ctx, tr, h.Ref(), at); e != nil {
		t.Fatal(e)
	}
	if e = (librarystore.Store{}).EnsurePlayerRootTx(ctx, tr, a.PlayerID, at); e != nil {
		t.Fatal(e)
	}
	if _, e = (librarystore.Store{}).BackfillMissingHeroTx(ctx, tr, h.Ref(), at); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_progression SET level=100 WHERE player_id=$1`, int64(a.PlayerID))
	for _, f := range []int64{71, 72, 73, 74} {
		exec(t, p, `INSERT INTO player_function_unlocks(player_id,function_id,source_fact_key,opened_at,state_version)VALUES($1,$2,$3,clock_timestamp()-interval '1 hour',1)`, int64(a.PlayerID), f, fmt.Sprint("i7c2c-explicit-campaign-prerequisite-", f))
	}
	c, e := (contentstore.Store{}).DormCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	for item := range c.Keys {
		skillBook(t, p, a, item)
		exec(t, p, `UPDATE player_item_stacks SET quantity=20 WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), item)
	}
	for _, item := range []int64{50005163, 50005164, 50005165, 50005167, 50031013} {
		skillBook(t, p, a, item)
		exec(t, p, `UPDATE player_item_stacks SET quantity=$3 WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), item, func() int64 {
			if item == 50005167 {
				return 1000
			}
			if item == 50031013 {
				return 10
			}
			return 20
		}())
	}
	return a, rev, c
}
func dormCommand(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Result {
	t.Helper()
	r, e := s.Command(ctx, a, c, op())
	if e != nil {
		t.Fatal(c, e)
	}
	return r
}
func dormKey(c dorm.Catalog, typ int64, random bool) int64 {
	for id, k := range c.Keys {
		if k.MainType == typ && (len(k.Templates) > 1) == random {
			return id
		}
	}
	panic("key absent")
}
func dormOpen(t *testing.T, s app.Service, a identity.ActorContext, c dorm.Catalog, typ, pos int64) int64 {
	t.Helper()
	dormCommand(t, s, a, app.Command{Family: app.Open, ItemID: dormKey(c, typ, false), Floor: 1, Position: pos})
	rooms, e := s.Owner.ListRoomsTx(ctx, s.Reads.DB.(*pg.Pool), a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	for _, r := range rooms {
		if r.MainType == typ && r.Position == pos {
			return r.ID
		}
	}
	t.Fatal("open missing")
	return 0
}
func dormStack(t *testing.T, p *pg.Pool, a identity.ActorContext, item int64) int64 {
	t.Helper()
	var n int64
	if e := p.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(a.PlayerID), item).Scan(&n); e != nil {
		t.Fatal(e)
	}
	return n
}
func TestI7C2CCommandsOwnershipCostsReplayAndProviders(t *testing.T) {
	p := pool(t)
	a, rev, c := dormFixture(t, p)
	s := dormService(p, p)
	key := dormKey(c, 2, true)
	cmd := app.Command{Family: app.Open, ItemID: key, Floor: 1, Position: 1}
	o := op()
	r, e := s.Command(ctx, a, cmd, o)
	if e != nil {
		t.Fatal(e)
	}
	rooms, e := s.Owner.ListRoomsTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	var id int64
	for _, x := range rooms {
		if x.MainType == 2 {
			id = x.ID
		}
	}
	if id == 0 || dormStack(t, p, a, key) != 19 {
		t.Fatal("one key/room", rooms)
	}
	retained, e := s.Command(ctx, a, cmd, o)
	if e != nil || retained.OperationID != r.OperationID || dormStack(t, p, a, key) != 19 {
		t.Fatal("replay", retained, e)
	}
	if _, e = s.Command(ctx, a, cmd, op()); !errors.Is(e, app.ErrRejected) || dormStack(t, p, a, key) != 19 {
		t.Fatal("occupied slot charged", e)
	}
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: id, Partners: []int64{1}})
	f, e := s.DormHouseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil || f.Room == nil || f.Room.ID != id {
		t.Fatal(f, e)
	}
	// Assignment converges even in its cooldown; movement out of source does not.
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: id, Partners: []int64{1}})
	if _, e = s.Command(ctx, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{1}}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("source cooldown", e)
	}
	exec(t, p, `UPDATE player_dorm_rooms SET last_enter_at=clock_timestamp()-interval '2 days' WHERE player_id=$1`, int64(a.PlayerID))
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{1}})
	room, e := s.Owner.ReadRoomTx(ctx, p, a.PlayerID, id)
	if e != nil {
		t.Fatal(e)
	}
	layout := map[string]string{}
	for k, v := range room.Layout {
		layout[k] = v
	}
	layout["50031013#4#1#0"] = ""
	dormCommand(t, s, a, app.Command{Family: app.Save, HouseID: id, Furniture: layout})
	before := dormStack(t, p, a, 50031013)
	if before != 10 {
		t.Fatal("placement consumed stock", before)
	}
	invalid := map[string]string{"50031013#1#1#0": ""}
	if _, e = s.Command(ctx, a, app.Command{Family: app.Save, HouseID: id, Furniture: invalid}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("removed dresser", e)
	}
	// Exchange is source-defined, atomic, and historical receipt doesn't debit again.
	var exchangeKey, rate int64
	for k, v := range c.ExchangeRates {
		exchangeKey = k
		rate = v
		break
	}
	beforeExchangeKey := dormStack(t, p, a, exchangeKey)
	cement := dormStack(t, p, a, 50005167)
	o = op()
	ec := app.Command{Family: app.Exchange, ItemID: exchangeKey, Amount: 2}
	if _, e = s.Command(ctx, a, ec, o); e != nil {
		t.Fatal("exchange", e)
	}
	if dormStack(t, p, a, exchangeKey) != beforeExchangeKey-2 || dormStack(t, p, a, 50005167) != cement+2*rate {
		t.Fatal("exchange vector")
	}
	if _, e = s.Command(ctx, a, ec, o); e != nil || dormStack(t, p, a, exchangeKey) != beforeExchangeKey-2 {
		t.Fatal("exchange replay", e)
	}
	villa := dormOpen(t, s, a, c, 4, 1)
	count, e := s.VillaCountTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()})
	if e != nil || count.Count != 1 {
		t.Fatal("unoccupied villa count", count, e)
	}
	dormCommand(t, s, a, app.Command{Family: app.Start, HouseID: villa})
	v, e := s.Owner.ReadRoomTx(ctx, p, a.PlayerID, villa)
	if e != nil || v.Pending == nil || v.ExpansionLevel != 0 {
		t.Fatal(v, e)
	}
	crystal := libraryAmount(t, p, a, "crystal")
	dormCommand(t, s, a, app.Command{Family: app.Finish, HouseID: villa})
	if libraryAmount(t, p, a, "crystal") != crystal-500 {
		t.Fatal("early finish ceil price")
	}
	dormCommand(t, s, a, app.Command{Family: app.Finish, HouseID: villa})
	if libraryAmount(t, p, a, "crystal") != crystal-500 {
		t.Fatal("finish twice")
	}
	for _, mid := range []uint16{2512, 2514} {
		if _, e = s.Read(ctx, a, op(), mid, 0, id); e != nil {
			t.Fatal(mid, e)
		}
	}
	exec(t, p, `DELETE FROM player_function_unlocks WHERE player_id=$1 AND function_id=73`, int64(a.PlayerID))
	if _, e = s.Command(ctx, a, app.Command{Family: app.Open, ItemID: dormKey(c, 3, false), Floor: 1, Position: 1}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("level substituted for function", e)
	}
}
func TestI7C2CLoungeFractionsCapOldComfortForeignAndNaturalExpansion(t *testing.T) {
	p := pool(t)
	a, _, c := dormFixture(t, p)
	s := dormService(p, p)
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{1}})
	exec(t, p, `UPDATE player_dorm_heroes SET lounge_anchor=clock_timestamp()-interval '11 hours' WHERE player_id=$1`, int64(a.PlayerID))
	body, e := s.Read(ctx, a, op(), 2514, 0, 1)
	if e != nil {
		t.Fatal(e)
	}
	h := skillRead(t, p, a, 1)
	if h.Exp != 600 {
		t.Fatal("10h bound", h.Exp, body)
	}
	exec(t, p, `UPDATE player_dorm_heroes SET lounge_anchor=clock_timestamp()-interval '30 seconds' WHERE player_id=$1`, int64(a.PlayerID))
	before := h.Exp
	dormCommand(t, s, a, app.Command{Family: app.Save, HouseID: 1, Furniture: map[string]string{"50031013#1#1#0": ""}})
	h = skillRead(t, p, a, 1)
	if h.Exp != before {
		t.Fatal("fraction discarded", h.Exp, before)
	}
	f, e := s.Owner.ReadHeroTx(ctx, p, h.Ref())
	if e != nil || f.LoungeFraction <= 0 {
		t.Fatal("fraction", f, e)
	}
	other, _, _ := dormFixture(t, p)
	anchor := f.LoungeAnchor
	if _, e = s.Read(ctx, other, op(), 2514, int64(a.PlayerID), 1); e != nil {
		t.Fatal("foreign", e)
	}
	f, e = s.Owner.ReadHeroTx(ctx, p, h.Ref())
	if e != nil || f.LoungeAnchor != anchor {
		t.Fatal("foreign payout", e)
	}
	// Leaving retains the fraction; re-enter starts a fresh anchor.
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{}})
	f, e = s.Owner.ReadHeroTx(ctx, p, h.Ref())
	if e != nil || !f.LoungeAnchor.IsZero() || f.LoungeFraction == 0 {
		t.Fatal(f, e)
	}
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: 1, Partners: []int64{1}})
	villa := dormOpen(t, s, a, c, 4, 1)
	dormCommand(t, s, a, app.Command{Family: app.Start, HouseID: villa})
	exec(t, p, `UPDATE player_dorm_rooms SET pending_expansion=jsonb_set(pending_expansion,'{StartedAt}',to_jsonb((clock_timestamp()-interval '2 hours')::text)) WHERE player_id=$1 AND house_id=$2`, int64(a.PlayerID), villa)
	// Timestamp fixture must retain the integer-second occurrence rule.
	exec(t, p, `UPDATE player_dorm_rooms SET pending_expansion=jsonb_set(pending_expansion,'{StartedAt}',to_jsonb(date_trunc('second',clock_timestamp()-interval '2 hours'))) WHERE player_id=$1 AND house_id=$2`, int64(a.PlayerID), villa)
	crystal := libraryAmount(t, p, a, "crystal")
	if _, e = s.Read(ctx, a, op(), 2514, 0, villa); e != nil {
		t.Fatal(e)
	}
	v, e := s.Owner.ReadRoomTx(ctx, p, a.PlayerID, villa)
	if e != nil || v.Pending != nil || v.ExpansionLevel != 1 || libraryAmount(t, p, a, "crystal") != crystal {
		t.Fatal("natural", v, e)
	}
	thresholds, e := (contentstore.Store{}).HeroExpPolicyTx(ctx, p, catalogRevision(s, p, t), 100)
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_heroes SET level=100,exp=$2 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID), thresholds[len(thresholds)-1].TotalExp)
	exec(t, p, `UPDATE player_dorm_heroes SET lounge_anchor=clock_timestamp()-interval '2 hours',lounge_fraction=1 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	if _, e = s.Read(ctx, a, op(), 2514, 0, 1); e != nil {
		t.Fatal("cap", e)
	}
	f, e = s.Owner.ReadHeroTx(ctx, p, h.Ref())
	if e != nil || f.LoungeFraction != 0 {
		t.Fatal("cap bank", f, e)
	}
	exec(t, p, `UPDATE player_dorm_heroes SET lounge_anchor=clock_timestamp()+interval '1 hour' WHERE player_id=$1`, int64(a.PlayerID))
	if _, e = s.Read(ctx, a, op(), 2514, 0, 1); e == nil {
		t.Fatal("backward anchor")
	}
}
func TestI7C2CUnknownCommitRetainedAdmissionAndConcurrentSlot(t *testing.T) {
	p := pool(t)
	for _, committed := range []bool{true, false} {
		a, _, c := dormFixture(t, p)
		fault := &libraryFaultDB{Beginner: p, commit: committed}
		s := dormService(p, fault)
		o := op()
		key := dormKey(c, 2, true)
		cmd := app.Command{Family: app.Open, ItemID: key, Floor: 1, Position: 1}
		_, e := s.Command(ctx, a, cmd, o)
		if committed {
			if e != nil || dormStack(t, p, a, key) != 19 {
				t.Fatal("positive commit", e)
			}
		} else {
			if e == nil || dormStack(t, p, a, key) != 20 {
				t.Fatal("unknown absence replay", e)
			}
		}
		retry := op()
		if committed {
			retry = o
		}
		out, e := dormService(p, p).Command(ctx, a, cmd, retry)
		if e != nil || dormStack(t, p, a, key) != 19 {
			t.Fatal("retained recovery", out, e)
		}
		if out.OperationID != o.ID && !committed {
			t.Fatal("retained op lost")
		}
	}
	a, _, c := dormFixture(t, p)
	s := dormService(p, p)
	key := dormKey(c, 2, true)
	var wg sync.WaitGroup
	fail := make(chan error, 6)
	for i := 0; i < 6; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(context.Background(), a, app.Command{Family: app.Open, ItemID: key, Floor: 1, Position: 1}, op())
			if e != nil && !errors.Is(e, app.ErrRejected) {
				fail <- e
			}
		}()
	}
	wg.Wait()
	close(fail)
	for e := range fail {
		t.Fatal(e)
	}
	if dormStack(t, p, a, key) != 19 {
		t.Fatal("concurrent duplicate", fmt.Sprint(dormStack(t, p, a, key)))
	}
}

func catalogRevision(s app.Service, p *pg.Pool, t *testing.T) string {
	t.Helper()
	rev, active, e := s.Content.DormInputsActive(ctx)
	if e != nil || !active {
		t.Fatal(rev, e)
	}
	return rev
}

func TestI7C2CEquipmentGatesRetainedGearAtomicCostsAndConcurrentMoves(t *testing.T) {
	p := pool(t)
	a, rev, c := dormFixture(t, p)
	s := dormService(p, p)
	id := dormOpen(t, s, a, c, 2, 1)
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: id, Partners: []int64{1}})
	equip := app.Command{Family: app.Equip, HouseID: id, Index: 1}
	if _, e := s.Command(ctx, a, equip, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("color/level gate", e)
	}
	// Explicit evolved canonical Hero fixture; no promotion writer acceptance.
	exec(t, p, `UPDATE player_heroes SET color=16,level=99 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	item := c.Equipment[10001001].Items[0]
	skillBook(t, p, a, item)
	r := dormCommand(t, s, a, equip)
	if dormStack(t, p, a, item) != 0 {
		t.Fatal("equipment debit", r)
	}
	dormCommand(t, s, a, equip)
	if dormStack(t, p, a, item) != 0 {
		t.Fatal("equipment double charge")
	}
	exec(t, p, `UPDATE player_dorm_rooms SET last_enter_at=clock_timestamp()-interval '2 days' WHERE player_id=$1`, int64(a.PlayerID))
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: id, Partners: []int64{}})
	inputs, e := s.DormHouseInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}, character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1})
	if e != nil || inputs.Room != nil || inputs.Facts.Equipment[0] != 1 || inputs.GrowthBP != (dorm.AttributesBP{}) {
		t.Fatal("inactive retained gear", inputs, e)
	}
	// Super exception does not inherit Normal's color16 gate.
	h := skillHero(t, p, a, rev, 11001, 2)
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = s.Owner.(dormstore.Store).InitFreshHeroTx(ctx, tr, h.Ref(), time.Now().UTC().Add(-time.Hour)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_heroes SET level=99 WHERE player_id=$1 AND partner_id=2`, int64(a.PlayerID))
	exec(t, p, `UPDATE player_dorm_rooms SET last_enter_at=clock_timestamp()-interval '2 days' WHERE player_id=$1`, int64(a.PlayerID))
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: id, Partners: []int64{2}})
	superItem := c.Equipment[11001].Items[0]
	skillBook(t, p, a, superItem)
	dormCommand(t, s, a, equip)
	if dormStack(t, p, a, superItem) != 0 {
		t.Fatal("Super gate")
	}
	// Deficient expansion must leave all costs, occurrence and applied level alone.
	villa := dormOpen(t, s, a, c, 4, 1)
	exec(t, p, `UPDATE player_item_stacks SET quantity=199 WHERE player_id=$1 AND item_id=50005167`, int64(a.PlayerID))
	permit := dormStack(t, p, a, 50005163)
	if _, e = s.Command(ctx, a, app.Command{Family: app.Start, HouseID: villa}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("deficient expansion", e)
	}
	v, e := s.Owner.ReadRoomTx(ctx, p, a.PlayerID, villa)
	if e != nil || v.Pending != nil || v.ExpansionLevel != 0 || dormStack(t, p, a, 50005163) != permit {
		t.Fatal("partial cost", v, e)
	}
	exec(t, p, `UPDATE player_dorm_rooms SET last_enter_at=clock_timestamp()-interval '2 days' WHERE player_id=$1`, int64(a.PlayerID))
	other := dormOpen(t, s, a, c, 2, 2)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for _, target := range []int64{other, 1} {
		wg.Add(1)
		go func(target int64) {
			defer wg.Done()
			_, e := s.Command(context.Background(), a, app.Command{Family: app.Enter, HouseID: target, Partners: []int64{2}}, op())
			if e != nil && !errors.Is(e, app.ErrRejected) {
				errs <- e
			}
		}(target)
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		t.Fatal(e)
	}
	rooms, e := s.Owner.ListRoomsTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	found := 0
	for _, r := range rooms {
		for _, p := range r.Residents {
			if p == 2 {
				found++
			}
		}
	}
	if found != 1 {
		t.Fatal("membership graph duplicated", rooms)
	}
}

func TestI7C2CStockConsumptionVersusPlacementAndRemovalGuard(t *testing.T) {
	p := pool(t)
	a, _, c := dormFixture(t, p)
	s := dormService(p, p)
	room := dormOpen(t, s, a, c, 2, 1)
	exec(t, p, `UPDATE player_item_stacks SET quantity=1 WHERE player_id=$1 AND item_id=50031013`, int64(a.PlayerID))
	r, e := s.Owner.ReadRoomTx(ctx, p, a.PlayerID, room)
	if e != nil {
		t.Fatal(e)
	}
	layout := r.Layout
	layout["50031013#4#1#0"] = ""
	values := s.Values.(i5store.Store)
	cs := contentstore.Store{Queryer: p}
	inv := i5.Service{Runner: tx.Runner{DB: p}, Store: values, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c2c-fixture-redeem-key-000000000")}
	var wg sync.WaitGroup
	wg.Add(2)
	go func() {
		defer wg.Done()
		s.Command(context.Background(), a, app.Command{Family: app.Save, HouseID: room, Furniture: layout}, op())
	}()
	go func() {
		defer wg.Done()
		inv.AdjustStack(context.Background(), a, grant.SourceIdentity{Domain: "i7c2c-stock-race", Operation: "consume", BusinessKey: fmt.Sprint(a.PlayerID), PolicyVersion: "fixture-v1"}, 50031013, -1, op())
	}()
	wg.Wait()
	minimum, e := (app.FurnitureUsage{Owner: s.Owner, Content: cs}).MinimumRetainedStackTx(ctx, p, a.PlayerID, 50031013)
	if e != nil || dormStack(t, p, a, 50031013) < minimum {
		t.Fatal("placed above stock", minimum, e)
	}
	// Actual reference port, not a claim that a deferred retirement route exists.
	dormCommand(t, s, a, app.Command{Family: app.Enter, HouseID: room, Partners: []int64{1}})
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	hs := characterstore.Store{}
	if _, e = hs.LockRootTx(ctx, tr, a.PlayerID); e != nil {
		t.Fatal(e)
	}
	if _, e = hs.LockHeroByPartnerIDTx(ctx, tr, a.PlayerID, 1); e != nil {
		t.Fatal(e)
	}
	guard := dormstore.Store{}
	ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
	plan, e := guard.PreflightHeroRemovalTx(ctx, tr, ref)
	if e != nil {
		t.Fatal(e)
	}
	for _, key := range plan.Locks {
		if e = guard.LockReferenceGuardKeyTx(ctx, tr, key); e != nil {
			t.Fatal(e)
		}
	}
	if e = guard.ValidateHeroRemovalLockedTx(ctx, tr, ref, plan); e == nil {
		t.Fatal("resident removal permitted")
	}
}

func TestI7C2CFreshBootstrapAndActualAcquisitionRequiredFacets(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	cs := contentstore.Store{Queryer: p}
	hs := characterstore.Store{Queryer: p}
	owner := dormstore.Store{}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	b := logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: op()}
	for _, port := range []appboot.CharacterBootstrapPersistenceContributor{characterstore.BootstrapContributor{}, librarystore.BootstrapContributor{}, dormstore.BootstrapContributor{Revision: rev}} {
		if e = port.PersistCharacterBootstrap(ctx, tr, b); e != nil {
			t.Fatal(e)
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	inv := i5store.Store{Queryer: p, StackUsage: app.FurnitureUsage{Owner: owner, Content: cs}}
	svc := hero.Service{FreshFacets: hero.FreshFacetChain{librarystore.Store{}, owner}, Runner: tx.Runner{DB: p}, Store: hs, Fencer: inv, Content: cs, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AcquisitionStore: hs, Acquisition: cs, Progression: cs, MaterialCosts: i5.MaterialCostDebiter{Store: inv, Content: cs}, PlayerLevel: i5.CrossOwner{Store: inv}, Capacity: skillTestCapacity{}}
	policy, e := cs.HeroNormalSummonTx(ctx, p, rev, 10001001)
	if e != nil {
		t.Fatal(e)
	}
	skillBook(t, p, a, policy.Template.FragmentItemID)
	exec(t, p, `UPDATE player_item_stacks SET quantity=$2 WHERE player_id=$1 AND item_id=$3`, int64(a.PlayerID), policy.FragmentCount, policy.Template.FragmentItemID)
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',100000000,1,clock_timestamp()-interval '1 hour')`, int64(a.PlayerID))
	original := op()
	h, e := svc.SummonNormal(ctx, a, 10001001, policy.Template.FragmentItemID, policy.FragmentCount, original)
	if e != nil {
		t.Fatal(e)
	}
	f, e := owner.ReadHeroTx(ctx, p, h.Ref())
	if e != nil || f.HouseID != 0 || f.Equipment != ([5]int64{}) {
		t.Fatal("new facet", f, e)
	}
	if _, e = (librarystore.Store{}).ReadHeroTx(ctx, p, h.Ref()); e != nil {
		t.Fatal("Library dropped", e)
	}
	if _, e = svc.SummonNormal(ctx, a, 10001001, policy.Template.FragmentItemID, policy.FragmentCount, original); e != nil {
		t.Fatal("acquisition replay", e)
	}
	root, e := owner.ReadRootTx(ctx, p, a.PlayerID)
	if e != nil || root.NextHouseID != 2 {
		t.Fatal(root, e)
	}
}

func TestI7C2CConcurrentResidentAdmissionVersusGuardedRemoval(t *testing.T) {
	p := pool(t)
	a, _, c := dormFixture(t, p)
	s := dormService(p, p)
	house := dormOpen(t, s, a, c, 2, 1)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	wg.Add(2)
	go func() {
		defer wg.Done()
		_, e := s.Command(context.Background(), a, app.Command{Family: app.Enter, HouseID: house, Partners: []int64{1}}, op())
		if e != nil && !errors.Is(e, app.ErrRejected) {
			errs <- e
		}
	}()
	go func() {
		defer wg.Done()
		tr, e := p.Begin(context.Background(), tx.Options{Isolation: tx.Serializable})
		if e != nil {
			errs <- e
			return
		}
		defer tr.Rollback(context.Background())
		hs := characterstore.Store{}
		if _, e = hs.LockRootTx(context.Background(), tr, a.PlayerID); e != nil {
			errs <- e
			return
		}
		if _, e = hs.LockHeroByPartnerIDTx(context.Background(), tr, a.PlayerID, 1); e != nil {
			return
		}
		ref := character.HeroRef{PlayerID: a.PlayerID, PartnerID: 1}
		guard := dormstore.Store{}
		plan, e := guard.PreflightHeroRemovalTx(context.Background(), tr, ref)
		if e != nil {
			errs <- e
			return
		}
		for _, k := range plan.Locks {
			if e = guard.LockReferenceGuardKeyTx(context.Background(), tr, k); e != nil {
				return
			}
		}
		if e = guard.ValidateHeroRemovalLockedTx(context.Background(), tr, ref, plan); e != nil {
			return
		}
		// Test-only canonical removal fixture following the actual guard. There is
		// no currently enabled production retirement/consumption route to qualify.
		if _, e = tr.Exec(context.Background(), `DELETE FROM player_heroes WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID)); e != nil {
			errs <- e
			return
		}
		tr.Commit(context.Background())
	}()
	wg.Wait()
	close(errs)
	for e := range errs {
		t.Fatal(e)
	}
	var deadResident int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM player_dorm_heroes d LEFT JOIN player_heroes h USING(player_id,partner_id) WHERE d.player_id=$1 AND d.house_id IS NOT NULL AND h.partner_id IS NULL`, int64(a.PlayerID)).Scan(&deadResident); e != nil || deadResident != 0 {
		t.Fatal("dangling live residency", deadResident, e)
	}
}

func TestI7C2CKeyExchangeOverflowAndActorGate(t *testing.T) {
	p := pool(t)
	a, _, c := dormFixture(t, p)
	s := dormService(p, p)
	exec(t, p, `UPDATE player_item_stacks SET quantity=9999 WHERE player_id=$1 AND item_id=50005167`, int64(a.PlayerID))
	var key, rate int64
	for k, r := range c.ExchangeRates {
		key = k
		rate = r
		break
	}
	before := dormStack(t, p, a, key)
	o := op()
	cmd := app.Command{Family: app.Exchange, ItemID: key, Amount: 1}
	if _, e := s.Command(ctx, a, cmd, o); e != nil {
		t.Fatal("overflow exchange", e)
	}
	if dormStack(t, p, a, key) != before-1 || dormStack(t, p, a, 50005167) != 9999 {
		t.Fatal("overflow quantities")
	}
	var count int64
	if e := p.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID)).Scan(&count); e != nil || count != 1 {
		t.Fatal("overflow Mail", count, rate, e)
	}
	if _, e := s.Command(ctx, a, cmd, o); e != nil {
		t.Fatal("overflow replay", e)
	}
	if e := p.QueryRow(ctx, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1`, int64(a.PlayerID)).Scan(&count); e != nil || count != 1 {
		t.Fatal("duplicate overflow", count, e)
	}
	exec(t, p, `UPDATE account_sessions SET revoked_at=clock_timestamp(),revocation_reason='i7c2c-test',liveness_version=liveness_version+1 WHERE session_id=$1::uuid`, a.SessionID.UUID().String())
	if _, e := s.Command(ctx, a, app.Command{Family: app.Open, ItemID: dormKey(c, 2, false), Floor: 1, Position: 1}, op()); e == nil {
		t.Fatal("revoked actor succeeded")
	}
}
