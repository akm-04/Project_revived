package identitylifecycle

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// IdleExpiryBatchSize bounds one idle-expiry page and revocation statement.
const IdleExpiryBatchSize = 500

// IdleExpiryStore is the identity owner's maintenance port. Both operations
// recheck the idle predicate, so a session touched after the page was read is
// never revoked.
type IdleExpiryStore interface {
	ListIdleExpiredSessionIDsTx(context.Context, tx.Queryer, time.Time, identity.SessionID, int) ([]identity.SessionID, error)
	RevokeIdleExpiredSessionsTx(context.Context, tx.Tx, []identity.SessionID, time.Time) (int64, error)
}

// IdleExpirySweep revokes sessions idle beyond their own timeout and ends their
// gameplay contexts. It is safe to run repeatedly: a revoked session leaves the
// expired set.
type IdleExpirySweep struct {
	Runner     tx.Runner
	Store      IdleExpiryStore
	Operations operation.Factory
}

func (s IdleExpirySweep) Run(ctx context.Context) (int64, error) {
	if s.Runner.DB == nil || s.Store == nil {
		return 0, errors.New("idle expiry sweep ports incomplete")
	}
	current, err := s.Operations.New(policy.Set{})
	if err != nil {
		return 0, err
	}
	now := current.StartedAt.UTC()
	var after identity.SessionID
	var revoked int64
	for {
		var page []identity.SessionID
		var count int64
		_, err := s.Runner.Run(ctx, current, DefaultProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(txctx context.Context, scope tx.Scope) error {
			listed, listErr := s.Store.ListIdleExpiredSessionIDsTx(txctx, scope.Tx, now, after, IdleExpiryBatchSize)
			if listErr != nil {
				return listErr
			}
			page = listed
			if len(listed) == 0 {
				return nil
			}
			count, listErr = s.Store.RevokeIdleExpiredSessionsTx(txctx, scope.Tx, listed, now)
			return listErr
		})
		if err != nil {
			return revoked, err
		}
		revoked += count
		if len(page) < IdleExpiryBatchSize {
			return revoked, nil
		}
		after = page[len(page)-1]
	}
}
