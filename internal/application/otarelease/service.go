// Package otarelease serves the OTA read side: the MID 2 update plan and the
// cross-contract ActiveRelease view (I11A_OTA_RELEASE_V1 rulings 4 and 5).
package otarelease

import (
	"context"
	"errors"
	"fmt"
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
	ListActiveDescriptorsTx(context.Context, tx.Queryer) ([]domain.RawRelease, error)
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
	if s.Store == nil {
		return domain.UpdatePlan{}, ErrUnavailable
	}
	rows, err := s.activeRows(ctx, s.Store.ListActiveDescriptorsTx)
	if err != nil {
		return domain.UpdatePlan{}, err
	}
	return domain.PlanUpdate(request, s.PublicEngineURL, rows)
}

// ActiveRows exposes the manifest read to the serving view, which needs both
// the union of shipped paths and each release's package volumes.
func (s Service) ActiveRows(ctx context.Context) ([]domain.RawRelease, error) {
	if s.Store == nil {
		return nil, ErrUnavailable
	}
	return s.activeRows(ctx, s.Store.ListActiveTx)
}

// StartupCheck refuses to start when ACTIVE rows exist without an OTA root, or
// when an ACTIVE volume is missing or differs from its registered size.
func (s Service) StartupCheck(ctx context.Context, root string) error {
	rows, err := s.ActiveRows(ctx)
	if err != nil {
		return err
	}
	releases, err := domain.ParseReleases(rows)
	if err != nil {
		return err
	}
	if root == "" {
		if len(releases) == 0 {
			return nil
		}
		release := releases[0]
		return fmt.Errorf("OTA root (GXB_OTA_ROOT) is not configured but ACTIVE release %s volume %s exists", release.Version, release.Volumes[0].Name)
	}
	return VerifyActiveVolumes(releases, root)
}

// ActiveRelease is the ARCHITECTURE section 4 seam for EVENTS and OPERATOR.
func (s Service) ActiveRelease(ctx context.Context) (domain.ActiveRelease, error) {
	if s.Store == nil {
		return domain.ActiveRelease{}, ErrUnavailable
	}
	rows, err := s.activeRows(ctx, s.Store.ListActiveTx)
	if err != nil {
		return domain.ActiveRelease{}, err
	}
	return domain.ActiveSet(rows)
}

// activeRows runs the read-only RepeatableRead transaction over one active-set
// read; Plan passes the descriptor read, ActiveRelease the manifest read.
func (s Service) activeRows(ctx context.Context, read func(context.Context, tx.Queryer) ([]domain.RawRelease, error)) ([]domain.RawRelease, error) {
	if s.Store == nil || s.Runner.DB == nil {
		return nil, ErrUnavailable
	}
	op, err := s.Operations.New(policy.Set{})
	if err != nil {
		return nil, err
	}
	var rows []domain.RawRelease
	_, err = s.Runner.Run(ctx, op, ReadProfile(), tx.Options{Isolation: tx.RepeatableRead, ReadOnly: true}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(ctx context.Context, scope tx.Scope) error {
		loaded, readErr := read(ctx, scope.Tx)
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
