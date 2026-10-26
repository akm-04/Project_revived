//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/marchstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	march "gxb.local/backend/v2/internal/application/march"
	top "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

func canonicalMarch(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, grants i5.Service, heroes hero.Service, fight combat.Service, opponents top.Service) march.Mode {
	return march.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: marchstore.Store{}, Content: content, Fence: values, Functions: values, Directory: i4store.PlayerDirectoryReader{},
		Heroes: heroes, HeroLocks: characterstore.MarchHeroPort{Store: characterstore.Store{Queryer: p}}, Roster: fight.Inputs.Heroes, HeroWire: heroproj.StockHero, Opponents: opponents, Combat: fight, Facts: i5.ObjectiveFacts{Owner: grants, Open: values}, Grants: grants, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
