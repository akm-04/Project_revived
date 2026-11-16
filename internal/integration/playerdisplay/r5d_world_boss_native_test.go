//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/worldbossstore"
	app "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// R5D-02: a RESULT credits the generation frozen at START even after other
// players advance the server to the next occurrence; the duplicate answer comes
// from the settlement row and never touches the successor board.
func TestR5DWorldBossFrozenGenerationNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	late, latePartner := worldBossActor(t, p, server)
	advance, advancePartner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)
	revision := installed(t, p)
	catalog, err := s.Content.WorldBossCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}

	if _, err = s.Start(ctx, late, app.StartRequest{CampaignID: d.FirstBossID, Formation: []int64{latePartner}}, op()); err != nil {
		t.Fatal(err)
	}
	for bossID := int64(d.FirstBossID); bossID <= d.LastBossID; bossID++ {
		boss, found := catalog.Boss(bossID)
		if !found {
			t.Fatal("missing boss", bossID)
		}
		exec(t, p, `UPDATE worldboss_occurrences SET current_boss=$2,courage=$3 WHERE logical_server_id=$1`, int64(server), bossID, boss.NeedBrave-1)
		if _, err = s.Start(ctx, advance, app.StartRequest{CampaignID: bossID, Formation: []int64{advancePartner}}, op()); err != nil {
			t.Fatalf("advance start %d: %v", bossID, err)
		}
		clock.Set(clock.at.Add(time.Minute))
		if _, err = s.Settle(ctx, advance, app.ResultRequest{CampaignID: bossID, Damage: 1, Formation: []int64{advancePartner}}, op()); err != nil {
			t.Fatalf("advance settle %d: %v", bossID, err)
		}
	}
	if generation, boss, courage, _ := worldBossOccurrence(t, p, server); generation != 2 || boss != d.FirstBossID || courage != 0 {
		t.Fatalf("occurrence did not advance generation=%d boss=%d courage=%d", generation, boss, courage)
	}

	clock.Set(clock.at.Add(time.Minute))
	settled, err := s.Settle(ctx, late, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 100, Formation: []int64{latePartner}}, op())
	if err != nil || settled.Duplicate || settled.Body["damage"] != int64(100) || settled.Body["total_hurt"] != int64(100) {
		t.Fatalf("late settle %+v %v", settled, err)
	}
	if total := scalar(t, p, `SELECT hurt FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=1 AND boss_id=$2 AND player_id=$3`, int64(server), d.FirstBossID, int64(late.PlayerID)); total != 100 {
		t.Fatal("frozen generation total", total)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=2 AND player_id=$2`, int64(server), int64(late.PlayerID)); rows != 0 {
		t.Fatal("successor totals touched", rows)
	}
	if generation, boss, courage, _ := worldBossOccurrence(t, p, server); generation != 2 || boss != d.FirstBossID || courage != 0 {
		t.Fatalf("late result changed the successor generation=%d boss=%d courage=%d", generation, boss, courage)
	}
	if n := scalar(t, p, `SELECT count(*) FROM worldboss_attempts WHERE player_id=$1`, int64(late.PlayerID)); n != 0 {
		t.Fatal("mode-local attempt row", n)
	}

	repeated, err := s.Settle(ctx, late, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 999, Formation: []int64{latePartner}}, op())
	if err != nil || !repeated.Duplicate || repeated.Body["damage"] != int64(100) || repeated.Body["total_hurt"] != int64(100) {
		t.Fatalf("duplicate settle %+v %v", repeated, err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM worldboss_attempt_settlements WHERE player_id=$1 AND damage=100`, int64(late.PlayerID)); n != 1 {
		t.Fatal("settlement rows", n)
	}
	if total := scalar(t, p, `SELECT hurt FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=1 AND boss_id=$2 AND player_id=$3`, int64(server), d.FirstBossID, int64(late.PlayerID)); total != 100 {
		t.Fatal("duplicate changed the frozen generation total", total)
	}
	if rows := scalar(t, p, `SELECT count(*) FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=2 AND player_id=$2`, int64(server), int64(late.PlayerID)); rows != 0 {
		t.Fatal("duplicate touched the successor board", rows)
	}
}

type cancellingSettlementStore struct {
	worldbossstore.Store
	cancel context.CancelFunc
}

func (s cancellingSettlementStore) InsertSettlementTx(c context.Context, t tx.Tx, attemptID ids.UUID, playerID identity.PlayerID, damage int64, settledAt time.Time) error {
	s.cancel()
	return s.Store.InsertSettlementTx(c, t, attemptID, playerID, damage, settledAt)
}

// R5D-03: cancelling the RESULT transaction at the settlement insert rolls back
// Combat's attestation and the damage, leaving the attempt unsettled.
func TestR5DWorldBossCancelledResultNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	a, partner := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	s := worldBossService(t, p, clock)
	formation := []int64{partner}

	if _, err := s.Start(ctx, a, app.StartRequest{CampaignID: d.FirstBossID, Formation: formation}, op()); err != nil {
		t.Fatal(err)
	}
	runContext, cancel := context.WithCancel(ctx)
	s.Store = cancellingSettlementStore{Store: worldbossstore.Store{}, cancel: cancel}
	if _, err := s.Settle(runContext, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 500, Formation: formation}, op()); err == nil {
		t.Fatal("cancelled RESULT committed")
	}
	if n := scalar(t, p, `SELECT count(*) FROM worldboss_attempt_settlements WHERE player_id=$1`, int64(a.PlayerID)); n != 0 {
		t.Fatal("cancelled RESULT left a settlement", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=1 AND player_id=$2`, int64(server), int64(a.PlayerID)); n != 0 {
		t.Fatal("cancelled RESULT credited damage", n)
	}
	if n := scalar(t, p, `SELECT count(*) FROM combat_attempts WHERE domain_kind='WORLD_BOSS' AND authority_scope=$1 AND domain_locator=$2 AND state='TERMINAL'`,
		fmt.Sprintf("server:%d", server), fmt.Sprintf("player:%d", a.PlayerID)); n != 0 {
		t.Fatal("cancelled RESULT terminalised the attempt", n)
	}

	s.Store = worldbossstore.Store{}
	settled, err := s.Settle(ctx, a, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 500, Formation: formation}, op())
	if err != nil || settled.Duplicate || settled.Body["damage"] != int64(500) {
		t.Fatalf("settle after cancellation %+v %v", settled, err)
	}
	if n := scalar(t, p, `SELECT count(*) FROM worldboss_attempt_settlements WHERE player_id=$1 AND damage=500`, int64(a.PlayerID)); n != 1 {
		t.Fatal("settlement rows after retry", n)
	}
}
