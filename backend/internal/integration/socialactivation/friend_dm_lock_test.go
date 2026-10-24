//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	dm "gxb.local/backend/v2/internal/application/frienddm"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/playerroot"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/friendmessage"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type dmLockTrace struct {
	t           *testing.T
	keys        []lockkey.Key
	transaction string
	mutated     bool
}

func (w *dmLockTrace) lock(t tx.Tx, key lockkey.Key) error {
	if w.mutated {
		return fmt.Errorf("lower lock after mutation")
	}
	id := fmt.Sprintf("%p", t)
	if w.transaction == "" {
		w.transaction = id
	}
	if w.transaction != id {
		return fmt.Errorf("provider changed caller transaction")
	}
	if len(w.keys) > 0 && lockkey.Compare(w.keys[len(w.keys)-1], key) > 0 {
		return fmt.Errorf("global lock order violation: %+v after %+v", key, w.keys[len(w.keys)-1])
	}
	w.keys = append(w.keys, key)
	return nil
}

type dmPlayerTrace struct {
	playerroot.TxLocker
	w *dmLockTrace
}

func (d dmPlayerTrace) LockPlayerRootsTx(c context.Context, t tx.Tx, server identity.LogicalServerID, ids []identity.PlayerID) ([]playerroot.Root, error) {
	for _, id := range ids {
		k, _ := playerroot.LockKey(id)
		if e := d.w.lock(t, k); e != nil {
			return nil, e
		}
	}
	return d.TxLocker.LockPlayerRootsTx(c, t, server, ids)
}

type dmRelationTrace struct {
	sr.Store
	w *dmLockTrace
}

func (d dmRelationTrace) LockRootTx(c context.Context, t tx.Tx, id identity.PlayerID) (sr.Root, bool, error) {
	k, _ := sr.SocialRootLockKey(id)
	if e := d.w.lock(t, k); e != nil {
		return sr.Root{}, false, e
	}
	return d.Store.LockRootTx(c, t, id)
}
func (d dmRelationTrace) LockFriendshipTx(c context.Context, t tx.Tx, a, b identity.PlayerID) (sr.Friendship, bool, error) {
	k, _ := sr.FriendshipLockKey(a, b)
	if e := d.w.lock(t, k); e != nil {
		return sr.Friendship{}, false, e
	}
	return d.Store.LockFriendshipTx(c, t, a, b)
}
func (d dmRelationTrace) LockBlockTx(c context.Context, t tx.Tx, a, b identity.PlayerID) (sr.Block, bool, error) {
	k, _ := sr.BlockLockKey(a, b)
	if e := d.w.lock(t, k); e != nil {
		return sr.Block{}, false, e
	}
	return d.Store.LockBlockTx(c, t, a, b)
}

type dmStoreTrace struct {
	dm.Store
	w *dmLockTrace
}

func (d dmStoreTrace) Snapshot(c context.Context, q tx.Queryer, id identity.PlayerID, locked bool) (dm.Manifest, error) {
	if locked {
		k, _ := dm.LockKey(id)
		if e := d.w.lock(q.(tx.Tx), k); e != nil {
			return dm.Manifest{}, e
		}
	}
	return d.Store.Snapshot(c, q, id, locked)
}
func (d dmStoreTrace) InsertTx(c context.Context, t tx.Tx, m dm.Manifest, o dm.Occurrence) error {
	d.w.mutated = true
	return d.Store.InsertTx(c, t, m, o)
}

type dmEconomyTrace struct {
	i5.MaterialCostStore
	w *dmLockTrace
}

func (d dmEconomyTrace) LockEconomyOwnerTx(c context.Context, t tx.Tx, id identity.PlayerID) error {
	k, _ := lockkey.New(700, "typed-economy", lockkey.Int64(int64(id)))
	if e := d.w.lock(t, k); e != nil {
		return e
	}
	return d.MaterialCostStore.LockEconomyOwnerTx(c, t, id)
}
func (d dmEconomyTrace) LockStackTx(c context.Context, t tx.Tx, id identity.PlayerID, item int64, at time.Time) (economy.StackState, bool, error) {
	k, _ := lockkey.New(722, "typed-economy.stack", lockkey.Int64(item))
	if e := d.w.lock(t, k); e != nil {
		return economy.StackState{}, false, e
	}
	return d.MaterialCostStore.LockStackTx(c, t, id, item, at)
}
func Test6A_G10_G13_G35SameTxCompleteOrderedPlan(t *testing.T) {
	f, s := dmPair(t)
	f.sql(`INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES(100001,190001001,1,1,$1,$1)`, f.at)
	// The prior catalog fixture initializes the real registry; this independent
	// fixture invokes the same initialization if tests are filtered separately.
	initDMContent(t, f)
	trace := &dmLockTrace{t: t}
	s.Players = dmPlayerTrace{TxLocker: s.Players, w: trace}
	s.Privacy = sr.FriendDMPrivacyProvider{Store: dmRelationTrace{Store: socialrelationstore.Store{}, w: trace}}
	s.Store = dmStoreTrace{Store: s.Store, w: trace}
	s.Entitlement = i5.EmoticonEntitlementReader{Store: dmEconomyTrace{MaterialCostStore: i5store.Store{Queryer: f.p}, w: trace}, Content: dmContent(f)}
	if _, e := s.Accept(ctx, actor(100001), 200001, friendmessage.Message{Kind: 1, EmoticonID: 26}, f.op()); e != nil {
		t.Fatal(e)
	}
	want := []uint16{315, 315, 360, 360, 361, 363, 380, 700, 722}
	if len(trace.keys) != len(want) {
		t.Fatal(trace.keys)
	}
	for i, k := range trace.keys {
		if k.DomainRank != want[i] {
			t.Fatal("complete plan", trace.keys)
		}
	}
	if !trace.mutated {
		t.Fatal("no effect witness")
	}
	t.Log("REAL_PG same caller transaction: both315 before360/361/363, absent380 creation fence, I5 Economy700/Stack722, all locks before first mutation")
}
