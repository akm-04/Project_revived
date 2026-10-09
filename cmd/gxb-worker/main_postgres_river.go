//go:build postgres && river

package main

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/adapters/guildbroadcastworker"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	if e := run(); e != nil {
		log.Fatal(e)
	}
}
func run() error {
	c, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	dsn := os.Getenv("GXB_POSTGRES_DSN")
	if dsn == "" {
		return errors.New("Guild broadcast worker requires GXB_POSTGRES_DSN")
	}
	p, e := postgres.Open(c, dsn, postgres.PoolSettings{MaxConns: 16, MinConns: 1, MaxConnLifetime: 30 * time.Minute, MaxConnIdleTime: 5 * time.Minute, HealthCheckPeriod: 30 * time.Second, ApplicationName: "gxb-guild-broadcast-worker"})
	if e != nil {
		return e
	}
	defer p.Close()
	ready, cancel := context.WithTimeout(c, 30*time.Second)
	v, e := guildbroadcastworker.New(ready, p)
	cancel()
	if e != nil {
		return e
	}
	log.Print("Guild broadcast worker configuration validated: finite Mail/reconcile routes; acquiring separate session owner before execution")
	e = v.Run(c)
	if errors.Is(e, context.Canceled) {
		return nil
	}
	return e
}
