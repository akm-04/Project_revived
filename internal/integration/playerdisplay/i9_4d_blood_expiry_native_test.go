//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
)

type bloodExpiryClock struct {
	mu sync.RWMutex
	at time.Time
}

func (c *bloodExpiryClock) Now(context.Context) (time.Time, error) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	return c.at, nil
}

func (c *bloodExpiryClock) Set(at time.Time) {
	c.mu.Lock()
	c.at = at
	c.mu.Unlock()
}

type bloodAttemptRow struct {
	id           string
	deadline     time.Time
	state        string
	terminalKind string
	receipt      string
}

func bloodAttemptRows(t *testing.T, p *pg.Pool, player identity.PlayerID) []bloodAttemptRow {
	t.Helper()
	rows, e := p.Raw().Query(ctx, `SELECT attempt_id::text,result_deadline,state,COALESCE(terminal_kind,''),COALESCE(semantic_receipt_id,'') FROM combat_attempts WHERE domain_kind='AWAKENING_BLOOD' AND domain_locator=$1 ORDER BY started_at`, fmt.Sprintf("player:%d", player))
	if e != nil {
		t.Fatal(e)
	}
	defer rows.Close()
	var out []bloodAttemptRow
	for rows.Next() {
		var row bloodAttemptRow
		if e := rows.Scan(&row.id, &row.deadline, &row.state, &row.terminalKind, &row.receipt); e != nil {
			t.Fatal(e)
		}
		out = append(out, row)
	}
	if e := rows.Err(); e != nil {
		t.Fatal(e)
	}
	return out
}

// TestI9_4DBloodExpiredAttemptNative proves an equivalent START replays the
// stored attempt only before its result deadline; at the deadline it retires
// the attempt and starts a successor the later RESULT can win.
func TestI9_4DBloodExpiredAttemptNative(t *testing.T) {
	p := pool(t)
	f := newBloodNativeFixture(t, p)
	base := time.Now().UTC().Add(time.Minute).Truncate(time.Second)
	clock := &bloodExpiryClock{at: base}
	mode := f.mode(p, clock)
	if _, e := mode.Start(ctx, f.actor, 2001002, op()); e != nil {
		t.Fatalf("START at T: %v", e)
	}
	rows := bloodAttemptRows(t, p, f.actor.PlayerID)
	if len(rows) != 1 || rows[0].state != "STAGED" {
		t.Fatalf("first START rows %+v", rows)
	}
	first := rows[0]
	if want := base.Add(3600 * time.Second); !first.deadline.Equal(want) {
		t.Fatalf("first deadline %v, want %v", first.deadline, want)
	}
	clock.Set(base.Add(3599 * time.Second))
	if _, e := mode.Start(ctx, f.actor, 2001002, op()); e != nil {
		t.Fatalf("START at T+3599: %v", e)
	}
	rows = bloodAttemptRows(t, p, f.actor.PlayerID)
	if len(rows) != 1 || rows[0].id != first.id || rows[0].state != "STAGED" {
		t.Fatalf("pre-deadline replay rows %+v", rows)
	}
	clock.Set(base.Add(3600 * time.Second))
	if _, e := mode.Start(ctx, f.actor, 2001002, op()); e != nil {
		t.Fatalf("START at T+3600: %v", e)
	}
	rows = bloodAttemptRows(t, p, f.actor.PlayerID)
	if len(rows) != 2 {
		t.Fatalf("expiry produced rows %+v", rows)
	}
	if rows[0].id != first.id || rows[0].state != "TERMINAL" || rows[0].terminalKind != "AWAKENING_BLOOD_EXPIRED" || rows[0].receipt != "blood-expired:"+first.id {
		t.Fatalf("expired attempt row %+v", rows[0])
	}
	successor := rows[1]
	if successor.state != "STAGED" || !successor.deadline.After(first.deadline) {
		t.Fatalf("successor row %+v", successor)
	}
	body, e := mode.Result(ctx, f.actor, 2001002, 20, op())
	if e != nil || body["twice_awake_mission_"] == nil {
		t.Fatalf("winning RESULT %v %v", body, e)
	}
	rows = bloodAttemptRows(t, p, f.actor.PlayerID)
	if len(rows) != 2 || rows[1].state != "TERMINAL" || rows[1].terminalKind != "AWAKENING_BLOOD_RESULT" {
		t.Fatalf("settled successor rows %+v", rows)
	}
}

// TestI9_4DBloodExpiredConcurrentStartNative races two STARTs at the expiry
// boundary; one retires the attempt and inserts the single successor.
func TestI9_4DBloodExpiredConcurrentStartNative(t *testing.T) {
	p := pool(t)
	f := newBloodNativeFixture(t, p)
	base := time.Now().UTC().Add(time.Minute).Truncate(time.Second)
	clock := &bloodExpiryClock{at: base}
	mode := f.mode(p, clock)
	if _, e := mode.Start(ctx, f.actor, 2001002, op()); e != nil {
		t.Fatalf("START at T: %v", e)
	}
	clock.Set(base.Add(3600 * time.Second))
	operations := []operation.Context{op(), op()}
	errs := make([]error, len(operations))
	start := make(chan struct{})
	var wait sync.WaitGroup
	wait.Add(len(operations))
	for index := range operations {
		go func(index int) {
			defer wait.Done()
			<-start
			_, errs[index] = mode.Start(ctx, f.actor, 2001002, operations[index])
		}(index)
	}
	close(start)
	wait.Wait()
	for index, e := range errs {
		if e != nil {
			t.Fatalf("concurrent START %d: %v", index, e)
		}
	}
	rows := bloodAttemptRows(t, p, f.actor.PlayerID)
	if len(rows) != 2 || rows[0].state != "TERMINAL" || rows[0].terminalKind != "AWAKENING_BLOOD_EXPIRED" || rows[1].state != "STAGED" {
		t.Fatalf("concurrent expiry rows %+v", rows)
	}
}
