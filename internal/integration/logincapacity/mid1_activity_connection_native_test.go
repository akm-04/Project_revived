//go:build postgres

package logincapacity_test

import (
	"context"
	"fmt"
	"os"
	"sync"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/activitystore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	appactivity "gxb.local/backend/v2/internal/application/activitydirectory"
	appworldboss "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const loginConcurrency = 8

// productionActivityDirectory mirrors cmd/gxb-api's MID1 wiring: the worldboss
// provider keeps the process pool as its own queryer. Inside an open MID1
// transaction it must read through the caller's transaction instead.
func productionActivityDirectory(p *postgres.Pool) appactivity.Directory {
	caps, err := appactivity.NewStaticContentCapabilities(nil)
	if err != nil {
		panic(err)
	}
	registry, err := appactivity.NewRegistry([]appactivity.Registration{{
		Name:              "worldboss",
		TableID:           1026,
		RuntimeCapability: "activity.worldboss",
		Provider:          appworldboss.ActivityProvider{Queryer: p, Directory: i4store.PlayerDirectoryReader{}},
	}}, caps)
	if err != nil {
		panic(err)
	}
	return appactivity.Directory{Registry: registry}
}

func nativeActor(t *testing.T, index int64) identity.ActorContext {
	t.Helper()
	mk := func() ids.UUID {
		u, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		return u
	}
	account, err := identity.AccountIDFrom(mk())
	if err != nil {
		t.Fatal(err)
	}
	session, err := identity.SessionIDFrom(mk())
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := identity.ContextIDFrom(mk())
	if err != nil {
		t.Fatal(err)
	}
	return identity.ActorContext{
		AccountID: account, AccountUID: "login-capacity", SessionID: session, ContextID: contextID,
		LogicalServerID: 1, PlayerID: identity.PlayerID(900000 + index),
		ContextGeneration: 1, SessionLivenessVersion: 1, ContextLivenessVersion: 1,
	}
}

func nativePool(t *testing.T, maxConnections int32) *postgres.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_LOGIN_CAPACITY_DSN")
	if dsn == "" {
		t.Fatal("GXB_LOGIN_CAPACITY_DSN is required")
	}
	p, err := postgres.Open(context.Background(), dsn, postgres.PoolSettings{
		MaxConns: maxConnections, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute,
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	return p
}

// TestMID1ActivityDetailDoesNotAcquireSecondPoolConnection reproduces the login
// collapse: every admitted MID1 SERIALIZABLE transaction holds one pool
// connection, and the activity detail contributor must not ask the same pool
// for a second one. With the pool exactly as large as the concurrent logins,
// the unfixed wiring blocks in pool acquisition until each context expires.
func TestMID1ActivityDetailDoesNotAcquireSecondPoolConnection(t *testing.T) {
	p := nativePool(t, loginConcurrency)
	contributor := activitystore.BootstrapProjection{Directory: productionActivityDirectory(p)}
	observedAt := time.Now().UTC()

	actors := make([]identity.ActorContext, loginConcurrency)
	for index := range actors {
		actors[index] = nativeActor(t, int64(index))
	}

	var ready, done sync.WaitGroup
	start := make(chan struct{})
	failures := make(chan error, loginConcurrency)
	ready.Add(loginConcurrency)
	done.Add(loginConcurrency)
	for index := int64(0); index < loginConcurrency; index++ {
		go func(index int64) {
			defer done.Done()
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
			if err != nil {
				failures <- fmt.Errorf("login %d begin: %w", index, err)
				ready.Done()
				return
			}
			defer transaction.Rollback(ctx)
			ready.Done()
			<-start
			detail := map[string]any{}
			if err := contributor.OverlayMID1(ctx, transaction, actors[index], false, observedAt, detail); err != nil {
				failures <- fmt.Errorf("login %d activity detail: %w", index, err)
				return
			}
			projection, ok := detail["229"].(map[string]any)
			if !ok {
				failures <- fmt.Errorf("login %d: MID229 projection missing", index)
				return
			}
			rows, ok := projection["list"].([]any)
			if !ok || len(rows) != 1 {
				failures <- fmt.Errorf("login %d: MID229 list = %#v", index, projection["list"])
				return
			}
			row, ok := rows[0].(map[string]any)
			if !ok || row["table_id"] != int64(1026) {
				failures <- fmt.Errorf("login %d: MID229 row = %#v", index, rows[0])
				return
			}
			if err := transaction.Commit(ctx); err != nil {
				failures <- fmt.Errorf("login %d commit: %w", index, err)
			}
		}(index)
	}
	ready.Wait()
	close(start)
	done.Wait()
	close(failures)
	for err := range failures {
		t.Error(err)
	}
}
