package socialrelation

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialreloadref"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type ReloadPurpose = socialreloadref.ReloadPurpose
type ReloadReference = socialreloadref.ReloadReference

const (
	ReloadRequest = socialreloadref.ReloadRequest
	ReloadAccept  = socialreloadref.ReloadAccept
	ReloadDeny    = socialreloadref.ReloadDeny
	ReloadDelete  = socialreloadref.ReloadDelete
)

type ReloadReader interface {
	ReadRootTx(context.Context, tx.Tx, identity.PlayerID) (Root, bool, error)
	ReadRequestTx(context.Context, tx.Tx, identity.PlayerID, identity.PlayerID) (FriendRequest, bool, error)
}

func (p commandPlan) reloadReferences(st commandState, c Command) ([]ReloadReference, error) {
	out := []ReloadReference{}
	add := func(r ReloadReference) error {
		root, ok := st.roots[r.Recipient]
		if !ok || !p.touch[r.Recipient] {
			return ErrStateConflict
		}
		r.RootVersion = root.StateVersion + 1
		if e := r.Validate(); e != nil {
			return e
		}
		out = append(out, r)
		return nil
	}
	if c.Kind == RequestFriend {
		for _, w := range p.requests {
			if w.next.Status == RequestPending {
				r := w.next
				if e := add(ReloadReference{Recipient: r.TargetPlayerID, Actor: r.RequesterPlayerID, Purpose: ReloadRequest, First: r.RequesterPlayerID, Second: r.TargetPlayerID, Generation: r.Generation}); e != nil {
					return nil, e
				}
			}
		}
	}
	for _, ev := range p.events {
		purpose := ReloadAccept
		switch ev.Event {
		case socialinbox.DenyRelationRequest:
			purpose = ReloadDeny
		case socialinbox.DeleteRelationFriendship:
			purpose = ReloadDelete
		}
		if e := add(ReloadReference{Recipient: ev.Recipient, Actor: ev.Actor, Purpose: purpose, First: ev.First, Second: ev.Second, Generation: ev.Generation}); e != nil {
			return nil, e
		}
	}
	return out, nil
}
