//go:build postgres && linux

package main

import (
	"context"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"log"
	"net/http"
)

func registerProfileMedia(c context.Context, p *pg.Pool, r tx.Runner, a realtimeauth.GameplayAuthorityPort, receipts receipt.Store, content contentstore.Store, router *httpedge.Router, root, origin string) (http.Handler, error) {
	if root == "" && origin == "" {
		inv, e := (publicprofilestore.Store{}).InventoryMediaTx(c, p)
		if e != nil {
			return nil, e
		}
		if len(inv.History) > 0 {
			return nil, fmt.Errorf("profile media configuration required for retained references")
		}
		log.Print("Profile media routes inactive: deployment store/origin not configured")
		return nil, nil
	}
	if root == "" || origin == "" {
		return nil, fmt.Errorf("both profile media root and public origin required")
	}
	urls, e := app.NewMediaURL(origin)
	if e != nil {
		return nil, e
	}
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		return nil, e
	}
	good, e := content.HasPublicProfileCapabilityTx(c, p, rev)
	if e != nil {
		return nil, e
	}
	if !good {
		return nil, fmt.Errorf("configured profile media requires qualified Content policy")
	}
	if _, e = content.ReadPublicProfilePolicy(c, p, rev); e != nil {
		return nil, e
	}
	blobs, e := blobstore.NewLocal(root)
	if e != nil {
		return nil, e
	}
	commands := app.CommandService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Reads: r, Fresh: p, Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, Receipts: receipts, Content: content}
	s := app.MediaService{Commands: commands, Media: publicprofilestore.Store{}, Blobs: blobs, URLs: urls}
	// Startup recovery refuses missing/corrupt referenced bytes before listening.
	if e = (app.MediaMaintenance{Service: s, Receipts: kernelstore.Store{}}).Validate(c); e != nil {
		return nil, e
	}
	if e = router.Register(1844, stockruntime.ProfileMediaDispatcher{Authority: a, Service: s}); e != nil {
		return nil, e
	}
	return stockruntime.ProfileMediaGET{Service: s}, nil
}
