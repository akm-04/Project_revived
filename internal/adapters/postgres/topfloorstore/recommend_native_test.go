//go:build postgres

package topfloorstore_test

import (
	"context"
	"reflect"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	cd "gxb.local/backend/v2/internal/domain/combat"
	hr "gxb.local/backend/v2/internal/domain/herorecommend"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/payload"
)

func TestHeroRecommendSourceTopFloorReadsSQLRows(t *testing.T) {
	ctx := context.Background()
	fixture := newTopFloorFixture(t)
	store := topfloorstore.Store{}

	ladder := domain.Ladder{Server: 1, ContentRevision: fixture.revision, Size: domain.RobotTeams, SettledDay: 0, StateVersion: 1, CreatedAt: fixture.now, UpdatedAt: fixture.now}
	if err := store.CreateLadderTx(ctx, fixture.transaction, ladder); err != nil {
		t.Fatal(err)
	}
	const playerRank = int64(domain.RobotTeams) + 1
	if err := store.AppendPlayerTx(ctx, fixture.transaction, 1, playerRank, 100001); err != nil {
		t.Fatal(err)
	}
	player := domain.Player{PlayerID: 100001, Server: 1, ContentRevision: fixture.revision, BestRank: playerRank, TicketDay: 1, TicketsLeft: 10, OfferedDay: 1,
		Offered: []domain.Occupant{}, Defense: []int64{10001001, 10001002}, DefensePet: 10002001, StateVersion: 1, CreatedAt: fixture.now, UpdatedAt: fixture.now}
	if err := store.InsertPlayerTx(ctx, fixture.transaction, player); err != nil {
		t.Fatal(err)
	}
	_, version := fixture.storedPayload(t, `SELECT defense::text,payload_version FROM top_floor_players WHERE player_id=$1`, int64(player.PlayerID))
	if version != payload.Current {
		t.Fatalf("top_floor_players payload_version=%d want %d", version, payload.Current)
	}
	if err := store.AddUsageTx(ctx, fixture.transaction, 100001, []cd.PartnerUse{{PartnerID: 10001001, Wins: 1, Kills: 2, Harms: "12.5"}}); err != nil {
		t.Fatal(err)
	}

	wantFormations := []hr.Formation{{PlayerID: 100001, PartnerIDs: []int64{10001001, 10001002}, PetID: 10002001, Weight: 5}}
	wantPopularity := []hr.Popularity{{PlayerID: 100001, PartnerID: 10001001, Score: 5}}
	source, err := store.HeroRecommendSourceTx(ctx, fixture.transaction, 1, fixture.now, hr.MaxSourceScan)
	if err != nil {
		t.Fatal("HeroRecommendSourceTx", err)
	}
	if !reflect.DeepEqual(source.Formations, wantFormations) || !reflect.DeepEqual(source.Popularity, wantPopularity) {
		t.Fatalf("source=%+v want formations=%+v popularity=%+v", source, wantFormations, wantPopularity)
	}

	// A pre-R8 row is the same writer bytes with payload_version left at 0; the R8 migration is metadata only.
	if _, err := fixture.transaction.Exec(ctx, `UPDATE top_floor_players SET payload_version=0 WHERE player_id=$1`, int64(player.PlayerID)); err != nil {
		t.Fatal(err)
	}
	_, legacyVersion := fixture.storedPayload(t, `SELECT defense::text,payload_version FROM top_floor_players WHERE player_id=$1`, int64(player.PlayerID))
	if legacyVersion != 0 {
		t.Fatalf("legacy top_floor_players payload_version=%d want 0", legacyVersion)
	}
	legacySource, err := store.HeroRecommendSourceTx(ctx, fixture.transaction, 1, fixture.now, hr.MaxSourceScan)
	if err != nil {
		t.Fatal("HeroRecommendSourceTx legacy", err)
	}
	if !reflect.DeepEqual(legacySource.Formations, wantFormations) {
		t.Fatalf("legacy formations=%+v want %+v", legacySource.Formations, wantFormations)
	}
}
