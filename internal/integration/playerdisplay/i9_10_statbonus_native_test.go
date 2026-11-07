//go:build postgres

package playerdisplay_test

import (
	"encoding/json"
	"fmt"
	"math"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/adapters/combatresolver"
	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/bookstore"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/combatstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	"gxb.local/backend/v2/internal/adapters/postgres/coursestore"
	"gxb.local/backend/v2/internal/adapters/postgres/dormstore"
	"gxb.local/backend/v2/internal/adapters/postgres/inscriptionstore"
	"gxb.local/backend/v2/internal/adapters/postgres/librarystore"
	"gxb.local/backend/v2/internal/adapters/postgres/topfloorstore"
	topfloor "gxb.local/backend/v2/internal/application/topfloor"
	"gxb.local/backend/v2/internal/content/combatcorpus"
	"gxb.local/backend/v2/internal/domain/character"
	combatdomain "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/course"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	librarydomain "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type r10BattleStatTotals struct {
	PublicStats [49]float64
	Resolver    map[int]float64
}

type r10StatMutation func(*testing.T, *pg.Pool, identity.ActorContext, string, character.HeroRef)

func r10TopFloorStatTotals(t *testing.T, pool *pg.Pool, service topfloor.Service, server identity.LogicalServerID, mutate r10StatMutation) r10BattleStatTotals {
	t.Helper()
	actor, revision, heroReference := topFloorPlayer(t, pool, server)
	if mutate != nil {
		mutate(t, pool, actor, revision, heroReference)
	}

	view, err := service.Load(ctx, actor, op())
	if err != nil || len(view.Enemies) == 0 {
		t.Fatalf("Top Floor offers: enemies=%d error=%v", len(view.Enemies), err)
	}
	if err = service.SaveDefense(ctx, actor, []int64{heroReference.PartnerID}, 0, op()); err != nil {
		t.Fatal("Top Floor defense", err)
	}
	_, err = service.Start(ctx, actor, topfloor.StartCommand{Formation: []int64{heroReference.PartnerID}, Enemy: view.Enemies[0].Occupant.TableID()}, op())
	if err != nil {
		t.Fatal("Top Floor START", err)
	}

	fight, found, err := (topfloorstore.Store{}).LatestFightTx(ctx, pool, actor.PlayerID)
	if err != nil || !found {
		t.Fatalf("Top Floor fight found=%v error=%v", found, err)
	}
	attempt, found, err := (combatstore.Store{}).ReadAttemptTx(ctx, pool, fight.AttemptID)
	if err != nil || !found {
		t.Fatalf("combat attempt found=%v error=%v", found, err)
	}
	rawSnapshot, err := (combatstore.Store{}).ReadSnapshotTx(ctx, pool, attempt.SnapshotHash)
	if err != nil {
		t.Fatal("read Top Floor snapshot", err)
	}
	snapshot, err := combatdomain.DecodeSnapshot(rawSnapshot, attempt.SnapshotHash)
	if err != nil {
		t.Fatal("decode Top Floor snapshot", err)
	}
	if len(snapshot.Battle.TeamA) != 1 || snapshot.Battle.TeamA[0].Identity != heroReference.PartnerID {
		t.Fatalf("unexpected Top Floor formation %+v", snapshot.Battle.TeamA)
	}
	var publicFacet struct {
		Model string      `json:"model"`
		Total [49]float64 `json:"total"`
	}
	if err = json.Unmarshal(snapshot.Battle.TeamA[0].BattleTotals, &publicFacet); err != nil {
		t.Fatal("decode frozen publicstats total", err)
	}
	corpus, err := combatcorpus.Load()
	if err != nil {
		t.Fatal(err)
	}
	resolverTotals, err := combatresolver.EvaluateActors(corpus, snapshot)
	if err != nil {
		t.Fatal("resolver getBattleAttr", err)
	}
	if len(resolverTotals) == 0 {
		t.Fatal("resolver returned no actors")
	}
	for attributeID := 1; attributeID <= 49; attributeID++ {
		publicValue := publicFacet.Total[attributeID-1]
		resolverValue := resolverTotals[0][attributeID]
		if math.Abs(publicValue-resolverValue) > 1e-6*math.Max(1, math.Abs(publicValue)) {
			t.Errorf("Top Floor %s attribute %d: publicstats=%v resolver=%v", publicFacet.Model, attributeID, publicValue, resolverValue)
		}
	}
	return r10BattleStatTotals{PublicStats: publicFacet.Total, Resolver: resolverTotals[0]}
}

func r10SetCourse(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := coursestore.Store{}
	facts, err := store.LockHeroTx(ctx, transaction, actor.PlayerID, heroReference.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	previousVersion := facts.Version
	facts.Version++
	facts.Facts.Courses = []course.Record{{ID: 100101, Progress: 100, Quality: 1, Skill: 1}}
	facts.UpdatedAt = r10DatabaseTime(t, transaction)
	if err = store.SaveHeroTx(ctx, transaction, facts, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func r10SetDormGrowth(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	catalog, err := (contentstore.Store{Queryer: pool}).DormCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	roomRule, found := catalog.Rooms[1000002]
	if !found || len(roomRule.Growth) == 0 {
		t.Fatal("Hero has no dorm growth source")
	}
	hasGrowth := false
	for _, tier := range roomRule.Growth {
		for _, attribute := range tier.Attributes {
			hasGrowth = hasGrowth || attribute > 0
		}
	}
	if !hasGrowth {
		t.Fatal("dorm source has no positive growth stage")
	}

	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := dormstore.Store{}
	root, err := store.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	rooms, err := store.ListRoomsTx(ctx, transaction, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	updatedAt := r10DatabaseTime(t, transaction)
	updatedRoot, room, err := catalog.NewRoom(root, rooms, roomRule.TableID, 1, 1, revision, updatedAt)
	if err != nil {
		t.Fatal(err)
	}
	facts, err := store.ReadHeroTx(ctx, transaction, heroReference)
	if err != nil {
		t.Fatal(err)
	}
	previousVersion := facts.StateVersion
	facts.StateVersion++
	facts.HouseID = room.ID
	facts.UpdatedAt = updatedAt
	if err = store.InsertRoomTx(ctx, transaction, room); err != nil {
		t.Fatal(err)
	}
	if err = store.SaveRootTx(ctx, transaction, updatedRoot, root.StateVersion); err != nil {
		t.Fatal(err)
	}
	if err = store.SaveHeroTx(ctx, transaction, facts, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func r10SetBookshelf(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := bookstore.Store{}
	facts, err := store.LockRootTx(ctx, transaction, actor.PlayerID)
	if err != nil {
		t.Fatal(err)
	}
	previousVersion := facts.Version
	facts.Version++
	facts.Facts.Skills[10010001] = 1
	facts.UpdatedAt = r10DatabaseTime(t, transaction)
	if err = store.SaveRootTx(ctx, transaction, facts, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func r10SetPractice(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := characterstore.Store{}
	hero, err := store.LockHeroByPartnerIDTx(ctx, transaction, actor.PlayerID, heroReference.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	previousVersion := hero.StateVersion
	hero.StateVersion++
	hero.Practice = character.PracticeAttrs{20, 30, 40}
	hero.UpdatedAt = r10DatabaseTime(t, transaction)
	if err = store.SaveHeroPracticeTx(ctx, transaction, hero, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func r10SetInscription(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	catalog, err := (contentstore.Store{Queryer: pool}).InscriptionCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	item, found := catalog.Item(160100102)
	if !found || item.Position < 1 || item.Position > 3 || len(item.Battle) == 0 {
		t.Fatal("Hero has no battle inscription source")
	}

	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := inscriptionstore.Store{}
	if _, err = store.LockRootTx(ctx, transaction, actor.PlayerID); err != nil {
		t.Fatal(err)
	}
	facts, err := store.LockHeroTx(ctx, transaction, actor.PlayerID, heroReference.PartnerID)
	if err != nil {
		t.Fatal(err)
	}
	previousVersion := facts.Version
	facts.Version++
	facts.Facts.Slots[item.Position-1] = item.ID
	if err = facts.Facts.Validate(catalog); err != nil {
		t.Fatal(err)
	}
	facts.UpdatedAt = r10DatabaseTime(t, transaction)
	if err = store.SaveHeroTx(ctx, transaction, facts, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func r10SetAwakening(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	if _, err = (characterstore.Store{}).LockHeroByPartnerIDTx(ctx, transaction, actor.PlayerID, heroReference.PartnerID); err != nil {
		t.Fatal(err)
	}
	store := characterstore.RawAwakeningStore{}
	awakening, err := store.ReadRawAwakeningBirthTx(ctx, transaction, heroReference)
	if err != nil {
		t.Fatal(err)
	}
	previousVersion := awakening.Version
	awakening.Version++
	awakening.RawStage = 3
	awakening.ProducerReference = "I9_AWAKENING_MISSIONS_V1/" + uuid().String()
	awakening.UpdatedAt = r10DatabaseTime(t, transaction)
	if err = store.SaveRawAwakeningTx(ctx, transaction, awakening, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func r10SetFeed(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	r10MutateLibraryHero(t, pool, actor, heroReference, func(facts *librarydomain.HeroFacts) {
		facts.Applied = librarydomain.FeedAttrs{20, 30, 40}
	})
}

func r10SetCollectionStage(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	catalog, err := (contentstore.Store{Queryer: pool}).LibraryCatalogTx(ctx, pool, revision)
	if err != nil {
		t.Fatal(err)
	}
	template, found := catalog.Templates[genuineHeroTable]
	if !found {
		t.Fatal("Hero has no collection source")
	}
	normal, found := catalog.NormalCollections[template.CollectionSourceID]
	if !found || len(normal.QualityHundredths) == 0 || normal.QualityHundredths[0] <= 0 {
		t.Fatal("Hero has no positive gallery quality stage")
	}
	r10MutateLibraryHero(t, pool, actor, heroReference, func(facts *librarydomain.HeroFacts) {
		facts.QualityStage = 1
	})
}

func r10MutateLibraryHero(t *testing.T, pool *pg.Pool, actor identity.ActorContext, heroReference character.HeroRef, mutate func(*librarydomain.HeroFacts)) {
	t.Helper()
	transaction, err := pool.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer transaction.Rollback(ctx)
	store := librarystore.Store{}
	if _, err = store.LockRootTx(ctx, transaction, actor.PlayerID); err != nil {
		t.Fatal(err)
	}
	facts, err := store.LockHeroTx(ctx, transaction, heroReference)
	if err != nil {
		t.Fatal(err)
	}
	previousVersion := facts.StateVersion
	facts.StateVersion++
	facts.UpdatedAt = r10DatabaseTime(t, transaction)
	mutate(&facts)
	if err = store.SaveHeroTx(ctx, transaction, facts, previousVersion); err != nil {
		t.Fatal(err)
	}
	if err = transaction.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

func r10DatabaseTime(t *testing.T, transaction tx.Tx) time.Time {
	t.Helper()
	var observedAt time.Time
	if err := transaction.QueryRow(ctx, "SELECT clock_timestamp()").Scan(&observedAt); err != nil {
		t.Fatal(err)
	}
	return observedAt.UTC()
}

func r10AssertDelta(t *testing.T, source string, baseline, changed r10BattleStatTotals, wantNonzero bool) {
	t.Helper()
	changedAttributes := []string{}
	for attributeID := 1; attributeID <= 49; attributeID++ {
		publicDelta := changed.PublicStats[attributeID-1] - baseline.PublicStats[attributeID-1]
		resolverDelta := changed.Resolver[attributeID] - baseline.Resolver[attributeID]
		if math.Abs(publicDelta-resolverDelta) > 1e-6*math.Max(1, math.Abs(publicDelta)) {
			t.Errorf("%s attribute %d delta: publicstats=%v resolver=%v", source, attributeID, publicDelta, resolverDelta)
		}
		if math.Abs(publicDelta) > 1e-8 {
			changedAttributes = append(changedAttributes, fmt.Sprintf("%d=%g", attributeID, publicDelta))
		}
	}
	if wantNonzero && len(changedAttributes) == 0 {
		t.Errorf("%s changed no battle attributes", source)
	}
	if !wantNonzero && len(changedAttributes) != 0 {
		t.Errorf("%s unexpectedly changed battle attributes: %v", source, changedAttributes)
	}
	t.Logf("%s publicstats/resolver deltas: %v", source, changedAttributes)
}

func TestI9_10R10TopFloorPublicStatsResolverSourceParityNative(t *testing.T) {
	pool := pool(t)
	defer pool.Close()
	service := topFloorService(t, pool)
	server := rankingServer(t, pool)
	installed(t, pool)
	activeRevision, err := (contentstore.Store{Queryer: pool}).ActiveRevision(ctx, pool)
	if err != nil {
		t.Fatal(err)
	}
	catalog, err := (contentstore.Store{Queryer: pool}).TopFloorCatalogTx(ctx, pool, activeRevision)
	if err != nil {
		t.Fatal(err)
	}
	if catalog.Frozen(time.Now()) {
		t.Skip("21:00-21:30 GMT+8 settlement freeze admits no START")
	}

	baseline := r10TopFloorStatTotals(t, pool, service, server, nil)
	sources := []struct {
		name        string
		mutate      r10StatMutation
		wantNonzero bool
	}{
		{name: "course/elective", mutate: r10SetCourse, wantNonzero: true},
		{name: "dorm growth", mutate: r10SetDormGrowth, wantNonzero: true},
		{name: "bookshelf", mutate: r10SetBookshelf, wantNonzero: true},
		{name: "inscription", mutate: r10SetInscription, wantNonzero: true},
		{name: "awakening", mutate: r10SetAwakening, wantNonzero: false},
		{name: "practice", mutate: r10SetPractice, wantNonzero: true},
		{name: "feed", mutate: r10SetFeed, wantNonzero: true},
		{name: "gallery quality stage", mutate: r10SetCollectionStage, wantNonzero: true},
		{name: "equipment", mutate: r10EquipHero, wantNonzero: true},
		{name: "skin", mutate: r10WearSkin, wantNonzero: false},
	}
	for _, source := range sources {
		t.Run(source.name, func(t *testing.T) {
			changed := r10TopFloorStatTotals(t, pool, service, server, source.mutate)
			r10AssertDelta(t, source.name, baseline, changed, source.wantNonzero)
		})
	}
}

func r10EquipHero(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	grantGenuine(t, pool, actor, revision, "r10-equipment", genuineResources(t, pool, revision, []int64{genuineHeroTable}))
	must(genuineHeroService(pool).OneKeyEquip(ctx, actor, heroReference.PartnerID, op()))(t, "equip Hero")
}

func r10WearSkin(t *testing.T, pool *pg.Pool, actor identity.ActorContext, revision string, heroReference character.HeroRef) {
	t.Helper()
	grantGenuine(t, pool, actor, revision, "r10-skin", []grant.Line{{Kind: grant.StackItem, ItemID: genuineSkinItem, Amount: 1}})
	heroes := genuineHeroService(pool)
	must(heroes.SkinOn(ctx, actor, heroReference.PartnerID, genuineSkinItem, op()))(t, "unlock Hero skin")
	must(heroes.SkinOn(ctx, actor, heroReference.PartnerID, genuineSkinItem, op()))(t, "wear Hero skin")
}
