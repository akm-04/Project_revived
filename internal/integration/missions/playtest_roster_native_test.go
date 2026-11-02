//go:build postgres

package missions_test

import (
	"context"
	"sync"
	"testing"
	"time"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/application/missioninputs"
	"gxb.local/backend/v2/internal/content/builtin"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func seedMissionHeroes(t *testing.T, p *pg.Pool, player identity.PlayerID, revision string) {
	t.Helper()
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	templates := make([]int64, 0, 123)
	for _, hero := range catalog.HeroCore.Templates {
		if hero.HeroKind == "NORMAL" && len(templates) < 123 {
			templates = append(templates, hero.TableID)
		}
	}
	if len(templates) != 123 {
		t.Fatalf("normal hero templates %d", len(templates))
	}
	at := time.Now().UTC().Add(-time.Hour)
	tr, err := p.Begin(context.Background(), tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	defer tr.Rollback(context.Background())
	if _, err = tr.Exec(context.Background(), `INSERT INTO player_hero_roots(player_id,next_partner_id,sort_type,state_version,created_at,updated_at)VALUES($1,124,0,1,$2,$2) ON CONFLICT(player_id) DO UPDATE SET next_partner_id=GREATEST(player_hero_roots.next_partner_id,124)`, int64(player), at); err != nil {
		t.Fatal(err)
	}
	for index, table := range templates {
		hero := character.Hero{RawSkills: character.NewHeroRawSkillSeed(), PlayerID: player, PartnerID: int64(index + 1), TableID: table, OriginTableID: table,
			Star: 5, Level: 1, Color: 1, CreationContentRevision: revision, IllusionSkinID: character.DefaultIllusionSkinID, StateVersion: 1, CreatedAt: at, UpdatedAt: at}
		if err = (characterstore.Store{}).InsertHeroTx(context.Background(), tr, hero); err != nil {
			t.Fatal(err)
		}
	}
	if err = tr.Commit(context.Background()); err != nil {
		t.Fatal(err)
	}
}

type countingHeroes struct {
	characterstore.Store
	lists int
}

func (c *countingHeroes) ListHeroesTx(ctx context.Context, q tx.Queryer, player identity.PlayerID) ([]character.Hero, error) {
	c.lists++
	return c.Store.ListHeroesTx(ctx, q, player)
}

func materializeOnce(t *testing.T, p *pg.Pool, materializer *i5.MissionMaterializer, scope i5.MissionScope) (time.Duration, error) {
	tr, err := p.Begin(context.Background(), tx.Options{Isolation: tx.ReadCommitted})
	if err != nil {
		return 0, err
	}
	defer tr.Rollback(context.Background())
	if _, err = tr.Exec(context.Background(), `SET LOCAL lock_timeout='2s'`); err != nil {
		return 0, err
	}
	started := time.Now()
	_, err = materializer.MaterializeTx(context.Background(), tr, scope)
	elapsed := time.Since(started)
	if err != nil {
		return elapsed, err
	}
	return elapsed, tr.Commit(context.Background())
}

func TestPlaytestMissionMaterializeReads123HeroRosterOnce(t *testing.T) {
	p := missionPool(t)
	now, err := (pg.AuthoritativeTime{Queryer: p}).Now(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	at := time.Date(now.Year(), now.Month(), now.Day()+1, 20, 59, 50, 0, time.UTC)
	a := runtimeActor(t, p, at)
	catalog, err := builtin.Load()
	if err != nil {
		t.Fatal(err)
	}
	seedMissionHeroes(t, p, a.PlayerID, catalog.RevisionID())
	service := runtimeService(p, &missionClock{at: at})
	reader := service.Missions.Observations.(missioninputs.Reader)
	heroLists := &countingHeroes{Store: characterstore.Store{Queryer: p}}
	reader.Heroes = heroLists
	service.Missions.Observations = reader
	scope := i5.MissionScope{PlayerID: a.PlayerID, ContentRevision: catalog.RevisionID(), DecisionAt: at}

	first, err := materializeOnce(t, p, service.Missions, scope)
	t.Logf("single materialize with 123 heroes: %s roster_lists=%d err=%v", first, heroLists.lists, err)
	if err != nil {
		t.Fatal("single materialize", err)
	}
	if heroLists.lists != 1 {
		t.Fatalf("roster reads per materialize pass %d", heroLists.lists)
	}

	heroLists.lists = 0
	start := make(chan struct{})
	elapsed := [2]time.Duration{}
	errors := [2]error{}
	var wait sync.WaitGroup
	for index := range 2 {
		wait.Add(1)
		go func(index int) {
			defer wait.Done()
			<-start
			elapsed[index], errors[index] = materializeOnce(t, p, service.Missions, scope)
		}(index)
	}
	close(start)
	wait.Wait()
	t.Logf("concurrent materialize with 123 heroes: %s / %s roster_lists=%d errors=%v/%v", elapsed[0], elapsed[1], heroLists.lists, errors[0], errors[1])
	if heroLists.lists != 2 {
		t.Fatalf("roster reads for two passes %d", heroLists.lists)
	}
	for index, err := range errors {
		if err != nil {
			t.Fatalf("concurrent materialize %d: %v", index, err)
		}
	}
}
