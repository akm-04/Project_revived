//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/workplacestore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	top "gxb.local/backend/v2/internal/application/topfloor"
	workplace "gxb.local/backend/v2/internal/application/workplace"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

func canonicalWorkplace(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, grants i5.Service, heroes hero.Service, fight combat.Service, opponents top.Service, rental workplace.RentalOffers) workplace.Mode {
	return workplace.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: workplacestore.Store{}, Content: content, Fence: values, Functions: values, Directory: i4store.PlayerDirectoryReader{}, Campaigns: campaignstore.Store{}, Heroes: heroes, HeroLocks: characterstore.WorkplaceHeroPort{Store: characterstore.Store{Queryer: p}}, HeroWire: heroproj.StockHero, Opponents: opponents, Combat: fight, Stats: fight.Inputs.Stats, Values: grants, Privileges: grants.Privileges, Facts: i5.ObjectiveFacts{Owner: grants, Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, Rental: rental}
}
