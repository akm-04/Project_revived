//go:build postgres

package playerdisplay_test

import (
	"context"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	"gxb.local/backend/v2/internal/application/i5"
	applibrary "gxb.local/backend/v2/internal/application/librarylocal"
	appwakeup "gxb.local/backend/v2/internal/application/realtimewakeup"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestI9_11GLProducersWakeThePartnerLog covers A-125 G1 step 5: every Girls Log
// producer commits one library.partner_log.v1 reference and a replay emits none.
func TestI9_11GLProducersWakeThePartnerLog(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a, _ := genuinePlayer(t, p, rankingServer(t, p))
	rule := must(contentstore.Store{Queryer: p}.ResolveProgressionPolicyTx(ctx, p, rev))(t, "progression")
	grantGenuine(t, p, a, rev, "player-level", []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[98].TotalExp}})
	grantGenuine(t, p, a, rev, "resources", genuineResources(t, p, rev, []int64{genuineHeroTable}))

	listener := startPartnerLogListener(t, p)

	heroes := genuineHeroService(p)
	heroes.Journals = librarystore.Store{}
	dispatcher := stockruntime.HeroDispatcher{Authority: playtestAuthority{a}, Service: heroes,
		Economy: i5.ScalarProjector{Runner: tx.Runner{DB: p}, Store: i5store.Store{Queryer: p}, FloorPolicies: contentstore.Store{Queryer: p}}}

	def := must(contentstore.Store{Queryer: p}.HeroNormalSummonTx(ctx, p, rev, genuineHeroTable))(t, "summon policy")
	summon := i911aDispatch(t, dispatcher, a, 59, map[string]any{"table_id": genuineHeroTable, "stone": int64(def.Template.FragmentItemID), "stone_num": int64(def.FragmentCount)}, op())
	partner := i9glPartner(t, summon.Body)
	listener.expect(t, a.PlayerID, partner, "acquisition")

	star := i911aDispatch(t, dispatcher, a, 52, map[string]any{"partner_id": partner}, op())
	if star.HTTPStatus != 200 {
		t.Fatalf("star status %d body %+v", star.HTTPStatus, star.Body)
	}
	listener.expect(t, a.PlayerID, partner, "star")

	equip := i911aDispatch(t, dispatcher, a, 62, map[string]any{"partner_id": partner}, op())
	if equip.HTTPStatus != 200 {
		t.Fatalf("one-key equip %d %+v", equip.HTTPStatus, equip.Body)
	}
	promotionOp := op()
	promotion := i911aDispatch(t, dispatcher, a, 51, map[string]any{"partner_id": partner}, promotionOp)
	if promotion.HTTPStatus != 200 {
		t.Fatalf("promotion %d %+v", promotion.HTTPStatus, promotion.Body)
	}
	listener.expect(t, a.PlayerID, partner, "promotion")
	if replay := i911aDispatch(t, dispatcher, a, 51, map[string]any{"partner_id": partner}, promotionOp); replay.HTTPStatus != 200 {
		t.Fatalf("promotion replay %d %+v", replay.HTTPStatus, replay.Body)
	}
	listener.silent(t, "promotion replay")

	seedStack(t, p, a, rev, 50001113, 10)
	favorOp := op()
	favor := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": partner, "gift_id": int64(50001113), "gift_num": int64(1)}, favorOp)
	if favor.HTTPStatus != 200 {
		t.Fatalf("favor gift %d %+v", favor.HTTPStatus, favor.Body)
	}
	listener.expect(t, a.PlayerID, partner, "favor")
	if replay := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": partner, "gift_id": int64(50001113), "gift_num": int64(1)}, favorOp); replay.HTTPStatus != 200 {
		t.Fatalf("favor replay %d %+v", replay.HTTPStatus, replay.Body)
	}
	listener.silent(t, "favor replay")

	dialog := libraryDispatch(t, p, a, 843, map[string]any{"partner_id": partner, "dialog_id": int64(11)}, op())
	if dialog.HTTPStatus != 200 {
		t.Fatalf("dialog %d %+v", dialog.HTTPStatus, dialog.Body)
	}
	listener.expect(t, a.PlayerID, partner, "dialog")

	exec(t, p, `UPDATE player_library_heroes SET created_at=clock_timestamp()-interval '1 hour' WHERE player_id=$1 AND partner_id=$2`, int64(a.PlayerID), partner)
	setLibraryFavor(t, p, a, partner, 2000)
	seedStack(t, p, a, rev, 50001112, 1)
	marriage := libraryDispatch(t, p, a, 840, map[string]any{"partner_id": partner, "gift_id": int64(50001112), "gift_num": int64(1)}, op())
	if marriage.HTTPStatus != 200 {
		t.Fatalf("marriage %d %+v", marriage.HTTPStatus, marriage.Body)
	}
	listener.expect(t, a.PlayerID, partner, "marriage")
}

func i9glPartner(t *testing.T, body map[string]any) int64 {
	t.Helper()
	partner, ok := body["partner_id"].(int64)
	if !ok || partner <= 0 {
		t.Fatalf("summon partner %#v", body)
	}
	return partner
}

type partnerLogListener struct {
	messages chan appwakeup.Envelope
	failure  chan error
	ref      string
}

func startPartnerLogListener(t *testing.T, p *pg.Pool) *partnerLogListener {
	t.Helper()
	connection, err := p.Raw().Acquire(ctx)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(connection.Release)
	if _, err = connection.Exec(ctx, `LISTEN `+pg.RealtimeWakeupChannel); err != nil {
		t.Fatal(err)
	}
	listener := &partnerLogListener{messages: make(chan appwakeup.Envelope, 8), failure: make(chan error, 1)}
	go func() {
		for {
			notification, err := connection.Conn().WaitForNotification(context.Background())
			if err != nil {
				listener.failure <- err
				return
			}
			envelope, err := appwakeup.Decode([]byte(notification.Payload))
			if err != nil {
				listener.failure <- err
				return
			}
			listener.messages <- envelope
		}
	}()
	return listener
}

func (l *partnerLogListener) expect(t *testing.T, player identity.PlayerID, partner int64, what string) {
	t.Helper()
	deadline := time.After(3 * time.Second)
	for {
		select {
		case envelope := <-l.messages:
			if envelope.Route != applibrary.PartnerLogNoticeRoute {
				continue
			}
			want := applibrary.PartnerLogRef(player, partner)
			if envelope.Ref != want {
				continue
			}
			l.ref = want
			l.silent(t, what+" duplicate")
			return
		case err := <-l.failure:
			t.Fatalf("%s listener %v", what, err)
		case <-deadline:
			t.Fatalf("%s produced no partner log wakeup", what)
		}
	}
}

func (l *partnerLogListener) silent(t *testing.T, what string) {
	t.Helper()
	deadline := time.After(300 * time.Millisecond)
	for {
		select {
		case envelope := <-l.messages:
			if envelope.Route != applibrary.PartnerLogNoticeRoute || envelope.Ref != l.ref {
				continue
			}
			t.Fatalf("%s: unexpected partner log wakeup %+v", what, envelope)
		case err := <-l.failure:
			t.Fatalf("%s listener %v", what, err)
		case <-deadline:
			return
		}
	}
}
