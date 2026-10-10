//go:build postgres

// gxb-content-gift-activate performs an explicit owning deployment transition.
// API startup never switches an existing activation pointer.
package main

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
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
	c, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()
	p, e := postgres.Open(c, os.Getenv("GXB_POSTGRES_DSN"), postgres.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		log.Fatal(e)
	}
	defer p.Close()
	s := registry.Service{Runner: tx.Runner{DB: p}, Repo: contentstore.Store{}, Fresh: p, Providers: registry.DefaultProviderSet()}
	b, e := registry.LoadBuiltinBundle()
	if e != nil {
		log.Fatal(e)
	}
	manifest, e := registry.DecodeManifestStrict(b.ManifestJSON())
	if e != nil {
		log.Fatal(e)
	}
	for _, capability := range manifest.EnabledCapabilities {
		if capability == "GUILD_INVITE_PRESENTATION_I7A8B" {
			log.Fatal("This catalog requires gxb-content-broadcast-deploy with the pinned River build, which prepares the complete phase8 bundle before activation.")
		}
	}
	factory := operation.Factory{Clock: clock.System{}}
	op, e := factory.New(policy.Set{})
	if e != nil {
		log.Fatal(e)
	}
	if _, e = s.EnsureBuiltinInstalled(c, op, b); e != nil {
		log.Fatal(e)
	}
	current, e := s.ValidateActiveReadiness(c)
	if e != nil {
		log.Fatal(e)
	}
	op, e = factory.New(policy.Set{})
	if e != nil {
		log.Fatal(e)
	}
	if _, e = s.ActivateBuiltin(c, op, b, current.Activation, "i7a7b-gift-stock-owner"); e != nil {
		log.Fatal(e)
	}
	verified, e := s.ValidateActiveReadiness(c)
	if e != nil {
		log.Fatal(e)
	}
	gift, e := (contentstore.Store{}).ReadGiftContent(c, p, verified.Activation.RevisionID)
	if e != nil || gift.Validate() != nil {
		log.Fatal("activated Gift catalog verification failed: ", e)
	}
	log.Printf("explicit Gift catalog activated revision=%s activation_version=%d; API finite consumer group validates all dependencies before exposure", verified.Activation.RevisionID, verified.Activation.Version)
}
