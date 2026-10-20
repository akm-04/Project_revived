//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	app "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalGirlsRanking(p *pg.Pool, r tx.Runner, content contentstore.Store, display playerdisplay.Service, receipts receipt.Store) app.Service {
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: rankingstore.Store{}, Cohort: i4store.PlayerRootLocker{}, Directory: i4store.PlayerDirectoryReader{}, Content: content, Fence: i5store.Store{}, Players: i4store.PlayerRootLocker{}, Recipient: display, Ledger: i5store.Store{}, Receipts: receipts, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
