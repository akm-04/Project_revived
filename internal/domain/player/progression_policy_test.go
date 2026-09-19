package player

import (
	"encoding/json"
	"math"
	"os"
	"testing"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
)

func sourcePolicy(t *testing.T) ProgressionPolicy {
	t.Helper()
	raw, err := os.ReadFile("../../content/builtin/generated/player_progression.json")
	if err != nil {
		t.Fatal(err)
	}
	var src struct {
		Rows []struct {
			Level int64 `json:"lev"`
			Total int64 `json:"total_exp"`
			Award int64 `json:"award_energy"`
			Cap   int64 `json:"energy"`
		} `json:"rows"`
	}
	if err := json.Unmarshal(raw, &src); err != nil {
		t.Fatal(err)
	}
	p := ProgressionPolicy{Revision: "fixture-current"}
	for _, r := range src.Rows {
		p.Rows = append(p.Rows, ProgressionRow{Level: r.Level, TotalExp: r.Total, AwardEnergy: r.Award, MaxEnergy: r.Cap})
	}
	if len(p.Rows) != 100 {
		t.Fatal(len(p.Rows))
	}
	return p
}

func TestR5ProgressionBoundaries(t *testing.T) {
	p := sourcePolicy(t)
	now := time.Unix(100, 0).UTC()
	pid := identity.PlayerID(100001)
	for _, c := range []struct{ level, exp, gain, wantLevel, wantExp, award int64 }{
		{1, 0, 5, 1, 5, 0}, {1, 0, 6, 2, 6, 6}, {1, 0, 18, 4, 18, 18},
		{99, 579614, 1, 100, 579615, 121}, {100, 579615, math.MaxInt64, 100, 613614, 0}, {100, 613614, math.MaxInt64, 100, 613614, 0},
	} {
		before := Progression{PlayerID: pid, Level: c.level, Exp: c.exp, StateVersion: 1, UpdatedAt: now}
		got, err := p.PlanCreditExp(before, c.gain, now.Add(time.Second))
		if err != nil {
			t.Fatalf("%+v: %v", c, err)
		}
		if got.After.Level != c.wantLevel || got.After.Exp != c.wantExp || got.AwardEnergy != c.award || got.EffectiveExp+got.DiscardedExp != c.gain {
			t.Fatalf("%+v => %+v", c, got)
		}
		if got.EffectiveExp == 0 && got.After != before {
			t.Fatal("saturation mutated progression")
		}
	}
}

func TestR5ProgressionRejectsDrift(t *testing.T) {
	p := sourcePolicy(t)
	now := time.Unix(100, 0).UTC()
	pid := identity.PlayerID(100001)
	for _, c := range []struct{ level, exp, version int64 }{{1, 6, 1}, {100, 613615, 1}, {2, 0, 1}, {1, 0, math.MaxInt64}} {
		before := Progression{PlayerID: pid, Level: c.level, Exp: c.exp, StateVersion: c.version, UpdatedAt: now}
		if _, err := p.PlanCreditExp(before, 1, now); err == nil {
			t.Fatalf("accepted %+v", c)
		}
	}
	p.Rows[1].TotalExp = p.Rows[0].TotalExp
	if p.Validate() == nil {
		t.Fatal("accepted threshold drift")
	}
}
