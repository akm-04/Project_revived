//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/sharedroomstore"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/occult"
	appsharedroom "gxb.local/backend/v2/internal/application/sharedroom"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalOccult(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, owner i5.Service, fight combat.Service, rooms appsharedroom.Service) occult.Mode {
	return occult.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: occultstore.Store{}, Content: content,
		Fence: values, Players: i4store.PlayerRootLocker{}, Functions: values, Directory: i4store.PlayerDirectoryReader{}, Presence: presencestore.Store{Queryer: p}, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Rooms: rooms, RoomStore: sharedroomstore.Store{}, Combat: fight, Tickets: owner, Values: owner, Awakening: owner,
		Facts: i5.ObjectiveFacts{Owner: owner, Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
