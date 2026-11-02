//go:build postgres

package missions_test

import (
	"context"
	"errors"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/commerceprivilegestore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/privilege"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Thresholds are explicitly seeded fixture state; this tests settlement, not earned-medal provenance.
func TestActivityNativeThresholdConcurrentReplayAndReset(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(now.Year(), now.Month(), now.Day()+1, 12, 0, 0, 0, time.UTC)
	actor := runtimeActor(t, p, at)
	ticker := &missionClock{at: at}
	service := runtimeService(p, ticker)
	if _, err = service.ReadMissions(ctx, actor, objective.Daily, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	if _, err = service.ClaimActivityChest(ctx, actor, "DAY", 1, runtimeOperation(t, at)); !errors.Is(err, i5.ErrMissionRefused) {
		t.Fatalf("below threshold: %v", err)
	}
	seed := func(day, week int64) {
		t.Helper()
		tr, err := p.Begin(ctx, tx.Options{})
		if err != nil {
			t.Fatal(err)
		}
		defer tr.Rollback(ctx)
		store := i5store.Store{}
		root, err := store.LockMissionRootTx(ctx, tr, actor.PlayerID, ticker.at)
		if err != nil {
			t.Fatal(err)
		}
		version := root.StateVersion
		root.DayHuoyue = day
		root.WeekHuoyue = week
		root.StateVersion++
		if err = store.SaveMissionRootTx(ctx, tr, root, version); err != nil {
			t.Fatal(err)
		}
		if err = tr.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	quantity := func(item int64) int64 {
		t.Helper()
		var n int64
		if err := p.QueryRow(ctx, `SELECT COALESCE((SELECT quantity FROM player_item_stacks WHERE player_id=$1 AND item_id=$2),0)`, int64(actor.PlayerID), item).Scan(&n); err != nil {
			t.Fatal(err)
		}
		return n
	}
	seed(150, 1000)
	before := quantity(50001001)
	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for range 2 {
		op := runtimeOperation(t, at)
		wg.Add(1)
		go func() { defer wg.Done(); _, e := service.ClaimActivityChest(ctx, actor, "DAY", 1, op); errs <- e }()
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if got := quantity(50001001) - before; got != 3 {
		t.Fatalf("concurrent/replayed grant = %d want3", got)
	}
	for _, index := range []int64{2, 3, 4, 5} {
		if _, err = service.ClaimActivityChest(ctx, actor, "DAY", index, runtimeOperation(t, at)); err != nil {
			t.Fatalf("daily%d: %v", index, err)
		}
	}
	if quantity(50001979) != 1 {
		t.Fatal("Dodge ticket custody not granted")
	}
	for _, index := range []int64{1, 2} {
		if _, err = service.ClaimActivityChest(ctx, actor, "WEEK", index, runtimeOperation(t, at)); err != nil {
			t.Fatalf("week%d: %v", index, err)
		}
	}
	body, err := service.ClaimActivityChest(ctx, actor, "DAY", 1, runtimeOperation(t, at))
	if err != nil {
		t.Fatal(err)
	}
	flags := body["huoyue_info"].(map[string]any)["day_award"].([]int64)
	for _, v := range flags {
		if v != 1 {
			t.Fatalf("stock flags: %v", flags)
		}
	}
	if quantity(50001001)-before != 3 || quantity(50001174) != 1 || quantity(50001175) != 1 {
		t.Fatal("retry or weekly gifts incorrect")
	}
	ticker.at = at.Add(24 * time.Hour)
	if _, err = service.ReadMissions(ctx, actor, objective.Daily, runtimeOperation(t, ticker.at)); err != nil {
		t.Fatal(err)
	}
	root, err := (i5store.Store{}).ReadMissionRootTx(ctx, p, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if root.DayHuoyue != 0 || len(root.DayAward) != 0 {
		t.Fatalf("day reset: %#v", root)
	}
	if _, err = service.ClaimActivityChest(ctx, actor, "DAY", 1, runtimeOperation(t, ticker.at)); !errors.Is(err, i5.ErrMissionRefused) {
		t.Fatalf("next day below threshold: %v", err)
	}
	ticker.at = at.Add(7 * 24 * time.Hour)
	if _, err = service.ReadMissions(ctx, actor, objective.Daily, runtimeOperation(t, ticker.at)); err != nil {
		t.Fatal(err)
	}
	root, err = (i5store.Store{}).ReadMissionRootTx(ctx, p, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if root.WeekHuoyue != 0 || len(root.WeekAward) != 0 {
		t.Fatalf("week reset: %#v", root)
	}
}

func TestActivityNativePinned47ConsumersAndCanonicalSpend(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := now.Add(24 * time.Hour)
	a := runtimeActor(t, p, at)
	service := runtimeService(p, &missionClock{at: at})
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = p.Raw().Exec(ctx, `UPDATE player_progression SET level=45,exp=$2 WHERE player_id=$1`, int64(a.PlayerID), catalog.PlayerProgression.Rows[43].TotalExp); err != nil {
		t.Fatal(err)
	}
	old := "5ca02bec78f825851fe6ec575977606a3280d15118f8c9900c7dcb66a204f62d"
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	earlier := *service.Missions
	earlier.Activity = nil
	if _, err = earlier.MaterializeTx(ctx, tr, i5.MissionScope{PlayerID: a.PlayerID, ContentRevision: old, DecisionAt: at}); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
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
	tr, err = p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	facts := i5.ObjectiveFacts{Owner: service, Open: i5store.Store{}}
	prepared, err := facts.PrepareTx(ctx, tr, a.PlayerID, timed)
	if err != nil {
		t.Fatal(err)
	}
	store := i5store.Store{}
	balance, exists, err := store.LockScalarTx(ctx, tr, a.PlayerID, "crystal", at)
	if err != nil {
		t.Fatal(err)
	}
	if !exists {
		balance = economy.ScalarBalance{PlayerID: a.PlayerID, ResourceKey: "crystal"}
	}
	// Funding is a fixture setup through the canonical value writer; only the decrease counts as spending.
	balance.Amount += 15000
	balance.StateVersion++
	balance.UpdatedAt = at
	if err = store.SaveScalarTx(ctx, tr, balance, exists); err != nil {
		t.Fatal(err)
	}
	balance.Amount -= 10000
	balance.StateVersion++
	if err = store.SaveScalarTx(ctx, tr, balance, true); err != nil {
		t.Fatal(err)
	}
	fact := objective.Fact{PlayerID: a.PlayerID, SourceDomain: "top-floor", SourceBusinessKey: "native-pinned-consumer", Kind: objective.PVPFightKind, Delta: 3}
	if err = facts.RecordTx(prepared, tr, op, fact); err != nil {
		t.Fatal(err)
	}
	if err = facts.RecordTx(prepared, tr, op, fact); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	rows, err := store.ListMissionInstancesTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	checked := 0
	for _, row := range rows {
		switch row.ObjectiveID {
		case 10006, 10031, 10032:
			checked++
			if row.ContentRevision != old || row.CompletedAt == nil {
				t.Fatalf("old row not advanced: %#v", row)
			}
			if row.ObjectiveID == 10006 && row.Progress != 3 {
				t.Fatalf("PVP retry counted twice: %#v", row)
			}
		}
	}
	if checked != 3 {
		t.Fatalf("checked %d expected3", checked)
	}
}

func TestActivityNativeMaxLevelVIPAndLostCommit(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := now.Add(24 * time.Hour)
	a := runtimeActor(t, p, at)
	service := runtimeService(p, &missionClock{at: at})
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	exp := catalog.PlayerProgression.Rows[98].TotalExp
	if _, err = p.Raw().Exec(ctx, `UPDATE player_progression SET level=100,exp=$2 WHERE player_id=$1`, int64(a.PlayerID), exp); err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	pc, err := (contentstore.Store{}).PrivilegeCatalogTx(ctx, tr, catalog.RevisionID())
	if err != nil {
		t.Fatal(err)
	}
	privileges := commerceprivilegestore.Store{}
	state, exists, err := privileges.ReadPrivilegeTx(ctx, tr, a.PlayerID, true)
	if err != nil {
		t.Fatal(err)
	}
	old := state.StateVersion
	if !exists {
		state = privilege.State{PlayerID: a.PlayerID, LogicalServerID: a.LogicalServerID, MonthlyState: privilege.MonthlyAbsent, PolicyVersion: privilege.ManualPolicy, OriginClass: privilege.ManualClass, CreatedAt: at}
	}
	state.Charge = pc.Rows[6].Charge
	state.VIPLevel = 6
	state.ContentRevision = catalog.RevisionID()
	state.Issuer = "native-fixture"
	state.Reason = "activity VIP boundary proof"
	state.StateVersion = old + 1
	state.UpdatedAt = at
	if err = privileges.SavePrivilegeTx(ctx, tr, old, state); err != nil {
		t.Fatal(err)
	}
	root, err := (i5store.Store{}).LockMissionRootTx(ctx, tr, a.PlayerID, at)
	if err != nil {
		t.Fatal(err)
	}
	version := root.StateVersion
	root.DayHuoyue = 90
	root.StateVersion++
	if err = (i5store.Store{}).SaveMissionRootTx(ctx, tr, root, version); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	service.Runner.DB = &loseFirstMissionCommit{db: p}
	if _, err = service.ClaimActivityChest(ctx, a, "DAY", 3, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	if _, err = service.ClaimActivityChest(ctx, a, "DAY", 3, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	for key, want := range map[string]int64{"guild_coin": 360, "march_coin": 300} {
		var n int64
		if err = p.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key=$2`, int64(a.PlayerID), key).Scan(&n); err != nil || n != want {
			t.Fatalf("%s got%d want%d: %v", key, n, want, err)
		}
	}
	var after int64
	if err = p.QueryRow(ctx, `SELECT exp FROM player_progression WHERE player_id=$1`, int64(a.PlayerID)).Scan(&after); err != nil || after != exp {
		t.Fatalf("max level EXP changed: %d -> %d %v", exp, after, err)
	}
}

type failActivityRootSave struct{ i5.MissionStore }

func (f failActivityRootSave) SaveMissionRootTx(context.Context, tx.Tx, objective.MissionRoot, int64) error {
	return errors.New("injected root-save failure")
}

func TestActivityNativeGrantRollsBackWithClaimFlag(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(ctx)
	if err != nil {
		t.Fatal(err)
	}
	at := now.Add(24 * time.Hour)
	a := runtimeActor(t, p, at)
	service := runtimeService(p, &missionClock{at: at})
	if _, err = service.ReadMissions(ctx, a, objective.Daily, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	store := i5store.Store{}
	root, err := store.LockMissionRootTx(ctx, tr, a.PlayerID, at)
	if err != nil {
		t.Fatal(err)
	}
	version := root.StateVersion
	root.DayHuoyue = 150
	root.StateVersion++
	if err = store.SaveMissionRootTx(ctx, tr, root, version); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	faulty := *service.Missions
	faulty.Store = failActivityRootSave{MissionStore: faulty.Store}
	service.Missions = &faulty
	if _, err = service.ClaimActivityChest(ctx, a, "DAY", 5, runtimeOperation(t, at)); err == nil {
		t.Fatal("injected failure ignored")
	}
	var n int64
	if err = p.QueryRow(ctx, `SELECT count(*) FROM player_item_stacks WHERE player_id=$1 AND item_id=50001979`, int64(a.PlayerID)).Scan(&n); err != nil || n != 0 {
		t.Fatalf("grant survived rollback %d %v", n, err)
	}
	saved, err := store.ReadMissionRootTx(ctx, p, a.PlayerID)
	if err != nil || len(saved.DayAward) != 0 {
		t.Fatalf("claim flag survived rollback %#v %v", saved, err)
	}
	service.Missions.Store = store
	if _, err = service.ClaimActivityChest(ctx, a, "DAY", 5, runtimeOperation(t, at)); err != nil {
		t.Fatal(err)
	}
}

func TestActivityNativeMissingRequiredPayloadIsRefused(t *testing.T) {
	p := missionPool(t)
	ctx := context.Background()
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(ctx)
	if _, err = tr.Exec(ctx, `DELETE FROM content_mission_activity_catalogs WHERE revision_id=$1`, catalog.RevisionID()); err != nil {
		t.Fatal(err)
	}
	if _, err = (contentstore.Store{}).MissionActivityCatalogTx(ctx, tr, catalog.RevisionID()); err == nil {
		t.Fatal("declared activity payload silently omitted")
	}
	old, err := (contentstore.Store{}).MissionActivityCatalogTx(ctx, tr, "5ca02bec78f825851fe6ec575977606a3280d15118f8c9900c7dcb66a204f62d")
	if err != nil || old != nil {
		t.Fatalf("old47 optional payload %#v %v", old, err)
	}
}
