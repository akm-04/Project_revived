package i5

import (
	"context"
	"errors"
	"time"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Every content generation moves the active revision while temporal rows keep the revision they were written under, and
// grants refuse a mixed revision (PASS480). The deployment re-pins them explicitly (D98); activation alone still migrates nothing.

var repinnedTemporalKeys = []string{"energy", "skill_point", "spirit_energy", WorkplaceSPKey}

type StaleTemporalDirectory interface {
	StaleTemporalPlayersTx(context.Context, tx.Queryer, string) ([]identity.PlayerID, error)
}

// RepinTemporalTx moves the player's immutable temporal rows to target inside the caller's transaction; legacy rows and rows
// already on target stay as they are. The re-pin is idempotent because the row itself records its revision.
func (s Service) RepinTemporalTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, target string, now time.Time) error {
	if s.Store == nil || s.Content == nil || t == nil || !pid.Valid() || now.IsZero() {
		return errors.New("invalid temporal repin")
	}
	if err := validateContentRevision(target); err != nil {
		return err
	}
	// Frozen R5 ordering: owner 700, progression 710, temporal 721.
	if err := s.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return err
	}
	progression, err := s.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return err
	}
	for _, key := range repinnedTemporalKeys {
		state, exists, err := s.Store.LockTemporalTx(ctx, t, pid, key)
		if err != nil {
			return err
		}
		if !exists || state.ContentRevision == "" || state.ContentRevision == target {
			continue
		}
		oldPolicy, err := s.temporalPolicyAtTx(ctx, t, pid, key, state.ContentRevision, progression.Level, now)
		if err != nil {
			return err
		}
		newPolicy, err := s.temporalPolicyAtTx(ctx, t, pid, key, target, progression.Level, now)
		if err != nil {
			return err
		}
		after, err := state.RepinPolicy(target, now, oldPolicy, newPolicy)
		if err != nil {
			return err
		}
		if err := s.Store.SaveTemporalTx(ctx, t, after); err != nil {
			return err
		}
	}
	return nil
}

func (s Service) temporalPolicyAtTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, key, revision string, level int64, now time.Time) (economy.TemporalPolicy, error) {
	resource, err := s.Content.ResolveResourceTx(ctx, q, revision, grant.Line{Kind: grant.Temporal, ResourceKey: key, Amount: 1})
	if err != nil {
		return economy.TemporalPolicy{}, err
	}
	if resource.Descriptor == nil || resource.Descriptor.Revision != revision {
		return economy.TemporalPolicy{}, economy.ErrInvalidTemporalPolicy
	}
	var progression player.ProgressionPolicy
	if resource.Descriptor.CapRule == "PLAYER_LEVEL_ENERGY" {
		if progression, err = s.Content.ResolveProgressionPolicyTx(ctx, q, revision); err != nil {
			return economy.TemporalPolicy{}, err
		}
	}
	policy, _, err := s.resolveTemporalPolicyTx(ctx, q, pid, *resource.Descriptor, progression, level, now)
	return policy, err
}

// RunTemporalRepin re-pins every stale player to target, one transaction per player at authoritative time.
func RunTemporalRepin(c context.Context, timed gen.TimedRunner, owner Service, players StaleTemporalDirectory, target string, op operation.Context) error {
	var stale []identity.PlayerID
	res, err := timed.Runner.Run(c, op, owner.profile(), tx.Options{Isolation: tx.RepeatableRead}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc tx.Scope) error {
		var err error
		stale, err = players.StaleTemporalPlayersTx(c, sc.Tx, target)
		return err
	})
	if err != nil {
		return err
	}
	if res.Outcome != tx.DefiniteCommit {
		return errors.New("i5: unresolved stale temporal enumeration")
	}
	for _, pid := range stale {
		_, res, err = timed.Run(c, op, owner.profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, nil, func(c context.Context, sc gen.TimedScope) error {
			return owner.RepinTemporalTx(c, sc.Tx, pid, target, sc.Operation.DecisionAt())
		})
		if err != nil {
			return err
		}
		if res.Outcome != tx.DefiniteCommit {
			return errors.New("i5: unresolved temporal repin")
		}
	}
	return nil
}
