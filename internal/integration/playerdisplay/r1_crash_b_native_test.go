//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/stockruntime"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	wb "gxb.local/backend/v2/internal/domain/worldboss"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// r1TournamentRoom seeds one stage-7 selecting room whose sides picked no pet.
func r1TournamentRoom(t *testing.T, owner, peer identity.ActorContext, revision string, identifier ids.UUID) d.TournamentRoom {
	t.Helper()
	now := time.Now().UTC()
	return d.TournamentRoom{
		Identifier: identifier, Season: 1, Stage: 7, Contest: 1, Status: d.RoomSelecting, StartsAt: now,
		ContentRevision: revision, StateVersion: 1,
		Selection:       d.SelectionRoom{Players: [2]identity.PlayerID{owner.PlayerID, peer.PlayerID}, Team: 1, Turn: 7, Deadline: now.Add(time.Minute)},
		SelectionHeroes: [2]map[string]map[string]any{{}, {}},
		SelectionPets:   [2]map[string]map[string]any{{}, {}},
		Actors:          [2]d.AdmissionContext{d.AdmissionFrom(owner), d.AdmissionFrom(peer)},
	}
}

func TestR1ArenaTournamentRoomNoPetThroughDispatcher(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	owner, peer := rankingActor(t, p, server, true), rankingActor(t, p, server, true)
	revision := installed(t, p)
	identifier := uuid()
	room := r1TournamentRoom(t, owner, peer, revision, identifier)
	transaction, err := p.Begin(ctx, tx.Options{Isolation: tx.Serializable})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err = transaction.Exec(ctx, `INSERT INTO arena_settlements(season,cutoff_at,settled_at,competition_version,content_revision,recipients)VALUES(1,$1,$1,1,$2,0)ON CONFLICT(season)DO NOTHING`, room.StartsAt, revision); err != nil {
		t.Fatal(err)
	}
	if _, err = transaction.Exec(ctx, `INSERT INTO arena_tournament_periods(season,content_revision,payload,state_version)VALUES(1,$1::text,jsonb_build_object('season',1,'content_revision',$1::text,'state_version',1),1)ON CONFLICT(season)DO NOTHING`, revision); err != nil {
		t.Fatal(err)
	}
	if err = (arenastore.Store{}).SaveTournamentRoomTx(ctx, transaction, room, 0); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	dispatcher := stockruntime.TournamentDispatcher{Authority: unpinnedDispatchAuthority{actor: owner}, Service: arenaService(t, p)}
	response := dispatcher.Dispatch(ctx, unpinnedRequest(1292, owner, time.Now().UTC(), map[string]any{"room_key": room.SelectionKey(), "stage": int64(room.Selection.Turn)}))
	if response.HTTPStatus != 200 {
		t.Fatalf("MID 1292 status %d body %#v cause %v", response.HTTPStatus, response.Body, response.Cause)
	}
	for _, key := range []string{"A_pet_info", "B_pet_info"} {
		if _, present := response.Body[key]; present {
			t.Fatalf("MID 1292 sent %s for a side with no pet: %#v", key, response.Body[key])
		}
	}
	for _, key := range []string{"A_partners_info", "B_partners_info"} {
		rows, ok := response.Body[key].(map[string]map[string]any)
		if !ok || rows == nil {
			t.Fatalf("MID 1292 %s is not an object: %#v", key, response.Body[key])
		}
	}
	if _, ok := response.Body["A_player_info"].(map[string]any); !ok {
		t.Fatalf("MID 1292 A_player_info: %#v", response.Body["A_player_info"])
	}
	raw, err := json.Marshal(response.Body)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), `"_pet_info":null`) {
		t.Fatal(string(raw))
	}
}

func TestR1WorldBossSweepKeepsPreInfoThroughDispatcher(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	actor, _ := worldBossActor(t, p, server)
	ahead, _ := worldBossActor(t, p, server)
	clock := worldBossTime(t)
	service := worldBossService(t, p, clock)
	worldBossSetPlayer(t, p, actor.PlayerID, modesDay(clock.at), 2, 900)
	exec(t, p, `DELETE FROM player_directory_profiles WHERE player_id=$1`, int64(ahead.PlayerID))
	if _, err := p.Raw().Exec(ctx, `INSERT INTO worldboss_player_totals(logical_server_id,generation,boss_id,player_id,hurt,first_hurt_at,updated_at)VALUES($1,1,$2,$3,10000,0,clock_timestamp())`, int64(server), wb.FirstBossID, int64(ahead.PlayerID)); err != nil {
		t.Fatal(err)
	}

	dispatcher := stockruntime.WorldBossDispatcher{Authority: unpinnedDispatchAuthority{actor: actor}, Service: service}
	response := dispatcher.Dispatch(ctx, unpinnedRequest(628, actor, clock.at, map[string]any{"campaign_id": wb.FirstBossID}))
	if response.HTTPStatus != 200 {
		t.Fatalf("MID 628 status %d body %#v cause %v", response.HTTPStatus, response.Body, response.Cause)
	}
	if rank, _ := response.Body["total_rank"].(int64); rank != 2 {
		t.Fatalf("MID 628 total_rank %#v", response.Body["total_rank"])
	}
	pre, ok := response.Body["pre_info"].(map[string]any)
	if !ok || pre == nil {
		t.Fatalf("MID 628 pre_info missing for a second-ranked viewer: %#v", response.Body)
	}
	if pre["hurt"] != int64(10000) || pre["pre_rank"] != int64(1) || pre["player_name"] != "" || pre["lev"] != int64(0) {
		t.Fatalf("MID 628 pre_info shape: %#v", pre)
	}
}
