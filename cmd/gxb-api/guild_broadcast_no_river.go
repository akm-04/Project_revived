//go:build postgres && !river

package main

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
)

// A postgres-only binary preserves the accepted finite API group; MID588 has
// no producer implementation and remains unregistered.
func registerGuildBroadcast(context.Context, *postgres.Pool, tx.Runner, realtimeauth.GameplayAuthorityPort, guildstore.Store, i5store.Store, receipt.Store, contentstore.Store, *httpedge.Router) error {
	return nil
}
