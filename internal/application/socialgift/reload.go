package socialgift

import (
	"context"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialreloadref"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ValidateReloadTx reloads exact immutable source facts. It grants no value and
// accepts already consumed sources only for a presentation refresh.
func (s Service) ValidateReloadTx(c context.Context, q tx.Queryer, r socialreloadref.ReloadReference) (bool, error) {
	if r.Validate() != nil || s.Store == nil || s.Content == nil || s.NoticeEvidence == nil {
		return false, ErrInvalid
	}
	v, ok, e := s.Store.ReadTransfer(c, q, r.TransferID)
	if e != nil || !ok {
		return false, e
	}
	if v.Validate() != nil {
		return false, ErrConflict
	}
	switch r.Purpose {
	case socialreloadref.ReloadGiftSenderList:
		if r.Recipient != v.Sender || r.Actor != v.Recipient {
			return false, ErrConflict
		}
	case socialreloadref.ReloadGiftRecipientNotice:
		if r.Recipient != v.Recipient || r.Actor != v.Sender {
			return false, ErrConflict
		}
	default:
		return false, ErrInvalid
	}
	n, ok, e := s.NoticeEvidence.ReadNoticeEvidenceTx(c, q, v.Recipient, v.NoticeID)
	if e != nil || !ok {
		return false, e
	}
	if socialinboxMatch(n, v) != nil {
		return false, ErrConflict
	}
	content, e := s.Content.ReadGiftContent(c, q, v.RewardRevision)
	if e != nil {
		return false, e
	}
	if !content.Compatible(v) {
		return false, ErrContent
	}
	return true, nil
}
func (s Service) ReloadReferences(c context.Context, a identity.ActorContext, p identity.PlayerID, result Result, op operation.Context) ([]socialreloadref.ReloadReference, error) {
	if len(result.TransferIDs) != 1 {
		return nil, ErrInvalid
	}
	u, e := ids.ParseUUID(result.TransferIDs[0])
	if e != nil {
		return nil, e
	}
	refs := []socialreloadref.ReloadReference{}
	var private []socialreloadref.ReloadReference
	out, e := s.Reads.Run(c, op, Profile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		roots, e := s.Relations.ReadRootsTx(c, sc.Tx, []identity.PlayerID{a.PlayerID, p})
		if e != nil {
			return e
		}
		for _, r := range []socialreloadref.ReloadReference{{Recipient: a.PlayerID, Actor: p, Purpose: socialreloadref.ReloadGiftSenderList, TransferID: u}, {Recipient: p, Actor: a.PlayerID, Purpose: socialreloadref.ReloadGiftRecipientNotice, TransferID: u}} {
			root, ok := roots[r.Recipient]
			if !ok || root.Validate() != nil {
				return ErrConflict
			}
			r.RootVersion = root.StateVersion
			ok, e := s.ValidateReloadTx(c, sc.Tx, r)
			if e != nil {
				return e
			}
			if !ok {
				return ErrConflict
			}
			refs = append(refs, r)
		}
		private = refs
		return nil
	})
	if e != nil {
		return nil, e
	}
	if out.Outcome != tx.DefiniteCommit {
		return nil, ErrConflict
	}
	return private, nil
}
func socialinboxMatch(n socialinbox.Notice, v Transfer) error {
	if socialinbox.MatchGift(n, v.Descriptor()) != nil || n.Active != v.ClaimOperation.IsZero() {
		return ErrConflict
	}
	return nil
}
