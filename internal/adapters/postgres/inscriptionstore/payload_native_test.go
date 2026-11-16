//go:build postgres

package inscriptionstore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	app "gxb.local/backend/v2/internal/application/inscription"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	inscription "gxb.local/backend/v2/internal/domain/inscription"
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
			`DELETE FROM player_inscription_admissions WHERE player_id=$1`,
			`DELETE FROM player_inscription_heroes WHERE player_id=$1`,
			`DELETE FROM player_inscription_roots WHERE player_id=$1`,
		} {
			pool.Raw().Exec(cleanup, query, int64(pid))
		}
		pool.Raw().Exec(cleanup, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		pool.Raw().Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, accountUID)
	})
	return accountUID
}

func TestPayloadVersionRoundTripInscriptionStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-inscriptionstore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	store := inscriptionstore.Store{}
	pid := identity.PlayerID(112015)
	accountUID := seedR82Player(t, p, pid, "inscription-native")
	now := time.Now().UTC().Truncate(time.Second)
	var revision string
	if err = p.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY revision_id LIMIT 1`).Scan(&revision); err != nil {
		t.Fatal(err)
	}

	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.EnsureRootTx(ctx, tr, pid, revision, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var insertedRoot inscription.State
	storedPayload(t, p, "player_inscription_roots", "facts", "player_id=$1", int64(pid), &insertedRoot)
	samePayload(t, inscription.Seed(), insertedRoot)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	root, err := store.LockRootTx(ctx, tr, pid)
	if err != nil {
		t.Fatal(err)
	}
	root.Facts.ForgeMisses, root.Facts.ReforgeMisses, root.Facts.Generation = 7, 2, 4
	root.Version, root.UpdatedAt = 2, now
	if err = store.SaveRootTx(ctx, tr, root, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedRoot inscription.State
	storedPayload(t, p, "player_inscription_roots", "facts", "player_id=$1", int64(pid), &savedRoot)
	samePayload(t, root.Facts, savedRoot)
	if read, err := store.ReadRootTx(ctx, p, pid); err != nil || read.Facts != savedRoot {
		t.Fatalf("ReadRootTx facts=%+v err=%v", read.Facts, err)
	}

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.EnsureHeroTx(ctx, tr, pid, 1, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var insertedHero inscription.HeroFacts
	storedPayload(t, p, "player_inscription_heroes", "facts", "player_id=$1 AND partner_id=1", int64(pid), &insertedHero)
	samePayload(t, inscription.SeedHero(), insertedHero)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	hero, err := store.LockHeroTx(ctx, tr, pid, 1)
	if err != nil {
		t.Fatal(err)
	}
	hero.Facts.Slots = [3]int64{160100101, 0, 160100102}
	hero.Version, hero.UpdatedAt = 2, now
	if err = store.SaveHeroTx(ctx, tr, hero, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedHero inscription.HeroFacts
	storedPayload(t, p, "player_inscription_heroes", "facts", "player_id=$1 AND partner_id=1", int64(pid), &savedHero)
	samePayload(t, hero.Facts, savedHero)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InitFreshHeroTx(ctx, tr, character.HeroRef{PlayerID: pid, PartnerID: 2}, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var freshHero inscription.HeroFacts
	storedPayload(t, p, "player_inscription_heroes", "facts", "player_id=$1 AND partner_id=2", int64(pid), &freshHero)
	samePayload(t, inscription.SeedHero(), freshHero)

	heroes, err := store.ListHeroesTx(ctx, p, pid)
	if err != nil || len(heroes) != 2 {
		t.Fatalf("ListHeroesTx = %+v err=%v", heroes, err)
	}
	samePayload(t, hero.Facts, heroes[0].Facts)
	samePayload(t, inscription.SeedHero(), heroes[1].Facts)

	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: revision}, policy.Ref{Name: "inscription", Version: app.LifecyclePolicy})
	if err != nil {
		t.Fatal(err)
	}
	operationID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	account, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	session, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	contextID, err := ids.NewUUID()
	if err != nil {
		t.Fatal(err)
	}
	admission := app.Admission{
		Operation:       operation.Context{ID: operationID, StartedAt: now, Policies: policies},
		DecisionAt:      now,
		Actor:           app.DurableActor{Account: account, Session: session, Context: contextID, AccountUID: accountUID, Server: 1, Player: int64(pid), Generation: 1, SessionVersion: 1, ContextVersion: 1},
		Command:         app.Command{Family: app.Rebuild, ItemID: 160100101, Amount: 10, CostType: 1},
		ContentRevision: revision,
		State:           "PENDING",
	}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SaveAdmissionTx(ctx, tr, admission); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var savedAdmission app.Admission
	storedPayload(t, p, "player_inscription_admissions", "operation_context", "player_id=$1 AND family='INSCRIPTION'", int64(pid), &savedAdmission)
	samePayload(t, admission, savedAdmission)
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, found, err := store.LockAdmissionTx(ctx, tr, pid, "INSCRIPTION")
	if err != nil || !found || locked.Operation.ID != operationID {
		t.Fatalf("LockAdmissionTx found=%v id=%s err=%v", found, locked.Operation.ID, err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
}
