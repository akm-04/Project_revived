//go:build postgres

package playerdisplay_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math"
	"strconv"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/nativebirth"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	app "gxb.local/backend/v2/internal/application/march"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// marchNewServer isolates the candidate pool so every ranked defense on it is
// a full-power fixture from this run.
func marchNewServer(t *testing.T, p *pg.Pool) identity.LogicalServerID {
	t.Helper()
	var server int64
	if e := p.QueryRow(ctx, `SELECT MIN(s) FROM generate_series(1,20000) s WHERE NOT EXISTS(SELECT 1 FROM logical_servers WHERE logical_server_id=s)`).Scan(&server); e != nil {
		t.Fatal(e)
	}
	exec(t, p, `INSERT INTO logical_servers(logical_server_id,name,directory_visible,existing_login_allowed,new_character_allowed,next_player_id,max_player_id,created_at)VALUES($1,'march-scale-test',true,true,true,$1*100000+25001,($1+1)*100000-1,clock_timestamp())`, server)
	return identity.LogicalServerID(server)
}

func marchActorOnServer(t *testing.T, p *pg.Pool, server identity.LogicalServerID) identity.ActorContext {
	t.Helper()
	a, account := playerRoot(t, p, server)
	if e := nativebirth.PersistBare(ctx, p, account, a.LogicalServerID, a.PlayerID); e != nil {
		t.Fatalf("fixture birth: %v", e)
	}
	for _, statement := range []string{
		`UPDATE player_profiles SET display_name='',avatar_id=110001001,avatar_frame_id=0,created_at=clock_timestamp()-interval '1 day',updated_at=clock_timestamp()-interval '1 day' WHERE player_id=$1`,
		`UPDATE player_progression SET exp=37,updated_at=clock_timestamp()-interval '1 day' WHERE player_id=$1`,
		`INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'crystal',1000,1,clock_timestamp()-interval '1 day') ON CONFLICT(player_id,resource_key) DO UPDATE SET amount=excluded.amount,updated_at=excluded.updated_at`,
	} {
		exec(t, p, statement, int64(a.PlayerID))
	}
	return a
}

func marchSetHeroLevel(t *testing.T, p *pg.Pool, a identity.ActorContext, partner, level int64) {
	t.Helper()
	h, e := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, a.PlayerID, partner)
	if e != nil {
		t.Fatal(e)
	}
	h.Level = level
	h.StateVersion++
	tr, e := p.Begin(ctx, tx.Options{})
	if e != nil {
		t.Fatal(e)
	}
	if e = (characterstore.Store{}).SaveHeroProgressionTx(ctx, tr, h, h.StateVersion-1); e != nil {
		tr.Rollback(ctx)
		t.Fatal(e)
	}
	if e = tr.Commit(ctx); e != nil {
		t.Fatal(e)
	}
}

func marchNumber(v any) int64 {
	switch x := v.(type) {
	case int64:
		return x
	case int:
		return int64(x)
	case float64:
		return int64(x)
	case json.Number:
		n, _ := x.Int64()
		return n
	}
	return 0
}

// TestI9_10MarchNativeScaledOpponentMatchesStageTarget builds one full-power
// opponent on its own server so the copied snapshot is the only real
// candidate. Stage targets must be met by scaling the copy, the frozen fight
// params must equal the displayed rows, and the stored defense must not move.
func TestI9_10MarchNativeScaledOpponentMatchesStageTarget(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := marchNewServer(t, p)
	requester := marchActorOnServer(t, p, server)
	opponent := marchActorOnServer(t, p, server)
	bornHero(t, p, requester, rev, 10001001, 1)
	marchSetHeroLevel(t, p, requester, 1, 100)
	compositeLevel(t, p, requester, rev, 30)
	defense := []int64{1, 2, 3, 4, 5}
	for _, id := range defense {
		bornHero(t, p, opponent, rev, 10001000+id, id)
		marchSetHeroLevel(t, p, opponent, id, 100)
	}
	compositeLevel(t, p, opponent, rev, 30)
	ladder := topFloorService(t, p)
	if _, err := ladder.Load(ctx, opponent, op()); err != nil {
		t.Fatal("opponent ladder entry", err)
	}
	if err := ladder.SaveDefense(ctx, opponent, defense, 0, op()); err != nil {
		t.Fatal("opponent defense", err)
	}
	storedBefore, found, err := ladder.Store.ReadPlayerTx(ctx, p, opponent.PlayerID, false)
	if err != nil || !found {
		t.Fatal("stored defense", err)
	}
	s, fight := marchModeWithCombat(t, p)
	if _, err = s.Load(ctx, requester, op()); err != nil {
		t.Fatal("load", err)
	}
	var power int64
	if err = coherentRead(t, p, rev, func(c context.Context, _ tx.Scope, scope ca.CoherentReadScope) error {
		result, e := rawBirthStats(p).HeroTx(c, scope, character.HeroRef{PlayerID: requester.PlayerID, PartnerID: 1}, publicstats.View{Kind: publicstats.Self, Viewer: requester.PlayerID})
		power = int64(math.Round(result.Stats.Force))
		return e
	}); err != nil || power <= 0 {
		t.Fatal("requester power", power, err)
	}
	var opponentForce int64
	if err = coherentRead(t, p, rev, func(c context.Context, _ tx.Scope, scope ca.CoherentReadScope) error {
		for _, id := range defense {
			result, e := rawBirthStats(p).HeroTx(c, scope, character.HeroRef{PlayerID: opponent.PlayerID, PartnerID: id}, publicstats.View{Kind: publicstats.Self, Viewer: opponent.PlayerID})
			if e != nil {
				return e
			}
			opponentForce += int64(math.Round(result.Stats.Force))
		}
		return nil
	}); err != nil {
		t.Fatal("opponent force", err)
	}
	t.Logf("requester power %d, opponent live force %d", power, opponentForce)
	catalog, err := (contentstore.Store{Queryer: p}).MarchCatalogTx(ctx, p, rev)
	if err != nil {
		t.Fatal("catalog", err)
	}
	factors := catalog.Factors("expedition_rival_param")
	record := marchRecord(t, p, requester)
	for _, stage := range []int64{1, 8, 15} {
		enemy := record.Enemies[stage-1]
		if enemy.Robot != 0 || enemy.Player != int64(opponent.PlayerID) {
			t.Fatalf("stage %d candidate is not the copied defense: %+v", stage, enemy)
		}
		target := float64(power) * factors[stage-1]
		t.Logf("stage %d: target %.0f, scaled force %d", stage, target, enemy.Force)
		if math.Abs(float64(enemy.Force)-target) > target*0.05 {
			t.Fatalf("stage %d force %d is outside 5%% of target %.0f", stage, enemy.Force, target)
		}
		for _, row := range enemy.Heroes {
			if marchNumber(row["lev"]) > 100 || marchNumber(row["star"]) > 5 || marchNumber(row["color"]) > 1 {
				t.Fatalf("stage %d scaled up: %+v", stage, row)
			}
		}
	}
	storedAfter, found, err := ladder.Store.ReadPlayerTx(ctx, p, opponent.PlayerID, false)
	if err != nil || !found || marchJSON(storedBefore.Defense) != marchJSON(storedAfter.Defense) {
		t.Fatalf("stored defense changed: %+v %+v %v", storedBefore.Defense, storedAfter.Defense, err)
	}
	for _, id := range defense {
		hero, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, opponent.PlayerID, id)
		if err != nil || hero.Level != 100 {
			t.Fatalf("owner hero %d changed: %+v %v", id, hero, err)
		}
	}
	if _, err = s.Start(ctx, requester, app.Fight{Formation: []int64{1, 0, 0, 0, 0}}, op()); err != nil {
		t.Fatal("start", err)
	}
	locator := cd.Locator{DomainKind: "CHAMPION_MARCH", AuthorityScope: fmt.Sprintf("server:%d", requester.LogicalServerID), DomainLocator: fmt.Sprintf("player:%d", requester.PlayerID)}
	attempt, found, err := fight.Store.FindUnresolvedTx(ctx, p, locator)
	if err != nil || !found {
		t.Fatal("frozen attempt", err)
	}
	raw, err := (combatstore.Store{}).ReadSnapshotTx(ctx, p, attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := cd.DecodeSnapshot(raw, attempt.SnapshotHash)
	if err != nil {
		t.Fatal(err)
	}
	displayed := marchRecord(t, p, requester).Enemies[0].Heroes
	actors := snapshot.Battle.WavesB[0]
	if len(actors) != len(defense) || len(displayed) != len(defense) {
		t.Fatalf("fight/display actor count %d/%d", len(actors), len(displayed))
	}
	for _, actor := range actors {
		row := displayed[strconv.FormatInt(actor.Identity, 10)]
		params := map[string]any{}
		decoder := json.NewDecoder(bytes.NewReader(actor.Params))
		decoder.UseNumber()
		if err = decoder.Decode(&params); err != nil {
			t.Fatal(err)
		}
		for _, key := range []string{"lev", "star", "color", "force"} {
			if marchNumber(params[key]) != marchNumber(row[key]) {
				t.Fatalf("fight actor %d %s = %v, display %v", actor.Identity, key, params[key], row[key])
			}
		}
	}
}
