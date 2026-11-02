//go:build postgres

package playerdisplay_test

import (
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/audit"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// maximumCharge reaches the top VIP level of the privilege catalog.
const maximumCharge = 100000000

func compositeI5(p *pg.Pool) i5.Service {
	cs := contentstore.Store{Queryer: p}
	v := i5store.Store{Queryer: p}
	return i5.Service{Runner: tx.Runner{DB: p}, Store: v, Content: cs, Privileges: privilegeProvider(p), Functions: i5.LevelFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: v, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Audit: audit.NopEmitter{}}
}

func compositeLevel(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, level int) {
	t.Helper()
	rule, e := (contentstore.Store{}).ResolveProgressionPolicyTx(ctx, p, rev)
	if e != nil {
		t.Fatal(e)
	}
	// Level 1 with no EXP, as the I7C-2H fixture: the level-up path itself must open the gates.
	exec(t, p, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))
	lines := []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[level-2].TotalExp}}
	if _, e = compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_2_NATIVE_COMPOSITE", lines, opPinned(rev)); e != nil {
		t.Fatal("exp grant", e)
	}
	got, e := (i5store.Store{}).ReadProgressionTx(ctx, p, a.PlayerID)
	if e != nil || got.Level != int64(level) {
		t.Fatal("level", got, e)
	}
}

func compositeOpened(t *testing.T, p *pg.Pool, a identity.ActorContext) map[int64]bool {
	t.Helper()
	var ids []int64
	if e := p.QueryRow(ctx, `SELECT coalesce(array_agg(function_id),'{}') FROM player_function_unlocks WHERE player_id=$1 AND function_id = ANY($2)`, int64(a.PlayerID), []int64{5, 12, 13, 35, 39}).Scan(&ids); e != nil {
		t.Fatal(e)
	}
	out := map[int64]bool{}
	for _, id := range ids {
		out[id] = true
	}
	return out
}

func TestI92NativeLevelAndVIPGatesOpenOnVIPChangeAndOnLevelUp(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	vipLater := bornActor(t, p)
	compositeLevel(t, p, vipLater, rev, 45)
	if got := compositeOpened(t, p, vipLater); len(got) != 0 {
		t.Fatal("VIP 0 opened kind 3", got)
	}
	r, e := privilegeService(p, p).ImportManual(ctx, authority(), importQ(vipLater, uuid().String(), maximumCharge), op())
	if e != nil || r.State.VIPLevel < 11 {
		t.Fatal("vip import", r.State.VIPLevel, e)
	}
	if got := compositeOpened(t, p, vipLater); !reflect.DeepEqual(got, map[int64]bool{12: true, 13: true}) {
		t.Fatal("VIP change openings", got)
	}

	levelLater := bornActor(t, p)
	if _, e = privilegeService(p, p).ImportManual(ctx, authority(), importQ(levelLater, uuid().String(), maximumCharge), op()); e != nil {
		t.Fatal(e)
	}
	compositeLevel(t, p, levelLater, rev, 45)
	if got := compositeOpened(t, p, levelLater); !reflect.DeepEqual(got, map[int64]bool{12: true, 13: true}) {
		t.Fatal("level-up openings", got)
	}
}

func TestI92NativeStageClearOpensKindTwoOnce(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	open := func() []int64 {
		tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		defer tr.Rollback(ctx)
		opened, e := compositeI5(p).OpenStageFunctionsTx(ctx, tr, a.PlayerID, rev, 200021, time.Now())
		if e != nil {
			t.Fatal(e)
		}
		if e = tr.Commit(ctx); e != nil {
			t.Fatal(e)
		}
		return opened
	}
	if got := open(); !reflect.DeepEqual(got, []int64{5, 39}) {
		t.Fatal("first clear", got)
	}
	if got := open(); len(got) != 0 {
		t.Fatal("second clear reopened", got)
	}
	if got := compositeOpened(t, p, a); !reflect.DeepEqual(got, map[int64]bool{5: true, 39: true}) {
		t.Fatal("rows", got)
	}
}

func TestI92NativeCrystalSpendLedgerCountsDebitsOnly(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	cs := contentstore.Store{Queryer: p}
	debit := func(amount int64) time.Time {
		tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if e != nil {
			t.Fatal(e)
		}
		defer tr.Rollback(ctx)
		cost := i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: amount}}}
		if _, e = (i5.MaterialCostDebiter{Store: i5store.Store{}, Content: cs}).DebitMaterialCostTx(ctx, tr, a.PlayerID, cost, opPinned(rev)); e != nil {
			t.Fatal(e)
		}
		var at time.Time
		if e = tr.QueryRow(ctx, `SELECT updated_at FROM player_currency_balances WHERE player_id=$1 AND resource_key='crystal'`, int64(a.PlayerID)).Scan(&at); e != nil {
			t.Fatal(e)
		}
		if e = tr.Commit(ctx); e != nil {
			t.Fatal(e)
		}
		return at
	}
	debit(300)
	at := debit(200)
	lines := []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "crystal", Amount: 5000}}
	if _, e := compositeI5(p).AdminGrant(ctx, authority().Operator, a.PlayerID, uuid().String(), "I9_2_NATIVE_SPEND", lines, opPinned(rev)); e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	spent, e := (i5store.Store{}).CrystalSpentOnDayTx(ctx, tr, a.PlayerID, modes.Day(at))
	if e != nil || spent != 500 {
		t.Fatal("spent", spent, e)
	}
}
