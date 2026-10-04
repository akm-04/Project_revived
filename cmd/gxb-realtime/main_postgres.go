//go:build postgres

package main

import (
	"context"
	"errors"
	"log"
	"net"
	"os"
	"os/signal"
	"strconv"
	"sync"
	"syscall"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildprojection"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appgeneration "gxb.local/backend/v2/internal/application/generation"
	appidentity "gxb.local/backend/v2/internal/application/identitylifecycle"
	apprealtime "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/application/socialpresence"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/config"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
	"gxb.local/backend/v2/internal/protocol/limits"
)

func main() {
	cfg := config.FromEnv()
	digestSecret := []byte(os.Getenv("GXB_CREDENTIAL_DIGEST_SECRET"))
	bearerSecret := []byte(os.Getenv("GXB_GAMEPLAY_BEARER_SECRET"))
	keyID := os.Getenv("GXB_DERIVATION_KEY_ID")
	host := os.Getenv("GXB_REALTIME_PUBLIC_HOST")
	port, err := strconv.Atoi(os.Getenv("GXB_REALTIME_PUBLIC_PORT"))
	if err != nil || port <= 0 || port > 65535 || host == "" {
		log.Fatal("valid advertised realtime endpoint required")
	}
	if len(cfg.PostgresDSN) == 0 || len(digestSecret) < 16 || len(bearerSecret) < 16 || keyID == "" {
		log.Fatal("I4 PostgreSQL/credential configuration incomplete")
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	pool, err := postgres.Open(ctx, string(cfg.PostgresDSN), postgres.PoolSettings{
		MaxConns: 16, MinConns: 1, MaxConnLifetime: 30 * time.Minute,
		MaxConnIdleTime: 5 * time.Minute, HealthCheckPeriod: 30 * time.Second,
		ApplicationName: "gxb-v2-i4-realtime",
	})
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatal(err)
	}
	ownerGuard, err := postgres.AcquireRealtimeOwner(ctx, pool)
	if err != nil {
		log.Fatalf("realtime single-owner acquisition failed: %v", err)
	}
	defer func() {
		if err := ownerGuard.Close(); err != nil {
			log.Printf("realtime owner guard close: %v", err)
		}
	}()
	realtimeInstanceID, err := ids.NewUUID()
	if err != nil {
		log.Fatalf("realtime process instance id: %v", err)
	}
	go func() {
		if err := ownerGuard.RunHealthPulses(ctx, postgres.DefaultRealtimeOwnerHealthInterval); err != nil && ctx.Err() == nil {
			log.Printf("realtime owner session lost: %v", err)
			stop()
		}
	}()
	bearerKeys := appidentity.StaticBearerKeyResolver{Key: appidentity.BearerDerivationKey{ID: keyID, Secret: bearerSecret}}
	authority := i4store.RealtimeAuthority{Queryer: pool, DigestSecret: digestSecret, BearerSecret: bearerSecret, DerivationKeyID: keyID, BearerKeys: bearerKeys}
	auth := apprealtime.Service{
		Authority: authority,
		Guilds:    guildprojection.RealtimeMembership{Queryer: pool},
		Endpoints: stockruntime.StaticEndpoints{Endpoint: apprealtime.Endpoint{Host: host, Port: port}},
	}
	runtimePolicy, err := stockruntime.RealtimePolicyFromEnv(os.Getenv)
	if err != nil {
		log.Fatalf("invalid realtime policy: %v", err)
	}
	admission, err := stockruntime.NewAdmissionLimiter(runtimePolicy)
	if err != nil {
		log.Fatalf("invalid realtime admission policy: %v", err)
	}
	tracker := lobby.NewBootTracker()
	evidenceCfg, evidenceEnabled, err := lobby.EvidenceConfigFromEnv(lobby.ProcessRealtime, os.Getenv)
	if err != nil {
		log.Fatalf("invalid Wave-S evidence configuration: %v", err)
	}
	if evidenceEnabled {
		tracker, err = lobby.NewCapturedBootTracker(evidenceCfg)
		if err != nil {
			log.Fatal(err)
		}
		defer func() {
			if err := tracker.Close(); err != nil {
				log.Printf("Wave-S evidence close: %v", err)
			}
		}()
		go func() {
			if err := tracker.RunHealthPulses(ctx, lobby.DefaultEvidenceHealthInterval); err != nil && ctx.Err() == nil {
				log.Printf("Wave-S evidence unhealthy: %v", err)
			}
		}()
	}
	presenceStore := presencestore.Store{Queryer: pool}
	presenceRunner := tx.Runner{DB: pool}
	presenceService := socialpresence.Service{
		Timed: appgeneration.TimedRunner{
			Binder: appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}},
			Runner: presenceRunner,
		},
		Store: presenceStore,
	}
	presenceOperations := operation.Factory{Clock: clock.System{}}
	presenceProviders, err := appgeneration.NewReconcileRegistry(socialpresence.Reconciler{
		Runner: presenceRunner, Store: presenceStore, Expired: presenceStore,
	})
	if err != nil {
		log.Fatalf("social presence reconciler registry: %v", err)
	}
	presenceReconcile := appgeneration.ReconcileKernel{
		Binder:    appgeneration.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}},
		Providers: presenceProviders,
	}
	runPresenceReconcile := func(stage string) {
		op, err := presenceOperations.New(policy.Set{})
		if err != nil {
			log.Printf("social presence reconcile %s operation degraded: %v", stage, err)
			return
		}
		results, err := presenceReconcile.Run(ctx, op, appgeneration.MaxReconcileBatch)
		if err != nil {
			log.Printf("social presence reconcile %s degraded: %v", stage, err)
			return
		}
		for _, result := range results {
			if result.Settled > 0 {
				log.Printf("social presence reconcile %s provider=%s scanned=%d settled=%d noops=%d", stage, result.Provider, result.Scanned, result.Settled, result.Noops)
			}
		}
	}
	runPresenceReconcile("startup")
	go func() {
		ticker := time.NewTicker(runtimePolicy.LivenessInterval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				runPresenceReconcile("periodic")
			}
		}
	}()
	server := stockruntime.RealtimeServer{
		Auth: auth, Limits: limits.Default(), Policy: runtimePolicy, Tracker: tracker,
		Registry: stockruntime.NewConnectionRegistry(), Admission: admission,
		Presence: presenceService, PresenceOperations: presenceOperations,
		RealtimeInstanceID: realtimeInstanceID,
		OnPresenceError:    func(stage string, err error) { log.Printf("social presence %s degraded: %v", stage, err) },
	}

	ln, err := net.Listen("tcp", cfg.RealtimeAddr)
	if err != nil {
		log.Fatal(err)
	}
	defer ln.Close()
	go func() { <-ctx.Done(); _ = ln.Close() }()
	log.Printf("gxb-realtime I4 listening on %s", cfg.RealtimeAddr)
	listenerSlots := make(chan struct{}, runtimePolicy.MaxConnections)
	var connections sync.WaitGroup
	defer connections.Wait()
	for {
		conn, err := ln.Accept()
		if err != nil {
			if ctx.Err() != nil || errors.Is(err, net.ErrClosed) {
				return
			}
			log.Printf("realtime accept: %v", err)
			continue
		}
		select {
		case listenerSlots <- struct{}{}:
		default:
			_ = conn.Close()
			continue
		}
		connections.Add(1)
		go func(c net.Conn) {
			defer connections.Done()
			defer func() { <-listenerSlots }()
			defer c.Close()
			if err := server.ServeConn(ctx, c); err != nil && ctx.Err() == nil {
				log.Printf("realtime connection closed: %v", err)
			}
		}(conn)
	}
}
