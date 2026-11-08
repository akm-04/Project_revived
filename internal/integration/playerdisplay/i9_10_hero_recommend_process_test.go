//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	appherorecommend "gxb.local/backend/v2/internal/application/herorecommend"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
)

func TestI9_10HeroRecommendProcessStockMIDs(t *testing.T) {
	pool := pool(t)
	revision := installed(t, pool)
	actor := bornActor(t, pool)
	var currentTableID, originTableID int64
	if err := pool.Raw().QueryRow(ctx, `SELECT table_id,origin_table_id FROM gxb_content_hero_templates WHERE revision_id=$1 AND is_awakened ORDER BY table_id LIMIT 1`, revision).Scan(&currentTableID, &originTableID); err != nil {
		t.Fatal(err)
	}
	bornHeroCard(t, pool, actor, revision, currentTableID, originTableID, 1)
	seedHeroRecommendSources(t, pool, actor, revision, currentTableID)
	staleGeneration := seedStaleHeroRecommendSnapshot(t, pool, actor.LogicalServerID, revision)
	process := startI9Process(t, pool, actor)

	status, body := process.post(2497, map[string]any{})
	if status != 200 {
		t.Fatalf("2497 status %d body %+v", status, body)
	}
	subRankList := i9Object(t, body["sub_rank_list"])
	oneOnOneRanks := i9List(t, subRankList["2"])
	arenaRanks := i9List(t, subRankList["3"])
	if len(oneOnOneRanks) != 1 || i9Number(t, oneOnOneRanks[0]) != originTableID || len(arenaRanks) != 1 || i9Number(t, arenaRanks[0]) != originTableID {
		t.Fatalf("2497 category split or origin identity: %+v", subRankList)
	}
	totalRankList := i9List(t, body["total_rank_list"])
	if len(totalRankList) != 1 {
		t.Fatalf("2497 total_rank_list %+v", totalRankList)
	}
	totalHero := i9Object(t, totalRankList[0])
	if i9Number(t, totalHero["table_id"]) != originTableID || i9Number(t, totalHero["recommend_score"]) != 15 {
		t.Fatalf("2497 aggregate %+v", totalHero)
	}

	status, body = process.post(2498, map[string]any{"table_id": originTableID})
	if status != 200 || i9Number(t, body["recommend_score"]) != 15 {
		t.Fatalf("2498 status %d body %+v", status, body)
	}
	forceInfo := i9Object(t, body["force_info"])
	topHero := i9Object(t, forceInfo["top_hero_info"])
	if i9Number(t, topHero["table_id"]) != currentTableID || i9Number(t, topHero["force"]) <= 0 {
		t.Fatalf("2498 top hero %+v", topHero)
	}
	formations := i9Object(t, body["recommend_formations"])
	if _, ok := formations["2"].(map[string]any); !ok {
		t.Fatalf("2498 category 2 formation shape %T", formations["2"])
	}
	if _, ok := formations["3"].(map[string]any); !ok {
		t.Fatalf("2498 category 3 formation shape %T", formations["3"])
	}
	oneOnOneFormation := i9Object(t, formations["2"])
	formationHeroes := i9List(t, oneOnOneFormation["formation"])
	if len(formationHeroes) != 1 || i9Number(t, i9Object(t, formationHeroes[0])["table_id"]) != currentTableID {
		t.Fatalf("2498 formation lost current hero identity: %+v", oneOnOneFormation)
	}

	status, body = process.post(2499, map[string]any{"table_id": originTableID})
	if status != 200 {
		t.Fatalf("2499 status %d body %+v", status, body)
	}
	myRank := i9Object(t, body["my_rank"])
	rankList := i9List(t, body["rank_list"])
	if i9Number(t, myRank["rank"]) != 1 || i9Number(t, myRank["force"]) <= 0 || len(rankList) != 1 {
		t.Fatalf("2499 ranking body %+v", body)
	}

	exec(t, pool, `UPDATE one_on_one_partner_usage SET fights=20,wins=20,kill_count=20 WHERE player_id=$1 AND partner_id=1`, int64(actor.PlayerID))
	status, body = process.post(2497, map[string]any{})
	if status != 200 || i9Number(t, i9Object(t, i9List(t, body["total_rank_list"])[0])["recommend_score"]) != 15 {
		t.Fatalf("2497 failed to serve cached generation: status %d body %+v", status, body)
	}
	var snapshotCount, currentGeneration int64
	if err := pool.Raw().QueryRow(ctx, `SELECT count(*),max(generation) FROM hero_recommend_snapshots WHERE logical_server_id=$1`, int64(actor.LogicalServerID)).Scan(&snapshotCount, &currentGeneration); err != nil || snapshotCount != 2 || currentGeneration <= staleGeneration {
		t.Fatalf("snapshot refresh count=%d generation=%d stale=%d err=%v", snapshotCount, currentGeneration, staleGeneration, err)
	}

	status, body = process.post(2496, map[string]any{})
	if status != 409 || i9Number(t, body["error_code"]) != 1 {
		t.Fatalf("2496 unsupported contract refusal status %d body %+v", status, body)
	}
	status, body = process.post(2497, map[string]any{"unexpected": true})
	if status != 400 {
		t.Fatalf("2497 extra-param status %d body %+v", status, body)
	}
	status, body = process.post(2498, map[string]any{})
	if status != 400 {
		t.Fatalf("2498 missing-table status %d body %+v", status, body)
	}
	status, body = process.post(2499, map[string]any{"table_id": int64(0)})
	if status != 400 {
		t.Fatalf("2499 nonpositive-table status %d body %+v", status, body)
	}

	process.stop()
	assertI9Journal(t, pool, actor, []int{2496, 2497, 2498, 2499})
}

func seedHeroRecommendSources(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, currentTableID int64) {
	t.Helper()
	at := time.Now().UTC()
	playerID := int64(actor.PlayerID)
	logicalServerID := int64(actor.LogicalServerID)
	oneOnOneTeams := `[{"heroes":[1],"pet":0}]`
	exec(t, pool, `INSERT INTO one_on_one_competitions(competition_id,content_revision,policy_id,master_count,senior_count,settled_through,opened_through,closed_through,state_version,created_at,updated_at)
		VALUES('GLOBAL',$1,'C5C_ONE_ON_ONE_PRIVATE_POLICY_V1',500,4500,0,0,0,1,$2,$2) ON CONFLICT(competition_id) DO NOTHING`, revision, at)
	exec(t, pool, `INSERT INTO one_on_one_players(player_id,logical_server_id,competition_id,content_revision,level,slot,points,points_at,tries_day,tries_left,purchases,last_fight_at,teams,offered_day,refreshes,offered,mode,promotion_week,candidates,opponent,challenges,promotion_wins,last_promotion_at,win_streak,fights,wins,state_version,created_at,updated_at)
		VALUES($1,$2,'GLOBAL',$3,3,NULL,80,$4,0,0,0,NULL,$5::jsonb,0,0,'[]',1,0,'[]',NULL,0,0,NULL,0,0,0,1,$4,$4)`, playerID, logicalServerID, revision, at, oneOnOneTeams)
	exec(t, pool, `INSERT INTO one_on_one_partner_usage(player_id,partner_id,fights,wins,kill_count,harms)VALUES($1,1,3,1,3,100)`, playerID)
	exec(t, pool, `INSERT INTO arena_competitions(competition_id,content_revision,policy_id,settled_through,state_version,created_at,updated_at)
		VALUES('GLOBAL',$1,'C5D_ARENA_PRIVATE_POLICY_V1',0,1,$2,$2) ON CONFLICT(competition_id) DO NOTHING`, revision, at)
	exec(t, pool, `INSERT INTO arena_players(player_id,logical_server_id,competition_id,content_revision,season,star,point,star_at,total_fight,win_times,keep_win,defense_wins,defense_losses,daily_day,daily_fights,defense,opponent,practice,match_counter,missions,mission_time,mission_draws,exchange_star,exchange_awaken,exchange_summon,awards,state_version,created_at,updated_at)
		VALUES($1,$2,'GLOBAL',$3,1,3,90,$4,0,0,0,0,0,0,0,$5::jsonb,NULL,false,0,'[]',$4,0,0,0,0,'[]',1,$4,$4)`, playerID, logicalServerID, revision, at, `{"heroes":[`+strconv.FormatInt(currentTableID, 10)+`,0,0,0,0],"pet":0}`)
	exec(t, pool, `INSERT INTO arena_partner_usage(player_id,season,table_id,fights,wins,kill_count,harms)VALUES($1,1,$2,2,1,3,100)`, playerID, currentTableID)
}

func seedStaleHeroRecommendSnapshot(t *testing.T, pool *pg.Pool, logicalServerID identity.LogicalServerID, revision string) int64 {
	t.Helper()
	observedAt := time.Now().UTC().Add(-8 * 24 * time.Hour)
	generation := appherorecommend.WeekStart(observedAt).Unix()
	snapshot := d.Snapshot{
		Schema:     d.Schema,
		Server:     int64(logicalServerID),
		Generation: generation,
		Revision:   revision,
		ObservedAt: observedAt,
		Digest:     "0000000000000000000000000000000000000000000000000000000000000000",
		Overview:   d.Overview{SubRankList: map[string][]int64{}, TotalRankList: []map[string]any{}},
		Details:    map[string]d.Detail{},
	}
	payload, err := json.Marshal(snapshot)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `DELETE FROM hero_recommend_snapshots WHERE logical_server_id=$1`, int64(logicalServerID))
	exec(t, pool, `INSERT INTO hero_recommend_snapshots(logical_server_id,generation,content_revision,observed_at,digest,payload)VALUES($1,$2,$3,$4,$5,$6::jsonb)`, int64(logicalServerID), generation, revision, observedAt, snapshot.Digest, string(payload))
	return generation
}

func i9Object(t *testing.T, value any) map[string]any {
	t.Helper()
	object, ok := value.(map[string]any)
	if !ok {
		t.Fatalf("not an object: %T %+v", value, value)
	}
	return object
}

func i9List(t *testing.T, value any) []any {
	t.Helper()
	list, ok := value.([]any)
	if !ok {
		t.Fatalf("not a list: %T %+v", value, value)
	}
	return list
}
