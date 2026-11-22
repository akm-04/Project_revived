//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterbirth"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyconsumestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/campaign"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	pet "gxb.local/backend/v2/internal/application/characterpet"
	"gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/tx"
	heroproj "gxb.local/backend/v2/internal/projection/hero"
)

func campaignModeWithLevelAnnouncements(t *testing.T, p *pg.Pool) app.Mode {
	t.Helper()
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	heroes := characterstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	owner := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.LevelFunctionAnnouncements{}, CampaignClears: campaignstore.TutorialMilestones{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i9-3a-campaign-native-fixture-secret")}
	return app.Mode{Daily: dailyconsume.Service{Store: dailyconsumestore.Store{}, Costs: i5.MaterialCostDebiter{Store: values, Content: content}}, Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Fresh: p, Store: campaignstore.Store{}, Content: content,
		Fence: values, Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: characterstore.CampaignHeroPort{Store: heroes}, HeroExp: hero.Service{ProgressionStore: heroes, Progression: content},
		StoryWire: heroproj.StockHero, StoryHeroes: hero.Service{AcquisitionStore: heroes, Acquisition: content, CollectionAdmission: hero.CatalogCollectionAdmission{Content: content}, FreshFacets: characterbirth.FreshHeroFacets()},
		Pets: pet.Service{Store: heroes, Progression: content}, MaxColor: i5.CurrentMaxHeroColorProvider{},
		Privileges: privilegeProvider(p), Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Progression: values,
		Combat: combatService(t, p), Energy: owner, Grants: owner, Stages: owner, Facts: i5.ObjectiveFacts{Owner: owner, Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, BattleCounts: battleCountObserver(p)}
}

// TestI9TutorialFunction33WaitsForTheFirst100007Clear drives a committed
// production 113/114 result at level 7 and checks the Skill Upgrade function is
// announced only by that clear, and that its stored receipt keeps the field.
func TestI9TutorialFunction33WaitsForTheFirst100007Clear(t *testing.T) {
	database := pool(t)
	defer database.Close()
	revision := installed(t, database)
	actor := bornActor(t, database)
	bornHero(t, database, actor, revision, 10001001, 1)
	bornHero(t, database, actor, revision, 10001002, 2)
	exec(t, database, `UPDATE player_progression SET level=7,exp=(SELECT p.total_exp FROM gxb_content_player_progression p JOIN gxb_content_activation a ON a.revision_id=p.revision_id WHERE a.slot='content' AND p.level=6) WHERE player_id=$1`, int64(actor.PlayerID))
	exec(t, database, `UPDATE player_directory_profiles SET lev=7 WHERE player_id=$1`, int64(actor.PlayerID))
	exec(t, database, `INSERT INTO campaign_players(player_id,normal_bonus_id,super_bonus_id,pending_generation,last_generation,state_version,updated_at)VALUES($1,0,0,'','',1,clock_timestamp()) ON CONFLICT(player_id) DO NOTHING`, int64(actor.PlayerID))
	for node := int64(100001); node <= 100006; node++ {
		exec(t, database, `INSERT INTO campaign_nodes(player_id,campaign_id,star,win_day,wins,reset_day,resets,partner_drop,first_clear_day)VALUES($1,$2,3,0,0,0,0,false,1) ON CONFLICT(player_id,campaign_id) DO UPDATE SET star=3,first_clear_day=1`, int64(actor.PlayerID), node)
	}
	mode := campaignModeWithLevelAnnouncements(t, database)
	team := []int64{0, 1, 2, 0, 0}
	if _, err := mode.Fight(ctx, actor, app.Fight{CampaignID: 100007, Type: d.Normal, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	tracked, _ := changes.Track(ctx)
	won, err := mode.Result(tracked, actor, app.Result{CampaignID: 100007, Type: d.Normal, Star: 3, Formation: team}, op())
	if err != nil || won.Body["is_win"] != 1 {
		t.Fatalf("100007 result %+v %v", won, err)
	}
	_, announced := changes.Recorded(tracked)
	if !containsID(announced, 33) {
		t.Fatalf("first 100007 clear announced %v, want 33", announced)
	}
	record, err := (campaignstore.Store{}).ReadTx(ctx, database, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	var stored map[string]any
	if err := json.Unmarshal(record.LastResult, &stored); err != nil {
		t.Fatal(err)
	}
	functions, ok := stored["new_funcs_"].([]any)
	if !ok || len(functions) == 0 {
		t.Fatalf("stored receipt new_funcs_ = %#v", stored["new_funcs_"])
	}
	found := false
	for _, raw := range functions {
		if number, ok := raw.(float64); ok && int64(number) == 33 {
			found = true
		}
	}
	if !found {
		t.Fatalf("stored receipt new_funcs_ = %#v, want 33", functions)
	}
	// A second clear of the same node (replay) adds nothing.
	exec(t, database, `UPDATE campaign_players SET last_generation='' WHERE player_id=$1`, int64(actor.PlayerID))
	if _, err := mode.Fight(ctx, actor, app.Fight{CampaignID: 100007, Type: d.Normal, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	trackedAgain, _ := changes.Track(ctx)
	if _, err := mode.Result(trackedAgain, actor, app.Result{CampaignID: 100007, Type: d.Normal, Star: 3, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	_, again := changes.Recorded(trackedAgain)
	if containsID(again, 33) {
		t.Fatalf("second clear announced 33 again: %v", again)
	}
}

func containsID(ids []int64, want int64) bool {
	for _, id := range ids {
		if id == want {
			return true
		}
	}
	return false
}
