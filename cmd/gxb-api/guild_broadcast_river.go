//go:build postgres && river

package main

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildbroadcaststore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	riveradapter "gxb.local/backend/v2/internal/adapters/river"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/guildbroadcast"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"log"
)

func registerGuildBroadcast(c context.Context, p *postgres.Pool, r tx.Runner, a realtimeauth.GameplayAuthorityPort, g guildstore.Store, i5 i5store.Store, receipts receipt.Store, content contentstore.Store, router *httpedge.Router) error {
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		return e
	}
	declared, e := content.HasGuildBroadcastCapabilityTx(c, p, rev)
	if e != nil {
		return e
	}
	if !declared {
		log.Print("Guild broadcast MID588 inactive: active catalog has no broadcast capability")
		return nil
	}
	if _, e = content.ReadBroadcastPolicy(c, p, rev); e != nil {
		return e
	}
	if e = riveradapter.ValidateDeployment(c, p.Raw()); e != nil {
		return e
	}
	queue, e := riveradapter.NewGuildInsertOnly(p.Raw())
	if e != nil {
		return e
	}
	source := app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Reads: r, Fresh: p, Store: guildbroadcaststore.Store{}, Guild: g, Names: i4store.PlayerRootLocker{}, Players: i4store.PlayerRootLocker{}, Fence: i5, Receipts: receipts, Content: content, Enqueue: queue}
	prepared, e := stockruntime.PrepareGuildBroadcast(a, source)
	if e != nil {
		return e
	}
	dispatcher, e := prepared.Enable(c, p)
	if e != nil {
		return e
	}
	return router.Register(588, dispatcher)
}
