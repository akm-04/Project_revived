//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	app "gxb.local/backend/v2/internal/application/dormhouse"
	dorm "gxb.local/backend/v2/internal/domain/dormhouse"
	"gxb.local/backend/v2/internal/foundation/changes"
	"gxb.local/backend/v2/internal/foundation/tx"
	"testing"
	"time"
)

type unavailableGlueContent struct{ app.ContentPort }

func (unavailableGlueContent) DormInputsActive(context.Context) (string, bool, error) {
	return "", false, errors.New("fresh source unavailable")
}

type failingGlueCounter struct{ app.GluePurchaseOwner }

func (counter failingGlueCounter) SaveGluePurchasesTx(ctx context.Context, transaction tx.Tx, planned dorm.GluePurchases, previousVersion int64) error {
	if err := counter.GluePurchaseOwner.SaveGluePurchasesTx(ctx, transaction, planned, previousVersion); err != nil {
		return err
	}
	_, err := transaction.Exec(ctx, `SELECT nonexistent_rollback_probe FROM player_dorm_glue_purchases`)
	return err
}

func TestI910CGlueOuterSQLFailureRollsBackCounterValueAndReceipts(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	player := bornActor(t, database)
	if _, err := privilegeService(database, database).ImportManual(ctx, authority(), importQ(player, uuid().String(), 0), op()); err != nil {
		t.Fatal(err)
	}
	owner := dormstore.Store{Queryer: database}
	service := dormService(database, database)
	service.GluePurchases = failingGlueCounter{owner}
	service.GlueValues = dailyFloorService(database)
	service.GluePrivileges = privilegeProvider(database)
	current := opPinned(revision)
	receiptsBefore := i910cGrantReceiptCount(t, database, player.PlayerID)
	if _, err := service.Command(ctx, player, app.Command{Family: app.BuyGlue}, current); err == nil {
		t.Fatal("injected SQL failure accepted")
	}
	if _, exists, err := owner.ReadGluePurchasesTx(ctx, database, player.PlayerID); err != nil || exists {
		t.Fatal("counter survived rollback", exists, err)
	}
	crystal, _, err := (i5store.Store{}).ReadScalarTx(ctx, database, player.PlayerID, "crystal")
	if err != nil || crystal.Amount != 1000 || i910cGrantReceiptCount(t, database, player.PlayerID) != receiptsBefore {
		t.Fatal("value/inner receipt survived rollback", crystal, err)
	}
	var outerReceipts int64
	if err = database.QueryRow(ctx, `SELECT count(*) FROM gxb_operation_receipts WHERE domain='dorm-house' AND operation=$1 AND semantic_key=$2`, app.BuyGlue, current.ID.String()).Scan(&outerReceipts); err != nil || outerReceipts != 0 {
		t.Fatal("outer receipt survived rollback", outerReceipts, err)
	}
	service.GluePurchases = owner
	if _, err = service.Command(ctx, player, app.Command{Family: app.BuyGlue}, current); err != nil {
		t.Fatal("retry of rolled back admission", err)
	}
	if i910cGrantReceiptCount(t, database, player.PlayerID) != receiptsBefore+1 {
		t.Fatal("retry did not settle exactly once")
	}
}

func TestI910CGlueOuterCommandReceiptAndDailyLimit(t *testing.T) {
	ctx, _ := changes.Track(ctx)
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
	economy, ok := first.Body["economy_"].(map[string]int64)
	if first.Body["buy_glue_times"] != int64(1) || !ok || economy["glue"] != int64(150) || economy["crystal"] != int64(950) {
		t.Fatalf("buy glue reply %#v", first)
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
	if _, err := service.Command(ctx, player, app.Command{Family: app.BuyGlue}, op()); err != nil {
		t.Fatal("stale captured time was not clamped to the observation", err)
	}
	if stored, exists, err := (dormstore.Store{}).ReadGluePurchasesTx(ctx, database, player.PlayerID); err != nil || !exists || stored.Count != 1 {
		t.Fatal("clamped admission did not buy once", exists, err)
	}
}
