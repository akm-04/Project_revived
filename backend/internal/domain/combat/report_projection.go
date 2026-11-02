package combat

import "encoding/json"

const stockTeamMemberLimit = 5

type ReportProgress struct {
	Wave     int
	NextWave int
}

// JudgeWithProgress keeps selection and wave interpretation inside the Combat owner.
func (p ReportPolicy) JudgeWithProgress(snapshot Snapshot, report Report) (Verdict, string, ReportProgress) {
	if !report.Finite() {
		return VerdictRejected, "NONFINITE_REPORT", ReportProgress{}
	}
	if p.SelectFrozenRoster {
		selected, reason := selectReportRoster(snapshot, report)
		if reason != "" {
			return VerdictRejected, reason, ReportProgress{}
		}
		snapshot.Battle = selected
	}
	progress := ReportProgress{}
	if p.ReportedWave {
		selected, position, reason := selectReportWave(snapshot, report)
		if reason != "" {
			return VerdictRejected, reason, ReportProgress{}
		}
		snapshot.Battle.WavesB = [][]Actor{selected}
		progress = position
	}
	verdict, reason := p.judgeStrict(snapshot, report)
	if verdict != VerdictAccepted {
		return verdict, reason, ReportProgress{}
	}
	return verdict, reason, progress
}

func selectReportRoster(snapshot Snapshot, report Report) (Battle, string) {
	battle := snapshot.Battle
	if snapshot.TrustProfile != ClientFullReportAttested.ID || len(battle.Formation) != 0 || len(report.Formation) == 0 || len(report.Formation) > stockTeamMemberLimit {
		return Battle{}, "ROSTER_SELECTION_INVALID"
	}
	eligible := map[int64]Actor{}
	owner := int64(0)
	for _, actor := range battle.TeamA {
		if actor.Origin != OwnedSelf || actor.Player <= 0 || owner != 0 && actor.Player != owner {
			return Battle{}, "ROSTER_OWNER_INVALID"
		}
		if _, duplicate := eligible[actor.Identity]; duplicate {
			return Battle{}, "ROSTER_DUPLICATE"
		}
		owner = actor.Player
		eligible[actor.Identity] = actor
	}
	selected := []Actor{}
	seen := map[int64]bool{}
	for _, identity := range report.Formation {
		actor, found := eligible[identity]
		if !found || identity <= 0 || seen[identity] {
			return Battle{}, "FORMATION_NOT_ELIGIBLE"
		}
		seen[identity] = true
		selected = append(selected, actor)
	}
	pets := []Actor{}
	if report.Pet < 0 {
		return Battle{}, "PET_NOT_ELIGIBLE"
	}
	for _, actor := range battle.PetsA {
		if actor.Identity != report.Pet || report.Pet == 0 {
			continue
		}
		if actor.Origin != OwnedSelf || actor.Player != owner || len(pets) != 0 {
			return Battle{}, "PET_NOT_ELIGIBLE"
		}
		pets = append(pets, actor)
	}
	if report.Pet > 0 && len(pets) != 1 {
		return Battle{}, "PET_NOT_ELIGIBLE"
	}
	battle.TeamA, battle.PetsA = selected, pets
	battle.Formation = append([]int64{}, report.Formation...)
	return battle, ""
}

func selectReportWave(snapshot Snapshot, report Report) ([]Actor, ReportProgress, string) {
	var parameters struct {
		FirstWave int `json:"first_wave"`
	}
	waves := snapshot.Battle.WavesB
	context := snapshot.Battle.Context
	if context == nil || json.Unmarshal(context.Parameters, &parameters) != nil || parameters.FirstWave < 1 || parameters.FirstWave > len(waves) {
		return nil, ReportProgress{}, "FIRST_WAVE_NOT_FROZEN"
	}
	if report.Round < parameters.FirstWave || report.Round > len(waves)+1 || !report.Win && report.Round > len(waves) {
		return nil, ReportProgress{}, "ROUND_OUT_OF_RANGE"
	}
	index := report.Round - 1
	covered := index < len(waves) && reportCoversWave(waves[index], report.Enemies)
	cleared := len(report.Enemies) > 0
	for _, enemy := range report.Enemies {
		cleared = cleared && enemy.HP == 0
	}
	if !covered {
		index--
		previousCovered := index >= parameters.FirstWave-1 && index < len(waves) && cleared && reportCoversWave(waves[index], report.Enemies)
		if !previousCovered {
			return nil, ReportProgress{}, "WAVE_IDENTITIES_CHANGED"
		}
	}
	if report.Win && index != len(waves)-1 {
		return nil, ReportProgress{}, "WIN_BEFORE_FINAL_WAVE"
	}
	next := index + 1
	if cleared && (index < len(waves)-1 || report.Win) {
		next++
	}
	return waves[index], ReportProgress{Wave: index + 1, NextWave: next}, ""
}

func reportCoversWave(wave []Actor, statuses []ActorStatus) bool {
	identities := map[int64]int64{}
	for _, actor := range wave {
		identities[actor.Identity] = actor.Player
	}
	if len(statuses) != len(identities) {
		return false
	}
	seen := map[int64]bool{}
	for _, status := range statuses {
		player, found := identities[status.Identity]
		if !found || player != status.Player || seen[status.Identity] {
			return false
		}
		seen[status.Identity] = true
	}
	return true
}
