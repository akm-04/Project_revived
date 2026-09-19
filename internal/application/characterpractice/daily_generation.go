package characterpractice

import (
	"context"
	"errors"
	"fmt"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var alchemyLocation = time.FixedZone("GXB_GMT_PLUS_8", 8*60*60)

// AlchemyEpochStartV1 is the explicit CA6 compatibility boundary. Source only
// establishes a daily/next-day reset; midnight GMT+8 is versioned policy, not
// claimed original-server fact.
func AlchemyEpochStartV1(at time.Time) (time.Time, error) {
	if at.IsZero() {
		return time.Time{}, errors.New("character practice: zero epoch time")
	}
	local := at.In(alchemyLocation)
	start := time.Date(local.Year(), local.Month(), local.Day(), 0, 0, 0, 0, alchemyLocation)
	return start.UTC(), nil
}

type Service struct {
	Runner           tx.Runner
	Store            Store
	Content          Content
	Privileges       appi5.PrivilegeSnapshotProvider
	ReconcileQueryer tx.Queryer
	// Deps contains only the narrow cross-owner seams needed by mutating CA6-3
	// commands. Receiptless GET/daily-generation paths deliberately do not depend
	// on these ports.
	Deps ServiceDeps
}

func dailyProfile() tx.Profile {
	return tx.Profile{Name: "CA6_PRACTICE_DAILY_GENERATION", AcquireTimeout: 2 * time.Second, LockTimeout: 2 * time.Second, StatementTimeout: 5 * time.Second, TransactionTimeout: 8 * time.Second, CleanupTimeout: 2 * time.Second, ReconcileTimeout: 5 * time.Second, OperationTimeout: 12 * time.Second}
}

func bindPolicyRef(op operation.Context, name, version string) (operation.Context, error) {
	if name == "" || version == "" {
		return operation.Context{}, errors.New("character practice: blank policy reference")
	}
	if got, ok := op.Policies.Get(name); ok {
		if got != version {
			return operation.Context{}, fmt.Errorf("character practice: policy %s conflict", name)
		}
		return op, nil
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: name, Version: version})
	set, err := policy.NewSet(refs...)
	if err != nil {
		return operation.Context{}, err
	}
	op.Policies = set
	return op, nil
}

func (s Service) bindDailyOperation(ctx context.Context, op operation.Context) (operation.Context, string, error) {
	if op.ID.IsZero() || op.StartedAt.IsZero() {
		return operation.Context{}, "", errors.New("character practice: invalid operation context")
	}
	var revision string
	if pinned, ok := op.Policies.Get("content"); ok {
		good, err := s.Content.PracticeRevision(ctx, pinned)
		if err != nil {
			return operation.Context{}, "", err
		}
		if !good {
			return operation.Context{}, "", ErrContentInactive
		}
		revision = pinned
	} else {
		active, good, err := s.Content.PracticeActive(ctx)
		if err != nil {
			return operation.Context{}, "", err
		}
		if !good {
			return operation.Context{}, "", ErrContentInactive
		}
		revision = active
		op, err = bindPolicyRef(op, "content", revision)
		if err != nil {
			return operation.Context{}, "", err
		}
	}
	var err error
	op, err = bindPolicyRef(op, DailyEpochPolicyRef, DailyEpochPolicyV1)
	if err != nil {
		return operation.Context{}, "", err
	}
	return op, revision, nil
}

func (s Service) validateDaily() error {
	if s.Runner.DB == nil || s.Store == nil || s.Content == nil || s.Privileges == nil || s.ReconcileQueryer == nil {
		return errors.New("character practice: incomplete daily-generation service")
	}
	return nil
}

// EnsureDailyGeneration materializes at most one strictly newer Alchemy daily
// generation. It is receiptless by contract: unknown COMMIT is reconciled by
// the durable monotonic generation postcondition, never by transport success.
func (s Service) EnsureDailyGeneration(ctx context.Context, pid identity.PlayerID, op operation.Context) (Root, error) {
	if err := s.validateDaily(); err != nil {
		return Root{}, err
	}
	if !pid.Valid() {
		return Root{}, errors.New("character practice: invalid player")
	}
	bound, revision, err := s.bindDailyOperation(ctx, op)
	if err != nil {
		return Root{}, err
	}
	desired, err := AlchemyEpochStartV1(bound.StartedAt)
	if err != nil {
		return Root{}, err
	}

	// Cheap current-generation path. The transaction rechecks under Root450 if
	// materialization is required.
	if current, err := s.Store.ReadPracticeRootTx(ctx, s.ReconcileQueryer, pid); err == nil {
		if generationAtLeast(current, desired) {
			return current, nil
		}
	} else if !errors.Is(err, ErrRootMissing) {
		return Root{}, err
	}

	var attempted Root
	resolver := generationResolver{Store: s.Store, Queryer: s.ReconcileQueryer, PlayerID: pid, DesiredEpoch: desired, PolicyVersion: DailyEpochPolicyV1, ContentRevision: revision}
	_, err = s.Runner.Run(ctx, bound, dailyProfile(), tx.Options{Isolation: tx.ReadCommitted}, tx.RetryPolicy{MaxAttempts: 3, RetryDefiniteAbort: true}, resolver, func(txctx context.Context, scope tx.Scope) error {
		root, err := s.Store.LockPracticeRootTx(txctx, scope.Tx, pid)
		if err != nil {
			return err
		}
		next, changed, err := s.planDailyGenerationTx(txctx, scope.Tx, root, desired, bound, revision)
		if err != nil {
			return err
		}
		if !changed {
			attempted = root
			return nil
		}
		if err := s.Store.SaveGenerationTx(txctx, scope.Tx, next, root.StateVersion); err != nil {
			return err
		}
		attempted = next
		return nil
	})
	if err != nil {
		return Root{}, err
	}

	// Return durable truth rather than merely the attempted in-memory state. This
	// also covers a reconciled unknown COMMIT and a concurrent later generation.
	fresh, err := s.Store.ReadPracticeRootTx(ctx, s.ReconcileQueryer, pid)
	if err != nil {
		return Root{}, err
	}
	if !generationAtLeast(fresh, desired) {
		return Root{}, errors.New("character practice: daily generation postcondition missing after commit")
	}
	_ = attempted
	return fresh, nil
}

// planDailyGenerationTx computes the one Root450 transition for a locked root
// but performs no write. Manual/ticket commands reuse this helper after they
// already own Root450, then fold any generation changes into their single final
// SaveAccountingTx CAS instead of nesting EnsureDailyGeneration.
func (s Service) planDailyGenerationTx(ctx context.Context, q tx.Queryer, root Root, desired time.Time, bound operation.Context, revision string) (Root, bool, error) {
	if q == nil || root.Validate() != nil || desired.IsZero() || bound.StartedAt.IsZero() || revision == "" {
		return Root{}, false, errors.New("character practice: invalid daily-generation plan input")
	}
	if generationAtLeast(root, desired) {
		return root, false, nil
	}
	snap, err := s.Privileges.SnapshotTx(ctx, q, root.PlayerID, bound.StartedAt.UTC())
	if err != nil {
		return Root{}, false, err
	}
	if snap.ProviderRevision == "" || snap.VIPLevel < 0 || snap.VIPLevel > 15 {
		return Root{}, false, errors.New("character practice: invalid privilege snapshot")
	}
	capacity, err := s.Content.PracticeVIPBlessTx(ctx, q, revision, snap.VIPLevel)
	if err != nil {
		return Root{}, false, err
	}
	if capacity < 0 {
		return Root{}, false, errors.New("character practice: negative Bless capacity")
	}

	next := root
	e := desired
	v := snap.VIPLevel
	next.DailyEpochStartAt = &e
	next.DailyEpochPolicyVersion = DailyEpochPolicyV1
	next.BlessRemaining = capacity
	next.BlessCapacityAtEpoch = capacity
	next.BlessVIPLevelAtEpoch = &v
	next.BlessPrivilegeProviderRevision = snap.ProviderRevision
	next.BlessContentRevision = revision
	next.BaseMana = 0
	next.BaseCrystal = 0
	next.StateVersion = root.StateVersion + 1
	next.UpdatedAt = bound.StartedAt.UTC()
	if err := next.Validate(); err != nil {
		return Root{}, false, err
	}
	return next, true, nil
}

func generationAtLeast(root Root, desired time.Time) bool {
	return root.DailyEpochStartAt != nil && !root.DailyEpochStartAt.Before(desired)
}

type generationResolver struct {
	Store           Store
	Queryer         tx.Queryer
	PlayerID        identity.PlayerID
	DesiredEpoch    time.Time
	PolicyVersion   string
	ContentRevision string
}

func (r generationResolver) Resolve(ctx context.Context, _ tx.ResolutionRequest) (tx.Resolution, error) {
	if r.Store == nil || r.Queryer == nil || !r.PlayerID.Valid() || r.DesiredEpoch.IsZero() {
		return tx.Resolution{State: tx.ResolutionUnknown}, errors.New("character practice: invalid generation resolver")
	}
	root, err := r.Store.ReadPracticeRootTx(ctx, r.Queryer, r.PlayerID)
	if err != nil {
		if errors.Is(err, ErrRootMissing) {
			return tx.Resolution{State: tx.ResolutionUnknown}, nil
		}
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	if !generationAtLeast(root, r.DesiredEpoch) {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	// A strictly later durable generation also proves the requested monotonic
	// postcondition. For the exact requested generation, require its frozen
	// policy/content provenance before declaring the ambiguous commit visible.
	if root.DailyEpochStartAt.Equal(r.DesiredEpoch) && (root.DailyEpochPolicyVersion != r.PolicyVersion || root.BlessContentRevision != r.ContentRevision) {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: root}, nil
}
