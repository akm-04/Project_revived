// Package socialreloadref owns only the finite Social wakeup reference syntax.
// Durable relation and Gift truth remain in their established owners.
package socialreloadref

import (
	"errors"
	"gxb.local/backend/v2/internal/application/socialinbox"
	gi "gxb.local/backend/v2/internal/domain/guildinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"math"
	"time"
)

var ErrInvalidState = errors.New("invalid Social reload reference")

func canonical(p identity.PlayerID) error {
	q := int64(p) / 100000
	if !p.Valid() || q < 1 || q > math.MaxInt32 {
		return ErrInvalidState
	}
	return nil
}

type ReloadPurpose uint8

const (
	ReloadRequest ReloadPurpose = iota + 1
	ReloadAccept
	ReloadDeny
	ReloadDelete
	ReloadGiftRecipientNotice
	ReloadGiftSenderList
	ReloadInviteMaterialized
	ReloadInviteInvalidated
)

// ReloadReference identifies committed owner state, never authoritative wire data.
type ReloadReference struct {
	Recipient, Actor   identity.PlayerID
	RootVersion        int64
	Purpose            ReloadPurpose
	First, Second      identity.PlayerID
	Generation         int64
	SourceID, MarkerID ids.UUID
	TransferID         ids.UUID
}

func (r ReloadReference) Validate() error {
	if r.Purpose == ReloadInviteMaterialized || r.Purpose == ReloadInviteInvalidated {
		if canonical(r.Recipient) != nil || canonical(r.Actor) != nil || r.RootVersion < 1 || r.SourceID.IsZero() || r.First != 0 || r.Second != 0 || r.Generation != 0 || !r.TransferID.IsZero() || r.Purpose == ReloadInviteMaterialized && (!r.MarkerID.IsZero() || r.Actor == r.Recipient) || r.Purpose == ReloadInviteInvalidated && r.MarkerID.IsZero() {
			return ErrInvalidState
		}
		return nil
	}
	if !r.SourceID.IsZero() || !r.MarkerID.IsZero() {
		return ErrInvalidState
	}

	if r.Purpose == ReloadGiftRecipientNotice || r.Purpose == ReloadGiftSenderList {
		if canonical(r.Recipient) != nil || canonical(r.Actor) != nil || r.Recipient == r.Actor || r.RootVersion < 1 || r.TransferID.IsZero() || r.First != 0 || r.Second != 0 || r.Generation != 0 {
			return ErrInvalidState
		}
		return nil
	}
	if !r.TransferID.IsZero() {
		return ErrInvalidState
	}
	for _, p := range []identity.PlayerID{r.Recipient, r.Actor, r.First, r.Second} {
		if e := canonical(p); e != nil {
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
	if r.Purpose == ReloadGiftRecipientNotice && !r.TransferID.IsZero() {
		return socialinbox.SourceKey{Kind: socialinbox.GiftSourceKind, Key: r.TransferID.String()}, nil
	}
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

// InviteObservation is prepared by the typed source/target owner before the
// response clock. Evaluation after Observe performs no owner query.
type InviteObservation struct {
	Snapshot             gi.Snapshot
	Active, Invalidation bool
}

func (v InviteObservation) ValidAt(at time.Time) (bool, error) {
	eligible, e := v.Snapshot.Eligible(at)
	if e != nil {
		return false, e
	}
	if v.Snapshot.CurrentGeneration != 0 && v.Snapshot.CurrentGeneration != v.Snapshot.Issue.Tuple.Generation {
		return false, nil
	}
	if v.Invalidation {
		return true, nil
	}
	return eligible && v.Active, nil
}
