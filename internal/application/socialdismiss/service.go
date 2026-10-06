// Package socialdismiss coordinates relation-only Inbox dismissal through typed
// owner ports. It owns no tables and never calls a delivery or grant provider.
package socialdismiss

import (
	"context"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/application/socialinbox"
	"gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"math"
	"sort"
	"time"
)

type RootStore interface {
	LockRootTx(context.Context, tx.Tx, identity.PlayerID) (socialrelation.Root, bool, error)
	TouchRootTx(context.Context, tx.Tx, socialrelation.Root, time.Time) error
}
type Service struct {
	Timed       gen.TimedRunner
	PlayerRoots playerroot.TxLocker
	Roots       RootStore
	Inbox       socialinbox.DismissStore
}

func (s Service) Dismiss(ctx context.Context, a identity.ActorContext, ids []socialinbox.NoticeID, op operation.Context) ([]socialinbox.NoticeID, error) {
	server, e := socialrelation.CanonicalServer(a.PlayerID)
	if e != nil || server != a.LogicalServerID || a.AccountID.UUID().IsZero() || !a.AccountUID.Valid() || a.SessionID.UUID().IsZero() || a.ContextID.UUID().IsZero() || a.ContextGeneration < 1 || a.SessionLivenessVersion < 1 || a.ContextLivenessVersion < 1 || s.Roots == nil || s.Inbox == nil || s.PlayerRoots == nil || s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil {
		return nil, socialinbox.ErrInvalidNotice
	}
	order := []socialinbox.NoticeID{}
	seen := map[socialinbox.NoticeID]bool{}
	for _, id := range ids {
		if !id.WireSafe() {
			return nil, socialinbox.ErrInvalidNotice
		}
		if !seen[id] {
			seen[id] = true
			order = append(order, id)
		}
	}
	sorted := append([]socialinbox.NoticeID{}, order...)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i] < sorted[j] })
	var answer []socialinbox.NoticeID
	_, outcome, e := s.Timed.Run(ctx, op, socialrelation.DefaultCommandProfile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, nil, func(ctx context.Context, scope gen.TimedScope) error {
		answer = nil
		roots, e := s.PlayerRoots.LockPlayerRootsTx(ctx, scope.Tx, server, []identity.PlayerID{a.PlayerID})
		if e != nil {
			return e
		}
		if len(roots) != 1 || roots[0].Validate() != nil || roots[0].PlayerID != a.PlayerID || roots[0].LogicalServerID != server {
			return socialinbox.ErrInvalidNotice
		}
		root, ok, e := s.Roots.LockRootTx(ctx, scope.Tx, a.PlayerID)
		if e != nil {
			return e
		}
		if !ok {
			answer = []socialinbox.NoticeID{}
			return nil
		}
		if root.PlayerID != a.PlayerID || root.Validate() != nil {
			return socialinbox.ErrInvalidNotice
		}
		accepted := map[socialinbox.NoticeID]bool{}
		pending := []socialinbox.Notice{}
		at := scope.Operation.DecisionAt()
		for _, id := range sorted {
			n, ok, e := s.Inbox.LockNoticeTx(ctx, scope.Tx, a.PlayerID, id)
			if e != nil {
				return e
			}
			if !ok {
				continue
			}
			if n.RecipientPlayerID != a.PlayerID || n.NoticeID != id {
				return socialinbox.ErrInvalidNotice
			}
			if !socialinbox.RelationFamily(n.Source) {
				continue
			}
			if socialinbox.ValidateRelationLifecycle(n) != nil {
				return socialinbox.ErrInvalidNotice
			}
			accepted[id] = true
			if n.Active {
				if n.StateVersion == math.MaxInt64 {
					return socialrelation.ErrCounterOverflow
				}
				if at.Before(n.NoticeTime) || at.Before(n.CreatedAt) || at.Before(n.UpdatedAt) {
					return socialrelation.ErrStaleDecisionTime
				}
				pending = append(pending, n)
			}
		}
		if len(pending) > 0 {
			if root.StateVersion == math.MaxInt64 {
				return socialrelation.ErrCounterOverflow
			}
			if at.Before(root.CreatedAt) || at.Before(root.UpdatedAt) {
				return socialrelation.ErrStaleDecisionTime
			}
			if e := s.Roots.TouchRootTx(ctx, scope.Tx, root, at); e != nil {
				return e
			}
			for _, n := range pending {
				if e := s.Inbox.DismissNoticeTx(ctx, scope.Tx, n, at); e != nil {
					return e
				}
			}
		}
		answer = []socialinbox.NoticeID{}
		for _, id := range order {
			if accepted[id] {
				answer = append(answer, id)
			}
		}
		return nil
	})
	if e != nil {
		return nil, e
	}
	if outcome.Outcome != tx.DefiniteCommit {
		return nil, socialrelation.ErrStateConflict
	}
	return answer, nil
}
