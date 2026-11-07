//go:build postgres

package playerdisplay_test

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	apparena "gxb.local/backend/v2/internal/application/arena"
	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	darena "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// arenaAdventureOpponents mirrors the production cmd/gxb-api adapter over the
// real Arena owner. The robot arm stays empty so no fallback can mask a miss.
type arenaAdventureOpponents struct {
	arena apparena.Service
	// robotReads counts fallback reads so a refusal can prove the robot was
	// never consulted for a selected but unavailable defense.
	robotReads *int
}

func (o arenaAdventureOpponents) ArenaOpponentTx(c context.Context, q tx.Queryer, player identity.PlayerID, section int64, ordinal uint64, at time.Time) (appadventure.Opponent, bool, error) {
	defense, found, err := o.arena.AdventureOpponentTx(c, q, player, section, ordinal, at)
	if err != nil || !found {
		return appadventure.Opponent{}, found, err
	}
	return appadventure.Opponent{PlayerID: defense.PlayerID, Heroes: defense.Heroes, Pets: defense.Pets}, true, nil
}

func (o arenaAdventureOpponents) RobotOpponentTx(context.Context, tx.Queryer, uint64) (appadventure.Opponent, bool, error) {
	if o.robotReads != nil {
		*o.robotReads = *o.robotReads + 1
	}
	return appadventure.Opponent{}, false, nil
}

func productionHeroRows(t *testing.T, fight cb.Service, p *pg.Pool, player identity.PlayerID, at time.Time) map[string]any {
	t.Helper()
	detail := map[string]any{}
	if err := fight.Inputs.Heroes.OverlayMID1(ctx, p, identity.ActorContext{PlayerID: player}, false, at, detail); err != nil {
		t.Fatal("hero roster", err)
	}
	body, _ := detail["49"].(map[string]any)
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		t.Fatalf("hero roster shape %#v", detail)
	}
	return rows
}

func integerValue(t *testing.T, value any) int64 {
	t.Helper()
	n, err := strconv.ParseInt(fmt.Sprint(value), 10, 64)
	if err != nil {
		t.Fatalf("not an integer: %#v", value)
	}
	return n
}

// TestPlaytestGauntlet6AdventureDefenderIdentityNative saves a production
// Arena defense by table id, observes the real Arena opponent read, and requires
// the typed team, the 2417 projection and the 2419 fight to use the defender's
// owned partner ids.
func TestPlaytestGauntlet6AdventureDefenderIdentityNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	arena := arenaService(t, p)
	attacker, attackerHeroes := oneOnOnePlayer(t, p, server)
	defender, _ := oneOnOnePlayer(t, p, server)

	if _, err := arena.Info(ctx, attacker, op()); err != nil {
		t.Fatal("attacker arena entry", err)
	}
	if _, err := arena.Info(ctx, defender, op()); err != nil {
		t.Fatal("defender arena entry", err)
	}
	tableIDs := arenaGirls(5)
	if _, err := arena.ModifyDefence(ctx, defender, tableIDs, 0, op()); err != nil {
		t.Fatal("save real arena defense", err)
	}
	exec(t, p, `DELETE FROM arena_players WHERE player_id NOT IN ($1,$2)`, int64(attacker.PlayerID), int64(defender.PlayerID))

	revision := installed(t, p)
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)
		VALUES($1,68,$2,'gauntlet6:function:68',clock_timestamp()-interval '1 minute') ON CONFLICT(player_id,function_id)DO NOTHING`,
		int64(attacker.PlayerID), revision)

	fight := combatService(t, p)
	partnerByTable := map[int64]int64{}
	for partnerKey, raw := range productionHeroRows(t, fight, p, defender.PlayerID, time.Now().UTC()) {
		row, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		partnerID, err := strconv.ParseInt(partnerKey, 10, 64)
		if err != nil {
			continue
		}
		partnerByTable[integerValue(t, row["table_id"])] = partnerID
	}
	wantByTable := map[int64]int64{}
	for _, tableID := range tableIDs {
		partnerID, known := partnerByTable[tableID]
		if !known {
			t.Fatalf("defender owns no copy of table %d", tableID)
		}
		if partnerID == tableID {
			t.Fatalf("fixture partner id equals table id %d; identity collision not exercised", tableID)
		}
		wantByTable[tableID] = partnerID
		t.Logf("saved defense table %d is owner partner %d", tableID, partnerID)
	}

	catalog, err := (contentstore.Store{Queryer: p}).AdventureCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal("adventure catalog", err)
	}
	opponents := arenaAdventureOpponents{arena: arena}
	defense, found, err := opponents.ArenaOpponentTx(ctx, p, attacker.PlayerID, catalog.Limits.PVPRankingSection, 0, time.Now().UTC())
	if err != nil || !found {
		t.Fatalf("real arena opponent found=%v err=%v", found, err)
	}
	if defense.PlayerID != defender.PlayerID || len(defense.Heroes) != len(tableIDs) {
		t.Fatalf("arena opponent is not the saved defense: %+v", defense)
	}
	for index, participant := range defense.Heroes {
		tableID := tableIDs[index]
		if participant.Origin != cd.OwnedForeign || participant.Kind != cd.HeroActor || participant.Player != defender.PlayerID ||
			participant.Identity != wantByTable[tableID] || participant.TemplateParams != nil {
			t.Fatalf("saved table %d was not resolved to owned participant %+v", tableID, participant)
		}
	}
	t.Logf("arena opponent player %d typed heroes %+v", defense.PlayerID, defense.Heroes)

	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, opponents)
	opContext := opPinned(revision)
	opContext.StartedAt = clock.at
	putAdventureOccurrence(t, p, attacker.PlayerID, d.EventBattle, 0, clock.at, clock.at.Add(2*time.Hour), "gauntlet6-pvp")

	t.Run("enemy projection carries the defender's owned partner ids", func(t *testing.T) {
		info, err := mode.Info(ctx, attacker, d.EventBattle, opContext)
		if err != nil {
			t.Fatal("battle info", err)
		}
		enemy, _ := info["detail"].(map[string]any)["enemy_infos"].(map[string]any)
		if enemy["player_id"] != int64(defender.PlayerID) || enemy["is_robot"] != int64(0) {
			t.Fatalf("enemy_infos is not the Arena player: %#v", enemy)
		}
		heroes, _ := enemy["heroes"].([]any)
		if len(heroes) != len(wantByTable) {
			t.Fatalf("enemy_infos.heroes has %d rows, want %d: the saved table ids were not resolved to the defender's owned copies: %#v", len(heroes), len(wantByTable), enemy["heroes"])
		}
		seen := map[int64]int64{}
		for _, raw := range heroes {
			row, ok := raw.(map[string]any)
			if !ok {
				t.Fatalf("hero row shape %#v", raw)
			}
			tableID := integerValue(t, row["table_id"])
			partnerID, owned := wantByTable[tableID]
			if !owned {
				t.Fatalf("enemy hero table %d was never in the saved defense", tableID)
			}
			if got := integerValue(t, row["partner_id"]); got != partnerID {
				t.Fatalf("enemy hero %d shows partner_id %d, want the defender's owned copy %d", tableID, got, partnerID)
			}
			seen[partnerID] = tableID
		}
		if len(seen) != len(wantByTable) {
			t.Fatalf("enemy heroes repeat a partner id: %#v", seen)
		}
	})

	t.Run("fight resolves the real saved arena defense", func(t *testing.T) {
		response, err := mode.Fight(ctx, attacker, appadventure.FightRequest{Formation: []int64{attackerHeroes[0]}}, opContext)
		if err != nil {
			t.Fatalf("2419 fight against the real arena defense failed: %v", err)
		}
		if report, _ := response.Body["battle_report"].(string); report == "" {
			t.Fatal("2419 battle report missing")
		}
		if win, ok := response.Body["is_win"].(int64); !ok || (win != 0 && win != 1) {
			t.Fatalf("2419 is_win %#v", response.Body["is_win"])
		}
	})
}

// TestPlaytestGauntlet6AdventureMixedDefenderNative keeps owned, summoned and pet
// categories in one saved Arena defense: four owned girls whose partner ids
// differ from their table ids, one production season Summon, and an owned pet.
func TestPlaytestGauntlet6AdventureMixedDefenderNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	arena := arenaService(t, p)
	attacker, attackerHeroes := oneOnOnePlayer(t, p, server)
	defender, _ := oneOnOnePlayer(t, p, server)
	revision := installed(t, p)

	if _, err := arena.Info(ctx, attacker, op()); err != nil {
		t.Fatal("attacker arena entry", err)
	}
	if _, err := arena.Info(ctx, defender, op()); err != nil {
		t.Fatal("defender arena entry", err)
	}
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)
		VALUES($1,68,$2,'gauntlet6:function:68',clock_timestamp()-interval '1 minute') ON CONFLICT(player_id,function_id)DO NOTHING`,
		int64(attacker.PlayerID), revision)
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'king_coin',100000,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=100000`, int64(defender.PlayerID))
	exchanged, err := arena.Exchange(ctx, defender, darena.ExchangeSummon, 10001040, op())
	if err != nil || exchanged.Award == nil || !exchanged.Award.Summon {
		t.Fatalf("production summon award %+v %v", exchanged.Award, err)
	}
	pet := statPet(t, p, defender, revision)
	ownedTables := []int64{10001001, 10001002, 10001003, 10001004}
	summonTable := int64(10001040)
	formation := append(append([]int64{}, ownedTables...), summonTable)
	if _, err = arena.ModifyDefence(ctx, defender, formation, pet.PetID, op()); err != nil {
		t.Fatal("save mixed arena defense", err)
	}
	exec(t, p, `DELETE FROM arena_players WHERE player_id NOT IN ($1,$2)`, int64(attacker.PlayerID), int64(defender.PlayerID))

	fight := combatService(t, p)
	partnerByTable := map[int64]int64{}
	for partnerKey, raw := range productionHeroRows(t, fight, p, defender.PlayerID, time.Now().UTC()) {
		row, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		partnerID, err := strconv.ParseInt(partnerKey, 10, 64)
		if err != nil {
			continue
		}
		partnerByTable[integerValue(t, row["table_id"])] = partnerID
	}
	for _, tableID := range ownedTables {
		partnerID, known := partnerByTable[tableID]
		if !known || partnerID == tableID {
			t.Fatalf("owned fixture table %d is not an identity collision: %d", tableID, partnerID)
		}
	}

	catalog, err := (contentstore.Store{Queryer: p}).AdventureCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal("adventure catalog", err)
	}
	opponents := arenaAdventureOpponents{arena: arena}
	defense, found, err := opponents.ArenaOpponentTx(ctx, p, attacker.PlayerID, catalog.Limits.PVPRankingSection, 0, time.Now().UTC())
	if err != nil || !found || defense.PlayerID != defender.PlayerID {
		t.Fatalf("real arena opponent found=%v defense=%+v err=%v", found, defense, err)
	}
	if len(defense.Heroes) != len(formation) {
		t.Fatalf("mixed heroes %+v", defense.Heroes)
	}
	for index, tableID := range ownedTables {
		participant := defense.Heroes[index]
		if participant.Origin != cd.OwnedForeign || participant.Kind != cd.HeroActor || participant.Player != defender.PlayerID ||
			participant.Identity != partnerByTable[tableID] || participant.TemplateParams != nil {
			t.Fatalf("owned table %d resolved to %+v", tableID, participant)
		}
	}
	summoned := defense.Heroes[len(ownedTables)]
	params := summoned.TemplateParams
	if summoned.Origin != cd.Template || summoned.Kind != cd.HeroActor || summoned.Player.Valid() || summoned.Identity != summonTable ||
		params == nil || integerValue(t, params["player_id"]) != 0 || integerValue(t, params["partner_id"]) != summonTable || integerValue(t, params["table_id"]) != summonTable {
		t.Fatalf("summoned table %d resolved to %+v", summonTable, summoned)
	}
	if len(defense.Pets) != 1 {
		t.Fatalf("mixed pets %+v", defense.Pets)
	}
	if pets := defense.Pets[0]; pets.Origin != cd.OwnedForeign || pets.Kind != cd.PetActor || pets.Player != defender.PlayerID || pets.Identity != pet.PetID {
		t.Fatalf("owned pet resolved to %+v", pets)
	}

	clock := &leagueClock{at: time.Now().UTC().Add(2 * time.Minute)}
	mode := adventureTestMode(t, p, clock, opponents)
	opContext := opPinned(revision)
	opContext.StartedAt = clock.at
	putAdventureOccurrence(t, p, attacker.PlayerID, d.EventBattle, 0, clock.at, clock.at.Add(2*time.Hour), "gauntlet6-mixed-pvp")

	info, err := mode.Info(ctx, attacker, d.EventBattle, opContext)
	if err != nil {
		t.Fatal("mixed battle info", err)
	}
	enemy, _ := info["detail"].(map[string]any)["enemy_infos"].(map[string]any)
	rows, _ := enemy["heroes"].([]any)
	if enemy["player_id"] != int64(defender.PlayerID) || enemy["is_robot"] != int64(0) || len(rows) != len(formation) {
		t.Fatalf("mixed enemy_infos %#v", enemy)
	}
	for index, tableID := range ownedTables {
		row, _ := rows[index].(map[string]any)
		if integerValue(t, row["table_id"]) != tableID || integerValue(t, row["partner_id"]) != partnerByTable[tableID] {
			t.Fatalf("owned enemy row for table %d: %#v", tableID, rows[index])
		}
	}
	summonRow, _ := rows[len(ownedTables)].(map[string]any)
	if integerValue(t, summonRow["player_id"]) != 0 || integerValue(t, summonRow["partner_id"]) != summonTable || integerValue(t, summonRow["table_id"]) != summonTable {
		t.Fatalf("summoned enemy row: %#v", rows[len(ownedTables)])
	}
	petRow, _ := enemy["pet"].(map[string]any)
	if petRow == nil || integerValue(t, petRow["pet_id"]) != pet.PetID {
		t.Fatalf("enemy pet row: %#v", enemy["pet"])
	}

	response, err := mode.Fight(ctx, attacker, appadventure.FightRequest{Formation: []int64{attackerHeroes[0]}}, opContext)
	if err != nil {
		t.Fatalf("2419 mixed fight failed: %v", err)
	}
	if report, _ := response.Body["battle_report"].(string); report == "" {
		t.Fatal("2419 mixed battle report missing")
	}
}

func ownedPartnerByTable(t *testing.T, fight cb.Service, p *pg.Pool, player identity.PlayerID, at time.Time) map[int64]int64 {
	t.Helper()
	out := map[int64]int64{}
	for partnerKey, raw := range productionHeroRows(t, fight, p, player, at) {
		row, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		partnerID, err := strconv.ParseInt(partnerKey, 10, 64)
		if err != nil {
			continue
		}
		out[integerValue(t, row["table_id"])] = partnerID
	}
	return out
}

func textValue(t *testing.T, p *pg.Pool, sql string, args ...any) string {
	t.Helper()
	var value string
	if err := p.QueryRow(ctx, sql, args...).Scan(&value); err != nil {
		t.Fatal(sql, err)
	}
	return value
}

func persistedAdventureSnapshot(t *testing.T, p *pg.Pool, actor identity.PlayerID, generationRef string) cd.Snapshot {
	t.Helper()
	var hash string
	if err := p.QueryRow(ctx, `SELECT snapshot_hash FROM combat_attempts WHERE actor_player_id=$1 AND generation_ref=$2 ORDER BY started_at DESC LIMIT 1`, int64(actor), generationRef).Scan(&hash); err != nil {
		t.Fatalf("combat attempt for %s: %v", generationRef, err)
	}
	raw, err := (combatstore.Store{}).ReadSnapshotTx(ctx, p, hash)
	if err != nil {
		t.Fatalf("persisted combat snapshot %s: %v", hash, err)
	}
	snapshot, err := cd.DecodeSnapshot(raw, hash)
	if err != nil {
		t.Fatalf("decode combat snapshot %s: %v", hash, err)
	}
	return snapshot
}

// TestPlaytestGauntlet6AdventureAwardedDefenderNative saves a defense carrying
// production season awards (an owned star and a summoned, awakened girl). The
// real Arena read must hand those transforms to Adventure, 2419 must resolve,
// and the persisted combat snapshot must keep the qualified Arena context and
// the per-actor award parameters.
func TestPlaytestGauntlet6AdventureAwardedDefenderNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	arena := arenaService(t, p)
	attacker, attackerHeroes := oneOnOnePlayer(t, p, server)
	defender, _ := oneOnOnePlayer(t, p, server)
	revision := installed(t, p)
	decisionAt := time.Now().UTC().Add(2 * time.Minute)

	if _, err := arena.Info(ctx, attacker, op()); err != nil {
		t.Fatal("attacker arena entry", err)
	}
	if _, err := arena.Info(ctx, defender, op()); err != nil {
		t.Fatal("defender arena entry", err)
	}
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)
		VALUES($1,68,$2,'gauntlet6:function:68',clock_timestamp()-interval '1 minute') ON CONFLICT(player_id,function_id)DO NOTHING`,
		int64(attacker.PlayerID), revision)
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'king_coin',100000,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=100000`, int64(defender.PlayerID))

	starTable, summonTable := int64(10001001), int64(10001040)
	starred, err := arena.Exchange(ctx, defender, darena.ExchangeStar, starTable, op())
	if err != nil || starred.Award == nil || starred.Award.AddStar != 1 {
		t.Fatalf("production star award %+v %v", starred.Award, err)
	}
	summoned, err := arena.Exchange(ctx, defender, darena.ExchangeSummon, summonTable, op())
	if err != nil || summoned.Award == nil || !summoned.Award.Summon {
		t.Fatalf("production summon award %+v %v", summoned.Award, err)
	}
	awakened, err := arena.Exchange(ctx, defender, darena.ExchangeAwaken, summonTable, op())
	if err != nil || awakened.Award == nil || !awakened.Award.Awake || !awakened.Award.Summon {
		t.Fatalf("production awaken award %+v %v", awakened.Award, err)
	}

	tableIDs := []int64{summonTable, starTable, 10001002, 10001003, 10001004}
	if _, err = arena.ModifyDefence(ctx, defender, tableIDs, 0, op()); err != nil {
		t.Fatal("save awarded arena defense", err)
	}
	exec(t, p, `DELETE FROM arena_players WHERE player_id NOT IN ($1,$2)`, int64(attacker.PlayerID), int64(defender.PlayerID))

	fight := combatService(t, p)
	partnerByTable := ownedPartnerByTable(t, fight, p, defender.PlayerID, decisionAt)
	starPartner, known := partnerByTable[starTable]
	if !known || starPartner == starTable {
		t.Fatalf("fixture star table %d is not an identity collision: %d", starTable, starPartner)
	}

	catalog, err := (contentstore.Store{Queryer: p}).AdventureCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal("adventure catalog", err)
	}
	opponents := arenaAdventureOpponents{arena: arena}
	defense, found, err := opponents.ArenaOpponentTx(ctx, p, attacker.PlayerID, catalog.Limits.PVPRankingSection, 0, decisionAt)
	if err != nil || !found || defense.PlayerID != defender.PlayerID || len(defense.Heroes) != len(tableIDs) {
		t.Fatalf("real arena awarded opponent found=%v defense=%+v err=%v", found, defense, err)
	}
	byIdentity := map[int64]cb.Participant{}
	for _, participant := range defense.Heroes {
		byIdentity[participant.Identity] = participant
	}
	starredParticipant, ownedStar := byIdentity[starPartner]
	if !ownedStar || starredParticipant.Origin != cd.OwnedForeign || len(starredParticipant.Transform) != 1 || starredParticipant.Transform["arena_add_star"] != 1 {
		t.Fatalf("owned star award did not reach the typed opponent: %+v", starredParticipant)
	}
	summonedParticipant, summonKnown := byIdentity[summonTable]
	if !summonKnown || summonedParticipant.Origin != cd.Template || len(summonedParticipant.Transform) != 1 || summonedParticipant.Transform["arena_awake"] != 1 {
		t.Fatalf("summoned awaken award did not reach the typed opponent: %+v", summonedParticipant)
	}

	clock := &leagueClock{at: decisionAt}
	mode := adventureTestMode(t, p, clock, opponents)
	opContext := opPinned(revision)
	opContext.StartedAt = decisionAt
	putAdventureOccurrence(t, p, attacker.PlayerID, d.EventBattle, 0, decisionAt, decisionAt.Add(2*time.Hour), "gauntlet6-awarded-pvp")

	info, err := mode.Info(ctx, attacker, d.EventBattle, opContext)
	if err != nil {
		t.Fatalf("2417 awarded battle info failed: %v", err)
	}
	enemy, _ := info["detail"].(map[string]any)["enemy_infos"].(map[string]any)
	enemyHeroes, _ := enemy["heroes"].([]any)
	if enemy["player_id"] != int64(defender.PlayerID) || len(enemyHeroes) != len(tableIDs) {
		t.Fatalf("2417 awarded enemy_infos %#v", enemy)
	}

	response, err := mode.Fight(ctx, attacker, appadventure.FightRequest{Formation: []int64{attackerHeroes[0]}}, opContext)
	if err != nil {
		t.Fatalf("2419 fight against the awarded defense failed: %v", err)
	}
	if report, _ := response.Body["battle_report"].(string); report == "" {
		t.Fatal("2419 awarded battle report missing")
	}
	if win, ok := response.Body["is_win"].(int64); !ok || (win != 0 && win != 1) {
		t.Fatalf("2419 awarded is_win %#v", response.Body["is_win"])
	}
	if _, ok := response.Body["awards"].([]any); !ok {
		t.Fatalf("2419 awarded awards shape %#v", response.Body["awards"])
	}

	snapshot := persistedAdventureSnapshot(t, p, attacker.PlayerID, "ADVENTURE_PVP/gauntlet6-awarded-pvp")
	if snapshot.Battle.Context == nil || snapshot.Battle.Context.Transform != darena.Transform {
		t.Fatalf("persisted snapshot lost the qualified Arena context: %+v", snapshot.Battle.Context)
	}
	if snapshot.Battle.CampaignType != darena.CampaignType || snapshot.Battle.BattleID != darena.BattleID {
		t.Fatalf("persisted snapshot mode %d/%d", snapshot.Battle.CampaignType, snapshot.Battle.BattleID)
	}
	persistedTransforms := map[int64]map[string]int64{}
	for _, wave := range snapshot.Battle.WavesB {
		for _, actor := range wave {
			if len(actor.Transform) == 0 {
				continue
			}
			var transform map[string]int64
			if err := json.Unmarshal(actor.Transform, &transform); err != nil {
				t.Fatalf("persisted actor transform %s: %v", actor.Transform, err)
			}
			persistedTransforms[actor.Identity] = transform
		}
	}
	if persistedTransforms[starPartner]["arena_add_star"] != 1 {
		t.Fatalf("persisted star transform for %d: %#v", starPartner, persistedTransforms)
	}
	if persistedTransforms[summonTable]["arena_awake"] != 1 {
		t.Fatalf("persisted awake transform for %d: %#v", summonTable, persistedTransforms)
	}
}

// TestPlaytestGauntlet6AdventureUnavailableDefenderRefusesNative crosses a
// season boundary so a saved defense of production summons resolves empty.
// Arena must still select that player, Adventure 2417 and 2419 must refuse with
// ErrRefused, the robot fallback must stay untouched, and no attempt, cost,
// reward or occurrence finish may happen.
func TestPlaytestGauntlet6AdventureUnavailableDefenderRefusesNative(t *testing.T) {
	p := pool(t)
	server := rankingServer(t, p)
	arena := arenaService(t, p)
	attacker, attackerHeroes := oneOnOnePlayer(t, p, server)
	defender, _ := oneOnOnePlayer(t, p, server)
	revision := installed(t, p)

	if _, err := arena.Info(ctx, attacker, op()); err != nil {
		t.Fatal("attacker arena entry", err)
	}
	if _, err := arena.Info(ctx, defender, op()); err != nil {
		t.Fatal("defender arena entry", err)
	}
	exec(t, p, `INSERT INTO player_function_eligibility(player_id,function_id,content_revision,source_fact_key,eligible_at)
		VALUES($1,68,$2,'gauntlet6:function:68',clock_timestamp()-interval '1 minute') ON CONFLICT(player_id,function_id)DO NOTHING`,
		int64(attacker.PlayerID), revision)
	exec(t, p, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'king_coin',100000,1,clock_timestamp())
		ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=100000`, int64(defender.PlayerID))

	summonTables := []int64{10001040, 10001041, 10001042, 10001043, 10001044}
	for _, tableID := range summonTables {
		awarded, err := arena.Exchange(ctx, defender, darena.ExchangeSummon, tableID, op())
		if err != nil || awarded.Award == nil || !awarded.Award.Summon {
			t.Fatalf("production summon award for %d: %+v %v", tableID, awarded.Award, err)
		}
	}
	if _, err := arena.ModifyDefence(ctx, defender, summonTables, 0, op()); err != nil {
		t.Fatal("save summoned-only arena defense", err)
	}
	exec(t, p, `DELETE FROM arena_players WHERE player_id NOT IN ($1,$2)`, int64(attacker.PlayerID), int64(defender.PlayerID))

	readAt := time.Now().UTC()
	catalog, err := (contentstore.Store{Queryer: p}).AdventureCatalogTx(ctx, p, revision)
	if err != nil {
		t.Fatal("adventure catalog", err)
	}
	robotReads := 0
	opponents := arenaAdventureOpponents{arena: arena, robotReads: &robotReads}
	defense, found, err := opponents.ArenaOpponentTx(ctx, p, attacker.PlayerID, catalog.Limits.PVPRankingSection, 0, readAt)
	if err != nil || !found || defense.PlayerID != defender.PlayerID || len(defense.Heroes) != len(summonTables) {
		t.Fatalf("in-season summoned defense found=%v defense=%+v err=%v", found, defense, err)
	}
	for _, participant := range defense.Heroes {
		if participant.Origin != cd.Template {
			t.Fatalf("summoned defense is not template-sourced: %+v", participant)
		}
	}

	seasonCalendar := arenaCatalog(t, p)
	boundary := seasonCalendar.SeasonNumbered(seasonCalendar.SeasonAt(readAt).Number + 1).OpensAt
	decisionAt := boundary.Add(time.Minute)
	defense, found, err = opponents.ArenaOpponentTx(ctx, p, attacker.PlayerID, catalog.Limits.PVPRankingSection, 0, decisionAt)
	if err != nil || !found || defense.PlayerID != defender.PlayerID || len(defense.Heroes) != 0 || len(defense.Pets) != 0 {
		t.Fatalf("post-boundary arena read found=%v defense=%+v err=%v", found, defense, err)
	}

	clock := &leagueClock{at: decisionAt}
	mode := adventureTestMode(t, p, clock, opponents)
	opContext := opPinned(revision)
	opContext.StartedAt = decisionAt
	putAdventureOccurrence(t, p, attacker.PlayerID, d.EventBattle, 0, decisionAt, decisionAt.Add(2*time.Hour), "gauntlet6-unavailable-pvp")

	before := refusalSignature(t, p, attacker.PlayerID, defender.PlayerID)
	if _, err = mode.Info(ctx, attacker, d.EventBattle, opContext); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("2417 accepted a selected but unavailable defense: %v", err)
	}
	if _, err = mode.Fight(ctx, attacker, appadventure.FightRequest{Formation: []int64{attackerHeroes[0]}}, opContext); !errors.Is(err, d.ErrRefused) {
		t.Fatalf("2419 accepted a selected but unavailable defense: %v", err)
	}
	if robotReads != 0 {
		t.Fatalf("unavailable selected player was delegated to the robot fallback %d times", robotReads)
	}
	if after := refusalSignature(t, p, attacker.PlayerID, defender.PlayerID); after != before {
		t.Fatalf("refusal changed durable state\nbefore %s\nafter  %s", before, after)
	}
}

func refusalSignature(t *testing.T, p *pg.Pool, attacker, defender identity.PlayerID) string {
	t.Helper()
	balances := textValue(t, p, `SELECT COALESCE(jsonb_agg(jsonb_build_array(resource_key,amount) ORDER BY resource_key),'[]')::text FROM player_currency_balances WHERE player_id=$1`, int64(attacker))
	stacks := textValue(t, p, `SELECT COALESCE(jsonb_agg(jsonb_build_array(item_id,quantity) ORDER BY item_id),'[]')::text FROM player_item_stacks WHERE player_id=$1`, int64(attacker))
	attempts := textValue(t, p, `SELECT count(*)::text FROM combat_attempts WHERE actor_player_id=$1`, int64(attacker))
	finished := textValue(t, p, `SELECT COALESCE(finished_at::text,'') FROM adventure_occurrences WHERE player_id=$1 AND event_type=$2 ORDER BY occurred_at DESC LIMIT 1`, int64(attacker), d.EventBattle)
	arenaRow := textValue(t, p, `SELECT season::text||':'||state_version::text||':'||awards::text||':'||defense::text FROM arena_players WHERE player_id=$1`, int64(defender))
	return fmt.Sprintf("%s|%s|%s|%s|%s", balances, stacks, attempts, finished, arenaRow)
}
