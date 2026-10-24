//go:build postgres

package main

import (
	"context"
	"log"
	"net/http"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/clientlogstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	appclientlog "gxb.local/backend/v2/internal/application/clientlog"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/observability"
)

const clientLogPurgeInterval = time.Hour

// startClientLog wires the ClientLog owner (I8.5-3): the per-session log_url
// issuer, the request journal writer, the log URL route (when
// GXB_CLIENT_LOG_URL is set) and the hourly retention purge (D43).
func startClientLog(ctx context.Context, pool *pg.Pool, authority i4store.RealtimeAuthority, baseURL string, metrics observability.Metrics, mux *http.ServeMux) (*appclientlog.Service, *appclientlog.Journal) {
	store := clientlogstore.Store{Pool: pool.Raw()}
	service := &appclientlog.Service{Store: store, Bearers: authority, Clock: clock.System{}, BaseURL: baseURL}
	journal := appclientlog.NewJournal(store, metrics)
	go journal.Run(ctx)
	go purgeClientLogs(ctx, service)
	if baseURL == "" {
		return service, journal
	}
	basePath, err := stockruntime.ClientLogBasePath(baseURL)
	if err != nil {
		log.Fatal(err)
	}
	handler := stockruntime.ClientLogHandler{Ingest: service, BasePath: basePath}
	mux.Handle(basePath, handler)
	mux.Handle(basePath+"/", handler)
	return service, journal
}

func purgeClientLogs(ctx context.Context, service *appclientlog.Service) {
	ticker := time.NewTicker(clientLogPurgeInterval)
	defer ticker.Stop()
	for {
		if _, err := service.Purge(ctx); err != nil && ctx.Err() == nil {
			log.Printf("client log purge: %v", err)
		}
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
		}
	}
}
