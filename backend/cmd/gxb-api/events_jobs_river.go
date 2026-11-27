//go:build postgres && river

package main

import (
	"context"
	"log"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/river/eventsworker"
	appevents "gxb.local/backend/v2/internal/application/events"
)

// startEventsJobs runs the leadership-elected E4 cycle and settlement jobs in
// the API process. A missing River deployment only disables maintenance.
func startEventsJobs(c context.Context, p *postgres.Pool, jobs appevents.Jobs) {
	runtime, err := eventsworker.New(p, jobs, 0)
	if err != nil {
		log.Printf("events maintenance jobs inactive: %v", err)
		return
	}
	go func() {
		if err := runtime.Run(c); err != nil && c.Err() == nil {
			log.Printf("events maintenance stopped: %v", err)
		}
	}()
}
