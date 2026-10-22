package combat

import (
	"encoding/json"
	"math"
)

// stockEnergyCap is the stock fighter energy clamp (src_64 const.lua
// ENERGY_DECIMAL_BASE; BaseFighter.updateEnergyTo).
const stockEnergyCap = 1000

// stockHPAttribute indexes the HP attribute in the frozen battle totals
// (src_64 AttributeType.HP = 4; totals are indexed by type - 1).
const stockHPAttribute = 3

// Report is a CLIENT_FULL_REPORT_ATTESTED RESULT as the mode adapter decoded
// it from the stock wire: the end state of every non-summoned fighter (March
// and Treasure hero/enemy status, Memoir heroes/enemies status). Family
// extras stay with the mode. It is CLIENT_ATTESTED evidence, never a replay.
type Report struct {
	Win       bool          `json:"win"`
	Formation []int64       `json:"formation,omitempty"`
	Pet       int64         `json:"pet,omitempty"`
	Allies    []ActorStatus `json:"allies"`
	Enemies   []ActorStatus `json:"enemies"`
}

type ActorStatus struct {
	Player   int64   `json:"player_id,omitempty"`
	Identity int64   `json:"identity"`
	HP       float64 `json:"hp"`
	MP       float64 `json:"mp"`
	Reborn   int64   `json:"is_reborn"`
}

// Finite reports whether every number is representable; the stock JSON codec
// cannot carry NaN or Inf, so a non-finite value is refused, never stored.
func (r Report) Finite() bool {
	for _, status := range append(append([]ActorStatus{}, r.Allies...), r.Enemies...) {
		if math.IsNaN(status.HP) || math.IsInf(status.HP, 0) || math.IsNaN(status.MP) || math.IsInf(status.MP, 0) {
			return false
		}
	}
	return true
}

// ReportPolicy is a family's versioned CLIENT_FULL_REPORT_ATTESTED validator.
// Its bounds are private policy (D19): the original server's checks are
// UNKNOWN. A changed bound is a new version, never an edit.
type ReportPolicy struct {
	ID      string
	Version int
	// Formation and Pet say the family RESULT carries them (March, Memoir).
	Formation bool
	Pet       bool
	// WinClearsEnemies makes a win require every reported enemy at zero hp.
	WinClearsEnemies bool
	MaxHP            float64
	// HPPerFrozen, when positive, caps an actor's hp at this multiple of its
	// frozen HP attribute; buffs may raise the stock hp limit.
	HPPerFrozen float64
}

func (p ReportPolicy) Valid() bool {
	return versionedID.MatchString(p.ID) && p.Version > 0 && p.MaxHP > 0 && p.HPPerFrozen >= 0
}

// Judge checks the report against the attempt's frozen snapshot and returns
// the verdict with a stable reason code for a rejection (H-42, H-43, H-41).
func (p ReportPolicy) Judge(snapshot Snapshot, report Report) (Verdict, string) {
	battle := snapshot.Battle
	if p.Formation {
		if verdict, reason := judgeFormation(battle, report.Formation); verdict == VerdictRejected {
			return verdict, reason
		}
	}
	if p.Pet && report.Pet != frozenPet(battle) {
		return VerdictRejected, "PET_CHANGED"
	}
	allies := map[[2]int64]Actor{}
	for _, a := range battle.TeamA {
		allies[[2]int64{a.Player, a.Identity}] = a
	}
	if verdict, reason := p.judgeStatuses(report.Allies, func(s ActorStatus) (Actor, bool) {
		a, ok := allies[[2]int64{s.Player, s.Identity}]
		return a, ok
	}, "ALLY"); verdict == VerdictRejected {
		return verdict, reason
	}
	if len(report.Allies) != len(allies) {
		return VerdictRejected, "ALLY_MISSING"
	}
	enemies := frozenEnemies(battle)
	if verdict, reason := p.judgeStatuses(report.Enemies, func(s ActorStatus) (Actor, bool) {
		a, ok := enemies[s.Identity]
		return a, ok
	}, "ENEMY"); verdict == VerdictRejected {
		return verdict, reason
	}
	if p.WinClearsEnemies && report.Win {
		for _, enemy := range report.Enemies {
			if enemy.HP > 0 {
				return VerdictRejected, "WIN_WITH_ENEMY_ALIVE"
			}
		}
	}
	return VerdictAccepted, ""
}

func (p ReportPolicy) judgeStatuses(statuses []ActorStatus, frozen func(ActorStatus) (Actor, bool), side string) (Verdict, string) {
	seen := map[[2]int64]bool{}
	for _, status := range statuses {
		actor, ok := frozen(status)
		key := [2]int64{status.Player, status.Identity}
		switch {
		case !ok:
			return VerdictRejected, side + "_UNKNOWN"
		case seen[key]:
			return VerdictRejected, side + "_DUPLICATE"
		case status.HP < 0 || status.HP > p.MaxHP:
			return VerdictRejected, "HP_OUT_OF_RANGE"
		case p.HPPerFrozen > 0 && status.HP > p.HPPerFrozen*frozenHP(actor):
			return VerdictRejected, "HP_ABOVE_FROZEN_BOUND"
		case status.MP < 0 || status.MP > stockEnergyCap:
			return VerdictRejected, "MP_OUT_OF_RANGE"
		case status.Reborn != 0 && status.Reborn != 1:
			return VerdictRejected, "REBORN_OUT_OF_RANGE"
		}
		seen[key] = true
	}
	return VerdictAccepted, ""
}

// frozenHP is the actor's frozen HP attribute; an actor without battle totals
// (a template) is bounded by the family's absolute cap only.
func frozenHP(a Actor) float64 {
	var totals struct {
		Total []float64 `json:"total"`
	}
	if json.Unmarshal(a.BattleTotals, &totals) != nil || len(totals.Total) <= stockHPAttribute {
		return math.Inf(1)
	}
	return totals.Total[stockHPAttribute]
}
