//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/achievementstore"
	"gxb.local/backend/v2/internal/adapters/postgres/arenastore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/guildstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	ach "gxb.local/backend/v2/internal/application/achievement"
	app "gxb.local/backend/v2/internal/application/arena"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func arenaService(t *testing.T, p *pg.Pool) app.Service {
	t.Helper()
	fight := combatService(t, p)
	values, content := i5store.Store{Queryer: p}, contentstore.Store{Queryer: p}
	runner := tx.Runner{DB: p}
	grants := i5.Service{Runner: runner, Store: values, Content: content, Privileges: i5.BaselinePrivilegeProvider{}, Functions: i5.PetStarterFunctionAnnouncements{}, Directory: i4store.DirectoryLevelProjection{},
		Backpack: values, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}, RedeemSecret: []byte("i7c5d-arena-native-fixture-secret-00")}
	return app.Service{Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: p}}, Runner: runner}, Fresh: p, Store: arenastore.Store{}, Content: content,
		Fence: values, Costs: i5.MaterialCostDebiter{Store: values, Content: content}, Grants: grants, Values: values, Mail: i5.SettlementMail{Store: values},
		Achievements: ach.Service{Store: achievementstore.Store{}, Content: content, Population: libraryService(p, p)}, Combat: fight, Heroes: fight.Inputs.Heroes, Pets: fight.Inputs.Pets,
		Directory: i4store.PlayerDirectoryReader{}, Guilds: guildstore.Store{}, Servers: i4store.ServerNames{}, Receipts: kernelstore.Store{}, ReceiptRead: kernelstore.Reader{Queryer: p}}
}

func arenaCatalog(t *testing.T, p *pg.Pool) d.Catalog {
	t.Helper()
	content := contentstore.Store{Queryer: p}
	rev, err := content.ActiveRevision(ctx, p)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := content.ArenaCatalogTx(ctx, p, rev)
	if err != nil {
		t.Fatal(err)
	}
	return catalog
}

// arenaGirls are the table ids oneOnOnePlayer summons (10001001.. in order).
func arenaGirls(n int) []int64 {
	out := []int64{}
	for i := range n {
		out = append(out, 10001001+int64(i))
	}
	return out
}

// fightSettled repeats an identical FIGHT while the battle is still resolving, as the stock client's retry does.
func fightSettled(s app.Service, a identity.ActorContext, command app.FightCommand) (d.FightView, error) {
	for {
		v, err := s.Fight(ctx, a, command, op())
		if !errors.Is(err, app.ErrUnresolved) {
			return v, err
		}
	}
}

func arenaFight(t *testing.T, s app.Service, a identity.ActorContext, enemy identity.PlayerID, practice bool) d.FightView {
	t.Helper()
	if _, err := s.Match(ctx, a, practice, op()); err != nil {
		t.Fatal(err)
	}
	if err := s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	v, err := fightSettled(s, a, app.FightCommand{Enemy: enemy, Practice: practice, Formation: arenaGirls(5)})
	if err != nil {
		t.Fatal(err)
	}
	return v
}

func TestI7C5DArenaEntryFightSettlementNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := arenaService(t, pool)
	a, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	catalog := arenaCatalog(t, pool)
	season := catalog.SeasonAt(time.Now())
	exec(t, pool, `DELETE FROM arena_settlements WHERE season>=$1`, season.Number-1)

	// D02: function 37 needs level 60 and 5 girls; entry is the current season at 0 stars with 3 missions.
	low, _, _ := combatOwner(t, pool, a.LogicalServerID)
	if _, err := s.Info(ctx, low, op()); err == nil {
		t.Fatal("a player below level 60 with one girl entered")
	}
	info, err := s.Info(ctx, a, op())
	if err != nil {
		t.Fatal(err)
	}
	if info.Player.Star != 0 || len(info.Player.Missions) != 3 || info.Season.Number != season.Number || info.Closed || info.Rank < 1 || scalar(t, pool, `SELECT count(*) FROM arena_competitions`) != 1 {
		t.Fatalf("entry %+v", info)
	}
	if _, err = s.Info(ctx, b, op()); err != nil {
		t.Fatal(err)
	}

	// D03: exactly five distinct owned girls; a missing girl or a duplicate base is refused.
	if _, err = s.ModifyDefence(ctx, b, arenaGirls(4), 0, op()); err == nil {
		t.Fatal("four girls accepted")
	}
	if _, err = s.ModifyDefence(ctx, b, append(arenaGirls(4), 10009999), 0, op()); err == nil {
		t.Fatal("an unowned girl accepted")
	}
	if _, err = s.ModifyDefence(ctx, b, []int64{10001001, 11001001, 10001002, 10001003, 10001004}, 0, op()); err == nil {
		t.Fatal("a girl and her awakened form accepted together")
	}
	if p, err := s.ModifyDefence(ctx, b, arenaGirls(5), 0, op()); err != nil || len(p.Defense.Heroes) != 5 {
		t.Fatal("defense", err)
	}

	// D04: matching offers the only defended opponent; START binds it.
	exec(t, pool, `UPDATE arena_players SET defense=jsonb_build_object('heroes','[]'::jsonb,'pet',0) WHERE player_id<>$1`, int64(b.PlayerID))
	enemy, err := s.Match(ctx, a, false, op())
	if err != nil || enemy.Face.Player != b.PlayerID || len(enemy.Heroes) != 5 || enemy.Face.ServerName == "" {
		t.Fatalf("match %+v %v", enemy.Face, err)
	}
	if _, err = s.Fight(ctx, a, app.FightCommand{Enemy: b.PlayerID, Formation: arenaGirls(5)}, op()); err == nil {
		t.Fatal("FIGHT before START accepted")
	}
	if err = s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if err = s.Start(ctx, a, op()); err != nil || scalar(t, pool, `SELECT count(*) FROM arena_matches WHERE attacker_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("repeated START must reuse the started match", err)
	}

	// D05: one server-resolved battle settles once with stars, coins, records, usage, missions and the streak.
	command := app.FightCommand{Enemy: b.PlayerID, Formation: arenaGirls(5)}
	started := time.Now()
	result, err := fightSettled(s, a, command)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("Arena FIGHT with resolution and settlement took %s (win %v)", time.Since(started), result.Win)
	wantStar, wantCoin := int64(0), int64(25)
	if result.Win {
		wantStar, wantCoin = 1, 50
	}
	if len(result.Report) == 0 || result.Player.Star != wantStar || result.Player.TotalFight != 1 || result.Coins != wantCoin || result.RegionCoin != wantCoin {
		t.Fatalf("fight %+v", result.Player)
	}
	replay, err := s.Fight(ctx, a, command, op())
	if err != nil || replay.Win != result.Win || string(replay.Report) != string(result.Report) {
		t.Fatal("identical FIGHT must return the recorded battle", err)
	}
	if scalar(t, pool, `SELECT count(*) FROM arena_records`) != 2 || scalar(t, pool, `SELECT count(*) FROM arena_partner_usage WHERE player_id=$1`, int64(a.PlayerID)) != 5 ||
		scalar(t, pool, `SELECT count(*) FROM combat_attempts c JOIN arena_matches m ON m.attempt_id=c.attempt_id WHERE c.state='TERMINAL'`) != 1 {
		t.Fatal("records, usage and terminal attempt")
	}
	if scalar(t, pool, `SELECT COALESCE(max(current),0) FROM achievement_streaks WHERE player_id=$1 AND achievement_id=100003`, int64(a.PlayerID)) != result.Player.KeepWin {
		t.Fatal("Achievement 100003 follows the attack win streak")
	}
	records, err := s.Records(ctx, b)
	if err != nil || len(records) != 1 || records[0].Record.Attack || records[0].Record.Win == result.Win || records[0].Opponent.Player != a.PlayerID {
		t.Fatal("defender record", err)
	}
	if report, found, err := s.Report(ctx, records[0].ReportKey); err != nil || !found || len(report) == 0 {
		t.Fatal("record report", err)
	}
	partners, err := s.Partners(ctx, a)
	if err != nil || len(partners.Usage) != 5 || partners.Player.TotalFight != 1 {
		t.Fatal("partners", err)
	}

	// D07: practice changes nothing; STOP and an abandoned START settle a loss without a battle.
	exec(t, pool, `UPDATE arena_players SET star=12 WHERE player_id=$1`, int64(a.PlayerID))
	practice := arenaFight(t, s, a, b.PlayerID, true)
	if practice.Player.Star != 12 || practice.Player.TotalFight != 1 || len(practice.Report) == 0 || scalar(t, pool, `SELECT count(*) FROM arena_records`) != 2 {
		t.Fatalf("practice %+v", practice.Player)
	}
	if _, err = s.Match(ctx, a, false, op()); err != nil {
		t.Fatal(err)
	}
	if err = s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	stopped, err := s.Stop(ctx, a, b.PlayerID, op())
	if err != nil || stopped.Star != 11 || stopped.TotalFight != 2 || stopped.KeepWin != 0 {
		t.Fatalf("stop %+v %v", stopped, err)
	}
	if _, err = s.Match(ctx, a, false, op()); err != nil {
		t.Fatal(err)
	}
	if err = s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE arena_matches SET started_at=started_at-interval '11 minutes' WHERE attacker_id=$1 AND status='STARTED'`, int64(a.PlayerID))
	timed, err := gen.Binder{Time: pg.AuthoritativeTime{Queryer: pool}}.Bind(ctx, op())
	if err != nil {
		t.Fatal(err)
	}
	if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 50); err != nil {
		t.Fatal(err)
	}
	if scalar(t, pool, `SELECT star FROM arena_players WHERE player_id=$1`, int64(a.PlayerID)) != 10 || scalar(t, pool, `SELECT count(*) FROM arena_matches WHERE attacker_id=$1 AND status IN ('STARTED','FIGHTING')`, int64(a.PlayerID)) != 0 {
		t.Fatal("abandoned START settles as a loss")
	}

	// D08: missions claim king_coin, give up empties a slot; exchanges cost king_coin per season.
	exec(t, pool, `UPDATE arena_players SET missions='[{"mission_id":1003,"current_num":18,"is_complete":true},{"mission_id":1006,"current_num":5,"is_complete":true},{"mission_id":1010,"current_num":1,"is_complete":false}]'::jsonb WHERE player_id=$1`, int64(a.PlayerID))
	claimed, err := s.ClaimMission(ctx, a, 1003, op())
	if err != nil || claimed.KingCoin != 320 || len(claimed.Player.Missions) != 2 {
		t.Fatalf("claim %+v %+v %v", claimed.KingCoin, claimed.Player.Missions, err)
	}
	if _, err = s.ClaimMission(ctx, a, 1010, op()); err == nil {
		t.Fatal("an incomplete mission was claimed")
	}
	if gave, err := s.GiveUpMission(ctx, a, 1010, op()); err != nil || len(gave.Player.Missions) != 1 {
		t.Fatal("give up", err)
	}
	exchanged, err := s.Exchange(ctx, a, d.ExchangeStar, 10001001, op())
	if err != nil || exchanged.KingCoin != 50 || exchanged.Award == nil || exchanged.Award.AddStar != 1 || exchanged.Player.ExchangeTimes[0] != 1 {
		t.Fatalf("star exchange %+v %v", exchanged, err)
	}
	if _, err = s.Exchange(ctx, a, d.ExchangeSummon, 10001040, op()); err == nil {
		t.Fatal("summon without enough king_coin")
	}

	// D09/D10: the closed season mails every participant by level, the Challenger champion once; the next season resets.
	exec(t, pool, `UPDATE arena_players SET season=$1,star=95,point=40,total_fight=3,win_times=3,keep_win=0 WHERE player_id=$2`, season.Number-1, int64(b.PlayerID))
	exec(t, pool, `UPDATE arena_players SET season=$1,star=20,total_fight=4,win_times=1,keep_win=0 WHERE player_id=$2`, season.Number-1, int64(a.PlayerID))
	exec(t, pool, `UPDATE arena_players SET season=$1 WHERE player_id NOT IN ($2,$3)`, season.Number, int64(a.PlayerID), int64(b.PlayerID))
	exec(t, pool, `UPDATE arena_competitions SET settled_through=$1,state_version=state_version+1`, season.Number-2)
	settled, err := s.Due(ctx, op())
	if err != nil || settled != 1 {
		t.Fatal("season settlement", settled, err)
	}
	if again, err := s.Due(ctx, op()); err != nil || again != 0 {
		t.Fatal("settlement replays once", again, err)
	}
	if scalar(t, pool, `SELECT count(*) FROM arena_settlement_ranks WHERE season=$1`, season.Number-1) != 2 ||
		scalar(t, pool, `SELECT count(*) FROM arena_settlement_ranks WHERE season=$1 AND champion AND player_id=$2`, season.Number-1, int64(b.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ARENA_CHAMPION'`, int64(b.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='ARENA_SEASON_REWARD'`, int64(a.PlayerID)) != 1 {
		t.Fatal("settlement rows and mails")
	}
	next, err := s.Info(ctx, a, op())
	if err != nil || next.Player.Season != season.Number || next.Player.Star != 0 || len(next.Player.Awards) != 0 || next.Player.ExchangeTimes != [3]int64{} {
		t.Fatalf("next season reset %+v %v", next.Player, err)
	}
	ranks, err := s.RankList(ctx, a)
	if err != nil || len(ranks.Rows) == 0 || ranks.Mine.Face.Player != a.PlayerID {
		t.Fatal("rank list", err)
	}
}

func TestI7C5DArenaSummonedGirlsAndConcurrentEntryNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := arenaService(t, pool)
	a, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))

	// Concurrent first entries of one player create one row.
	errs := make(chan error, 2)
	for range 2 {
		go func() {
			_, err := s.Info(ctx, a, op())
			errs <- err
		}()
	}
	for range 2 {
		if err := <-errs; err != nil {
			t.Fatal(err)
		}
	}
	if _, err := s.Info(ctx, b, op()); err != nil {
		t.Fatal(err)
	}
	if scalar(t, pool, `SELECT count(*) FROM arena_players WHERE player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("one entry per player")
	}
	for _, pid := range []identity.PlayerID{a.PlayerID, b.PlayerID} {
		exec(t, pool, `INSERT INTO player_currency_balances(player_id,resource_key,amount,updated_at)VALUES($1,'king_coin',5000,now()) ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=5000`, int64(pid))
	}

	// D08 award effects: the defender summons and awakens a girl and stars up an owned one.
	for _, x := range []struct{ kind, table int64 }{{d.ExchangeSummon, 10001040}, {d.ExchangeAwaken, 10001040}, {d.ExchangeStar, 10001001}} {
		if _, err := s.Exchange(ctx, b, x.kind, x.table, op()); err != nil {
			t.Fatal(x, err)
		}
	}
	if _, err := s.Exchange(ctx, b, d.ExchangeSummon, 10001040, op()); err == nil {
		t.Fatal("a summoned girl summoned twice")
	}
	defense := []int64{10001040, 10001001, 10001002, 10001003, 10001004}
	if _, err := s.ModifyDefence(ctx, b, defense, 0, op()); err != nil {
		t.Fatal("a summoned girl defends", err)
	}
	if _, err := s.Exchange(ctx, a, d.ExchangeSummon, 10001041, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE arena_players SET defense=jsonb_build_object('heroes','[]'::jsonb,'pet',0) WHERE player_id<>$1`, int64(b.PlayerID))
	enemy, err := s.Match(ctx, a, false, op())
	if err != nil || enemy.Face.Player != b.PlayerID || len(enemy.Heroes) != 5 {
		t.Fatal("match", err)
	}
	if enemy.Heroes[0]["table_id"] != int64(11001040) || enemy.Heroes[1]["star"] == nil {
		t.Fatalf("awarded lineup rows %v", enemy.Heroes[0]["table_id"])
	}
	if err = s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	result, err := fightSettled(s, a, app.FightCommand{Enemy: b.PlayerID, Formation: []int64{10001041, 10001002, 10001003, 10001004, 10001005}})
	if err != nil {
		t.Fatal(err)
	}
	var report struct {
		Fighter map[string]struct {
			Hero struct {
				TableID int64 `json:"table_id"`
				Lev     int64 `json:"lev"`
			} `json:"hero"`
		} `json:"fighter"`
	}
	if err = json.Unmarshal(result.Report, &report); err != nil {
		t.Fatal(err)
	}
	seen := map[int64]int64{}
	for _, f := range report.Fighter {
		seen[f.Hero.TableID] = f.Hero.Lev
	}
	if seen[10001041] != 100 || seen[11001040] != 100 || seen[10001001] != 100 {
		t.Fatalf("summoned, awakened and balanced girls fought %v", seen)
	}
}

// stalledArena withholds resolution from FIGHT, as if the client vanished.
type stalledArena struct{ app.Combat }

func (stalledArena) ResolveDetached(context.Context, operation.Context, ids.UUID) *combat.Flight {
	f := &combat.Flight{Done: make(chan struct{}), Err: cd.ErrResolverRetryable}
	close(f.Done)
	return f
}

// D05: a fight left unresolved by its request is resolved and settled once by the reconcile provider.
func TestI7C5DArenaReconcileUnresolvedFightNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	s := arenaService(t, pool)
	a, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	b, _ := oneOnOnePlayer(t, pool, rankingServer(t, pool))
	for _, x := range []identity.ActorContext{a, b} {
		if _, err := s.Info(ctx, x, op()); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := s.ModifyDefence(ctx, b, arenaGirls(5), 0, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, pool, `UPDATE arena_players SET defense=jsonb_build_object('heroes','[]'::jsonb,'pet',0) WHERE player_id<>$1`, int64(b.PlayerID))
	if _, err := s.Match(ctx, a, false, op()); err != nil {
		t.Fatal(err)
	}
	if err := s.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	stalled := s
	stalled.Combat = stalledArena{s.Combat}
	if _, err := stalled.Fight(ctx, a, app.FightCommand{Enemy: b.PlayerID, Formation: arenaGirls(5)}, op()); err == nil {
		t.Fatal("an unresolved fight must not answer a result")
	}
	exec(t, pool, `UPDATE arena_matches SET started_at=started_at-interval '5 minutes' WHERE attacker_id=$1`, int64(a.PlayerID))
	timed, err := gen.Binder{Time: pg.AuthoritativeTime{Queryer: pool}}.Bind(ctx, op())
	if err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if _, err = (app.Reconciler{Service: s}).Reconcile(ctx, timed, 50); err != nil {
			t.Fatal(err)
		}
	}
	if scalar(t, pool, `SELECT count(*) FROM arena_matches WHERE attacker_id=$1 AND status='SETTLED'`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT count(*) FROM arena_records WHERE owner_player_id=$1`, int64(a.PlayerID)) != 1 ||
		scalar(t, pool, `SELECT total_fight FROM arena_players WHERE player_id=$1`, int64(a.PlayerID)) != 1 {
		t.Fatal("unresolved fight not settled once")
	}
}
