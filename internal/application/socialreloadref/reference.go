// Package socialreloadref owns only the finite Social wakeup reference syntax.
// Durable relation and Gift truth remain in their established owners.
package socialreloadref

import (
	"errors"
	"gxb.local/backend/v2/internal/application/socialinbox"
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
)

// ReloadReference identifies committed owner state, never authoritative wire data.
type ReloadReference struct {
	Recipient, Actor identity.PlayerID
	RootVersion      int64
	Purpose          ReloadPurpose
	First, Second    identity.PlayerID
	Generation       int64
	TransferID       ids.UUID
}

func (r ReloadReference) Validate() error {
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
