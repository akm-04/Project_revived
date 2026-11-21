//go:build postgres

package missions_test

import (
	"context"
	"errors"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// TestGrowPromotionChainNativeHeroPromotedFact proves the I9-11 Hero promotion
// producer's fact kind advances the source mission chain: one committed delta
// per promotion, a claim creates the next chained row, and the next row starts
// empty and expects its own promotions.
func TestGrowPromotionChainNativeHeroPromotedFact(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(now.Year(), now.Month(), now.Day()+1, 20, 59, 50, 0, time.UTC)
	a := runtimeActor(t, p, at)
	service := runtimeService(p, &missionClock{at: at})

	seed := func(campaignIDs ...int64) {
		t.Helper()
		tr, err := p.Begin(ctx, tx.Options{})
		if err != nil {
			t.Fatal(err)
		}
		store := campaignstore.Store{}
		record, err := store.LockTx(ctx, tr, a.PlayerID, at)
		if err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		record.Progress.Nodes = map[int64]campaign.NodeState{}
		for _, id := range campaignIDs {
			record.Progress.Nodes[id] = campaign.NodeState{CampaignID: id, Star: 1, ClearCountFloor: 1, ClearCountExact: true}
		}
		if err = store.SaveTx(ctx, tr, a.PlayerID, record, campaignIDs, at); err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	seed(100004, 100011)

	body, err := service.ReadMissions(ctx, a, objective.GrowMain, runtimeOperation(t, at))
	if err != nil {
		t.Fatal(err)
	}
	rows, ok := body["mission_list"].([]any)
	if !ok {
		t.Fatalf("mission_list %#v", body["mission_list"])
	}
	found := false
	for _, raw := range rows {
		if row, ok := raw.(map[string]any); ok && row["table_id"] == int64(20001) {
			found = true
		}
	}
	if !found {
		t.Fatalf("unlocked grow chain head missing from %#v", rows)
	}

	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	op := runtimeOperation(t, at)
	op.Policies, err = policy.NewSet(policy.Ref{Name: "content", Version: catalog.RevisionID()})
	if err != nil {
		t.Fatal(err)
	}
	timed, err := gen.NewTimedOperation(op, at)
	if err != nil {
		t.Fatal(err)
	}
	facts := i5.ObjectiveFacts{Owner: service, Open: i5store.Store{}}
	promote := func(source string) {
		t.Helper()
		tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		prepared, err := facts.PrepareTx(ctx, tr, a.PlayerID, timed)
		if err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		fact := objective.Fact{PlayerID: a.PlayerID, SourceDomain: "character-hero", SourceBusinessKey: source, Kind: "HERO_PROMOTED", Delta: 1}
		if err = facts.RecordTx(prepared, tr, op, fact); err != nil {
			tr.Rollback(ctx)
			t.Fatal(err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	progress := func(id int64) (int64, bool, bool) {
		t.Helper()
		var got int64
		var complete bool
		err := p.QueryRow(ctx, `SELECT progress,completed_at IS NOT NULL FROM player_mission_instances WHERE player_id=$1 AND objective_id=$2 AND definition_revision='I9_MISSIONS_V1'`, int64(a.PlayerID), id).Scan(&got, &complete)
		if errors.Is(err, kernelstore.ErrNoRows) {
			return 0, false, false
		}
		if err != nil {
			t.Fatal(err)
		}
		return got, complete, true
	}

	promote("promotion-1")
	promote("promotion-2")
	if got, complete, exists := progress(20001); !exists || got != 2 || !complete {
		t.Fatalf("20001 progress %d complete %v exists %v", got, complete, exists)
	}
	if _, err := service.ClaimMission(ctx, a, 20001, "", runtimeOperation(t, at)); err != nil {
		t.Fatalf("claim 20001: %v", err)
	}
	var mana int64
	if err = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='mana'`, int64(a.PlayerID)).Scan(&mana); err != nil || mana != 50000 {
		t.Fatalf("20001 mana reward %d %v", mana, err)
	}
	if got, complete, exists := progress(20002); !exists || got != 0 || complete {
		t.Fatalf("chained 20002 progress %d complete %v exists %v", got, complete, exists)
	}
	promote("promotion-3")
	if got, complete, _ := progress(20002); got != 1 || complete {
		t.Fatalf("20002 after one promotion progress %d complete %v", got, complete)
	}
	if _, err := service.ClaimMission(ctx, a, 20002, "", runtimeOperation(t, at)); !errors.Is(err, i5.ErrMissionRefused) {
		t.Fatalf("incomplete chained claim: %v", err)
	}
	promote("promotion-4")
	if got, complete, _ := progress(20002); got != 2 || !complete {
		t.Fatalf("20002 after two promotions progress %d complete %v", got, complete)
	}
	if _, err := service.ClaimMission(ctx, a, 20002, "", runtimeOperation(t, at)); err != nil {
		t.Fatalf("claim 20002: %v", err)
	}
	if got, complete, exists := progress(20003); !exists || got != 0 || complete {
		t.Fatalf("last chained row 20003 progress %d complete %v exists %v", got, complete, exists)
	}
}
