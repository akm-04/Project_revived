package compat

import (
	"context"
	"time"

	d "gxb.local/backend/v2/internal/domain/compat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const transactionName = "compat-preferences"

// Service writes the player compat preferences. The message-push toggles and
// the first-touch marker change no value and need no receipt: the R6 edge
// replays a state reply within ten minutes and a second execution is a no-op.
type Service struct {
	Runner  tx.Runner
	Fresh   tx.Queryer
	Store   Store
	Content Content
	Players Players
	Fence   Fence
}

func Profile() tx.Profile {
	return tx.Profile{Name: transactionName, AcquireTimeout: 2 * time.Second, LockTimeout: 5 * time.Second, StatementTimeout: 10 * time.Second, TransactionTimeout: 30 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 10 * time.Second, OperationTimeout: 60 * time.Second}
}

func retryPolicy() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true, DefiniteAbortBackoffBase: 20 * time.Millisecond, DefiniteAbortBackoffMax: 160 * time.Millisecond}
}

// SetMessagePush adds or removes one stock notification id. Ids outside the
// compiled catalog are a malformed request and change nothing.
func (s Service) SetMessagePush(ctx context.Context, actor identity.ActorContext, messageType int64, enabled bool, op operation.Context) error {
	if messageType <= 0 {
		return d.ErrInvalidMessageType
	}
	if err := s.require(); err != nil {
		return err
	}
	revision, err := s.Content.ActiveRevision(ctx, s.Fresh)
	if err != nil {
		return err
	}
	catalog, err := s.Content.MessagePushCatalogTx(ctx, s.Fresh, revision)
	if err != nil {
		return err
	}
	if !catalog.ValidMessagePush(messageType) {
		return d.ErrInvalidMessageType
	}
	return s.write(ctx, actor, op, func(preferences *d.Preferences) bool {
		if enabled {
			return preferences.AddMessagePush(messageType)
		}
		return preferences.RemoveMessagePush(messageType)
	})
}

// FirstMainTouch records the one-shot first-open marker (I9-11D C3).
func (s Service) FirstMainTouch(ctx context.Context, actor identity.ActorContext, op operation.Context) error {
	if err := s.require(); err != nil {
		return err
	}
	return s.write(ctx, actor, op, func(preferences *d.Preferences) bool {
		return preferences.MarkFirstMainTouch()
	})
}

func (s Service) write(ctx context.Context, actor identity.ActorContext, op operation.Context, change func(*d.Preferences) bool) error {
	_, err := s.Runner.Run(ctx, op, Profile(), tx.Options{Isolation: tx.Serializable}, retryPolicy(), nil, func(c context.Context, scope tx.Scope) error {
		at := scope.Operation.StartedAt
		if err := s.Fence.FenceActorTx(c, scope.Tx, actor, at); err != nil {
			return err
		}
		if _, err := s.Players.LockPlayerRootsTx(c, scope.Tx, actor.LogicalServerID, []identity.PlayerID{actor.PlayerID}); err != nil {
			return err
		}
		preferences, err := s.Store.LockTx(c, scope.Tx, actor.PlayerID, at)
		if err != nil {
			return err
		}
		if !change(&preferences) {
			return nil
		}
		expectedVersion := preferences.StateVersion
		preferences.StateVersion++
		return s.Store.SaveTx(c, scope.Tx, actor.PlayerID, preferences, expectedVersion, at)
	})
	return err
}

func (s Service) require() error {
	if s.Runner.DB == nil || s.Fresh == nil || s.Store == nil || s.Content == nil || s.Players == nil || s.Fence == nil {
		return d.ErrUnavailable
	}
	return nil
}
