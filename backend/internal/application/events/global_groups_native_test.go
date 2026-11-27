//go:build postgres

package events_test

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/eventstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	appevents "gxb.local/backend/v2/internal/application/events"
	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/domain/events"
	"gxb.local/backend/v2/internal/foundation/clock"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	e4GlobalActivity        = 1099
	e4GlobalOverlapActivity = 1100
)

type e4GroupOccurrence struct {
	ID            int64
	ServerID      int64
	GlobalGroupID *int64
	StartsAt      time.Time
	EndsAt        *time.Time
	ClaimUntil    *time.Time
}

type e4GroupRecord struct {
	ID       int64
	State    string
	Revision int64
	StartsAt time.Time
	EndsAt   *time.Time
	EndedAt  *time.Time
}

// TestGlobalGroupsLifecycle covers EA-15 items 2-6 on a fresh database: a
// global schedule covers every current server, a server created afterwards
// joins on the maintenance tick with the same window, a server running its own
// overlapping event is skipped and reported, a group end_now ends every
// occurrence and stops later joins, and a stale group revision changes
// nothing.
func TestGlobalGroupsLifecycle(t *testing.T) {
	pool := e4Pool(t)
	at := time.Date(2026, 11, 23, 12, 0, 0, 0, time.UTC)
	bus := e4BusAt(t, pool, e4Clock{at: at})
	t.Cleanup(func() { e4ResetGlobal(t, pool) })
	e4ResetGlobal(t, pool)
	e4DeployDisplay(t, bus, e4GlobalActivity)

	for _, server := range []int64{491, 492, 493} {
		e4SeedServer(t, pool, server)
	}
	currentServers := e4ServerIDs(t, pool)

	start := at.Add(-time.Hour)
	payload := map[string]any{"activity_id": int64(e4GlobalActivity), "scope": "global", "duration": "1d", "start": start.Format(time.RFC3339)}
	outcome := e4Applied(t, bus, e4Command(t, "events.schedule", nil, "global", payload))
	var result struct {
		Occurrences []appevents.OccurrenceView `json:"occurrences"`
		Group       *struct {
			GroupID  int64  `json:"group_id"`
			State    string `json:"state"`
			Revision int64  `json:"revision"`
		} `json:"group"`
	}
	if err := json.Unmarshal(outcome.Result, &result); err != nil {
		t.Fatal(err)
	}
	if result.Group == nil || result.Group.GroupID <= 0 || result.Group.State != events.GroupRunning {
		t.Fatalf("group result %s", outcome.Result)
	}
	if len(result.Occurrences) != len(currentServers) {
		t.Fatalf("scheduled occurrences = %d, want %d: %s", len(result.Occurrences), len(currentServers), outcome.Result)
	}
	groupID := result.Group.GroupID
	group := e4ReadGroup(t, pool, groupID)
	if group.State != events.GroupRunning || !group.StartsAt.Equal(start) {
		t.Fatalf("stored group %+v", group)
	}
	assertGroupWindow(t, pool, groupID, start, start.Add(24*time.Hour), len(currentServers))

	// A server created after the schedule joins on the next maintenance run,
	// with the group's own window; a second run changes nothing.
	e4SeedServer(t, pool, 494)
	jobs := e4Jobs(t, pool, e4Clock{at: at})
	if err := jobs.ReconcileGlobalGroups(context.Background()); err != nil {
		t.Fatal(err)
	}
	assertGroupWindow(t, pool, groupID, start, start.Add(24*time.Hour), len(currentServers)+1)
	if err := jobs.ReconcileGlobalGroups(context.Background()); err != nil {
		t.Fatal(err)
	}
	assertGroupWindow(t, pool, groupID, start, start.Add(24*time.Hour), len(currentServers)+1)

	// A server running its own overlapping occurrence of the same activity is
	// skipped and never overwritten.
	e4SeedServer(t, pool, 495)
	serverOnly := map[string]any{"activity_id": int64(e4GlobalActivity), "scope": "server", "logical_server_ids": []int64{495}, "duration": "1d", "start": start.Format(time.RFC3339)}
	e4Applied(t, bus, e4Command(t, "events.schedule", nil, "global", serverOnly))
	if err := jobs.ReconcileGlobalGroups(context.Background()); err != nil {
		t.Fatal(err)
	}
	assertGroupWindow(t, pool, groupID, start, start.Add(24*time.Hour), len(currentServers)+1)
	for _, occurrence := range e4ReadGroupOccurrences(t, pool, groupID) {
		if occurrence.ServerID == 495 {
			t.Fatalf("a blocked server joined the group")
		}
	}

	// The global list reports N current servers, K joined and the blocked
	// server's name and reason (EA-15 item 5).
	service := appevents.Service{Runner: tx.Runner{DB: pool}, Operations: operation.Factory{Clock: clock.System{}}, Store: eventstore.Store{}, Clock: clock.System{}, Servers: i4store.ServerDirectoryReader{}}
	page, err := service.List(context.Background(), appevents.OccurrenceFilter{Limit: 50})
	if err != nil {
		t.Fatal(err)
	}
	listed := findGroup(page.Groups, groupID)
	if listed == nil {
		t.Fatal("the global list lost the group")
	}
	if listed.ServerCount != len(currentServers)+2 || listed.JoinedCount != len(currentServers)+1 {
		t.Fatalf("coverage %d/%d", listed.JoinedCount, listed.ServerCount)
	}
	blocked := findMissing(listed.MissingServers, 495)
	if blocked == nil || blocked.Reason != "runs its own event" || blocked.Name == "" {
		t.Fatalf("blocked server row %+v", listed.MissingServers)
	}

	// A global schedule whose window overlaps a server's own event refuses the
	// whole schedule and names that server (EA-15 item 3).
	e4DeployDisplay(t, bus, e4GlobalOverlapActivity)
	overlapServerOnly := map[string]any{"activity_id": int64(e4GlobalOverlapActivity), "scope": "server", "logical_server_ids": []int64{495}, "duration": "1d", "start": start.Format(time.RFC3339)}
	e4Applied(t, bus, e4Command(t, "events.schedule", nil, "global", overlapServerOnly))
	overlapGlobal := map[string]any{"activity_id": int64(e4GlobalOverlapActivity), "scope": "global", "duration": "1d", "start": start.Format(time.RFC3339)}
	refused := e4Execute(t, bus, e4Command(t, "events.schedule", nil, "global", overlapGlobal))
	if refused.State != operator.StateRefused || e4RefusalCode(t, refused) != appevents.CodeOverlap {
		t.Fatalf("overlapping global schedule: %s %s", refused.State, refused.Result)
	}
	if count := e4CountGroups(t, pool, e4GlobalOverlapActivity); count != 0 {
		t.Fatalf("a refused global schedule created %d groups", count)
	}

	// A stale group revision is refused and changes nothing.
	before := e4ReadGroup(t, pool, groupID)
	staleRevision := before.Revision + 5
	stale := e4Execute(t, bus, e4Command(t, "events.end_now", &staleRevision, "global", map[string]any{"group_id": groupID}))
	if stale.State != operator.StateRefused || e4RefusalCode(t, stale) != appevents.CodeStale {
		t.Fatalf("stale end_now: %s %s", stale.State, stale.Result)
	}
	after := e4ReadGroup(t, pool, groupID)
	if after.Revision != before.Revision || after.State != before.State || after.EndedAt != nil {
		t.Fatalf("a stale revision changed the group: %+v", after)
	}

	// Group end_now ends every occurrence and a server added afterwards does
	// not join.
	current := after.Revision
	e4Applied(t, bus, e4Command(t, "events.end_now", &current, "global", map[string]any{"group_id": groupID}))
	endedGroup := e4ReadGroup(t, pool, groupID)
	if endedGroup.State != events.GroupEnded || endedGroup.EndedAt == nil || endedGroup.EndsAt == nil {
		t.Fatalf("ended group %+v", endedGroup)
	}
	for _, occurrence := range e4ReadGroupOccurrences(t, pool, groupID) {
		if occurrence.EndsAt == nil || !occurrence.EndsAt.Equal(at) || occurrence.ClaimUntil == nil {
			t.Fatalf("occurrence not ended with a claim window: %+v", occurrence)
		}
	}
	e4SeedServer(t, pool, 496)
	if err := jobs.ReconcileGlobalGroups(context.Background()); err != nil {
		t.Fatal(err)
	}
	for _, occurrence := range e4ReadGroupOccurrences(t, pool, groupID) {
		if occurrence.ServerID == 496 {
			t.Fatal("a server joined an ended group")
		}
	}
}

func assertGroupWindow(t *testing.T, pool *pg.Pool, groupID int64, start, end time.Time, want int) {
	t.Helper()
	occurrences := e4ReadGroupOccurrences(t, pool, groupID)
	if len(occurrences) != want {
		t.Fatalf("group occurrences = %d, want %d", len(occurrences), want)
	}
	for _, occurrence := range occurrences {
		if occurrence.GlobalGroupID == nil || *occurrence.GlobalGroupID != groupID {
			t.Fatalf("occurrence without the group id: %+v", occurrence)
		}
		if !occurrence.StartsAt.Equal(start) || occurrence.EndsAt == nil || !occurrence.EndsAt.Equal(end) {
			t.Fatalf("occurrence window %+v", occurrence)
		}
	}
}

func findGroup(groups []appevents.GroupView, groupID int64) *appevents.GroupView {
	for index := range groups {
		if groups[index].ID == groupID {
			return &groups[index]
		}
	}
	return nil
}

func findMissing(servers []appevents.MissingServerView, serverID int64) *appevents.MissingServerView {
	for index := range servers {
		if servers[index].ServerID == serverID {
			return &servers[index]
		}
	}
	return nil
}

func e4RefusalCode(t *testing.T, outcome operator.Outcome) string {
	t.Helper()
	var refusal struct {
		Code string `json:"error_code"`
	}
	if err := json.Unmarshal(outcome.Result, &refusal); err != nil {
		t.Fatalf("refusal body %s: %v", outcome.Result, err)
	}
	return refusal.Code
}

func e4SeedServer(t *testing.T, pool *pg.Pool, server int64) {
	t.Helper()
	_, err := pool.Raw().Exec(context.Background(), `INSERT INTO logical_servers(logical_server_id,name,first_opened_at,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at)
		VALUES($1,$2,now(),true,true,true,$3,$4,now())
		ON CONFLICT (logical_server_id) DO UPDATE SET name=EXCLUDED.name`,
		server, fmt.Sprintf("Global %d", server), server*100000+25001, (server+1)*100000-1)
	if err != nil {
		t.Fatalf("seed server %d: %v", server, err)
	}
}

func e4ServerIDs(t *testing.T, pool *pg.Pool) []int64 {
	t.Helper()
	rows, err := pool.Raw().Query(context.Background(), `SELECT logical_server_id FROM logical_servers ORDER BY logical_server_id`)
	if err != nil {
		t.Fatalf("read servers: %v", err)
	}
	defer rows.Close()
	var out []int64
	for rows.Next() {
		var server int64
		if err := rows.Scan(&server); err != nil {
			t.Fatal(err)
		}
		out = append(out, server)
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

func e4ReadGroup(t *testing.T, pool *pg.Pool, groupID int64) e4GroupRecord {
	t.Helper()
	var group e4GroupRecord
	if err := pool.Raw().QueryRow(context.Background(), `SELECT id,state,revision,starts_at,ends_at,ended_at FROM event_global_groups WHERE id=$1`, groupID).
		Scan(&group.ID, &group.State, &group.Revision, &group.StartsAt, &group.EndsAt, &group.EndedAt); err != nil {
		t.Fatalf("read group %d: %v", groupID, err)
	}
	return group
}

func e4ReadGroupOccurrences(t *testing.T, pool *pg.Pool, groupID int64) []e4GroupOccurrence {
	t.Helper()
	rows, err := pool.Raw().Query(context.Background(), `SELECT id,logical_server_id,global_group_id,starts_at,ends_at,claim_until
		FROM event_occurrences WHERE global_group_id=$1 ORDER BY logical_server_id,id`, groupID)
	if err != nil {
		t.Fatalf("read group occurrences: %v", err)
	}
	defer rows.Close()
	var out []e4GroupOccurrence
	for rows.Next() {
		var occurrence e4GroupOccurrence
		if err := rows.Scan(&occurrence.ID, &occurrence.ServerID, &occurrence.GlobalGroupID, &occurrence.StartsAt, &occurrence.EndsAt, &occurrence.ClaimUntil); err != nil {
			t.Fatal(err)
		}
		out = append(out, occurrence)
	}
	if err := rows.Err(); err != nil {
		t.Fatal(err)
	}
	return out
}

func e4CountGroups(t *testing.T, pool *pg.Pool, activityID int64) int {
	t.Helper()
	var count int
	if err := pool.Raw().QueryRow(context.Background(), `SELECT COUNT(*) FROM event_global_groups WHERE activity_id=$1`, activityID).Scan(&count); err != nil {
		t.Fatalf("count groups: %v", err)
	}
	return count
}

func e4ResetGlobal(t *testing.T, pool *pg.Pool) {
	t.Helper()
	ctx := context.Background()
	for _, activityID := range []int64{e4GlobalActivity, e4GlobalOverlapActivity} {
		for _, statement := range []string{
			`DELETE FROM player_event_claims WHERE occurrence_id IN (SELECT id FROM event_occurrences WHERE activity_id=$1)`,
			`DELETE FROM event_occurrences WHERE activity_id=$1`,
			`DELETE FROM event_global_groups WHERE activity_id=$1`,
			`DELETE FROM event_definitions WHERE activity_id=$1`,
		} {
			if _, err := pool.Raw().Exec(ctx, statement, activityID); err != nil {
				t.Fatalf("reset global activity %d: %v", activityID, err)
			}
		}
	}
	for _, server := range []int64{491, 492, 493, 494, 495, 496} {
		for _, statement := range []string{
			`DELETE FROM event_cycle_settings WHERE logical_server_id=$1`,
			`DELETE FROM event_occurrences WHERE logical_server_id=$1`,
			`DELETE FROM logical_servers WHERE logical_server_id=$1`,
		} {
			if _, err := pool.Raw().Exec(ctx, statement, server); err != nil {
				t.Fatalf("reset global server %d: %v", server, err)
			}
		}
	}
}
