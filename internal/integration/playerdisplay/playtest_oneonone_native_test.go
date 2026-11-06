//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/domain/grant"
)

func TestPlaytestOneOnOneSettlementSkipsOwnedFrameNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	s := oneOnOneService(t, p)
	actorWithOwnedFrame, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	actorWithoutOwnedFrame, _ := oneOnOnePlayer(t, p, rankingServer(t, p))
	if _, err := s.Load(ctx, actorWithOwnedFrame, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Load(ctx, actorWithoutOwnedFrame, op()); err != nil {
		t.Fatal(err)
	}
	catalog := oneOnOneCatalog(t, p)
	now := time.Now()
	latest := catalog.LatestSettlement(now)
	latestPromotion := catalog.LatestPromotion(now)
	revision, err := (contentstore.Store{Queryer: p}).ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	grantGenuine(t, p, actorWithOwnedFrame, revision, "playtest owned one-on-one frame", []grant.Line{{Kind: grant.StackItem, ItemID: 120001005, Amount: 1}})
	exec(t, p, `DELETE FROM one_on_one_settlement_ranks WHERE day>$1`, latest-8)
	exec(t, p, `DELETE FROM one_on_one_settlements WHERE day>$1`, latest-8)
	exec(t, p, `UPDATE one_on_one_competitions SET settled_through=$1,opened_through=$2,closed_through=$2,state_version=state_version+1`, latest-8, latestPromotion)

	settled, err := s.Due(ctx, op())
	if err != nil || settled < 2 {
		t.Fatalf("owed settlements=%d err=%v", settled, err)
	}
	if again, err := s.Due(ctx, op()); err != nil || again != 0 {
		t.Fatalf("settlements replayed: count=%d err=%v", again, err)
	}
	if scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_FRAME'`, int64(actorWithOwnedFrame.PlayerID)) != 0 ||
		scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_FRAME'`, int64(actorWithoutOwnedFrame.PlayerID)) != 1 {
		t.Fatal("owned frame mail was not suppressed or unowned frame mail was not sent")
	}
	if scalar(t, p, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ONE_ON_ONE_REWARD'`, int64(actorWithOwnedFrame.PlayerID)) != int64(settled) {
		t.Fatal("regular OneOnOne reward mails were not retained")
	}
}
