package registry

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// StartupRegistry separates deployment startup from gameplay/HTTP admission.
// Migrations are a prerequisite; this seam never executes them or switches an existing pointer.
type StartupRegistry interface {
	EnsureBuiltinInstalled(context.Context, operation.Context, Bundle) (tx.Result, error)
	BootstrapActivationIfMissing(context.Context, operation.Context, Bundle) (tx.Result, error)
	ValidateActiveReadiness(context.Context) (ActiveSummary, error)
}

func Initialize(ctx context.Context, svc StartupRegistry, factory operation.Factory) (ActiveSummary, error) {
	b, err := LoadBuiltinBundle()
	if err != nil {
		return ActiveSummary{}, err
	}
	install, err := factory.New(policy.Set{})
	if err != nil {
		return ActiveSummary{}, err
	}
	if _, err = svc.EnsureBuiltinInstalled(ctx, install, b); err != nil {
		return ActiveSummary{}, fmt.Errorf("install content: %w", err)
	}
	activate, err := factory.New(policy.Set{})
	if err != nil {
		return ActiveSummary{}, err
	}
	if _, err = svc.BootstrapActivationIfMissing(ctx, activate, b); err != nil {
		return ActiveSummary{}, fmt.Errorf("bootstrap content: %w", err)
	}
	return svc.ValidateActiveReadiness(ctx)
}
