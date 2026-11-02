//go:build postgres

package playerdisplay_test

import (
	"context"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	app "gxb.local/backend/v2/internal/application/championsleague"
	"gxb.local/backend/v2/internal/application/i5"
	display "gxb.local/backend/v2/internal/application/playerdisplay"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sync"
	"testing"
	"time"
)

type rejectedCharacterFunction struct{ i5.Store }

func (store rejectedCharacterFunction) InsertFunctionUnlockTx(requestContext context.Context, transaction tx.Tx, unlock player.FunctionUnlock) (bool, error) {
	inserted, err := store.Store.InsertFunctionUnlockTx(requestContext, transaction, unlock)
	if err == nil && inserted && unlock.FunctionID == 16 {
		return false, errors.New("injected after canonical function unlock insert")
	}
	return inserted, err
}
func TestI97DCharacterFunctionsNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	for _, race := range []bool{false, true} {
		t.Run(fmt.Sprint("concurrent-", race), func(t *testing.T) {
			actor, revision := companionActor(t, database), installed(t, database)
			owner := compositeI5(database)
			owner.CharacterFunctions = characterstore.FunctionPrerequisites{Store: characterstore.Store{Queryer: database}, Content: contentstore.Store{Queryer: database}}
			if _, err := owner.AdminGrant(ctx, authority().Operator, actor.PlayerID, uuid().String(), "i97d-fixture-mana", []grant.Line{{Kind: grant.ScalarCurrency, ResourceKey: "mana", Amount: 100000000}}, opPinned(revision)); err != nil {
				t.Fatal(err)
			}
			summoner := ownerSummoner(database)
			summoner.CharacterFunctions = owner
			exec(t, database, `UPDATE player_progression SET level=1,exp=0 WHERE player_id=$1`, int64(actor.PlayerID))
			rule, err := (contentstore.Store{}).ResolveProgressionPolicyTx(ctx, database, revision)
			if err != nil {
				t.Fatal(err)
			}
			raise := func(level int64) error {
				current, err := (i5store.Store{}).ReadProgressionTx(ctx, database, actor.PlayerID)
				if err != nil {
					return err
				}
				_, err = owner.AdminGrant(ctx, authority().Operator, actor.PlayerID, uuid().String(), "i97d-native", []grant.Line{{Kind: grant.PlayerExp, Amount: rule.Rows[level-2].TotalExp - current.Exp}}, opPinned(revision))
				return err
			}
			if !race {
				if err := raise(55); err != nil {
					t.Fatal(err)
				}
			}
			nextTable := int64(10001001)
			for scalar(t, database, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(actor.PlayerID)) < 14 {
				table := nextTable
				nextTable++
				if scalar(t, database, `SELECT count(*) FROM player_heroes WHERE player_id=$1 AND origin_table_id=$2`, int64(actor.PlayerID), table) > 0 {
					continue
				}
				policy := collectionResources(t, database, actor, revision, table)
				if _, err := summoner.SummonNormal(ctx, actor, table, policy.Template.FragmentItemID, policy.FragmentCount, op()); err != nil {
					t.Fatal(err)
				}
			}
			if count := scalar(t, database, `SELECT count(*) FROM player_function_unlocks WHERE player_id=$1 AND function_id IN(16,37,45)`, int64(actor.PlayerID)); count != 0 {
				t.Fatal("premature opening", count)
			}
			policy := collectionResources(t, database, actor, revision, nextTable)
			if !race {
				rejected := owner
				rejected.Store = rejectedCharacterFunction{owner.Store}
				failedSummoner := summoner
				failedSummoner.CharacterFunctions = rejected
				if _, err := failedSummoner.SummonNormal(ctx, actor, nextTable, policy.Template.FragmentItemID, policy.FragmentCount, op()); err == nil {
					t.Fatal("injected opening failure committed")
				}
				if count := scalar(t, database, `SELECT count(*) FROM player_heroes WHERE player_id=$1`, int64(actor.PlayerID)); count != 14 {
					t.Fatal("failed opening committed Hero", count)
				}
				if count := scalar(t, database, `SELECT count(*) FROM player_function_eligibility WHERE player_id=$1 AND function_id=16`, int64(actor.PlayerID)); count != 0 {
					t.Fatal("failed opening committed eligibility", count)
				}
			}
			request := op()
			summoner.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
			results := make(chan error, 2)
			var workers sync.WaitGroup
			workers.Add(1)
			go func() {
				defer workers.Done()
				_, err := summoner.SummonNormal(ctx, actor, nextTable, policy.Template.FragmentItemID, policy.FragmentCount, request)
				results <- err
			}()
			if race {
				workers.Add(1)
				go func() { defer workers.Done(); results <- raise(55) }()
			}
			workers.Wait()
			close(results)
			for err := range results {
				if err != nil {
					t.Fatal(err)
				}
			}
			if count := scalar(t, database, `SELECT count(*) FROM player_function_unlocks WHERE player_id=$1 AND function_id=16`, int64(actor.PlayerID)); count != 1 {
				t.Fatal("kind6 missed", count)
			}
			if err := raise(60); err != nil {
				t.Fatal(err)
			}
			if count := scalar(t, database, `SELECT count(*) FROM player_function_unlocks WHERE player_id=$1 AND function_id=37`, int64(actor.PlayerID)); count != 1 {
				t.Fatal("level-after-population", count)
			}
			transaction, err := database.Begin(ctx, tx.Options{Isolation: tx.Serializable})
			if err != nil {
				t.Fatal(err)
			}
			if err := owner.PrepareCharacterFunctionsTx(ctx, transaction, actor.PlayerID); err != nil {
				t.Fatal(err)
			}
			opened, err := owner.OpenCharacterFunctionsTx(ctx, transaction, actor.PlayerID, revision, time.Now().UTC())
			if err != nil || len(opened) != 0 {
				t.Fatal("duplicate opening", opened, err)
			}
			if err := transaction.Commit(ctx); err != nil {
				t.Fatal(err)
			}
		})
	}
}
func TestI97DLegacyLeagueTitlesNative(t *testing.T) {
	database := pool(t)
	defer database.Close()
	service, clock, catalog, first, second, hero, _ := leagueActors(t, database)
	at, _ := clock.Now(ctx)
	season := catalog.SeasonAt(at)
	fight := leagueFight(t, service, first, second, hero)
	if fight.Match.Attempt.IsZero() {
		t.Fatal("no genuine battle")
	}
	clock.Set(season.ClosesAt)
	lost := service
	lost.Timed.Runner.DB = &faultDB{Beginner: database, n: 2, commit: true}
	if err := lost.Due(ctx, op(), 100); err != nil {
		t.Fatal(err)
	}
	for _, actor := range []identity.ActorContext{first, second} {
		for _, title := range catalog.LegacyTitles {
			observed, err := service.ReadCatalogDisplayOriginsTx(ctx, database, display.CatalogOriginRequest{PlayerID: actor.PlayerID, Family: "title", CatalogID: title.Identifier, Revision: installed(t, database), ObservedAt: season.ClosesAt})
			if err != nil || !observed.Qualified || len(observed.Origins) != 1 {
				t.Fatal("legacy title proof", title, err)
			}
		}
		if count := scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='CHAMPIONS_LEAGUE_LEGACY_TITLE'`, int64(actor.PlayerID)); count != 3 {
			t.Fatal("missing title notification", count)
		}
		current, found, err := service.Store.SettlementTx(ctx, database, "SEASON", season.Number)
		if err != nil || !found || len(current.Rows) != 2 {
			t.Fatal(err)
		}
	}
	if err := service.Due(ctx, op(), 100); err != nil {
		t.Fatal(err)
	}
	if count := scalar(t, database, `SELECT count(*) FROM league_cosmetic_origins WHERE player_id=$1 AND family='title'`, int64(first.PlayerID)); count != 4 {
		t.Fatal("existing progression changed or duplicate legacy", count)
	}
	clock.Set(season.NextAt.Add(10 * time.Hour))
	if err := service.Due(ctx, op(), 100); err != nil {
		t.Fatal(err)
	}
	leagueDo(t, service, first, app.Command{Kind: "INFO"})
	leagueDo(t, service, second, app.Command{Kind: "INFO"})
	leagueFight(t, service, first, second, hero)
	nextSeason := catalog.SeasonNumbered(season.Number + 1)
	clock.Set(nextSeason.ClosesAt)
	if err := service.Due(ctx, op(), 100); err != nil {
		t.Fatal(err)
	}
	if count := scalar(t, database, `SELECT count(*) FROM mail_records WHERE recipient_player_id=$1 AND source_kind='CHAMPIONS_LEAGUE_LEGACY_TITLE'`, int64(first.PlayerID)); count != 3 {
		t.Fatal("later season duplicated legacy mail", count)
	}
	if count := scalar(t, database, `SELECT count(*) FROM league_cosmetic_origins WHERE player_id=$1 AND family='title'`, int64(first.PlayerID)); count != 5 {
		t.Fatal("second existing progression title missing", count)
	}
	exec(t, database, `UPDATE mail_records SET compatibility_policy_version='tampered' WHERE recipient_player_id=$1 AND source_kind='CHAMPIONS_LEAGUE_LEGACY_TITLE' AND source_key='100078'`, int64(first.PlayerID))
	if _, err := service.ReadCatalogDisplayOriginsTx(ctx, database, display.CatalogOriginRequest{PlayerID: first.PlayerID, Family: "title", CatalogID: 100078, Revision: installed(t, database), ObservedAt: season.ClosesAt}); err == nil {
		t.Fatal("unproved mail origin qualified")
	}
}
