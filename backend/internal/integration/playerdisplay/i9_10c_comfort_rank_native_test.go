//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	app "gxb.local/backend/v2/internal/application/ranking"
	"gxb.local/backend/v2/internal/domain/identity"
	d "gxb.local/backend/v2/internal/domain/ranking"
)

func comfortRankingService(p *pg.Pool) app.Service {
	service := rankingService(p, p)
	service.Comfort = dormstore.Store{Queryer: p}
	return service
}

func comfortRooms(t *testing.T, p *pg.Pool, player identity.PlayerID, revision string, comforts map[int64]int64) {
	t.Helper()
	at := time.Now().UTC().Add(-time.Hour)
	next := int64(2)
	for houseID := range comforts {
		if houseID >= next {
			next = houseID + 1
		}
	}
	exec(t, p, `INSERT INTO player_dorm_roots(player_id,next_house_id,state_version,created_at,updated_at)VALUES($1,$2,1,$3,$3) ON CONFLICT(player_id)DO UPDATE SET next_house_id=GREATEST(player_dorm_roots.next_house_id,EXCLUDED.next_house_id)`, int64(player), next, at)
	for houseID, comfort := range comforts {
		exec(t, p, `INSERT INTO player_dorm_rooms(player_id,house_id,table_id,house_type,creation_revision,floor,position,comfort,expansion_level,state_version,furniture_record,created_at,updated_at)VALUES($1,$2,1000001,1,$3,1,$2,$4,0,1,'{}'::jsonb,$5,$5) ON CONFLICT(player_id,house_id)DO UPDATE SET comfort=EXCLUDED.comfort,state_version=player_dorm_rooms.state_version+1,updated_at=EXCLUDED.updated_at`, int64(player), houseID, revision, comfort, at)
	}
}

func TestI910CDormComfortRankTotalsScopeTiesAndRefresh(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	server := rankingServer(t, p)
	first := rankingActor(t, p, server, true)
	second := rankingActor(t, p, server, true)
	if first.PlayerID >= second.PlayerID {
		t.Fatalf("fixture order: %d %d", first.PlayerID, second.PlayerID)
	}
	comfortRooms(t, p, first.PlayerID, revision, map[int64]int64{1: 10})
	comfortRooms(t, p, second.PlayerID, revision, map[int64]int64{1: 10, 2: 7})
	service := comfortRankingService(p)
	board := func(a identity.ActorContext) (players []identity.PlayerID, values []int64, since []time.Time) {
		read, e := service.ReadBoard(ctx, d.DormComfortBoard, a, op())
		if e != nil {
			t.Fatal(e)
		}
		for _, row := range read.Rows {
			players = append(players, row.Player)
			values = append(values, row.Score)
			since = append(since, row.ScoreSince)
		}
		return players, values, since
	}
	board(first)
	players, values, _ := board(second)
	if len(players) != 2 || players[0] != second.PlayerID || values[0] != 17 || values[1] != 10 {
		t.Fatalf("lounge-inclusive totals %v %v", players, values)
	}

	comfortRooms(t, p, second.PlayerID, revision, map[int64]int64{2: 0})
	board(second)
	players, values, _ = board(first)
	if players[0] != first.PlayerID || values[0] != 10 || values[1] != 10 {
		t.Fatalf("stable-ID tie %v %v", players, values)
	}

	comfortRooms(t, p, second.PlayerID, revision, map[int64]int64{1: 5})
	board(second)
	players, values, _ = board(first)
	if players[0] != first.PlayerID || values[0] != 10 || values[1] != 5 {
		t.Fatalf("comfort drop %v %v", players, values)
	}

	time.Sleep(2 * time.Millisecond)
	comfortRooms(t, p, first.PlayerID, revision, map[int64]int64{1: 5})
	board(second)
	players, values, since := board(first)
	if players[0] != second.PlayerID || values[0] != 5 || !since[0].Before(since[1]) {
		t.Fatalf("first-observed tie %v %v %v", players, values, since)
	}

	comfortRooms(t, p, first.PlayerID, revision, map[int64]int64{1: 30})
	board(first)
	players, values, _ = board(second)
	if players[0] != first.PlayerID || values[0] != 30 {
		t.Fatalf("refresh after comfort change %v %v", players, values)
	}

	otherServer := rankingServer(t, p)
	other := rankingActor(t, p, otherServer, true)
	comfortRooms(t, p, other.PlayerID, revision, map[int64]int64{1: 500})
	players, _, _ = board(first)
	for _, player := range players {
		if player == other.PlayerID {
			t.Fatal("foreign server ranked in this board")
		}
	}
	players, values, _ = board(other)
	if len(players) != 1 || players[0] != other.PlayerID || values[0] != 500 {
		t.Fatalf("other server board %v %v", players, values)
	}
}
