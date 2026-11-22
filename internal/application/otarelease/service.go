// Package otarelease serves the OTA read side: the MID 2 update plan and the
// cross-contract ActiveRelease view (I11A_OTA_RELEASE_V1 rulings 4 and 5).
package otarelease

import (
	"context"
	"errors"
	"time"

	domain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var ErrUnavailable = errors.New("ota release: unavailable")

// ActiveStore is the read side of ota_releases.
type ActiveStore interface {
	ListActiveTx(context.Context, tx.Queryer) ([]domain.RawRelease, error)
}

// Service plans MID 2 and summarizes the active release set.
type Service struct {
	Runner          tx.Runner
	Store           ActiveStore
	Operations      operation.Factory
	PublicEngineURL string
}

func ReadProfile() tx.Profile {
	return tx.Profile{Name: "ota-release-read-v1", AcquireTimeout: 500 * time.Millisecond, LockTimeout: 500 * time.Millisecond, StatementTimeout: 1500 * time.Millisecond, TransactionTimeout: 2 * time.Second, CleanupTimeout: 500 * time.Millisecond, ReconcileTimeout: 500 * time.Millisecond, OperationTimeout: 3 * time.Second}
}

// Plan is the MID 2 scheduler. A database failure reaches the caller as a
// fault, never as a fake no-update.
func (s Service) Plan(ctx context.Context, request domain.PlanRequest) (domain.UpdatePlan, error) {
	rows, err := s.activeRows(ctx)
	if err != nil {
		return domain.UpdatePlan{}, err
	}
	return domain.PlanUpdate(request, s.PublicEngineURL, rows)
}

// ActiveRelease is the ARCHITECTURE section 4 seam for EVENTS and OPERATOR.
func (s Service) ActiveRelease(ctx context.Context) (domain.ActiveRelease, error) {
	rows, err := s.activeRows(ctx)
	if err != nil {
		return domain.ActiveRelease{}, err
	}
	return domain.ActiveSet(rows)
}

func (s Service) activeRows(ctx context.Context) ([]domain.RawRelease, error) {
	if s.Store == nil || s.Runner.DB == nil {
		return nil, ErrUnavailable
	}
	op, err := s.Operations.New(policy.Set{})
	if err != nil {
		return nil, err
	}
	var rows []domain.RawRelease
	_, err = s.Runner.Run(ctx, op, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := s.Store.ListActiveTx(ctx, scope.Tx)
		if readErr == nil {
			rows = loaded
		}
		return readErr
	})
	if err != nil {
		return nil, err
	}
	return rows, nil
}
