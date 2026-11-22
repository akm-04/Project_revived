//go:build postgres

package playerdisplay_test

import (
	"slices"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	apparena "gxb.local/backend/v2/internal/application/arena"
	appmarch "gxb.local/backend/v2/internal/application/march"
	arena "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/guild"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// missionRow reads one partner mission row's process/state; state 0 means the
// row does not exist.
func missionRow(t *testing.T, p *pg.Pool, player identity.PlayerID, partner, mission int64) (int64, int64) {
	t.Helper()
	var process, state int64
	if e := p.QueryRow(ctx, `SELECT COALESCE(MAX(process),0),COALESCE(MAX(mission_state),0) FROM player_library_partner_missions WHERE player_id=$1 AND partner_id=$2 AND mission_id=$3`, int64(player), partner, mission).Scan(&process, &state); e != nil {
		t.Fatal(e)
	}
	return process, state
}

func missionRowCount(t *testing.T, p *pg.Pool, player identity.PlayerID, mission, state int64) int64 {
	t.Helper()
	return scalar(t, p, `SELECT count(*) FROM player_library_partner_missions WHERE player_id=$1 AND mission_id=$2 AND mission_state=$3`, int64(player), mission, state)
}

// A-206 R7 #1002: a settled friend-fight duel advances mission 1002 for both
// participants' fielded girls; a replayed settlement adds nothing.
func TestI9_12R7Mission1002FriendFightNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	service := arenaService(t, p)
	server := rankingServer(t, p)
	first, firstHeroes := oneOnOnePlayer(t, p, server)
	second, _ := oneOnOnePlayer(t, p, server)
	clock := &workplaceTime{at: time.Now().UTC().Add(time.Hour)}
	service.Timed.Binder.Time = clock
	for _, actor := range []identity.ActorContext{first, second} {
		exec(t, p, `UPDATE account_sessions SET absolute_expires_at=$2,idle_timeout_seconds=NULL WHERE session_id=$1`, actor.SessionID.UUID().String(), clock.at.Add(24*time.Hour))
		exec(t, p, `UPDATE player_directory_profiles SET lev=55 WHERE player_id=$1`, int64(actor.PlayerID))
		transaction, err := p.Begin(ctx, tx.Options{})
		if err != nil {
			t.Fatal(err)
		}
		if err = (characterstore.PetBootstrapContributor{}).PersistCharacterBootstrap(ctx, transaction, logicalserver.BootstrapContext{PlayerID: actor.PlayerID, Operation: op()}); err != nil {
			transaction.Rollback(ctx)
			t.Fatal(err)
		}
		if err = transaction.Commit(ctx); err != nil {
			t.Fatal(err)
		}
	}
	dodgeballFriends(t, p, first.PlayerID, second.PlayerID, clock.at.Add(-time.Minute))
	command := apparena.FriendFightCommand{Player: second.PlayerID, Mode: 1, GameType: 1}
	if _, err := service.InviteFriendFight(ctx, first, command, op()); err != nil {
		t.Fatal(err)
	}
	accept := command
	accept.Player = first.PlayerID
	room, err := service.AcceptFriendFight(ctx, second, accept, op())
	if err != nil {
		t.Fatal(err)
	}
	if _, err = service.ReadyTournament(ctx, first, room.Identifier, op()); err != nil {
		t.Fatal(err)
	}
	clock.at = room.StartsAt
	if _, err = service.ReconcileTournamentSelection(ctx, room.Identifier, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = service.SelectTournament(ctx, first, apparena.TournamentSelectionCommand{Room: room.Identifier, Team: 1, Turn: 0, Formation: arena.SelectedFormation{Heroes: firstHeroes[:1]}}, op()); err != nil {
		t.Fatal(err)
	}
	clock.at = room.StartsAt.Add(20 * time.Minute)
	if _, err = service.ReconcileTournamentSelection(ctx, room.Identifier, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = service.StartTournamentCombat(ctx, room.Identifier, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = service.ResolveTournamentCombat(ctx, room.Identifier, op()); err != nil {
		t.Fatal(err)
	}
	process, state := missionRow(t, p, first.PlayerID, firstHeroes[0], lib.FriendFightMissionID)
	if process != 1 || state != lib.MissionSuccess {
		t.Fatalf("first participant mission 1002 = %d/%d", process, state)
	}
	if others := missionRowCount(t, p, second.PlayerID, lib.FriendFightMissionID, lib.MissionSuccess); others < 1 {
		t.Fatal("second participant mission 1002 did not advance")
	}
	before := missionRowCount(t, p, first.PlayerID, lib.FriendFightMissionID, lib.MissionSuccess)
	if _, err = service.ResolveTournamentCombat(ctx, room.Identifier, op()); err != nil {
		t.Fatal("replayed settlement", err)
	}
	process, state = missionRow(t, p, first.PlayerID, firstHeroes[0], lib.FriendFightMissionID)
	if process != 1 || state != lib.MissionSuccess || missionRowCount(t, p, first.PlayerID, lib.FriendFightMissionID, lib.MissionSuccess) != before {
		t.Fatal("replayed settlement advanced 1002 again")
	}
	// The forwarded fixture clock created a future-dated competition root; keep
	// it usable for later arena tests sharing this native database.
	exec(t, p, `UPDATE arena_competitions SET created_at=LEAST(created_at,clock_timestamp()),updated_at=GREATEST(updated_at,clock_timestamp())`)
}

// A-206 R7 #1003: a charged hero loan advances the lender's mission 1003
// once; a replayed START charges and advances nothing.
func TestI9_12R7Mission1003RentalNative(t *testing.T) {
	f := newRentalFixture(t)
	if err := f.service.Place(ctx, f.lender, guild.RentalHero, f.hero, opPinned(f.revision)); err != nil {
		t.Fatal("place", err)
	}
	if _, err := f.borrow(t, "mission1003", 1, f.hero, 0); err != nil {
		t.Fatal("lend", err)
	}
	process, state := missionRow(t, f.pool, f.lender.PlayerID, f.hero, lib.RentalMissionID)
	if process != 1 || state != lib.MissionSuccess {
		t.Fatalf("lender mission 1003 = %d/%d", process, state)
	}
	replay, err := f.borrow(t, "mission1003", 1, f.hero, 0)
	if err != nil || !replay.Replayed {
		t.Fatalf("replayed START %+v %v", replay, err)
	}
	process, state = missionRow(t, f.pool, f.lender.PlayerID, f.hero, lib.RentalMissionID)
	if process != 1 || state != lib.MissionSuccess || missionRowCount(t, f.pool, f.lender.PlayerID, lib.RentalMissionID, lib.MissionSuccess) != 1 {
		t.Fatal("replayed START advanced 1003 again")
	}
}

// A-206 R7 #1004: a winning Champion battle advances mission 1004 for the owned
// girls in the formation once the favor stage unlocks it, and a replayed
// settlement adds nothing. A win below the stage leaves no row.
func TestI9_12R7Mission1004MarchNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	a, revision := bornActor(t, p), installed(t, p)
	mode := marchMode(t, p)
	bornHero(t, p, a, revision, 10001001, 1)
	compositeLevel(t, p, a, revision, 30)
	if _, err := mode.Load(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	team := []int64{1, 0, 0, 0, 0}
	settle := func() {
		stage := marchRecord(t, p, a).NextStage()
		if _, err := mode.Start(ctx, a, appmarch.Fight{Formation: team}, op()); err != nil {
			t.Fatal(err)
		}
		q := marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true)
		if _, err := mode.Result(ctx, a, q, op()); err != nil {
			t.Fatal(err)
		}
		if _, err := mode.Chest(ctx, a, stage, op()); err != nil {
			t.Fatal(err)
		}
	}
	settle()
	if _, state := missionRow(t, p, a.PlayerID, 1, lib.ChampionMissionID); state != 0 {
		t.Fatalf("locked mission 1004 advanced state=%d", state)
	}
	exec(t, p, `UPDATE player_library_heroes SET favor_degree=801 WHERE player_id=$1 AND partner_id=1`, int64(a.PlayerID))
	if _, err := mode.Start(ctx, a, appmarch.Fight{Formation: team}, op()); err != nil {
		t.Fatal(err)
	}
	q := marchReport(marchRecord(t, p, a), int64(a.PlayerID), team, true)
	resultOperation := op()
	if _, err := mode.Result(ctx, a, q, resultOperation); err != nil {
		t.Fatal(err)
	}
	process, state := missionRow(t, p, a.PlayerID, 1, lib.ChampionMissionID)
	if process != 1 || state != lib.MissionProceed {
		t.Fatalf("won Champion 1004 = %d/%d", process, state)
	}
	if _, err := mode.Result(ctx, a, q, resultOperation); err != nil {
		t.Fatal("replayed result", err)
	}
	process, state = missionRow(t, p, a.PlayerID, 1, lib.ChampionMissionID)
	if process != 1 || state != lib.MissionProceed {
		t.Fatalf("replayed result advanced 1004 to %d/%d", process, state)
	}
}

// A-206 R7 #1005: the donor's matching girl advances mission 1005 on the gift;
// the same settlement replayed adds nothing.
func TestI9_12R7Mission1005TeaNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	revision := installed(t, p)
	donor, receiver := bornActor(t, p), bornActor(t, p)
	guildFixture(t, p, donor, receiver)
	bornHero(t, p, donor, revision, 10001001, 1)
	bornHero(t, p, receiver, revision, 10001001, 1)
	exec(t, p, `UPDATE player_library_heroes SET favor_degree=301 WHERE player_id=$1 AND partner_id=1`, int64(donor.PlayerID))
	scroll := scrollForHero(t, p, revision, 10001001)
	exec(t, p, `INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)VALUES($1,$2,1,1,clock_timestamp()-interval '1 hour',clock_timestamp()-interval '1 hour')`, int64(donor.PlayerID), scroll)
	service := teaService(p)
	if _, err := service.Request(ctx, receiver, scroll, op()); err != nil {
		t.Fatal("wish", err)
	}
	presentOperation := op()
	if _, err := service.Present(ctx, donor, receiver.PlayerID, presentOperation); err != nil {
		t.Fatal("present", err)
	}
	process, state := missionRow(t, p, donor.PlayerID, 1, lib.TeaPartyMissionID)
	if process != 1 || state != lib.MissionSuccess {
		t.Fatalf("donor mission 1005 = %d/%d", process, state)
	}
	if _, err := service.Present(ctx, donor, receiver.PlayerID, presentOperation); err == nil {
		t.Fatal("replayed present paid a second scroll")
	}
	process, state = missionRow(t, p, donor.PlayerID, 1, lib.TeaPartyMissionID)
	if process != 1 || state != lib.MissionSuccess || missionRowCount(t, p, donor.PlayerID, lib.TeaPartyMissionID, lib.MissionSuccess) != 1 {
		t.Fatal("replayed present advanced 1005 again")
	}
}

// A-206 R7 #1006: a ranked arena match advances mission 1006 for each owned girl
// with kills > 0 whose table id also fielded on the other side; practice and a
// replayed result add nothing. Victim attribution stays UNKNOWN.
func TestI9_12R7Mission1006RankedArenaNative(t *testing.T) {
	p := pool(t)
	defer p.Close()
	service := arenaService(t, p)
	server := rankingServer(t, p)
	a, _ := oneOnOnePlayer(t, p, server)
	b, _ := oneOnOnePlayer(t, p, server)
	if _, err := service.Info(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err := service.Info(ctx, b, op()); err != nil {
		t.Fatal(err)
	}
	// Mission 1006 unlocks at the 2000 favor stage; only the fielded girls need it.
	exec(t, p, `UPDATE player_library_heroes SET favor_degree=2000 WHERE player_id IN ($1,$2) AND partner_id BETWEEN 1 AND 5`, int64(a.PlayerID), int64(b.PlayerID))
	if _, err := service.ModifyDefence(ctx, b, arenaGirls(5), 0, op()); err != nil {
		t.Fatal(err)
	}
	exec(t, p, `UPDATE arena_players SET defense=jsonb_build_object('heroes','[]'::jsonb,'pet',0) WHERE player_id<>$1`, int64(b.PlayerID))
	if _, err := service.Match(ctx, a, false, op()); err != nil {
		t.Fatal(err)
	}
	if err := service.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	result, err := fightSettled(service, a, apparena.FightCommand{Enemy: b.PlayerID, Formation: arenaGirls(5)})
	if err != nil {
		t.Fatal(err)
	}
	attackerUses, err := cd.Usage(result.Report, "A", result.Win)
	if err != nil {
		t.Fatal(err)
	}
	defenderUses, err := cd.Usage(result.Report, "B", !result.Win)
	if err != nil {
		t.Fatal(err)
	}
	expectedAttacker := killedSameTablePartners(attackerUses, defenderUses)
	expectedDefender := killedSameTablePartners(defenderUses, attackerUses)
	if len(expectedAttacker) == 0 && len(expectedDefender) == 0 {
		t.Fatalf("settled report carried no qualifying kill: A=%+v B=%+v", attackerUses, defenderUses)
	}
	assertMissionPartners(t, p, a.PlayerID, lib.PvPKillMissionID, expectedAttacker)
	assertMissionPartners(t, p, b.PlayerID, lib.PvPKillMissionID, expectedDefender)

	before := missionRowCount(t, p, a.PlayerID, lib.PvPKillMissionID, lib.MissionSuccess) + missionRowCount(t, p, b.PlayerID, lib.PvPKillMissionID, lib.MissionSuccess)
	if _, err = service.Fight(ctx, a, apparena.FightCommand{Enemy: b.PlayerID, Formation: arenaGirls(5)}, op()); err != nil {
		t.Fatal("replayed result", err)
	}
	after := missionRowCount(t, p, a.PlayerID, lib.PvPKillMissionID, lib.MissionSuccess) + missionRowCount(t, p, b.PlayerID, lib.PvPKillMissionID, lib.MissionSuccess)
	if after != before {
		t.Fatal("replayed ranked result advanced 1006 again")
	}
	if _, err = service.Match(ctx, a, true, op()); err != nil {
		t.Fatal("practice match", err)
	}
	if err = service.Start(ctx, a, op()); err != nil {
		t.Fatal(err)
	}
	if _, err = fightSettled(service, a, apparena.FightCommand{Enemy: b.PlayerID, Practice: true, Formation: arenaGirls(5)}); err != nil {
		t.Fatal("practice fight", err)
	}
	if practice := missionRowCount(t, p, a.PlayerID, lib.PvPKillMissionID, lib.MissionSuccess) + missionRowCount(t, p, b.PlayerID, lib.PvPKillMissionID, lib.MissionSuccess); practice != before {
		t.Fatal("practice advanced 1006")
	}
}

// killedSameTablePartners mirrors the R7 rule independently of the server: a
// side's killer whose table id also fought on the opposite side.
func killedSameTablePartners(uses, opposite []cd.PartnerUse) []int64 {
	tables := map[int64]bool{}
	for _, use := range opposite {
		tables[use.TableID] = true
	}
	partners := []int64{}
	for _, use := range uses {
		if use.Kills > 0 && tables[use.TableID] {
			partners = append(partners, use.PartnerID)
		}
	}
	return partners
}

func assertMissionPartners(t *testing.T, p *pg.Pool, player identity.PlayerID, mission int64, expected []int64) {
	t.Helper()
	rows, err := p.Raw().Query(ctx, `SELECT partner_id FROM player_library_partner_missions WHERE player_id=$1 AND mission_id=$2 AND mission_state=$3 ORDER BY partner_id`, int64(player), mission, lib.MissionSuccess)
	if err != nil {
		t.Fatal(err)
	}
	defer rows.Close()
	stored := []int64{}
	for rows.Next() {
		var partner int64
		if err = rows.Scan(&partner); err != nil {
			t.Fatal(err)
		}
		stored = append(stored, partner)
	}
	slices.Sort(expected)
	if err = rows.Err(); err != nil {
		t.Fatal(err)
	}
	if !slices.Equal(stored, expected) {
		t.Fatalf("player %d mission %d rows %v, want %v", player, mission, stored, expected)
	}
}
