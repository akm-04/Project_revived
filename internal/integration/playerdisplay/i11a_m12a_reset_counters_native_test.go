//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/campaignstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dailyconsumestore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	app "gxb.local/backend/v2/internal/application/campaign"
	"gxb.local/backend/v2/internal/application/dailyconsume"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/operatorgrant"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func m12aAdmin() i5.AdminOperator {
	return i5.AdminOperator{ID: "m12a-native", ReasonCode: "M12a native reset"}
}

func m12aDailyService(p *pg.Pool) dailyconsume.Service {
	return dailyconsume.Service{Store: dailyconsumestore.Store{}, Runner: tx.Runner{DB: p}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12aCampaignMode(p *pg.Pool) app.Mode {
	return app.Mode{
		Timed:       gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: tx.Runner{DB: p}},
		Store:       campaignstore.Store{},
		Receipts:    kernelstore.Store{},
		ReceiptRead: kernelstore.Reader{Queryer: p},
	}
}

func m12aI5Service(p *pg.Pool) i5.Service {
	values := i5store.Store{Queryer: p}
	return i5.Service{Runner: tx.Runner{DB: p}, Store: values, Content: contentstore.Store{Queryer: p}, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.NoFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{}, Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func m12aDatabaseNow(t *testing.T, p *pg.Pool) time.Time {
	t.Helper()
	var now time.Time
	if err := p.Raw().QueryRow(ctx, `SELECT now()`).Scan(&now); err != nil {
		t.Fatal(err)
	}
	return now.UTC()
}

func m12aSeedDailyCounts(t *testing.T, p *pg.Pool, player int64, at time.Time, counts dailyconsume.Counts) {
	t.Helper()
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := dailyconsumestore.Store{}
	if _, err = store.LockTx(ctx, transaction, identity.PlayerID(player), at); err != nil {
		t.Fatal(err)
	}
	if err = store.SaveTx(ctx, transaction, identity.PlayerID(player), counts, at); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func m12aDailyUsed(t *testing.T, p *pg.Pool, player, day, counter int64) int64 {
	t.Helper()
	counts, err := (dailyconsumestore.Store{}).ReadTx(ctx, p, identity.PlayerID(player))
	if err != nil {
		t.Fatal(err)
	}
	return counts[counter].In(day).Used
}

func m12aSeedCampaign(t *testing.T, p *pg.Pool, player int64, at time.Time, day int64) {
	t.Helper()
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := campaignstore.Store{}
	record, err := store.LockTx(ctx, transaction, identity.PlayerID(player), at)
	if err != nil {
		t.Fatal(err)
	}
	record.Progress.Nodes = map[int64]d.NodeState{
		100001: {CampaignID: 100001, Star: 1, Wins: modes.Counter{Period: day, Used: 2}, Resets: modes.Counter{Period: day, Used: 1}},
		100002: {CampaignID: 100002, Star: 1, Wins: modes.Counter{Period: day, Used: 1}},
	}
	record.Progress.TrialWins = map[int64]modes.Counter{16: {Period: day, Used: 1}}
	if err = store.SaveTx(ctx, transaction, identity.PlayerID(player), record, []int64{100001, 100002}, at); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func m12aUpsertScalar(t *testing.T, p *pg.Pool, player int64, key string, amount int64, at time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at) VALUES($1,$2,$3,1,$4)
		ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=EXCLUDED.amount,state_version=player_currency_balances.state_version+1,updated_at=EXCLUDED.updated_at`,
		player, key, amount, at)
}

func m12aUpsertSkillPoints(t *testing.T, p *pg.Pool, player, amount int64, at time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO player_temporal_resources(player_id,resource_key,stored_amount,regen_anchor_at,policy_version,content_revision,state_version,updated_at)
		VALUES($1,'skill_point',$2,$3,'operator-reset-native',NULL,1,$3)
		ON CONFLICT(player_id,resource_key) DO UPDATE SET stored_amount=EXCLUDED.stored_amount,regen_anchor_at=EXCLUDED.regen_anchor_at,content_revision=NULL,state_version=player_temporal_resources.state_version+1,updated_at=EXCLUDED.updated_at`,
		player, amount, at)
}

func TestI11A_M12ADailyBuysResetNative(t *testing.T) {
	p := pool(t)
	service := m12aDailyService(p)
	a := bornActor(t, p)
	operationContext := op()
	day := modes.Day(operationContext.StartedAt)
	at := m12aDatabaseNow(t, p)
	m12aSeedDailyCounts(t, p, int64(a.PlayerID), at, dailyconsume.Counts{
		dailyconsume.CounterBuyEnergy: {Period: day, Used: 1},
		dailyconsume.CounterBuyMana:   {Period: day, Used: 1},
		dailyconsume.CounterBuySkill:  {Period: day, Used: 1},
		1:                             {Period: day, Used: 1},
	})

	if err := service.ResetOperatorDailyBuys(ctx, m12aAdmin(), a.PlayerID, "daily-buys:1", operationContext); err != nil {
		t.Fatal(err)
	}
	for _, counter := range []int64{dailyconsume.CounterBuyEnergy, dailyconsume.CounterBuyMana, dailyconsume.CounterBuySkill, 1} {
		if used := m12aDailyUsed(t, p, int64(a.PlayerID), day, counter); used != 0 {
			t.Fatalf("counter %d after reset = %d", counter, used)
		}
	}

	m12aSeedDailyCounts(t, p, int64(a.PlayerID), at, dailyconsume.Counts{dailyconsume.CounterBuyEnergy: {Period: day, Used: 1}})
	if err := service.ResetOperatorDailyBuys(ctx, m12aAdmin(), a.PlayerID, "daily-buys:1", op()); err != nil {
		t.Fatal(err)
	}
	if used := m12aDailyUsed(t, p, int64(a.PlayerID), day, dailyconsume.CounterBuyEnergy); used != 1 {
		t.Fatalf("a replayed key reset new use: used = %d", used)
	}

	missing := bornActor(t, p)
	if err := service.ResetOperatorDailyBuys(ctx, m12aAdmin(), missing.PlayerID, "daily-buys:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err := p.Raw().QueryRow(ctx, `SELECT count(*) FROM daily_consumption_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing row was created: %d", rows)
	}
}

func TestI11A_M12ACampaignDailyResetNative(t *testing.T) {
	p := pool(t)
	mode := m12aCampaignMode(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	day := modes.Day(at)
	m12aSeedCampaign(t, p, int64(a.PlayerID), at, day)

	if err := mode.ResetOperatorCampaignDaily(ctx, m12aAdmin(), a.PlayerID, "campaign-daily:1", op()); err != nil {
		t.Fatal(err)
	}
	record, err := (campaignstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	for _, node := range []int64{100001, 100002} {
		state := record.Progress.State(node)
		if state.Wins.In(day).Used != 0 || state.Resets.In(day).Used != 0 {
			t.Fatalf("node %d after reset = %+v", node, state)
		}
	}
	if used := record.Progress.TrialWins[16].In(day).Used; used != 0 {
		t.Fatalf("trial 16 after reset = %d", used)
	}

	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	state := record.Progress.State(100001)
	state.Wins = modes.Counter{Period: day, Used: 2}
	record.Progress.Nodes[100001] = state
	if err = (campaignstore.Store{}).SaveTx(ctx, transaction, a.PlayerID, record, []int64{100001}, at); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err = mode.ResetOperatorCampaignDaily(ctx, m12aAdmin(), a.PlayerID, "campaign-daily:1", op()); err != nil {
		t.Fatal(err)
	}
	record, err = (campaignstore.Store{}).ReadTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if used := record.Progress.State(100001).Wins.In(day).Used; used != 2 {
		t.Fatalf("a replayed key reset new use: used = %d", used)
	}

	missing := bornActor(t, p)
	if err = mode.ResetOperatorCampaignDaily(ctx, m12aAdmin(), missing.PlayerID, "campaign-daily:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM campaign_players WHERE player_id=$1`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing campaign row was created: %d", rows)
	}
}

func TestI11A_M12AOccultTicketsResetNative(t *testing.T) {
	p := pool(t)
	service := m12aI5Service(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	m12aUpsertScalar(t, p, int64(a.PlayerID), "occult_ticket", 0, at)
	m12aUpsertScalar(t, p, int64(a.PlayerID), "occult_energy_progress", 1, at)

	if err := service.ResetOperatorOccultTickets(ctx, m12aAdmin(), a.PlayerID, "occult-tickets:1", op()); err != nil {
		t.Fatal(err)
	}
	tickets, err := service.OccultTicketsTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if tickets.Tickets != 2 || tickets.Progress != 1 {
		t.Fatalf("tickets after reset = %+v", tickets)
	}

	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.DebitOccultTicketTx(ctx, transaction, a.PlayerID, op()); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err = service.ResetOperatorOccultTickets(ctx, m12aAdmin(), a.PlayerID, "occult-tickets:1", op()); err != nil {
		t.Fatal(err)
	}
	tickets, err = service.OccultTicketsTx(ctx, p, a.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	if tickets.Tickets != 1 {
		t.Fatalf("a replayed key reset new use: tickets = %d", tickets.Tickets)
	}

	missing := bornActor(t, p)
	if err = service.ResetOperatorOccultTickets(ctx, m12aAdmin(), missing.PlayerID, "occult-tickets:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM player_currency_balances WHERE player_id=$1 AND resource_key='occult_ticket'`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing ticket row was created: %d", rows)
	}
}

func TestI11A_M12ASkillPointsResetNative(t *testing.T) {
	p := pool(t)
	service := m12aI5Service(p)
	a := bornActor(t, p)
	at := m12aDatabaseNow(t, p)
	m12aUpsertSkillPoints(t, p, int64(a.PlayerID), 3, at)

	if err := service.ResetOperatorSkillPoints(ctx, m12aAdmin(), a.PlayerID, "skill-points:1", op()); err != nil {
		t.Fatal(err)
	}
	state, found, err := (i5store.Store{}).ReadTemporalTx(ctx, p, a.PlayerID, "skill_point")
	if err != nil || !found {
		t.Fatalf("skill point row: found=%v err=%v", found, err)
	}
	if state.StoredAmount != 10 || state.RegenAnchorAt != nil {
		t.Fatalf("skill points after reset = %+v", state)
	}

	state.StoredAmount, state.RegenAnchorAt, state.StateVersion, state.UpdatedAt = 4, &at, state.StateVersion+1, at
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	if err = (i5store.Store{}).SaveTemporalTx(ctx, transaction, state); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err = service.ResetOperatorSkillPoints(ctx, m12aAdmin(), a.PlayerID, "skill-points:1", op()); err != nil {
		t.Fatal(err)
	}
	state, _, err = (i5store.Store{}).ReadTemporalTx(ctx, p, a.PlayerID, "skill_point")
	if err != nil {
		t.Fatal(err)
	}
	if state.StoredAmount != 4 {
		t.Fatalf("a replayed key reset new use: amount = %d", state.StoredAmount)
	}

	missing := bornActor(t, p)
	exec(t, p, `DELETE FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(missing.PlayerID))
	if err = service.ResetOperatorSkillPoints(ctx, m12aAdmin(), missing.PlayerID, "skill-points:2", op()); err != nil {
		t.Fatal(err)
	}
	var rows int
	if err = p.Raw().QueryRow(ctx, `SELECT count(*) FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(missing.PlayerID)).Scan(&rows); err != nil {
		t.Fatal(err)
	}
	if rows != 0 {
		t.Fatalf("missing skill point row was created: %d", rows)
	}
}

func TestI11A_M12ABulkResetOverThreePlayersNative(t *testing.T) {
	p := pool(t)
	players := []identity.PlayerID{bornActor(t, p).PlayerID, bornActor(t, p).PlayerID, bornActor(t, p).PlayerID}
	at := m12aDatabaseNow(t, p)
	day := modes.Day(at)
	for _, player := range players {
		m12aSeedDailyCounts(t, p, int64(player), at, dailyconsume.Counts{dailyconsume.CounterBuyEnergy: {Period: day, Used: 1}})
		m12aUpsertScalar(t, p, int64(player), "occult_ticket", 0, at)
	}

	raw, err := json.Marshal(map[string]any{
		"target":   map[string]any{"player_ids": []int64{int64(players[0]), int64(players[1]), int64(players[2])}},
		"counters": []string{operatorgrant.CounterDailyBuys, operatorgrant.CounterOccultTickets},
	})
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(operatorgrant.CommandResetCounters, operator.Envelope{Principal: "m12a-native", Role: operator.RoleRoot, Scope: "global", Reason: "M12a bulk reset", SemanticKey: "m12a-bulk-1"}, raw)
	if err != nil {
		t.Fatal(err)
	}
	bus := operator.Bus{Runner: tx.Runner{DB: p}, Clock: clock.System{}, Store: operatorstore.Store{}, Handlers: operatorgrant.ResetCommands{Store: operatorstore.Store{}}.Handlers()}
	outcome, err := bus.Execute(ctx, command)
	if err != nil {
		t.Fatal(err)
	}
	if outcome.State != operator.StateApplied {
		t.Fatalf("command state = %s", outcome.State)
	}

	applier := operatorgrant.Applier{
		Runner:        tx.Runner{DB: p},
		Operations:    operation.Factory{Clock: clock.System{}},
		Store:         operatorstore.Store{},
		DailyBuys:     m12aDailyService(p),
		OccultTickets: m12aI5Service(p),
	}
	finished, err := applier.ApplyPending(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if finished != 1 {
		t.Fatalf("finished targets = %d", finished)
	}
	target, err := (operatorstore.Store{}).ReadBulkTx(ctx, p, "m12a-bulk-1")
	if err != nil || target == nil {
		t.Fatalf("bulk target: %v", err)
	}
	if target.State != operatorgrant.StateDone || target.Applied != 3 || target.Refused != 0 {
		t.Fatalf("bulk target = %+v", target)
	}
	service := m12aI5Service(p)
	for _, player := range players {
		if used := m12aDailyUsed(t, p, int64(player), day, dailyconsume.CounterBuyEnergy); used != 0 {
			t.Fatalf("player %d daily buys = %d", player, used)
		}
		tickets, err := service.OccultTicketsTx(ctx, p, player)
		if err != nil {
			t.Fatal(err)
		}
		if tickets.Tickets != 2 {
			t.Fatalf("player %d occult tickets = %d", player, tickets.Tickets)
		}
	}
}
