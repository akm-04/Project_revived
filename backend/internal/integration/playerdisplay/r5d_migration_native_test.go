//go:build postgres

package playerdisplay_test

import (
	"fmt"
	"os"
	osexec "os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	app "gxb.local/backend/v2/internal/application/worldboss"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/worldboss"
)

const r5dRetireMigrationName = "00169_r5d_retire_mode_attempts.sql"
const r5dRenameBackScriptName = "r5d_rename_back.sh"

func r5dMigrationDatabase(t *testing.T, suffix string) (string, *pg.Pool) {
	t.Helper()
	base := os.Getenv("GXB_I7B6A_DSN")
	if base == "" {
		t.Fatal("native DSN required")
	}
	dsn, cleanup := disposableNativeDatabase(t, base, suffix)
	t.Cleanup(cleanup)
	runTool(t, "goose", "-dir", migrationsRoot(t), "postgres", dsn, "up-to", "00168")
	p := openNativePool(t, dsn)
	t.Cleanup(p.Close)
	return dsn, p
}

// r5dRolledBackDatabase is a head database put through the R5D rollback
// script, so fixtures written by the current binary meet the pre-00169 table
// names and every later column.
func r5dRolledBackDatabase(t *testing.T, suffix string) (string, *pg.Pool) {
	t.Helper()
	base := os.Getenv("GXB_I7B6A_DSN")
	if base == "" {
		t.Fatal("native DSN required")
	}
	dsn, cleanup := disposableNativeDatabase(t, base, suffix)
	t.Cleanup(cleanup)
	runTool(t, "goose", "-dir", migrationsRoot(t), "postgres", dsn, "up")
	script := filepath.Join(filepath.Dir(migrationsRoot(t)), "tools", r5dRenameBackScriptName)
	if output, err := osexec.Command("bash", script, dsn).CombinedOutput(); err != nil {
		t.Fatalf("rename-back script failed: %v\n%s", err, output)
	}
	p := openNativePool(t, dsn)
	t.Cleanup(p.Close)
	return dsn, p
}

func r5dApplyRetireMigration(t *testing.T, dsn string) (string, error) {
	t.Helper()
	command := osexec.Command("psql", dsn, "-X", "-q", "-v", "ON_ERROR_STOP=1", "--single-transaction",
		"-f", filepath.Join(migrationsRoot(t), r5dRetireMigrationName))
	output, err := command.CombinedOutput()
	return string(output), err
}

func r5dFixtureCombatContext(t *testing.T, p *pg.Pool) {
	t.Helper()
	exec(t, p, `INSERT INTO gxb_content_revisions(revision_id,content_sha256,schema_version,compiler_version,parser_version,manifest)
		VALUES(encode(sha256(convert_to('r5d-migration-fixture','UTF8')),'hex'),sha256(convert_to('r5d-migration-fixture','UTF8')),1,'r5d','r5d',
		jsonb_build_object('revision_id',encode(sha256(convert_to('r5d-migration-fixture','UTF8')),'hex'),'schema_version',1,'compiler_version','r5d','parser_version','r5d'))`)
	exec(t, p, `INSERT INTO combat_snapshots(snapshot_hash,content_revision,rules_corpus_id,canonical)
		VALUES($1,encode(sha256(convert_to('r5d-migration-fixture','UTF8')),'hex'),$2,decode('0000','hex'))`,
		fingerprint("r5d-migration-snapshot"), fingerprint("r5d-migration-rules"))
}

func r5dFixtureCombatAttempt(t *testing.T, p *pg.Pool, attemptID string, playerID int64, terminal bool, terminalAt time.Time) {
	t.Helper()
	exec(t, p, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)VALUES('R5D_MIGRATION_FIXTURE','fixture',$1)`, attemptID)
	state := "STAGED"
	var kind, receipt any
	if terminal {
		kind, receipt = "R5D_MIGRATION_FIXTURE", "r5d-receipt-"+attemptID
		state = "TERMINAL"
	}
	startedAt := terminalAt
	if startedAt.IsZero() {
		startedAt = time.Now().UTC().Add(-time.Hour)
	} else {
		startedAt = startedAt.Add(-time.Hour)
	}
	exec(t, p, `INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,
		generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,
		entropy_key_version,resolver_status,state,started_at,result_deadline,state_version,terminal_kind,terminal_at,semantic_receipt_id)
		VALUES($1,'R5D_MIGRATION_FIXTURE','fixture',$2,$3,$4,$5,$6,'SERVER_REPORT_AUTHORITATIVE_V1',1,$7,$8,
		'HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1','fixture','PENDING',$9,$10,$11,1,$12,$13,$14)`,
		attemptID, attemptID, playerID, uuid().String(), "R5D_MIGRATION_FIXTURE/"+attemptID, fingerprint("r5d-start-"+attemptID),
		fingerprint("r5d-migration-snapshot"), fingerprint("r5d-migration-rules"), state, startedAt, startedAt.Add(2*time.Hour), kind, nullableTime(terminalAt), receipt)
}

func nullableTime(value time.Time) any {
	if value.IsZero() {
		return nil
	}
	return value
}

func r5dWorldBossAttemptRow(t *testing.T, p *pg.Pool, attemptID string, playerID, server int64, resolved bool, damage int64) {
	t.Helper()
	exec(t, p, `INSERT INTO worldboss_attempts(attempt_id,player_id,logical_server_id,generation,campaign_id,formation,frozen_at,resolved,damage)
		VALUES($1,$2,$3,1,10011,'1',0,$4,$5)`, attemptID, playerID, server, resolved, damage)
}

func r5dIllusionAttemptRow(t *testing.T, p *pg.Pool, attemptID string, playerID, server int64, resolved bool, damage int64) {
	t.Helper()
	exec(t, p, `INSERT INTO illusion_attempts(attempt_id,player_id,logical_server_id,open_day,campaign_id,room_id,formation,frozen_at,resolved,damage)
		VALUES($1,$2,$3,1,100001,NULL,'1',0,$4,$5)`, attemptID, playerID, server, resolved, damage)
}

func r5dAdventureAttemptRow(t *testing.T, p *pg.Pool, attemptID string, playerID int64, resolved bool, damage int64) {
	t.Helper()
	exec(t, p, `INSERT INTO adventure_single_attempts(attempt_id,player_id,event_type,occurred_at,created_at,resolved,damage)
		VALUES($1,$2,10006,clock_timestamp(),clock_timestamp(),$3,$4)`, attemptID, playerID, resolved, damage)
}

func r5dNotice(t *testing.T, output, key string) int64 {
	t.Helper()
	match := regexp.MustCompile(`R5D 00169 ` + regexp.QuoteMeta(key) + `=([0-9]+)`).FindStringSubmatch(output)
	if match == nil {
		t.Fatalf("migration notice %s missing: %s", key, output)
	}
	value, err := strconv.ParseInt(match[1], 10, 64)
	if err != nil {
		t.Fatal(err)
	}
	return value
}

func r5dAssertSettlement(t *testing.T, p *pg.Pool, table, attemptID string, damage int64) {
	t.Helper()
	var got int64
	var matchesTerminal bool
	if err := p.QueryRow(ctx, `SELECT damage,settled_at=(SELECT terminal_at FROM combat_attempts WHERE attempt_id=$1) FROM `+table+` WHERE attempt_id=$1`, attemptID).Scan(&got, &matchesTerminal); err != nil {
		t.Fatalf("%s settlement %s: %v", table, attemptID, err)
	}
	if got != damage || !matchesTerminal {
		t.Fatalf("%s settlement %s damage=%d computed=%t", table, attemptID, got, matchesTerminal)
	}
}

func r5dAssertNoSettlement(t *testing.T, p *pg.Pool, table, attemptID string) {
	t.Helper()
	if rows := scalar(t, p, `SELECT count(*) FROM `+table+` WHERE attempt_id=$1`, attemptID); rows != 0 {
		t.Fatalf("%s has %d settlement rows for %s", table, rows, attemptID)
	}
}

func r5dTableExists(t *testing.T, p *pg.Pool, name string) bool {
	t.Helper()
	var exists bool
	if err := p.QueryRow(ctx, `SELECT to_regclass($1) IS NOT NULL`, name).Scan(&exists); err != nil {
		t.Fatal(err)
	}
	return exists
}

// R5D migration 00169: settled mode-local rows become settlement rows on their
// terminal attempt, open rows stay with Combat, stale rows are counted and
// kept, a non-uuid attempt id fails the migration, and the rename-back script
// restores the old names.
func TestR5DMigrationNative(t *testing.T) {
	t.Run("goose-applies-on-empty", func(t *testing.T) {
		base := os.Getenv("GXB_I7B6A_DSN")
		if base == "" {
			t.Fatal("native DSN required")
		}
		dsn, cleanup := disposableNativeDatabase(t, base, "empty")
		t.Cleanup(cleanup)
		runTool(t, "goose", "-dir", migrationsRoot(t), "postgres", dsn, "up")
		p := openNativePool(t, dsn)
		t.Cleanup(p.Close)
		for _, table := range []string{"worldboss_attempts_retired_r5d", "illusion_attempts_retired_r5d", "adventure_single_attempts_retired_r5d"} {
			if !r5dTableExists(t, p, table) {
				t.Fatalf("%s missing after goose up", table)
			}
		}
		if version := scalar(t, p, `SELECT count(*) FROM goose_db_version WHERE version_id = 169 AND is_applied`); version != 1 {
			t.Fatalf("goose applied 00169 %d times, want 1", version)
		}
	})

	t.Run("classification", func(t *testing.T) {
		dsn, p := r5dMigrationDatabase(t, "classify")
		server := int64(rankingServer(t, p))
		players := []identity.ActorContext{}
		for range 4 {
			a, _ := playerRoot(t, p, identity.LogicalServerID(server))
			players = append(players, a)
		}
		r5dFixtureCombatContext(t, p)

		terminalAt := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
		settled := map[string]string{"worldboss": uuid().String(), "illusion": uuid().String(), "adventure": uuid().String()}
		open := map[string]string{"worldboss": uuid().String(), "illusion": uuid().String(), "adventure": uuid().String()}
		openOnTerminal := map[string]string{"worldboss": uuid().String(), "illusion": uuid().String(), "adventure": uuid().String()}
		missing := map[string]string{"worldboss": uuid().String(), "illusion": uuid().String(), "adventure": uuid().String()}
		placeholder := map[string]string{"worldboss": uuid().String(), "illusion": uuid().String(), "adventure": uuid().String()}
		damage := map[string]int64{"worldboss": 11, "illusion": 22, "adventure": 33}

		r5dFixtureCombatAttempt(t, p, settled["worldboss"], int64(players[0].PlayerID), true, terminalAt)
		r5dFixtureCombatAttempt(t, p, open["worldboss"], int64(players[1].PlayerID), false, time.Time{})
		r5dFixtureCombatAttempt(t, p, openOnTerminal["worldboss"], int64(players[3].PlayerID), true, terminalAt.Add(time.Minute))
		r5dFixtureCombatAttempt(t, p, settled["illusion"], int64(players[0].PlayerID), true, terminalAt.Add(2*time.Minute))
		r5dFixtureCombatAttempt(t, p, open["illusion"], int64(players[1].PlayerID), false, time.Time{})
		r5dFixtureCombatAttempt(t, p, openOnTerminal["illusion"], int64(players[3].PlayerID), true, terminalAt.Add(3*time.Minute))
		r5dFixtureCombatAttempt(t, p, settled["adventure"], int64(players[0].PlayerID), true, terminalAt.Add(4*time.Minute))
		r5dFixtureCombatAttempt(t, p, open["adventure"], int64(players[1].PlayerID), false, time.Time{})
		r5dFixtureCombatAttempt(t, p, openOnTerminal["adventure"], int64(players[3].PlayerID), true, terminalAt.Add(5*time.Minute))

		r5dWorldBossAttemptRow(t, p, settled["worldboss"], int64(players[0].PlayerID), server, true, damage["worldboss"])
		r5dWorldBossAttemptRow(t, p, open["worldboss"], int64(players[1].PlayerID), server, false, 0)
		r5dWorldBossAttemptRow(t, p, placeholder["worldboss"], int64(players[2].PlayerID), server, false, 0)
		r5dWorldBossAttemptRow(t, p, openOnTerminal["worldboss"], int64(players[3].PlayerID), server, false, 0)
		r5dWorldBossAttemptRow(t, p, missing["worldboss"], int64(players[0].PlayerID), server, true, 0)
		r5dIllusionAttemptRow(t, p, settled["illusion"], int64(players[0].PlayerID), server, true, damage["illusion"])
		r5dIllusionAttemptRow(t, p, open["illusion"], int64(players[1].PlayerID), server, false, 0)
		r5dIllusionAttemptRow(t, p, placeholder["illusion"], int64(players[2].PlayerID), server, false, 0)
		r5dIllusionAttemptRow(t, p, openOnTerminal["illusion"], int64(players[3].PlayerID), server, false, 0)
		r5dIllusionAttemptRow(t, p, missing["illusion"], int64(players[0].PlayerID), server, true, 0)
		r5dAdventureAttemptRow(t, p, settled["adventure"], int64(players[0].PlayerID), true, damage["adventure"])
		r5dAdventureAttemptRow(t, p, open["adventure"], int64(players[1].PlayerID), false, 0)
		r5dAdventureAttemptRow(t, p, placeholder["adventure"], int64(players[2].PlayerID), false, 0)
		r5dAdventureAttemptRow(t, p, openOnTerminal["adventure"], int64(players[3].PlayerID), false, 0)
		r5dAdventureAttemptRow(t, p, missing["adventure"], int64(players[0].PlayerID), true, 0)

		output, err := r5dApplyRetireMigration(t, dsn)
		if err != nil {
			t.Fatalf("migration failed: %v\n%s", err, output)
		}
		for key, want := range map[string]int64{"settled": 3, "open_kept": 3, "stale_placeholder": 3, "stale_open_terminal": 3, "stale_resolved_missing": 3} {
			if got := r5dNotice(t, output, key); got != want {
				t.Fatalf("notice %s=%d, want %d\n%s", key, got, want, output)
			}
		}

		r5dAssertSettlement(t, p, "worldboss_attempt_settlements", settled["worldboss"], damage["worldboss"])
		r5dAssertSettlement(t, p, "illusion_attempt_settlements", settled["illusion"], damage["illusion"])
		r5dAssertSettlement(t, p, "adventure_attempt_settlements", settled["adventure"], damage["adventure"])
		for mode, table := range map[string]string{"worldboss": "worldboss_attempt_settlements", "illusion": "illusion_attempt_settlements", "adventure": "adventure_attempt_settlements"} {
			for _, attemptID := range []string{open[mode], openOnTerminal[mode], missing[mode], placeholder[mode]} {
				r5dAssertNoSettlement(t, p, table, attemptID)
			}
		}
		for old, retired := range map[string]string{
			"worldboss_attempts": "worldboss_attempts_retired_r5d",
			"illusion_attempts":  "illusion_attempts_retired_r5d", "adventure_single_attempts": "adventure_single_attempts_retired_r5d",
		} {
			if r5dTableExists(t, p, old) || !r5dTableExists(t, p, retired) {
				t.Fatalf("%s was not renamed to %s", old, retired)
			}
			if rows := scalar(t, p, `SELECT count(*) FROM `+retired); rows != 5 {
				t.Fatalf("%s kept %d rows, want 5", retired, rows)
			}
		}

		script := filepath.Join(filepath.Dir(migrationsRoot(t)), "tools", r5dRenameBackScriptName)
		renameBack, err := osexec.Command("bash", script, dsn).CombinedOutput()
		if err != nil {
			t.Fatalf("rename-back script failed: %v\n%s", err, renameBack)
		}
		for old, retired := range map[string]string{
			"worldboss_attempts": "worldboss_attempts_retired_r5d",
			"illusion_attempts":  "illusion_attempts_retired_r5d", "adventure_single_attempts": "adventure_single_attempts_retired_r5d",
		} {
			if !r5dTableExists(t, p, old) || r5dTableExists(t, p, retired) {
				t.Fatalf("rename-back did not restore %s", old)
			}
		}
		if rows := scalar(t, p, `SELECT (SELECT count(*) FROM worldboss_attempt_settlements)+(SELECT count(*) FROM illusion_attempt_settlements)+(SELECT count(*) FROM adventure_attempt_settlements)`); rows != 3 {
			t.Fatalf("rename-back changed settlement rows, want 3, got %d", rows)
		}
	})

	t.Run("non-uuid-id-refused", func(t *testing.T) {
		dsn, p := r5dMigrationDatabase(t, "refuse")
		server := int64(rankingServer(t, p))
		a, _ := playerRoot(t, p, identity.LogicalServerID(server))
		r5dWorldBossAttemptRow(t, p, "not-a-uuid", int64(a.PlayerID), server, false, 0)

		output, err := r5dApplyRetireMigration(t, dsn)
		if err == nil {
			t.Fatalf("migration accepted a non-uuid attempt id: %s", output)
		}
		if !strings.Contains(output, "is not a uuid") || !strings.Contains(output, "worldboss_attempts") {
			t.Fatalf("refusal did not name the offending row: %s", output)
		}
		if !r5dTableExists(t, p, "worldboss_attempts") || r5dTableExists(t, p, "worldboss_attempts_retired_r5d") {
			t.Fatal("refused migration changed the table names")
		}
		if rows := scalar(t, p, `SELECT count(*) FROM worldboss_attempt_settlements`); rows != 0 {
			t.Fatalf("refused migration left %d settlement rows", rows)
		}
	})

	t.Run("world-boss-result-after-migration", func(t *testing.T) {
		dsn, p := r5dRolledBackDatabase(t, "worldboss")
		server := rankingServer(t, p)
		late, latePartner := worldBossActor(t, p, server)
		advance, advancePartner := worldBossActor(t, p, server)
		clock := worldBossTime(t)
		s := worldBossService(t, p, clock)
		formation := []int64{latePartner}

		if _, err := s.Start(ctx, late, app.StartRequest{CampaignID: d.FirstBossID, Formation: formation}, op()); err != nil {
			t.Fatal("late START", err)
		}
		var attemptID string
		if err := p.QueryRow(ctx, `SELECT attempt_id::text FROM combat_attempts WHERE domain_kind='WORLD_BOSS' AND authority_scope=$1 AND domain_locator=$2 AND state<>'TERMINAL'`,
			fmt.Sprintf("server:%d", server), fmt.Sprintf("player:%d", late.PlayerID)).Scan(&attemptID); err != nil {
			t.Fatal("open combat attempt", err)
		}
		// The previous binary also held an open worldboss_attempts row for this attempt.
		r5dWorldBossAttemptRow(t, p, attemptID, int64(late.PlayerID), int64(server), false, 0)

		output, err := r5dApplyRetireMigration(t, dsn)
		if err != nil {
			t.Fatalf("migration failed: %v\n%s", err, output)
		}
		if got := r5dNotice(t, output, "settled"); got != 0 {
			t.Fatalf("settled=%d, want 0", got)
		}
		if got := r5dNotice(t, output, "open_kept"); got != 1 {
			t.Fatalf("open_kept=%d, want 1", got)
		}
		if rows := scalar(t, p, `SELECT count(*) FROM worldboss_attempts_retired_r5d WHERE player_id=$1`, int64(late.PlayerID)); rows != 1 {
			t.Fatalf("retired open row count=%d, want 1", rows)
		}

		revision := installed(t, p)
		catalog, err := s.Content.WorldBossCatalogTx(ctx, p, revision)
		if err != nil {
			t.Fatal(err)
		}
		for bossID := int64(d.FirstBossID); bossID <= d.LastBossID; bossID++ {
			boss, found := catalog.Boss(bossID)
			if !found {
				t.Fatal("missing boss", bossID)
			}
			exec(t, p, `UPDATE worldboss_occurrences SET current_boss=$2,courage=$3 WHERE logical_server_id=$1`, int64(server), bossID, boss.NeedBrave-1)
			if _, err = s.Start(ctx, advance, app.StartRequest{CampaignID: bossID, Formation: []int64{advancePartner}}, op()); err != nil {
				t.Fatalf("advance start %d: %v", bossID, err)
			}
			clock.Set(clock.at.Add(time.Minute))
			if _, err = s.Settle(ctx, advance, app.ResultRequest{CampaignID: bossID, Damage: 1, Formation: []int64{advancePartner}}, op()); err != nil {
				t.Fatalf("advance settle %d: %v", bossID, err)
			}
		}
		if generation, boss, courage, _ := worldBossOccurrence(t, p, server); generation != 2 || boss != d.FirstBossID || courage != 0 {
			t.Fatalf("occurrence did not advance generation=%d boss=%d courage=%d", generation, boss, courage)
		}

		clock.Set(clock.at.Add(time.Minute))
		settled, err := s.Settle(ctx, late, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 100, Formation: formation}, op())
		if err != nil || settled.Duplicate || settled.Body["damage"] != int64(100) || settled.Body["total_hurt"] != int64(100) {
			t.Fatalf("late settle %+v %v", settled, err)
		}
		if total := scalar(t, p, `SELECT hurt FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=1 AND boss_id=$2 AND player_id=$3`, int64(server), d.FirstBossID, int64(late.PlayerID)); total != 100 {
			t.Fatalf("frozen generation total=%d, want 100", total)
		}
		if rows := scalar(t, p, `SELECT count(*) FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=2 AND player_id=$2`, int64(server), int64(late.PlayerID)); rows != 0 {
			t.Fatalf("successor totals touched: %d", rows)
		}
		if generation, boss, courage, _ := worldBossOccurrence(t, p, server); generation != 2 || boss != d.FirstBossID || courage != 0 {
			t.Fatalf("late result changed the successor generation=%d boss=%d courage=%d", generation, boss, courage)
		}
		if rows := scalar(t, p, `SELECT count(*) FROM worldboss_attempt_settlements WHERE player_id=$1 AND damage=100`, int64(late.PlayerID)); rows != 1 {
			t.Fatalf("settlement rows=%d, want 1", rows)
		}

		repeated, err := s.Settle(ctx, late, app.ResultRequest{CampaignID: d.FirstBossID, Damage: 999, Formation: formation}, op())
		if err != nil || !repeated.Duplicate || repeated.Body["damage"] != int64(100) || repeated.Body["total_hurt"] != int64(100) {
			t.Fatalf("duplicate settle %+v %v", repeated, err)
		}
		if total := scalar(t, p, `SELECT hurt FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=1 AND boss_id=$2 AND player_id=$3`, int64(server), d.FirstBossID, int64(late.PlayerID)); total != 100 {
			t.Fatalf("duplicate changed the frozen generation total=%d", total)
		}
		if rows := scalar(t, p, `SELECT count(*) FROM worldboss_player_totals WHERE logical_server_id=$1 AND generation=2 AND player_id=$2`, int64(server), int64(late.PlayerID)); rows != 0 {
			t.Fatalf("duplicate touched the successor board: %d", rows)
		}
	})
}
