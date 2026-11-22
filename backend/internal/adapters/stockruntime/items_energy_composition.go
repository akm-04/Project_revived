package stockruntime

import (
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyconsumestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/itemsenergystore"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	app "gxb.local/backend/v2/internal/application/itemsenergy"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

// ItemsEnergyDependencies are the owners the production server and the natives
// pass to the one 11B composition constructor.
type ItemsEnergyDependencies struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Content     contentstore.Store
	Values      i5store.Store
	Privileges  app.Privileges
	I5          appi5.Service
	Heroes      apphero.Service
	Receipts    kernelstore.Store
	ReceiptRead kernelstore.Reader
	Authority   rt.GameplayAuthorityPort
	Campaign    CampaignPort
	Fumo        QuickFumoPort
}

// ItemsEnergyComposition is the composed command owner plus the MID 1 and
// daily-reset counter projections that read the same owner.
type ItemsEnergyComposition struct {
	Service    app.Service
	Dispatcher ItemsEnergyDispatcher
	MID1       app.Bootstrap
	Counters   app.BuyCounterReader
}

func NewItemsEnergyComposition(d ItemsEnergyDependencies) ItemsEnergyComposition {
	daily := appconsume.Service{Store: dailyconsumestore.Store{}}
	service := app.Service{
		Timed:       d.Timed,
		Fresh:       d.Fresh,
		Content:     d.Content,
		Tuning:      itemsenergystore.Store{},
		Fence:       d.Values,
		Players:     i4store.PlayerRootLocker{},
		Counters:    daily,
		Exchange:    d.I5,
		Debiter:     appi5.MaterialCostDebiter{Store: d.Values, Content: d.Content},
		Balances:    d.Values,
		Privileges:  d.Privileges,
		Progression: d.Values,
		Facts:       appi5.ObjectiveFacts{Owner: d.I5, Open: d.Values},
		Heroes:      d.Heroes,
		Fragments:   d.Content,
		HeroWire:    app.HeroWire(heroproj.StockHero),
		Receipts:    d.Receipts,
		ReceiptRead: d.ReceiptRead,
	}
	return ItemsEnergyComposition{
		Service:    service,
		Dispatcher: ItemsEnergyDispatcher{Authority: d.Authority, Service: service, Campaign: d.Campaign, Fumo: d.Fumo},
		MID1:       app.Bootstrap{Counters: daily},
		Counters:   app.BuyCounterReader{Reads: daily, Fresh: d.Fresh},
	}
}
