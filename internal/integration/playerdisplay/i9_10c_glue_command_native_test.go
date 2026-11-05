//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	"testing"
	"time"
)

type unavailableGlueContent struct{ app.ContentPort }

func (unavailableGlueContent) DormInputsActive(context.Context) (string, bool, error) {
	return "", false, errors.New("fresh source unavailable")
}

func TestI910CGlueOuterCommandReceiptAndDailyLimit(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := bornActor(t, database)
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(player, uuid().String(), 0), op()); err != nil {
		t.Fatal(err)
	}
	service := dormService(database, database)
	service.GluePurchases = dormstore.Store{Queryer: database}
	service.GlueValues = dailyFloorService(database)
	service.GluePrivileges = privilegeProvider(database)
	current := opPinned(revision)
	first, err := service.Command(ctx, player, app.Command{Family: app.BuyGlue}, current)
	if err != nil {
		t.Fatal(err)
	}
	economy := first.Body["economy_"].(map[string]any)
	if first.Body["buy_glue_times"] != int64(1) || economy["glue"] != int64(150) || economy["crystal"] != int64(950) {
		t.Fatal(first)
	}
	service.Content = unavailableGlueContent{service.Content}
	service.GluePrivileges = nil
	replay, err := service.Command(ctx, player, app.Command{Family: app.BuyGlue}, current)
	if err != nil {
		t.Fatal("receipt depended on fresh source/VIP", err)
	}
	expected, _ := json.Marshal(first)
	actual, _ := json.Marshal(replay)
	if string(expected) != string(actual) {
		t.Fatal("reply replay drift", string(expected), string(actual))
	}
	service = dormService(database, database)
	service.GluePurchases = dormstore.Store{Queryer: database}
	service.GlueValues = dailyFloorService(database)
	service.GluePrivileges = privilegeProvider(database)
	if _, err = service.Command(ctx, player, app.Command{Family: app.BuyGlue}, op()); !errors.Is(err, app.ErrRejected) {
		t.Fatal("daily cap", err)
	}
	crystal, _, err := (i5store.Store{}).ReadScalarTx(ctx, database, player.PlayerID, "crystal")
	if err != nil || crystal.Amount != 950 {
		t.Fatal(crystal, err)
	}
	projection := app.GlueBootstrap{Owner: dormstore.Store{Queryer: database}}
	detail := map[string]any{"17": map[string]any{}}
	if err = projection.OverlayMID1(ctx, database, player, false, time.Now().UTC(), detail); err != nil || detail["17"].(map[string]any)["buy_glue_times"] != int64(1) {
		t.Fatal("reload", detail, err)
	}
	if err = projection.OverlayMID1(ctx, database, player, false, time.Now().UTC().Add(24*time.Hour), detail); err != nil || detail["17"].(map[string]any)["buy_glue_times"] != int64(0) {
		t.Fatal("next-day reload", detail, err)
	}
}

func TestI910CGlueUnknownPrivilegeRecoversWithoutInventingVIPZero(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := bornActor(t, database)
	service := dormService(database, database)
	service.GluePurchases = dormstore.Store{Queryer: database}
	service.GlueValues = dailyFloorService(database)
	service.GluePrivileges = privilegeProvider(database)
	if _, err := service.Command(ctx, player, app.Command{Family: app.BuyGlue}, opPinned(revision)); err == nil {
		t.Fatal("unknown privilege became VIP0")
	}
	if _, exists, err := (dormstore.Store{}).ReadGluePurchasesTx(ctx, database, player.PlayerID); err != nil || exists {
		t.Fatal("unknown privilege consumed purchase", exists, err)
	}
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(player, uuid().String(), 0), op()); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Command(ctx, player, app.Command{Family: app.BuyGlue}, op()); !errors.Is(err, app.ErrRejected) {
		t.Fatal("old admission was not retired at stale captured time", err)
	}
	if _, err := service.Command(ctx, player, app.Command{Family: app.BuyGlue}, op()); err != nil {
		t.Fatal("later qualification left lane permanently blocked", err)
	}
}
