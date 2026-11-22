//go:build postgres && river

package main

import (
	"context"
	"log"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/river/rankingworker"
	appranking "gxb.local/backend/v2/internal/application/ranking"
)

// startRankingJobs runs the leadership-elected R7 maintenance jobs in the API
// process, which owns the complete metric provider composition. A missing
// River deployment only disables maintenance; serving continues.
func startRankingJobs(c context.Context, p *postgres.Pool, jobs appranking.Service) {
	runtime, e := rankingworker.New(p, jobs, 0)
	if e != nil {
		log.Printf("ranking maintenance jobs inactive: %v", e)
		return
	}
	if e = runtime.EnqueueBackfill(c); e != nil {
		log.Printf("ranking backfill enqueue failed: %v", e)
	}
	go func() {
		if e := runtime.Run(c); e != nil && c.Err() == nil {
			log.Printf("ranking maintenance stopped: %v", e)
		}
	}()
}
