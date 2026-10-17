//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	ps "gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	cp "gxb.local/backend/v2/internal/application/commerceprivilege"
	ds "gxb.local/backend/v2/internal/application/directorysync"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	d "gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"os"
	"reflect"
	"sync"
	"testing"
	"time"
)

func privilegeProvider(p *pg.Pool) cp.Provider {
	return cp.Provider{Store: ps.Store{}, Content: contentstore.Store{Queryer: p}}
}
func privilegeService(p *pg.Pool, db tx.Beginner) cp.Service {
	return cp.Service{Runner: tx.Runner{DB: db}, Fresh: p, Time: pg.AuthoritativeTime{Queryer: p}, Players: i4store.PlayerRootLocker{}, Store: ps.Store{}, Content: contentstore.Store{Queryer: p}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Effects: i5.PrivilegeTransitionOwner{Store: i5store.Store{}, Content: contentstore.Store{Queryer: p}}, Directory: i4store.DirectoryLevelProjection{}, Audit: audit.NopEmitter{}}
}
func privilegeActor(t *testing.T, p *pg.Pool, rev string) identity.ActorContext {
	a := actor(t, p)
	exec(t, p, `DELETE FROM player_economy_owners WHERE player_id=$1`, int64(a.PlayerID))
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	b := logicalserver.BootstrapContext{PlayerID: a.PlayerID, Operation: opPinned(rev)}
	if e = (i5store.EconomyOwnerBootstrapContributor{Content: contentstore.Store{Queryer: p}, Privileges: privilegeProvider(p)}).PersistCharacterBootstrap(ctx, tr, b); e != nil {
		t.Fatal(e)
	}
	if e = (characterstore.BootstrapContributor{}).PersistCharacterBootstrap(ctx, tr, b); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	return a
}
func authority() cp.Authority {
	return cp.Authority{Operator: i5.AdminOperator{ID: "preservation-native", ReasonCode: "explicit-user-snapshot"}, Capability: d.ManualCapability, PolicyVersion: d.ManualPolicy}
}
func importQ(a identity.ActorContext, key string, charge int64) cp.Import {
	return cp.Import{PlayerID: a.PlayerID, LogicalServerID: a.LogicalServerID, CommandKey: key, Charge: charge, MonthlyState: d.MonthlyAbsent}
}
func display4a(p *pg.Pool) app.Service {
	s := service(p, p)
	s.CosmeticPrivileges = privilegeProvider(p)
	s.Privileges = privilegeProvider(p)
	s.Population = characterstore.DisplayReader{Store: characterstore.Store{Queryer: p}, Content: contentstore.Store{Queryer: p}}
	s.Inventory = i5store.Store{}
	return s
}
func facts4a(t *testing.T, p *pg.Pool, a identity.ActorContext, rev, family string) app.EligibilityObservation {
	t.Helper()
	var out app.EligibilityObservation
	_, e := (tx.Runner{DB: p}).Run(ctx, opPinned(rev), i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, s tx.Scope) error {
		at, e := (pg.AuthoritativeTime{Queryer: s.Tx}).Now(c)
		if e != nil {
			return e
		}
		sc, e := ca.NewCoherentReadScope(s, rev, at)
		if e != nil {
			return e
		}
		out, e = display4a(p).ReadEligibilityTx(c, sc, app.EligibilityRequest{PlayerID: a.PlayerID, Family: family})
		return e
	})
	if e != nil {
		t.Fatal(e)
	}
	return out
}
func fact4a(t *testing.T, o app.EligibilityObservation, id, category int64) app.EligibilityFact {
	t.Helper()
	for _, f := range o.Facts {
		if f.CatalogID == id && f.Category == category {
			return f
		}
	}
	t.Fatal("missingfact", id, category)
	return app.EligibilityFact{}
}
func TestI7C4ANativeManualCanonicalReplayConsumers(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := privilegeActor(t, p, rev)
	s := privilegeService(p, p)
	pr := privilegeProvider(p)
	if _, e := pr.ReadCosmeticPrivilegeTx(ctx, p, a.PlayerID, rev, time.Now()); !errors.Is(e, d.ErrUnavailable) {
		t.Fatal("missingroot becameVIP0", e)
	}
	x, e := pr.SnapshotTx(ctx, p, a.PlayerID, time.Now())
	if e != nil || x.VIPLevel != 0 {
		t.Fatal("named legacycompat", x, e)
	}
	q := importQ(a, uuid().String(), 3000)
	r, e := s.ImportManual(ctx, authority(), q, op())
	if e != nil || r.State.VIPLevel != 5 || r.State.StateVersion != 1 || !r.Changed {
		t.Fatal(r, e)
	}
	first := r
	r, e = s.ImportManual(ctx, authority(), q, op())
	if e != nil || !reflect.DeepEqual(first, r) {
		t.Fatal("exactreplay", r, e)
	}
	// Replay must precede discovery of current content, even if that route fails.
	replay := s
	replay.Content = unavailableManualContent{Content: s.Content}
	if _, e = replay.ImportManual(ctx, authority(), q, op()); e != nil {
		t.Fatal("replayreboundcontent", e)
	}
	x, e = pr.SnapshotTx(ctx, p, a.PlayerID, time.Now())
	if e != nil || x.VIPLevel != 5 || x.SkillPointNaturalCap != 20 || x.MonthlyPrivilegeActive {
		t.Fatal(x, e)
	}
	snap, e := pr.ReadCosmeticPrivilegeTx(ctx, p, a.PlayerID, rev, time.Now())
	if e != nil || snap.State.Charge != 3000 {
		t.Fatal(snap, e)
	}
	detail := map[string]any{"17": map[string]any{"vip": int64(0), "charge": int64(0)}}
	if e = (cp.BootstrapProjection{Provider: pr}).OverlayMID1(ctx, p, a, false, time.Now(), detail); e != nil || detail["17"].(map[string]any)["vip"] != int64(5) {
		t.Fatal(detail, e)
	}
	var vip, version int64
	if e = p.QueryRow(ctx, `SELECT vip,state_version FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)).Scan(&vip, &version); e != nil || vip != 5 || version != 2 {
		t.Fatal(vip, version, e)
	}
	q.CommandKey = uuid().String()
	r, e = s.ImportManual(ctx, authority(), q, op())
	if e != nil || r.Changed || r.State.StateVersion != 1 {
		t.Fatal("noop", r, e)
	}
	q.Charge = 2999
	q.CommandKey = uuid().String()
	if _, e = s.ImportManual(ctx, authority(), q, op()); e == nil {
		t.Fatal("decrease")
	}
	q = first.Request
	other := privilegeActor(t, p, rev)
	q.PlayerID = other.PlayerID
	if _, e = s.ImportManual(ctx, authority(), q, op()); e == nil {
		t.Fatal("issuerkeyretarget")
	}
	q = first.Request
	q.Charge++
	if _, e = s.ImportManual(ctx, authority(), q, op()); e == nil {
		t.Fatal("receiptchangedcharge")
	}
	bad := authority()
	bad.Operator.ReasonCode = "different"
	if _, e = s.ImportManual(ctx, bad, first.Request, op()); e == nil {
		t.Fatal("changedreason")
	}
	bad = authority()
	bad.Capability = "client.claim"
	if _, e = s.ImportManual(ctx, bad, importQ(other, uuid().String(), 3000), op()); e == nil {
		t.Fatal("unauthorized")
	}
	q = importQ(other, uuid().String(), 3000)
	q.MonthlyState = ""
	if _, e = s.ImportManual(ctx, authority(), q, op()); e == nil {
		t.Fatal("monthlyunknown")
	}
	// Source VIP frames use qualified facts, never the compatibility baseline.
	catalog, e := (contentstore.Store{}).ReadPlayerDisplayCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	for _, v := range catalog.Cosmetics {
		if v.Family == "frame" && v.Type == 6 && v.VIP <= 5 {
			if _, e = display4a(p).Execute(ctx, a, app.Command{Kind: "frame", ID: v.ID}, op()); e != nil {
				t.Fatal("VIPselection", e)
			}
			break
		}
	}
	o := facts4a(t, p, a, rev, "frame")
	if o.Privilege == nil || o.Privilege.State.VIPLevel != 5 || o.CompleteFamily {
		t.Fatal(o)
	}
	// I5's existing display directory reconciliation must preserve Commerce VIP.
	if _, e = display4a(p).Execute(ctx, a, app.Command{Kind: "rename", Name: "VIPName"}, op()); e != nil {
		t.Fatal(e)
	}
	if e = p.QueryRow(ctx, `SELECT vip FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)).Scan(&vip); e != nil || vip != 5 {
		t.Fatal(vip, e)
	}
}

type unavailableManualContent struct {
	cp.ManualContent
	Content cp.ManualContent
}

func (u unavailableManualContent) PrivilegeCatalogTx(c context.Context, q tx.Queryer, r string) (d.Catalog, error) {
	return u.Content.PrivilegeCatalogTx(c, q, r)
}
func (unavailableManualContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return "", errors.New("activation unavailable")
}

type manualFaultDB struct {
	tx.Beginner
	commit bool
}

func (d manualFaultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	return faultTx{Tx: t, commit: d.commit}, nil
}

type failDirectory struct{ ds.VIPProjectionPort }
type failProjection struct{ ds.PreparedVIPProjection }

func (f failProjection) Apply(c context.Context, t tx.Tx) error {
	if e := f.PreparedVIPProjection.Apply(c, t); e != nil {
		return e
	}
	return errors.New("after-directory-fault")
}
func (f failDirectory) PrepareVIPProjectionTx(c context.Context, t tx.Tx, p identity.PlayerID, v int64, at time.Time) (ds.PreparedVIPProjection, error) {
	x, e := f.VIPProjectionPort.PrepareVIPProjectionTx(c, t, p, v, at)
	return failProjection{x}, e
}
func TestI7C4ANativeAtomicRollbackUnknownAndConcurrency(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	for _, commit := range []bool{false, true} {
		a := privilegeActor(t, p, rev)
		s := privilegeService(p, manualFaultDB{Beginner: p, commit: commit})
		r, e := s.ImportManual(ctx, authority(), importQ(a, uuid().String(), 3000), op())
		if commit {
			if e != nil || r.State.VIPLevel != 5 {
				t.Fatal("positiveACKproof", r, e)
			}
		} else {
			var unknown *tx.UnknownCommitError
			if !errors.As(e, &unknown) {
				t.Fatal("negativeACKmissmustunresolved", e)
			}
			_, ok, e := (ps.Store{}).ReadPrivilegeTx(ctx, p, a.PlayerID, false)
			if e != nil || ok {
				t.Fatal("negativeunexpectedstate", ok, e)
			}
		}
	}
	a := privilegeActor(t, p, rev)
	s := privilegeService(p, p)
	s.Directory = failDirectory{s.Directory}
	q := importQ(a, uuid().String(), 3000)
	if _, e := s.ImportManual(ctx, authority(), q, op()); e == nil {
		t.Fatal("faultdidnotabort")
	}
	_, ok, e := (ps.Store{}).ReadPrivilegeTx(ctx, p, a.PlayerID, false)
	if e != nil || ok {
		t.Fatal("partialprivilege", ok, e)
	}
	var vip, n int64
	if e = p.QueryRow(ctx, `SELECT vip FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)).Scan(&vip); e != nil || vip != 0 {
		t.Fatal("partialdirectory", vip, e)
	}
	if e = p.QueryRow(ctx, `SELECT state_version FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID)).Scan(&n); e != nil || n != 1 {
		t.Fatal("partialtemporal", n, e)
	}
	s = privilegeService(p, p)
	var wg sync.WaitGroup
	errs := make(chan error, 6)
	for i := 0; i < 6; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.ImportManual(ctx, authority(), q, op()); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal("samekeyconcurrency", e)
		}
	}
	st, ok, e := (ps.Store{}).ReadPrivilegeTx(ctx, p, a.PlayerID, false)
	if e != nil || !ok || st.StateVersion != 1 {
		t.Fatal(st, e)
	}
}
func TestI7C4ANativeOldCapSettlementAndPausedRearm(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	for _, paused := range []bool{false, true} {
		a := privilegeActor(t, p, rev)
		var at time.Time
		if e := p.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&at); e != nil {
			t.Fatal(e)
		}
		// Qualified baseline state fixture. Nonbaseline VIP still enters only through ImportManual.
		var anchor any = at.Add(-time.Hour)
		if paused {
			anchor = nil
		}
		exec(t, p, `UPDATE player_temporal_resources SET stored_amount=9,regen_anchor_at=$2,updated_at=$3 WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID), anchor, at.Add(-time.Hour))
		s := privilegeService(p, p)
		s.Time = fixedManualTime{at}
		r, e := s.ImportManual(ctx, authority(), importQ(a, uuid().String(), 3000), op())
		if e != nil {
			t.Fatal(r, e)
		}
		var amount, version int64
		var next *time.Time
		if e = p.QueryRow(ctx, `SELECT stored_amount,regen_anchor_at,state_version FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID)).Scan(&amount, &next, &version); e != nil {
			t.Fatal(e)
		}
		want := int64(10)
		if paused {
			want = 9
		}
		if amount != want || version != 2 || next == nil || !next.Equal(at) {
			t.Fatal("oldcapthennewcap", paused, amount, version, next, at)
		}
	}
}

type fixedManualTime struct{ at time.Time }

func (f fixedManualTime) Now(context.Context) (time.Time, error) { return f.at, nil }
func TestI7C4ANativeCoreFactsPurchaseSourceCA7AndFailClosed(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := privilegeActor(t, p, rev)
	s := display4a(p)
	before := facts4a(t, p, a, rev, "avatar")
	if fact4a(t, before, 110005001, 5).Status != app.Ineligible || fact4a(t, before, 110006001, 5).Status != app.Unavailable {
		t.Fatal("canonicalabsence/timedunknown")
	}
	if _, e := s.Execute(ctx, a, app.Command{Kind: "purchase", ID: 110005001}, op()); e != nil {
		t.Fatal(e)
	}
	after := facts4a(t, p, a, rev, "avatar")
	if fact4a(t, after, 110005001, 5).Status != app.Eligible || after.PopulationDigest == before.PopulationDigest {
		t.Fatal("actual656purchase")
	}
	// Canonical Hero fixture distinguishes the reader boundary from acquisition policy.
	// CA7 SkinOn below is the real item debit, entitlement, Hero CAS and receipt path.
	h := skillHero(t, p, a, rev, 10001144, 11)
	skillBook(t, p, a, 50000000)
	hs := characterstore.Store{Queryer: p}
	cs := contentstore.Store{Queryer: p}
	iv := i5store.Store{Queryer: p}
	skin := hero.Service{Runner: tx.Runner{DB: p}, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: hs, Fencer: iv, Content: cs, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AppearanceMutationStore: hs, AppearanceMutationContent: cs, MaterialCosts: i5.MaterialCostDebiter{Store: iv, Content: cs}}
	original := op()
	v, e := skin.SkinOn(ctx, a, h.PartnerID, 50000000, original)
	if e != nil || !v.Mutated {
		t.Fatal("actualCA7skin", v, e)
	}
	if _, e = skin.SkinOn(ctx, a, h.PartnerID, 50000000, original); e != nil {
		t.Fatal(e)
	}
	after = facts4a(t, p, a, rev, "avatar")
	catalog, e := cs.ReadPlayerDisplayCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	found := false
	for _, v := range catalog.Cosmetics {
		if v.Family == "avatar" && v.Type == 7 && v.PartnerID == 40001144 {
			found = true
			if fact4a(t, after, v.ID, 5).Status != app.Eligible {
				t.Fatal("CA7notobserved")
			}
		}
	}
	if !found {
		t.Fatal("sourceprofile")
	}
	_, e = (tx.Runner{DB: p}).Run(ctx, opPinned(rev), i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		at := time.Now().UTC()
		co, e := ca.NewCoherentReadScope(sc, rev, at)
		if e != nil {
			return e
		}
		if _, e = s.ReadEligibilityTx(c, co, app.EligibilityRequest{PlayerID: a.PlayerID, Family: "avatar", CompleteFamily: true}); !errors.Is(e, app.ErrUnavailable) {
			t.Fatal("wholefamilyqualified", e)
		}
		co.ContentRevision = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
		if _, e = s.ReadEligibilityTx(c, co, app.EligibilityRequest{PlayerID: a.PlayerID, Family: "avatar"}); e == nil {
			t.Fatal("pinmismatch")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_heroes SET updated_at=clock_timestamp()+interval '1 hour' WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), h.PartnerID)
	_, e = (s.Population).ReadDisplayPopulationTx(ctx, ca.CoherentReadScope{}, a.PlayerID)
	if e == nil {
		t.Fatal("unwitnessed")
	}
	_, e = (tx.Runner{DB: p}).Run(ctx, opPinned(rev), i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		co, e := ca.NewCoherentReadScope(sc, rev, time.Now())
		if e != nil {
			return e
		}
		_, e = s.ReadEligibilityTx(c, co, app.EligibilityRequest{PlayerID: a.PlayerID, Family: "avatar"})
		return e
	})
	if e == nil {
		t.Fatal("futureowner")
	}
}

var _ receipt.Store = kernelstore.Store{}

func TestI7C4ANativeAdditivePermanentGrantAndSnapshotCoherence(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := privilegeActor(t, p, rev)
	s := display4a(p)
	cs := contentstore.Store{Queryer: p}
	cat, e := cs.ReadPlayerDisplayCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	iv := i5store.Store{Queryer: p}
	g := i5.Service{Runner: tx.Runner{DB: p}, Store: iv, Content: cs, Privileges: privilegeProvider(p), Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Audit: audit.NopEmitter{}}
	var skin, frame int64
	for _, v := range cat.Cosmetics {
		if v.Family == "avatar" && v.Type == 7 && skin == 0 {
			skin = v.ID
		}
		if v.Family == "frame" && v.Type == 6 && frame == 0 {
			frame = v.ID
		}
	}
	for _, id := range []int64{skin, frame} {
		if _, e = g.AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "NATIVE_EXPLICIT_MANUAL_I5_PERMANENT", []grant.Line{{Kind: grant.StackItem, ItemID: id, Amount: 1}}, op()); e != nil {
			t.Fatal("canonicalgrant", id, e)
		}
	}
	// No Hero skins and no canonical VIP root. Independent permanent stack wins.
	if _, e = s.Execute(ctx, a, app.Command{Kind: "frame", ID: frame}, op()); e != nil {
		t.Fatal("VIPalternative", e)
	}
	for _, id := range []int64{skin} {
		v, _ := cat.Find("avatar", id)
		if _, e = s.Execute(ctx, a, app.Command{Kind: "avatar", ID: id, Icon: v.Icon, Category: 5}, op()); e != nil {
			t.Fatal("skinalternative", id, e)
		}
		o := facts4a(t, p, a, rev, "avatar")
		if fact4a(t, o, id, 5).Status != app.Eligible {
			t.Fatal("selection/providerdrift", id)
		}
	}
	// One repeatable snapshot must not mix a later committed stack mutation with
	// earlier population. This is a real second transaction, not a mocked snapshot.
	_, e = (tx.Runner{DB: p}).Run(ctx, opPinned(rev), i5.DefaultProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, tr tx.Scope) error {
		at, e := (pg.AuthoritativeTime{Queryer: tr.Tx}).Now(c)
		if e != nil {
			return e
		}
		co, e := ca.NewCoherentReadScope(tr, rev, at)
		if e != nil {
			return e
		}
		before, e := s.ReadEligibilityTx(c, co, app.EligibilityRequest{PlayerID: a.PlayerID, Family: "avatar"})
		if e != nil {
			return e
		}
		if _, e = p.Raw().Exec(c, `UPDATE player_item_stacks SET quantity=0,state_version=state_version+1,updated_at=clock_timestamp() WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), skin); e != nil {
			return e
		}
		after, e := s.ReadEligibilityTx(c, co, app.EligibilityRequest{PlayerID: a.PlayerID, Family: "avatar"})
		if e != nil {
			return e
		}
		if before.PopulationDigest != after.PopulationDigest || fact4a(t, after, skin, 5).Status != app.Eligible {
			t.Fatal("mixedsnapshot")
		}
		return nil
	})
	if e != nil {
		t.Fatal(e)
	}
	if fact4a(t, facts4a(t, p, a, rev, "avatar"), skin, 5).Status != app.Ineligible {
		t.Fatal("freshsnapshotmissedchange")
	}
}
func TestI7C4ANativeCapRunningRemainderOvercapAndStoredPin(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	cs := contentstore.Store{Queryer: p}
	rp, e := cs.ResolveResourceTx(ctx, p, rev, grant.Line{Kind: grant.Temporal, ResourceKey: "skill_point", Amount: 1})
	if e != nil || rp.Descriptor == nil {
		t.Fatal(rp, e)
	}
	for _, amount := range []int64{3, 30} {
		a := privilegeActor(t, p, rev)
		var at time.Time
		if e = p.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&at); e != nil {
			t.Fatal(e)
		}
		anchor := at.Add(-rp.Descriptor.RegenEvery / 2)
		exec(t, p, `UPDATE player_temporal_resources SET stored_amount=$2,regen_anchor_at=$3,updated_at=$4 WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID), amount, anchor, anchor)
		s := privilegeService(p, p)
		s.Time = fixedManualTime{at}
		if _, e = s.ImportManual(ctx, authority(), importQ(a, uuid().String(), 3000), op()); e != nil {
			t.Fatal(e)
		}
		var got, version int64
		var next *time.Time
		var pin string
		if e = p.QueryRow(ctx, `SELECT stored_amount,regen_anchor_at,state_version,content_revision FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID)).Scan(&got, &next, &version, &pin); e != nil {
			t.Fatal(e)
		}
		if got != amount || pin != rev {
			t.Fatal("balance/pin", got, pin)
		}
		if amount == 3 {
			if next == nil || !next.Equal(anchor) || version != 1 {
				t.Fatal("remainder", next, anchor, version)
			}
		} else if next != nil || version != 2 {
			t.Fatal("overcap", next, version)
		}
	}
}

func TestI7C4ANativeFourActualCA7SkinsQualifyCollection(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := privilegeActor(t, p, rev)
	hs := characterstore.Store{Queryer: p}
	cs := contentstore.Store{Queryer: p}
	iv := i5store.Store{Queryer: p}
	svc := hero.Service{Runner: tx.Runner{DB: p}, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}}, Store: hs, Fencer: iv, Content: cs, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, AppearanceMutationStore: hs, AppearanceMutationContent: cs, MaterialCosts: i5.MaterialCostDebiter{Store: iv, Content: cs}}
	for i, x := range [][2]int64{{10001026, 50001133}, {10001027, 50001114}, {10001043, 50001134}, {10001049, 50001132}} {
		skillHero(t, p, a, rev, x[0], int64(i+1))
		skillBook(t, p, a, x[1])
		if _, e := svc.SkinOn(ctx, a, int64(i+1), x[1], op()); e != nil {
			t.Fatal(e)
		}
		f := fact4a(t, facts4a(t, p, a, rev, "avatar"), 110006002, 5)
		want := app.Ineligible
		if i == 3 {
			want = app.Eligible
		}
		if f.Status != want {
			t.Fatal(i, f.Status, want)
		}
	}
	if _, e := display4a(p).Execute(ctx, a, app.Command{Kind: "avatar", ID: 110006002, Icon: 110006002, Category: 5}, op()); e != nil {
		t.Fatal("collectionselection", e)
	}
}

// Raw source-predicate fixtures qualify only the consumer boundary. They do not
// attest an earned evolution/awakening origin or remove the retained3B gates.
func TestI7C4ANativeSourceNormalSuperAndAwakenFacets(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := privilegeActor(t, p, rev)
	for i, id := range []int64{10001001, 11001, 11001001} {
		skillHero(t, p, a, rev, id, int64(i+1))
	}
	exec(t, p, `UPDATE player_heroes SET color=7,star=2,state_version=state_version+1 WHERE player_id=$1`, int64(a.PlayerID))
	o := facts4a(t, p, a, rev, "avatar")
	cat, e := (contentstore.Store{}).ReadPlayerDisplayCatalogTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	seen := map[int64]bool{}
	for _, v := range cat.Cosmetics {
		if v.Family != "avatar" {
			continue
		}
		var category int64
		if v.Type == 2 && v.PartnerID == 10001001 {
			category = 2
		}
		if v.Type == 2 && v.PartnerID == 11001 {
			category = 3
		}
		if v.Type == 3 && v.PartnerID == 11001001 {
			category = 4
		}
		if category > 0 {
			seen[category] = true
			if fact4a(t, o, v.ID, category).Status != app.Eligible {
				t.Fatal(v, category)
			}
		}
	}
	if len(seen) != 3 {
		t.Fatal("sourcecoverage", seen)
	}
}
func TestI7C4ANativeUpgradeTemporalUsesOriginalDescriptor(t *testing.T) {
	old := os.Getenv("GXB_I7C4A_UPGRADE_OLD_REVISION")
	if old == "" {
		t.Skip("populated59upgrade/restore profile only; required in that matrix")
	}
	p := pool(t)
	current := installed(t, p)
	if current == old {
		t.Fatal("upgradepinnotdifferent")
	}
	a := privilegeActor(t, p, old)
	var at time.Time
	if e := p.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&at); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `UPDATE player_temporal_resources SET stored_amount=10,regen_anchor_at=NULL WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID))
	svc := privilegeService(p, p)
	svc.Time = fixedManualTime{at}
	r, e := svc.ImportManual(ctx, authority(), importQ(a, uuid().String(), 3000), op())
	if e != nil || r.ContentRevision != current {
		t.Fatal(r, e)
	}
	var pin string
	var amount, version int64
	var anchor *time.Time
	if e = p.QueryRow(ctx, `SELECT content_revision,stored_amount,state_version,regen_anchor_at FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(a.PlayerID)).Scan(&pin, &amount, &version, &anchor); e != nil || pin != old || amount != 10 || version != 2 || anchor == nil || !anchor.Equal(at) {
		t.Fatal(pin, amount, version, anchor, e)
	}
}
