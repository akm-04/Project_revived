//go:build postgres

package oneononestore_test

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/oneonone"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type oneOnOneFixture struct {
	transaction tx.Tx
	revision    string
}

func newOneOnOneFixture(t *testing.T) *oneOnOneFixture {
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
	fixture := &oneOnOneFixture{transaction: transaction}
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
	competition := d.Competition{ID: d.CompetitionID, ContentRevision: fixture.revision, StateVersion: 1, CreatedAt: time.Now().UTC(), UpdatedAt: time.Now().UTC()}
	if err := (oneononestore.Store{}).CreateCompetitionTx(ctx, transaction, competition); err != nil {
		t.Fatal(err)
	}
	return fixture
}

func (f *oneOnOneFixture) storedPayload(t *testing.T, sql string, args ...any) (string, int16) {
	t.Helper()
	var raw string
	var version int16
	if err := f.transaction.QueryRow(context.Background(), sql, args...).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	return raw, version
}

func requireVersionOne(t *testing.T, version int16) {
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

func newOneOnOnePlayer(id identity.PlayerID, revision string, at time.Time) d.Player {
	return d.Player{PlayerID: id, Server: 1, ContentRevision: revision,
		Position: d.Position{Level: d.LevelJunior3, Points: 4300, PointsAt: at},
		TriesDay: 1, TriesLeft: 10, OfferedDay: 1,
		Teams:         []d.Team{{Heroes: []int64{1}}, {Heroes: []int64{2}}, {Heroes: []int64{3}}},
		Offered:       []identity.PlayerID{100001},
		OfferSnapshot: &d.OfferSnapshot{Challenger: d.OfferRank{Global: 1, InGroup: 1}, Targets: []d.OfferTarget{{Player: 100001, OfferRank: d.OfferRank{Global: 2, InGroup: 2}}}},
		Mode:          d.ModePromotion, Candidates: []identity.PlayerID{100001},
		StateVersion: 1, CreatedAt: at, UpdatedAt: at}
}

func newOneOnOneMatch(t *testing.T, at time.Time) d.Match {
	t.Helper()
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return d.Match{ID: identifier, Attacker: 100002, Defender: 100001, Mode: d.ModeNormal, Fingerprint: fmt.Sprintf("%064x", 8),
		AttackTeams: []d.Team{{Heroes: []int64{1}}, {Heroes: []int64{2}}, {Heroes: []int64{3}}}, DefenseTeams: []d.Team{{Heroes: []int64{4}}},
		Rounds: []d.Round{{}, {}, {}}, StartedAt: at, Status: d.StatusStarted, StateVersion: 1}
}

func TestPayloadVersionRoundTripOneOnOneStore(t *testing.T) {
	ctx := context.Background()
	fixture := newOneOnOneFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := oneononestore.Store{}

	player := newOneOnOnePlayer(100001, fixture.revision, now)
	if err := store.InsertPlayerTx(ctx, fixture.transaction, player); err != nil {
		t.Fatal(err)
	}
	teams, offered, candidates, snapshot := "", "", "", ""
	version := int16(0)
	if err := fixture.transaction.QueryRow(ctx, `SELECT teams::text,offered::text,candidates::text,offer_snapshot::text,payload_version FROM one_on_one_players WHERE player_id=$1`, int64(player.PlayerID)).Scan(&teams, &offered, &candidates, &snapshot, &version); err != nil {
		t.Fatal(err)
	}
	requireVersionOne(t, version)
	requireSameJSON(t, teams, player.Teams)
	requireSameJSON(t, offered, player.Offered)
	requireSameJSON(t, candidates, player.Candidates)
	requireSameJSON(t, snapshot, player.OfferSnapshot)
	storedPlayer, _, found, err := store.ReadPlayerTx(ctx, fixture.transaction, player.PlayerID, false)
	if err != nil || !found || storedPlayer.StateVersion != player.StateVersion || storedPlayer.Position.Points != player.Position.Points ||
		!reflect.DeepEqual(storedPlayer.Teams, player.Teams) || !reflect.DeepEqual(storedPlayer.Offered, player.Offered) ||
		!reflect.DeepEqual(storedPlayer.Candidates, player.Candidates) || !reflect.DeepEqual(storedPlayer.OfferSnapshot, player.OfferSnapshot) {
		t.Fatalf("ReadPlayerTx payloads differ found=%v err=%v", found, err)
	}
	player.Position.Points, player.StateVersion, player.UpdatedAt = 4400, 2, now.Add(time.Minute)
	if err := store.SavePlayerTx(ctx, fixture.transaction, player, 1, d.Totals{}); err != nil {
		t.Fatal(err)
	}
	storedPlayer, _, found, err = store.ReadPlayerTx(ctx, fixture.transaction, player.PlayerID, false)
	if err != nil || !found || storedPlayer.StateVersion != 2 || !reflect.DeepEqual(storedPlayer.Teams, player.Teams) {
		t.Fatal("SavePlayerTx read back", found, err)
	}
	_, version = fixture.storedPayload(t, `SELECT teams::text,payload_version FROM one_on_one_players WHERE player_id=$1`, int64(player.PlayerID))
	requireVersionOne(t, version)

	defender := newOneOnOnePlayer(100002, fixture.revision, now)
	if err := store.InsertPlayerTx(ctx, fixture.transaction, defender); err != nil {
		t.Fatal(err)
	}
	match := newOneOnOneMatch(t, now)
	if err := store.InsertMatchTx(ctx, fixture.transaction, match); err != nil {
		t.Fatal(err)
	}
	attack, defense, version := "", "", int16(0)
	if err := fixture.transaction.QueryRow(ctx, `SELECT attack_teams::text,defense_teams::text,payload_version FROM one_on_one_matches WHERE match_id=$1`, match.ID.String()).Scan(&attack, &defense, &version); err != nil {
		t.Fatal(err)
	}
	requireVersionOne(t, version)
	requireSameJSON(t, attack, match.AttackTeams)
	requireSameJSON(t, defense, match.DefenseTeams)
	settledAt := now.Add(time.Minute)
	match.Status, match.Outcome, match.SettledAt, match.StateVersion = d.StatusSettled, &d.Outcome{Wins: []int64{1, 1}, Win: true}, &settledAt, 2
	if err := store.FinishMatchTx(ctx, fixture.transaction, match, 1); err != nil {
		t.Fatal(err)
	}
	outcome, version := "", int16(0)
	if err := fixture.transaction.QueryRow(ctx, `SELECT outcome::text,payload_version FROM one_on_one_matches WHERE match_id=$1`, match.ID.String()).Scan(&outcome, &version); err != nil {
		t.Fatal(err)
	}
	requireVersionOne(t, version)
	requireSameJSON(t, outcome, match.Outcome)
	storedMatch, found, err := store.ReadMatchTx(ctx, fixture.transaction, match.ID, false)
	if err != nil || !found || storedMatch.ID != match.ID || storedMatch.Status != match.Status || storedMatch.StateVersion != match.StateVersion ||
		!reflect.DeepEqual(storedMatch.AttackTeams, match.AttackTeams) || !reflect.DeepEqual(storedMatch.DefenseTeams, match.DefenseTeams) || !reflect.DeepEqual(storedMatch.Outcome, match.Outcome) {
		t.Fatal("ReadMatchTx payloads differ", found, err)
	}
	closed := newOneOnOneMatch(t, now.Add(-time.Minute))
	if err := store.InsertMatchTx(ctx, fixture.transaction, closed); err != nil {
		t.Fatal(err)
	}
	closedAt := now.Add(2 * time.Minute)
	closed.Status, closed.SettledAt, closed.StateVersion = d.StatusClosed, &closedAt, 2
	if err := store.FinishMatchTx(ctx, fixture.transaction, closed, 1); err != nil {
		t.Fatal(err)
	}
	var storedStatus string
	var outcomeNull bool
	if err := fixture.transaction.QueryRow(ctx, `SELECT status,outcome IS NULL,payload_version FROM one_on_one_matches WHERE match_id=$1`, closed.ID.String()).Scan(&storedStatus, &outcomeNull, &version); err != nil {
		t.Fatal(err)
	}
	if storedStatus != d.StatusClosed || !outcomeNull {
		t.Fatalf("closed match status=%s outcomeNull=%v", storedStatus, outcomeNull)
	}
	requireVersionOne(t, version)
	latest, found, err := store.LatestMatchTx(ctx, fixture.transaction, match.Attacker)
	if err != nil || !found || latest.ID != match.ID {
		t.Fatal("LatestMatchTx", found, err)
	}
	source, err := store.HeroRecommendSourceTx(ctx, fixture.transaction, 1, now, 10)
	if err != nil || len(source.Formations) == 0 {
		t.Fatal("HeroRecommendSourceTx", err)
	}
}
