package generation

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"gxb.local/backend/v2/internal/foundation/operation"
)

var (
	ErrInvalidReconciler      = errors.New("invalid generation reconciler")
	ErrNoReconcileProviders   = errors.New("no generation reconciliation providers")
	ErrInvalidReconcileResult = errors.New("invalid generation reconciliation result")
)

const MaxReconcileBatch = 1000

type ReconcileResult struct {
	Provider string
	Scanned  int
	Wakeups  int
	Settled  int
	Noops    int
}

func (r ReconcileResult) validate(limit int) error {
	if strings.TrimSpace(r.Provider) == "" || r.Scanned < 0 || r.Wakeups < 0 || r.Settled < 0 || r.Noops < 0 || r.Scanned > limit {
		return ErrInvalidReconcileResult
	}
	return nil
}

// ReconcileProvider is implemented by an owning domain. It scans/reloads only
// that domain's canonical truth and transactionally ensures missing wakeups or
// performs due semantic convergence. I6A never supplies fabricated empty owner
// state on its behalf.
type ReconcileProvider interface {
	Name() string
	Reconcile(context.Context, TimedOperation, int) (ReconcileResult, error)
}

type ReconcileRegistry struct{ providers []ReconcileProvider }

func NewReconcileRegistry(in ...ReconcileProvider) (ReconcileRegistry, error) {
	seen := make(map[string]struct{}, len(in))
	providers := make([]ReconcileProvider, 0, len(in))
	for _, p := range in {
		if nilInterface(p) {
			return ReconcileRegistry{}, ErrInvalidReconciler
		}
		name := strings.TrimSpace(p.Name())
		if name == "" {
			return ReconcileRegistry{}, ErrInvalidReconciler
		}
		if _, ok := seen[name]; ok {
			return ReconcileRegistry{}, ErrInvalidReconciler
		}
		seen[name] = struct{}{}
		providers = append(providers, p)
	}
	return ReconcileRegistry{providers: providers}, nil
}

// ReconcileKernel binds one authoritative database decision instant and carries
// it unchanged through all registered owner reconcilers. A periodic River job
// may wake this kernel, but the owner providers remain gameplay authority.
type ReconcileKernel struct {
	Binder    Binder
	Providers ReconcileRegistry
}

func (k ReconcileKernel) Run(ctx context.Context, op operation.Context, limit int) ([]ReconcileResult, error) {
	if limit <= 0 || limit > MaxReconcileBatch {
		return nil, fmt.Errorf("%w: batch limit %d", ErrInvalidReconciler, limit)
	}
	if len(k.Providers.providers) == 0 {
		return nil, ErrNoReconcileProviders
	}
	timed, err := k.Binder.Bind(ctx, op)
	if err != nil {
		return nil, err
	}
	out := make([]ReconcileResult, 0, len(k.Providers.providers))
	for _, provider := range k.Providers.providers {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		result, err := provider.Reconcile(ctx, timed, limit)
		if err != nil {
			return nil, fmt.Errorf("reconcile provider %q: %w", provider.Name(), err)
		}
		if result.Provider != strings.TrimSpace(provider.Name()) {
			return nil, fmt.Errorf("%w: provider identity mismatch", ErrInvalidReconcileResult)
		}
		if err := result.validate(limit); err != nil {
			return nil, err
		}
		out = append(out, result)
	}
	return out, nil
}
