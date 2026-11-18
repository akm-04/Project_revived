//go:build postgres

package main

import (
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/compatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	appcompat "gxb.local/backend/v2/internal/application/compat"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// canonicalCompat builds the I9-11D preference service in production shape.
func canonicalCompat(pool *postgres.Pool, runner tx.Runner, content contentstore.Store, i5db i5store.Store) appcompat.Service {
	return appcompat.Service{
		Runner: runner, Fresh: pool, Store: compatstore.Store{}, Content: content,
		Players: i4store.PlayerRootLocker{}, Fence: i5db,
	}
}
