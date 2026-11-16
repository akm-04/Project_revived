//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/illusionstore"
	il "gxb.local/backend/v2/internal/application/illusion"
	"gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// R5D-03: the RESULT credits the one shared Combat attempt and records the
// credited damage in the mode's settlement row; a duplicate answers from that
// row instead of changing it.
func TestR5DIllusionDuplicateSettlementNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}

	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	settled, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 500, CostTime: 5, Formation: formation}, op())
	if err != nil || settled.Duplicate || settled.Body["now_hurt"] != int64(500) {
		t.Fatalf("settle %+v %v", settled, err)
	}
	duplicate, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 900, CostTime: 5, Formation: formation}, op())
	if err != nil || !duplicate.Duplicate || duplicate.Body["now_hurt"] != int64(500) {
		t.Fatalf("duplicate %+v %v", duplicate, err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_attempt_settlements WHERE player_id=$1 AND damage=500`, int64(a.PlayerID)); n != 1 {
		t.Fatal("settlement rows", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_attempts WHERE player_id=$1`, int64(a.PlayerID)); n != 0 {
		t.Fatal("mode-local attempt row", n)
	}
}

type cancellingIllusionSettlementStore struct {
	illusionstore.Store
	cancel context.CancelFunc
}

func (s cancellingIllusionSettlementStore) InsertSettlementTx(c context.Context, t tx.Tx, attemptID ids.UUID, playerID identity.PlayerID, damage int64, settledAt time.Time) error {
	s.cancel()
	return s.Store.InsertSettlementTx(c, t, attemptID, playerID, damage, settledAt)
}

// R5D-03: cancelling the RESULT at the settlement insert rolls back Combat's
// attestation and the damage, leaving the attempt unsettled.
func TestR5DIllusionCancelledResultNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}

	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	runContext, cancel := context.WithCancel(ctx)
	s.Store = cancellingIllusionSettlementStore{Store: illusionstore.Store{}, cancel: cancel}
	if _, err := s.Settle(runContext, a, il.ResultRequest{Star: 1, Damage: 500, CostTime: 5, Formation: formation}, op()); err == nil {
		t.Fatal("cancelled RESULT committed")
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_attempt_settlements WHERE player_id=$1`, int64(a.PlayerID)); n != 0 {
		t.Fatal("cancelled RESULT left a settlement", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_occurrence_results WHERE player_id=$1`, int64(a.PlayerID)); n != 0 {
		t.Fatal("cancelled RESULT credited damage", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='ILLUSION' AND actor_player_id=$1 AND state='TERMINAL'`, int64(a.PlayerID)); n != 0 {
		t.Fatal("cancelled RESULT terminalised the attempt", n)
	}

	s.Store = illusionstore.Store{}
	settled, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 500, CostTime: 5, Formation: formation}, op())
	if err != nil || settled.Duplicate || settled.Body["now_hurt"] != int64(500) {
		t.Fatalf("settle after cancellation %+v %v", settled, err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_attempt_settlements WHERE player_id=$1 AND damage=500`, int64(a.PlayerID)); n != 1 {
		t.Fatal("settlement rows after retry", n)
	}
}

// R5D-03 design item 3: the Fantasy recommendation reads the formation from the
// Combat START that the settlement names, never from a mode-local copy.
func TestR5DIllusionRecommendationUsesFrozenStartNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := illusionOwner(t, p, server)
	clock := illusionTime(t)
	s := illusionService(t, p, clock, illusionPrivileges{level: 3}, illusionGuildSource{})
	formation := []int64{partner}

	if _, err := s.Start(ctx, a, il.StartRequest{Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Settle(ctx, a, il.ResultRequest{Star: 1, Damage: 500, CostTime: 5, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	source, err := (illusionstore.Store{Combat: combatstore.Store{}}).HeroRecommendSourceTx(ctx, p, server, clock.at, herorecommend.MaxSourceScan)
	if err != nil {
		t.Fatal(err)
	}
	if len(source.Formations) != 1 {
		t.Fatalf("formations %+v", source.Formations)
	}
	shown := source.Formations[0]
	if shown.PlayerID != int64(a.PlayerID) || fmt.Sprint(shown.PartnerIDs) != fmt.Sprint(formation) || shown.Weight != 500 || shown.ParadiseID != int64(d.FirstCampaignID) {
		t.Fatalf("recommendation formation %+v", shown)
	}
	if len(source.Popularity) != 1 || source.Popularity[0].PartnerID != partner || source.Popularity[0].Score != 500 || source.Popularity[0].PlayerID != int64(a.PlayerID) {
		t.Fatalf("recommendation popularity %+v", source.Popularity)
	}
	if n := scalar(t, p, `SELECT count(*) FROM illusion_attempts WHERE player_id=$1`, int64(a.PlayerID)); n != 0 {
		t.Fatal("mode-local attempt row", n)
	}
}
