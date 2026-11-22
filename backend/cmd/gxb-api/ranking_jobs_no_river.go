//go:build postgres && !river

package main

import (
	"context"

	"gxb.local/backend/v2/internal/adapters/postgres"
	appranking "gxb.local/backend/v2/internal/application/ranking"
)

// A postgres-only binary keeps the finite API group; R7 maintenance jobs need
// the River mechanism build.
func startRankingJobs(context.Context, *postgres.Pool, appranking.Service) {}
