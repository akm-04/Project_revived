package socialrelation

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/lockkey"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"time"
)

// FriendDMPrivacy is a directed read qualification, not a friendship mutation.
// An absent recipient block binds version zero; block/unblock binds its version.
type FriendDMPrivacy struct {
	FriendshipGeneration, RecipientBlockVersion int64
	Eligible                                    bool
	LatestRelationAt                            time.Time
}
type FriendDMPrivacyPlan struct {
	RecipientRootPresent bool
	BySender             map[identity.PlayerID]FriendDMPrivacy
}
type FriendDMPrivacyReader interface {
	PrepareFriendDMPrivacyTx(context.Context, tx.Tx, identity.PlayerID, []identity.PlayerID) (FriendDMPrivacyPlan, error)
}
type FriendDMPrivacyProvider struct{ Store Store }

// The caller has acquired all canonical I4 roots (315). Acquire all 360 roots,
// then all canonical 361 pairs, then directed recipient->sender 363 blocks.
// This port never ensures missing Social roots and never starts a transaction.
func (p FriendDMPrivacyProvider) PrepareFriendDMPrivacyTx(c context.Context, t tx.Tx, recipient identity.PlayerID, senders []identity.PlayerID) (FriendDMPrivacyPlan, error) {
	if p.Store == nil || t == nil {
		return FriendDMPrivacyPlan{}, ErrInvalidState
	}
	ids := append([]identity.PlayerID{recipient}, senders...)
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	present := map[identity.PlayerID]bool{}
	for _, id := range ids {
		if _, e := CanonicalServer(id); e != nil {
			return FriendDMPrivacyPlan{}, e
		}
		if _, ok := present[id]; ok {
			continue
		}
		r, ok, e := p.Store.LockRootTx(c, t, id)
		if e != nil {
			return FriendDMPrivacyPlan{}, e
		}
		if ok && (r.Validate() != nil || r.PlayerID != id) {
			return FriendDMPrivacyPlan{}, ErrInvalidState
		}
		present[id] = ok
	}
	unique := []identity.PlayerID{}
	seen := map[identity.PlayerID]bool{}
	for _, id := range senders {
		if id == recipient {
			return FriendDMPrivacyPlan{}, ErrInvalidState
		}
		if !seen[id] {
			unique = append(unique, id)
			seen[id] = true
		}
	}
	sort.Slice(unique, func(i, j int) bool {
		a, _ := FriendshipLockKey(recipient, unique[i])
		x, _ := FriendshipLockKey(recipient, unique[j])
		return lockkey.Compare(a, x) < 0
	})
	out := map[identity.PlayerID]FriendDMPrivacy{}
	for _, id := range unique {
		f, ok, e := p.Store.LockFriendshipTx(c, t, recipient, id)
		if e != nil {
			return FriendDMPrivacyPlan{}, e
		}
		v := FriendDMPrivacy{}
		if ok {
			if f.Validate() != nil {
				return FriendDMPrivacyPlan{}, ErrInvalidState
			}
			v.FriendshipGeneration = f.Generation
			v.LatestRelationAt = f.UpdatedAt
			v.Eligible = f.Active && present[id] && present[recipient]
		}
		out[id] = v
	}
	sort.Slice(unique, func(i, j int) bool {
		a, _ := BlockLockKey(recipient, unique[i])
		x, _ := BlockLockKey(recipient, unique[j])
		return lockkey.Compare(a, x) < 0
	})
	for _, id := range unique {
		v := out[id]
		bl, ok, e := p.Store.LockBlockTx(c, t, recipient, id)
		if e != nil {
			return FriendDMPrivacyPlan{}, e
		}
		if ok {
			if bl.Validate() != nil {
				return FriendDMPrivacyPlan{}, ErrInvalidState
			}
			v.RecipientBlockVersion = bl.StateVersion
			if bl.UpdatedAt.After(v.LatestRelationAt) {
				v.LatestRelationAt = bl.UpdatedAt
			}
			v.Eligible = v.Eligible && !bl.Active
		}
		out[id] = v
	}
	return FriendDMPrivacyPlan{RecipientRootPresent: present[recipient], BySender: out}, nil
}

var _ FriendDMPrivacyReader = FriendDMPrivacyProvider{}
