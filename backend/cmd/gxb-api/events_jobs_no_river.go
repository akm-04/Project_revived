//go:build postgres && !river

package main

import (
	"context"

	"gxb.local/backend/v2/internal/adapters/postgres"
	appevents "gxb.local/backend/v2/internal/application/events"
)

// A postgres-only binary has no River mechanism; events maintenance stays off.
func startEventsJobs(context.Context, *postgres.Pool, appevents.Jobs) {}
