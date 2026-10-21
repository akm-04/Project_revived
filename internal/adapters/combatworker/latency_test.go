package combatworker

import (
	"context"
	"crypto/sha256"
	"fmt"
	"math"
	"os"
	"slices"
	"strings"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/content/combatcorpus"
	d "gxb.local/backend/v2/internal/domain/combat"
)

func templateActor(t *testing.T, kind d.ActorKind, table string, tableID int64, star, level, color int) d.Actor {
	fields := map[string]any{"player_id": 0, "table_id": tableID, "star": star, "lev": level, "color": color, "skills": []any{1, 1, 1, 1, 1, 1}}
	if kind == d.PetActor {
		fields["pet_id"], fields["skills"] = tableID, []any{1, 1, 1, 1, 1}
	} else {
		fields["partner_id"], fields["skin_ids"], fields["current_skin_id"], fields["illusion_skin_id"] = tableID, map[string]any{}, 0, -1
		fields["spirit_equip"], fields["spirit_item"], fields["practice_attr"] = []any{}, []any{}, []any{0, 0, 0}
		fields["equips"], fields["fumos"] = []any{0, 0, 0, 0, 0, 0}, []any{0, 0, 0, 0, 0, 0}
	}
	params, err := d.CanonicalJSON(fields)
	if err != nil {
		t.Fatal(err)
	}
	corpus, _ := combatcorpus.Load()
	class, _, _ := corpus.FighterClass(table, tableID)
	return d.Actor{Origin: d.Template, Kind: kind, Identity: tableID, TableID: tableID, FighterClass: class, Params: params}
}

// I8_RESOLVER_LATENCY_V1: p95 of a single fight through the real worker binary
// and the production pool shape stays within 5 s on the reference machine, at
// a steady cadence after the pool's first spares are prepared. Opt-in because
// it measures the host.
func TestResolverLatencyGate(t *testing.T) {
	if os.Getenv("GXB_I8_LATENCY_GATE") != "1" {
		t.Skip("set GXB_I8_LATENCY_GATE=1 on the reference machine")
	}
	const rounds, cadence, bound = 5, 3 * time.Second, 5 * time.Second
	distinctA, distinctB := []int64{10001001, 10001040, 10001122, 10001042, 10001070}, []int64{10001002, 10001003, 10001004, 10001005, 10001006}
	mirror := []int64{10001122, 10001042, 10001070, 10001040, 10001001}
	cases := []struct {
		name        string
		a, b        []int64
		star, level int
		color       int
		pets        bool
		timedOut    bool
	}{
		{"distinct-3-20", distinctA, distinctB, 3, 20, 2, true, false},
		{"distinct-5-100", distinctA, distinctB, 5, 100, 2, true, false},
		{"mirror-5-100", mirror, mirror, 5, 100, 2, true, false},
		{"mirror-timeout-1-1", []int64{10001005}, []int64{10001005}, 1, 1, 1, false, true},
	}
	corpus, _ := combatcorpus.Load()
	l := pool(t, limits(t), 3, 5*time.Second)
	request := func(index int) ([]byte, string) {
		c := cases[index]
		team := func(ids []int64) []d.Actor {
			out := []d.Actor{}
			for _, id := range ids {
				out = append(out, templateActor(t, d.HeroActor, "partner", id, c.star, c.level, c.color))
			}
			return out
		}
		pets := func(id int64) []d.Actor {
			if !c.pets {
				return []d.Actor{}
			}
			return []d.Actor{templateActor(t, d.PetActor, "pet", id, 3, 20, 2)}
		}
		s := d.Snapshot{Schema: d.SnapshotSchema, Contract: d.ContractID, ContentRevision: strings.Repeat("b", 64), CorpusID: corpus.ID(), SourceArchiveSHA256: corpus.SourceArchiveSHA256(),
			TrustProfile: d.TrustProfileID, EntropyPolicy: d.EntropyPolicyVersion, AdapterPolicy: d.AdapterPolicyVersion, CollectionPolicy: d.CollectionPolicy,
			DecidedAt: time.Unix(1700000000, 0).UTC(), Battle: d.Battle{CampaignType: 1, TeamA: team(c.a), WavesB: [][]d.Actor{team(c.b)}, PetsA: pets(10010001), PetsB: pets(10020001)}, Players: []d.PlayerContext{}}
		raw, hash, err := s.Canonical()
		if err != nil {
			t.Fatal(err)
		}
		return raw, hash
	}
	warmRaw, warmHash := request(0)
	cold := time.Now()
	if _, err := l.Resolve(context.Background(), warmRaw, warmHash, root); err != nil {
		t.Fatal(err)
	}
	t.Logf("cold first attempt %s", time.Since(cold))
	time.Sleep(15 * time.Second)
	samples := []time.Duration{}
	for round := range rounds {
		for index, c := range cases {
			raw, hash := request(index)
			began := time.Now()
			output, err := l.Resolve(context.Background(), raw, hash, sha256.Sum256([]byte(fmt.Sprint(c.name, round))))
			elapsed := time.Since(began)
			if err != nil {
				t.Fatal(c.name, err)
			}
			if output.Outcome.TimedOut != c.timedOut {
				t.Fatalf("%s timed out %v", c.name, output.Outcome.TimedOut)
			}
			samples = append(samples, elapsed)
			t.Logf("%s round %d %s frames %d", c.name, round, elapsed, output.Outcome.Frames)
			time.Sleep(max(cadence-elapsed, 0))
		}
	}
	slices.Sort(samples)
	p95 := samples[int(math.Ceil(0.95*float64(len(samples))))-1]
	t.Logf("p95 %s max %s over %d attempts", p95, samples[len(samples)-1], len(samples))
	if p95 > bound {
		t.Fatalf("p95 %s exceeds %s", p95, bound)
	}
}
