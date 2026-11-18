package stockruntime

import (
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyconsumestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appconsume "gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/heroassets"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	rt "gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// HeroAssetsDependencies are the owners the production server and the natives
// pass to the one 11A composition constructor.
type HeroAssetsDependencies struct {
	Timed       gen.TimedRunner
	Fresh       tx.Queryer
	Content     contentstore.Store
	Values      i5store.Store
	Privileges  appi5.PrivilegeSnapshotProvider
	I5          appi5.Service
	Receipts    kernelstore.Store
	ReceiptRead kernelstore.Reader
	Authority   rt.GameplayAuthorityPort
}

// HeroAssetsComposition is the composed I9-11A command owner plus the MID 1
// buy_skill_times projection that reads the same counter owner.
type HeroAssetsComposition struct {
	Service    app.Service
	Dispatcher HeroAssetsDispatcher
	Bootstrap  app.Bootstrap
}

func NewHeroAssetsComposition(d HeroAssetsDependencies) HeroAssetsComposition {
	daily := appconsume.Service{Store: dailyconsumestore.Store{}}
	service := app.Service{
		Timed:       d.Timed,
		Fresh:       d.Fresh,
		Content:     d.Content,
		Fence:       d.Values,
		Players:     i4store.PlayerRootLocker{},
		Counters:    daily,
		Exchange:    d.I5,
		Balances:    d.Values,
		Privileges:  d.Privileges,
		Receipts:    d.Receipts,
		ReceiptRead: d.ReceiptRead,
	}
	return HeroAssetsComposition{
		Service:    service,
		Dispatcher: HeroAssetsDispatcher{Authority: d.Authority, Service: service},
		Bootstrap:  app.Bootstrap{Counters: daily},
	}
}
