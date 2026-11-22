//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

const (
	arenaRaceReadTimeout   = 30 * time.Second
	arenaRaceSettleTimeout = 90 * time.Second
	arenaRaceFillerPlayers = 20
)

// TestL3CArenaSeasonSettlementReadRaceNative races one season settlement
// (settleSeasonTx, service.go:164) with the two Arena reads that take root 603
// without FOR UPDATE: the shared player read (service.go:236, reached through
// ModifyDefence) and Info (service.go:292). Every answer must describe one
// season (a rolled player never keeps its old-season star) and no call may
// deadlock or time out. DL-b680fb51.
func TestL3CArenaSeasonSettlementReadRaceNative(t *testing.T) {
	pool := pool(t)
	service := arenaService(t, pool)
	actor, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	if _, err := service.Info(ctx, actor, op()); err != nil {
		t.Fatalf("arena entry: %v", err)
	}

	catalog := arenaCatalog(t, pool)
	closed := catalog.LatestClosed(time.Now())
	if closed < 1 {
		t.Fatalf("latest closed season %d cannot be settled", closed)
	}
	// A shared package database may already hold this settlement; the race
	// needs the season owed again. Tournament periods hang off the settlement;
	// rooms and friend invitations point at each other, so one statement drops them.
	exec(t, pool, `WITH rooms AS (SELECT room_id FROM arena_tournament_rooms WHERE season>=$1),
entries AS (DELETE FROM arena_casual_entries WHERE room_id IN (SELECT room_id FROM rooms)),
invitations AS (DELETE FROM arena_friend_invitations WHERE room_id IN (SELECT room_id FROM rooms)),
dropped AS (DELETE FROM arena_tournament_rooms WHERE room_id IN (SELECT room_id FROM rooms))
DELETE FROM arena_tournament_periods WHERE season>=$1`, closed)
	exec(t, pool, `DELETE FROM arena_settlement_ranks WHERE season>=$1`, closed)
	exec(t, pool, `DELETE FROM arena_settlements WHERE season>=$1`, closed)
	// Earlier tests in a shared package database leave their participants in the
	// settled season; only this test's player and fillers may stand at it.
	exec(t, pool, `UPDATE arena_players SET season=GREATEST(season,$1) WHERE player_id<>$2`, closed+1, int64(actor.PlayerID))
	exec(t, pool, `UPDATE arena_competitions SET settled_through=$1, state_version=state_version+1 WHERE competition_id='GLOBAL'`, closed-1)
	exec(t, pool, `UPDATE arena_players SET season=$1, star=20, point=0, total_fight=3, win_times=1, keep_win=1 WHERE player_id=$2`, closed, int64(actor.PlayerID))

	fillers := make([]int64, 0, arenaRaceFillerPlayers)
	for i := range arenaRaceFillerPlayers {
		filler, _ := playerRoot(t, pool, actor.LogicalServerID)
		exec(t, pool, `INSERT INTO arena_players(player_id,logical_server_id,competition_id,content_revision,season,star,point,star_at,total_fight,win_times,keep_win,defense_wins,defense_losses,daily_day,daily_fights,defense,practice,match_counter,missions,mission_time,mission_draws,exchange_star,exchange_awaken,exchange_summon,awards,state_version,created_at,updated_at)
SELECT $1,logical_server_id,competition_id,content_revision,$2,$3,0,$4,1,1,0,0,0,0,0,'{"heroes":[],"pet":0}'::jsonb,false,0,'[]'::jsonb,$4,0,0,0,0,'[]'::jsonb,1,$4,$4
FROM arena_players WHERE player_id=$5`, int64(filler.PlayerID), closed, int64(i+1), time.Now(), int64(actor.PlayerID))
		fillers = append(fillers, int64(filler.PlayerID))
	}
	t.Cleanup(func() {
		exec(t, pool, `DELETE FROM arena_players WHERE player_id=ANY($1)`, fillers)
	})

	settleContext, cancelSettlement := context.WithTimeout(ctx, arenaRaceSettleTimeout)
	defer cancelSettlement()
	settled := make(chan error, 1)
	begin := make(chan struct{})
	go func() {
		<-begin
		_, err := service.Due(settleContext, op())
		settled <- err
	}()

	var infoCalls, defenceCalls atomic.Int64
	stop := make(chan struct{})
	var readers sync.WaitGroup
	var failures []string
	var failuresLock sync.Mutex
	record := func(path string, problem string) {
		failuresLock.Lock()
		defer failuresLock.Unlock()
		if len(failures) < 10 {
			failures = append(failures, fmt.Sprintf("%s: %s", path, problem))
		}
	}
	read := func(path string, answer func(context.Context) string) {
		defer readers.Done()
		<-begin
		for {
			select {
			case <-stop:
				return
			default:
			}
			readContext, cancel := context.WithTimeout(ctx, arenaRaceReadTimeout)
			problem := answer(readContext)
			cancel()
			if problem != "" {
				record(path, problem)
				return
			}
		}
	}

	readers.Add(2)
	go read("Info", func(c context.Context) string {
		infoCalls.Add(1)
		view, err := service.Info(c, actor, op())
		if err != nil {
			return err.Error()
		}
		if view.Player.Season != view.Season.Number {
			return fmt.Sprintf("player season %d with season %d", view.Player.Season, view.Season.Number)
		}
		if want := catalog.SeasonAt(view.At).Number; view.Season.Number != want {
			return fmt.Sprintf("season %d at %s, want %d", view.Season.Number, view.At, want)
		}
		if view.Player.Season > closed && view.Player.Star != 0 {
			return fmt.Sprintf("season %d player kept star %d", view.Player.Season, view.Player.Star)
		}
		return ""
	})
	go read("ModifyDefence", func(c context.Context) string {
		defenceCalls.Add(1)
		player, err := service.ModifyDefence(c, actor, arenaGirls(5), 0, op())
		if err != nil {
			return err.Error()
		}
		if want := catalog.SeasonAt(time.Now()).Number; player.Season != want {
			return fmt.Sprintf("player season %d, want %d", player.Season, want)
		}
		if player.Season > closed && player.Star != 0 {
			return fmt.Sprintf("season %d player kept star %d", player.Season, player.Star)
		}
		return ""
	})

	close(begin)
	settleError := <-settled
	close(stop)
	readers.Wait()
	t.Logf("read calls started during the settlement race: Info=%d ModifyDefence=%d", infoCalls.Load(), defenceCalls.Load())
	if settleError != nil {
		t.Fatalf("season settlement: %v", settleError)
	}
	for _, failure := range failures {
		t.Errorf("uncoherent read: %s", failure)
	}

	if got := scalar(t, pool, `SELECT settled_through FROM arena_competitions WHERE competition_id='GLOBAL'`); got != closed {
		t.Fatalf("settled_through %d, want %d", got, closed)
	}
	if got := scalar(t, pool, `SELECT count(*) FROM arena_settlements WHERE season=$1`, closed); got != 1 {
		t.Fatalf("settlement rows for season %d: %d", closed, got)
	}
	if got := scalar(t, pool, `SELECT count(*) FROM arena_settlement_ranks WHERE season=$1`, closed); got != int64(arenaRaceFillerPlayers+1) {
		t.Fatalf("settlement ranks for season %d: %d", closed, got)
	}
	if got, want := scalar(t, pool, `SELECT season FROM arena_players WHERE player_id=$1`, int64(actor.PlayerID)), catalog.SeasonAt(time.Now()).Number; got != want {
		t.Fatalf("actor season %d, want %d", got, want)
	}
}
