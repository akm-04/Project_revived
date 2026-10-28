package combat

import (
	"encoding/json"
	"math"
	"testing"
)

func memoirReportFixture() (Snapshot, ReportPolicy, Report) {
	snapshot := reportSnapshot()
	snapshot.Battle.Formation = nil
	second := snapshot.Battle.TeamA[0]
	second.Identity = 4
	snapshot.Battle.TeamA = append(snapshot.Battle.TeamA, second)
	snapshot.Battle.PetsA[0].Origin = OwnedSelf
	snapshot.Battle.PetsA[0].Player = snapshot.Battle.TeamA[0].Player
	enemy := snapshot.Battle.WavesB[0][0]
	enemy.Identity = 8
	snapshot.Battle.WavesB = append(snapshot.Battle.WavesB, []Actor{enemy})
	snapshot.Battle.Context = &BattleContext{Transform: "MEMOIR_CARRY_V1", Parameters: json.RawMessage(`{"first_wave":1}`)}
	policy := ReportPolicy{ID: "I9_MEMOIR_REPORT_V1", Version: 1, Formation: true, Pet: true, CompleteEnemies: true, LivingWinner: true, WinClearsEnemies: true, MaxHP: 1e12, HPPerFrozen: 2, SelectFrozenRoster: true, ReportedWave: true}
	report := acceptedReport()
	report.Formation, report.Round, report.Enemies = []int64{3}, 2, []ActorStatus{{Identity: 8}}
	return snapshot, policy, report
}

func TestFrozenRosterSelectionAndWaveProgress(t *testing.T) {
	snapshot, policy, report := memoirReportFixture()
	before, _ := json.Marshal(snapshot)
	verdict, reason, progress := policy.JudgeWithProgress(snapshot, report)
	if !policy.Valid() || verdict != VerdictAccepted || reason != "" || progress.Wave != 2 || progress.NextWave != 3 {
		t.Fatal(verdict, reason, progress)
	}
	after, _ := json.Marshal(snapshot)
	if string(before) != string(after) {
		t.Fatal("projection mutated the immutable snapshot")
	}
	cases := []struct {
		name   string
		mutate func(*Snapshot, *Report)
		reason string
	}{
		{"unfrozen hero", func(_ *Snapshot, r *Report) { r.Formation = []int64{99} }, "FORMATION_NOT_ELIGIBLE"},
		{"duplicate selection", func(_ *Snapshot, r *Report) { r.Formation = []int64{3, 3} }, "FORMATION_NOT_ELIGIBLE"},
		{"zero slot", func(_ *Snapshot, r *Report) { r.Formation = []int64{0, 3} }, "FORMATION_NOT_ELIGIBLE"},
		{"oversized team", func(_ *Snapshot, r *Report) { r.Formation = []int64{3, 4, 5, 6, 7, 8} }, "ROSTER_SELECTION_INVALID"},
		{"missing selected ally", func(_ *Snapshot, r *Report) { r.Allies = nil }, "ALLY_MISSING"},
		{"unselected ally", func(_ *Snapshot, r *Report) { r.Allies[0].Identity = 4 }, "ALLY_UNKNOWN"},
		{"foreign owner", func(s *Snapshot, _ *Report) { s.Battle.TeamA[1].Origin = OwnedForeign }, "ROSTER_OWNER_INVALID"},
		{"pet not frozen", func(_ *Snapshot, r *Report) { r.Pet = 99 }, "PET_NOT_ELIGIBLE"},
		{"frozen exact formation", func(s *Snapshot, _ *Report) { s.Battle.Formation = []int64{3, 4} }, "ROSTER_SELECTION_INVALID"},
		{"not full-report profile", func(s *Snapshot, _ *Report) { s.TrustProfile = ClientSummaryAttested.ID }, "ROSTER_SELECTION_INVALID"},
		{"wrong wave", func(_ *Snapshot, r *Report) { r.Enemies[0].Identity = 99 }, "WAVE_IDENTITIES_CHANGED"},
		{"empty wave", func(_ *Snapshot, r *Report) { r.Enemies = nil }, "WAVE_IDENTITIES_CHANGED"},
		{"round below frozen", func(s *Snapshot, r *Report) {
			s.Battle.Context.Parameters = json.RawMessage(`{"first_wave":2}`)
			r.Round = 1
		}, "ROUND_OUT_OF_RANGE"},
		{"round beyond end", func(_ *Snapshot, r *Report) { r.Round = 4 }, "ROUND_OUT_OF_RANGE"},
		{"early victory", func(_ *Snapshot, r *Report) { r.Round = 1; r.Enemies[0].Identity = 3 }, "WIN_BEFORE_FINAL_WAVE"},
		{"unfinished victory", func(_ *Snapshot, r *Report) { r.Enemies[0].HP = 1 }, "WIN_WITH_ENEMY_ALIVE"},
		{"dead winner", func(_ *Snapshot, r *Report) { r.Allies[0].HP = 0 }, "WIN_WITHOUT_SURVIVOR"},
		{"over frozen HP", func(_ *Snapshot, r *Report) { r.Allies[0].HP = 201 }, "HP_ABOVE_FROZEN_BOUND"},
		{"nonfinite", func(_ *Snapshot, r *Report) { r.Allies[0].HP = math.NaN() }, "NONFINITE_REPORT"},
	}
	for _, test := range cases {
		t.Run(test.name, func(t *testing.T) {
			s, p, r := memoirReportFixture()
			test.mutate(&s, &r)
			v, why, progress := p.JudgeWithProgress(s, r)
			if v != VerdictRejected || why != test.reason || progress != (ReportProgress{}) {
				t.Fatal(v, why, progress)
			}
		})
	}
}

func TestWaveReportCarriesCurrentOrClearedPreviousWave(t *testing.T) {
	snapshot, policy, report := memoirReportFixture()
	report.Win = false
	report.Enemies = []ActorStatus{{Identity: 3}}
	verdict, reason, progress := policy.JudgeWithProgress(snapshot, report)
	if verdict != VerdictAccepted || reason != "" || progress != (ReportProgress{Wave: 1, NextWave: 2}) {
		t.Fatal(verdict, reason, progress)
	}
	report.Enemies[0].HP = 1
	if verdict, _, _ := policy.JudgeWithProgress(snapshot, report); verdict != VerdictRejected {
		t.Fatal("unfinished previous wave accepted as advancement")
	}
	report.Round = 1
	verdict, reason, progress = policy.JudgeWithProgress(snapshot, report)
	if verdict != VerdictAccepted || progress != (ReportProgress{Wave: 1, NextWave: 1}) {
		t.Fatal(verdict, reason, progress)
	}
	snapshot.Battle.WavesB[0] = append(snapshot.Battle.WavesB[0], snapshot.Battle.WavesB[0][0])
	if verdict, reason := policy.Judge(snapshot, report); verdict != VerdictAccepted {
		t.Fatal("source status map collapses duplicate table identities", reason)
	}
	report.Enemies = append(report.Enemies, report.Enemies[0])
	if verdict, _, _ := policy.JudgeWithProgress(snapshot, report); verdict != VerdictRejected {
		t.Fatal("duplicate report identity accepted")
	}
}
