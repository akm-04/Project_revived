//go:build postgres

package missions_test

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestCampaignClearCountNativeRoundtripAndRollback(t *testing.T) {
	p := missionPool(t)
	player := missionPlayer(t, p)
	ctx := context.Background()
	store := campaignstore.Store{}
	raw, err := builtin.GeneratedFile("campaign_catalog.json")
	if err != nil {
		t.Fatal(err)
	}
	var catalog campaign.Catalog
	if err = json.Unmarshal(raw, &catalog); err != nil {
		t.Fatal(err)
	}
	if err = catalog.Validate(); err != nil {
		t.Fatal(err)
	}
	node, _ := catalog.Node(100001)
	at := time.Date(2026, 10, 25, 12, 0, 0, 0, time.UTC)
	run := func(commit bool) {
		t.Helper()
		tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
		if err != nil {
			t.Fatal(err)
		}
		defer tr.Rollback(ctx)
		record, err := store.LockTx(ctx, tr, player, at)
		if err != nil {
			t.Fatal(err)
		}
		result, err := catalog.Settle(record.Progress, node, 3, 100, false)
		if err != nil {
			t.Fatal(err)
		}
		record.Progress = result.Progress
		if err = store.SaveTx(ctx, tr, player, record, []int64{node.ID}, at); err != nil {
			t.Fatal(err)
		}
		if commit {
			if err = tr.Commit(ctx); err != nil {
				t.Fatal(err)
			}
		}
	}
	run(true)
	run(false)
	record, err := store.ReadTx(ctx, p, player)
	if err != nil || record.Progress.State(node.ID).ClearCountFloor != 1 || !record.Progress.State(node.ID).ClearCountExact {
		t.Fatalf("roundtrip/rollback: %+v %v", record, err)
	}
}
