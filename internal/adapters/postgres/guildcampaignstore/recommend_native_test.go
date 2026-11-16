//go:build postgres

package guildcampaignstore_test

import (
	"context"
	"encoding/json"
	"os"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/guildcampaignstore"
	d "gxb.local/backend/v2/internal/domain/guildcampaign"
	hr "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type guildCampaignFixture struct {
	transaction tx.Tx
}

func newGuildCampaignFixture(t *testing.T) *guildCampaignFixture {
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
	return &guildCampaignFixture{transaction: transaction}
}

func TestHeroRecommendSourceGuildCampaignReadsSQLRows(t *testing.T) {
	ctx := context.Background()
	fixture := newGuildCampaignFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := guildcampaignstore.Store{}

	chapter := d.Chapter{GuildID: 900001, ChapterID: 7001, Run: 1, StartTime: now}
	copies := []d.Copy{{GuildID: chapter.GuildID, ChapterID: chapter.ChapterID, CopyID: 1, Run: chapter.Run, Waves: json.RawMessage(`[]`)}}
	if err := store.BeginRunTx(ctx, fixture.transaction, chapter, copies, nil); err != nil {
		t.Fatal(err)
	}
	records := []struct {
		player   identity.PlayerID
		damage   int64
		partners string
		at       time.Time
	}{
		{100001, 500, `[10001001,10001002]`, now},
		{100002, 900, `[10001002]`, now.Add(time.Minute)},
	}
	for _, record := range records {
		if err := store.UpsertServerRecordTx(ctx, fixture.transaction, 1, chapter.ChapterID-7000, int64(record.player), chapter.GuildID, record.damage, []byte(record.partners), record.at); err != nil {
			t.Fatal(err)
		}
	}

	source, err := store.HeroRecommendSourceTx(ctx, fixture.transaction, 1, now, hr.MaxSourceScan)
	if err != nil {
		t.Fatal("HeroRecommendSourceTx", err)
	}
	wantFormations := []hr.Formation{
		{PlayerID: 100002, PartnerIDs: []int64{10001002}, Weight: 900, ChapterID: chapter.ChapterID},
		{PlayerID: 100001, PartnerIDs: []int64{10001001, 10001002}, Weight: 500, ChapterID: chapter.ChapterID},
	}
	if !reflect.DeepEqual(source.Formations, wantFormations) {
		t.Fatalf("formations=%+v want %+v", source.Formations, wantFormations)
	}
	popularity := map[int64]hr.Popularity{}
	for _, row := range source.Popularity {
		popularity[row.PartnerID] = row
	}
	wantPopularity := map[int64]hr.Popularity{
		10001001: {PlayerID: 100001, PartnerID: 10001001, Score: 500},
		10001002: {PlayerID: 100002, PartnerID: 10001002, Score: 1400},
	}
	if !reflect.DeepEqual(popularity, wantPopularity) {
		t.Fatalf("popularity=%+v want %+v", popularity, wantPopularity)
	}
}
