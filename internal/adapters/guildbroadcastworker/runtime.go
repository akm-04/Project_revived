//go:build postgres && river

// Package guildbroadcastworker composes the two qualified Guild routes through
// the existing River runtime and application reconciliation kernel.
package guildbroadcastworker

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildbroadcaststore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Runtime has no migration or activation capability. Explicit deployment must
// install/activate compatible content and validate pinned River schema first.
type Runtime struct {
	pool       *postgres.Pool
	river      *riveradapter.Runtime
	kernel     gen.ReconcileKernel
	operations operation.Factory
}

func New(c context.Context, p *postgres.Pool) (*Runtime, error) {
	if p == nil {
		return nil, errors.New("nil Guild broadcast worker pool")
	}
	if e := riveradapter.ValidateDeployment(c, p.Raw()); e != nil {
		return nil, e
	}
	var e error
	var schema bool
	if e = p.QueryRow(c, `SELECT to_regclass('guild_broadcast_sources') IS NOT NULL AND to_regclass('guild_broadcast_recipients') IS NOT NULL AND to_regclass('content_guild_broadcast_policies') IS NOT NULL`).Scan(&schema); e != nil || !schema {
		return nil, errors.New("Guild broadcast schema not ready")
	}
	if e := (guildbroadcaststore.Store{}).ValidateSchema(c, p); e != nil {
		return nil, e
	}
	runner := tx.Runner{DB: p, Admission: tx.NewSemaphore(32)}
	registryService := registry.Service{Runner: runner, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	active, e := registryService.ValidateActiveReadiness(c)
	if e != nil {
		return nil, e
	}
	return newForRevision(c, p, active.Activation.RevisionID)
}

// PrepareDeployment validates complete finite worker dependencies for an exact
// installed revision before the explicit content activation transaction.
func PrepareDeployment(c context.Context, p *postgres.Pool, revision string) error {
	_, e := newForRevision(c, p, revision)
	return e
}
func newForRevision(c context.Context, p *postgres.Pool, revision string) (*Runtime, error) {
	if p == nil {
		return nil, errors.New("nil Guild broadcast worker pool")
	}
	if e := riveradapter.ValidateDeployment(c, p.Raw()); e != nil {
		return nil, e
	}
	var schema bool
	if e := p.QueryRow(c, `SELECT to_regclass('guild_broadcast_sources') IS NOT NULL AND to_regclass('guild_broadcast_recipients') IS NOT NULL AND to_regclass('content_guild_broadcast_policies') IS NOT NULL`).Scan(&schema); e != nil || !schema {
		return nil, errors.New("Guild broadcast schema not ready")
	}
	if e := (guildbroadcaststore.Store{}).ValidateSchema(c, p); e != nil {
		return nil, e
	}
	runner := tx.Runner{DB: p, Admission: tx.NewSemaphore(32)}
	pol, e := (contentstore.Store{}).ReadBroadcastPolicy(c, p, revision)
	if e != nil || pol.Validate() != nil {
		return nil, errors.New("active content is not Guild broadcast compatible")
	}
	source := app.ImmutableSourceReader{Store: guildbroadcaststore.Store{}, Receipts: kernelstore.Store{}, Content: contentstore.Store{}}
	target := i5.GuildBroadcastMailService{Runner: runner, Reads: runner, Sources: source, Players: i4store.PlayerRootLocker{}, Mail: i5store.Store{}, Receipts: kernelstore.Store{}}
	binder := gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}
	delivery := app.Delivery{Timed: gen.TimedRunner{Binder: binder, Runner: runner}, Reads: runner, Store: guildbroadcaststore.Store{}, Sources: source, Target: target}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		return nil, e
	}
	providers, e := gen.NewReconcileRegistry(app.Reconciler{Runner: runner, Store: guildbroadcaststore.Store{}, Sources: source, Enqueue: queue})
	if e != nil {
		return nil, e
	}
	kernel := gen.ReconcileKernel{Binder: binder, Providers: providers}
	operations := operation.Factory{Clock: clock.System{}}
	handler := app.ReconcileHandler{Kernel: kernel, Operations: operations, Batch: app.DefaultReconcileBatch}
	dispatch, e := gen.NewDispatchRegistry(gen.DispatchRegistration{Kind: app.MailKind, Profile: app.WorkerProfile, Handler: delivery}, gen.DispatchRegistration{Kind: app.ReconcileKind, Profile: app.WorkerProfile, Handler: handler})
	if e != nil {
		return nil, e
	}
	runtime, e := riveradapter.NewRuntime(p.Raw(), dispatch, riveradapter.RuntimeConfig{Queues: map[string]int{riveradapter.GuildPhysicalQueue: 4}, SoftStopTimeout: 15 * time.Second, JobTimeout: 45 * time.Second})
	if e != nil {
		return nil, e
	}
	return &Runtime{pool: p, river: runtime, kernel: kernel, operations: operations}, nil
}
func (v *Runtime) reconcile(c context.Context) error {
	c, cancel := context.WithTimeout(c, app.DeliveryOperationBudget)
	defer cancel()
	op, e := v.operations.New(policy.Set{})
	if e != nil {
		return e
	}
	_, e = v.kernel.Run(c, op, app.DefaultReconcileBatch)
	return e
}
func (v *Runtime) Run(c context.Context) error {
	if v == nil || v.pool == nil || v.river == nil {
		return errors.New("Guild broadcast worker runtime unavailable")
	}
	owner, e := postgres.AcquireGuildBroadcastOwner(c, v.pool)
	if e != nil {
		return e
	}
	defer owner.Close()
	c, stop := context.WithCancel(c)
	defer stop()
	// Prove an initial bounded canonical scan before execution starts. Missing or
	// corrupt sources block readiness rather than silently acknowledging jobs.
	if e = v.reconcile(c); e != nil {
		return e
	}
	if e = v.river.Start(c); e != nil {
		return e
	}
	events := make(chan error, 2)
	go func() { events <- owner.RunHealthPulses(c, postgres.DefaultRealtimeOwnerHealthInterval) }()
	go func() {
		tick := time.NewTicker(30 * time.Second)
		defer tick.Stop()
		for {
			select {
			case <-c.Done():
				events <- c.Err()
				return
			case <-tick.C:
				if e := v.reconcile(c); e != nil {
					events <- e
					return
				}
			}
		}
	}()
	first := <-events
	stop()
	// Drain River and join both owner loops before releasing session ownership.
	drain, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	drainErr := v.river.Stop(drain)
	cancel()
	<-events
	if drainErr != nil {
		return fmt.Errorf("Guild worker drain: %w", drainErr)
	}
	return first
}
