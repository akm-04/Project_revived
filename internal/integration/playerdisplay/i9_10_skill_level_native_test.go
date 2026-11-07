//go:build postgres

package playerdisplay_test

import (
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/i4store"
	"gxb.local/backend/v2/internal/adapters/postgres/i5store"
	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	appbook "gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/application/characterasset"
	apphero "gxb.local/backend/v2/internal/application/characterhero"
	gen "gxb.local/backend/v2/internal/application/generation"
	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"gxb.local/backend/v2/internal/projection/hero"
)

func heroSkillLevelService(database *pg.Pool) apphero.HeroSkillLevelService {
	runner := tx.Runner{DB: database}
	characters := characterstore.Store{Queryer: database}
	content := contentstore.Store{Queryer: database}
	inventory := i5store.Store{Queryer: database}
	return apphero.HeroSkillLevelService{
		Timed: gen.TimedRunner{Binder: gen.Binder{Time: pg.AuthoritativeTime{Queryer: database}}, Runner: runner},
		Reads: runner, Store: characters,
		Books:   appbook.Service{Heroes: characterstore.LibraryHeroPort{Store: characters}, Owner: bookstore.Store{}, Content: content},
		Content: content, Players: i4store.PlayerRootLocker{}, Fence: inventory, Receipts: kernelstore.Store{},
		Resources: appi5.Service{Runner: runner, Store: inventory, Content: content, Privileges: privilegeProvider(database)}, DiscountBasisPoints: 10000,
	}
}

func heroSkillLevelFixture(t *testing.T, database *pg.Pool, revision string, mana, skillPoints int64, anchor time.Time) identity.ActorContext {
	t.Helper()
	actor := privilegeActor(t, database, revision)
	skillHero(t, database, actor, revision, 11001144, 1)
	transaction, err := database.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = (bookstore.Store{}).EnsureRootTx(ctx, transaction, actor.PlayerID, revision, time.Now().UTC().Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	exec(t, database, `INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)VALUES($1,'mana',$2,1,clock_timestamp()-interval '1 hour')ON CONFLICT(player_id,resource_key)DO UPDATE SET amount=excluded.amount,state_version=player_currency_balances.state_version+1,updated_at=excluded.updated_at`, int64(actor.PlayerID), mana)
	exec(t, database, `UPDATE player_temporal_resources SET stored_amount=$2,regen_anchor_at=$3,state_version=state_version+1,updated_at=$3 WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID), skillPoints, anchor)
	return actor
}

func TestI9I10NativeHeroSkillLevelMIDsRegenerateReplayRefuseAndRefresh(t *testing.T) {
	database := pool(t)
	revision := installed(t, database)
	content := contentstore.Store{Queryer: database}
	resource, err := content.ResolveResourceTx(ctx, database, revision, grant.Line{Kind: grant.Temporal, ResourceKey: "skill_point", Amount: 1})
	if err != nil || resource.Descriptor == nil || resource.Descriptor.RegenEvery <= 0 {
		t.Fatal("skill-point regeneration descriptor", resource, err)
	}

	singleOperation := op()
	regenerationAnchor := singleOperation.StartedAt.Add(-resource.Descriptor.RegenEvery * 20)
	actor := heroSkillLevelFixture(t, database, revision, 1000000, 0, regenerationAnchor)
	service := heroSkillLevelService(database)
	single, err := service.SetSkillLevel(ctx, actor, 1, 1, singleOperation)
	if err != nil || !single.Success || single.SkillLevels[0] != 2 || single.SkillPoint != 9 || single.StateVersion != 2 {
		t.Fatal("MID 53 mutation and regeneration", single, err)
	}
	replay, err := service.SetSkillLevel(ctx, actor, 1, 1, singleOperation)
	if err != nil || !replay.Success || !replay.Changed || replay.SkillLevels != single.SkillLevels || replay.SkillPoint != single.SkillPoint || replay.StateVersion != single.StateVersion || !replay.DecisionAt.Equal(single.DecisionAt) {
		t.Fatal("MID 53 replay", replay, err)
	}

	bulk, err := service.SetAllSkillLevels(ctx, actor, 1, []apphero.HeroSkillLevelChange{{Slot: 2, Count: 1}, {Slot: 1, Count: 1}}, op())
	if err != nil || !bulk.Success || bulk.SkillLevels[0] != 3 || bulk.SkillLevels[1] != 2 || bulk.SkillPoint != 7 || bulk.StateVersion != 3 {
		t.Fatal("MID 39 mutation", bulk, err)
	}
	storedHero := skillRead(t, database, actor, 1)
	if storedHero.RawSkills.Levels != bulk.SkillLevels || storedHero.StateVersion != bulk.StateVersion {
		t.Fatal("canonical hero reload", storedHero)
	}
	storedMana, storedPoints := int64(0), int64(0)
	if err = database.QueryRow(ctx, `SELECT amount FROM player_currency_balances WHERE player_id=$1 AND resource_key='mana'`, int64(actor.PlayerID)).Scan(&storedMana); err != nil {
		t.Fatal(err)
	}
	if err = database.QueryRow(ctx, `SELECT stored_amount FROM player_temporal_resources WHERE player_id=$1 AND resource_key='skill_point'`, int64(actor.PlayerID)).Scan(&storedPoints); err != nil {
		t.Fatal(err)
	}
	if storedMana != 999300 || storedPoints != 7 {
		t.Fatal("atomic resource debits", storedMana, storedPoints)
	}
	stockHero := storedHero
	stockHero.Kind, err = content.HeroKind(ctx, revision, stockHero.TableID)
	if err != nil {
		t.Fatal(err)
	}
	stockProjection, err := hero.StockHero(stockHero)
	if err != nil || stockProjection["skills"].([]any)[0] != int64(3) {
		t.Fatal("stock roster refresh", stockProjection, err)
	}
	if err = statRead(t, database, revision, func(scope characterasset.CoherentReadScope) error {
		observation, readErr := (apphero.RawSkillObservationReader{Store: characterstore.Store{Queryer: database}, Content: content}).HeroRawSkillsTx(ctx, scope, storedHero.Ref())
		if readErr != nil {
			return readErr
		}
		if observation.StateVersion != bulk.StateVersion || observation.Facts.Levels != bulk.SkillLevels || observation.ContentRevision != revision {
			t.Fatal("public-stat skill input refresh", observation)
		}
		return nil
	}); err != nil {
		t.Fatal(err)
	}

	capActor := heroSkillLevelFixture(t, database, revision, 1000000, 10, time.Now().UTC())
	exec(t, database, `UPDATE player_heroes SET raw_skill_1=150,state_version=2,updated_at=clock_timestamp()-interval '1 second' WHERE player_id=$1 AND partner_id=1`, int64(capActor.PlayerID))
	capped, err := service.SetSkillLevel(ctx, capActor, 1, 1, op())
	if err != nil || capped.Success || capped.SkillLevels[0] != 150 || capped.SkillPoint != 10 || skillRead(t, database, capActor, 1).StateVersion != 2 {
		t.Fatal("skill cap refusal", capped, err)
	}

	resourceOperation := op()
	resourceActor := heroSkillLevelFixture(t, database, revision, 1000000, 0, resourceOperation.StartedAt)
	refused, err := service.SetAllSkillLevels(ctx, resourceActor, 1, []apphero.HeroSkillLevelChange{{Slot: 1, Count: 1}}, resourceOperation)
	if err != nil || refused.Success || refused.SkillPoint != 0 || skillRead(t, database, resourceActor, 1).StateVersion != 1 {
		t.Fatal("skill-point refusal", refused, err)
	}
}
