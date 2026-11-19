package stockruntime

import (
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/shopstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	app "gxb.local/backend/v2/internal/application/shop"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ShopDependencies are the owners the production server and the natives pass
// to the one 11C composition constructor.
type ShopDependencies struct {
	Timed        gen.TimedRunner
	Fresh        tx.Queryer
	Content      contentstore.Store
	Values       i5store.Store
	Privileges   app.Privileges
	I5           appi5.Service
	Receipts     kernelstore.Store
	ReceiptRead  kernelstore.Reader
	Authority    rt.GameplayAuthorityPort
	TeamShops    app.TeamShops
	Achievements app.Achievements
	Facts        app.ObjectiveFacts
}

// ShopComposition is the composed 11C owner plus its dispatcher.
type ShopComposition struct {
	Service    app.Service
	Dispatcher ShopDispatcher
}

func NewShopComposition(deps ShopDependencies) ShopComposition {
	service := app.Service{
		Timed:        deps.Timed,
		Fresh:        deps.Fresh,
		Content:      deps.Content,
		Store:        shopstore.Store{},
		Fence:        deps.Values,
		Players:      i4store.PlayerRootLocker{},
		Exchange:     deps.I5,
		Debiter:      appi5.MaterialCostDebiter{Store: deps.Values, Content: deps.Content},
		Balances:     deps.Values,
		Privileges:   deps.Privileges,
		Progression:  deps.Values,
		Functions:    deps.Values,
		TeamShops:    deps.TeamShops,
		Achievements: deps.Achievements,
		Facts:        deps.Facts,
		Receipts:     deps.Receipts,
		ReceiptRead:  deps.ReceiptRead,
	}
	return ShopComposition{
		Service:    service,
		Dispatcher: ShopDispatcher{Authority: deps.Authority, Service: service},
	}
}
