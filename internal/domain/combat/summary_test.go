package combat

import (
	"bytes"
	"encoding/json"
	"testing"
	"time"
)

// summarySnapshot is a client-summary START: hero 3 in slot 2 of 3, pet 7,
// force 1000, one template enemy; the pet is a template (no owner producers).
func summarySnapshot() Snapshot {
	s := fixtureSnapshot()
	s.TrustProfile = ClientSummaryAttested.ID
	s.Battle.TeamA[0].BattleTotals = json.RawMessage(`{"force":1000,"hp":1}`)
	pet := fixtureActor(Template, 0)
	pet.Kind, pet.Identity = PetActor, 7
	s.Battle.PetsA = []Actor{pet}
	s.Battle.Formation = []int64{0, 3, 0}
	return s
}

func acceptedSummary() Summary {
	return Summary{Star: 3, Win: true, Damage: 5000, Alive: 1, Formation: []int64{0, 3, 0}, Pet: 7, Enemies: []EnemyStatus{{Identity: 3, HP: 0}}}
}

func TestSnapshotFormationRules(t *testing.T) {
	s := summarySnapshot()
	raw, hash, err := s.Canonical()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = DecodeSnapshot(raw, hash); err != nil {
		t.Fatal(err)
	}
	plain, _, err := fixtureSnapshot().Canonical()
	if err != nil || bytes.Contains(plain, []byte("formation")) {
		t.Fatal("a snapshot without formation must keep its bytes", err)
	}
	rejected := map[string]func(*Snapshot){
		"server profile": func(s *Snapshot) { s.TrustProfile = TrustProfileID },
		"schema 2":       func(s *Snapshot) { s.Schema = ContextSnapshotSchema; s.TrustProfile = TrustProfileID },
		"negative slot":  func(s *Snapshot) { s.Battle.Formation = []int64{-1, 3} },
		"wrong hero":     func(s *Snapshot) { s.Battle.Formation = []int64{4} },
		"missing hero":   func(s *Snapshot) { s.Battle.Formation = []int64{0, 0} },
		"extra hero":     func(s *Snapshot) { s.Battle.Formation = []int64{3, 5} },
		"hero order kept": func(s *Snapshot) {
			s.Battle.TeamA = append(s.Battle.TeamA, s.Battle.TeamA[0])
			s.Battle.Formation = []int64{3, 4}
		},
	}
	for name, mutate := range rejected {
		s := summarySnapshot()
		mutate(&s)
		if err := s.Validate(); err == nil {
			t.Fatal(name, "accepted")
		}
	}
}

func TestSummaryPolicyBounds(t *testing.T) {
	campaign := SummaryPolicy{ID: "FIXTURE_CAMPAIGN_SUMMARY_V1", Version: 1, MaxStar: 3, WinFromStar: true, MaxDamage: 1 << 40, DamagePerForce: 10}
	if verdict, reason := campaign.Judge(summarySnapshot(), acceptedSummary()); verdict != VerdictAccepted || reason != "" {
		t.Fatal(verdict, reason)
	}
	cases := map[string]struct {
		mutate func(*Summary, *Snapshot)
		reason string
	}{
		"H-41 formation slot moved": {func(m *Summary, _ *Snapshot) { m.Formation = []int64{3, 0, 0} }, "FORMATION_CHANGED"},
		"H-41 hero swapped":         {func(m *Summary, _ *Snapshot) { m.Formation = []int64{0, 4, 0} }, "FORMATION_CHANGED"},
		"H-41 pet swapped":          {func(m *Summary, _ *Snapshot) { m.Pet = 8 }, "PET_CHANGED"},
		"formation not frozen":      {func(_ *Summary, s *Snapshot) { s.Battle.Formation = nil }, "FORMATION_NOT_FROZEN"},
		"H-27 star above family":    {func(m *Summary, _ *Snapshot) { m.Star = 4 }, "STAR_OUT_OF_RANGE"},
		"H-27 negative star":        {func(m *Summary, _ *Snapshot) { m.Star, m.Win = -1, false }, "STAR_OUT_OF_RANGE"},
		"H-27 win without star":     {func(m *Summary, _ *Snapshot) { m.Star = 0 }, "WIN_STAR_MISMATCH"},
		"H-27 negative damage":      {func(m *Summary, _ *Snapshot) { m.Damage = -1 }, "DAMAGE_OUT_OF_RANGE"},
		"H-27 damage above force":   {func(m *Summary, _ *Snapshot) { m.Damage = 10001 }, "DAMAGE_ABOVE_FORCE_BOUND"},
		"H-27 more alive than team": {func(m *Summary, _ *Snapshot) { m.Alive = 2 }, "ALIVE_OUT_OF_RANGE"},
		"H-27 unknown enemy":        {func(m *Summary, _ *Snapshot) { m.Enemies = []EnemyStatus{{Identity: 99}} }, "ENEMY_UNKNOWN"},
		"H-27 more enemies":         {func(m *Summary, _ *Snapshot) { m.Enemies = append(m.Enemies, m.Enemies[0]) }, "ENEMY_UNKNOWN"},
		"H-27 negative enemy hp":    {func(m *Summary, _ *Snapshot) { m.Enemies[0].HP = -5 }, "ENEMY_HP_NEGATIVE"},
	}
	for name, c := range cases {
		summary, snapshot := acceptedSummary(), summarySnapshot()
		c.mutate(&summary, &snapshot)
		if verdict, reason := campaign.Judge(snapshot, summary); verdict != VerdictRejected || reason != c.reason {
			t.Fatal(name, verdict, reason)
		}
	}
	noDamage := SummaryPolicy{ID: "FIXTURE_NO_DAMAGE_V1", Version: 1, MaxStar: 3}
	if verdict, reason := noDamage.Judge(summarySnapshot(), acceptedSummary()); reason != "DAMAGE_OUT_OF_RANGE" {
		t.Fatal("a family without damage must reject a damage value", verdict)
	}
	loss := acceptedSummary()
	loss.Star, loss.Win = 0, false
	if verdict, _ := campaign.Judge(summarySnapshot(), loss); verdict != VerdictAccepted {
		t.Fatal("a loss is a valid summary")
	}
	for _, policy := range []SummaryPolicy{{ID: "lower_V1", Version: 1}, {ID: "FIXTURE_V1"}, {ID: "FIXTURE_V1", Version: 1, MaxStar: -1}, {ID: "FIXTURE_V1", Version: 1, DamagePerForce: -1}} {
		if policy.Valid() {
			t.Fatal("invalid policy accepted", policy)
		}
	}
}

func TestAttestRefusedPastDeadline(t *testing.T) {
	start := time.Unix(1700000000, 0).UTC()
	a := clientAttempt(start)
	if _, err := a.Attest("WIN", "attest:x", a.ResultDeadline); err == nil {
		t.Fatal("attested at the deadline")
	}
	if _, err := a.Attest(RejectedKind, "attest:x", start.Add(time.Second)); err != nil {
		t.Fatal(err)
	}
}
