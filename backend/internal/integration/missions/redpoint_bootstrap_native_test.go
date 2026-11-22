//go:build postgres

package missions_test

import (
	"context"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/lobby"
)

func seedMissionHuoyue(t *testing.T, p *pg.Pool, player identity.PlayerID, at time.Time, day, week int64) {
	t.Helper()
	ctx := context.Background()
	transaction, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := i5store.Store{}
	root, err := store.LockMissionRootTx(ctx, transaction, player, at)
	if err != nil {
		t.Fatal(err)
	}
	version := root.StateVersion
	root.DayHuoyue, root.WeekHuoyue = day, week
	root.StateVersion++
	if err := store.SaveMissionRootTx(ctx, transaction, root, version); err != nil {
		t.Fatal(err)
	}
	if err := transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func mid1Detail(t *testing.T, actor identity.ActorContext, at time.Time) map[string]any {
	t.Helper()
	detail, err := lobby.BuildMID1Detail(lobby.BootstrapView{Actor: actor, RegionName: "i94-native", Now: at})
	if err != nil {
		t.Fatal(err)
	}
	if shape, ok := detail["2560"].(map[string]any); !ok || len(shape) != 0 {
		t.Fatalf("lobby MID1 2560 baseline = %#v", detail["2560"])
	}
	return detail
}

func TestMID1BootstrapsMissionRedmarksUnder2560(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(now.Year(), now.Month(), now.Day()+1, 12, 0, 0, 0, time.UTC)
	content := contentstore.Store{Queryer: p}
	revision, err := content.ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := content.MissionActivityCatalogTx(ctx, p, revision)
	if err != nil || catalog == nil || len(catalog.Rules) == 0 {
		t.Fatalf("activity catalog unavailable: %v %#v", err, catalog)
	}
	var medal int64
	for _, rule := range catalog.Rules {
		medal = max(medal, rule.Medal)
	}
	medal++
	service := runtimeService(p, &missionClock{at: at})

	claimed := runtimeActor(t, p, at)
	seedMissionHuoyue(t, p, claimed.PlayerID, at, medal, medal)
	detail := mid1Detail(t, claimed, at)
	if err := (i5.MissionBootstrap{Owner: service}).OverlayMID1(ctx, p, claimed, false, at, detail); err != nil {
		t.Fatal(err)
	}
	want := map[string]any{"27": map[string]any{"function_id": int64(27), "redmark_list": []int64{2701}}}
	if !reflect.DeepEqual(detail["2560"], want) {
		t.Fatalf("MID1 2560 = %#v, want %#v", detail["2560"], want)
	}
	if !reflect.DeepEqual(detail["160"].(map[string]any)["redmarks_"], detail["2560"]) {
		t.Fatalf("MID1 160 redmarks_ = %#v, 2560 = %#v", detail["160"].(map[string]any)["redmarks_"], detail["2560"])
	}

	idle := runtimeActor(t, p, at)
	seedMissionHuoyue(t, p, idle.PlayerID, at, 0, 0)
	idleDetail := mid1Detail(t, idle, at)
	if err := (i5.MissionBootstrap{Owner: service}).OverlayMID1(ctx, p, idle, false, at, idleDetail); err != nil {
		t.Fatal(err)
	}
	wantIdle := map[string]any{"27": map[string]any{"function_id": int64(27), "redmark_list": []int64{}}}
	if !reflect.DeepEqual(idleDetail["2560"], wantIdle) {
		t.Fatalf("idle MID1 2560 = %#v, want %#v", idleDetail["2560"], wantIdle)
	}
}
