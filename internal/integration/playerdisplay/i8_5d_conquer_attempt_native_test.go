//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"sync"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
)

type conquerAttemptRow struct {
	id, generation, profile, state, kind, verdict string
}

// conquerAttempts lists the player's Conquer Combat attempts, oldest first.
func conquerAttempts(t *testing.T, p *pg.Pool, a identity.ActorContext) []conquerAttemptRow {
	t.Helper()
	rows, err := p.Raw().Query(ctx, `SELECT a.attempt_id::text,a.generation_ref,a.trust_profile_id,a.state,COALESCE(a.terminal_kind,''),COALESCE(v.verdict,'')
		FROM combat_attempts a LEFT JOIN combat_attestations v USING(attempt_id)
		WHERE a.domain_kind='CONQUER_SCHOOL' AND a.authority_scope=$1 AND a.domain_locator=$2 ORDER BY a.started_at,a.state_version`,
		fmt.Sprintf("server:%d", a.LogicalServerID), fmt.Sprintf("player:%d", a.PlayerID))
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	out := []conquerAttemptRow{}
	for rows.Next() {
		var r conquerAttemptRow
		if err = rows.Scan(&r.id, &r.generation, &r.profile, &r.state, &r.kind, &r.verdict); err != nil {
			t.Fatal(err)
		}
		out = append(out, r)
	}
	return out
}

func (r conquerAttemptRow) is(state, kind, verdict string) bool {
	return r.state == state && r.kind == kind && r.verdict == verdict
}

func TestI8_5DConquerStartBindsCombatAttemptNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := conquerMode(t, pool)
	a, girls := conquerPlayer(t, pool, rankingServer(t, pool))
	if _, err := s.Info(ctx, a, op()); err != nil {
		t.Fatal(err)
	}

	// D5-01: START freezes team A, the pet slot and the formation (no enemy) into a client-summary attempt.
	first := op()
	info, err := s.Start(ctx, a, girls[:2], 0, first)
	attempts := conquerAttempts(t, pool, a)
	if err != nil || info.Mode.LeftTimes != 9 || len(attempts) != 1 || !attempts[0].is("STAGED", "", "") ||
		attempts[0].profile != "CLIENT_SUMMARY_ATTESTED_V1" || attempts[0].generation != d.ModeContractID+"/1/10001" {
		t.Fatalf("bound START %+v %+v %v", info, attempts, err)
	}
	var snapshot struct {
		Battle struct {
			CampaignType int64             `json:"campaign_type"`
			TeamA        []json.RawMessage `json:"team_a"`
			WavesB       []json.RawMessage `json:"waves_b"`
			Formation    []int64           `json:"formation"`
		} `json:"battle"`
	}
	var raw []byte
	if err = pool.Raw().QueryRow(ctx, `SELECT s.canonical FROM combat_snapshots s JOIN combat_attempts a USING(snapshot_hash) WHERE a.attempt_id::text=$1`, attempts[0].id).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	if err = json.Unmarshal(raw, &snapshot); err != nil || snapshot.Battle.CampaignType != 25 || len(snapshot.Battle.TeamA) != 2 || len(snapshot.Battle.WavesB) != 0 || !slices.Equal(snapshot.Battle.Formation, girls[:2]) {
		t.Fatalf("frozen snapshot %s %v", raw, err)
	}

	// D5-02: a retransmitted START replays the attempt without a second chance.
	if info, err = s.Start(ctx, a, girls[:2], 0, first); err != nil || info.Mode.LeftTimes != 9 || len(conquerAttempts(t, pool, a)) != 1 {
		t.Fatalf("START replay %+v %v", info, err)
	}

	// D5-03: a new START supersedes the open attempt and spends one more chance.
	if info, err = s.Start(ctx, a, girls[:3], 0, op()); err != nil || info.Mode.LeftTimes != 8 {
		t.Fatalf("superseding START %+v %v", info, err)
	}
	attempts = conquerAttempts(t, pool, a)
	if len(attempts) != 2 || !attempts[0].is("TERMINAL", "SUPERSEDED", "") || !attempts[1].is("STAGED", "", "") {
		t.Fatalf("supersede %+v", attempts)
	}

	// D5-04: a summary off the frozen START is REJECTED: the close commits, the RESULT is refused, the mode is unchanged.
	rejected := op()
	result := d.Result{CampaignID: 10001, TeamID: 1, Win: true, Formation: girls[:2], Alive: 2}
	for range 2 {
		if _, err = s.Result(ctx, a, result, json.RawMessage(`{"fighter":{}}`), rejected); !errors.Is(err, d.ErrRefused) {
			t.Fatal("changed formation accepted", err)
		}
	}
	attempts = conquerAttempts(t, pool, a)
	if !attempts[1].is("TERMINAL", "REJECTED", "REJECTED") ||
		scalar(t, pool, `SELECT count(*) FROM gxb_operation_receipts WHERE domain='conquer-school' AND owner_key=$1`, fmt.Sprint(int64(a.PlayerID))) != 1 {
		t.Fatalf("rejected close %+v", attempts)
	}
	if info, err = s.Info(ctx, a, op()); err != nil || info.Mode.LeftTimes != 8 || len(info.Mode.BeatenTeams) != 0 || info.Mode.Buff != 0 {
		t.Fatalf("mode after rejection %+v %v", info, err)
	}

	// D5-05: a RESULT with no open attempt drains: refused, nothing written.
	if _, err = s.Result(ctx, a, d.Result{CampaignID: 10001, TeamID: 1, Formation: girls[:3]}, json.RawMessage(`{}`), op()); !errors.Is(err, d.ErrRefused) || len(conquerAttempts(t, pool, a)) != 2 {
		t.Fatal("drained RESULT", err)
	}

	// D5-06: an accepted summary closes as CONQUER_RESULT and settles the loss.
	if _, err = s.Start(ctx, a, girls[:3], 0, op()); err != nil {
		t.Fatal(err)
	}
	lost, err := s.Result(ctx, a, d.Result{CampaignID: 10001, TeamID: 1, Formation: girls[:3], Alive: 0, Damage: 10}, json.RawMessage(`{}`), op())
	attempts = conquerAttempts(t, pool, a)
	if err != nil || lost.Info.Mode.Buff != 1 || lost.Info.Mode.LeftTimes != 7 || !attempts[2].is("TERMINAL", "CONQUER_RESULT", "ACCEPTED") {
		t.Fatalf("accepted RESULT %+v %+v %v", lost, attempts, err)
	}

	// D5-07: RESET withdraws the open attempt; its RESULT then drains. A RESET with none open succeeds.
	if _, err = s.Start(ctx, a, girls[:1], 0, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = s.Reset(ctx, a, op()); err != nil {
		t.Fatal("reset", err)
	}
	attempts = conquerAttempts(t, pool, a)
	if !attempts[3].is("TERMINAL", "CONQUER_RESET", "") {
		t.Fatalf("reset close %+v", attempts)
	}
	if _, err = s.Result(ctx, a, d.Result{CampaignID: 10001, TeamID: 1, Win: true, Formation: girls[:1], Alive: 1}, json.RawMessage(`{}`), op()); !errors.Is(err, d.ErrRefused) {
		t.Fatal("RESULT after reset", err)
	}
	if _, err = s.Reset(ctx, a, op()); err != nil {
		t.Fatal("reset without an open attempt", err)
	}
}

func TestI8_5DConquerConcurrentStartsNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := conquerMode(t, pool)
	a, girls := conquerPlayer(t, pool, rankingServer(t, pool))
	if _, err := s.Info(ctx, a, op()); err != nil {
		t.Fatal(err)
	}

	// D5-08: racing STARTs never double-spend or leave two attempts open: each
	// commits whole (one chance, one attempt) or loses the I7C-5E decision-time
	// guard (ErrConflict, or a lock timeout under -race) and writes nothing.
	var wait sync.WaitGroup
	errs := make([]error, 4)
	for i := range errs {
		wait.Add(1)
		go func() {
			defer wait.Done()
			_, errs[i] = s.Start(ctx, a, girls[i:i+1], 0, op())
		}()
	}
	wait.Wait()
	started := int64(0)
	for _, err := range errs {
		if err == nil {
			started++
		}
	}
	attempts := conquerAttempts(t, pool, a)
	open := 0
	superseded := int64(0)
	for _, r := range attempts {
		if r.is("STAGED", "", "") {
			open++
		}
		if r.is("TERMINAL", "SUPERSEDED", "") {
			superseded++
		}
	}
	info, err := s.Info(ctx, a, op())
	if err != nil || started == 0 || int64(len(attempts)) != started || open != 1 || superseded != started-1 || info.Mode.LeftTimes != 10-started {
		t.Fatalf("racing STARTs %+v %+v %v", attempts, info, err)
	}
}
