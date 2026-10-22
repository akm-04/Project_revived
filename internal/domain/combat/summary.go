package combat

import (
	"encoding/json"
	"slices"
)

// RejectedKind closes a client-summary attempt whose summary failed its family
// validator; it settles no value and cannot be retried until it passes.
const RejectedKind = "REJECTED"

// Summary is a client-attested RESULT summary as the mode adapter decoded it
// from the stock wire. It is CLIENT_ATTESTED evidence for bounds and history,
// never a replay (I8_ATTESTED_SUMMARY_STORAGE_V1).
type Summary struct {
	Star      int64         `json:"star"`
	Win       bool          `json:"win"`
	Damage    int64         `json:"total_damage"`
	Alive     int64         `json:"alive"`
	Formation []int64       `json:"formation"`
	Pet       int64         `json:"pet"`
	Enemies   []EnemyStatus `json:"enemies"`
}

type EnemyStatus struct {
	Identity int64 `json:"identity"`
	HP       int64 `json:"hp"`
}

// SummaryRecord is the stored attestation summary with the rejection reason.
type SummaryRecord struct {
	Summary Summary `json:"summary"`
	Reason  string  `json:"reason,omitempty"`
}

// SummaryPolicy is a family's versioned CLIENT_SUMMARY_ATTESTED validator.
// Its bounds are private policy (I8_CLIENT_SUMMARY_BOUNDS_V1): the original
// server's checks are UNKNOWN. A changed bound is a new version, never an edit.
type SummaryPolicy struct {
	ID      string
	Version int
	// MaxStar bounds the star rating; zero means the family's RESULT carries none.
	MaxStar int64
	// WinFromStar makes a positive star the win (campaign families).
	WinFromStar bool
	// MaxDamage bounds total damage; zero means the RESULT carries none.
	MaxDamage int64
	// DamagePerForce, when positive, caps damage at this multiple of the
	// frozen team force (the 3B battle-facing projection, D9 Q4(a)).
	DamagePerForce int64
}

func (p SummaryPolicy) Valid() bool {
	return versionedID.MatchString(p.ID) && p.Version > 0 && p.MaxStar >= 0 && p.MaxDamage >= 0 && p.DamagePerForce >= 0
}

// Judge checks the summary against the attempt's frozen snapshot and returns
// the verdict with a stable reason code for a rejection (H-27, H-41).
func (p SummaryPolicy) Judge(snapshot Snapshot, summary Summary) (Verdict, string) {
	battle := snapshot.Battle
	frozenPet := int64(0)
	if len(battle.PetsA) > 0 {
		frozenPet = battle.PetsA[0].Identity
	}
	starInRange := summary.Star >= 0 && summary.Star <= p.MaxStar
	winMatchesStar := !p.WinFromStar || summary.Win == (summary.Star > 0)
	damageInRange := summary.Damage >= 0 && summary.Damage <= p.MaxDamage
	switch {
	case len(battle.Formation) == 0:
		return VerdictRejected, "FORMATION_NOT_FROZEN"
	case !slices.Equal(summary.Formation, battle.Formation):
		return VerdictRejected, "FORMATION_CHANGED"
	case summary.Pet != frozenPet:
		return VerdictRejected, "PET_CHANGED"
	case !starInRange:
		return VerdictRejected, "STAR_OUT_OF_RANGE"
	case !winMatchesStar:
		return VerdictRejected, "WIN_STAR_MISMATCH"
	case !damageInRange:
		return VerdictRejected, "DAMAGE_OUT_OF_RANGE"
	case p.DamagePerForce > 0 && float64(summary.Damage) > float64(p.DamagePerForce)*teamForce(battle):
		return VerdictRejected, "DAMAGE_ABOVE_FORCE_BOUND"
	case summary.Alive < 0 || summary.Alive > int64(len(battle.TeamA)):
		return VerdictRejected, "ALIVE_OUT_OF_RANGE"
	}
	return judgeEnemies(battle, summary.Enemies)
}

func judgeEnemies(battle Battle, enemies []EnemyStatus) (Verdict, string) {
	frozen := map[int64]bool{}
	count := 0
	for _, wave := range battle.WavesB {
		for _, a := range wave {
			frozen[a.Identity] = true
			count++
		}
	}
	if len(enemies) > count {
		return VerdictRejected, "ENEMY_UNKNOWN"
	}
	for _, enemy := range enemies {
		if !frozen[enemy.Identity] {
			return VerdictRejected, "ENEMY_UNKNOWN"
		}
		if enemy.HP < 0 {
			return VerdictRejected, "ENEMY_HP_NEGATIVE"
		}
	}
	return VerdictAccepted, ""
}

// teamForce sums the frozen battle-facing force of the attacking heroes and
// pets; template actors carry no owner projection and add nothing.
func teamForce(battle Battle) float64 {
	total := 0.0
	for _, a := range append(append([]Actor{}, battle.TeamA...), battle.PetsA...) {
		var totals struct {
			Force float64 `json:"force"`
		}
		if json.Unmarshal(a.BattleTotals, &totals) == nil {
			total += totals.Force
		}
	}
	return total
}
