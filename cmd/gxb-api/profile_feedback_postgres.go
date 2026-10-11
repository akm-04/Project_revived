//go:build postgres

package main

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	gen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/profilefeedback"
	"gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"log"
)

func registerProfileFeedback(c context.Context, p *postgres.Pool, r tx.Runner, a realtimeauth.GameplayAuthorityPort, receipts receipt.Store, content contentstore.Store, router *httpedge.Router) error {
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		return e
	}
	good, e := content.HasPublicProfileCapabilityTx(c, p, rev)
	if e != nil {
		return e
	}
	if !good {
		log.Printf("ProfileFeedback routes inactive; required PublicProfile content policy unavailable")
		return nil
	}
	if _, e = content.ReadPublicProfilePolicy(c, p, rev); e != nil {
		return e
	}
	basic := publicprofile.BasicReader{Roots: publicprofile.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: content}
	s := app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: postgres.AuthoritativeTime{Queryer: p}}, Runner: r}, Reads: r, Fresh: p, Roots: app.RootService{Store: profilefeedbackstore.Store{}}, Basic: basic, Content: content, Receipts: receipts, Recipients: i4store.PlayerRootLocker{}, Authors: i5store.Store{}}
	d := stockruntime.ProfileFeedbackDispatcher{Authority: a, Service: s}
	for _, mid := range []uint16{1830, 1842} {
		if e = router.Register(mid, d); e != nil {
			return e
		}
	}
	comments := stockruntime.ProfileCommentDispatcher{Authority: a, Service: app.CommentService{Base: s, Store: profilefeedbackstore.Store{}}}
	for _, mid := range []uint16{1835, 1836, 1839, 1841} {
		if e = router.Register(mid, comments); e != nil {
			return e
		}
	}
	return nil
}
