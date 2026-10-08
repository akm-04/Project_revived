//go:build postgres && socialintegration

package socialactivation_test

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	sg "gxb.local/backend/v2/internal/application/socialgift"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"testing"
	"time"
)

type giftLockStore struct {
	sg.Store
	w *dmLockTrace
}

func (s giftLockStore) LockEpoch(c context.Context, t tx.Tx, p identity.PlayerID, day string) (sg.Epoch, bool, sg.Epoch, bool, error) {
	k, _ := sg.EpochKey(p)
	if e := s.w.lock(t, k); e != nil {
		return sg.Epoch{}, false, sg.Epoch{}, false, e
	}
	return s.Store.LockEpoch(c, t, p, day)
}
func (s giftLockStore) LockTransfer(c context.Context, t tx.Tx, a, b identity.PlayerID, day string) (sg.Transfer, bool, error) {
	k, _ := sg.TransferKey(a, b, day)
	if e := s.w.lock(t, k); e != nil {
		return sg.Transfer{}, false, e
	}
	return s.Store.LockTransfer(c, t, a, b, day)
}
func (s giftLockStore) PutEpoch(c context.Context, t tx.Tx, e sg.Epoch, ok bool, at time.Time) error {
	s.w.mutated = true
	return s.Store.PutEpoch(c, t, e, ok, at)
}

type giftLockInbox struct {
	socialinbox.GiftNoticeStore
	w *dmLockTrace
}

func (s giftLockInbox) LockNoticeTx(c context.Context, t tx.Tx, p identity.PlayerID, id socialinbox.NoticeID) (socialinbox.Notice, bool, error) {
	k, _ := socialinbox.NoticeLockKey(p, id)
	if e := s.w.lock(t, k); e != nil {
		return socialinbox.Notice{}, false, e
	}
	return s.GiftNoticeStore.LockNoticeTx(c, t, p, id)
}
func (s giftLockInbox) LockNoticeSourceTx(c context.Context, t tx.Tx, p identity.PlayerID, key socialinbox.SourceKey) (socialinbox.Notice, bool, error) {
	k, _ := socialinbox.NoticeSourceLockKey(p, key)
	if e := s.w.lock(t, k); e != nil {
		return socialinbox.Notice{}, false, e
	}
	return s.GiftNoticeStore.LockNoticeSourceTx(c, t, p, key)
}

type giftLockRelation struct {
	sg.RelationOwner
	w *dmLockTrace
}

func (s giftLockRelation) LockRootTx(c context.Context, t tx.Tx, p identity.PlayerID) (sr.Root, bool, error) {
	k, _ := sr.SocialRootLockKey(p)
	if e := s.w.lock(t, k); e != nil {
		return sr.Root{}, false, e
	}
	return s.RelationOwner.LockRootTx(c, t, p)
}

type giftLockEconomy struct {
	i5.Store
	w *dmLockTrace
}

func (s giftLockEconomy) LockEconomyOwnerTx(c context.Context, t tx.Tx, p identity.PlayerID) error {
	k, _ := lockkey.New(700, "typed-economy", lockkey.Int64(int64(p)))
	if e := s.w.lock(t, k); e != nil {
		return e
	}
	return s.Store.LockEconomyOwnerTx(c, t, p)
}
func (s giftLockEconomy) LockScalarTx(c context.Context, t tx.Tx, p identity.PlayerID, key string, at time.Time) (economy.ScalarBalance, bool, error) {
	k, _ := lockkey.New(720, "typed-economy.scalar", lockkey.String(key))
	if e := s.w.lock(t, k); e != nil {
		return economy.ScalarBalance{}, false, e
	}
	return s.Store.LockScalarTx(c, t, p, key, at)
}
func (s giftLockEconomy) SaveScalarTx(c context.Context, t tx.Tx, v economy.ScalarBalance, ok bool) error {
	s.w.mutated = true
	return s.Store.SaveScalarTx(c, t, v, ok)
}
func Test7A_CompleteLockPlanSameCallerTx(t *testing.T) {
	f, s, a, b := giftFixture(t)
	w := &dmLockTrace{t: t}
	s.Players = dmPlayerTrace{s.Players, w}
	s.Privacy = sr.FriendDMPrivacyProvider{Store: dmRelationTrace{s.Relations, w}}
	s.Store = giftLockStore{s.Store, w}
	s.Inbox.Store = giftLockInbox{s.Inbox.Store, w}
	r, e := s.Send(ctx, a, b.PlayerID, f.op())
	if e != nil {
		t.Fatal(e)
	}
	ranks := []uint16{}
	for _, k := range w.keys {
		ranks = append(ranks, k.DomainRank)
	}
	if !reflect.DeepEqual(ranks, []uint16{315, 315, 360, 360, 361, 363, 370, 371, 372}) {
		t.Fatal(ranks)
	}
	s = f.gift()
	w = &dmLockTrace{t: t}
	s.Players = dmPlayerTrace{s.Players, w}
	s.Relations = giftLockRelation{s.Relations, w}
	s.Store = giftLockStore{s.Store, w}
	s.Inbox.Store = giftLockInbox{s.Inbox.Store, w}
	gr := s.Grants.(i5.Service)
	gr.Store = giftLockEconomy{gr.Store, w}
	s.Grants = gr
	if _, e = s.Claim(ctx, b, r.NoticeIDs, f.op()); e != nil {
		t.Fatal(e)
	}
	ranks = nil
	for _, k := range w.keys {
		ranks = append(ranks, k.DomainRank)
	}
	if !reflect.DeepEqual(ranks, []uint16{315, 360, 370, 371, 372, 700, 720, 720}) {
		t.Fatal(ranks)
	}
	t.Log("REAL_PG canonical315/360/361/363/370/371/372 and claim700/720 before mutation, accepted same-key scalar recheck, same callerTx, no late lower lock")
}
