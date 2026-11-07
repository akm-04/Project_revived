package socialinvite

import (
	"context"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ReadService is the MID 384 boundary. It is a read-only coherent snapshot of
// the durable socialinvite projection plus the installed mission catalog.
type ReadService struct {
	Timed   generation.TimedRunner
	Content Content
	Reader  InviteReader
}

func readProfile() tx.Profile {
	return tx.Profile{Name: "social-invite-read", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 8 * time.Second, TransactionTimeout: 15 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 2 * time.Second, OperationTimeout: 45 * time.Second}
}

func (service ReadService) Read(ctx context.Context, actor identity.ActorContext, current operation.Context) (map[string]any, error) {
	if service.Timed.Runner.DB == nil || service.Timed.Binder.Time == nil || service.Content == nil || service.Reader == nil {
		return nil, ErrUnavailable
	}
	if !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || actor.ContextID.UUID().IsZero() || current.ID.IsZero() || current.StartedAt.IsZero() {
		return nil, ErrFacts
	}
	var output map[string]any
	_, _, err := service.Timed.Run(ctx, current, readProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, AllowReplayAfterAuthoritativeNegative: false}, nil, func(ctx context.Context, scope generation.TimedScope) error {
		at := scope.Operation.DecisionAt()
		revision, pinned := current.Policies.Get("content")
		var err error
		if !pinned {
			revision, err = service.Content.ActiveRevision(ctx, scope.Tx)
			if err != nil {
				return err
			}
		}
		if characterasset.ValidateExactRevisionID(revision) != nil {
			return ErrFacts
		}
		bound, err := BindInvitePolicies(scope.Operation.Operation(), revision)
		if err != nil {
			return err
		}
		catalog, err := service.Content.SocialInvitationMissionsTx(ctx, scope.Tx, revision)
		if err != nil {
			return err
		}
		snapshot, err := service.Reader.ReadInviteTx(ctx, tx.Scope{Tx: scope.Tx, Operation: bound, Attempt: scope.Attempt, Options: scope.Options}, actor, revision, at)
		if err != nil {
			return err
		}
		projection, err := BuildProjection(snapshot, catalog)
		if err != nil {
			return err
		}
		output = projection.ReadBody()
		return nil
	})
	if err != nil {
		return nil, err
	}
	return output, nil
}
