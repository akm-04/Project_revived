//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/bookskill"
	dorm "gxb.local/backend/v2/internal/application/dormhouse"
	gen "gxb.local/backend/v2/internal/application/generation"
	i5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func bookService(p *pg.Pool, db tx.Beginner) app.Service {
	cs := contentstore.Store{Queryer: p}
	hs := characterstore.Store{Queryer: p}
	values := i5store.Store{Queryer: p, StackUsage: dorm.FurnitureUsage{Owner: dormstore.Store{}, Content: cs}}
	runner := tx.Runner{DB: db}
	iv := i5.Service{Runner: runner, Store: values, Content: cs, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c2d-native-fixture-only-secret-000")}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Reads: tx.Runner{DB: p}, Heroes: characterstore.LibraryHeroPort{Store: hs}, Owner: bookstore.Store{}, Content: cs, Players: i4store.PlayerRootLocker{}, Fence: values, Costs: i5.MaterialCostDebiter{Store: values, Content: cs}, Values: values, Grants: iv, Exchange: iv, Receipts: kernelstore.Store{}}
}
func bookFixture(t *testing.T, p *pg.Pool) (identity.ActorContext, string, app.Service) {
	t.Helper()
	rev := installed(t, p)
	a := actor(t, p)
	s := bookService(p, p)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	at := time.Now().UTC().Add(-time.Hour)
	if e = (bookstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	if e = (dormstore.Store{}).EnsureRootTx(ctx, tr, a.PlayerID, rev, at); e != nil {
		t.Fatal(e)
	}
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	lines := []grant.Line{}
	for _, k := range []string{"mana", "crystal", "magic_dust", "magic_liquid", "magic_energy", "magic_exp"} {
		lines = append(lines, grant.Line{Kind: grant.ScalarCurrency, ResourceKey: k, Amount: 10000000000})
	}
	lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: 140001001, Amount: 20})
	plan := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2d-fixture", Operation: "canonical-inputs", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: "fixture-v1"}, Lines: lines}
	if _, e = s.Grants.SettleGrantTx(ctx, tr, a, plan, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return a, rev, s
}
func bookCmd(t *testing.T, s app.Service, a identity.ActorContext, c app.Command) app.Result {
	t.Helper()
	r, e := s.Command(ctx, a, c, op())
	if e != nil {
		t.Fatal(c, e)
	}
	return r
}
func bookRoot(t *testing.T, p *pg.Pool, a identity.ActorContext) bookstore.Root {
	t.Helper()
	r, e := (bookstore.Store{}).ReadRootTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	return r
}
func TestI7C2DBookComposeResearchSpeedReplayInputs(t *testing.T) {
	p := pool(t)
	a, rev, s := bookFixture(t, p)
	o := op()
	c := app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1}
	first, e := s.Command(ctx, a, c, o)
	if e != nil {
		t.Fatal(e)
	}
	replay, e := s.Command(ctx, a, c, o)
	if e != nil || replay.OperationID != first.OperationID {
		t.Fatal("receipt", e)
	}
	b1, _ := json.Marshal(first.Body)
	b2, _ := json.Marshal(replay.Body)
	if string(b1) != string(b2) {
		t.Fatal("changed receipt wire")
	}
	stock, e := s.Values.ListStacksTx(ctx, p, a.PlayerID)
	if e != nil {
		t.Fatal(e)
	}
	for _, v := range stock {
		if v.ItemID == 130001001 && v.Quantity != 1 {
			t.Fatal("bookqty", v)
		}
		if v.ItemID == 140001001 && v.Quantity != 0 {
			t.Fatal("fragments", v)
		}
	}
	if _, e = s.Command(ctx, a, c, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("already owned book", e)
	}
	r := bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 10010001})
	if r.Body["cabinet_info"].(map[string]any)["cur_learn_skill"] != int64(10010001) {
		t.Fatal(r)
	}
	root := bookRoot(t, p, a)
	if root.Facts.Skills[10010001] != 0 || root.Facts.Research == nil {
		t.Fatal("early application")
	}
	beforeMana, _, _ := s.Values.ReadScalarTx(ctx, p, a.PlayerID, "mana")
	bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 10010001})
	afterMana, _, _ := s.Values.ReadScalarTx(ctx, p, a.PlayerID, "mana")
	if beforeMana.Amount != afterMana.Amount {
		t.Fatal("double learn cost")
	}
	bookCmd(t, s, a, app.Command{Family: app.SpeedSkill, SkillID: 10010001})
	root = bookRoot(t, p, a)
	if root.Facts.Skills[10010001] != 1 || root.Facts.Research != nil || root.Facts.RecentSkill != 10010001 {
		t.Fatal("speed", root)
	}
	bookCmd(t, s, a, app.Command{Family: app.ConfirmSkill})
	body, e := s.Read(ctx, a, 1059, op())
	if e != nil || len(body["book_info"].(map[string]any)) != 54 {
		t.Fatal(body, e)
	}
	inp, e := s.BookshelfInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()})
	if e != nil || inp.Applied.Skills[10010001] != 1 || inp.Applied.Buildings[4].Level != 1 {
		t.Fatal(inp, e)
	}
}
func TestI7C2DBookPrerequisitesBuildingLadderAndRefund(t *testing.T) {
	p := pool(t)
	a, _, s := bookFixture(t, p)
	bookCmd(t, s, a, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1})
	if _, e := s.Command(ctx, a, app.Command{Family: app.Learn, SkillID: 10010004}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("prerequisite", e)
	}
	bookCmd(t, s, a, app.Command{Family: app.Start, Type: 1})
	root := bookRoot(t, p, a)
	if root.Facts.Buildings[1].Job == nil || root.Facts.Buildings[1].Level != 1 {
		t.Fatal("upgrade early applied")
	}
	bookCmd(t, s, a, app.Command{Family: app.Cancel, Type: 1})
	root = bookRoot(t, p, a)
	if root.Facts.Buildings[1].Job != nil || root.Facts.Buildings[1].Level != 1 {
		t.Fatal("cancel")
	}
	bookCmd(t, s, a, app.Command{Family: app.Start, Type: 1})
	bookCmd(t, s, a, app.Command{Family: app.Speed, Type: 1})
	bookCmd(t, s, a, app.Command{Family: app.Confirm, Type: 1})
	if _, e := s.Command(ctx, a, app.Command{Family: app.Start, Type: 1}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("missingRecyclelevel", e)
	}
	bookCmd(t, s, a, app.Command{Family: app.Start, Type: 3})
	bookCmd(t, s, a, app.Command{Family: app.Speed, Type: 3})
	bookCmd(t, s, a, app.Command{Family: app.Confirm, Type: 3})
	bookCmd(t, s, a, app.Command{Family: app.Start, Type: 1})
	bookCmd(t, s, a, app.Command{Family: app.Cancel, Type: 1})
	bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 10010001})
	bookCmd(t, s, a, app.Command{Family: app.ConfirmSkill})
	bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 10010004})
	if _, e := s.Command(ctx, a, app.Command{Family: app.Start, Type: 1}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("upgrade whilelearning", e)
	}
	bookCmd(t, s, a, app.Command{Family: app.GiveUp, SkillID: 10010004})
	root = bookRoot(t, p, a)
	if root.Facts.Skills[10010004] != 0 || root.Facts.Research != nil {
		t.Fatal("cancel applied skill")
	}
}
func TestI7C2DBookConcurrentCompositionOneProducer(t *testing.T) {
	p := pool(t)
	a, _, s := bookFixture(t, p)
	var wg sync.WaitGroup
	errs := make(chan error, 8)
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, e := s.Command(context.Background(), a, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1}, op())
			errs <- e
		}()
	}
	wg.Wait()
	close(errs)
	success := 0
	for e := range errs {
		if e == nil {
			success++
		} else if !errors.Is(e, app.ErrRejected) && !errors.Is(e, app.ErrStale) {
			t.Fatal(e)
		}
	}
	if success < 1 {
		t.Fatal("no producer")
	}
	var n int64
	if e := p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=130001001`, int64(a.PlayerID)).Scan(&n); e != nil || n != 1 {
		t.Fatal(n, e)
	}
}

var _ operation.Context

func TestI7C2DBookUnknownCommitRollbackAndActor(t *testing.T) {
	p := pool(t)
	for _, committed := range []bool{true, false} {
		a, _, _ := bookFixture(t, p)
		f := &libraryFaultDB{Beginner: p, commit: committed}
		s := bookService(p, f)
		o := op()
		c := app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1}
		_, e := s.Command(ctx, a, c, o)
		if committed {
			if e != nil || dormStack(t, p, a, 130001001) != 1 {
				t.Fatal("positive proof", e)
			}
		} else if e == nil || dormStack(t, p, a, 130001001) != 0 || dormStack(t, p, a, 140001001) != 20 {
			t.Fatal("unknown rollback", e)
		}
		r, e := bookService(p, p).Command(ctx, a, c, o)
		if e != nil || r.OperationID != o.ID || dormStack(t, p, a, 130001001) != 1 || dormStack(t, p, a, 140001001) != 0 {
			t.Fatal("retained recovery", r, e)
		}
	}
	a, _, s := bookFixture(t, p)
	bookCmd(t, s, a, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1})
	exec(t, p, `UPDATE player_currency_balances SET amount=0 WHERE player_id=$1 AND resource_key='magic_dust'`, int64(a.PlayerID))
	before := libraryAmount(t, p, a, "mana")
	if _, e := s.Command(ctx, a, app.Command{Family: app.Learn, SkillID: 10010001}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("insufficient", e)
	}
	if libraryAmount(t, p, a, "mana") != before || bookRoot(t, p, a).Facts.Research != nil {
		t.Fatal("partial loss")
	}
	exec(t, p, `UPDATE gameplay_contexts SET liveness_version=liveness_version+1 WHERE context_id=$1`, a.ContextID.UUID().String())
	if _, e := s.Command(ctx, a, app.Command{Family: app.Start, Type: 4}, op()); e == nil {
		t.Fatal("revoked actor charged")
	}
}
func TestI7C2DBookFullShelfProgressionAndSourceThresholds(t *testing.T) {
	p := pool(t)
	a, rev, s := bookFixture(t, p)
	for level := int64(1); level < 6; level++ {
		bookCmd(t, s, a, app.Command{Family: app.Start, Type: 1})
		bookCmd(t, s, a, app.Command{Family: app.Speed, Type: 1})
		bookCmd(t, s, a, app.Command{Family: app.Confirm, Type: 1})
		if level < 5 {
			bookCmd(t, s, a, app.Command{Family: app.Start, Type: 3})
			bookCmd(t, s, a, app.Command{Family: app.Speed, Type: 3})
			bookCmd(t, s, a, app.Command{Family: app.Confirm, Type: 3})
		}
	}
	for level := int64(2); level <= 100; level++ {
		bookCmd(t, s, a, app.Command{Family: app.Start, Type: 4})
		bookCmd(t, s, a, app.Command{Family: app.Speed, Type: 4})
		bookCmd(t, s, a, app.Command{Family: app.Confirm, Type: 4})
		if level == 50 || level == 80 || level == 100 {
			v, e := s.BookshelfInputsTx(ctx, p, app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()})
			if e != nil || v.Applied.Buildings[4].Level != level || v.OwnerVersion < 2 {
				t.Fatal("threshold", level, v, e)
			}
		}
	}
	if _, e := s.Command(ctx, a, app.Command{Family: app.Start, Type: 4}, op()); !errors.Is(e, app.ErrRejected) {
		t.Fatal("max shelf", e)
	}
}
func TestI7C2DBookMemoirPagesRefundAndRecipeOverrides(t *testing.T) {
	p := pool(t)
	a, rev, s := bookFixture(t, p)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	o := op()
	o.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: rev})
	pl := grant.Plan{PlayerID: a.PlayerID, Source: grant.SourceIdentity{Domain: "i7c2d-fixture", Operation: "memoir-inputs", BusinessKey: fmt.Sprint(a.PlayerID), Occurrence: o.ID.String(), PolicyVersion: "fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 230001001, Amount: 1}, {Kind: grant.StackItem, ItemID: 240001001, Amount: 500}, {Kind: grant.StackItem, ItemID: 140001020, Amount: 40}, {Kind: grant.StackItem, ItemID: 140001021, Amount: 45}}}
	if _, e = s.Grants.SettleGrantTx(ctx, tr, a, pl, o, i5.GrantTxOptions{}); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	c, e := s.Content.BookCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	for l := int64(1); l < 6; l++ {
		bookCmd(t, s, a, app.Command{Family: app.Start, Type: 1})
		bookCmd(t, s, a, app.Command{Family: app.Speed, Type: 1})
		bookCmd(t, s, a, app.Command{Family: app.Confirm, Type: 1})
		if l < 5 {
			bookCmd(t, s, a, app.Command{Family: app.Start, Type: 3})
			bookCmd(t, s, a, app.Command{Family: app.Speed, Type: 3})
			bookCmd(t, s, a, app.Command{Family: app.Confirm, Type: 3})
		}
	}
	if c.Skills[20010003].Book != 230001001 || c.Skills[20010003].Times[5] <= 9000 {
		t.Fatal("source running memoir node")
	}
	for l := 0; l < 6; l++ {
		bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 20010001})
		bookCmd(t, s, a, app.Command{Family: app.ConfirmSkill})
	}
	for l := 0; l < 5; l++ {
		bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 20010003})
		bookCmd(t, s, a, app.Command{Family: app.ConfirmSkill})
	}
	id := int64(20010003)
	beforePages := dormStack(t, p, a, 240001001)
	bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: id})
	used := beforePages - dormStack(t, p, a, 240001001)
	if used <= 0 || bookRoot(t, p, a).Facts.Research == nil {
		t.Fatal("running page debit")
	}
	r := bookCmd(t, s, a, app.Command{Family: app.GiveUp, SkillID: id})
	if r.Body["return_skillpage"] != used || dormStack(t, p, a, 240001001) != beforePages || bookRoot(t, p, a).Facts.Skills[id] != 5 {
		t.Fatal("page refund", r)
	}
	for _, pair := range [][2]int64{{130001020, 140001020}, {130001021, 140001021}} {
		before := libraryAmount(t, p, a, "mana")
		bookCmd(t, s, a, app.Command{Family: app.Compose, ItemID: pair[0], Amount: 1})
		if dormStack(t, p, a, pair[0]) != 1 || dormStack(t, p, a, pair[1]) != 0 || libraryAmount(t, p, a, "mana") != before {
			t.Fatal("approved recipe", pair)
		}
	}
}
func TestI7C2DBookNaturalCompletionPureInputsAndHeroProfiles(t *testing.T) {
	p := pool(t)
	a, rev, s := bookFixture(t, p)
	normal := skillHero(t, p, a, rev, 10001001, 1)
	super := skillHero(t, p, a, rev, 11001, 2)
	bookCmd(t, s, a, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1})
	bookCmd(t, s, a, app.Command{Family: app.Learn, SkillID: 10010001})
	before := bookRoot(t, p, a)
	for until := time.Now().Add(65 * time.Second); ; {
		now := time.Now().UTC()
		if now.Unix() >= before.Facts.Research.StartedAt.Unix()+before.Facts.Research.Duration {
			break
		}
		if time.Now().After(until) {
			t.Fatal("real DB timer expiry")
		}
		time.Sleep(100 * time.Millisecond)
	}
	scope := app.InputScope{Player: a.PlayerID, ContentRevision: rev, ObservedAt: time.Now().UTC()}
	v, e := s.HeroBookInputsTx(ctx, p, scope, normal.Ref())
	if e != nil || v.Skills[10010001] != 1 || !v.Inputs.MaterializationDue || v.Inputs.Stored.Skills[10010001] != 0 {
		t.Fatal("pure due", v, e)
	}
	sv, e := s.HeroBookInputsTx(ctx, p, scope, super.Ref())
	if e != nil || len(sv.Skills) != 0 || sv.Bookshelf.Level != 1 {
		t.Fatal("qualified Super absence/shared shelf", sv, e)
	}
	after := bookRoot(t, p, a)
	if after.Version != before.Version || after.Facts.Research == nil {
		t.Fatal("pure query mutated")
	}
	if _, e = s.Read(ctx, a, 1059, op()); e != nil {
		t.Fatal(e)
	}
	after = bookRoot(t, p, a)
	if after.Facts.Skills[10010001] != 1 || after.Facts.Research != nil || after.Version != before.Version+1 {
		t.Fatal("materialization", after)
	}
	bookCmd(t, s, a, app.Command{Family: app.ConfirmSkill})
	if bookRoot(t, p, a).Facts.Skills[10010001] != 1 {
		t.Fatal("ack erased level")
	}
}

func TestI7C2DBookConcurrentJobTransitions(t *testing.T) {
	p := pool(t)
	a, _, s := bookFixture(t, p)
	bookCmd(t, s, a, app.Command{Family: app.Compose, ItemID: 130001001, Amount: 1})
	race := func(commands []app.Command) {
		var wg sync.WaitGroup
		errs := make(chan error, len(commands))
		for _, c := range commands {
			wg.Add(1)
			go func(c app.Command) { defer wg.Done(); _, e := s.Command(context.Background(), a, c, op()); errs <- e }(c)
		}
		wg.Wait()
		close(errs)
		for e := range errs {
			if e != nil && !errors.Is(e, app.ErrRejected) && !errors.Is(e, app.ErrStale) {
				t.Fatal(e)
			}
		}
	}
	race([]app.Command{{Family: app.Learn, SkillID: 10010001}, {Family: app.Learn, SkillID: 10010001}})
	r := bookRoot(t, p, a)
	if r.Facts.Research == nil || r.Facts.Research.Target != 1 {
		t.Fatal("one research", r)
	}
	race([]app.Command{{Family: app.GiveUp, SkillID: 10010001}, {Family: app.SpeedSkill, SkillID: 10010001}, {Family: app.ConfirmSkill}})
	r = bookRoot(t, p, a)
	if r.Facts.Research != nil || r.Facts.Skills[10010001] > 1 {
		t.Fatal("research race", r)
	}
	race([]app.Command{{Family: app.Start, Type: 4}, {Family: app.Start, Type: 4}})
	r = bookRoot(t, p, a)
	if r.Facts.Buildings[4].Job == nil || r.Facts.Buildings[4].Job.Target != 2 {
		t.Fatal("one building", r)
	}
	race([]app.Command{{Family: app.Cancel, Type: 4}, {Family: app.Speed, Type: 4}, {Family: app.Confirm, Type: 4}})
	r = bookRoot(t, p, a)
	if r.Facts.Buildings[4].Job != nil || r.Facts.Buildings[4].Level > 2 {
		t.Fatal("building race", r)
	}
}
