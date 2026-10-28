//go:build postgres

package main

import (
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/godstrialstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/godstrial"
	"gxb.local/backend/v2/internal/application/i5"
	spirit "gxb.local/backend/v2/internal/application/spirit"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func canonicalGodsTrial(p *pg.Pool, r tx.Runner, content contentstore.Store, values i5store.Store, grants i5.Service, heroes hero.Service, pets pet.Service, fight combat.Service, spirits spirit.Service) app.Mode {
	return app.Mode{Spirit: spirits, Progression: values, Mail: values, Energy: grants, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Fresh: p, Store: godstrialstore.Store{}, Content: content, Fence: values, Functions: values, Heroes: heroes, HeroLocks: characterstore.GodsTrialHeroPort{Store: characterstore.Store{Queryer: p}}, Pets: pets, Combat: fight, Rules: fight.Rules, Values: grants, Facts: i5.ObjectiveFacts{Owner: grants, Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}
