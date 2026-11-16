//go:build postgres

package topfloorstore_test

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type topFloorFixture struct {
	transaction tx.Tx
	revision    string
	now         time.Time
}

func newTopFloorFixture(t *testing.T) *topFloorFixture {
	t.Helper()
	dsn := os.Getenv("GXB_R8_MANIFEST_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_MANIFEST_DSN required")
	}
	ctx := context.Background()
	pool, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 2, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	transaction, err := pool.Begin(ctx, tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = transaction.Rollback(ctx) })
	fixture := &topFloorFixture{transaction: transaction, now: time.Now().UTC().Truncate(time.Second)}
	if err := transaction.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY installed_at DESC LIMIT 1`).Scan(&fixture.revision); err != nil {
		t.Fatal("content revision required:", err)
	}
	for _, pid := range []identity.PlayerID{100001, 100002} {
		account, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',now())`, account.String(), account.String()); err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,now(),'payload-version-probe')`, int64(pid), account.String()); err != nil {
			t.Fatal(err)
		}
	}
	return fixture
}

func (f *topFloorFixture) storedPayload(t *testing.T, sql string, args ...any) (string, int16) {
	t.Helper()
	var raw string
	var version int16
	if err := f.transaction.QueryRow(context.Background(), sql, args...).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	return raw, version
}

func (f *topFloorFixture) storedVersion(t *testing.T, sql string, args ...any) int16 {
	t.Helper()
	var version int16
	if err := f.transaction.QueryRow(context.Background(), sql, args...).Scan(&version); err != nil {
		t.Fatal(err)
	}
	return version
}

func (f *topFloorFixture) attempt(t *testing.T, locator string) ids.UUID {
	t.Helper()
	attempt, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	if _, err := f.transaction.Exec(ctx, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)VALUES('TOP_FLOOR',$1,$2)`, "round-trip", locator); err != nil {
		t.Fatal(err)
	}
	fingerprint := fmt.Sprintf("%064x", 7)
	if _, err := f.transaction.Exec(ctx, `INSERT INTO combat_snapshots(snapshot_hash,content_revision,rules_corpus_id,canonical)VALUES($1,$2,$1,'{}')ON CONFLICT DO NOTHING`, fingerprint, f.revision); err != nil {
		t.Fatal(err)
	}
	if _, err := f.transaction.Exec(ctx, `INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,entropy_key_version,resolver_status,state,started_at,result_deadline,state_version)VALUES($1,'TOP_FLOOR',$2,$3,100001,$4,'round-trip',$5,'SERVER_REPORT_AUTHORITATIVE_V1',1,$5,$5,'HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1','v1','PENDING','STAGED',$6,$7,1)`,
		attempt.String(), "round-trip", locator, attempt.String(), fingerprint, f.now, f.now.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	return attempt
}

func requirePayloadVersionOne(t *testing.T, version int16) {
	t.Helper()
	if version != payload.Current {
		t.Fatalf("payload_version = %d, want %d", version, payload.Current)
	}
}

func requireSameJSON(t *testing.T, raw string, value any) {
	t.Helper()
	expected, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	var storedValue, expectedValue any
	if err := json.Unmarshal([]byte(raw), &storedValue); err != nil {
		t.Fatal(err)
	}
	if err := json.Unmarshal(expected, &expectedValue); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(storedValue, expectedValue) {
		t.Fatalf("stored payload differs from written value\n got: %s\nwant: %s", raw, expected)
	}
}

func TestPayloadVersionRoundTripTopFloorStore(t *testing.T) {
	ctx := context.Background()
	fixture := newTopFloorFixture(t)
	store := topfloorstore.Store{}

	ladder := domain.Ladder{Server: 1, ContentRevision: fixture.revision, Size: domain.RobotTeams, SettledDay: 0, StateVersion: 1, CreatedAt: fixture.now, UpdatedAt: fixture.now}
	if err := store.CreateLadderTx(ctx, fixture.transaction, ladder); err != nil {
		t.Fatal(err)
	}
	player := domain.Player{PlayerID: 100001, Server: 1, ContentRevision: fixture.revision, BestRank: 1, TicketDay: 1, TicketsLeft: 10, OfferedDay: 1,
		Offered: []domain.Occupant{{Robot: domain.RobotTeams}, {Player: 100002}}, Defense: []int64{1, 2},
		StateVersion: 1, CreatedAt: fixture.now, UpdatedAt: fixture.now}
	if err := store.InsertPlayerTx(ctx, fixture.transaction, player); err != nil {
		t.Fatal(err)
	}
	offered, version := fixture.storedPayload(t, `SELECT offered::text,payload_version FROM top_floor_players WHERE player_id=100001`)
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, offered, player.Offered)
	defense, version := fixture.storedPayload(t, `SELECT defense::text,payload_version FROM top_floor_players WHERE player_id=100001`)
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, defense, player.Defense)
	storedPlayer, found, err := store.ReadPlayerTx(ctx, fixture.transaction, player.PlayerID, false)
	if err != nil || !found || !reflect.DeepEqual(storedPlayer.Offered, player.Offered) || !reflect.DeepEqual(storedPlayer.Defense, player.Defense) {
		t.Fatalf("ReadPlayerTx after insert found=%v err=%v", found, err)
	}
	player.Defense, player.StateVersion, player.UpdatedAt = []int64{3, 4}, 2, fixture.now.Add(time.Minute)
	if err := store.SavePlayerTx(ctx, fixture.transaction, player, 1); err != nil {
		t.Fatal(err)
	}
	requirePayloadVersionOne(t, fixture.storedVersion(t, `SELECT payload_version FROM top_floor_players WHERE player_id=100001`))
	storedPlayer, found, err = store.ReadPlayerTx(ctx, fixture.transaction, player.PlayerID, false)
	if err != nil || !found || !reflect.DeepEqual(storedPlayer.Defense, player.Defense) {
		t.Fatalf("ReadPlayerTx after save found=%v err=%v", found, err)
	}

	snapshot := domain.OfferSnapshot{Player: 100001, Server: 1, Scope: domain.OfferScopeNormal, Generation: 1, ChallengerRank: 1,
		Offers: []domain.Ranked{{Rank: 2, Occupant: domain.Occupant{Robot: domain.RobotTeams - 1}}, {Rank: 3, Occupant: domain.Occupant{Player: 100002}}}, UpdatedAt: fixture.now}
	if err := store.SaveOfferSnapshotTx(ctx, fixture.transaction, snapshot); err != nil {
		t.Fatal(err)
	}
	offers, version := fixture.storedPayload(t, `SELECT offers::text,payload_version FROM top_floor_offer_snapshots WHERE player_id=100001 AND scope=0`)
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, offers, snapshot.Offers)
	storedSnapshot, found, err := store.ReadOfferSnapshotTx(ctx, fixture.transaction, snapshot.Player, snapshot.Scope, false)
	if err != nil || !found || !reflect.DeepEqual(storedSnapshot.Offers, snapshot.Offers) {
		t.Fatalf("ReadOfferSnapshotTx found=%v err=%v", found, err)
	}
	snapshot.Generation, snapshot.Offers, snapshot.UpdatedAt = 2, []domain.Ranked{{Rank: 2, Occupant: domain.Occupant{Player: 100002}}}, fixture.now.Add(time.Minute)
	if err := store.SaveOfferSnapshotTx(ctx, fixture.transaction, snapshot); err != nil {
		t.Fatal(err)
	}
	requirePayloadVersionOne(t, fixture.storedVersion(t, `SELECT payload_version FROM top_floor_offer_snapshots WHERE player_id=100001 AND scope=0`))
	storedSnapshot, found, err = store.ReadOfferSnapshotTx(ctx, fixture.transaction, snapshot.Player, snapshot.Scope, false)
	if err != nil || !found || !reflect.DeepEqual(storedSnapshot.Offers, snapshot.Offers) {
		t.Fatalf("ReadOfferSnapshotTx after update found=%v err=%v", found, err)
	}

	fight := domain.Fight{AttemptID: fixture.attempt(t, "fight"), Server: 1, Challenger: 100001, Defender: domain.Occupant{Robot: domain.RobotTeams},
		Fingerprint: fmt.Sprintf("%064x", 7), Formation: []int64{1, 2, 3}, ChallengerRank: 1, DefenderRank: 2, StartedAt: fixture.now, Status: domain.StatusStarted, StateVersion: 1}
	if err := store.InsertFightTx(ctx, fixture.transaction, fight); err != nil {
		t.Fatal(err)
	}
	formation, version := fixture.storedPayload(t, `SELECT formation::text,payload_version FROM top_floor_fights WHERE attempt_id=$1`, fight.AttemptID.String())
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, formation, fight.Formation)
	if _, found, err := store.ReadFightTx(ctx, fixture.transaction, fight.AttemptID, false); err != nil || !found {
		t.Fatalf("ReadFightTx found=%v err=%v", found, err)
	}
	if _, found, err := store.LatestFightTx(ctx, fixture.transaction, fight.Challenger); err != nil || !found {
		t.Fatalf("LatestFightTx found=%v err=%v", found, err)
	}
	open, err := store.OpenFightsTx(ctx, fixture.transaction, fixture.now.Add(time.Minute), 10)
	if err != nil || len(open) != 1 || !reflect.DeepEqual(open[0].Formation, fight.Formation) {
		t.Fatalf("OpenFightsTx %v %v", open, err)
	}
	settledAt := fixture.now.Add(time.Minute)
	fight.Status, fight.Outcome, fight.SettledAt, fight.StateVersion = domain.StatusSettled, &domain.Outcome{Win: true, ChallengerBefore: 1, DefenderBefore: 2, ChallengerAfter: 2, DefenderAfter: 1, BestBefore: 1, BestAfter: 1}, &settledAt, 2
	if err := store.FinishFightTx(ctx, fixture.transaction, fight, 1); err != nil {
		t.Fatal(err)
	}
	outcome, version := fixture.storedPayload(t, `SELECT outcome::text,payload_version FROM top_floor_fights WHERE attempt_id=$1`, fight.AttemptID.String())
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, outcome, fight.Outcome)
	storedFight, found, err := store.ReadFightTx(ctx, fixture.transaction, fight.AttemptID, false)
	if err != nil || !found || !reflect.DeepEqual(storedFight.Formation, fight.Formation) || !reflect.DeepEqual(storedFight.Outcome, fight.Outcome) {
		t.Fatalf("ReadFightTx after finish found=%v err=%v", found, err)
	}
	closed := domain.Fight{AttemptID: fixture.attempt(t, "closed-fight"), Server: 1, Challenger: 100001, Defender: domain.Occupant{Robot: domain.RobotTeams},
		Fingerprint: fmt.Sprintf("%064x", 7), Formation: []int64{4}, ChallengerRank: 1, DefenderRank: 2, StartedAt: fixture.now, Status: domain.StatusStarted, StateVersion: 1}
	if err := store.InsertFightTx(ctx, fixture.transaction, closed); err != nil {
		t.Fatal(err)
	}
	closedAt := fixture.now.Add(2 * time.Minute)
	closed.Status, closed.SettledAt, closed.StateVersion = domain.StatusClosed, &closedAt, 2
	if err := store.FinishFightTx(ctx, fixture.transaction, closed, 1); err != nil {
		t.Fatal(err)
	}
	var outcomeNull bool
	var closedVersion int16
	if err := fixture.transaction.QueryRow(ctx, `SELECT outcome IS NULL,payload_version FROM top_floor_fights WHERE attempt_id=$1`, closed.AttemptID.String()).Scan(&outcomeNull, &closedVersion); err != nil {
		t.Fatal(err)
	}
	if !outcomeNull {
		t.Fatal("closed fight outcome is not null")
	}
	requirePayloadVersionOne(t, closedVersion)

	startsAt := fixture.now.Add(-2 * time.Hour)
	period := domain.TaskModePeriod{
		Ladder:   domain.Ladder{Server: 1, ContentRevision: fixture.revision, Size: 0, SettledDay: 0, StateVersion: 1, CreatedAt: fixture.now.Add(-time.Hour), UpdatedAt: fixture.now.Add(-time.Hour)},
		Rotation: domain.TaskModeRotation{Number: 1, Mode: domain.TaskModeSingle, Submode: 0, StartsAt: startsAt, EndsAt: startsAt.Add(168 * time.Hour)},
	}
	if err := store.CreateTaskPeriodTx(ctx, fixture.transaction, period); err != nil {
		t.Fatal(err)
	}
	taskPlayerValue := player
	taskPlayerValue.StateVersion = 1
	taskPlayer := domain.TaskModePlayer{Player: taskPlayerValue, PeriodNumber: 1}
	if err := store.InsertTaskPlayerTx(ctx, fixture.transaction, taskPlayer, period); err != nil {
		t.Fatal(err)
	}
	taskPayload, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM top_floor_task_players WHERE player_id=100001 AND period_number=1`)
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, taskPayload, taskPlayer)
	storedTaskPlayer, found, err := store.ReadTaskPlayerTx(ctx, fixture.transaction, taskPlayer.Player.PlayerID, period, false)
	if err != nil || !found || storedTaskPlayer.Player.PlayerID != taskPlayer.Player.PlayerID {
		t.Fatalf("ReadTaskPlayerTx found=%v err=%v", found, err)
	}
	taskPlayer.Player.StateVersion, taskPlayer.Player.UpdatedAt = 2, fixture.now.Add(time.Minute)
	if err := store.SaveTaskPlayerTx(ctx, fixture.transaction, taskPlayer, period, 1); err != nil {
		t.Fatal(err)
	}
	requirePayloadVersionOne(t, fixture.storedVersion(t, `SELECT payload_version FROM top_floor_task_players WHERE player_id=100001 AND period_number=1`))
	storedTaskPlayer, found, err = store.ReadTaskPlayerTx(ctx, fixture.transaction, taskPlayer.Player.PlayerID, period, false)
	if err != nil || !found || storedTaskPlayer.Player.StateVersion != 2 {
		t.Fatalf("ReadTaskPlayerTx after save found=%v err=%v", found, err)
	}

	preference := domain.TaskModeDefense{Heroes: []int64{3, 4}, Pet: 0, Leader: 0}
	if err := store.SaveTaskPreferenceTx(ctx, fixture.transaction, 100001, domain.TaskModeSingle, preference); err != nil {
		t.Fatal(err)
	}
	preferencePayload, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM top_floor_task_preferences WHERE player_id=100001 AND mode=1`)
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, preferencePayload, preference)
	storedPreference, found, err := store.TaskPreferenceTx(ctx, fixture.transaction, 100001, domain.TaskModeSingle)
	if err != nil || !found || !reflect.DeepEqual(storedPreference, preference) {
		t.Fatalf("TaskPreferenceTx found=%v err=%v", found, err)
	}
	preference.Heroes = []int64{5}
	if err := store.SaveTaskPreferenceTx(ctx, fixture.transaction, 100001, domain.TaskModeSingle, preference); err != nil {
		t.Fatal(err)
	}
	requirePayloadVersionOne(t, fixture.storedVersion(t, `SELECT payload_version FROM top_floor_task_preferences WHERE player_id=100001 AND mode=1`))
	storedPreference, found, err = store.TaskPreferenceTx(ctx, fixture.transaction, 100001, domain.TaskModeSingle)
	if err != nil || !found || !reflect.DeepEqual(storedPreference, preference) {
		t.Fatalf("TaskPreferenceTx after update found=%v err=%v", found, err)
	}

	taskFight := domain.TaskModeFight{Fight: domain.Fight{AttemptID: fixture.attempt(t, "task-fight"), Server: 1, Challenger: 100001, Defender: domain.Occupant{Robot: domain.RobotTeams},
		Fingerprint: fmt.Sprintf("%064x", 7), Formation: []int64{1, 2}, ChallengerRank: 1, DefenderRank: 1, StartedAt: fixture.now, Status: domain.StatusStarted, StateVersion: 1},
		PeriodNumber: 1, Mode: domain.TaskModeSingle, Formation: []map[string]any{{"table_id": 1}, {"table_id": 2}},
		Enemy: domain.Display{Occupant: domain.Occupant{Robot: domain.RobotTeams}, Rank: 1}}
	if err := store.InsertTaskFightTx(ctx, fixture.transaction, taskFight); err != nil {
		t.Fatal(err)
	}
	taskFightPayload, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM top_floor_task_fights WHERE attempt_id=$1`, taskFight.Fight.AttemptID.String())
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, taskFightPayload, taskFight)
	if _, found, err := store.ReadTaskFightTx(ctx, fixture.transaction, taskFight.Fight.AttemptID, false); err != nil || !found {
		t.Fatalf("ReadTaskFightTx found=%v err=%v", found, err)
	}
	if _, found, err := store.LatestTaskFightTx(ctx, fixture.transaction, taskFight.Fight.Challenger); err != nil || !found {
		t.Fatalf("LatestTaskFightTx found=%v err=%v", found, err)
	}
	openTaskFights, err := store.OpenTaskFightsTx(ctx, fixture.transaction, fixture.now.Add(time.Minute), 10)
	if err != nil || len(openTaskFights) != 1 {
		t.Fatalf("OpenTaskFightsTx %v %v", openTaskFights, err)
	}
	taskSettledAt := fixture.now.Add(time.Minute)
	taskFight.Fight.Status, taskFight.Fight.Outcome, taskFight.Fight.SettledAt, taskFight.Fight.StateVersion = domain.StatusSettled, &domain.Outcome{Win: false, ChallengerBefore: 1, DefenderBefore: 1, ChallengerAfter: 1, DefenderAfter: 1, BestBefore: 1, BestAfter: 1}, &taskSettledAt, 2
	if err := store.FinishTaskFightTx(ctx, fixture.transaction, taskFight, 1); err != nil {
		t.Fatal(err)
	}
	taskFightPayload, version = fixture.storedPayload(t, `SELECT payload::text,payload_version FROM top_floor_task_fights WHERE attempt_id=$1`, taskFight.Fight.AttemptID.String())
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, taskFightPayload, taskFight)
	storedTaskFight, found, err := store.ReadTaskFightTx(ctx, fixture.transaction, taskFight.Fight.AttemptID, false)
	if err != nil || !found || storedTaskFight.Fight.Status != taskFight.Fight.Status || storedTaskFight.Fight.StateVersion != taskFight.Fight.StateVersion ||
		!reflect.DeepEqual(storedTaskFight.Fight.Outcome, taskFight.Fight.Outcome) || !reflect.DeepEqual(storedTaskFight.Enemy.Occupant, taskFight.Enemy.Occupant) {
		t.Fatalf("ReadTaskFightTx after finish found=%v err=%v", found, err)
	}

	record := domain.TaskModeRecord{Record: domain.Record{Owner: 100001, AttemptID: taskFight.Fight.AttemptID, Attack: true, Win: false, Opponent: domain.Occupant{Robot: domain.RobotTeams}, At: fixture.now},
		PeriodNumber: 1, Mode: domain.TaskModeSingle}
	if err := store.InsertTaskRecordTx(ctx, fixture.transaction, record, 10); err != nil {
		t.Fatal(err)
	}
	recordPayload, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM top_floor_task_records WHERE owner_player_id=100001`)
	requirePayloadVersionOne(t, version)
	requireSameJSON(t, recordPayload, record)
	var storedRecordID int64
	if err := fixture.transaction.QueryRow(ctx, `SELECT record_id FROM top_floor_task_records WHERE owner_player_id=100001`).Scan(&storedRecordID); err != nil {
		t.Fatal(err)
	}
	records, err := store.TaskRecordsTx(ctx, fixture.transaction, 100001)
	if err != nil || len(records) != 1 || records[0].Record.ID != storedRecordID || records[0].Record.AttemptID != record.Record.AttemptID {
		t.Fatalf("TaskRecordsTx %v %v", records, err)
	}
	single, found, err := store.TaskRecordTx(ctx, fixture.transaction, storedRecordID)
	if err != nil || !found || single.Record.ID != storedRecordID || single.Record.AttemptID != record.Record.AttemptID {
		t.Fatalf("TaskRecordTx found=%v err=%v", found, err)
	}
}
