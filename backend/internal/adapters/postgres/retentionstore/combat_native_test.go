//go:build postgres

package retentionstore_test

import (
	"context"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/retentionstore"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type combatAttemptSeed struct {
	ID             string
	Locator        string
	SnapshotHash   string
	ResolutionHash string
	TrustProfile   string
	ResolverStatus string
	State          string
	TerminalKind   string
	Supersedes     string
	ReplayResponse string
	TerminalAt     *time.Time
}

func insertCombatSnapshot(t *testing.T, ctx context.Context, pool *pg.Pool, revision, hash string) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_snapshots(snapshot_hash,content_revision,rules_corpus_id,canonical)
VALUES($1,$2,repeat('e',64),decode('0000','hex')) ON CONFLICT(snapshot_hash) DO NOTHING`, hash, revision); err != nil {
		t.Fatal(err)
	}
}

func insertCombatAttempt(t *testing.T, ctx context.Context, pool *pg.Pool, revision string, player int64, seed combatAttemptSeed) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)
VALUES('R8_4C','r8-4c',$1) ON CONFLICT DO NOTHING`, seed.Locator); err != nil {
		t.Fatal(err)
	}
	trustProfile := seed.TrustProfile
	if trustProfile == "" {
		trustProfile = "SERVER_REPORT_AUTHORITATIVE_V1"
	}
	replayResponse := seed.ReplayResponse
	if replayResponse == "" {
		replayResponse = "STORED_REPORT"
	}
	retainer := any(nil)
	if seed.Supersedes != "" {
		retainer = seed.Supersedes
	}
	var resolutionHash any
	if seed.ResolutionHash != "" {
		resolutionHash = seed.ResolutionHash
	}
	var terminalKind, semanticReceipt, terminalAt any
	if seed.TerminalAt != nil {
		terminalKind = seed.TerminalKind
		semanticReceipt = "receipt-" + seed.ID
		terminalAt = seed.TerminalAt.UTC()
	}
	startedAt := time.Now().Add(-48 * time.Hour).UTC()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,entropy_key_version,resolver_status,state,started_at,result_deadline,state_version,resolution_hash,terminal_kind,terminal_at,semantic_receipt_id,supersedes_attempt_id,replay_response)
VALUES($1,'R8_4C','r8-4c',$2,$3,$4,$5,repeat('a',64),$6,1,$7,repeat('b',64),'HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1','r8-4c-key',$8,$9,$10::timestamptz,($10::timestamptz + interval '1 hour'),1,$11,$12,$13,$14,$15,$16)`,
		seed.ID, seed.Locator, player, newUUID(t), "r8-4c-generation-"+seed.Locator, trustProfile,
		seed.SnapshotHash, seed.ResolverStatus, seed.State, startedAt, resolutionHash, terminalKind, terminalAt, semanticReceipt, retainer, replayResponse); err != nil {
		t.Fatal(err)
	}
}

func insertCombatResolution(t *testing.T, ctx context.Context, pool *pg.Pool, attemptID, resolutionHash, reportHash string) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_report_blobs(report_sha256,encoding,byte_length,report)
VALUES($1,'JSON',2,decode('0000','hex')) ON CONFLICT(report_sha256) DO NOTHING`, reportHash); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_resolutions(resolution_hash,attempt_id,report_sha256,canonical)
VALUES($1,$2,$3,decode('0000','hex'))`, resolutionHash, attemptID, reportHash); err != nil {
		t.Fatal(err)
	}
}

func insertCombatChildren(t *testing.T, ctx context.Context, pool *pg.Pool, attemptID string, player int64) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_start_packages(attempt_id,package_policy,package_sha256,draws,canonical)
VALUES($1,'HMAC_SHA256_COUNTER_START_PACKAGE_V1',repeat('c',64),1,decode('0000','hex'))`, attemptID); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_attestations(attempt_id,validator_id,validator_version,verdict,summary_sha256,summary,recorded_at)
VALUES($1,'R8_4C_V1',1,'ACCEPTED',repeat('d',64),decode('0000','hex'),clock_timestamp())`, attemptID); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_attempt_members(attempt_id,seat,member_player_id)VALUES($1,0,$2)`, attemptID, player); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_member_settlements(attempt_id,member_player_id,semantic_receipt_id,settled_at)
VALUES($1,$2,$3,clock_timestamp())`, attemptID, player, "settle-"+attemptID); err != nil {
		t.Fatal(err)
	}
}

func insertSettlement(t *testing.T, ctx context.Context, pool *pg.Pool, table, attemptID string, player int64, settledAt time.Time) {
	t.Helper()
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO `+table+`(attempt_id,player_id,damage,settled_at)VALUES($1,$2,0,$3)`, attemptID, player, settledAt.UTC()); err != nil {
		t.Fatal(err)
	}
}

func newHash(t *testing.T) string {
	t.Helper()
	first := strings.ReplaceAll(newUUID(t), "-", "")
	second := strings.ReplaceAll(newUUID(t), "-", "")
	return first + second
}

func combatRowExists(t *testing.T, ctx context.Context, pool *pg.Pool, statement string, argument any) bool {
	t.Helper()
	var count int
	if err := pool.Raw().QueryRow(ctx, statement, argument).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count == 1
}

func TestCombatChainAndBlobRules(t *testing.T) {
	pool, ctx := openPool(t)
	revision := contentRevision(t, ctx, pool)
	server := int64(884010 + time.Now().UnixNano()%1000)
	player := server*100000 + 25001
	seedServerAndPlayer(t, ctx, pool, server, player)
	old := time.Now().Add(-2 * time.Hour)
	newer := time.Now()

	unreferenced := newUUID(t)
	unreferencedResolution := newHash(t)
	unreferencedReport := newHash(t)
	unreferencedSnapshot := newHash(t)
	insertCombatSnapshot(t, ctx, pool, revision, unreferencedSnapshot)
	insertCombatResolution(t, ctx, pool, unreferenced, unreferencedResolution, unreferencedReport)
	insertCombatAttempt(t, ctx, pool, revision, player, combatAttemptSeed{ID: unreferenced, Locator: "r8-4c-unreferenced", SnapshotHash: unreferencedSnapshot,
		ResolutionHash: unreferencedResolution, ResolverStatus: "READY", State: "TERMINAL", TerminalKind: "WIN", TerminalAt: &old})
	insertCombatChildren(t, ctx, pool, unreferenced, player)

	referenced := newUUID(t)
	referencedSnapshot := newHash(t)
	insertCombatSnapshot(t, ctx, pool, revision, referencedSnapshot)
	insertCombatAttempt(t, ctx, pool, revision, player, combatAttemptSeed{ID: referenced, Locator: "r8-4c-referenced", SnapshotHash: referencedSnapshot,
		ResolverStatus: "PERMANENT_FAILED", State: "TERMINAL", TerminalKind: "WIN", TerminalAt: &old})
	successor := newUUID(t)
	insertCombatAttempt(t, ctx, pool, revision, player, combatAttemptSeed{ID: successor, Locator: "r8-4c-successor", SnapshotHash: referencedSnapshot,
		TrustProfile: "CLIENT_SUMMARY_ATTESTED_V1", ResolverStatus: "NOT_REQUIRED", State: "TERMINAL", TerminalKind: "WIN", TerminalAt: &newer, Supersedes: referenced, ReplayResponse: "OK"})

	settlementReferenced := newUUID(t)
	settlementReferencedSnapshot := newHash(t)
	insertCombatSnapshot(t, ctx, pool, revision, settlementReferencedSnapshot)
	insertCombatAttempt(t, ctx, pool, revision, player, combatAttemptSeed{ID: settlementReferenced, Locator: "r8-4c-settlement-referenced", SnapshotHash: settlementReferencedSnapshot,
		ResolverStatus: "PERMANENT_FAILED", State: "TERMINAL", TerminalKind: "WIN", TerminalAt: &old})
	insertSettlement(t, ctx, pool, "illusion_attempt_settlements", settlementReferenced, player, newer)

	fresh := newUUID(t)
	freshSnapshot := newHash(t)
	freshResolution := newHash(t)
	freshReport := newHash(t)
	insertCombatSnapshot(t, ctx, pool, revision, freshSnapshot)
	insertCombatResolution(t, ctx, pool, fresh, freshResolution, freshReport)
	insertCombatAttempt(t, ctx, pool, revision, player, combatAttemptSeed{ID: fresh, Locator: "r8-4c-fresh", SnapshotHash: freshSnapshot,
		ResolutionHash: freshResolution, ResolverStatus: "READY", State: "TERMINAL", TerminalKind: "WIN", TerminalAt: &newer})

	orphanSnapshot := newHash(t)
	insertCombatSnapshot(t, ctx, pool, revision, orphanSnapshot)
	orphanReport := newHash(t)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO combat_report_blobs(report_sha256,encoding,byte_length,report)VALUES($1,'JSON',2,decode('0000','hex'))`, orphanReport); err != nil {
		t.Fatal(err)
	}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	deleted, err := (retentionstore.Store{}).DeleteExpiredCombatChain(ctx, transaction, time.Now().Add(-time.Hour))
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if deleted < 1 {
		t.Fatalf("chain deleted=%d want at least 1", deleted)
	}
	for table, statement := range map[string]string{
		"attempt":            `SELECT count(*) FROM combat_attempts WHERE attempt_id=$1`,
		"resolution":         `SELECT count(*) FROM combat_resolutions WHERE attempt_id=$1`,
		"start package":      `SELECT count(*) FROM combat_start_packages WHERE attempt_id=$1`,
		"attestation":        `SELECT count(*) FROM combat_attestations WHERE attempt_id=$1`,
		"attempt members":    `SELECT count(*) FROM combat_attempt_members WHERE attempt_id=$1`,
		"member settlements": `SELECT count(*) FROM combat_member_settlements WHERE attempt_id=$1`,
	} {
		if combatRowExists(t, ctx, pool, statement, unreferenced) {
			t.Fatalf("unreferenced old %s survived", table)
		}
	}
	for name, id := range map[string]string{"superseded": referenced, "settlement-referenced": settlementReferenced, "new": fresh, "successor": successor} {
		if !combatRowExists(t, ctx, pool, `SELECT count(*) FROM combat_attempts WHERE attempt_id=$1`, id) {
			t.Fatalf("%s attempt was deleted", name)
		}
	}

	transaction, err = pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func(open tx.Tx) { _ = open.Rollback(ctx) }(transaction)
	deleted, err = (retentionstore.Store{}).DeleteUnreferencedCombatBlobs(ctx, transaction)
	if err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	// The four orphans are the deleted attempt's snapshot and report plus the
	// seeded orphan snapshot and report.
	if deleted != 4 {
		t.Fatalf("blob rule deleted=%d want 4", deleted)
	}
	for name, hash := range map[string]string{"attempt snapshot": referencedSnapshot, "settlement-referenced snapshot": settlementReferencedSnapshot, "new snapshot": freshSnapshot} {
		if !combatRowExists(t, ctx, pool, `SELECT count(*) FROM combat_snapshots WHERE snapshot_hash=$1`, hash) {
			t.Fatalf("%s was deleted", name)
		}
	}
	for name, hash := range map[string]string{"deleted attempt snapshot": unreferencedSnapshot, "orphan snapshot": orphanSnapshot} {
		if combatRowExists(t, ctx, pool, `SELECT count(*) FROM combat_snapshots WHERE snapshot_hash=$1`, hash) {
			t.Fatalf("%s survived", name)
		}
	}
	if combatRowExists(t, ctx, pool, `SELECT count(*) FROM combat_report_blobs WHERE report_sha256=$1`, unreferencedReport) {
		t.Fatal("report blob of the deleted resolution survived")
	}
	if !combatRowExists(t, ctx, pool, `SELECT count(*) FROM combat_report_blobs WHERE report_sha256=$1`, freshReport) {
		t.Fatal("report blob of the surviving resolution was deleted")
	}
	if combatRowExists(t, ctx, pool, `SELECT count(*) FROM combat_report_blobs WHERE report_sha256=$1`, orphanReport) {
		t.Fatal("orphan report blob survived the blob rule")
	}
}

func TestCombatRulesDeleteOnlyInsideTheSweep(t *testing.T) {
	pool, ctx := openPool(t)
	revision := contentRevision(t, ctx, pool)
	server := int64(885010 + time.Now().UnixNano()%1000)
	player := server*100000 + 25001
	seedServerAndPlayer(t, ctx, pool, server, player)
	terminalAt := time.Now()

	attempt := newUUID(t)
	snapshot := newHash(t)
	resolution := newHash(t)
	report := newHash(t)
	insertCombatSnapshot(t, ctx, pool, revision, snapshot)
	insertCombatAttempt(t, ctx, pool, revision, player, combatAttemptSeed{ID: attempt, Locator: "r8-4c-sweep-only", SnapshotHash: snapshot,
		ResolverStatus: "PERMANENT_FAILED", State: "TERMINAL", TerminalKind: "WIN", TerminalAt: &terminalAt})
	insertCombatChildren(t, ctx, pool, attempt, player)
	insertCombatResolution(t, ctx, pool, attempt, resolution, report)

	statements := []struct {
		query     string
		arguments []any
	}{
		{`DELETE FROM combat_snapshots WHERE snapshot_hash=$1`, []any{snapshot}},
		{`DELETE FROM combat_report_blobs WHERE report_sha256=$1`, []any{report}},
		{`DELETE FROM combat_resolutions WHERE attempt_id=$1`, []any{attempt}},
		{`DELETE FROM combat_start_packages WHERE attempt_id=$1`, []any{attempt}},
		{`DELETE FROM combat_attestations WHERE attempt_id=$1`, []any{attempt}},
		{`DELETE FROM combat_member_settlements WHERE attempt_id=$1`, []any{attempt}},
		{`DELETE FROM combat_attempt_members WHERE attempt_id=$1`, []any{attempt}},
		{`DELETE FROM combat_attempts WHERE attempt_id=$1`, []any{attempt}},
		{`UPDATE combat_attempts SET state_version=state_version WHERE attempt_id=$1`, []any{attempt}},
		{`UPDATE combat_snapshots SET encoding=encoding WHERE snapshot_hash=$1`, []any{snapshot}},
		{`UPDATE combat_report_blobs SET encoding=encoding WHERE report_sha256=$1`, []any{report}},
		{`UPDATE combat_resolutions SET resolution_hash=resolution_hash WHERE attempt_id=$1`, []any{attempt}},
		{`UPDATE combat_start_packages SET draws=draws WHERE attempt_id=$1`, []any{attempt}},
		{`UPDATE combat_attestations SET verdict=verdict WHERE attempt_id=$1`, []any{attempt}},
		{`UPDATE combat_member_settlements SET semantic_receipt_id=semantic_receipt_id WHERE attempt_id=$1`, []any{attempt}},
		{`UPDATE combat_attempt_members SET seat=seat WHERE attempt_id=$1`, []any{attempt}},
	}
	for _, statement := range statements {
		if _, err := pool.Raw().Exec(ctx, statement.query, statement.arguments...); err == nil {
			t.Fatalf("outside the sweep %s was accepted", statement.query)
		}
	}

	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = transaction.Rollback(ctx) }()
	if _, err = transaction.Exec(ctx, "SET LOCAL gxb.retention_sweep = 'on'"); err != nil {
		t.Fatal(err)
	}
	if _, err = transaction.Exec(ctx, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)
VALUES('R8_4C','r8-4c','r8-4c-staged')`); err != nil {
		t.Fatal(err)
	}
	staged := newUUID(t)
	if _, err = transaction.Exec(ctx, `INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,entropy_key_version,resolver_status,state,started_at,result_deadline,state_version)
VALUES($1,'R8_4C','r8-4c','r8-4c-staged',$2,$3,'r8-4c-staged',repeat('a',64),'SERVER_REPORT_AUTHORITATIVE_V1',1,$4,repeat('b',64),'HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1','r8-4c-key','PENDING','STAGED',clock_timestamp() - interval '2 hours',clock_timestamp() - interval '1 hour',1)`,
		staged, player, newUUID(t), snapshot); err != nil {
		t.Fatal(err)
	}
	if _, err = transaction.Exec(ctx, `DELETE FROM combat_attempts WHERE attempt_id=$1`, staged); err == nil {
		t.Fatal("a non-terminal attempt was deleted inside the sweep")
	}
	if err = transaction.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
}

// R5D design, Retention: an expired settlement row is purged first, which
// releases its attempt to the chain rule; a fresh settlement keeps its attempt.
func TestSettlementRuleReleasesItsAttempt(t *testing.T) {
	pool, ctx := openPool(t)
	revision := contentRevision(t, ctx, pool)
	server := int64(886010 + time.Now().UnixNano()%1000)
	player := server*100000 + 25001
	seedServerAndPlayer(t, ctx, pool, server, player)
	old := time.Now().Add(-2 * time.Hour)
	cutoff := time.Now().Add(-time.Hour)

	attempts := map[string]string{}
	for _, table := range []string{"adventure_attempt_settlements", "illusion_attempt_settlements", "worldboss_attempt_settlements", "fresh"} {
		attempt := newUUID(t)
		snapshot := newHash(t)
		insertCombatSnapshot(t, ctx, pool, revision, snapshot)
		insertCombatAttempt(t, ctx, pool, revision, player, combatAttemptSeed{ID: attempt, Locator: "r8-4c-settled-" + attempt, SnapshotHash: snapshot,
			ResolverStatus: "PERMANENT_FAILED", State: "TERMINAL", TerminalKind: "WIN", TerminalAt: &old})
		attempts[table] = attempt
	}
	for _, table := range []string{"adventure_attempt_settlements", "illusion_attempt_settlements", "worldboss_attempt_settlements"} {
		insertSettlement(t, ctx, pool, table, attempts[table], player, old)
	}
	insertSettlement(t, ctx, pool, "illusion_attempt_settlements", attempts["fresh"], player, time.Now())

	if _, err := pool.Raw().Exec(ctx, `DELETE FROM illusion_attempt_settlements WHERE attempt_id=$1`, attempts["illusion_attempt_settlements"]); err == nil {
		t.Fatal("outside the sweep a settlement DELETE was accepted")
	}

	sweep := func(rule func(context.Context, tx.Tx) (int64, error)) int64 {
		t.Helper()
		transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = transaction.Rollback(ctx) }()
		deleted, err := rule(ctx, transaction)
		if err != nil {
			t.Fatal(err)
		}
		if err = transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
		return deleted
	}
	store := retentionstore.Store{}
	if deleted := sweep(func(c context.Context, t tx.Tx) (int64, error) {
		return store.DeleteExpiredAttemptSettlements(c, t, cutoff)
	}); deleted < 3 {
		t.Fatalf("settlement rule deleted=%d want at least 3", deleted)
	}
	for table, attempt := range attempts {
		settled := table
		if table == "fresh" {
			settled = "illusion_attempt_settlements"
		}
		if survived := combatRowExists(t, ctx, pool, `SELECT count(*) FROM `+settled+` WHERE attempt_id=$1`, attempt); survived != (table == "fresh") {
			t.Fatalf("%s settlement survived=%v", table, survived)
		}
	}
	sweep(func(c context.Context, t tx.Tx) (int64, error) { return store.DeleteExpiredCombatChain(c, t, cutoff) })
	// Leave no orphan snapshots behind for the exact blob count of the chain test.
	sweep(store.DeleteUnreferencedCombatBlobs)
	for table, attempt := range attempts {
		if survived := combatRowExists(t, ctx, pool, `SELECT count(*) FROM combat_attempts WHERE attempt_id=$1`, attempt); survived != (table == "fresh") {
			t.Fatalf("%s attempt survived=%v", table, survived)
		}
	}
}
