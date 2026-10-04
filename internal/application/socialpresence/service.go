package socialpresence

import (
	"context"
	"errors"
	"time"

	appgeneration "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Store is the canonical SocialPresence owner port. Every method mutates or
// reads only SocialPresence-owned root/lease state.
type Store interface {
	EnsureAndLockRootTx(context.Context, tx.Tx, identity.PlayerID, time.Time) error
	SettleExpiredTx(context.Context, tx.Tx, identity.PlayerID, time.Time) (ExpiredSummary, error)
	UpsertLeaseTx(context.Context, tx.Tx, LeaseRef, time.Time, time.Time) error
	DeleteExactLeaseTx(context.Context, tx.Tx, LeaseRef) (time.Time, bool, error)
	AdvanceLastSeenTx(context.Context, tx.Tx, identity.PlayerID, time.Time, time.Time) (bool, error)
}

type ObservationStore interface {
	ReadManyAt(context.Context, []identity.PlayerID, time.Time) (map[identity.PlayerID]Observation, error)
}

type ExpiredPlayerStore interface {
	ExpiredPlayerIDs(context.Context, time.Time, int) ([]identity.PlayerID, error)
}

type Service struct {
	Timed appgeneration.TimedRunner
	Store Store
}

func DefaultProfile() tx.Profile {
	return tx.Profile{
		Name:               "I7A3_SOCIAL_PRESENCE",
		AcquireTimeout:     2 * time.Second,
		LockTimeout:        2 * time.Second,
		StatementTimeout:   5 * time.Second,
		TransactionTimeout: 8 * time.Second,
		CleanupTimeout:     2 * time.Second,
		ReconcileTimeout:   5 * time.Second,
		OperationTimeout:   12 * time.Second,
	}
}

func retryPolicy() tx.RetryPolicy {
	return tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}
}

func (s Service) validate() error {
	if s.Store == nil || s.Timed.Runner.DB == nil || s.Timed.Binder.Time == nil {
		return errors.New("social presence: incomplete service")
	}
	return nil
}

// Admit installs the derived lease after canonical realtime authorization and
// registry generation establishment. ttl is the admitted realtime idle horizon.
func (s Service) Admit(ctx context.Context, op operation.Context, ref LeaseRef, ttl time.Duration) error {
	if err := s.validateMutation(op, ref, ttl); err != nil {
		return err
	}
	_, _, err := s.Timed.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retryPolicy(), nil,
		func(txctx context.Context, scope appgeneration.TimedScope) error {
			at := scope.Operation.DecisionAt()
			if err := s.Store.EnsureAndLockRootTx(txctx, scope.Tx, ref.PlayerID, at); err != nil {
				return err
			}
			settled, err := s.Store.SettleExpiredTx(txctx, scope.Tx, ref.PlayerID, at)
			if err != nil {
				return err
			}
			if settled.MaxExpiredAt != nil && !settled.HasLiveLease {
				if _, err := s.Store.AdvanceLastSeenTx(txctx, scope.Tx, ref.PlayerID, *settled.MaxExpiredAt, at); err != nil {
					return err
				}
			}
			return s.Store.UpsertLeaseTx(txctx, scope.Tx, ref, at, at.Add(ttl))
		})
	return err
}

// Renew is intentionally identical to Admit at the owner boundary: an exact
// heartbeat can repair a missing derived admission lease, while store CAS keeps
// a stale generation from superseding a newer one.
func (s Service) Renew(ctx context.Context, op operation.Context, ref LeaseRef, ttl time.Duration) error {
	return s.Admit(ctx, op, ref, ttl)
}

// Retire removes only the exact process+generation lease. If that was the final
// live lease, it advances the durable latest offline transition.
func (s Service) Retire(ctx context.Context, op operation.Context, ref LeaseRef) error {
	if err := s.validateMutation(op, ref, time.Second); err != nil {
		return err
	}
	_, _, err := s.Timed.Run(ctx, op, DefaultProfile(), tx.Options{Isolation: tx.Serializable}, retryPolicy(), nil,
		func(txctx context.Context, scope appgeneration.TimedScope) error {
			at := scope.Operation.DecisionAt()
			if err := s.Store.EnsureAndLockRootTx(txctx, scope.Tx, ref.PlayerID, at); err != nil {
				return err
			}
			exactExpiry, found, err := s.Store.DeleteExactLeaseTx(txctx, scope.Tx, ref)
			if err != nil || !found {
				return err
			}
			settled, err := s.Store.SettleExpiredTx(txctx, scope.Tx, ref.PlayerID, at)
			if err != nil {
				return err
			}
			if settled.HasLiveLease {
				return nil
			}
			candidate := exactExpiry
			if at.Before(candidate) {
				candidate = at
			}
			if settled.MaxExpiredAt != nil && settled.MaxExpiredAt.After(candidate) {
				candidate = *settled.MaxExpiredAt
			}
			_, err = s.Store.AdvanceLastSeenTx(txctx, scope.Tx, ref.PlayerID, candidate, at)
			return err
		})
	return err
}

func (s Service) validateMutation(op operation.Context, ref LeaseRef, ttl time.Duration) error {
	if err := s.validate(); err != nil {
		return err
	}
	if op.ID.IsZero() || op.StartedAt.IsZero() || ttl <= 0 {
		return ErrInvalidLease
	}
	return ref.Validate()
}

// Reader binds one PostgreSQL-authoritative instant for the entire batch.
type Reader struct {
	Time  appgeneration.TimeAuthority
	Store ObservationStore
}

func (r Reader) ReadMany(ctx context.Context, playerIDs []identity.PlayerID) (map[identity.PlayerID]Observation, error) {
	if r.Time == nil || r.Store == nil {
		return nil, errors.New("social presence: incomplete reader")
	}
	if len(playerIDs) == 0 {
		return map[identity.PlayerID]Observation{}, nil
	}
	for _, pid := range playerIDs {
		if !pid.Valid() {
			return nil, ErrInvalidObservation
		}
	}
	at, err := r.Time.Now(ctx)
	if err != nil {
		return nil, err
	}
	return r.Store.ReadManyAt(ctx, playerIDs, at.UTC())
}
