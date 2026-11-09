//go:build postgres

package playerdisplay_test

import (
	"strconv"
	"testing"

	"gxb.local/backend/v2/internal/adapters/postgres/contentstore"
	app "gxb.local/backend/v2/internal/application/march"
)

type marchFixedRandom uint64

func (r marchFixedRandom) Uniform(n uint64) uint64 { return uint64(r) % n }

// TestI9_10MarchNativeVanguardSweepFollowsSourceBand pins the installed
// march_advance table: the rating is the count of reached rate_fight
// thresholds and the cleared prefix is a member of that band's clean_numb
// group. Forged force never rates; the qualified canonical force does.
func TestI9_10MarchNativeVanguardSweepFollowsSourceBand(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	catalog, err := (contentstore.Store{Queryer: p}).MarchCatalogTx(ctx, p, rev)
	if err != nil {
		t.Fatal("catalog", err)
	}
	for _, level := range []int64{65, 90, 100} {
		advance := catalog.Advances[level-65]
		cases := []struct {
			name  string
			force int64
			group []int64
		}{
			{"below first rate", 0, advance.Counts[0]},
			{"first rate", advance.Rates[0], advance.Counts[1]},
			{"second rate", advance.Rates[1], advance.Counts[2]},
			{"third rate", advance.Rates[2], advance.Counts[3]},
			{"fourth rate", advance.Rates[3], advance.Counts[4]},
			{"just below fourth rate", advance.Rates[3] - 1, advance.Counts[3]},
		}
		for _, c := range cases {
			for seed := range c.group {
				got, err := catalog.SweepCount(level, c.force, marchFixedRandom(seed))
				if err != nil {
					t.Fatal(level, c.name, err)
				}
				if want := c.group[uint64(seed)%uint64(len(c.group))]; got != want {
					t.Fatalf("level %d %s: cleared %d, want %d", level, c.name, got, want)
				}
			}
		}
	}
	top := catalog.Advances[len(catalog.Advances)-1].Counts
	if top[len(top)-1][2] != 14 {
		t.Fatal("source top band no longer clears all but the last stage")
	}
}

// TestI9_10MarchNativeVanguardSweepSettlesSourcePrefix runs the production
// Vanguard path: the response length equals the cleared prefix, every cleared
// stage keeps its frozen rewards, the five sent girls die and the rest survive.
func TestI9_10MarchNativeVanguardSweepSettlesSourcePrefix(t *testing.T) {
	p := pool(t)
	rev := installed(t, p)
	a := bornActor(t, p)
	s := marchMode(t, p)
	for i := int64(1); i <= 6; i++ {
		bornHero(t, p, a, rev, 10001000+i, i)
		marchSetHeroLevel(t, p, a, i, 100)
	}
	compositeLevel(t, p, a, rev, 100)
	exec(t, p, `UPDATE player_directory_profiles SET lev=100 WHERE player_id=$1`, int64(a.PlayerID))
	if _, err := s.Load(ctx, a, op()); err != nil {
		t.Fatal("load", err)
	}
	team := []int64{1, 2, 3, 4, 5}
	body, err := s.Advance(ctx, a, app.Fight{Formation: team, Force: 9999999999999}, op())
	if err != nil {
		t.Fatal("advance", err)
	}
	r := marchRecord(t, p, a)
	cleared := r.Passed
	t.Logf("canonical level-100 team cleared %d of 15", cleared)
	if cleared < 1 || cleared > 14 {
		t.Fatalf("cleared %d outside the source prefix", cleared)
	}
	drinks := body["power_drink"].([]int64)
	awards := body["award"].([]any)
	if int64(len(drinks)) != cleared || int64(len(awards)) != cleared {
		t.Fatalf("reply groups drinks=%d awards=%d cleared=%d", len(drinks), len(awards), cleared)
	}
	if info := body["map_info"].(map[string]any); info["passed_stage"] != cleared {
		t.Fatalf("map_info passed_stage %v, cleared %d", info["passed_stage"], cleared)
	}
	for stage := int64(1); stage <= cleared; stage++ {
		if len(r.Rewards[strconv.FormatInt(stage, 10)]) == 0 {
			t.Fatalf("stage %d reward not frozen", stage)
		}
	}
	for _, id := range team {
		if r.Alive(id) {
			t.Fatalf("sent girl %d survived", id)
		}
	}
	if !r.Advanced || !r.Alive(6) || r.Drinks != cleared {
		t.Fatalf("sweep state %+v", r)
	}
}
