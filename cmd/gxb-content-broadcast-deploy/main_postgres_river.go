//go:build postgres && river

// gxb-content-broadcast-deploy is an explicit owning deployment transition.
// Backend physical migrations are a prerequisite. API and worker startup never
// migrate River or switch an existing active content pointer.
package main

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/guildbroadcastworker"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	appdorm "gxb.local/backend/v2/internal/application/dormhouse"
	gen "gxb.local/backend/v2/internal/application/generation"
	applib "gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/content/registry"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"log"
	"os"
	"time"
)

func main() {
	if e := deploy(); e != nil {
		log.Fatal(e)
	}
}
func deploy() error {
	c, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()
	dsn := os.Getenv("GXB_POSTGRES_DSN")
	if dsn == "" {
		return errors.New("explicit Guild broadcast deployment requires GXB_POSTGRES_DSN")
	}
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		return e
	}
	defer p.Close()
	if e = riveradapter.DeploySchema(c, p.Raw()); e != nil {
		return e
	}
	store := contentstore.Store{}
	service := registry.Service{Runner: tx.Runner{DB: p}, Repo: store, Fresh: p, Providers: registry.DefaultProviderSet()}
	bundle, e := registry.LoadBuiltinBundle()
	if e != nil {
		return e
	}
	factory := operation.Factory{Clock: clock.System{}}
	op, e := factory.New(policy.Set{})
	if e != nil {
		return e
	}
	if _, e = service.EnsureBuiltinInstalled(c, op, bundle); e != nil {
		return e
	}
	if e = applib.RunBackfill(c, gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: service.Runner}, characterstore.Store{}, librarystore.Store{}, op); e != nil {
		return e
	}
	if e = appdorm.RunBackfill(c, gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: service.Runner}, characterstore.Store{}, dormstore.Store{}, bundle.RevisionID(), op); e != nil {
		return e
	}
	if e = appbook.RunBackfill(c, gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: service.Runner}, characterstore.Store{}, bookstore.Store{}, bundle.RevisionID(), op); e != nil {
		return e
	}
	if e = guildbroadcastworker.PrepareDeployment(c, p, bundle.RevisionID()); e != nil {
		return e
	}
	op, e = factory.New(policy.Set{})
	if e != nil {
		return e
	}
	_, exists, e := store.ReadActivation(c, p)
	if e != nil {
		return e
	}
	if !exists {
		_, e = service.BootstrapActivationIfMissing(c, op, bundle)
	} else {
		current, e2 := service.ValidateActiveReadiness(c)
		if e2 != nil {
			return e2
		}
		_, e = service.ActivateBuiltin(c, op, bundle, current.Activation, "i7a8-guild-broadcast-invite-owner")
	}
	if e != nil {
		return e
	}
	if _, e = guildbroadcastworker.New(c, p); e != nil {
		return e
	}
	active, e := service.ValidateActiveReadiness(c)
	if e != nil {
		return e
	}
	log.Printf("explicit Guild broadcast deployment complete: revision=%s activation_version=%d; finite source API and Mail/reconcile worker dependencies validated", active.Activation.RevisionID, active.Activation.Version)
	return nil
}
