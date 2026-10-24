//go:build postgres

package playerdisplay_test

import (
	"errors"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	app "gxb.local/backend/v2/internal/application/campaign"
	hero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func campaignMode(t *testing.T, p *pg.Pool) app.Mode {
	t.Helper()
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	heroes := characterstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	owner := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i9-3a-campaign-native-fixture-secret")}
	return app.Mode{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Fresh: p, Store: campaignstore.Store{}, Content: content,
		Fence: values, Functions: values, Directory: i4store.PlayerDirectoryReader{}, Heroes: characterstore.CampaignHeroPort{Store: heroes}, HeroExp: hero.Service{ProgressionStore: heroes, Progression: content},
		Privileges: privilegeProvider(p), Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Progression: values,
		Combat: combatService(t, p), Energy: owner, Grants: owner, Stages: owner, Facts: i5.ObjectiveFacts{Owner: owner, Open: values}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func campaignRow(t *testing.T, rows any, id int64) map[string]any {
	t.Helper()
	list, _ := rows.([]any)
	for _, raw := range list {
		if row, ok := raw.(map[string]any); ok && fmt.Sprint(row["campaign_id"]) == fmt.Sprint(id) {
			return row
		}
	}
	t.Fatalf("campaign row %d missing from %v", id, rows)
	return nil
}

func TestI9_3ACampaignNormalAndSuperNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := campaignMode(t, pool)
	a, revision := bornActor(t, pool), installed(t, pool)
	bornHero(t, pool, a, revision, 10001001, 1)
	bornHero(t, pool, a, revision, 10001002, 2)
	team := []int64{0, 1, 2, 0, 0}
	exec(t, pool, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(a.PlayerID))

	world, err := s.Load(ctx, a, op())
	if err != nil || len(world["normal"].([]any)) != 1 || world["super"] != nil && len(world["super"].([]any)) != 0 || fmt.Sprint(world["normal_campaign_id"]) != "100001" {
		t.Fatalf("new player world %v %v", world, err)
	}
	if _, err = s.Fight(ctx, a, app.Fight{CampaignID: 100002, Type: d.Normal, Formation: team}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("unopened node fought: %v", err)
	}
	if _, err = s.Fight(ctx, a, app.Fight{CampaignID: 100001, Type: d.Super, Formation: team}, op()); !errors.Is(err, d.ErrInvalid) {
		t.Fatalf("wrong wire type fought: %v", err)
	}

	first, err := s.Fight(ctx, a, app.Fight{CampaignID: 100001, Type: d.Normal, Formation: team}, op())
	if err != nil || first["battle_id"] != 1 || first["items"] == nil {
		t.Fatalf("fight %v %v", first, err)
	}
	again, err := s.Fight(ctx, a, app.Fight{CampaignID: 100001, Type: d.Normal, Formation: team[:4]}, op())
	if err != nil || fmt.Sprint(again["items"]) != fmt.Sprint(first["items"]) {
		t.Fatalf("a re-sent fight with a changed team redrew drops: %v / %v %v", first["items"], again["items"], err)
	}

	tracked, _ := changes.Track(ctx)
	won, err := s.Result(tracked, a, app.Result{CampaignID: 100001, Type: d.Normal, Star: 3, Formation: team[:4]}, op())
	if err != nil || won.Duplicate || won.Body["is_win"] != 1 || fmt.Sprint(won.Body["star_crystal"]) != "30" || len(won.Body["exps"].([]any)) != 2 {
		t.Fatalf("win %+v %v", won, err)
	}
	if fmt.Sprint(campaignRow(t, won.Body["campaigns"], 100001)["star"]) != "3" || fmt.Sprint(campaignRow(t, won.Body["campaigns"], 100002)["star"]) != "0" {
		t.Fatalf("touched rows %v", won.Body["campaigns"])
	}
	duplicate, err := s.Result(ctx, a, app.Result{CampaignID: 100001, Type: d.Normal, Star: 3, Formation: team[:4]}, op())
	economy, _ := duplicate.Body["economy_"].(map[string]any)
	if err != nil || !duplicate.Duplicate || economy["energy"] == nil || economy["mana"] == nil || economy["crystal"] == nil {
		t.Fatalf("duplicate result %+v %v", duplicate, err)
	}
	if _, err = s.Result(ctx, a, app.Result{CampaignID: 100002, Type: d.Normal, Star: 3, Formation: team}, op()); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("result without a fight: %v", err)
	}

	if _, err = s.Fight(ctx, a, app.Fight{CampaignID: 100002, Type: d.Normal, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	lost, err := s.Result(ctx, a, app.Result{CampaignID: 100002, Type: d.Normal, Star: 0, Formation: team}, op())
	if err != nil || lost.Body["is_win"] != 0 || fmt.Sprint(campaignRow(t, lost.Body["campaigns"], 100002)["star"]) != "0" || lost.Body["exps"] != nil {
		t.Fatalf("loss %+v %v", lost, err)
	}

	exec(t, pool, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)VALUES($1,31,$2,'function.lua:31:1|11',clock_timestamp()-interval '1 minute')`, int64(a.PlayerID), revision)
	world, err = s.Load(ctx, a, op())
	if err != nil || fmt.Sprint(campaignRow(t, world["super"], 100019)["daily_limit"]) != "3" {
		t.Fatalf("super world %v %v", world, err)
	}
	if _, err = s.Fight(ctx, a, app.Fight{CampaignID: 100019, Type: d.Super, Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	elite, err := s.Result(ctx, a, app.Result{CampaignID: 100019, Type: d.Super, Star: 2, Formation: team}, op())
	if err != nil || fmt.Sprint(campaignRow(t, elite.Body["campaigns"], 100019)["daily_limit"]) != "2" || elite.Body["star_crystal"] != nil {
		t.Fatalf("super win %+v %v", elite, err)
	}
	detail := map[string]any{}
	loaded, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if err = s.OverlayMID1(ctx, pool, a, false, time.Now(), detail); err != nil || fmt.Sprint(detail["112"]) != fmt.Sprint(loaded) {
		t.Fatalf("MID1 detail[112] differs from 112: %v / %v %v", detail["112"], loaded, err)
	}
}
