//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"reflect"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// R12: Top Floor robots display and fight with source equipment plus the
// PRIVATE_POLICY rank band, and source values beyond the meeting rank.
func TestI9_10TopFloorRobotRankBandNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := topFloorService(t, pool)
	server := rankingServer(t, pool)
	a, _, ref := topFloorPlayer(t, pool, server)
	revision, err := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := (contentstore.Store{Queryer: pool}).TopFloorCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}

	if _, err = s.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if err = s.SaveDefense(ctx, a, []int64{ref.PartnerID}, 0, op()); err != nil {
		t.Fatal(err)
	}

	// Rank 1: every girl red+1, level 100, level-100 pet.
	movePlayerRank(t, pool, server, a.PlayerID, 2)
	view, err := s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	first, ok := enemyAtRank(view, 1)
	if !ok {
		t.Fatalf("rank 1 robot not offered: %v", ranksOf(view))
	}
	assertDisplayBand(t, catalog, first, 100, 16, 3)
	assertPet(t, first.Pet, 100, catalog)

	if !catalog.Frozen(time.Now()) {
		command := app.StartCommand{Formation: []int64{ref.PartnerID}, Enemy: first.Occupant.TableID()}
		if _, err = s.Start(ctx, a, command, op()); err != nil {
			t.Fatal(err)
		}
		assertFightBand(t, pool, a.PlayerID, first.Occupant.Robot, 1, 100, 16, 3, 100, catalog)
	}

	// Rank 30: orange+1, level 88, level-88 pet; source star and equipment kept.
	movePlayerRank(t, pool, server, a.PlayerID, 31)
	view, err = s.Load(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	thirtieth, ok := enemyAtRank(view, 30)
	if !ok {
		t.Fatalf("rank 30 robot not offered: %v", ranksOf(view))
	}
	assertDisplayBand(t, catalog, thirtieth, 88, 13, 3)
	assertPet(t, thirtieth.Pet, 88, catalog)

	// Rank 600: beyond the meeting rank the source values apply unchanged and
	// the source robot carries no pet.
	movePlayerRank(t, pool, server, a.PlayerID, 601)
	sixHundredth, ok := refreshUntilRank(t, s, a, 600)
	if !ok {
		t.Fatal("rank 600 robot was never offered")
	}
	if sixHundredth.Pet != nil {
		t.Fatalf("rank 600 source robot must carry no pet: %v", sixHundredth.Pet)
	}
	source, found := catalog.Team(sixHundredth.Occupant.Robot)
	if !found || sixHundredth.Level != source.Level {
		t.Fatalf("rank 600 team level %d want source %d", sixHundredth.Level, source.Level)
	}
	for i, id := range source.Heroes {
		params, ok := catalog.RobotHeroParams(id)
		if !ok {
			t.Fatalf("source robot hero %d", id)
		}
		display := sixHundredth.Heroes[i]
		if force := formValue(t, display, "force"); force <= 0 {
			t.Fatalf("rank 600 hero %d force %d is not the resolved template power", id, force)
		}
		delete(display, "force")
		if !reflect.DeepEqual(display, params) {
			t.Fatalf("rank 600 hero %d display %v want source %v", id, display, params)
		}
	}
}

func ranksOf(view app.ArenaView) []int64 {
	out := []int64{}
	for _, enemy := range view.Enemies {
		out = append(out, enemy.Rank)
	}
	return out
}

func enemyAtRank(view app.ArenaView, rank int64) (d.Display, bool) {
	for _, enemy := range view.Enemies {
		if enemy.Rank == rank {
			return enemy, true
		}
	}
	return d.Display{}, false
}

func refreshUntilRank(t *testing.T, s app.Service, a identity.ActorContext, rank int64) (d.Display, bool) {
	t.Helper()
	for range 120 {
		view, err := s.Refresh(ctx, a, op())
		if err != nil {
			t.Fatal(err)
		}
		if enemy, ok := enemyAtRank(view, rank); ok {
			return enemy, true
		}
	}
	return d.Display{}, false
}

func sourceTeam(t *testing.T, catalog d.Catalog, rank int64) (d.RobotTeam, []d.RobotHero) {
	t.Helper()
	team, ok := catalog.Team(d.RobotTeams + 1 - rank)
	if !ok {
		t.Fatalf("rank %d source team", rank)
	}
	byID := map[int64]d.RobotHero{}
	for _, hero := range catalog.RobotHeroes {
		byID[hero.ID] = hero
	}
	heroes := make([]d.RobotHero, 0, len(team.Heroes))
	for _, id := range team.Heroes {
		hero, ok := byID[id]
		if !ok {
			t.Fatalf("rank %d source hero %d", rank, id)
		}
		heroes = append(heroes, hero)
	}
	return team, heroes
}

func assertDisplayBand(t *testing.T, catalog d.Catalog, display d.Display, level, quality, star int64) {
	t.Helper()
	if display.Rank < 1 || display.Level != level {
		t.Fatalf("rank %d display level %d want %d", display.Rank, display.Level, level)
	}
	if display.Occupant.Robot != d.RobotTeams+1-display.Rank {
		t.Fatalf("rank %d occupant robot %d", display.Rank, display.Occupant.Robot)
	}
	want, ok := catalog.RobotHeroesAt(display.Occupant.Robot, display.Rank)
	if !ok {
		t.Fatalf("rank %d robot heroes", display.Rank)
	}
	lineup, banded := catalog.RobotLineup(display.Rank)
	if !banded || len(lineup.Heroes) != len(want) {
		t.Fatalf("rank %d lineup %+v", display.Rank, lineup)
	}
	if len(display.Heroes) != len(want) {
		t.Fatalf("rank %d display %d heroes want %d", display.Rank, len(display.Heroes), len(want))
	}
	for i, hero := range display.Heroes {
		if hero["partner_id"] != lineup.Heroes[i].PartnerID {
			t.Fatalf("rank %d hero %d partner %v want lineup %d", display.Rank, i, hero["partner_id"], lineup.Heroes[i].PartnerID)
		}
		assertHeroBand(t, hero, want[i], level, quality, star)
	}
}

func assertPet(t *testing.T, pet map[string]any, level int64, catalog d.Catalog) {
	t.Helper()
	if pet == nil || pet["lev"] != level {
		t.Fatalf("pet %v want level %d", pet, level)
	}
	tableID, _ := pet["table_id"].(int64)
	for _, candidate := range catalog.PetPool {
		if candidate.TableID != tableID {
			continue
		}
		if pet["star"] != candidate.InitialStar {
			t.Fatalf("pet %v want source initial star %d", pet, candidate.InitialStar)
		}
		return
	}
	t.Fatalf("pet %v not from the source pool", pet)
}

func assertHeroBand(t *testing.T, hero, want map[string]any, level, quality, star int64) {
	t.Helper()
	if hero["lev"] != level || hero["color"] != quality || hero["star"] != star {
		t.Fatalf("hero %v want lev %d color %d star %d", hero, level, quality, star)
	}
	if hero["partner_id"] != want["partner_id"] {
		t.Fatalf("hero partner %v want lineup %v", hero["partner_id"], want["partner_id"])
	}
	if !reflect.DeepEqual(hero["equips"], want["equips"]) {
		t.Fatalf("hero %v equipment %v want source slot %v", want["partner_id"], hero["equips"], want["equips"])
	}
	if !reflect.DeepEqual(hero["skills"], []any{1, 1, 1, 1, 1, 1}) {
		t.Fatalf("hero %v skills %v", want["partner_id"], hero["skills"])
	}
}

func robotEquipSlots(flags []int64) []any {
	out := make([]any, 6)
	for i := range out {
		out[i] = int64(0)
		if i < len(flags) {
			out[i] = flags[i]
		}
	}
	return out
}

type frozenActorParams struct {
	Lev       int64   `json:"lev"`
	Color     int64   `json:"color"`
	Star      int64   `json:"star"`
	PartnerID int64   `json:"partner_id"`
	Equips    []int64 `json:"equips"`
	Skills    []int64 `json:"skills"`
	PetID     int64   `json:"pet_id"`
	TableID   int64   `json:"table_id"`
}

func assertFightBand(t *testing.T, pool *pg.Pool, player identity.PlayerID, robot, rank, level, quality, star, petLevel int64, catalog d.Catalog) {
	t.Helper()
	want, ok := catalog.RobotHeroesAt(robot, rank)
	if !ok {
		t.Fatalf("rank %d fight robot heroes", rank)
	}
	lineup, banded := catalog.RobotLineup(rank)
	if !banded || len(lineup.Heroes) != len(want) {
		t.Fatalf("rank %d fight lineup %+v", rank, lineup)
	}
	var raw []byte
	if err := pool.QueryRow(ctx, `SELECT cs.canonical FROM combat_attempts ca JOIN combat_snapshots cs ON cs.snapshot_hash=ca.snapshot_hash WHERE ca.actor_player_id=$1 ORDER BY ca.started_at DESC,ca.attempt_id DESC LIMIT 1`, int64(player)).Scan(&raw); err != nil {
		t.Fatal(err)
	}
	var snapshot struct {
		Battle struct {
			WavesB [][]struct {
				Params json.RawMessage `json:"params"`
			} `json:"waves_b"`
			PetsB []struct {
				Params json.RawMessage `json:"params"`
			} `json:"pets_b"`
		} `json:"battle"`
	}
	if err := json.Unmarshal(raw, &snapshot); err != nil {
		t.Fatal(err)
	}
	if len(snapshot.Battle.WavesB) != 1 || len(snapshot.Battle.WavesB[0]) != len(want) {
		t.Fatalf("fight robot waves %+v want %d", snapshot.Battle.WavesB, len(want))
	}
	for i, actor := range snapshot.Battle.WavesB[0] {
		var params frozenActorParams
		if err := json.Unmarshal(actor.Params, &params); err != nil {
			t.Fatal(err)
		}
		wanted, err := json.Marshal(want[i])
		if err != nil {
			t.Fatal(err)
		}
		var expected frozenActorParams
		if err = json.Unmarshal(wanted, &expected); err != nil {
			t.Fatal(err)
		}
		if params.Lev != level || params.Color != quality || params.Star != star || params.PartnerID != expected.PartnerID || !reflect.DeepEqual(params.Equips, expected.Equips) || !reflect.DeepEqual(params.Skills, []int64{1, 1, 1, 1, 1, 1}) {
			t.Fatalf("fight hero %d params %+v want lev %d color %d star %d equips %v", params.PartnerID, params, level, quality, star, expected.Equips)
		}
		if params.PartnerID != lineup.Heroes[i].PartnerID {
			t.Fatalf("fight hero %d partner %d want lineup %d", i, params.PartnerID, lineup.Heroes[i].PartnerID)
		}
	}
	if len(snapshot.Battle.PetsB) != 1 {
		t.Fatalf("fight robot pets %+v", snapshot.Battle.PetsB)
	}
	var pet frozenActorParams
	if err := json.Unmarshal(snapshot.Battle.PetsB[0].Params, &pet); err != nil {
		t.Fatal(err)
	}
	known := false
	for _, candidate := range catalog.PetPool {
		known = known || candidate.TableID == pet.TableID
	}
	if !known || pet.Lev != petLevel || pet.PetID <= 0 {
		t.Fatalf("fight robot pet %+v want level %d from the source pool", pet, petLevel)
	}
}

func movePlayerRank(t *testing.T, pool *pg.Pool, server identity.LogicalServerID, player identity.PlayerID, toRank int64) {
	t.Helper()
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	var oldRank, robot int64
	if err = transaction.QueryRow(ctx, `SELECT rank FROM top_floor_ranks WHERE logical_server_id=$1 AND player_id=$2`, int64(server), int64(player)).Scan(&oldRank); err != nil {
		t.Fatal(err)
	}
	if oldRank == toRank {
		return
	}
	if err = transaction.QueryRow(ctx, `SELECT robot_team FROM top_floor_ranks WHERE logical_server_id=$1 AND rank=$2`, int64(server), toRank).Scan(&robot); err != nil {
		t.Fatal(err)
	}
	if _, err = transaction.Exec(ctx, `UPDATE top_floor_ranks SET player_id=$3,robot_team=NULL WHERE logical_server_id=$1 AND rank=$2`, int64(server), toRank, int64(player)); err != nil {
		t.Fatal(err)
	}
	if _, err = transaction.Exec(ctx, `UPDATE top_floor_ranks SET player_id=NULL,robot_team=$3 WHERE logical_server_id=$1 AND rank=$2`, int64(server), oldRank, robot); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}
