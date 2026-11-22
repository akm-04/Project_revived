//go:build postgres && !river

package main

import (
	"context"
	"log"

	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/application/operatorgrant"
)

// startOperatorBulkJob is absent without the River build: a bulk target stays
// PENDING until a River-enabled API runs, and the inline path still works.
func startOperatorBulkJob(_ context.Context, _ *postgres.Pool, _ operatorgrant.Applier) {
	log.Printf("operator bulk job inactive: build with -tags river")
}
