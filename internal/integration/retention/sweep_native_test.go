//go:build postgres && river

package retention_test

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	"gxb.local/backend/v2/internal/adapters/river/retentionworker"
)

// R8-4d end-to-end: run the production sweep over a database the existing mode
// natives populated, with a clock far enough ahead that every terminal attempt
// is old, and prove every record row and every report it references survives.
func TestRetentionSweepKeepsReferencedModeReports(t *testing.T) {
	dsn := os.Getenv("GXB_R8_4C_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_4C_DSN with a database populated by the mode natives is required")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Minute)
	defer cancel()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-4d-sweep-native"})
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	references := []struct {
		table string
		query string
	}{
		{"arena_matches", `SELECT attempt_id::text FROM arena_matches WHERE attempt_id IS NOT NULL`},
		{"one_on_one_rounds", `SELECT attempt_id::text FROM one_on_one_rounds WHERE attempt_id IS NOT NULL`},
		{"league_matches", `SELECT attempt_id::text FROM league_matches`},
		{"top_floor_fights", `SELECT attempt_id::text FROM top_floor_fights`},
		{"top_floor_records", `SELECT attempt_id::text FROM top_floor_records`},
		{"top_floor_task_fights", `SELECT attempt_id::text FROM top_floor_task_fights`},
		{"top_floor_task_records", `SELECT attempt_id::text FROM top_floor_task_records`},
		{"conquer_school_reports", `SELECT attempt_id FROM conquer_school_reports`},
		{"illusion_attempts", `SELECT attempt_id FROM illusion_attempts`},
		{"worldboss_attempts", `SELECT attempt_id FROM worldboss_attempts`},
		{"adventure_single_attempts", `SELECT attempt_id FROM adventure_single_attempts`},
	}
	referenced := map[string]struct{}{}
	rowCounts := map[string]int64{}
	for _, reference := range references {
		var count int64
		if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM `+reference.table).Scan(&count); err != nil {
			t.Fatal(err)
		}
		rowCounts[reference.table] = count
		rows, err := pool.Raw().Query(ctx, reference.query)
		if err != nil {
			t.Fatal(err)
		}
		for rows.Next() {
			var id string
			if err = rows.Scan(&id); err != nil {
				rows.Close()
				t.Fatal(err)
			}
			referenced[id] = struct{}{}
		}
		rows.Close()
	}
	if len(referenced) == 0 {
		t.Fatal("the database has no mode record referencing a combat attempt; run the mode natives first")
	}
	attemptIDs := make([]string, 0, len(referenced))
	for id := range referenced {
		attemptIDs = append(attemptIDs, id)
	}
	var present int64
	if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE attempt_id::text = ANY($1)`, attemptIDs).Scan(&present); err != nil {
		t.Fatal(err)
	}
	if present != int64(len(attemptIDs)) {
		t.Fatalf("referenced attempts=%d present in combat_attempts=%d before the sweep", len(attemptIDs), present)
	}

	probe := insertUnreferencedTerminalAttempt(t, ctx, pool)
	policies := retentionstore.Policies{RetentionDays: 1, CacheRetentionDays: 1, RunBudget: 5 * time.Minute, ProfileMediaHistoryDays: 1}
	clock := func() time.Time { return time.Now().Add(24 * time.Hour) }
	logs := make([]string, 0, 8)
	sweeper := retentionworker.Sweeper{Begin: pool.Begin, Rules: retentionworker.NewRules(policies), Budget: policies.RunBudget, Now: clock,
		Logf: func(format string, arguments ...any) { logs = append(logs, fmt.Sprintf(format, arguments...)) }}
	sweeper.Run(ctx)
	joined := strings.Join(logs, "\n")
	for _, rule := range []string{"receipts", "combat-chain", "combat-blobs", "ranking-snapshots", "hero-recommend-snapshots", "media-history"} {
		if !strings.Contains(joined, rule) {
			t.Fatalf("rule %s did not run; logs=%q", rule, joined)
		}
	}

	var probeRows int64
	if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE attempt_id=$1`, probe).Scan(&probeRows); err != nil {
		t.Fatal(err)
	}
	if probeRows != 0 {
		t.Fatal("an unreferenced terminal attempt survived the sweep; the test proves nothing")
	}
	for _, id := range attemptIDs {
		var count int64
		if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM combat_attempts WHERE attempt_id=$1`, id).Scan(&count); err != nil {
			t.Fatal(err)
		}
		if count != 1 {
			t.Fatalf("referenced attempt %s was deleted", id)
		}
		var missingResolutions, missingSnapshots int64
		if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM combat_resolutions r WHERE r.attempt_id=$1
AND NOT EXISTS (SELECT 1 FROM combat_report_blobs b WHERE b.report_sha256=r.report_sha256)`, id).Scan(&missingResolutions); err != nil {
			t.Fatal(err)
		}
		if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM combat_attempts a WHERE a.attempt_id=$1 AND a.snapshot_hash IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM combat_snapshots s WHERE s.snapshot_hash=a.snapshot_hash)`, id).Scan(&missingSnapshots); err != nil {
			t.Fatal(err)
		}
		if missingResolutions != 0 || missingSnapshots != 0 {
			t.Fatalf("attempt %s lost %d reports or %d snapshots", id, missingResolutions, missingSnapshots)
		}
	}
	for table, before := range rowCounts {
		var after int64
		if err = pool.Raw().QueryRow(ctx, `SELECT count(*) FROM `+table).Scan(&after); err != nil {
			t.Fatal(err)
		}
		if after != before {
			t.Fatalf("%s rows changed from %d to %d", table, before, after)
		}
	}
}

// insertUnreferencedTerminalAttempt seeds one terminal attempt no record
// references, so the test proves the sweep really deletes while keeping the
// referenced mode attempts.
func insertUnreferencedTerminalAttempt(t *testing.T, ctx context.Context, pool *pg.Pool) string {
	t.Helper()
	var revision string
	if err := pool.Raw().QueryRow(ctx, `SELECT revision_id FROM gxb_content_activation WHERE slot='content'`).Scan(&revision); err != nil {
		t.Fatalf("content-deployed database required: %v", err)
	}
	var player int64
	if err := pool.Raw().QueryRow(ctx, `SELECT player_id FROM players ORDER BY player_id LIMIT 1`).Scan(&player); err != nil {
		t.Fatalf("populated database required: %v", err)
	}
	var attempt, first, second, locator string
	if err := pool.Raw().QueryRow(ctx, `SELECT gen_random_uuid()::text,
md5(gen_random_uuid()::text)||md5(gen_random_uuid()::text),
md5(gen_random_uuid()::text)||md5(gen_random_uuid()::text),
'r8-4d-probe-'||gen_random_uuid()::text`).Scan(&attempt, &first, &second, &locator); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)VALUES('R8_4D','r8-4d',$1)`, locator); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_snapshots(snapshot_hash,content_revision,rules_corpus_id,canonical)VALUES($1,$2,$3,decode('0000','hex'))`, first, revision, second); err != nil {
		t.Fatal(err)
	}
	startedAt := time.Now().Add(-2 * time.Hour).UTC()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,entropy_key_version,resolver_status,state,started_at,result_deadline,state_version,terminal_kind,terminal_at,semantic_receipt_id)
VALUES($1,'R8_4D','r8-4d',$2,$3,gen_random_uuid(),'r8-4d-probe',$4,'SERVER_REPORT_AUTHORITATIVE_V1',1,$5,$6,'HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1','r8-4d-key','PERMANENT_FAILED','TERMINAL',$7::timestamptz,($7::timestamptz + interval '1 hour'),1,'WIN',$7::timestamptz,$8)`,
		attempt, locator, player, first, first, second, startedAt, "r8-4d-probe-receipt-"+attempt); err != nil {
		t.Fatal(err)
	}
	return attempt
}
