//go:build postgres

package conquerstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/conquerstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func storedPayload[T any](t *testing.T, p *pg.Pool, table, column, where string, arg any, out *T) []byte {
	t.Helper()
	var raw []byte
	var version int16
	if err := p.QueryRow(context.Background(), `SELECT `+column+`::text,payload_version FROM `+table+` WHERE `+where, arg).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("%s.%s payload_version=%d want %d", table, column, version, payload.Current)
	}
	if err := payload.Decode(table, version, raw, out); err != nil {
		t.Fatalf("%s.%s strict decode: %v", table, column, err)
	}
	return raw
}

func samePayload(t *testing.T, written, decoded any) {
	t.Helper()
	writtenRaw, err := json.Marshal(written)
	if err != nil {
		t.Fatal(err)
	}
	decodedRaw, err := json.Marshal(decoded)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(decodedRaw, writtenRaw) {
		t.Fatalf("payload changed: decoded=%s written=%s", decodedRaw, writtenRaw)
	}
}

func seedR82Player(t *testing.T, pool *pg.Pool, pid identity.PlayerID, tag string) string {
	t.Helper()
	ctx := context.Background()
	accountUID := "r8-2b-" + tag + "-" + strconv.FormatInt(int64(pid), 10)
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at) VALUES(gen_random_uuid(),$1,'ACTIVE',clock_timestamp())`, accountUID); err != nil {
		t.Fatal(err)
	}
	if _, err := pool.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version) SELECT $1,account_id,1,clock_timestamp(),'r8-2b-native' FROM accounts WHERE account_uid=$2`, int64(pid), accountUID); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cleanup := context.Background()
		for _, query := range []string{
			`DELETE FROM conquer_school_reports WHERE owner_player_id=$1`,
			`DELETE FROM conquer_school_players WHERE player_id=$1`,
			`DELETE FROM player_conquer_facts WHERE player_id=$1`,
		} {
			pool.Raw().Exec(cleanup, query, int64(pid))
		}
		pool.Raw().Exec(cleanup, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, accountUID)
	})
	return accountUID
}

func TestPayloadVersionRoundTripConquerStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-conquerstore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	store := conquerstore.Store{}
	pid := identity.PlayerID(112014)
	seedR82Player(t, p, pid, "conquer-native")
	now := time.Now().UTC().Truncate(time.Second)
	var revision string
	if err = p.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY revision_id LIMIT 1`).Scan(&revision); err != nil {
		t.Fatal(err)
	}
	catalog, err := (contentstore.Store{Queryer: p}).ConquerCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal(err)
	}
	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision})
	if err != nil {
		t.Fatal(err)
	}
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	op := operation.Context{ID: operationID, StartedAt: now, Policies: policies}

	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InsertLegacyUnknownTx(ctx, tr, pid, revision, op, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var insertedFacts d.Payload
	storedPayload(t, p, "player_conquer_facts", "payload", "player_id=$1", int64(pid), &insertedFacts)
	if insertedFacts.Kind != d.Unknown {
		t.Fatalf("facts kind = %q", insertedFacts.Kind)
	}

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	facts, err := store.LockFactsTx(ctx, tr, pid)
	if err != nil {
		t.Fatal(err)
	}
	facts.Version, facts.UpdatedAt = 2, now
	if err = store.SaveFactsTx(ctx, tr, facts, 1, catalog); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedFacts d.Payload
	storedPayload(t, p, "player_conquer_facts", "payload", "player_id=$1", int64(pid), &savedFacts)
	samePayload(t, facts.Payload, savedFacts)
	if read, err := store.ReadFactsTx(ctx, p, pid); err != nil || read.Version != 2 {
		t.Fatalf("ReadFactsTx version=%d err=%v", read.Version, err)
	}

	mode := d.Mode{Player: pid, Day: 20261116, LeftTimes: 7, BuyTimes: 2, Buff: 3, AwardTimes: 1, BeatenTeams: []int64{1, 2}, UsedHeroes: []int64{10001001}, UsedPets: []int64{50001}, StateVersion: 1, CreatedAt: now, UpdatedAt: now}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InsertModeTx(ctx, tr, mode, 1, revision); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var insertedMode d.Mode
	storedPayload(t, p, "conquer_school_players", "state", "player_id=$1", int64(pid), &insertedMode)
	samePayload(t, mode, insertedMode)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	lockedMode, found, err := store.ReadModeTx(ctx, tr, pid, true)
	if err != nil || !found {
		t.Fatalf("ReadModeTx found=%v err=%v", found, err)
	}
	lockedMode.StateVersion, lockedMode.UpdatedAt = 2, now
	lockedMode.BuyTimes = 4
	if err = store.SaveModeTx(ctx, tr, lockedMode, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedMode d.Mode
	storedPayload(t, p, "conquer_school_players", "state", "player_id=$1", int64(pid), &savedMode)
	samePayload(t, lockedMode, savedMode)

	reportKey, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	report := d.Report{
		Key:        reportKey.String(),
		Owner:      pid,
		Loop:       1,
		MissionID:  10001,
		TeamID:     1,
		Score:      9000,
		Profile:    d.ReportProfile{Name: "native", Level: 100, ConquerLevel: 1, ConquerLoop: 1, Server: 1, AvatarID: 110001001, FrameID: 2},
		Heroes:     json.RawMessage(`[10001001]`),
		Pet:        json.RawMessage(`{"id":50001}`),
		Body:       json.RawMessage(`{"fighter":{}}`),
		AttemptID:  "r8-2b-conquer-native-attempt",
		RecordedAt: now,
	}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InsertReportTx(ctx, tr, report, 3); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedProfile d.ReportProfile
	storedPayload(t, p, "conquer_school_reports", "profile", "report_key=$1::uuid", report.Key, &savedProfile)
	samePayload(t, report.Profile, savedProfile)
	read, found, err := store.ReportTx(ctx, p, report.Key)
	if err != nil || !found || read.Profile != report.Profile {
		t.Fatalf("ReportTx found=%v err=%v", found, err)
	}
	reports, err := store.ReportsTx(ctx, p, report.Loop, report.MissionID, report.TeamID, 3)
	if err != nil || len(reports) != 1 || reports[0].Profile != report.Profile {
		t.Fatalf("ReportsTx = %+v err=%v", reports, err)
	}
}
