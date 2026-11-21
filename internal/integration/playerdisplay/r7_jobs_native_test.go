//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/occultstore"
	"gxb.local/backend/v2/internal/adapters/postgres/presencestore"
	"gxb.local/backend/v2/internal/adapters/postgres/rankingstore"
	appgen "gxb.local/backend/v2/internal/application/generation"
	app "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type r7FixedTime struct{ at time.Time }

func (f r7FixedTime) Now(context.Context) (time.Time, error) { return f.at.UTC(), nil }

func r7JobService(p *pg.Pool) app.Service {
	metrics := countingMetrics(p, nil)
	metrics.Force = rawBirthStats(p)
	metrics.Awakenings = characterstore.RawAwakeningStore{}
	service := rankingService(p, p)
	service.Metrics = metrics
	service.TopForce = metrics
	service.BloodAwaken = metrics
	service.Comfort = dormstore.Store{Queryer: p}
	service.Occult = occultstore.Store{}
	service.Presence = nil
	service.Login = nil
	return service
}

func r7ServerPlayers(t *testing.T, p *pg.Pool, server identity.LogicalServerID) []identity.PlayerID {
	t.Helper()
	roots, e := (i4store.PlayerRootLocker{}).ListPlayerRootsTx(ctx, p)
	if e != nil {
		t.Fatal(e)
	}
	players := []identity.PlayerID{}
	for _, root := range roots {
		if root.LogicalServerID == server {
			players = append(players, root.PlayerID)
		}
	}
	return players
}

func r7Summon(t *testing.T, p *pg.Pool, a identity.ActorContext, rev string, table int64) {
	t.Helper()
	definition := collectionResources(t, p, a, rev, table)
	if _, e := ownerSummoner(p).SummonNormal(ctx, a, definition.Template.TableID, definition.Template.FragmentItemID, definition.FragmentCount, op()); e != nil {
		t.Fatal(table, e)
	}
}

func r7Population(t *testing.T, p *pg.Pool, server identity.LogicalServerID) (identity.ActorContext, string) {
	t.Helper()
	first, rev, _ := combatOwner(t, p, server)
	second, _, _ := combatOwner(t, p, server)
	third := rankingActor(t, p, server, true)
	r7Summon(t, p, first, rev, 10001002)
	r7Summon(t, p, first, rev, 10001003)
	exec(t, p, `INSERT INTO player_hero_skin_entitlements(player_id,partner_id,model_id,expires_at)SELECT player_id,partner_id,40001001,NULL FROM player_heroes WHERE player_id=$1 ORDER BY partner_id LIMIT 1`, int64(second.PlayerID))
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,50001409,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(second.PlayerID))
	comfortRooms(t, p, third.PlayerID, rev, map[int64]int64{1: 12})
	viewer, _, _ := combatOwner(t, p, server)
	return viewer, rev
}

func TestR7RefreshActiveScoresPicksVisiblyActivePlayers(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	player, _, _ := combatOwner(t, p, server)
	service := r7JobService(p)
	service.Presence = presencestore.Store{}
	t0 := time.Now().UTC().Add(time.Minute).Truncate(time.Microsecond)
	service.Timed.Binder.Time = r7FixedTime{at: t0}
	if e := service.BackfillScoresServer(ctx, op(), server, r7ServerPlayers(t, p, server)); e != nil {
		t.Fatal(e)
	}
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if e != nil {
		t.Fatal(e)
	}
	if e = (presencestore.Store{}).EnsureAndLockRootTx(ctx, tr, player.PlayerID, t0.Add(time.Minute)); e != nil {
		t.Fatal(e)
	}
	if _, e = (presencestore.Store{}).AdvanceLastSeenTx(ctx, tr, player.PlayerID, t0.Add(time.Minute), t0.Add(time.Minute)); e != nil {
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
	t1 := t0.Add(2 * time.Minute)
	service.Timed.Binder.Time = r7FixedTime{at: t1}
	if e = service.RefreshActiveScoresServer(ctx, op(), server, r7ServerPlayers(t, p, server)); e != nil {
		t.Fatal(e)
	}
	row, ok, e := (rankingstore.Store{}).ReadScoreRowTx(ctx, p, d.GirlsPolicy, player.PlayerID)
	if e != nil || !ok || !row.UpdatedAt.Equal(t1) || row.Revision != rev {
		t.Fatal(row, ok, e)
	}
}

func TestR7SettlementAtBoundaryWithoutReadersAndReplay(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	_, _ = r7Population(t, p, server)
	settleAt := time.Now().UTC().Add(time.Minute).Truncate(time.Microsecond)
	service := r7JobService(p)
	var e error
	service.Timed.Binder.Time = r7FixedTime{at: settleAt}
	if e = service.BackfillScoresServer(ctx, op(), server, r7ServerPlayers(t, p, server)); e != nil {
		t.Fatal(e)
	}
	service.Timed.Binder.Time = r7FixedTime{at: settleAt.Add(time.Minute)}
	before := rankingCount(t, p, server, "ranking_girls_awards")
	if e = service.SettleBoardBoundariesServer(ctx, op(), server); e != nil {
		t.Fatal(e)
	}
	after := rankingCount(t, p, server, "ranking_girls_awards")
	if after <= before {
		t.Fatal("no title settled at the boundary", before, after)
	}
	var winner, title int64
	if e = p.QueryRow(ctx, `SELECT player_id,title_id FROM ranking_girls_awards WHERE logical_server_id=$1 AND policy_id=$2 AND rank=1`, int64(server), d.GirlsPolicy).Scan(&winner, &title); e != nil || title != 100059 {
		t.Fatal("boundary winner", winner, title, e)
	}
	if e = service.SettleBoardBoundariesServer(ctx, op(), server); e != nil {
		t.Fatal(e)
	}
	if again := rankingCount(t, p, server, "ranking_girls_awards"); again != after {
		t.Fatal("rerun awarded twice", after, again)
	}
	_ = rev
}

// A backwards clock step across a weekly boundary settles the week of the
// stored root observation, not the earlier decision week. Before the fix the
// snapshot was bound to the stored week while the caller re-read the decision
// week, committing phantom snapshots and reporting ErrConflict forever.
func TestR7SettlementAfterClockRollbackUsesTheStoredWeek(t *testing.T) {
	p := pool(t)
	_ = installed(t, p)
	server := rankingServer(t, p)
	settledAt := time.Date(2026, 11, 18, 12, 0, 0, 0, time.UTC)
	service := r7JobService(p)
	service.Timed.Binder.Time = r7FixedTime{at: settledAt.Add(time.Minute)}
	if e := service.SettleBoardServer(ctx, op(), d.GirlsBoard, server); e != nil {
		t.Fatal(e)
	}
	service.Timed.Binder.Time = r7FixedTime{at: settledAt.Add(-7 * 24 * time.Hour)}
	if e := service.SettleBoardServer(ctx, op(), d.GirlsBoard, server); e != nil {
		t.Fatalf("settlement after a backwards clock step across the week: %v", e)
	}
}

func r7BulkPlayers(t *testing.T, p *pg.Pool, server identity.LogicalServerID, count int64) {
	t.Helper()
	tr, e := p.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if e != nil {
		t.Fatal(e)
	}
	defer tr.Rollback(ctx)
	for i := int64(1); i <= count; i++ {
		account, e := ids.NewUUID()
		if e != nil {
			t.Fatal(e)
		}
		pid := int64(server)*100000 + i
		for _, row := range []struct {
			sql  string
			args []any
		}{
			{`INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, []any{account.String(), account.String()}},
			{`INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,$3,clock_timestamp(),'r7-scale-native')`, []any{pid, account.String(), int64(server)}},
			{`INSERT INTO player_directory_profiles(player_id,name,lev,avatar_id,avatar_frame_id,vip,conquer_lev,state_version,created_at,updated_at)VALUES($1,'Scale',100,110001001,0,0,0,1,clock_timestamp(),clock_timestamp())`, []any{pid}},
			{`INSERT INTO player_profiles(player_id,display_name,avatar_id,avatar_frame_id,player_type,state_version,created_at,updated_at)VALUES($1,'Scale',110001001,0,0,1,clock_timestamp(),clock_timestamp())`, []any{pid}},
			{`INSERT INTO player_progression(player_id,level,exp,state_version,updated_at)VALUES($1,100,0,1,clock_timestamp())`, []any{pid}},
			{`INSERT INTO player_economy_owners(player_id,state_version,created_at)VALUES($1,1,clock_timestamp())`, []any{pid}},
			{`INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,1,0,1,clock_timestamp(),clock_timestamp())`, []any{pid}},
		} {
			if _, e = tr.Exec(ctx, row.sql, row.args...); e != nil {
				t.Fatal(e)
			}
		}
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}

func r7P95(samples []time.Duration) time.Duration {
	sort.Slice(samples, func(i, j int) bool { return samples[i] < samples[j] })
	index := (len(samples)*95 + 99) / 100
	if index < 1 {
		index = 1
	}
	return samples[index-1]
}

func r7Temperature() string {
	paths, _ := filepath.Glob("/sys/class/hwmon/*/temp*_input")
	values := []string{}
	for _, path := range paths {
		raw, e := os.ReadFile(path)
		if e != nil {
			continue
		}
		values = append(values, fmt.Sprintf("%s=%s", path, strings.TrimSpace(string(raw))))
	}
	if len(values) == 0 {
		return "temperature unavailable"
	}
	return "temperatures " + strings.Join(values, " ")
}

func TestR7MID301StoredReadScales(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	r7BulkPlayers(t, p, server, 999)
	viewer, _, _ := combatOwner(t, p, server)
	var raw string
	if e := p.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(table_id ORDER BY table_id),'[]'::jsonb)::text FROM (SELECT DISTINCT ON (h.origin_table_id) h.table_id FROM gxb_content_hero_templates h JOIN gxb_content_hero_normal_star s ON s.revision_id=h.revision_id AND s.target_star=h.initial_star WHERE h.revision_id=$1 AND h.kind='NORMAL' AND h.origin_table_id=h.table_id AND h.table_id NOT IN (SELECT table_id FROM player_heroes WHERE player_id=$2) ORDER BY h.origin_table_id,h.table_id LIMIT 50)t`, rev, int64(viewer.PlayerID)).Scan(&raw); e != nil {
		t.Fatal(e)
	}
	tables := []int64{}
	if e := json.Unmarshal([]byte(raw), &tables); e != nil || len(tables) != 50 {
		t.Fatal(len(tables), e)
	}
	for _, table := range tables {
		r7Summon(t, p, viewer, rev, table)
	}
	service := r7JobService(p)
	base := time.Now().UTC().Add(time.Minute).Truncate(time.Microsecond)
	service.Timed.Binder.Time = r7FixedTime{at: base}
	if e := service.BackfillScoresServer(ctx, op(), server, r7ServerPlayers(t, p, server)); e != nil {
		t.Fatal(e)
	}
	// The viewer owns fifty real heroes; the other 999 players keep empty
	// canonical rosters, which the stored read never scans.
	service.Timed.Binder.Time = r7FixedTime{at: base.Add(time.Minute)}
	pinned := op()
	var e error
	pinned.Policies, e = policy.NewSet(policy.Ref{Name: "content", Version: rev}, policy.Ref{Name: "roster-metrics", Version: d.RosterMetricSourcePolicy}, policy.Ref{Name: "ranking", Version: d.GirlsPolicy})
	if e != nil {
		t.Fatal(e)
	}
	refreshSamples := []time.Duration{}
	for i := 0; i < 20; i++ {
		started := time.Now()
		_, _, e := service.Timed.Run(ctx, pinned, app.Profile(), tx.Options{Isolation: tx.Serializable}, tx.RetryPolicy{MaxAttempts: 1}, nil, func(c context.Context, sc appgen.TimedScope) error {
			return service.RefreshScoresTx(c, app.ScoreScope{Scope: tx.Scope{Tx: sc.Tx, Operation: sc.Operation.Operation(), Attempt: sc.Attempt, Options: sc.Options}, Server: server}, d.GirlsBoard, []identity.PlayerID{viewer.PlayerID}, rev, sc.Operation.DecisionAt())
		})
		if e != nil {
			t.Fatal(e)
		}
		refreshSamples = append(refreshSamples, time.Since(started))
	}
	readSamples := []time.Duration{}
	for i := 0; i < 20; i++ {
		started := time.Now()
		if _, e := service.ReadBoard(ctx, d.GirlsBoard, viewer, op()); e != nil {
			t.Fatal(e)
		}
		readSamples = append(readSamples, time.Since(started))
	}
	t.Logf("R7_SCALE players=1000 viewer_heroes=50 viewer_refresh_p95=%s mid301_read_p95=%s %s", r7P95(refreshSamples), r7P95(readSamples), r7Temperature())
}

type r7MovingTime struct {
	mu sync.Mutex
	at time.Time
}

func (m *r7MovingTime) Now(context.Context) (time.Time, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.at.UTC(), nil
}

func (m *r7MovingTime) set(at time.Time) {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.at = at
}

// r7RacingPresence runs race once, just before the job's first batch, and then
// reports every player as seen at the given instant.
type r7RacingPresence struct {
	once *sync.Once
	race func()
	seen time.Time
}

func (r r7RacingPresence) LastSeenAtTx(_ context.Context, _ tx.Queryer, players []identity.PlayerID) (map[identity.PlayerID]time.Time, error) {
	r.once.Do(r.race)
	out := map[identity.PlayerID]time.Time{}
	for _, player := range players {
		out[player] = r.seen
	}
	return out, nil
}

// A-030: a viewer stores a newer row after the job began. The batch must use its
// own decision time and finish instead of failing the run.
func TestR7RefreshSurvivesAViewerRowStoredAfterTheJobBegan(t *testing.T) {
	p := pool(t)
	_ = installed(t, p)
	server := rankingServer(t, p)
	viewer, _, _ := combatOwner(t, p, server)
	players := r7ServerPlayers(t, p, server)
	start := time.Now().UTC().Add(time.Minute).Truncate(time.Microsecond)

	seed := r7JobService(p)
	seed.Timed.Binder.Time = r7FixedTime{at: start.Add(-time.Minute)}
	if e := seed.BackfillScoresServer(ctx, op(), server, players); e != nil {
		t.Fatal(e)
	}

	clock := &r7MovingTime{at: start}
	job := r7JobService(p)
	job.Timed.Binder.Time = clock
	job.Presence = r7RacingPresence{once: &sync.Once{}, seen: start.Add(45 * time.Second), race: func() {
		reader := r7JobService(p)
		reader.Timed.Binder.Time = r7FixedTime{at: start.Add(30 * time.Second)}
		if e := reader.BackfillScoresServer(ctx, op(), server, []identity.PlayerID{viewer.PlayerID}); e != nil {
			t.Error("viewer refresh", e)
		}
		clock.set(start.Add(time.Minute))
	}}
	if e := job.RefreshActiveScoresServer(ctx, op(), server, players); e != nil {
		t.Fatal(e)
	}
	row, ok, e := (rankingstore.Store{}).ReadScoreRowTx(ctx, p, d.GirlsPolicy, viewer.PlayerID)
	if e != nil || !ok || !row.UpdatedAt.Equal(start.Add(time.Minute)) {
		t.Fatal("viewer row was not refreshed at the batch's own time", row, ok, e)
	}
}
