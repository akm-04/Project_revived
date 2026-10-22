package combat

import (
	"encoding/json"
	"math"
	"testing"
)

var marchPolicy = ReportPolicy{ID: "FIXTURE_MARCH_REPORT_V1", Version: 1, Formation: true, Pet: true, WinClearsEnemies: true, MaxHP: 1e12, HPPerFrozen: 2}

// reportSnapshot is a client full-report START: hero 3 of player 9 with a
// frozen HP attribute of 100, pet 7, one template enemy 3.
func reportSnapshot() Snapshot {
	s := summarySnapshot()
	s.TrustProfile = ClientFullReportAttested.ID
	s.Battle.TeamA[0].BattleTotals = json.RawMessage(`{"force":1000,"total":[1,1,1,100]}`)
	return s
}

func acceptedReport() Report {
	return Report{Win: true, Formation: []int64{0, 3, 0}, Pet: 7, Allies: []ActorStatus{{Player: 9, Identity: 3, HP: 150.5, MP: 1000, Reborn: 1}}, Enemies: []ActorStatus{{Identity: 3}}}
}

func TestReportPolicyBounds(t *testing.T) {
	if verdict, reason := marchPolicy.Judge(reportSnapshot(), acceptedReport()); verdict != VerdictAccepted || reason != "" {
		t.Fatal(verdict, reason)
	}
	cases := map[string]struct {
		mutate func(*Report, *Snapshot)
		reason string
	}{
		"H-41 formation moved":      {func(r *Report, _ *Snapshot) { r.Formation = []int64{3, 0, 0} }, "FORMATION_CHANGED"},
		"formation not frozen":      {func(_ *Report, s *Snapshot) { s.Battle.Formation = nil }, "FORMATION_NOT_FROZEN"},
		"H-41 pet swapped":          {func(r *Report, _ *Snapshot) { r.Pet = 8 }, "PET_CHANGED"},
		"H-42 unknown ally":         {func(r *Report, _ *Snapshot) { r.Allies[0].Identity = 4 }, "ALLY_UNKNOWN"},
		"H-42 ally of other player": {func(r *Report, _ *Snapshot) { r.Allies[0].Player = 10 }, "ALLY_UNKNOWN"},
		"H-42 duplicate ally":       {func(r *Report, _ *Snapshot) { r.Allies = append(r.Allies, r.Allies[0]) }, "ALLY_DUPLICATE"},
		"H-42 missing ally":         {func(r *Report, _ *Snapshot) { r.Allies = nil }, "ALLY_MISSING"},
		"H-42 unknown enemy":        {func(r *Report, _ *Snapshot) { r.Enemies[0].Identity = 99 }, "ENEMY_UNKNOWN"},
		"H-42 duplicate enemy":      {func(r *Report, _ *Snapshot) { r.Enemies = append(r.Enemies, r.Enemies[0]) }, "ENEMY_DUPLICATE"},
		"H-43 negative hp":          {func(r *Report, _ *Snapshot) { r.Allies[0].HP = -0.5 }, "HP_OUT_OF_RANGE"},
		"H-43 hp above cap":         {func(r *Report, _ *Snapshot) { r.Enemies[0].HP = 2e12 }, "HP_OUT_OF_RANGE"},
		"H-43 hp above frozen":      {func(r *Report, _ *Snapshot) { r.Allies[0].HP = 200.5 }, "HP_ABOVE_FROZEN_BOUND"},
		"H-43 mp above clamp":       {func(r *Report, _ *Snapshot) { r.Allies[0].MP = 1000.5 }, "MP_OUT_OF_RANGE"},
		"H-43 negative mp":          {func(r *Report, _ *Snapshot) { r.Enemies[0].MP = -1 }, "MP_OUT_OF_RANGE"},
		"H-43 reborn not boolean":   {func(r *Report, _ *Snapshot) { r.Allies[0].Reborn = 2 }, "REBORN_OUT_OF_RANGE"},
		"win with enemy alive":      {func(r *Report, _ *Snapshot) { r.Enemies[0].HP = 1 }, "WIN_WITH_ENEMY_ALIVE"},
	}
	for name, c := range cases {
		report, snapshot := acceptedReport(), reportSnapshot()
		c.mutate(&report, &snapshot)
		if verdict, reason := marchPolicy.Judge(snapshot, report); verdict != VerdictRejected || reason != c.reason {
			t.Fatal(name, verdict, reason)
		}
	}
	treasure := ReportPolicy{ID: "FIXTURE_TREASURE_REPORT_V1", Version: 1, MaxHP: 1e12}
	loose := acceptedReport()
	loose.Formation, loose.Pet, loose.Win, loose.Enemies[0].HP, loose.Allies[0].HP = nil, 0, false, 5, 1e9
	if verdict, reason := treasure.Judge(reportSnapshot(), loose); verdict != VerdictAccepted {
		t.Fatal("a family without formation, pet or frozen ratio", reason)
	}
	templateAlly := acceptedReport()
	snapshot := reportSnapshot()
	snapshot.Battle.TeamA[0].BattleTotals = nil
	templateAlly.Allies[0].HP = 1e9
	if verdict, reason := marchPolicy.Judge(snapshot, templateAlly); verdict != VerdictAccepted {
		t.Fatal("an actor without frozen totals is bounded by the absolute cap only", reason)
	}
	for _, policy := range []ReportPolicy{{ID: "FIXTURE_V1", Version: 1}, {ID: "fixture_V1", Version: 1, MaxHP: 1}, {ID: "FIXTURE_V1", MaxHP: 1}, {ID: "FIXTURE_V1", Version: 1, MaxHP: 1, HPPerFrozen: -1}} {
		if policy.Valid() {
			t.Fatal("invalid policy accepted", policy)
		}
	}
	for _, bad := range []float64{math.NaN(), math.Inf(1), math.Inf(-1)} {
		report := acceptedReport()
		report.Enemies[0].MP = bad
		if report.Finite() {
			t.Fatal("non-finite report", bad)
		}
	}
	if !acceptedReport().Finite() {
		t.Fatal("finite report")
	}
}

// FuzzReportJudge drives the stock JSON codec into Judge (H-42, H-43): decoded
// numbers are always finite and an accepted report satisfies every bound.
func FuzzReportJudge(f *testing.F) {
	accepted, _ := json.Marshal(acceptedReport())
	f.Add(accepted)
	f.Add([]byte(`{"win":true,"formation":[0,3,0],"pet":7,"allies":[{"player_id":9,"identity":3,"hp":1e400}],"enemies":[]}`))
	f.Add([]byte(`{"allies":[{"player_id":9,"identity":3,"hp":NaN}]}`))
	f.Add([]byte(`{"formation":[0,3,0],"pet":7,"allies":[{"player_id":9,"identity":4,"hp":1}],"enemies":[{"identity":3,"mp":-1}]}`))
	snapshot := reportSnapshot()
	f.Fuzz(func(t *testing.T, raw []byte) {
		var report Report
		if json.Unmarshal(raw, &report) != nil {
			return
		}
		if !report.Finite() {
			t.Fatal("the JSON codec produced a non-finite value", string(raw))
		}
		verdict, reason := marchPolicy.Judge(snapshot, report)
		if verdict == VerdictRejected {
			if reason == "" {
				t.Fatal("rejection without reason")
			}
			return
		}
		if len(report.Allies) != 1 || report.Allies[0].Player != 9 || report.Allies[0].Identity != 3 || report.Allies[0].HP > 200 {
			t.Fatal("accepted an ally outside the frozen team or bound", string(raw))
		}
		for _, status := range append(report.Allies, report.Enemies...) {
			if status.HP < 0 || status.MP < 0 || status.MP > stockEnergyCap || status.Reborn < 0 || status.Reborn > 1 || report.Win && status.Identity == 3 && status.Player == 0 && status.HP > 0 {
				t.Fatal("accepted an out-of-range status", string(raw))
			}
		}
	})
}
