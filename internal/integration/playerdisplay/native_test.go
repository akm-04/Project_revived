//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	app "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

func TestDisplayRenameAvatarReplayAndDirectory(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	exec(t, p, `UPDATE player_directory_profiles SET vip=7,conquer_lev=9 WHERE player_id=$1`, int64(a.PlayerID))
	q := app.Command{Kind: "rename", Name: "名字"}
	first := op()
	r, e := s.Execute(ctx, a, q, first)
	if e != nil || !r.Changed || r.ProfileVersion != 2 {
		t.Fatal(r, e)
	}
	r, e = s.Execute(ctx, a, q, op())
	if e != nil || r.Changed || r.ProfileVersion != 2 {
		t.Fatal("noop", r, e)
	}
	r, e = s.Execute(ctx, a, app.Command{Kind: "rename", Name: "NextName"}, op())
	if e != nil || r.ProfileVersion != 3 {
		t.Fatal("charged", r, e)
	}
	var amount int64
	if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); e != nil || amount != 900 {
		t.Fatal(amount, e)
	}
	r, e = s.Execute(ctx, a, q, first)
	if e != nil || r.ProfileVersion != 2 || r.Wire["player_name"] != "名字" || state(t, p, a).Basis.Profile.DisplayName != "NextName" {
		t.Fatal("original replay", r, e)
	}
	avatar := app.Command{Kind: "avatar", ID: 110001002, Icon: 10002004, Category: 1}
	r, e = s.Execute(ctx, a, avatar, op())
	if e != nil || r.ProfileVersion != 4 {
		t.Fatal(r, e)
	}
	x := state(t, p, a)
	if x.Selection.AvatarTableID != avatar.ID || x.Basis.Profile.AvatarID != avatar.Icon {
		t.Fatal(x)
	}
	var name string
	var icon, version int64
	if e = p.QueryRow(ctx, `SELECT name,avatar_id,state_version FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)).Scan(&name, &icon, &version); e != nil || name != "NextName" || icon != avatar.Icon {
		t.Fatal(name, icon, version, e)
	}
	var vip, conquest int64
	if e = p.QueryRow(ctx, `SELECT vip,conquer_lev FROM player_directory_profiles WHERE player_id=$1`, int64(a.PlayerID)).Scan(&vip, &conquest); e != nil || vip != 7 || conquest != 9 {
		t.Fatal("foreign directory facts", vip, conquest, e)
	}
	bad := avatar
	bad.Icon = avatar.ID
	if _, e = s.Execute(ctx, a, bad, op()); !errors.Is(e, app.ErrRequest) {
		t.Fatal("forged tuple", e)
	}
	obs, e := s.ObserveTx(ctx, p, a.PlayerID, rev, time.Now().UTC())
	if e != nil || obs.AvatarID != avatar.Icon || obs.ProfileVersion != 4 {
		t.Fatal(obs, e)
	}
	names, e := s.Read(ctx, a, "names", op())
	if e != nil || len(names["player_name_list"].([]string)) != 12 {
		t.Fatal(names, e)
	}
}
func TestDisplayPurchaseAtomicAndMissingProviders(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	purchase := app.Command{Kind: "purchase", ID: 110005001}
	o := op()
	r, e := s.Execute(ctx, a, purchase, o)
	if e != nil {
		t.Fatal(r, e)
	}
	var amount, qty int64
	if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); e != nil || amount != 712 {
		t.Fatal(amount, e)
	}
	if e = p.QueryRow(ctx, `SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2`, int64(a.PlayerID), purchase.ID).Scan(&qty); e != nil || qty != 1 {
		t.Fatal(qty, e)
	}
	if _, e = s.Execute(ctx, a, purchase, o); e != nil {
		t.Fatal("known purchase", e)
	}
	if _, e = s.Execute(ctx, a, purchase, op()); e == nil {
		t.Fatal("double ownership charge")
	}
	if _, e = s.Execute(ctx, a, app.Command{Kind: "avatar", ID: 110005001, Icon: 110005001, Category: 5}, op()); e != nil {
		t.Fatal("canonical purchased stack", e)
	}
	if _, e = s.Read(ctx, a, "titles", op()); !errors.Is(e, app.ErrUnavailable) {
		t.Fatal("missing required title producer", e)
	}
	if _, e = s.Read(ctx, a, "bubbles", op()); !errors.Is(e, app.ErrUnavailable) {
		t.Fatal("missing required bubble producer", e)
	}
}
func TestDisplayConcurrentAssignmentsAndRetirement(t *testing.T) {
	p := pool(t)
	installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	q := app.Command{Kind: "avatar", ID: 110001002, Icon: 10002004, Category: 1}
	var wg sync.WaitGroup
	errs := make(chan error, 4)
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func() { defer wg.Done(); _, e := s.Execute(ctx, a, q, op()); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil && !errors.Is(e, app.ErrConflict) {
			t.Fatal(e)
		}
	}
	x := state(t, p, a)
	if x.Basis.Profile.StateVersion != 2 {
		t.Fatal("one effective assignment", x)
	}
	exec(t, p, `UPDATE gameplay_contexts SET ended_at=clock_timestamp(),end_reason='LOGOUT',liveness_version=liveness_version+1 WHERE context_id=$1`, a.ContextID.UUID().String())
	if _, e := s.Execute(ctx, a, q, op()); e == nil {
		t.Fatal("retired actor accepted")
	}
}

// External provider double proves consumer binding/fail-closed behavior, not an
// actual Activity/Ranking/VIP producer qualification or complete activation.
type originProvider struct{ o app.Origin }

func (x originProvider) ReadDisplayOriginsTx(_ context.Context, _ tx.Queryer, pid identity.PlayerID, f, rev string, at time.Time) (app.OriginObservation, error) {
	return app.OriginObservation{PlayerID: pid, Family: f, Revision: rev, ObservedAt: at, Qualified: true, Origins: []app.Origin{x.o}}, nil
}
func TestDisplayTimedOriginBoundariesAndNoOwnershipDeletion(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	at := time.Now().UTC()
	o := app.Origin{PlayerID: a.PlayerID, Key: "test-qualified-origin", Owner: "test-external-only", Family: "bubble", CatalogID: 10002, Revision: rev, StateVersion: 1, EndTime: at.Unix() + 100}
	s.External = originProvider{o: o}
	if _, e := s.Execute(ctx, a, app.Command{Kind: "bubble", ID: 10002}, op()); e != nil {
		t.Fatal(e)
	}
	for _, sec := range []int64{o.EndTime - 1, o.EndTime, o.EndTime + 1} {
		obs, e := s.ObserveTx(ctx, p, a.PlayerID, rev, time.Unix(sec, 0).UTC())
		if e != nil {
			t.Fatal(e)
		}
		want := int64(10001)
		if sec < o.EndTime {
			want = 10002
		}
		if obs.BubbleID != want {
			t.Fatal(sec, obs)
		}
	}
	if state(t, p, a).Selection.BubbleID != 10002 {
		t.Fatal("expiry deleted assignment")
	}
	// Canonical Exp remains unchanged and available through existing I5 basis.
	b, e := (i5store.Store{}).ReadPublicPlayerBasisTx(ctx, p, a.PlayerID)
	if e != nil || b.Progression.Exp != 37 {
		t.Fatal(b, e)
	}
}

// ACK-loss injection wraps a real PostgreSQL COMMIT/ROLLBACK. It does not replace
// database storage or lock behavior. Only the third (semantic value) Tx faults.
type faultDB struct {
	tx.Beginner
	n      int
	commit bool
}
type faultTx struct {
	tx.Tx
	commit bool
}

func (d *faultDB) Begin(c context.Context, o tx.Options) (tx.Tx, error) {
	t, e := d.Beginner.Begin(c, o)
	if e != nil {
		return nil, e
	}
	d.n++
	if d.n == 3 {
		return faultTx{t, d.commit}, nil
	}
	return t, nil
}
func (t faultTx) Commit(c context.Context) error {
	if t.commit {
		if e := t.Tx.Commit(c); e != nil {
			return e
		}
	} else {
		_ = t.Tx.Rollback(c)
	}
	return errors.New("injected lost COMMIT ACK")
}
func TestDisplayUnknownValueRecovery(t *testing.T) {
	p := pool(t)
	installed(t, p)
	for _, committed := range []bool{true, false} {
		a := actor(t, p)
		normal := service(p, p)
		if _, e := normal.Execute(ctx, a, app.Command{Kind: "rename", Name: "Initial"}, op()); e != nil {
			t.Fatal(e)
		}
		q := app.Command{Kind: "rename", Name: "Charged"}
		original := op()
		fault := service(p, &faultDB{Beginner: p, commit: committed})
		r, e := fault.Execute(ctx, a, q, original)
		if committed {
			if e != nil || r.Wire["player_name"] != "Charged" {
				t.Fatal("positive unknown proof", r, e)
			}
			if _, e = normal.Execute(ctx, a, q, original); e != nil {
				t.Fatal("known afterACKloss", e)
			}
		} else {
			var unknown *tx.UnknownCommitError
			if !errors.As(e, &unknown) {
				t.Fatal("negative unknown mustremainunresolved", e)
			}
			if _, e = normal.Execute(ctx, a, q, op()); !errors.Is(e, app.ErrUnresolved) {
				t.Fatal("cancel guardedoldattempt", e)
			}
			if _, e = normal.Execute(ctx, a, q, op()); e != nil {
				t.Fatal("new admitted attempt", e)
			}
			if _, e = normal.Execute(ctx, a, q, original); e == nil {
				t.Fatal("aborted identity revived")
			}
		}
		var amount int64
		if e = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount); e != nil || amount != 900 {
			t.Fatal("debit exactlyonce", amount, e)
		}
	}
}

type failReceipt struct{ receipt.Store }

func (r failReceipt) PutTx(c context.Context, t tx.Tx, x receipt.Receipt) (receipt.PutResult, error) {
	if x.OperationClass == "I7B6A_PLAYER_DISPLAY" {
		return receipt.PutResult{}, errors.New("injected outerreceipt failure")
	}
	return r.Store.PutTx(c, t, x)
}
func TestDisplayAtomicValueRollbackAndOriginPersistence(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := actor(t, p)
	s := service(p, p)
	s.Receipts = failReceipt{s.Receipts}
	if _, e := s.Execute(ctx, a, app.Command{Kind: "purchase", ID: 110005001}, op()); e == nil {
		t.Fatal("receiptfailure accepted")
	}
	var amount, qty int64
	p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&amount)
	p.QueryRow(ctx, `SELECT COALESCE(sum(quantity),0) FROM player_item_stacks WHERE player_id=$1 AND item_id=110005001`, int64(a.PlayerID)).Scan(&qty)
	if amount != 1000 || qty != 0 {
		t.Fatal("non-atomicvalue", amount, qty)
	}
	s = service(p, p)
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	roots, e := s.Players.LockPlayerRootsTx(ctx, tr, 1, []identity.PlayerID{a.PlayerID})
	if e != nil {
		t.Fatal(e)
	}
	origin := app.Origin{PlayerID: a.PlayerID, Key: "typed-recipient-test", Owner: "test-qualified-source", Family: "bubble", CatalogID: 10002, UniqueID: 0, EndTime: time.Now().Unix() + 500, Revision: rev, StateVersion: 1}
	if e = s.ReceiveOriginTx(ctx, tr, roots[0], origin); e != nil {
		t.Fatal(e)
	}
	if e = s.ReceiveOriginTx(ctx, tr, roots[0], origin); e != nil {
		t.Fatal("idempotent origin", e)
	}
	bad := origin
	bad.EndTime++
	if e = s.ReceiveOriginTx(ctx, tr, roots[0], bad); !errors.Is(e, app.ErrConflict) {
		t.Fatal("originidentity drift", e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	os, e := s.Store.ReadDisplayEntitlementsTx(ctx, p, a.PlayerID, "bubble")
	if e != nil || len(os) != 1 || os[0].Key != origin.Key || os[0].EndTime != origin.EndTime {
		t.Fatal(os, e)
	}
}
