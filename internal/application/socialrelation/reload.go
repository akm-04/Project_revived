package socialrelation

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type ReloadPurpose uint8

const (
	ReloadRequest ReloadPurpose = iota + 1
	ReloadAccept
	ReloadDeny
	ReloadDelete
)

// ReloadReference identifies committed owner state, never authoritative wire data.
type ReloadReference struct {
	Recipient, Actor identity.PlayerID
	RootVersion      int64
	Purpose          ReloadPurpose
	First, Second    identity.PlayerID
	Generation       int64
}

func (r ReloadReference) Validate() error {
	for _, p := range []identity.PlayerID{r.Recipient, r.Actor, r.First, r.Second} {
		if _, e := CanonicalServer(p); e != nil {
			return e
		}
	}
	if r.RootVersion < 1 || r.Generation < 1 || r.First == r.Second {
		return ErrInvalidState
	}
	if r.Purpose == ReloadRequest {
		if r.Actor != r.First || r.Recipient != r.Second {
			return ErrInvalidState
		}
		return nil
	}
	_, e := r.NoticeSource()
	return e
}
func (r ReloadReference) NoticeSource() (socialinbox.SourceKey, error) {
	ev := socialinbox.RelationEvent(0)
	switch r.Purpose {
	case ReloadAccept:
		ev = socialinbox.AcceptRelationRequest
	case ReloadDeny:
		ev = socialinbox.DenyRelationRequest
	case ReloadDelete:
		ev = socialinbox.DeleteRelationFriendship
	default:
		return socialinbox.SourceKey{}, ErrInvalidState
	}
	n, e := (socialinbox.RelationTransition{Event: ev, First: r.First, Second: r.Second, Generation: r.Generation, Actor: r.Actor, Recipient: r.Recipient, At: time.Unix(1, 0)}).Descriptor()
	return n.Source, e
}

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
