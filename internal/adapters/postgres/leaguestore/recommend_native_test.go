//go:build postgres

package leaguestore_test

import (
	"context"
	"reflect"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/leaguestore"
	d "gxb.local/backend/v2/internal/domain/championsleague"
	hr "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestHeroRecommendSourceLeagueReadsSQLRows(t *testing.T) {
	ctx := context.Background()
	fixture := newLeagueFixture(t)
	now := time.Now().UTC().Truncate(time.Second)
	store := leaguestore.Store{}

	root := d.Root{Revision: fixture.revision, Season: 1, Day: 1, Version: 1, CreatedAt: now, UpdatedAt: now}
	if err := store.PutRootTx(ctx, fixture.transaction, root, 0); err != nil {
		t.Fatal(err)
	}
	first := newLeaguePlayer(190001, 1, fixture.revision, now)
	second := newLeaguePlayer(190002, 1, fixture.revision, now)
	for _, player := range []d.Player{first, second} {
		if err := store.PutPlayerTx(ctx, fixture.transaction, player, 0); err != nil {
			t.Fatal(err)
		}
		_, version := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_players WHERE player_id=$1`, int64(player.ID))
		if version != payload.Current {
			t.Fatalf("league_players payload_version=%d want %d", version, payload.Current)
		}
	}

	settledAt := now.Add(time.Minute)
	attempt := fixture.insertAttempt(t, first.ID, "recommend-settled", now)
	match := newLeagueMatch(t, first.ID, second.ID, attempt, fixture.revision, now)
	match.Status, match.SettledAt = "SETTLED", &settledAt
	if _, err := store.PutMatchTx(ctx, fixture.transaction, match, 0); err != nil {
		t.Fatal(err)
	}
	_, matchVersion := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_matches WHERE match_id=$1`, match.ID.String())
	if matchVersion != payload.Current {
		t.Fatalf("league_matches payload_version=%d want %d", matchVersion, payload.Current)
	}

	// A pre-R8 row is the same writer bytes with payload_version left at 0; the R8 migration is metadata only.
	if _, err := fixture.transaction.Exec(ctx, `UPDATE league_players SET payload_version=0 WHERE player_id=$1`, int64(first.ID)); err != nil {
		t.Fatal(err)
	}
	_, legacyVersion := fixture.storedPayload(t, `SELECT payload::text,payload_version FROM league_players WHERE player_id=$1`, int64(first.ID))
	if legacyVersion != 0 {
		t.Fatalf("legacy league_players payload_version=%d want 0", legacyVersion)
	}

	source, err := store.HeroRecommendSourceTx(ctx, fixture.transaction, 1, now, hr.MaxSourceScan)
	if err != nil {
		t.Fatal("HeroRecommendSourceTx", err)
	}
	wantFormations := []hr.Formation{
		{PlayerID: 190001, PartnerIDs: []int64{10001001}, Weight: 1000},
		{PlayerID: 190002, PartnerIDs: []int64{10001001}, Weight: 1000},
	}
	if !reflect.DeepEqual(source.Formations, wantFormations) {
		t.Fatalf("formations=%+v want %+v", source.Formations, wantFormations)
	}
	wantPopularity := []hr.Popularity{{PlayerID: 190001, PartnerID: 10001001, Score: 1}}
	if !reflect.DeepEqual(source.Popularity, wantPopularity) {
		t.Fatalf("popularity=%+v want %+v", source.Popularity, wantPopularity)
	}
}
