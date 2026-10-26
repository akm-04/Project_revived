//go:build postgres

package missions_test

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
	"sync"
	"testing"
	"time"
)

// VIP and starting count are explicit canonical fixture state, not proof of earned VIP or elapsed login days.
func TestSignInNativeBonusReplayConcurrentAndCalendar(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	at := time.Date(2026, 10, 26, 12, 0, 0, 0, time.UTC)
	actor := runtimeActor(t, p, at)
	clock := &missionClock{at: at}
	service := runtimeService(p, clock)
	store := i5store.Store{Queryer: p}
	content := contentstore.Store{Queryer: p}
	service.SignIn = &i5.SignInRuntime{Store: store, Content: content}
	loaded, err := service.ReadSignIn(ctx, actor, runtimeOperation(t, at))
	if err != nil {
		t.Fatal(err)
	}
	if loaded["sign_times"] != int64(0) || loaded["is_signed"] != int64(0) || loaded["month"] != int64(10) {
		t.Fatal(loaded)
	}
	// Earn the first two calendar rows through the owner, then exercise day3's source VIP1 bonus.
	for range 2 {
		if _, err = service.ClaimSignIn(ctx, actor, runtimeOperation(t, clock.at)); err != nil {
			t.Fatal(err)
		}
		clock.at = clock.at.Add(24 * time.Hour)
	}
	at = clock.at
	op := runtimeOperation(t, at)
	first, err := service.ClaimSignIn(ctx, actor, op)
	if err != nil {
		t.Fatal(err)
	}
	if first["sign_times"] != int64(3) || first["is_signed"] != int64(1) {
		t.Fatal(first)
	}
	award := first["award"].(map[string]any)
	item := award["table_id"].(int64)
	amount := award["item_num"].(int64)
	replay, err := service.ClaimSignIn(ctx, actor, op)
	if err != nil || replay["sign_times"] != int64(3) {
		t.Fatal(replay, err)
	}
	if _, err = service.ClaimSignIn(ctx, actor, runtimeOperation(t, at)); !errors.Is(err, objective.ErrSignRefused) {
		t.Fatal("VIP0 bonus", err)
	}
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	vipCatalog, err := content.PrivilegeCatalogTx(ctx, tr, catalog.RevisionID())
	if err != nil {
		t.Fatal(err)
	}
	state := privilege.State{PlayerID: actor.PlayerID, LogicalServerID: actor.LogicalServerID, Charge: vipCatalog.Rows[1].Charge, VIPLevel: 1, MonthlyState: privilege.MonthlyAbsent, ContentRevision: catalog.RevisionID(), PolicyVersion: privilege.ManualPolicy, OriginClass: privilege.ManualClass, Issuer: "signin-native-fixture", Reason: "same-day upgrade test", StateVersion: 1, CreatedAt: at, UpdatedAt: at}
	if err = (commerceprivilegestore.Store{}).SavePrivilegeTx(ctx, tr, 0, state); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for range 2 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := service.ClaimSignIn(ctx, actor, runtimeOperation(t, at))
			errs <- err
		}()
	}
	wg.Wait()
	close(errs)
	success, refused := 0, 0
	for err := range errs {
		if err == nil {
			success++
		} else if errors.Is(err, objective.ErrSignRefused) {
			refused++
		} else {
			t.Fatal(err)
		}
	}
	if success != 1 || refused != 1 {
		t.Fatal("bonus concurrency", success, refused)
	}
	var got int64
	if err = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(actor.PlayerID), item).Scan(&got); err != nil || got != 2*amount {
		t.Fatal("reward custody", got, err)
	}
	root, err := store.ReadSignInTx(ctx, p, actor.PlayerID)
	if err != nil || root.Count != 3 || root.Signed != 2 {
		t.Fatal(root, err)
	}
	// Exact operation replay remains the original outcome after the entitlement has advanced.
	if _, err = service.ClaimSignIn(ctx, actor, op); err != nil {
		t.Fatal(err)
	}
	clock.at = at.Add(24 * time.Hour)
	next, err := service.ReadSignIn(ctx, actor, runtimeOperation(t, clock.at))
	if err != nil || next["is_signed"] != int64(0) || next["sign_times"] != int64(3) {
		t.Fatal("new day", next, err)
	}
	pinned := runtimeOperation(t, clock.at)
	pinned.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: "d9b1c731a9efc936ab2cbadfda84d64177196d9329902d763a2b97b6c56b117d"})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.ClaimSignIn(ctx, actor, pinned); err != nil {
		t.Fatal("pinned month after admission revision change", err)
	}
	clock.at = time.Date(2026, 10, 31, 20, 59, 59, 0, time.UTC)
	before, err := service.ReadSignIn(ctx, actor, runtimeOperation(t, clock.at))
	if err != nil || before["month"] != int64(10) {
		t.Fatal(before, err)
	}
	clock.at = clock.at.Add(time.Second)
	after, err := service.ReadSignIn(ctx, actor, runtimeOperation(t, clock.at))
	if err != nil || after["month"] != int64(11) || after["sign_times"] != int64(0) {
		t.Fatal("F7 month", after, err)
	}
	clock.at = clock.at.Add(-time.Second)
	if _, err = service.ReadSignIn(ctx, actor, runtimeOperation(t, clock.at)); !errors.Is(err, objective.ErrSignRefused) {
		t.Fatal("backward day", err)
	}
}

func TestSignInNativeMissingContentAndDeploymentVerification(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	bundle, err := registry.LoadBuiltinBundle()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	content := contentstore.Store{}
	if _, err = tr.Exec(ctx, `DELETE FROM content_monthly_signin_catalogs WHERE revision_id=$1`, bundle.RevisionID()); err != nil {
		t.Fatal(err)
	}
	if _, err = content.SignInCatalogTx(ctx, tr, bundle.RevisionID()); err == nil {
		t.Fatal("missing catalog accepted")
	}
	verified, err := content.VerifyRevision(ctx, tr, bundle)
	if err != nil {
		t.Fatal(err)
	}
	if verified.Exact {
		t.Fatal("missing catalog passed content verification")
	}
}

type signFailStore struct{ i5store.Store }

func (s signFailStore) SaveSignInTx(context.Context, tx.Tx, identity.PlayerID, objective.SignRoot, int64) error {
	return errors.New("injected sign root write failure")
}

type signLostDB struct {
	tx.Beginner
	injected bool
}
type signLostTx struct{ tx.Tx }

func (d *signLostDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	tr, err := d.Beginner.Begin(c, o)
	if err != nil {
		return nil, err
	}
	if !d.injected {
		d.injected = true
		return signLostTx{tr}, nil
	}
	return tr, nil
}
func (t signLostTx) Commit(c context.Context) error {
	if err := t.Tx.Commit(c); err != nil {
		return err
	}
	return errors.New("injected lost sign-in COMMIT reply")
}
func TestSignInNativeRollbackAndLostCommit(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	at := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	actor := runtimeActor(t, p, at)
	clock := &missionClock{at: at}
	s := runtimeService(p, clock)
	store := i5store.Store{Queryer: p}
	s.SignIn = &i5.SignInRuntime{Store: store, Content: contentstore.Store{Queryer: p}}
	if _, err := s.ReadSignIn(ctx, actor, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	broken := s
	copyRuntime := *s.SignIn
	copyRuntime.Store = signFailStore{store}
	broken.SignIn = &copyRuntime
	if _, err := broken.ClaimSignIn(ctx, actor, runtimeOperation(t, at)); err == nil {
		t.Fatal("injected failure ignored")
	}
	root, err := store.ReadSignInTx(ctx, p, actor.PlayerID)
	if err != nil || root.Count != 0 {
		t.Fatal("failed claim changed root", root, err)
	}
	var stacks int64
	if err = p.QueryRow(ctx, `SELECT count(*) FROM player_item_stacks WHERE player_id=$1`, int64(actor.PlayerID)).Scan(&stacks); err != nil || stacks != 0 {
		t.Fatal("failed claim leaked value", stacks, err)
	}
	s.Runner.DB = &signLostDB{Beginner: p}
	op := runtimeOperation(t, at)
	if _, err = s.ClaimSignIn(ctx, actor, op); err != nil {
		t.Fatal("lost committed reply recovery", err)
	}
	if _, err = s.ClaimSignIn(ctx, actor, op); err != nil {
		t.Fatal(err)
	}
	root, err = store.ReadSignInTx(ctx, p, actor.PlayerID)
	if err != nil || root.Count != 1 {
		t.Fatal("lost commit duplicate", root, err)
	}
}

// This fixture selects the recovered2015 full-Hero award; active D89 calendars currently award skin items instead.
type signHeroCatalog struct{ contentstore.Store }

func (c signHeroCatalog) SignInCatalogTx(ctx context.Context, q tx.Queryer, revision string) (objective.SignCatalog, error) {
	catalog, err := c.Store.SignInCatalogTx(ctx, q, revision)
	if err != nil {
		return catalog, err
	}
	for i := range catalog.Months {
		catalog.Months[i].Awards[0] = objective.SignAward{ItemID: 10001033, ItemNum: 1, Crystal: -1, DoubleVIP: -1}
	}
	return catalog, catalog.Validate()
}
func TestSignInNativeSourceHeroFreshFacetsAndDuplicate(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	at := time.Date(2026, 10, 27, 12, 0, 0, 0, time.UTC)
	a := runtimeActor(t, p, at)
	clock := &missionClock{at: at}
	s := runtimeService(p, clock)
	content := contentstore.Store{Queryer: p}
	heroes := characterstore.Store{Queryer: p}
	s.SignIn = &i5.SignInRuntime{Store: i5store.Store{Queryer: p}, Content: signHeroCatalog{content}, Heroes: characterhero.Service{AcquisitionStore: heroes, Acquisition: content, CollectionAdmission: characterhero.CatalogCollectionAdmission{Content: content}, FreshFacets: characterbirth.FreshHeroFacets()}, HeroWire: heroproj.StockHero}
	if _, err := s.ReadSignIn(ctx, a, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	admission := runtimeOperation(t, at)
	admission.Policies, _ = policy.NewSet(policy.Ref{Name: "content", Version: "d9b1c731a9efc936ab2cbadfda84d64177196d9329902d763a2b97b6c56b117d"})
	body, err := s.ClaimSignIn(ctx, a, admission)
	if err != nil {
		t.Fatal(err)
	}
	award := body["award"].(map[string]any)
	if award["is_partner"] != true {
		t.Fatal(body)
	}
	var count int64
	if err = p.QueryRow(ctx, `SELECT count(*) FROM player_heroes WHERE player_id=$1 AND table_id=10001033`, int64(a.PlayerID)).Scan(&count); err != nil || count != 1 {
		t.Fatal("fresh Hero", count, err)
	}
	// A new source month with the same Hero converts through the existing Vending fragment policy.
	clock.at = time.Date(2026, 11, 2, 12, 0, 0, 0, time.UTC)
	body, err = s.ClaimSignIn(ctx, a, runtimeOperation(t, clock.at))
	if err != nil {
		t.Fatal(err)
	}
	award = body["award"].(map[string]any)
	if award["to_stone"] != true {
		t.Fatal("duplicate did not convert", body)
	}
	root, err := (i5store.Store{}).ReadSignInTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	summons, err := content.SummonCatalogTx(ctx, p, root.ContentRevision)
	if err != nil {
		t.Fatal(err)
	}
	stone, err := summons.Fragments(10001033)
	if err != nil {
		t.Fatal(err)
	}
	var qty int64
	if err = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), stone[0]).Scan(&qty); err != nil || qty != stone[1] {
		t.Fatal("duplicate shard custody", qty, err)
	}
	if err = p.QueryRow(ctx, `SELECT count(*) FROM player_heroes WHERE player_id=$1 AND table_id=10001033`, int64(a.PlayerID)).Scan(&count); err != nil || count != 1 {
		t.Fatal("duplicate Hero created", count, err)
	}
}

func TestSignInNativeCrystalAwardWireAndCustody(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	at := time.Date(2026, 11, 1, 12, 0, 0, 0, time.UTC)
	a := runtimeActor(t, p, at)
	clock := &missionClock{at: at}
	s := runtimeService(p, clock)
	content := contentstore.Store{Queryer: p}
	s.SignIn = &i5.SignInRuntime{Store: i5store.Store{Queryer: p}, Content: content}
	revision, err := content.ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := content.SignInCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	month, err := catalog.Month(11)
	if err != nil {
		t.Fatal(err)
	}
	var before int64
	if err = p.QueryRow(ctx, `SELECT COALESCE((SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'),0)`, int64(a.PlayerID)).Scan(&before); err != nil {
		t.Fatal(err)
	}
	for _, award := range month.Awards {
		body, err := s.ClaimSignIn(ctx, a, runtimeOperation(t, clock.at))
		if err != nil {
			t.Fatal(err)
		}
		if award.Crystal > 0 {
			wire := body["award"].(map[string]any)
			if wire["table_id"] != int64(-1) || wire["item_num"] != award.Crystal || wire["to_stone"] != false {
				t.Fatal("Crystal wire", body)
			}
			var after int64
			if err = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&after); err != nil || after-before != award.Crystal {
				t.Fatal("Crystal custody", before, after, err)
			}
			if body["economy_"] == nil {
				t.Fatal("Crystal balance sideband missing", body)
			}
			return
		}
		clock.at = clock.at.Add(24 * time.Hour)
	}
	t.Fatal("source month lacks Crystal proof row")
}
