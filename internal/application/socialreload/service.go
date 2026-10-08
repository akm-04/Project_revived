// Package socialreload reloads finite Social owner references. Hints never
// settle gameplay and never supply projection facts from notification bytes.
package socialreload

import (
	"context"
	"gxb.local/backend/v2/internal/application/playerpresentation"
	"gxb.local/backend/v2/internal/application/socialinbox"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/application/socialreloadref"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

type Intent struct {
	Recipient  identity.PlayerID
	Purpose    sr.ReloadPurpose
	ObservedAt time.Time
}
type GiftReloadReader interface {
	ValidateReloadTx(context.Context, tx.Queryer, socialreloadref.ReloadReference) (bool, error)
}
type Service struct {
	Gifts     GiftReloadReader
	Runner    tx.Runner
	Relations sr.ReloadReader
	Inbox     socialinbox.SourceReader
	Observer  playerpresentation.TxObserver
}

func (s Service) Reload(ctx context.Context, r sr.ReloadReference, op operation.Context) (Intent, bool, error) {
	if r.Validate() != nil || s.Runner.DB == nil || s.Relations == nil || s.Inbox == nil || s.Observer == nil {
		return Intent{}, false, sr.ErrInvalidState
	}
	var value Intent
	valid := false
	profile := tx.Profile{Name: "I7A4D_RELOAD", AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 500 * time.Millisecond, TransactionTimeout: time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 2 * time.Second}
	outcome, e := s.Runner.Run(ctx, op, profile, tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(ctx context.Context, scope tx.Scope) error {
		value = Intent{}
		valid = false
		root, ok, e := s.Relations.ReadRootTx(ctx, scope.Tx, r.Recipient)
		if e != nil {
			return e
		}
		if !ok || root.StateVersion < r.RootVersion {
			return nil
		}
		if root.PlayerID != r.Recipient || root.Validate() != nil {
			return sr.ErrInvalidState
		}
		if r.Purpose == socialreloadref.ReloadGiftSenderList || r.Purpose == socialreloadref.ReloadGiftRecipientNotice {
			if s.Gifts == nil {
				return sr.ErrInvalidState
			}
			ok, e := s.Gifts.ValidateReloadTx(ctx, scope.Tx, r)
			if e != nil {
				return e
			}
			if !ok {
				return nil
			}
		} else if r.Purpose == sr.ReloadRequest {
			req, ok, e := s.Relations.ReadRequestTx(ctx, scope.Tx, r.First, r.Second)
			if e != nil {
				return e
			}
			if !ok || req.Generation != r.Generation || req.Status != sr.RequestPending {
				return nil
			}
			if req.RequesterPlayerID != r.Actor || req.TargetPlayerID != r.Recipient || req.Validate() != nil {
				return sr.ErrInvalidState
			}
		} else {
			key, e := r.NoticeSource()
			if e != nil {
				return e
			}
			n, ok, e := s.Inbox.ReadNoticeSourceTx(ctx, scope.Tx, r.Recipient, key)
			if e != nil {
				return e
			}
			if !ok {
				return nil
			}
			if n.RecipientPlayerID != r.Recipient || n.Source != key || socialinbox.ValidateRelationLifecycle(n) != nil || (!n.RelatedPlayerDeleted && n.RelatedPlayerID != r.Actor) {
				return socialinbox.ErrInvalidNotice
			}
		}
		at, e := s.Observer.ObserveTx(ctx, scope.Tx)
		if e != nil {
			return e
		}
		if at.IsZero() {
			return sr.ErrInvalidState
		}
		value = Intent{Recipient: r.Recipient, Purpose: r.Purpose, ObservedAt: at}
		valid = true
		return nil
	})
	if e != nil {
		return Intent{}, false, e
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return Intent{}, false, sr.ErrStateConflict
	}
	return value, valid, nil
}
