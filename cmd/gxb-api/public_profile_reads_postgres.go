//go:build postgres

package main

import (
	"context"
	"gxb.local/backend/v2/internal/adapters/guildinvitebundle"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/profilefeedbackstore"
	"gxb.local/backend/v2/internal/adapters/postgres/publicprofilestore"
	"gxb.local/backend/v2/internal/adapters/postgres/socialrelationstore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/characterhero"
	"gxb.local/backend/v2/internal/application/characterpet"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/guildcore"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	feedback "gxb.local/backend/v2/internal/application/profilefeedback"
	app "gxb.local/backend/v2/internal/application/publicprofile"
	"gxb.local/backend/v2/internal/application/realtimeauth"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/protocol/httpedge"
	"log"
)

type profileCharacterBases struct {
	characterhero.BaseObservationReader
	Pet characterpet.BaseObservationReader
}

func (b profileCharacterBases) PetBaseObservationTx(c context.Context, q tx.Queryer, p identity.PlayerID, id int64) (characterasset.PetBaseObservation, error) {
	return b.Pet.PetBaseObservationTx(c, q, p, id)
}
func registerPublicProfileReads(c context.Context, p *pg.Pool, r tx.Runner, a realtimeauth.GameplayAuthorityPort, receipts receipt.Store, content contentstore.Store, display playerdisplay.Service, router *httpedge.Router) error {
	rev, e := content.ActiveRevision(c, p)
	if e != nil {
		return e
	}
	qualified, e := content.HasPublicProfileCapabilityTx(c, p, rev)
	if e != nil {
		return e
	}
	if !qualified {
		return nil
	}
	showcaseReady, e := content.HasPublicShowcaseCapabilityTx(c, p, rev)
	if e != nil {
		return e
	}
	if !showcaseReady {
		log.Print("PublicProfile component routes inactive: required showcase content unavailable")
		return nil
	}
	if _, e = content.ReadPublicShowcasePolicy(c, p, rev); e != nil {
		return e
	}
	invite, e := guildinvitebundle.Prepare(c, p, r, rev)
	if e != nil {
		return e
	}
	basic := app.BasicReader{Roots: app.RootService{Store: publicprofilestore.Store{}}, Players: i4store.PlayerRootLocker{}, Fence: i5store.Store{}, PlayerBasis: i5store.Store{}, Relations: socialrelationstore.Store{}, Content: content}
	fb := feedback.Service{Roots: feedback.RootService{Store: profilefeedbackstore.Store{}}, Content: content, Recipients: i4store.PlayerRootLocker{}, Authors: i5store.Store{}, Display: display}
	bases := profileCharacterBases{characterhero.BaseObservationReader{Store: characterstore.Store{}, Content: content}, characterpet.BaseObservationReader{Store: characterstore.Store{}}}
	records := app.UnavailableShowcaseRecords{}
	reads := app.ReadService{Runner: r, Fresh: p, Time: pg.AuthoritativeTime{Queryer: p}, Content: content, Basic: basic, Display: display, Guilds: guildcore.PublicViewReader{Store: guildstore.Store{}, Invites: invite.Source}, Feedback: fb.Roots, Comments: feedback.CommentService{Base: fb, Store: profilefeedbackstore.Store{}}, Media: publicprofilestore.Store{}, Metrics: app.CanonicalCreationMetricProvider{Players: i5store.Store{}}, Slots: publicprofilestore.Store{}, Characters: characterasset.PublicShowcaseCharacterReader{OwnerComposite: &characterasset.OwnedCompositeBuilder{HeroBase: bases, PetBase: bases}}, Records: records}
	wire := app.ShowcaseWireService{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: r}, Reads: r, Fresh: p, Roots: basic.Roots, Players: basic.Players, Fence: basic.Fence, Receipts: receipts, Content: content, Slots: publicprofilestore.Store{}, References: characterstore.Store{}, Bases: bases, Records: records}
	d := stockruntime.PublicProfileReadDispatcher{Authority: a, Service: reads, Showcase: wire}
	for _, mid := range []uint16{1829, 1832, 1838, 1840} {
		if e = router.Register(mid, d); e != nil {
			return e
		}
	}
	log.Print("PublicProfile component routes: metric1011/emptyshowcase qualified; nonemptyrichdetail and history fail closed until actual producers qualify; full I7B6B remains partial")
	return nil
}
