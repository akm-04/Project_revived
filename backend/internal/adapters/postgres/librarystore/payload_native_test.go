//go:build postgres

package librarystore_test

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/application/librarylocal"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/payload"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func storedPayload[T any](t *testing.T, p *pg.Pool, table, column, where string, out *T, args ...any) []byte {
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
	return accountUID
}

func TestPayloadVersionRoundTripLibraryStore(t *testing.T) {
	dsn := os.Getenv("GXB_R8_2B_DSN")
	if dsn == "" {
		t.Skip("GXB_R8_2B_DSN required")
	}
	ctx := context.Background()
	p, err := pg.Open(ctx, dsn, pg.PoolSettings{MaxConns: 4, MaxConnLifetime: time.Minute, MaxConnIdleTime: time.Minute, HealthCheckPeriod: time.Second, ApplicationName: "r8-2b-librarystore-native"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(p.Close)
	store := librarystore.Store{}
	pid := identity.PlayerID(113024)
	bootstrapPID := identity.PlayerID(113025)
	accountUID := seedR82Player(t, p, pid, "library-native")
	bootstrapUID := seedR82Player(t, p, bootstrapPID, "library-bootstrap-native")
	t.Cleanup(func() {
		cleanup := context.Background()
		for _, player := range []identity.PlayerID{pid, bootstrapPID} {
			pool := p.Raw()
			pool.Exec(cleanup, `DELETE FROM player_library_hero_logs WHERE player_id=$1`, int64(player))
			pool.Exec(cleanup, `DELETE FROM player_library_admissions WHERE player_id=$1`, int64(player))
			pool.Exec(cleanup, `DELETE FROM player_library_heroes WHERE player_id=$1`, int64(player))
			pool.Exec(cleanup, `DELETE FROM player_library_roots WHERE player_id=$1`, int64(player))
			pool.Exec(cleanup, `DELETE FROM players WHERE player_id=$1`, int64(player))
		}
		pool := p.Raw()
		pool.Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, accountUID)
		pool.Exec(cleanup, `DELETE FROM accounts WHERE account_uid=$1`, bootstrapUID)
	})
	now := time.Now().UTC().Truncate(time.Microsecond)
	ref := character.HeroRef{PlayerID: pid, PartnerID: 1}

	tr, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	if err = store.EnsurePlayerRootTx(ctx, tr, pid, now); err != nil {
		t.Fatal(err)
	}
	if err = store.InitFreshHeroTx(ctx, tr, ref, now); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	fresh, err := library.NewPlayerFacts(pid, now)
	if err != nil {
		t.Fatal(err)
	}
	var claims []bool
	storedPayload(t, p, "player_library_roots", "special_claims", "player_id=$1", &claims, int64(pid))
	samePayload(t, fresh.SpecialClaims, claims)
	var attrs []int64
	storedPayload(t, p, "player_library_heroes", "feed_attrs", "player_id=$1 AND partner_id=$2", &attrs, int64(pid), ref.PartnerID)
	samePayload(t, library.FeedAttrs{}, attrs)

	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	root, err := store.LockRootTx(ctx, tr, pid)
	if err != nil {
		t.Fatal(err)
	}
	root.SpecialClaims[3] = true
	root.StateVersion++
	root.UpdatedAt = now.Add(time.Second)
	if err = store.SavePlayerTx(ctx, tr, root, root.StateVersion-1); err != nil {
		t.Fatal(err)
	}
	hero, err := store.LockHeroTx(ctx, tr, ref)
	if err != nil {
		t.Fatal(err)
	}
	hero.Favor = library.FavorLimit
	hero.Married = true
	original := hero.StateVersion
	operationID, err := ids.ParseUUID("12345678-1234-4234-8234-123456789012")
	if err != nil {
		t.Fatal(err)
	}
	candidate := library.Candidate{OperationID: operationID, Revision: original + 1, PolicyVersion: library.FeedPolicyV1, ContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", Base: library.FeedAttrs{}, Proposed: library.FeedAttrs{60, 5, 5, 2, 2, 2}, Delta: library.FeedAttrs{60, 5, 5, 2, 2, 2}, CreatedAt: now.Add(time.Second)}
	preview, err := hero.WithPreview(candidate, candidate.CreatedAt)
	if err != nil {
		t.Fatal(err)
	}
	if err = store.SaveHeroTx(ctx, tr, preview, original); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	storedPayload(t, p, "player_library_roots", "special_claims", "player_id=$1", &claims, int64(pid))
	samePayload(t, root.SpecialClaims, claims)
	var savedAttrs []int64
	storedPayload(t, p, "player_library_heroes", "feed_attrs", "player_id=$1 AND partner_id=$2", &savedAttrs, int64(pid), ref.PartnerID)
	samePayload(t, preview.Applied, savedAttrs)
	var savedCandidate library.Candidate
	storedPayload(t, p, "player_library_heroes", "pending_candidate", "player_id=$1 AND partner_id=$2", &savedCandidate, int64(pid), ref.PartnerID)
	samePayload(t, *preview.Pending, savedCandidate)

	readRoot, err := store.ReadRootTx(ctx, p, pid)
	if err != nil {
		t.Fatal(err)
	}
	samePayload(t, root.SpecialClaims, readRoot.SpecialClaims)
	readHero, err := store.ReadHeroTx(ctx, p, ref)
	if err != nil {
		t.Fatal(err)
	}
	samePayload(t, preview.Applied, readHero.Applied)
	samePayload(t, *preview.Pending, *readHero.Pending)
	heroes, err := store.ListHeroesTx(ctx, p, pid)
	if err != nil {
		t.Fatal(err)
	}
	if len(heroes) != 1 {
		t.Fatalf("ListHeroesTx returned %d heroes", len(heroes))
	}
	samePayload(t, preview.Applied, heroes[0].Applied)
	samePayload(t, *preview.Pending, *heroes[0].Pending)

	policies, err := policy.NewSet(policy.Ref{Name: "content", Version: candidate.ContentRevision}, policy.Ref{Name: "library", Version: librarylocal.LifecyclePolicy})
	if err != nil {
		t.Fatal(err)
	}
	admission := librarylocal.Admission{
		Operation:       operation.Context{ID: operationID, StartedAt: now, Policies: policies},
		DecisionAt:      now,
		Actor:           librarylocal.DurableActor{AccountUID: accountUID, Server: 1, Player: int64(pid)},
		Command:         librarylocal.Command{Family: librarylocal.Gift, PartnerID: 1, Value: 100, Quantity: 1},
		ContentRevision: candidate.ContentRevision,
		State:           "COMMITTED",
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
	var storedAdmission librarylocal.Admission
	storedPayload(t, p, "player_library_admissions", "operation_context", "player_id=$1 AND family=$2", &storedAdmission, int64(pid), librarylocal.Gift)
	samePayload(t, admission, storedAdmission)
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	locked, ok, err := store.LockAdmissionTx(ctx, tr, pid, librarylocal.Gift)
	if err != nil {
		t.Fatal(err)
	}
	if err = tr.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if !ok {
		t.Fatal("LockAdmissionTx lost the admission")
	}
	samePayload(t, admission, locked)

	contributor := librarystore.BootstrapContributor{}
	tr, err = p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	bootstrapContext := logicalserver.BootstrapContext{PlayerID: bootstrapPID, Operation: operation.Context{StartedAt: now}}
	if err = contributor.PersistCharacterBootstrap(ctx, tr, bootstrapContext); err != nil {
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	bootstrapFacts, err := library.NewPlayerFacts(bootstrapPID, now)
	if err != nil {
		t.Fatal(err)
	}
	storedPayload(t, p, "player_library_roots", "special_claims", "player_id=$1", &claims, int64(bootstrapPID))
	samePayload(t, bootstrapFacts.SpecialClaims, claims)
}
