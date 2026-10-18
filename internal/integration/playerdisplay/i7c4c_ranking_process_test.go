//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"encoding/json"
	"gxb.local/backend/v2/internal/adapters/blobstore"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/domain/identity"
	"net"
	"net/http"
	"net/url"
	"os"
	osexec "os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestI7C4CRankingActualAPIReopenRestartAndDatabaseRestore(t *testing.T) {
	binary := os.Getenv("GXB_I7B6A_API_BINARY")
	if binary == "" {
		t.Skip("exact working API binary required")
	}
	p := pool(t)
	rev := installed(t, p)
	server := rankingServer(t, p)
	a := rankingActor(t, p, server, true)
	b := rankingActor(t, p, server, true)
	// Genuine Character acquisition, with the diagnostic capacity authorizer
	// disclosed by rankingSummon; this is not production acquisition proof.
	rankingSummon(t, p, a, rev, 10001001)
	bearer := displayToken(t, p, a)
	original := op()
	first, e := rankingService(p, p).ReadGirls(ctx, a, original)
	if e != nil {
		t.Fatal(e)
	}
	listener, e := net.Listen("tcp", "127.0.0.1:0")
	if e != nil {
		t.Fatal(e)
	}
	addr := listener.Addr().String()
	listener.Close()
	origin := "http://" + addr
	targetDSN := os.Getenv("GXB_I7B6A_DSN")
	assets := filepath.Join(t.TempDir(), "private-media")
	if _, e := blobstore.NewLocal(assets); e != nil {
		t.Fatal(e)
	}
	start := func() *osexec.Cmd {
		cmd := osexec.Command(binary)
		cmd.Env = append(os.Environ(), "GXB_POSTGRES_DSN="+targetDSN, "GXB_HTTP_ADDR="+addr, "GXB_PUBLIC_ENGINE_URL="+origin+"/engine", "GXB_REALTIME_PUBLIC_HOST=127.0.0.1", "GXB_REALTIME_PUBLIC_PORT=19001", "GXB_CREDENTIAL_DIGEST_SECRET=i7b2b-fixture-digest-key-00001", "GXB_GAMEPLAY_BEARER_SECRET=i7b2b-fixture-bearer-key-00001", "GXB_REDEEM_DIGEST_SECRET=i7b5b-fixture-redeem-key-00001", "GXB_DERIVATION_KEY_ID=i7b2b-native", "GXB_PROFILE_MEDIA_ROOT="+assets, "GXB_PROFILE_MEDIA_PUBLIC_ORIGIN="+origin)
		log, e := os.CreateTemp(t.TempDir(), "api-log")
		if e != nil {
			t.Fatal(e)
		}
		t.Cleanup(func() { log.Close() })
		cmd.Stdout = log
		cmd.Stderr = log
		if e = cmd.Start(); e != nil {
			t.Fatal(e)
		}
		for end := time.Now().Add(10 * time.Second); time.Now().Before(end); {
			resp, e := http.Get(origin + "/profile-media/missing")
			if e == nil {
				resp.Body.Close()
				return cmd
			}
			time.Sleep(30 * time.Millisecond)
		}
		cmd.Process.Kill()
		cmd.Wait()
		raw, _ := os.ReadFile(log.Name())
		t.Fatal("startup", string(raw))
		return nil
	}
	post := func(mid int, fields map[string]any) (int, map[string]any) {
		fields["mid"] = mid
		fields["token"] = bearer
		fields["region"] = int64(a.LogicalServerID)
		raw, _ := json.Marshal(fields)
		resp, e := http.Post(origin+"/engine", "application/x-www-form-urlencoded", bytes.NewBufferString(url.Values{"payload": {string(raw)}}.Encode()))
		if e != nil {
			t.Fatal(e)
		}
		defer resp.Body.Close()
		var out map[string]any
		if e = json.NewDecoder(resp.Body).Decode(&out); e != nil {
			t.Fatal(e)
		}
		return resp.StatusCode, out
	}

	cmd := start()
	running := true
	stop := func() {
		if running {
			cmd.Process.Signal(os.Interrupt)
			cmd.Wait()
			running = false
		}
	}
	defer stop()
	board := func(want int64) {
		t.Helper()
		code, out := post(301, map[string]any{"rank_types": []int{37}})
		if code != 200 || out["error_code"] != float64(0) {
			t.Fatal("MID301", code, out)
		}
		raw, err := json.Marshal(out)
		if err != nil {
			t.Fatal(err)
		}
		t.Log("RANKING_SOURCE_RESPONSE", string(raw))
		list, ok := out["rank_list"].([]any)
		if !ok || len(list) != 1 {
			t.Fatal(out)
		}
		typ := list[0].(map[string]any)
		if typ["rank_type"] != float64(37) {
			t.Fatal(typ)
		}
		info := typ["rank_info"].(map[string]any)
		mine := info["my_rank"].(map[string]any)
		rows := info["rank_info"].([]any)
		if mine["rank"] != float64(1) || mine["score"] != float64(want) || len(rows) != 2 {
			t.Fatal(info)
		}
		row := rows[0].(map[string]any)
		if row["player_id"] != float64(a.PlayerID) || row["score"] != float64(want) || row["player_name"] != "Ranker" {
			t.Fatal(row)
		}
		for _, k := range []string{"policy", "source_versions", "population_digest", "content_revision", "generation"} {
			if row[k] != nil || info[k] != nil || out[k] != nil {
				t.Fatal("internal provenance leaked", k, out)
			}
		}
	}
	board(1)
	for _, fields := range []map[string]any{{"rank_types": []int{37, 38}}, {"rank_types": []int{16001}}, {"rank_types": []int{1001}}, {"rank_types": []int{37}, "player_id": int64(b.PlayerID)}} {
		code, out := post(301, fields)
		if code == 200 {
			t.Fatal("unsupported/mixed/forged ranking accepted", fields, out)
		}
	}
	if n := rankingCount(t, p, server, "ranking_girls_snapshots"); n != 2 {
		t.Fatal("invalid request mutated Ranking", n)
	}
	code, out := post(2492, map[string]any{"title_id": 100059, "unique_id": 0})
	if code != 200 {
		t.Fatal("genuine ranking title selection", code, out)
	}
	code, out = post(2490, map[string]any{})
	if code == 200 {
		t.Fatal("partial Girls owner opened whole family picker", out)
	}
	rankingSummon(t, p, a, rev, 10001002)
	board(2) // A new menu request observes the new canonical count.
	stop()
	cmd = start()
	running = true
	board(2)
	// Bind all durable Ranking and recipient/receipt state across relocation.
	snapshot, e := rankingService(p, p).RefreshGirls(ctx, a, original)
	if e != nil || !reflect.DeepEqual(snapshot, first) {
		t.Fatal("restart original receipt", e)
	}
	fingerprint := func(db *pg.Pool) string {
		t.Helper()
		var digest string
		e := db.QueryRow(ctx, `SELECT md5(coalesce(string_agg(v,E'\n' ORDER BY v),'')) FROM (
   SELECT 'root:'||to_jsonb(x)::text v FROM ranking_girls_roots x WHERE logical_server_id=$1
   UNION ALL SELECT 'snapshot:'||to_jsonb(x)::text FROM ranking_girls_snapshots x WHERE logical_server_id=$1
   UNION ALL SELECT 'period:'||to_jsonb(x)::text FROM ranking_girls_periods x WHERE logical_server_id=$1
   UNION ALL SELECT 'award:'||to_jsonb(x)::text FROM ranking_girls_awards x WHERE logical_server_id=$1
   UNION ALL SELECT 'birth:'||to_jsonb(x)::text FROM ranking_girls_birth_tracking x WHERE logical_server_id=$1
   UNION ALL SELECT 'recipient:'||to_jsonb(x)::text FROM player_cosmetic_entitlements x WHERE player_id=$2
  ) durable`, int64(server), int64(a.PlayerID)).Scan(&digest)
		if e != nil {
			t.Fatal(e)
		}
		return digest
	}
	before := fingerprint(p)
	stop()
	tool := func(name string, args ...string) {
		raw, e := osexec.Command(name, args...).CombinedOutput()
		if e != nil {
			t.Fatal(name, e, string(raw))
		}
	}
	dump := filepath.Join(t.TempDir(), "girls-ranking.dump")
	tool("pg_dump", "--format=custom", "--file", dump, targetDSN)
	u, e := url.Parse(targetDSN)
	if e != nil {
		t.Fatal(e)
	}
	newDB := "girls_restore_" + strings.ReplaceAll(uuid().String(), "-", "")
	tool("createdb", "--maintenance-db", targetDSN, newDB)
	u.Path = "/" + newDB
	targetDSN = u.String()
	tool("pg_restore", "--no-owner", "--dbname", targetDSN, dump)
	restored, e := pg.Open(ctx, targetDSN, pg.PoolSettings{MaxConns: 8, MaxConnLifetime: time.Hour, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Minute})
	if e != nil {
		t.Fatal(e)
	}
	defer restored.Close()
	if after := fingerprint(restored); after != before {
		t.Fatal("relocated durable state changed", before, after)
	}
	recovered, e := rankingService(restored, restored).ReadGirls(ctx, a, original)
	if e != nil || !reflect.DeepEqual(first, recovered) {
		t.Fatal("restored immutable snapshot/Kernel receipt", e)
	}
	if n := rankingCount(t, restored, server, "ranking_girls_awards"); n != 1 {
		t.Fatal("duplicate restored awards", n)
	}
	cmd = start()
	running = true
	board(2)
	code, out = post(2492, map[string]any{"title_id": 100059, "unique_id": 0})
	if code != 200 {
		t.Fatal("restored genuine title", code, out)
	}

	// Exercise the actual production MID1 fresh namespace, not a direct call to
	// the contributor. A required Ranking insertion failure must roll back I4.
	newAccount, newSession := uuid(), uuid()
	exec(t, restored, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp()-interval '1 hour')`, newAccount.String(), newAccount.String())
	exec(t, restored, `INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)VALUES($1,$2,$3,clock_timestamp()-interval '1 hour',clock_timestamp())`, newSession.String(), newAccount.String(), string(identity.AuthProductionPair))
	sidRaw, loginRaw := "ranking-sid-"+newSession.String(), "ranking-login-"+newSession.String()
	for _, c := range []struct{ kind, label, raw string }{{"SID", "sid", sidRaw}, {"LOGIN_TOKEN", "login_token", loginRaw}} {
		digest, e := identity.DigestCredential([]byte("i7b2b-fixture-digest-key-00001"), c.label, c.raw)
		if e != nil {
			t.Fatal(e)
		}
		exec(t, restored, `INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)VALUES($1,$2,$3,$4,clock_timestamp()-interval '1 minute')`, uuid().String(), newSession.String(), c.kind, digest[:])
	}
	code, out = post(18, map[string]any{"sid": sidRaw, "login_token": loginRaw})
	if code != 200 {
		t.Fatal("account observe", code, out)
	}
	var cursor int64
	if e = restored.QueryRow(ctx, `SELECT next_player_id FROM logical_servers WHERE logical_server_id=$1`, int64(server)).Scan(&cursor); e != nil {
		t.Fatal(e)
	}
	exec(t, restored, `CREATE FUNCTION ranking_reject_birth()RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'qualification Ranking birth failure'; END $$`)
	exec(t, restored, `CREATE TRIGGER ranking_reject_birth BEFORE INSERT ON ranking_girls_birth_tracking FOR EACH ROW EXECUTE FUNCTION ranking_reject_birth()`)
	code, out = post(1, map[string]any{"sid": sidRaw, "login_token": loginRaw})
	exec(t, restored, `DROP TRIGGER ranking_reject_birth ON ranking_girls_birth_tracking`)
	exec(t, restored, `DROP FUNCTION ranking_reject_birth()`)
	if code == 200 {
		t.Fatal("required Ranking birth failure ignored", out)
	}
	var n, next int64
	if e = restored.QueryRow(ctx, `SELECT count(*) FROM players WHERE account_id=$1`, newAccount.String()).Scan(&n); e != nil || n != 0 {
		t.Fatal("partial fresh player", n, e)
	}
	if e = restored.QueryRow(ctx, `SELECT next_player_id FROM logical_servers WHERE logical_server_id=$1`, int64(server)).Scan(&next); e != nil || next != cursor {
		t.Fatal("fresh allocation escaped rollback", cursor, next, e)
	}
	code, out = post(1, map[string]any{"sid": sidRaw, "login_token": loginRaw})
	if code != 200 || out["detail"] == nil {
		t.Fatal("production fresh MID1", code, out)
	}
	var born int64
	if e = restored.QueryRow(ctx, `SELECT player_id FROM players WHERE account_id=$1`, newAccount.String()).Scan(&born); e != nil {
		t.Fatal(e)
	}
	if e = restored.QueryRow(ctx, `SELECT count(*) FROM ranking_girls_birth_tracking WHERE player_id=$1 AND logical_server_id=$2`, born, int64(server)).Scan(&n); e != nil || n != 1 {
		t.Fatal("missing real fresh tracking", n, e)
	}
	code, out = post(1, map[string]any{"sid": sidRaw, "login_token": loginRaw})
	if code != 200 {
		t.Fatal("existing login", code, out)
	}
	if e = restored.QueryRow(ctx, `SELECT count(*) FROM ranking_girls_birth_tracking WHERE player_id=$1`, born).Scan(&n); e != nil || n != 1 {
		t.Fatal("login duplicated birth marker", n, e)
	}
	t.Log("ACTUAL_API_301_SERVER37_REOPEN_RESTART_RELOCATED_PG_RESTORE immutable snapshot receipt/weekly award/recipient provenance preserved; diagnostic acquisition capacity only; whole title picker remains gated", before)
}
