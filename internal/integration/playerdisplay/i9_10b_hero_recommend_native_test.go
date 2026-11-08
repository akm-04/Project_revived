//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"reflect"
	"strings"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/herorecommendstore"
	"gxb.local/backend/v2/internal/adapters/postgres/oneononestore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	"gxb.local/backend/v2/internal/application/characterasset"
	gen "gxb.local/backend/v2/internal/application/generation"
	appherorecommend "gxb.local/backend/v2/internal/application/herorecommend"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/guild"
	d "gxb.local/backend/v2/internal/domain/herorecommend"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func TestI9_10RecommendPopularityKeepsPlayersOfTheSamePartnerApart(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	first := bornActor(t, p)
	second := bornActor(t, p)
	const partnerID = int64(7)
	const firstTable, secondTable = int64(10001001), int64(10001002)
	bornHeroCard(t, p, first, revision, firstTable, firstTable, partnerID)
	bornHeroCard(t, p, second, revision, secondTable, secondTable, partnerID)

	var firstHero, secondHero int64
	if err := p.Raw().QueryRow(ctx, `SELECT table_id FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(first.PlayerID), partnerID).Scan(&firstHero); err != nil {
		t.Fatal(err)
	}
	if err := p.Raw().QueryRow(ctx, `SELECT table_id FROM player_heroes WHERE player_id=$1 AND partner_id=$2`, int64(second.PlayerID), partnerID).Scan(&secondHero); err != nil {
		t.Fatal(err)
	}
	if firstHero != firstTable || secondHero != secondTable || firstHero == secondHero {
		t.Fatalf("fixture heroes partner=%d first=%d second=%d", partnerID, firstHero, secondHero)
	}

	seedRecommendUsage(t, p, revision, first, second, partnerID, firstTable)

	wantTopFloor := []d.Popularity{{PlayerID: int64(second.PlayerID), PartnerID: partnerID, Score: 20}, {PlayerID: int64(first.PlayerID), PartnerID: partnerID, Score: 8}}
	assertPopularity(t, "top floor", callRecommendSource(t, topfloorstore.Store{}, p, first.LogicalServerID), wantTopFloor)
	assertPopularity(t, "one on one", callRecommendSource(t, oneononestore.Store{}, p, first.LogicalServerID), wantTopFloor)
	wantArena := []d.Popularity{{PlayerID: int64(second.PlayerID), TableID: firstTable, Score: 20}, {PlayerID: int64(first.PlayerID), TableID: firstTable, Score: 14}}
	assertPopularity(t, "arena", callRecommendSource(t, arenastore.Store{}, p, first.LogicalServerID), wantArena)
}

func TestI9_10CorruptCurrentGenerationSnapshotIsReplaced(t *testing.T) {
	p := pool(t)
	revision := installed(t, p)
	actor := bornActor(t, p)
	at := time.Now().UTC().Truncate(time.Microsecond)
	generation := appherorecommend.WeekStart(at).Unix()
	server := int64(actor.LogicalServerID)
	exec(t, p, `DELETE FROM hero_recommend_snapshots WHERE logical_server_id=$1`, server)
	exec(t, p, `INSERT INTO hero_recommend_snapshots(logical_server_id,generation,content_revision,observed_at,digest,payload)VALUES($1,$2,$3,$4,$5,$6::jsonb)`,
		server, generation, revision, at, strings.Repeat("0", 64), `{"schema":2}`)

	content := &recommendCountingContent{revision: revision}
	service := appherorecommend.Service{
		Timed:     gen.TimedRunner{Binder: gen.Binder{Time: recommendFixedTime{now: at}}, Runner: tx.Runner{DB: p}},
		Store:     herorecommendstore.Store{},
		Content:   content,
		Directory: recommendUnusedDirectory{},
		Guilds:    recommendUnusedGuilds{},
		Heroes:    recommendUnusedRoster{},
		Pets:      recommendUnusedRoster{},
		HeroPower: recommendUnusedPower{},
	}
	op := operation.Context{ID: ids.UUID{15: 9}, StartedAt: at}
	first, err := service.Snapshot(ctx, actor, op)
	if err != nil {
		t.Fatal(err)
	}
	if content.calls != 1 {
		t.Fatalf("first read builds once, got %d", content.calls)
	}
	var raw string
	var observed time.Time
	if err := p.Raw().QueryRow(ctx, `SELECT payload::text,observed_at FROM hero_recommend_snapshots WHERE logical_server_id=$1`, server).Scan(&raw, &observed); err != nil {
		t.Fatal(err)
	}
	var stored d.Snapshot
	if err := json.Unmarshal([]byte(raw), &stored); err != nil {
		t.Fatal(err)
	}
	if stored.Validate() != nil || stored.Schema != d.Schema || stored.Generation != generation || stored.Revision != revision {
		t.Fatalf("corrupt row not replaced: %+v", stored)
	}
	if stored.Digest != first.Digest || !stored.ObservedAt.Equal(first.ObservedAt) || !stored.ObservedAt.Equal(observed) {
		t.Fatalf("replacement payload mismatch: stored=%+v built=%+v observed=%s", stored, first, observed)
	}

	second, err := service.Snapshot(ctx, actor, op)
	if err != nil {
		t.Fatal(err)
	}
	if content.calls != 1 {
		t.Fatalf("following read must reuse the replaced row, builds=%d", content.calls)
	}
	if !reflect.DeepEqual(first, second) {
		t.Fatalf("cached snapshot differs: first=%+v second=%+v", first, second)
	}
}

func callRecommendSource(t *testing.T, source interface {
	HeroRecommendSourceTx(context.Context, tx.Queryer, identity.LogicalServerID, time.Time, int) (d.Source, error)
}, p *pg.Pool, server identity.LogicalServerID,
) d.Source {
	t.Helper()
	result, err := source.HeroRecommendSourceTx(ctx, p, server, time.Now().UTC(), d.MaxSourceScan)
	if err != nil {
		t.Fatal(err)
	}
	return result
}

func assertPopularity(t *testing.T, label string, source d.Source, want []d.Popularity) {
	t.Helper()
	// The gate shares one DB and one on one usage is global, so other tests' players appear.
	players := map[int64]bool{}
	for _, row := range want {
		players[row.PlayerID] = true
	}
	var got []d.Popularity
	for _, row := range source.Popularity {
		if players[row.PlayerID] {
			got = append(got, row)
		}
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("%s popularity got %+v want %+v", label, source.Popularity, want)
	}
}

func seedRecommendUsage(t *testing.T, p *pg.Pool, revision string, first, second identity.ActorContext, partnerID, arenaTable int64) {
	t.Helper()
	at := time.Now().UTC()
	server := int64(first.LogicalServerID)
	firstID, secondID := int64(first.PlayerID), int64(second.PlayerID)

	exec(t, p, `INSERT INTO top_floor_ladders(logical_server_id,content_revision,policy_id,size,settled_day,state_version,created_at,updated_at)
		VALUES($1,$2,'C5B_TOP_FLOOR_PRIVATE_POLICY_V1',10325,0,1,$3,$3) ON CONFLICT(logical_server_id) DO NOTHING`, server, revision, at)
	for _, playerID := range []int64{firstID, secondID} {
		exec(t, p, `INSERT INTO top_floor_players(player_id,logical_server_id,content_revision,best_rank,ticket_day,tickets_left,purchases,refresh_count,offered_day,offered,defense,defense_pet,fights,wins,state_version,created_at,updated_at)
			VALUES($1,$2,$3,1,0,0,0,0,0,'[]','[]',0,0,0,1,$4,$4)`, playerID, server, revision, at)
	}
	exec(t, p, `INSERT INTO top_floor_partner_usage(player_id,partner_id,fights,wins,kill_count,harms)VALUES($1,$2,3,1,3,100)`, firstID, partnerID)
	exec(t, p, `INSERT INTO top_floor_partner_usage(player_id,partner_id,fights,wins,kill_count,harms)VALUES($1,$2,5,5,5,100)`, secondID, partnerID)

	exec(t, p, `INSERT INTO one_on_one_competitions(competition_id,content_revision,policy_id,master_count,senior_count,settled_through,opened_through,closed_through,state_version,created_at,updated_at)
		VALUES('GLOBAL',$1,'C5C_ONE_ON_ONE_PRIVATE_POLICY_V1',500,4500,0,0,0,1,$2,$2) ON CONFLICT(competition_id) DO NOTHING`, revision, at)
	for _, playerID := range []int64{firstID, secondID} {
		exec(t, p, `INSERT INTO one_on_one_players(player_id,logical_server_id,competition_id,content_revision,level,slot,points,points_at,tries_day,tries_left,purchases,last_fight_at,teams,offered_day,refreshes,offered,mode,promotion_week,candidates,opponent,challenges,promotion_wins,last_promotion_at,win_streak,fights,wins,state_version,created_at,updated_at)
			VALUES($1,$2,'GLOBAL',$3,3,NULL,80,$4,0,0,0,NULL,'[]',0,0,'[]',1,0,'[]',NULL,0,0,NULL,0,0,0,1,$4,$4)`, playerID, server, revision, at)
	}
	exec(t, p, `INSERT INTO one_on_one_partner_usage(player_id,partner_id,fights,wins,kill_count,harms)VALUES($1,$2,3,1,3,100)`, firstID, partnerID)
	exec(t, p, `INSERT INTO one_on_one_partner_usage(player_id,partner_id,fights,wins,kill_count,harms)VALUES($1,$2,5,5,5,100)`, secondID, partnerID)

	exec(t, p, `INSERT INTO arena_competitions(competition_id,content_revision,policy_id,settled_through,state_version,created_at,updated_at)
		VALUES('GLOBAL',$1,'C5D_ARENA_PRIVATE_POLICY_V1',0,1,$2,$2) ON CONFLICT(competition_id) DO NOTHING`, revision, at)
	for _, playerID := range []int64{firstID, secondID} {
		exec(t, p, `INSERT INTO arena_players(player_id,logical_server_id,competition_id,content_revision,season,star,point,star_at,total_fight,win_times,keep_win,defense_wins,defense_losses,daily_day,daily_fights,defense,opponent,practice,match_counter,missions,mission_time,mission_draws,exchange_star,exchange_awaken,exchange_summon,awards,state_version,created_at,updated_at)
			VALUES($1,$2,'GLOBAL',$3,1,3,90,$4,0,0,0,0,0,0,0,'{"heroes":[],"pet":0}',NULL,false,0,'[]',$4,0,0,0,0,'[]',1,$4,$4)`, playerID, server, revision, at)
	}
	exec(t, p, `INSERT INTO arena_partner_usage(player_id,season,table_id,fights,wins,kill_count,harms)VALUES($1,1,$2,3,1,3,100)`, firstID, arenaTable)
	exec(t, p, `INSERT INTO arena_partner_usage(player_id,season,table_id,fights,wins,kill_count,harms)VALUES($1,2,$2,2,1,2,100)`, firstID, arenaTable)
	exec(t, p, `INSERT INTO arena_partner_usage(player_id,season,table_id,fights,wins,kill_count,harms)VALUES($1,1,$2,5,5,5,100)`, secondID, arenaTable)
}

type recommendFixedTime struct{ now time.Time }

func (f recommendFixedTime) Now(context.Context) (time.Time, error) { return f.now, nil }

type recommendCountingContent struct {
	revision string
	calls    int
}

func (c *recommendCountingContent) ActiveRevision(context.Context, tx.Queryer) (string, error) {
	c.calls++
	return c.revision, nil
}

type recommendUnusedDirectory struct{}

func (recommendUnusedDirectory) ProfileTx(context.Context, tx.Queryer, identity.PlayerID) (playerdirectory.Profile, bool, error) {
	return playerdirectory.Profile{}, false, nil
}

type recommendUnusedGuilds struct{}

func (recommendUnusedGuilds) ReadMembershipTx(context.Context, tx.Queryer, identity.PlayerID) (guild.Membership, bool, error) {
	return guild.Membership{}, false, nil
}

func (recommendUnusedGuilds) ReadGuildTx(context.Context, tx.Queryer, guild.ID) (guild.Guild, bool, error) {
	return guild.Guild{}, false, nil
}

type recommendUnusedRoster struct{}

func (recommendUnusedRoster) OverlayMID1(context.Context, tx.Queryer, identity.ActorContext, bool, time.Time, map[string]any) error {
	return nil
}

func (recommendUnusedRoster) HeroOriginTableIDsTx(context.Context, tx.Queryer, identity.PlayerID) (map[int64]int64, error) {
	return map[int64]int64{}, nil
}

type recommendUnusedPower struct{}

func (recommendUnusedPower) HeroTx(context.Context, characterasset.CoherentReadScope, character.HeroRef, publicstats.View) (publicstats.Result, error) {
	return publicstats.Result{}, nil
}
