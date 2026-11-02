//go:build postgres

package main

import (
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/memoirstore"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/memoir"
	"gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalMemoir(pool *postgres.Pool, runner tx.Runner, content contentstore.Store, values i5store.Store, grants i5.Service, heroes characterhero.Service, fight combat.Service, opponents topfloor.Service) memoir.Mode {
	return memoir.Mode{Timed: generation.TimedRunner{Binder: generation.Binder{Time: postgres.AuthoritativeTime{Queryer: pool}}, Runner: runner}, Fresh: pool, Store: memoirstore.Store{}, Content: content, Fence: values, Functions: values, Heroes: heroes, HeroLocks: characterstore.MarchHeroPort{Store: characterstore.Store{Queryer: pool}}, Roster: fight.Inputs.Heroes, Pets: fight.Inputs.Pets, Opponents: opponents, Combat: fight, Grants: grants, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Energy: grants, Exchange: grants, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: pool}}
}
