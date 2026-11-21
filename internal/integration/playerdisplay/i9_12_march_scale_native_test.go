//go:build postgres

package playerdisplay_test

import (
	"context"
	"math"
	"sort"
	"testing"

	pg "gxb.local/backend/v2/internal/adapters/postgres"
	"gxb.local/backend/v2/internal/adapters/postgres/characterstore"
	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/publicstats"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	marchdomain "gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// marchSetCoherentHero gives a born Hero its final star, level and colour in one
// production CAS so every facet observes the same triple.
func marchSetCoherentHero(t *testing.T, p *pg.Pool, a identity.ActorContext, partner, level, star, color int64) {
	t.Helper()
	h, err := (characterstore.Store{}).ReadHeroByPartnerIDTx(ctx, p, a.PlayerID, partner)
	if err != nil {
		t.Fatal(err)
	}
	h.Level, h.Star, h.Color = level, star, color
	h.StateVersion++
	tr, err := p.Begin(ctx, tx.Options{})
	if err != nil {
		t.Fatal(err)
	}
	if err = (characterstore.Store{}).SaveHeroStateTx(ctx, tr, h, h.StateVersion-1); err != nil {
		tr.Rollback(ctx)
		t.Fatal(err)
	}
	if err = tr.Commit(ctx); err != nil {
		t.Fatal(err)
	}
}

// TestI9_12MarchScaleClampsImpossibleGrade loads a stage whose opponent is one
// real player with a level-100 red+1 defence on an isolated server. The copied
// enemy must be scaled to a level the grade rules allow, its force recomputed
// from that triple, and the whole team kept within the stage-1 limit.
func TestI9_12MarchScaleClampsImpossibleGrade(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	server := marchNewServer(t, p)
	owner := marchActorOnServer(t, p, server)
	viewer := marchActorOnServer(t, p, server)
	bornHero(t, p, owner, rev, 10001001, 1)
	compositeLevel(t, p, owner, rev, 100)
	marchSetCoherentHero(t, p, owner, 1, 100, 3, 16)
	ladder := topFloorService(t, p)
	if _, err := ladder.Load(ctx, owner, op()); err != nil {
		t.Fatal("owner ladder load", err)
	}
	if err := ladder.SaveDefense(ctx, owner, []int64{1}, 0, op()); err != nil {
		t.Fatal("owner defense", err)
	}
	bornHero(t, p, viewer, rev, 10001001, 1)
	compositeLevel(t, p, viewer, rev, 60)
	marchSetCoherentHero(t, p, viewer, 1, 60, 3, 7)

	mode := marchMode(t, p)
	if _, err := mode.Load(ctx, viewer, op()); err != nil {
		t.Fatal("viewer march load", err)
	}
	enemy := marchRecord(t, p, viewer).Enemies[0]
	if enemy.Robot != 0 || enemy.Player != int64(owner.PlayerID) {
		t.Fatalf("stage 1 opponent=%+v, want the real owner", enemy)
	}
	levels, err := (contentstore.Store{Queryer: p}).HeroColorLevelsTx(ctx, p, rev)
	if err != nil {
		t.Fatal("colour levels", err)
	}
	// combatOwner/player births the 10001001 table used by this fixture.
	heroLevels, ok := levels[10001001]
	if !ok {
		t.Fatal("no colour levels for hero 10001001")
	}

	var limit float64
	if err = coherentRead(t, p, rev, func(c context.Context, _ tx.Scope, scope ca.CoherentReadScope) error {
		catalog, e := (contentstore.Store{Queryer: p}).MarchCatalogTx(c, p, rev)
		if e != nil {
			return e
		}
		heroes, e := (characterstore.Store{Queryer: p}).ListHeroesTx(c, p, viewer.PlayerID)
		if e != nil {
			return e
		}
		stats := rawBirthStats(p)
		forces := make([]int64, 0, len(heroes))
		for _, hero := range heroes {
			result, e := stats.HeroTx(c, scope, hero.Ref(), publicstats.View{Kind: publicstats.Self, Viewer: viewer.PlayerID})
			if e != nil {
				return e
			}
			forces = append(forces, int64(math.Round(result.Stats.Force)))
		}
		sort.Slice(forces, func(i, j int) bool { return forces[i] > forces[j] })
		power := int64(0)
		for i, force := range forces {
			if i >= 5 {
				break
			}
			power += force
		}
		limit = float64(power) * catalog.Factors("expedition_rival_param")[0] * (1 + float64(catalog.Policy.RivalForceTolerance)/10000)
		return nil
	}); err != nil {
		t.Fatal("stage-1 limit", err)
	}
	if float64(enemy.Force) > limit {
		t.Fatalf("stage 1 force=%d exceeds limit %.0f", enemy.Force, limit)
	}
	if len(enemy.Heroes) != 1 {
		t.Fatalf("stage 1 enemy heroes=%d want the one defended girl", len(enemy.Heroes))
	}
	if err = coherentRead(t, p, rev, func(c context.Context, _ tx.Scope, scope ca.CoherentReadScope) error {
		stats := rawBirthStats(p)
		for _, row := range enemy.Heroes {
			level, color, star := marchNumber(row["lev"]), marchNumber(row["color"]), marchNumber(row["star"])
			if level == 100 {
				t.Fatalf("level was not fitted: %+v", row)
			}
			if color == 16 {
				t.Fatalf("red+1 survived the level fit: %+v", row)
			}
			legal, e := marchdomain.CoherentColor(heroLevels, level, color, 1)
			if e != nil || legal != color {
				t.Fatalf("level=%d colour=%d is not a legal grade (highest %d, err %v)", level, color, legal, e)
			}
			result, e := stats.ScaledHeroTx(c, scope, character.HeroRef{PlayerID: owner.PlayerID, PartnerID: 1},
				publicstats.View{Kind: publicstats.Foreign, Viewer: viewer.PlayerID}, level, star, color)
			if e != nil {
				return e
			}
			want := int64(math.Round(result.Stats.Force))
			if got := marchNumber(row["force"]); got != want {
				t.Fatalf("row force=%d, canonical force at (%d,%d,%d)=%d", got, level, star, color, want)
			}
		}
		return nil
	}); err != nil {
		t.Fatal("row force", err)
	}
}
