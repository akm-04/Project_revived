//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"fmt"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	app "gxb.local/backend/v2/internal/application/campaign"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/changes"
)

func TestI9_4DCampaignFrozenFinalAndOrdinaryClaim(t *testing.T) {
	p := pool(t)
	defer p.Close()
	actor, rev := bornActor(t, p), installed(t, p)
	bornHero(t, p, actor, rev, 10001001, 1)
	ref := character.HeroRef{PlayerID: actor.PlayerID, PartnerID: 1}
	compositeLevel(t, p, actor, rev, 100)
	exec(t, p, `UPDATE player_heroes SET level=100,color=15 WHERE player_id=$1 AND partner_id=$2`, int64(actor.PlayerID), ref.PartnerID)
	owner, heroes := i94AwakeningOwners(p)
	heroes.AwakeningEquipment = &owner
	if _, err := owner.ChangeAwakening(ctx, actor, "open", 1001001, 1, op()); err != nil {
		t.Fatal(err)
	}
	content := contentstore.Store{Queryer: p}
	mode := campaignMode(t, p)
	mode.Awakening = owner
	team := []int64{ref.PartnerID, 0, 0, 0, 0}
	if _, err := mode.Fight(ctx, actor, app.Fight{CampaignID: 100001, Type: d.Normal, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := mode.Result(ctx, actor, app.Result{CampaignID: 100001, Type: d.Normal, Star: 3, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	firstRecord, err := (campaignstore.Store{}).ReadTx(ctx, p, actor.PlayerID)
	if err != nil || firstRecord.Progress.State(100001).FirstClearDay == nil {
		t.Fatal("first clear day absent", err)
	}

	catalog, err := content.CampaignCatalogTx(ctx, p, rev)
	if err != nil {
		t.Fatal(err)
	}
	// Explicit campaign progression fixture exposes the high-level source quest node.
	for _, node := range catalog.Nodes {
		if node.Type == d.Normal || node.Type == d.Super {
			exec(t, p, `INSERT INTO campaign_nodes(player_id,campaign_id,star,win_day,wins,reset_day,resets,partner_drop)VALUES($1,$2,3,0,0,0,0,false) ON CONFLICT(player_id,campaign_id) DO NOTHING`, int64(actor.PlayerID), node.ID)
		}
	}

	// Qualify source material draws through actual113/114, including stale occurrence suppression.
	quantity := func(item int64) int64 {
		var n int64
		if err := p.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(actor.PlayerID), item).Scan(&n); err != nil {
			t.Fatal(err)
		}
		return n
	}
	for _, stale := range []bool{false, true} {
		materialFight := app.Fight{CampaignID: 1200021, Type: d.Super, Formation: team}
		if _, err := mode.Fight(ctx, actor, materialFight, op()); err != nil {
			t.Fatal(err)
		}
		frozenRecord, err := (campaignstore.Store{}).ReadTx(ctx, p, actor.PlayerID)
		if err != nil {
			t.Fatal(err)
		}
		var material objective.AwakeCampaignContext
		if err = json.Unmarshal(frozenRecord.PendingAwakening, &material); err != nil || len(material.Drops) != 1 || material.Final != nil {
			t.Fatal("source material binding", material, err)
		}
		if _, err = mode.Fight(ctx, actor, materialFight, op()); err != nil {
			t.Fatal(err)
		}
		repeated, err := (campaignstore.Store{}).ReadTx(ctx, p, actor.PlayerID)
		if err != nil || string(repeated.PendingAwakening) != string(frozenRecord.PendingAwakening) {
			t.Fatal("material START rerolled", err)
		}
		drop := material.Drops[0]
		if stale {
			if _, err = owner.ChangeAwakening(ctx, actor, "cancel", 1001001, 1, op()); err != nil {
				t.Fatal(err)
			}
			if _, err = owner.ChangeAwakening(ctx, actor, "open", 1001001, 1, op()); err != nil {
				t.Fatal(err)
			}
		}
		before := quantity(drop.ItemID)
		result := app.Result{CampaignID: 1200021, Type: d.Super, Star: 3, Formation: team}
		terminal := op()
		if _, err = mode.Result(ctx, actor, result, terminal); err != nil {
			t.Fatal("ordinary settlement stranded", err)
		}
		expected := before
		if !stale {
			expected += drop.Count
		}
		if got := quantity(drop.ItemID); got != expected {
			t.Fatal("source draw/stale credit", stale, drop.Count, got, expected)
		}
		if _, err = mode.Result(ctx, actor, result, terminal); err != nil {
			t.Fatal(err)
		}
		if quantity(drop.ItemID) != expected {
			t.Fatal("material result replay credited twice")
		}
	}
	fixture := op()
	if _, err := owner.SettleGrant(ctx, actor, grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "i94-fixture", Operation: "ordinary-gear", BusinessKey: fixture.ID.String(), Occurrence: fixture.ID.String(), PolicyVersion: "i94-fixture-v1"}, Lines: []grant.Line{{Kind: grant.StackItem, ItemID: 20001185, Amount: 1}, {Kind: grant.StackItem, ItemID: 50001013, Amount: 2}}}, fixture); err != nil {
		t.Fatal(err)
	}
	var slot int64
	for n := int64(1); n <= 6; n++ {
		pos, err := content.HeroEquipmentPositionTx(ctx, p, rev, 10001001, 15, n)
		if err != nil {
			t.Fatal(err)
		}
		if pos.ItemID == 20001185 {
			slot = n
		}
	}
	if _, err := heroes.EquipItem(ctx, actor, ref.PartnerID, slot, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := owner.ChangeAwakening(ctx, actor, "claim", 1001001, 1, op()); err != nil {
		t.Fatal(err)
	}
	sweep := app.Sweep{CampaignID: 1100006, Type: d.Normal, Count: 1, Kind: 1}
	sweepOp := op()
	if _, err := mode.Sweep(ctx, actor, sweep, sweepOp); err != nil {
		t.Fatal("actual117", err)
	}
	cardsAfterFirst := quantity(50001013)
	if _, err := mode.Sweep(ctx, actor, sweep, sweepOp); err != nil {
		t.Fatal("117 replay", err)
	}
	awakeRoot, err := (i5store.Store{Queryer: p}).ReadAwakeningTx(ctx, p, actor.PlayerID)
	if err != nil || awakeRoot.Active[0].Complete || quantity(50001013) != cardsAfterFirst {
		t.Fatal("sweep completed final or debited twice", awakeRoot, err)
	}
	fight := app.Fight{CampaignID: 1100006, Type: d.Normal, Formation: team}
	first, err := mode.Fight(ctx, actor, fight, op())
	if err != nil {
		t.Fatal(err)
	}
	again, err := mode.Fight(ctx, actor, fight, op())
	if err != nil || fmt.Sprint(again["items"]) != fmt.Sprint(first["items"]) {
		t.Fatal("START redrew rewards", err)
	}
	record, err := (campaignstore.Store{}).ReadTx(ctx, p, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	var frozen objective.AwakeCampaignContext
	if err = json.Unmarshal(record.PendingAwakening, &frozen); err != nil || frozen.Final == nil || frozen.Final.Mission != 1001003 {
		t.Fatal(frozen, err)
	}
	tracked, _ := changes.Track(ctx)
	result := app.Result{CampaignID: 1100006, Type: d.Normal, Star: 3, Formation: team, AwakeMission: 1001003}
	terminal := op()
	won, err := mode.Result(tracked, actor, result, terminal)
	if err != nil || won.Body["awake_mission_"] == nil {
		t.Fatal(won, err)
	}
	if _, err = mode.Result(ctx, actor, result, terminal); err != nil {
		t.Fatal("result replay", err)
	}
	claim := op()
	if _, err = owner.ChangeAwakening(ctx, actor, "claim", 1001003, 1, claim); err != nil {
		t.Fatal(err)
	}
	if _, err = owner.ChangeAwakening(ctx, actor, "claim", 1001003, 1, claim); err != nil {
		t.Fatal("claim replay", err)
	}
	h, err := (characterstore.Store{Queryer: p}).ReadHeroByPartnerIDTx(ctx, p, actor.PlayerID, ref.PartnerID)
	if err != nil || h.TableID != 11001001 {
		t.Fatal(h, err)
	}
}
