package character

import (
	"errors"
	"math"
	"time"
)

type HeroExpThreshold struct {
	Level    int64 `json:"level"`
	TotalExp int64 `json:"total_exp"`
}

type HeroTemplateProgression struct {
	Kind           HeroKind
	OriginTableID  int64
	FragmentItemID int64
	InitialStar    int64
}

type HeroAcquisitionTemplate struct {
	TableID        int64
	OriginTableID  int64
	Kind           HeroKind
	InitialStar    int64
	FragmentItemID int64
}

type HeroNormalSummonPolicy struct {
	Template      HeroAcquisitionTemplate
	FragmentCount int64
	Mana          int64
}

type HeroEvolutionPolicy struct {
	FragmentCount int64
	Mana          int64
	NeedHeroNum   int64
	Effective     bool
}

type HeroPieceMapping struct {
	ItemID        int64 `json:"item_id"`
	OriginTableID int64 `json:"origin_table_id"`
}

// AddSourceEXP applies the recovered NormalHero/SuperHero EXP semantics: total
// EXP is clamped to totalExp(heroMaxLev(player.lev)), then level is derived from
// cumulative thresholds without exceeding that player-qualified Hero max level.
func (h Hero) AddSourceEXP(amount, maxLevel int64, thresholds []HeroExpThreshold, now time.Time) (Hero, error) {
	if err := h.ValidatePersistent(); err != nil {
		return Hero{}, err
	}
	if amount <= 0 || maxLevel <= 0 || maxLevel > MaxHeroLevel || int64(len(thresholds)) != maxLevel || now.IsZero() {
		return Hero{}, errors.New("character hero: invalid EXP progression input")
	}
	var prev int64 = -1
	for i, x := range thresholds {
		if x.Level != int64(i+1) || x.TotalExp < 0 || x.TotalExp < prev {
			return Hero{}, errors.New("character hero: invalid EXP thresholds")
		}
		prev = x.TotalExp
	}
	if h.Level > maxLevel {
		// Canonical imported state may predate a lower current player-level cap;
		// CA2-2 never de-levels a Hero. Fail closed instead of inventing behavior.
		return Hero{}, errors.New("character hero: Hero level exceeds current source-qualified max")
	}
	capExp := thresholds[maxLevel-1].TotalExp
	if h.Exp > capExp {
		return Hero{}, errors.New("character hero: Hero EXP exceeds current source-qualified max")
	}
	// Stored EXP is cumulative. A legacy row below totalExp(level-1) is repaired
	// on its next write so every writer persists the source floor.
	floorExp := int64(0)
	if h.Level > 1 {
		floorExp = thresholds[h.Level-2].TotalExp
	}
	if h.Exp < floorExp {
		h.Exp = floorExp
	}
	nextExp := h.Exp
	if amount > math.MaxInt64-nextExp {
		nextExp = capExp
	} else {
		nextExp += amount
		if nextExp > capExp {
			nextExp = capExp
		}
	}
	nextLevel := h.Level
	// Source loops from current level through max and advances when cumulative
	// EXP reaches totalExp(level); clamp prevents advancing beyond maxLevel.
	for level := h.Level; level <= maxLevel; level++ {
		if nextExp >= thresholds[level-1].TotalExp {
			candidate := level + 1
			if candidate > maxLevel {
				candidate = maxLevel
			}
			if candidate > nextLevel {
				nextLevel = candidate
			}
		}
	}
	h.Exp = nextExp
	h.Level = nextLevel
	h.StateVersion++
	h.UpdatedAt = now.UTC()
	if err := h.ValidatePersistent(); err != nil {
		return Hero{}, err
	}
	return h, nil
}

// SourceCumulativeEXP returns the cumulative EXP the stock client subtracts
// totalExp(level-1) from. A row below that floor is the legacy placeholder
// (level set before the source cumulative curve) and reads as zero progress
// inside its level; no durable state changes.
func (h Hero) SourceCumulativeEXP(thresholds []HeroExpThreshold) (int64, error) {
	if h.Level < 1 || int64(len(thresholds)) < h.Level {
		return 0, errors.New("character hero: invalid cumulative EXP input")
	}
	for i := 0; i < int(h.Level); i++ {
		if thresholds[i].Level != int64(i+1) || thresholds[i].TotalExp < 0 {
			return 0, errors.New("character hero: invalid cumulative EXP thresholds")
		}
	}
	var floor int64
	if h.Level > 1 {
		floor = thresholds[h.Level-2].TotalExp
	}
	return max(h.Exp, floor), nil
}

func (h Hero) EvolveOneStar(now time.Time) (Hero, error) {
	if err := h.ValidatePersistent(); err != nil {
		return Hero{}, err
	}
	if h.Star >= MaxHeroStar || now.IsZero() {
		return Hero{}, errors.New("character hero: cannot evolve")
	}
	h.Star++
	h.StateVersion++
	h.UpdatedAt = now.UTC()
	if err := h.ValidatePersistent(); err != nil {
		return Hero{}, err
	}
	return h, nil
}
