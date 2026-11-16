//go:build postgres

package coursestore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	app "gxb.local/backend/v2/internal/application/course"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func storedPayload[T any](t *testing.T, p *pg.Pool, table, column, where string, out *T, args ...any) {
	t.Helper()
	var raw []byte
	var version int16
	if err := p.QueryRow(context.Background(), `SELECT `+column+`::text,payload_version FROM `+table+` WHERE `+where, args...).Scan(&raw, &version); err != nil {
		t.Fatal(err)
	}
	if version != payload.Current {
		t.Fatalf("%s.%s payload_version=%d want %d", table, column, version, payload.Current)
	}
	if err := payload.Decode(table, version, raw, out); err != nil {
		t.Fatalf("%s.%s strict decode: %v", table, column, err)
	}
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

func TestPayloadVersionRoundTripCourseStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-coursestore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	var rev string
	if err = p.QueryRow(ctx, `SELECT revision_id FROM gxb_content_revisions ORDER BY revision_id LIMIT 1`).Scan(&rev); err != nil {
		t.Fatal(err)
	}
	pid := identity.PlayerID(110002)
	accountID, _ := ids.NewUUID()
	if _, err = p.Raw().Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',clock_timestamp())`, accountID.String(), accountID.String()); err != nil {
		t.Fatal(err)
	}
	if _, err = p.Raw().Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,clock_timestamp(),'r8-2b-native')`, int64(pid), accountID.String()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		p.Raw().Exec(ctx, `DELETE FROM player_course_admissions WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM player_course_heroes WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM player_course_roots WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM players WHERE player_id=$1`, int64(pid))
		p.Raw().Exec(ctx, `DELETE FROM accounts WHERE account_id=$1`, accountID.String())
	})
	store := coursestore.Store{Queryer: p}
	at := time.Now().UTC().Add(-time.Hour)
	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.EnsureRootTx(ctx, tr, pid, rev, at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var seed course.State
	storedPayload(t, p, "player_course_roots", "facts", "player_id=$1", &seed, int64(pid))
	samePayload(t, course.Seed(), seed)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	root, err := store.LockRootTx(ctx, tr, pid)
	if err != nil {
		t.Fatal(err)
	}
	root.Facts.Logs = append(root.Facts.Logs, course.Log{PartnerID: 1, CourseID: 1, Kind: 2, At: 123, Param: 4})
	root.Version++
	root.UpdatedAt = at.Add(time.Second)
	if err = store.SaveRootTx(ctx, tr, root, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var rootFacts course.State
	storedPayload(t, p, "player_course_roots", "facts", "player_id=$1", &rootFacts, int64(pid))
	samePayload(t, root.Facts, rootFacts)
	if _, err = store.ReadRootTx(ctx, p, pid); err != nil {
		t.Fatal(err)
	}

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.EnsureHeroTx(ctx, tr, pid, 1, at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var heroSeed course.HeroFacts
	storedPayload(t, p, "player_course_heroes", "facts", "player_id=$1", &heroSeed, int64(pid))
	samePayload(t, course.SeedHero(), heroSeed)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.InitFreshHeroTx(ctx, tr, character.HeroRef{PlayerID: pid, PartnerID: 2}, at); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var secondHero course.HeroFacts
	storedPayload(t, p, "player_course_heroes", "facts", "player_id=$1 AND partner_id=2", &secondHero, int64(pid))
	samePayload(t, course.SeedHero(), secondHero)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	hero, err := store.LockHeroTx(ctx, tr, pid, 1)
	if err != nil {
		t.Fatal(err)
	}
	hero.Facts.Courses = append(hero.Facts.Courses, course.Record{ID: 1, Progress: 100, Quality: 1, Skill: 0, EXP: 100})
	hero.Version++
	hero.UpdatedAt = at.Add(time.Second)
	if err = store.SaveHeroTx(ctx, tr, hero, 1); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var heroFacts course.HeroFacts
	storedPayload(t, p, "player_course_heroes", "facts", "player_id=$1 AND partner_id=1", &heroFacts, int64(pid))
	samePayload(t, hero.Facts, heroFacts)
	heroes, err := store.ListHeroesTx(ctx, p, pid)
	if err != nil || len(heroes) != 2 || len(heroes[0].Facts.Courses) != 1 {
		t.Fatalf("ListHeroesTx heroes=%d err=%v", len(heroes), err)
	}

	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: rev}, policy.Ref{Name: "course", Version: app.LifecyclePolicy})
	if err != nil {
		t.Fatal(err)
	}
	operationID, _ := ids.NewUUID()
	admission := app.Admission{
		Operation:       operation.Context{ID: operationID, StartedAt: at, Policies: policies},
		DecisionAt:      at,
		Actor:           app.DurableActor{Account: accountID, Session: operationID, Context: operationID, AccountUID: accountID.String(), Server: 1, Player: int64(pid), Generation: 1, SessionVersion: 1, ContextVersion: 1},
		Command:         app.Command{Family: app.Collect, PartnerID: 1, CourseID: 1},
		ContentRevision: rev,
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
	var decoded app.Admission
	storedPayload(t, p, "player_course_admissions", "operation_context", "player_id=$1", &decoded, int64(pid))
	samePayload(t, admission, decoded)
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, exists, err := store.LockAdmissionTx(ctx, tr, pid, app.Collect)
	if err != nil || !exists || locked.Operation.ID != operationID {
		t.Fatalf("LockAdmissionTx exists=%v id=%s err=%v", exists, locked.Operation.ID, err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
}
