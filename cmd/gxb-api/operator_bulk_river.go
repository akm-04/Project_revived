//go:build postgres && river

package main

import (
	"context"
	"log"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/river/operatorbulkworker"
	"gxb.local/backend/v2/internal/application/operatorgrant"
)

// startOperatorBulkJob runs the leadership-elected bulk settlement job in the
// API process. A missing River deployment only leaves bulk targets pending;
// inline grants still work.
func startOperatorBulkJob(ctx context.Context, pool *postgres.Pool, applier operatorgrant.Applier) {
	runtime, err := operatorbulkworker.New(pool, applier)
	if err != nil {
		log.Printf("operator bulk job inactive: %v", err)
		return
	}
	go func() {
		if err := runtime.Run(ctx); err != nil && ctx.Err() == nil {
			log.Printf("operator bulk job stopped: %v", err)
		}
	}()
}
