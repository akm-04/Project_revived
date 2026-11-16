//go:build postgres

package illusionstore_test

import (
	"context"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/illusionstore"
	hr "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/illusion"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type illusionFixture struct {
	transaction tx.Tx
}

func newIllusionFixture(t *testing.T) *illusionFixture {
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
	for _, pid := range []identity.PlayerID{100001, 100002} {
		account, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO accounts(account_id,account_uid,status,created_at)VALUES($1,$2,'ACTIVE',now())`, account.String(), account.String()); err != nil {
			t.Fatal(err)
		}
		if _, err := transaction.Exec(ctx, `INSERT INTO players(player_id,account_id,logical_server_id,created_at,bootstrap_profile_version)VALUES($1,$2,1,now(),'recommend-native')`, int64(pid), account.String()); err != nil {
			t.Fatal(err)
		}
	}
	return &illusionFixture{transaction: transaction}
}

func TestHeroRecommendSourceIllusionReadsSQLRows(t *testing.T) {
	ctx := context.Background()
	fixture := newIllusionFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := illusionstore.Store{}

	attempts := []d.Attempt{
		{PlayerID: 100001, LogicalServerID: 1, OpenDay: 0, CampaignID: d.FirstCampaignID, Formation: "10001001|10001002", FrozenAt: now.Unix(), Resolved: true, Damage: 700},
		{PlayerID: 100002, LogicalServerID: 1, OpenDay: 0, CampaignID: d.FirstCampaignID, Formation: "10001002|10001003", FrozenAt: now.Unix(), Resolved: true, Damage: 900},
	}
	for index := range attempts {
		identifier, err := ids.NewUUID()
		if err != nil {
			t.Fatal(err)
		}
		attempts[index].ID = identifier.String()
		if err := store.InsertAttemptTx(ctx, fixture.transaction, attempts[index]); err != nil {
			t.Fatal(err)
		}
	}

	source, err := store.HeroRecommendSourceTx(ctx, fixture.transaction, 1, now, hr.MaxSourceScan)
	if err != nil {
		t.Fatal("HeroRecommendSourceTx", err)
	}
	wantFormations := []hr.Formation{
		{PlayerID: 100002, PartnerIDs: []int64{10001002, 10001003}, Weight: 900, ParadiseID: d.FirstCampaignID},
		{PlayerID: 100001, PartnerIDs: []int64{10001001, 10001002}, Weight: 700, ParadiseID: d.FirstCampaignID},
	}
	if !reflect.DeepEqual(source.Formations, wantFormations) {
		t.Fatalf("formations=%+v want %+v", source.Formations, wantFormations)
	}
	popularity := map[int64]hr.Popularity{}
	for _, row := range source.Popularity {
		popularity[row.PartnerID] = row
	}
	wantPopularity := map[int64]hr.Popularity{
		10001001: {PlayerID: 100001, PartnerID: 10001001, Score: 700},
		10001002: {PlayerID: 100002, PartnerID: 10001002, Score: 1600},
		10001003: {PlayerID: 100002, PartnerID: 10001003, Score: 900},
	}
	if !reflect.DeepEqual(popularity, wantPopularity) {
		t.Fatalf("popularity=%+v want %+v", popularity, wantPopularity)
	}
}
