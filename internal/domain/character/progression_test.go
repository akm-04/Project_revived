package character

import (
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func testProgressHero(now time.Time) Hero {
	return Hero{PlayerID: identity.PlayerID(7), PartnerID: 11, TableID: 1001, OriginTableID: 1001, Star: 3, Level: 1, Exp: 0, Color: 1, CreationContentRevision: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", StateVersion: 1, CreatedAt: now, UpdatedAt: now}
}

func TestAddSourceEXPMatchesRecoveredCumulativeLevelLoop(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	h := testProgressHero(now)
	thresholds := []HeroExpThreshold{{1, 25}, {2, 55}, {3, 95}, {4, 155}}
	got, err := h.AddSourceEXP(60, 4, thresholds, now.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	if got.Exp != 60 || got.Level != 3 || got.StateVersion != 2 {
		t.Fatalf("got exp=%d level=%d version=%d", got.Exp, got.Level, got.StateVersion)
	}
}

func TestAddSourceEXPClampsAtPlayerQualifiedHeroMaxLevel(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	h := testProgressHero(now)
	thresholds := []HeroExpThreshold{{1, 25}, {2, 55}, {3, 95}}
	got, err := h.AddSourceEXP(100000, 3, thresholds, now.Add(time.Second))
	if err != nil {
		t.Fatal(err)
	}
	if got.Exp != 95 || got.Level != 3 {
		t.Fatalf("got exp=%d level=%d", got.Exp, got.Level)
	}
}

func TestEvolveOneStarNeverCrossesEffectiveClientCeiling(t *testing.T) {
	now := time.Unix(100, 0).UTC()
	h := testProgressHero(now)
	h.Star = 7
	got, err := h.EvolveOneStar(now.Add(time.Second))
	if err != nil || got.Star != 8 {
		t.Fatalf("got=%+v err=%v", got, err)
	}
	if _, err := got.EvolveOneStar(now.Add(2 * time.Second)); err == nil {
		t.Fatal("star 8 must not evolve")
	}
}
