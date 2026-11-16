//go:build postgres

package leaguestore_test

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	app "gxb.local/backend/v2/internal/application/championsleague"
	"gxb.local/backend/v2/internal/application/playerdisplay"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type leagueFixture struct {
	transaction tx.Tx
	revision    string
}

func newLeagueFixture(t *testing.T) *leagueFixture {
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
	fixture := &leagueFixture{transaction: transaction}
	if err := transaction.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY installed_at DESC LIMIT 1`).Scan(&fixture.revision); err != nil {
		t.Fatal("content revision required:", err)
	}
	for _, pid := range []identity.PlayerID{190001, 190002} {
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

func (f *leagueFixture) storedPayload(t *testing.T, sql string, args ...any) (string, int16) {
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

func (f *leagueFixture) insertAttempt(t *testing.T, actor identity.PlayerID, token string, at time.Time) ids.UUID {
	t.Helper()
	ctx := context.Background()
	attempt, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	gameplayContext, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	domainLocator := "league-payload-probe-" + token
	snapshotHash := fmt.Sprintf("%064x", len(token))
	rulesCorpus := "d" + snapshotHash[1:]
	startFingerprint := "e" + snapshotHash[1:]
	if _, err := f.transaction.Exec(ctx, `INSERT INTO combat_locator_roots(domain_kind,authority_scope,domain_locator)VALUES('championsleague','GLOBAL',$1)`, domainLocator); err != nil {
		t.Fatal(err)
	}
	if _, err := f.transaction.Exec(ctx, `INSERT INTO combat_snapshots(snapshot_hash,content_revision,rules_corpus_id,canonical)VALUES($1,$2,$3,'\x0001'::bytea)`, snapshotHash, f.revision, rulesCorpus); err != nil {
		t.Fatal(err)
	}
	if _, err := f.transaction.Exec(ctx, `INSERT INTO combat_attempts(attempt_id,domain_kind,authority_scope,domain_locator,actor_player_id,gameplay_context_id,generation_ref,start_fingerprint,trust_profile_id,trust_profile_version,snapshot_hash,rules_corpus_version,entropy_policy_version,entropy_key_version,resolver_status,state,started_at,result_deadline,state_version)VALUES($1,'championsleague','GLOBAL',$2,$3,$4,'payload-probe',$5,'SERVER_REPORT_AUTHORITATIVE_V1',1,$6,$7,'HMAC_SHA256_COUNTER_LUA_RANDOM_COMPAT_V1','payload-probe-key','PENDING','STAGED',$8,$9,1)`,
		attempt.String(), domainLocator, int64(actor), gameplayContext.String(), startFingerprint, snapshotHash, rulesCorpus, at, at.Add(time.Hour)); err != nil {
		t.Fatal(err)
	}
	return attempt
}

func newLeaguePlayer(id, server int64, revision string, at time.Time) d.Player {
	return d.Player{ID: identity.PlayerID(id), Server: identity.LogicalServerID(server), Season: 1, Group: 3, Points: 1000, ScoreAt: at,
		Tie: fmt.Sprintf("%064x", id), Defense: d.Lineup{Heroes: []int64{10001001}}, Intent: 1, Version: 1, CreatedAt: at, UpdatedAt: at}
}

func newLeagueMatch(t *testing.T, attacker, defender identity.PlayerID, attempt ids.UUID, revision string, at time.Time) d.Match {
	t.Helper()
	identifier, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	return d.Match{ID: identifier, Attacker: attacker, Defender: defender, Intent: 1, Season: 1, Group: 3,
		Fingerprint: fmt.Sprintf("%064x", 7), Revision: revision, Status: "FIGHTING", Attempt: attempt,
		Attack: d.Lineup{Heroes: []int64{10001001}}, Defense: d.Lineup{Heroes: []int64{10001002}}, StartedAt: at, Version: 1}
}

func TestPayloadVersionRoundTripLeagueStore(t *testing.T) {
	ctx := context.Background()
	fixture := newLeagueFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := leaguestore.Store{}

	root := d.Root{Revision: fixture.revision, Season: 1, Day: 1, Version: 1, CreatedAt: now, UpdatedAt: now}
	if err := store.PutRootTx(ctx, fixture.transaction, root, 0); err != nil {
		t.Fatal(err)
	}
	raw, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_competitions WHERE competition_id='GLOBAL'`)
	requireVersionOne(t, version)
	requireSameJSON(t, raw, root)
	storedRoot, found, err := store.RootTx(ctx, fixture.transaction, false)
	if err != nil || !found || !reflect.DeepEqual(storedRoot, root) {
		t.Fatal("RootTx payload differs", found, err)
	}

	first := newLeaguePlayer(190001, 1, fixture.revision, now)
	second := newLeaguePlayer(190002, 1, fixture.revision, now)
	for _, player := range []d.Player{first, second} {
		if err := store.PutPlayerTx(ctx, fixture.transaction, player, 0); err != nil {
			t.Fatal(err)
		}
		raw, version = fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_players WHERE player_id=$1`, int64(player.ID))
		requireVersionOne(t, version)
		requireSameJSON(t, raw, player)
	}
	storedPlayers, err := store.PlayersTx(ctx, fixture.transaction, false)
	if err != nil || !reflect.DeepEqual(storedPlayers, []d.Player{first, second}) {
		t.Fatal("PlayersTx payloads differ", err)
	}

	settledAttempt := fixture.insertAttempt(t, first.ID, "settled", now)
	settled := newLeagueMatch(t, first.ID, second.ID, settledAttempt, fixture.revision, now)
	if _, err := store.PutMatchTx(ctx, fixture.transaction, settled, 0); err != nil {
		t.Fatal(err)
	}
	storedSettled, found, err := store.MatchTx(ctx, fixture.transaction, settled.ID)
	if err != nil || !found {
		t.Fatal("MatchTx", found, err)
	}
	settledAt := now.Add(time.Minute)
	storedSettled.Status, storedSettled.SettledAt, storedSettled.Version = "SETTLED", &settledAt, 2
	if _, err := store.PutMatchTx(ctx, fixture.transaction, storedSettled, 1); err != nil {
		t.Fatal(err)
	}
	raw, version = fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_matches WHERE match_id=$1`, settled.ID.String())
	requireVersionOne(t, version)
	requireSameJSON(t, raw, storedSettled)
	storedSettled, found, err = store.MatchTx(ctx, fixture.transaction, settled.ID)
	if err != nil || !found || !reflect.DeepEqual(storedSettled, settledMatch(t, raw)) {
		t.Fatal("MatchTx payload differs", found, err)
	}
	if byIntent, found, err := store.IntentTx(ctx, fixture.transaction, first.ID, 1); err != nil || !found || byIntent.ID != settled.ID {
		t.Fatal("IntentTx", found, err)
	}
	records, err := store.RecordsTx(ctx, fixture.transaction, first.ID)
	if err != nil || len(records) != 1 || records[0].ID != settled.ID {
		t.Fatal("RecordsTx", err)
	}

	fightingAttempt := fixture.insertAttempt(t, second.ID, "fighting", now)
	fighting := newLeagueMatch(t, second.ID, first.ID, fightingAttempt, fixture.revision, now)
	if _, err := store.PutMatchTx(ctx, fixture.transaction, fighting, 0); err != nil {
		t.Fatal(err)
	}
	open, err := store.OpenTx(ctx, fixture.transaction, 10)
	if err != nil || len(open) != 1 || open[0].ID != fighting.ID {
		t.Fatal("OpenTx", err)
	}

	settlement := d.Settlement{Kind: "DAY", Number: 1, CutoffAt: now, SettledAt: now, Revision: fixture.revision,
		Rows: []d.SettlementRow{{Player: first.ID, Placement: d.Placement{Group: 3, Rank: 1, Points: 1000, ScoreAt: now, Tie: first.Tie, Participated: true}}}}
	if err := store.PutSettlementTx(ctx, fixture.transaction, settlement); err != nil {
		t.Fatal(err)
	}
	raw, version = fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_settlements WHERE kind='DAY' AND number=1`)
	requireVersionOne(t, version)
	requireSameJSON(t, raw, settlement)
	storedSettlement, found, err := store.SettlementTx(ctx, fixture.transaction, "DAY", 1)
	if err != nil || !found || !reflect.DeepEqual(storedSettlement, settlement) {
		t.Fatal("SettlementTx payload differs", found, err)
	}

	award := app.OriginAward{Origin: playerdisplay.Origin{PlayerID: first.ID, Key: "league:payload-probe", Owner: "ChampionsLeague", Family: "title", CatalogID: 1, Revision: fixture.revision, StateVersion: 1},
		Season: 1, Placement: d.Placement{Group: 3, Rank: 1, Points: 1000, ScoreAt: now, Tie: first.Tie, Participated: true}, Count: 1}
	if err := store.PutOriginTx(ctx, fixture.transaction, award); err != nil {
		t.Fatal(err)
	}
	raw, version = fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_cosmetic_origins WHERE player_id=$1`, int64(first.ID))
	requireVersionOne(t, version)
	requireSameJSON(t, raw, award)
	origins, err := store.OriginsTx(ctx, fixture.transaction, first.ID)
	if err != nil || !reflect.DeepEqual(origins, []app.OriginAward{award}) {
		t.Fatal("OriginsTx payloads differ", err)
	}
}

func settledMatch(t *testing.T, raw string) d.Match {
	t.Helper()
	var match d.Match
	if err := payload.Decode("league_matches", payload.Current, []byte(raw), &match); err != nil {
		t.Fatal(err)
	}
	return match
}
