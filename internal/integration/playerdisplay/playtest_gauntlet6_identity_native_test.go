//go:build postgres

package playerdisplay_test

import (
	"context"
	"fmt"
	"strconv"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	appadventure "gxb.local/backend/v2/internal/application/adventure"
	apparena "gxb.local/backend/v2/internal/application/arena"
	cb "gxb.local/backend/v2/internal/application/combat"
	d "gxb.local/backend/v2/internal/domain/adventure"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// arenaAdventureOpponents mirrors the production cmd/gxb-api adapter over the
// real Arena owner. The robot arm stays empty so no fallback can mask a miss.
type arenaAdventureOpponents struct{ arena apparena.Service }

func (o arenaAdventureOpponents) ArenaOpponentTx(c context.Context, q tx.Queryer, player identity.PlayerID, section int64, ordinal uint64) (appadventure.Opponent, bool, error) {
	defense, found, err := o.arena.AdventureOpponentTx(c, q, player, section, ordinal)
	if err != nil || !found {
		return appadventure.Opponent{}, found, err
	}
	return appadventure.Opponent{PlayerID: defense.PlayerID, Heroes: defense.Heroes, PetID: defense.PetID}, true, nil
}

func (arenaAdventureOpponents) RobotOpponentTx(context.Context, tx.Queryer, uint64) (appadventure.Opponent, bool, error) {
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

// TestPlaytestGauntlet6AdventureDefenderIdentityNative is expected RED until the
// lead's typed Arena->Adventure boundary lands. It saves a production Arena
// defense by table id, observes the real Arena opponent read, and requires the
// 2417 projection and 2419 fight to use the defender's owned partner ids.
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
	defense, found, err := opponents.ArenaOpponentTx(ctx, p, attacker.PlayerID, catalog.Limits.PVPRankingSection, 0)
	if err != nil || !found {
		t.Fatalf("real arena opponent found=%v err=%v", found, err)
	}
	if defense.PlayerID != defender.PlayerID || len(defense.Heroes) != len(tableIDs) {
		t.Fatalf("arena opponent is not the saved defense: %+v", defense)
	}
	t.Logf("arena opponent player %d raw heroes %v", defense.PlayerID, defense.Heroes)

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
