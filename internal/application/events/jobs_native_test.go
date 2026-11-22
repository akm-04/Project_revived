//go:build postgres

package events_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/eventstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/operatorstore"
	appevents "gxb.local/backend/v2/internal/application/events"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/operator"
	eventscontent "gxb.local/backend/v2/internal/content/events"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/economy"
	domainevents "gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/mail"
	otadomain "gxb.local/backend/v2/internal/domain/otarelease"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const e4Server = 4

var e4Anchor = time.Date(2025, 12, 31, 21, 0, 0, 0, time.UTC)

func e4Pool(t *testing.T) *pg.Pool {
	t.Helper()
	dsn := os.Getenv("GXB_I11A_E4_DSN")
	if dsn == "" {
		t.Skip("GXB_I11A_E4_DSN required (ops/testing/fresh_db.sh e4)")
	}
	pool, err := pg.Open(context.Background(), dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return pool
}

type e4Coverage struct{}

func (e4Coverage) Covers(context.Context, otadomain.CoversRequest) (otadomain.CoversResult, error) {
	return otadomain.CoversResult{Status: otadomain.CoversCovered}, nil
}

type e4Gifts struct{}

func (e4Gifts) GiftTx(context.Context, tx.Queryer, int64) ([]domainevents.RewardLine, bool, error) {
	return nil, false, nil
}

type e4Catalogue struct{}

func (e4Catalogue) CheckRewardsTx(context.Context, tx.Queryer, []domainevents.RewardLine) error {
	return nil
}

func e4Bus(t *testing.T, pool *pg.Pool) operator.Bus {
	t.Helper()
	return e4BusAt(t, pool, clock.System{})
}

func e4BusAt(t *testing.T, pool *pg.Pool, operatorClock clock.Clock) operator.Bus {
	t.Helper()
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	commands := appevents.Commands{Store: eventstore.Store{}, Coverage: e4Coverage{}, Gifts: e4Gifts{}, Catalogue: e4Catalogue{}, Hooks: hooks}
	return operator.Bus{Runner: tx.Runner{DB: pool}, Clock: operatorClock, Store: operatorstore.Store{}, Handlers: commands.Handlers()}
}

func e4Command(t *testing.T, name string, revision *int64, scope string, payload any) operator.Command {
	t.Helper()
	key, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatal(err)
	}
	command, err := operator.NewCommand(name, operator.Envelope{Principal: "root", Role: operator.RoleRoot, Scope: scope, Reason: "i11a e4 native", SemanticKey: key.String(), ExpectedRevision: revision}, raw)
	if err != nil {
		t.Fatal(err)
	}
	return command
}

func e4Execute(t *testing.T, bus operator.Bus, command operator.Command) operator.Outcome {
	t.Helper()
	outcome, err := bus.Execute(context.Background(), command)
	if err != nil {
		t.Fatalf("%s: %v", command.ModuleCommand, err)
	}
	return outcome
}

func e4Applied(t *testing.T, bus operator.Bus, command operator.Command) operator.Outcome {
	t.Helper()
	outcome := e4Execute(t, bus, command)
	if outcome.State != operator.StateApplied {
		t.Fatalf("%s: %s %s", command.ModuleCommand, outcome.State, outcome.Result)
	}
	return outcome
}

func e4Deploy(t *testing.T, bus operator.Bus, definition string) {
	t.Helper()
	e4Applied(t, bus, e4Command(t, "events.definition.deploy", nil, "global", json.RawMessage(definition)))
}

func e4DeployDisplay(t *testing.T, bus operator.Bus, activityID int64) {
	t.Helper()
	e4Deploy(t, bus, fmt.Sprintf(`{"activity_id":%d,"revision":1,"archetype":"DISPLAY","client_requirements":{},"default_days":3}`, activityID))
}

func e4DeployTiered(t *testing.T, bus operator.Bus, activityID int64) {
	t.Helper()
	e4Deploy(t, bus, fmt.Sprintf(`{"activity_id":%d,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[`+
		`{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[{"kind":"item","item_id":50001003,"amount":1}]}]},`+
		`{"id":2,"requirement":{"kind":"player_level","value":20},"choices":[{"lines":[{"kind":"item","item_id":50001003,"amount":2}]}]}]}`, activityID))
}

func e4Schedule(t *testing.T, bus operator.Bus, server, activityID int64, start time.Time, duration string) appevents.OccurrenceView {
	t.Helper()
	payload := map[string]any{"activity_id": activityID, "logical_server_ids": []int64{server}, "duration": duration, "start": start.UTC().Format(time.RFC3339)}
	outcome := e4Applied(t, bus, e4Command(t, "events.schedule", nil, "global", payload))
	var result struct {
		Occurrences []appevents.OccurrenceView `json:"occurrences"`
	}
	if err := json.Unmarshal(outcome.Result, &result); err != nil || len(result.Occurrences) != 1 {
		t.Fatalf("schedule result %s: %v", outcome.Result, err)
	}
	return result.Occurrences[0]
}

type e4Clock struct{ at time.Time }

func (c e4Clock) Now() time.Time { return c.at.UTC() }

func e4Jobs(t *testing.T, pool *pg.Pool, clk clock.Clock) appevents.Jobs {
	t.Helper()
	hooks, err := appevents.NewHookRegistry()
	if err != nil {
		t.Fatal(err)
	}
	cycle, err := domainevents.ParseCycle(eventscontent.DefaultCycle())
	if err != nil {
		t.Fatal(err)
	}
	return appevents.Jobs{
		Runner:       tx.Runner{DB: pool},
		Operations:   operation.Factory{Clock: clk},
		Store:        eventstore.Store{},
		Coverage:     e4Coverage{},
		Hooks:        hooks,
		Clock:        clk,
		DefaultCycle: cycle,
		Servers:      i4store.PlayerRootLocker{},
		Players:      i4store.EventPlayerSource{},
		Mail:         appi5.SettlementMail{Store: i5store.Store{}},
	}
}

func e4ResetServer(t *testing.T, pool *pg.Pool, server int64) {
	t.Helper()
	ctx := context.Background()
	for _, statement := range []string{
		`DELETE FROM player_event_claims WHERE occurrence_id IN (SELECT id FROM event_occurrences WHERE logical_server_id=$1)`,
		`DELETE FROM event_occurrences WHERE logical_server_id=$1`,
		`DELETE FROM event_cycle_settings WHERE logical_server_id=$1`,
	} {
		if _, err := pool.Raw().Exec(ctx, statement, server); err != nil {
			t.Fatalf("reset server %d: %v", server, err)
		}
	}
}

func e4SeedPlayer(t *testing.T, pool *pg.Pool, server, playerID, level int64, uid string) {
	t.Helper()
	ctx := context.Background()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,status,account_uid,created_at)
		VALUES(gen_random_uuid(),'ACTIVE',$1,now()) ON CONFLICT (account_uid) DO NOTHING`, uid); err != nil {
		t.Fatalf("seed account: %v", err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)
		SELECT $1,account_id,$2,now(),'e4-native' FROM accounts WHERE account_uid=$3 ON CONFLICT (player_id) DO NOTHING`, playerID, server, uid); err != nil {
		t.Fatalf("seed player: %v", err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO player_directory_profiles(player_id,name,lev,created_at,updated_at)
		VALUES($1,'',$2,now(),now()) ON CONFLICT (player_id) DO UPDATE SET lev=EXCLUDED.lev,updated_at=now()`, playerID, level); err != nil {
		t.Fatalf("seed profile: %v", err)
	}
}

type e4CycleRow struct {
	ID          int64
	ActivityID  int64
	Revision    int64
	StartsAt    time.Time
	CancelledAt *time.Time
	SettledAt   *time.Time
}

func e4CycleRows(t *testing.T, pool *pg.Pool, server int64) []e4CycleRow {
	t.Helper()
	rows, err := pool.Raw().Query(context.Background(), `SELECT id,activity_id,revision,starts_at,cancelled_at,settled_at
		FROM event_occurrences WHERE logical_server_id=$1 AND source='CYCLE' ORDER BY starts_at,id`, server)
	if err != nil {
		t.Fatalf("read cycle rows: %v", err)
	}
	defer rows.Close()
	var out []e4CycleRow
	for rows.Next() {
		var row e4CycleRow
		if err := rows.Scan(&row.ID, &row.ActivityID, &row.Revision, &row.StartsAt, &row.CancelledAt, &row.SettledAt); err != nil {
			t.Fatal(err)
		}
		out = append(out, row)
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

func e4CycleActivities(rows []e4CycleRow) []int64 {
	out := make([]int64, 0, len(rows))
	for _, row := range rows {
		out = append(out, row.ActivityID)
	}
	return out
}

func e4CycleDefinitions(t *testing.T, bus operator.Bus) {
	t.Helper()
	for _, activityID := range []int64{1008, 1009, 1007, 1010, 1016} {
		e4DeployDisplay(t, bus, activityID)
	}
}

func e4Operation(t *testing.T, jobs appevents.Jobs) operation.Context {
	t.Helper()
	op, err := jobs.Operations.New(policy.Set{})
	if err != nil {
		t.Fatal(err)
	}
	return op
}

func TestCycleMaterialiserAddsTwoSlotsOnce(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400001, 1, "e4-cycle")
	e4CycleDefinitions(t, bus)
	jobs := e4Jobs(t, pool, e4Clock{at: e4Anchor.Add(30*24*time.Hour - time.Hour)})
	ctx := context.Background()

	if err := jobs.MaterialiseCycle(ctx); err != nil {
		t.Fatal(err)
	}
	rows := e4CycleRows(t, pool, e4Server)
	if len(rows) != 2 {
		t.Fatalf("two slots expected, got %+v", rows)
	}
	if got := e4CycleActivities(rows); got[0] != 1008 || got[1] != 1009 {
		t.Fatalf("activities = %v", got)
	}
	if !rows[0].StartsAt.Equal(e4Anchor.Add(30*24*time.Hour)) || !rows[1].StartsAt.Equal(e4Anchor.Add(33*24*time.Hour)) {
		t.Fatalf("starts = %s %s", rows[0].StartsAt, rows[1].StartsAt)
	}
	if err := jobs.MaterialiseCycle(ctx); err != nil {
		t.Fatal(err)
	}
	if again := e4CycleRows(t, pool, e4Server); len(again) != 2 {
		t.Fatalf("a second run must add nothing, got %+v", again)
	}
}

func TestCycleMaterialiserConcurrentRunsAddEachSlotOnce(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400001, 1, "e4-cycle")
	e4CycleDefinitions(t, bus)
	jobs := e4Jobs(t, pool, e4Clock{at: e4Anchor.Add(30*24*time.Hour - time.Hour)})
	ctx := context.Background()

	started := make(chan struct{})
	errs := make([]error, 2)
	var wait sync.WaitGroup
	for index := range errs {
		wait.Add(1)
		go func(slot int) {
			defer wait.Done()
			<-started
			errs[slot] = jobs.MaterialiseServer(ctx, e4Operation(t, jobs), identity.LogicalServerID(e4Server))
		}(index)
	}
	close(started)
	wait.Wait()
	for index, err := range errs {
		if err != nil {
			t.Fatalf("concurrent run %d: %v", index, err)
		}
	}
	if rows := e4CycleRows(t, pool, e4Server); len(rows) != 2 {
		t.Fatalf("each slot must exist exactly once, got %+v", rows)
	}
}

func TestCycleMaterialiserCancelledSlotStaysEmpty(t *testing.T) {
	pool := e4Pool(t)
	clk := e4Clock{at: e4Anchor.Add(30*24*time.Hour - time.Hour)}
	bus := e4BusAt(t, pool, clock.Fixed{T: clk.at})
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400001, 1, "e4-cycle")
	e4CycleDefinitions(t, bus)
	jobs := e4Jobs(t, pool, clk)
	ctx := context.Background()
	if err := jobs.MaterialiseCycle(ctx); err != nil {
		t.Fatal(err)
	}
	rows := e4CycleRows(t, pool, e4Server)
	if len(rows) != 2 {
		t.Fatalf("rows = %+v", rows)
	}
	e4Applied(t, bus, e4Command(t, "events.cancel", &rows[0].Revision, "global", map[string]any{"occurrence_id": rows[0].ID}))
	if err := jobs.MaterialiseCycle(ctx); err != nil {
		t.Fatal(err)
	}
	after := e4CycleRows(t, pool, e4Server)
	if len(after) != 2 || after[0].CancelledAt == nil || after[1].CancelledAt != nil {
		t.Fatalf("a cancelled slot must not be recreated: %+v", after)
	}
}

func TestCycleMaterialiserGateFailureDoesNotShift(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400001, 1, "e4-cycle")
	e4DeployDisplay(t, bus, 1008)
	anchor := time.Date(2026, 12, 31, 21, 0, 0, 0, time.UTC)
	body := map[string]any{"revision": 1, "anchor": anchor.Format(time.RFC3339), "entries": []map[string]any{
		{"activity_id": 4242, "duration": "3d"},
		{"activity_id": 1008, "duration": "3d"},
	}}
	e4Applied(t, bus, e4Command(t, "events.cycle.set", int64Ptr(0), "global", map[string]any{"logical_server_ids": []int64{e4Server}, "cycle": body}))

	jobs := e4Jobs(t, pool, e4Clock{at: anchor.Add(30*24*time.Hour - time.Hour)})
	if err := jobs.MaterialiseServer(context.Background(), e4Operation(t, jobs), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	rows := e4CycleRows(t, pool, e4Server)
	if len(rows) != 1 || rows[0].ActivityID != 1008 {
		t.Fatalf("only the deployed slot may run, got %+v", rows)
	}
	if !rows[0].StartsAt.Equal(anchor.Add(33 * 24 * time.Hour)) {
		t.Fatalf("the next slot must not shift: %s", rows[0].StartsAt)
	}
}

func TestCycleModeOffAddsNothing(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400001, 1, "e4-cycle")
	e4CycleDefinitions(t, bus)
	jobs := e4Jobs(t, pool, e4Clock{at: e4Anchor.Add(30*24*time.Hour - time.Hour)})
	ctx := context.Background()
	e4Applied(t, bus, e4Command(t, "events.cycle.mode", nil, "global", map[string]any{"logical_server_ids": []int64{e4Server}, "mode": "OFF"}))
	if err := jobs.MaterialiseServer(ctx, e4Operation(t, jobs), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	if rows := e4CycleRows(t, pool, e4Server); len(rows) != 0 {
		t.Fatalf("OFF must add nothing, got %+v", rows)
	}
	e4Applied(t, bus, e4Command(t, "events.cycle.mode", nil, "global", map[string]any{"logical_server_ids": []int64{e4Server}, "mode": "AUTO"}))
	if err := jobs.MaterialiseServer(ctx, e4Operation(t, jobs), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	if rows := e4CycleRows(t, pool, e4Server); len(rows) != 2 {
		t.Fatalf("AUTO must materialise, got %+v", rows)
	}
}

func TestCycleSetChangesLaterSlotsOnly(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400001, 1, "e4-cycle")
	e4CycleDefinitions(t, bus)
	jobs := e4Jobs(t, pool, e4Clock{at: e4Anchor.Add(30*24*time.Hour - time.Hour)})
	ctx := context.Background()
	if err := jobs.MaterialiseServer(ctx, e4Operation(t, jobs), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	before := e4CycleRows(t, pool, e4Server)
	if len(before) != 2 {
		t.Fatalf("first run = %+v", before)
	}
	body := map[string]any{"revision": 1, "anchor": e4Anchor.Format(time.RFC3339), "entries": []map[string]any{
		{"activity_id": 1010, "duration": "3d"},
		{"activity_id": 1016, "duration": "3d"},
	}}
	e4Applied(t, bus, e4Command(t, "events.cycle.set", int64Ptr(0), "global", map[string]any{"logical_server_ids": []int64{e4Server}, "cycle": body}))
	opposite := map[string]any{"revision": 2, "anchor": e4Anchor.Format(time.RFC3339), "entries": []map[string]any{{"activity_id": 1007, "duration": "3d"}}}
	stale := e4Execute(t, bus, e4Command(t, "events.cycle.set", int64Ptr(0), "global", map[string]any{"logical_server_ids": []int64{e4Server}, "cycle": opposite}))
	if stale.State != operator.StateRefused {
		t.Fatalf("a stale expected revision must be refused: %s %s", stale.State, stale.Result)
	}
	if err := jobs.MaterialiseServer(ctx, e4Operation(t, jobs), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	after := e4CycleRows(t, pool, e4Server)
	if len(after) != 2 {
		t.Fatalf("a set must not double an occupied window, got %+v", after)
	}
	later := e4Jobs(t, pool, e4Clock{at: e4Anchor.Add(36*24*time.Hour - time.Hour)})
	if err := later.MaterialiseServer(ctx, e4Operation(t, later), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	after = e4CycleRows(t, pool, e4Server)
	if len(after) != 4 {
		t.Fatalf("later windows must use the new body, got %+v", after)
	}
	want := map[int64]time.Time{
		1008: e4Anchor.Add(30 * 24 * time.Hour),
		1009: e4Anchor.Add(33 * 24 * time.Hour),
		1010: e4Anchor.Add(36 * 24 * time.Hour),
		1016: e4Anchor.Add(39 * 24 * time.Hour),
	}
	for _, row := range after {
		start, ok := want[row.ActivityID]
		if !ok || !row.StartsAt.Equal(start) || row.CancelledAt != nil {
			t.Fatalf("unexpected slot %+v, want %v", row, want)
		}
		delete(want, row.ActivityID)
	}
	if len(want) != 0 {
		t.Fatalf("missing slots %v", want)
	}
}

func TestCycleResetChangesLaterSlotsOnly(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400001, 1, "e4-cycle")
	e4CycleDefinitions(t, bus)
	jobs := e4Jobs(t, pool, e4Clock{at: e4Anchor.Add(30*24*time.Hour - time.Hour)})
	ctx := context.Background()
	if err := jobs.MaterialiseServer(ctx, e4Operation(t, jobs), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	if before := e4CycleRows(t, pool, e4Server); len(before) != 2 {
		t.Fatalf("first run = %+v", before)
	}
	body := map[string]any{"revision": 1, "anchor": e4Anchor.Format(time.RFC3339), "entries": []map[string]any{
		{"activity_id": 1010, "duration": "3d"},
		{"activity_id": 1016, "duration": "3d"},
	}}
	e4Applied(t, bus, e4Command(t, "events.cycle.set", int64Ptr(0), "global", map[string]any{"logical_server_ids": []int64{e4Server}, "cycle": body}))
	reset := e4Applied(t, bus, e4Command(t, "events.cycle.reset", int64Ptr(1), "global", map[string]any{"logical_server_ids": []int64{e4Server}}))
	var result struct {
		Settings []appevents.CycleSettingView `json:"settings"`
	}
	if err := json.Unmarshal(reset.Result, &result); err != nil || len(result.Settings) != 1 || result.Settings[0].CycleRevision != 0 {
		t.Fatalf("reset must return to the shipped body: %s %v", reset.Result, err)
	}
	if err := jobs.MaterialiseServer(ctx, e4Operation(t, jobs), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	if after := e4CycleRows(t, pool, e4Server); len(after) != 2 {
		t.Fatalf("a reset must not double an occupied window, got %+v", after)
	}
	later := e4Jobs(t, pool, e4Clock{at: e4Anchor.Add(36*24*time.Hour - time.Hour)})
	if err := later.MaterialiseServer(ctx, e4Operation(t, later), identity.LogicalServerID(e4Server)); err != nil {
		t.Fatal(err)
	}
	after := e4CycleRows(t, pool, e4Server)
	if len(after) != 4 {
		t.Fatalf("later windows must return to the shipped body, got %+v", after)
	}
	want := map[int64]time.Time{
		1008: e4Anchor.Add(30 * 24 * time.Hour),
		1009: e4Anchor.Add(33 * 24 * time.Hour),
		1007: e4Anchor.Add(36 * 24 * time.Hour),
		1010: e4Anchor.Add(39 * 24 * time.Hour),
	}
	for _, row := range after {
		start, ok := want[row.ActivityID]
		if !ok || !row.StartsAt.Equal(start) || row.CancelledAt != nil {
			t.Fatalf("unexpected slot %+v, want %v", row, want)
		}
		delete(want, row.ActivityID)
	}
	if len(want) != 0 {
		t.Fatalf("missing slots %v", want)
	}
}

type e4CountingMailer struct {
	next   appevents.Mailer
	failAt int
	calls  int
}

func (m *e4CountingMailer) DeliverTx(ctx context.Context, transaction tx.Tx, request appi5.SettlementMailRequest) (mail.Record, bool, error) {
	m.calls++
	if m.failAt > 0 && m.calls == m.failAt {
		return mail.Record{}, false, errors.New("injected mail restart")
	}
	return m.next.DeliverTx(ctx, transaction, request)
}

func e4SettlementJobs(t *testing.T, pool *pg.Pool, at time.Time, page int) appevents.Jobs {
	t.Helper()
	jobs := e4Jobs(t, pool, e4Clock{at: at})
	jobs.PlayerPage = page
	jobs.OccurrenceBatch = 10
	return jobs
}

func e4MailRows(t *testing.T, pool *pg.Pool, players []int64) map[string]int {
	t.Helper()
	rows, err := pool.Raw().Query(context.Background(), `SELECT recipient_player_id,source_key FROM mail_records
		WHERE source_kind=$1 AND recipient_player_id=ANY($2) ORDER BY recipient_player_id,source_key`, appevents.SettlementMailSourceKind, players)
	if err != nil {
		t.Fatalf("read mail rows: %v", err)
	}
	defer rows.Close()
	out := map[string]int{}
	for rows.Next() {
		var player int64
		var key string
		if err := rows.Scan(&player, &key); err != nil {
			t.Fatal(err)
		}
		out[fmt.Sprintf("%d|%s", player, key)]++
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

func e4ClaimCount(t *testing.T, pool *pg.Pool, occurrenceID int64) int {
	t.Helper()
	var count int
	if err := pool.Raw().QueryRow(context.Background(), `SELECT COUNT(*) FROM player_event_claims WHERE occurrence_id=$1`, occurrenceID).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func e4PlayerClaimCount(t *testing.T, pool *pg.Pool, occurrenceID, playerID int64) int {
	t.Helper()
	var count int
	if err := pool.Raw().QueryRow(context.Background(), `SELECT COUNT(*) FROM player_event_claims WHERE occurrence_id=$1 AND player_id=$2`, occurrenceID, playerID).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func e4MailCountForOccurrence(t *testing.T, pool *pg.Pool, occurrenceID int64) int {
	t.Helper()
	var count int
	if err := pool.Raw().QueryRow(context.Background(), `SELECT COUNT(*) FROM mail_records WHERE source_kind=$1 AND source_key LIKE $2`,
		appevents.SettlementMailSourceKind, fmt.Sprintf("%d:%%", occurrenceID)).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func e4SettledAt(t *testing.T, pool *pg.Pool, occurrenceID int64) *time.Time {
	t.Helper()
	var settled *time.Time
	if err := pool.Raw().QueryRow(context.Background(), `SELECT settled_at FROM event_occurrences WHERE id=$1`, occurrenceID).Scan(&settled); err != nil {
		t.Fatal(err)
	}
	return settled
}

func TestSettlementMailsUnclaimedTiersOnceAcrossRestart(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400002, 10, "e4-settle-a")
	e4SeedPlayer(t, pool, e4Server, 400003, 25, "e4-settle-b")
	e4SeedPlayer(t, pool, e4Server, 400004, 5, "e4-settle-c")
	e4DeployTiered(t, bus, 2081)
	now := time.Now().UTC()
	occurrence := e4Schedule(t, bus, e4Server, 2081, now.Add(-72*time.Hour), "1d")
	players := []int64{400002, 400003, 400004}
	ctx := context.Background()

	failing := e4SettlementJobs(t, pool, now, 1)
	failing.Mail = &e4CountingMailer{next: failing.Mail, failAt: 2}
	if err := failing.SettleDue(ctx); err == nil {
		t.Fatal("the injected mail restart must surface")
	}
	if settled := e4SettledAt(t, pool, occurrence.ID); settled != nil {
		t.Fatalf("a failed batch must not archive the occurrence: %s", settled)
	}
	if claims := e4ClaimCount(t, pool, occurrence.ID); claims != 1 {
		t.Fatalf("the committed page must hold one claim, got %d", claims)
	}
	if mails := e4MailRows(t, pool, players); len(mails) != 1 {
		t.Fatalf("the committed page must hold one mail, got %v", mails)
	}

	restarted := e4SettlementJobs(t, pool, now, 1)
	if err := restarted.SettleDue(ctx); err != nil {
		t.Fatal(err)
	}
	mails := e4MailRows(t, pool, players)
	if len(mails) != 3 {
		t.Fatalf("each eligible unclaimed tier must be mailed once, got %v", mails)
	}
	for _, key := range []string{
		fmt.Sprintf("400002|%d:400002:1", occurrence.ID),
		fmt.Sprintf("400003|%d:400003:1", occurrence.ID),
		fmt.Sprintf("400003|%d:400003:2", occurrence.ID),
	} {
		if mails[key] != 1 {
			t.Fatalf("mail key %s = %d, want exactly one", key, mails[key])
		}
	}
	if claims := e4ClaimCount(t, pool, occurrence.ID); claims != 3 {
		t.Fatalf("claims = %d, want 3", claims)
	}
	if settled := e4SettledAt(t, pool, occurrence.ID); settled == nil {
		t.Fatal("the occurrence must be archived after settlement")
	}
	if err := restarted.SettleDue(ctx); err != nil {
		t.Fatal(err)
	}
	if again := e4MailRows(t, pool, players); len(again) != 3 {
		t.Fatalf("a second run must mail nothing, got %v", again)
	}
	if claims := e4ClaimCount(t, pool, occurrence.ID); claims != 3 {
		t.Fatalf("a second run must write no claim, got %d", claims)
	}
}

func TestPermanentOccurrenceNeverSettles(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400002, 10, "e4-settle-a")
	e4DeployTiered(t, bus, 2082)
	e4DeployDisplay(t, bus, 2083)
	now := time.Now().UTC()
	permanent := e4Schedule(t, bus, e4Server, 2082, now.Add(-time.Hour), "permanent")
	timed := e4Schedule(t, bus, e4Server, 2083, now.Add(-72*time.Hour), "1d")
	jobs := e4SettlementJobs(t, pool, now, 10)
	if err := jobs.SettleDue(context.Background()); err != nil {
		t.Fatal(err)
	}
	if settled := e4SettledAt(t, pool, permanent.ID); settled != nil {
		t.Fatalf("a permanent occurrence must never settle: %s", settled)
	}
	if settled := e4SettledAt(t, pool, timed.ID); settled == nil {
		t.Fatal("the scan must still settle a timed occurrence")
	}
}

func TestSettlementSkipsCancelledOccurrence(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400010, 10, "e4-settle-cancelled")
	e4DeployTiered(t, bus, 2086)
	now := time.Now().UTC()
	occurrence := e4Schedule(t, bus, e4Server, 2086, now.Add(time.Hour), "1d")
	e4Applied(t, bus, e4Command(t, "events.cancel", &occurrence.Revision, "global", map[string]any{"occurrence_id": occurrence.ID}))
	if _, err := pool.Raw().Exec(context.Background(), `UPDATE event_occurrences
		SET starts_at=$2::timestamptz- interval '72 hours', ends_at=$2::timestamptz- interval '48 hours', claim_until=$2::timestamptz- interval '24 hours'
		WHERE id=$1 AND cancelled_at IS NOT NULL`, occurrence.ID, now); err != nil {
		t.Fatalf("make the cancelled occurrence due: %v", err)
	}
	jobs := e4SettlementJobs(t, pool, now, 10)
	if err := jobs.SettleDue(context.Background()); err != nil {
		t.Fatal(err)
	}
	if settled := e4SettledAt(t, pool, occurrence.ID); settled != nil {
		t.Fatalf("a cancelled occurrence must never settle: %s", settled)
	}
	if mails := e4MailCountForOccurrence(t, pool, occurrence.ID); mails != 0 {
		t.Fatalf("a cancelled occurrence must mail nothing, got %d", mails)
	}
	if claims := e4ClaimCount(t, pool, occurrence.ID); claims != 0 {
		t.Fatalf("a cancelled occurrence must write no claim, got %d", claims)
	}
}

func TestSettlementMailsOnlyTheOccurrenceServer(t *testing.T) {
	const secondServer = 3
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4ResetServer(t, pool, secondServer)
	e4SeedPlayer(t, pool, e4Server, 400011, 10, "e4-settle-here")
	e4SeedPlayer(t, pool, secondServer, 300012, 10, "e4-settle-elsewhere")
	e4DeployTiered(t, bus, 2087)
	now := time.Now().UTC()
	occurrence := e4Schedule(t, bus, e4Server, 2087, now.Add(-72*time.Hour), "1d")
	jobs := e4SettlementJobs(t, pool, now, 10)
	if err := jobs.SettleDue(context.Background()); err != nil {
		t.Fatal(err)
	}
	mails := e4MailRows(t, pool, []int64{400011, 300012})
	if mails[fmt.Sprintf("400011|%d:400011:1", occurrence.ID)] != 1 {
		t.Fatalf("the occurrence server's player must be mailed once, got %v", mails)
	}
	if mails[fmt.Sprintf("300012|%d:300012:1", occurrence.ID)] != 0 {
		t.Fatalf("another server's player must not be mailed, got %v", mails)
	}
	if claims := e4PlayerClaimCount(t, pool, occurrence.ID, 400011); claims != 1 {
		t.Fatalf("the occurrence server's player must hold one claim, got %d", claims)
	}
	if claims := e4PlayerClaimCount(t, pool, occurrence.ID, 300012); claims != 0 {
		t.Fatalf("another server's player must hold no claim, got %d", claims)
	}
}

func TestSettlementSkipsPlayerWithoutDirectoryRow(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400013, 1, "e4-settle-with-directory")
	e4SeedPlayer(t, pool, e4Server, 400014, 1, "e4-settle-without-directory")
	if _, err := pool.Raw().Exec(context.Background(), `DELETE FROM player_directory_profiles WHERE player_id=$1`, int64(400014)); err != nil {
		t.Fatalf("drop the directory row: %v", err)
	}
	e4Deploy(t, bus, `{"activity_id":2088,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[`+
		`{"id":1,"requirement":{"kind":"player_level","value":0},"choices":[{"lines":[{"kind":"item","item_id":50001003,"amount":1}]}]}]}`)
	now := time.Now().UTC()
	occurrence := e4Schedule(t, bus, e4Server, 2088, now.Add(-72*time.Hour), "1d")
	jobs := e4SettlementJobs(t, pool, now, 10)
	if err := jobs.SettleDue(context.Background()); err != nil {
		t.Fatal(err)
	}
	mails := e4MailRows(t, pool, []int64{400013, 400014})
	if mails[fmt.Sprintf("400013|%d:400013:1", occurrence.ID)] != 1 {
		t.Fatalf("a player with a directory row must be mailed, got %v", mails)
	}
	if mails[fmt.Sprintf("400014|%d:400014:1", occurrence.ID)] != 0 {
		t.Fatalf("a player without a directory row must not be mailed, got %v", mails)
	}
	if claims := e4PlayerClaimCount(t, pool, occurrence.ID, 400013); claims != 1 {
		t.Fatalf("a player with a directory row must hold one claim, got %d", claims)
	}
	if claims := e4PlayerClaimCount(t, pool, occurrence.ID, 400014); claims != 0 {
		t.Fatalf("a player without a directory row must hold no claim, got %d", claims)
	}
}

func int64Ptr(value int64) *int64 { return &value }

type e4SettlementContent struct{ revision string }

func (content e4SettlementContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	return content.revision, nil
}

type e4HeroContent struct{ originTableID int64 }

func (content e4HeroContent) HeroNormalSummonTx(context.Context, tx.Queryer, string, int64) (character.HeroNormalSummonPolicy, error) {
	return character.HeroNormalSummonPolicy{Template: character.HeroAcquisitionTemplate{OriginTableID: content.originTableID}}, nil
}

type e4OwnedHeroOwner struct{}

func (e4OwnedHeroOwner) LockStoryRosterTx(context.Context, tx.Tx, identity.PlayerID) error {
	return nil
}

func (e4OwnedHeroOwner) OwnsOriginTx(context.Context, tx.Tx, identity.PlayerID, int64) (bool, error) {
	return true, nil
}

func (e4OwnedHeroOwner) AwardStoryPartnerTx(context.Context, tx.Tx, identity.PlayerID, int64, string, operation.Context) (character.Hero, *character.CollectionAdmissionProof, error) {
	return character.Hero{}, nil, errors.New("an owned hero must convert to its stone")
}

type e4HeroStoneFragments struct{}

func (e4HeroStoneFragments) HeroFragmentsTx(context.Context, tx.Queryer, string, int64) ([2]int64, error) {
	return [2]int64{50001004, 30}, nil
}

type e4RefusingGrants struct{}

func (e4RefusingGrants) SettleGrantTx(context.Context, tx.Tx, identity.ActorContext, grant.Plan, operation.Context, appi5.GrantTxOptions) (appi5.GrantResult, error) {
	return appi5.GrantResult{}, economy.ErrUnknownResource
}

// TestSettlementRecordsAPermanentGrantRefusalAndStillSettles covers E4d: a
// settled item row that no longer exists in the catalogue is a permanent owner
// refusal, so the tier is recorded refused and the occurrence still archives.
func TestSettlementRecordsAPermanentGrantRefusalAndStillSettles(t *testing.T) {
	pool := e4Pool(t)
	bus := e4Bus(t, pool)
	e4ResetServer(t, pool, e4Server)
	e4SeedPlayer(t, pool, e4Server, 400050, 10, "e4-settle-refused")
	e4Deploy(t, bus, `{"activity_id":2091,"revision":1,"archetype":"TIERED_CLAIM","client_requirements":{},"default_days":-1,"tiers":[`+
		`{"id":1,"requirement":{"kind":"player_level","value":10},"choices":[{"lines":[`+
		`{"kind":"hero","item_id":10001034,"amount":1},{"kind":"item","item_id":50001003,"amount":1}]}]}]}`)
	now := time.Now().UTC()
	occurrence := e4Schedule(t, bus, e4Server, 2091, now.Add(-72*time.Hour), "1d")
	jobs := e4SettlementJobs(t, pool, now, 10)
	jobs.Content = e4SettlementContent{revision: strings.Repeat("a", 64)}
	jobs.ClaimGrant = appevents.ChoiceGrant{
		HeroContent: e4HeroContent{originTableID: 10001034},
		Heroes:      e4OwnedHeroOwner{},
		Fragments:   e4HeroStoneFragments{},
		Grants:      e4RefusingGrants{},
		HeroWire:    func(character.Hero) (map[string]any, error) { return map[string]any{}, nil },
	}
	ctx := context.Background()
	if err := jobs.SettleDue(ctx); err != nil {
		t.Fatalf("a permanent refusal must not wedge settlement: %v", err)
	}
	if settled := e4SettledAt(t, pool, occurrence.ID); settled == nil {
		t.Fatal("the occurrence must settle after recording the refused tier")
	}
	var receipt string
	if err := pool.Raw().QueryRow(ctx, `SELECT grant_receipt FROM player_event_claims WHERE player_id=$1 AND occurrence_id=$2 AND tier=1`,
		int64(400050), occurrence.ID).Scan(&receipt); err != nil {
		t.Fatalf("read the refused claim: %v", err)
	}
	if receipt != "refused" {
		t.Fatalf("grant_receipt = %q, want refused", receipt)
	}
}
