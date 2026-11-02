//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/petcampaignstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/petcampaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalPetCampaign(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, grants i5.Service, heroes hero.Service, pets pet.Service, fight combat.Service) app.Mode {
	return app.Mode{Directory: i4store.PlayerDirectoryReader{}, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: petcampaignstore.Store{}, Content: content, Fence: values, Functions: values, Heroes: heroes, HeroLocks: characterstore.CampaignHeroPort{Store: characterstore.Store{Queryer: p}}, Pets: pets, Combat: fight, Rules: fight.Rules, Values: grants, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Privileges: grants.Privileges, Facts: i5.ObjectiveFacts{Owner: grants, Open: values}, Awakening: grants, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
