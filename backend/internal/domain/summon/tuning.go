package summon

import (
	"errors"
	"fmt"
)

// Tuning is the operator overlay (summon_tuning, written by the I11 operator
// tool): zero or empty fields keep I9_GACHA_PRIVATE_POLICY_V1. Pins replace the
// daily featured calendar while set.
type Tuning struct {
	Version           int64   `json:"version"`
	SmallSuperChance  int64   `json:"small_super_chance_per_10000"`
	MediumSuperChance int64   `json:"medium_super_chance_per_10000"`
	FeaturedChance    int64   `json:"medium_featured_chance_per_10000"`
	FeaturedPity      int64   `json:"medium_featured_pity_slots"`
	ExtensionWeight   int64   `json:"medium_extension_weight"`
	MediumFeatured    []int64 `json:"medium_featured_cohort"`
	MediumExtension   []int64 `json:"medium_extension_cohort"`
	SXCohort          []int64 `json:"sx_cohort"`
	Partner           int64   `json:"partner_id"`
	Pet               int64   `json:"pet_id"`
	// JuicePerPull is a pointer so the operator can set 0 (no juice); nil keeps the source policy.
	JuicePerPull   *int64           `json:"juice_per_pull"`
	Main           []int64          `json:"main_ids"`
	Second         []int64          `json:"second_ids"`
	SXClassWeights map[string]int64 `json:"sx_class_weights"`
	SXHotspotShare int64            `json:"sx_hotspot_share_per_10000"`
	SXHotspotPity  int64            `json:"sx_hotspot_pity"`
}

var errTuning = errors.New("summon: operator tuning")

// maxJuicePerPull bounds the overlay so a typo cannot flood backpacks (a 100-pull Small purchase pays 100 x this).
const maxJuicePerPull = 100

// Tune returns the catalog with t applied; a rejected overlay leaves the source policy in force for the caller to report.
func (c Catalog) Tune(t Tuning) (Catalog, error) {
	for _, chance := range []int64{t.SmallSuperChance, t.MediumSuperChance, t.FeaturedChance, t.SXHotspotShare} {
		if chance < 0 || chance > 10000 {
			return c, errTuning
		}
	}
	if t.FeaturedPity < 0 || t.ExtensionWeight < 0 || t.SXHotspotPity < 0 || (t.JuicePerPull != nil && (*t.JuicePerPull < 0 || *t.JuicePerPull > maxJuicePerPull)) {
		return c, errTuning
	}
	if t.SXClassWeights != nil && validClassWeights(t.SXClassWeights) != nil {
		return c, errTuning
	}
	p := c.Policy
	p.Classic.Small.SuperChance = override(p.Classic.Small.SuperChance, t.SmallSuperChance)
	p.Classic.Medium.SuperChance = override(p.Classic.Medium.SuperChance, t.MediumSuperChance)
	p.Classic.MediumFeatured.Chance = override(p.Classic.MediumFeatured.Chance, t.FeaturedChance)
	p.Classic.MediumFeatured.Pity = override(p.Classic.MediumFeatured.Pity, t.FeaturedPity)
	p.Classic.ExtensionWeight = override(p.Classic.ExtensionWeight, t.ExtensionWeight)
	p.Cohorts.MediumFeatured = overrideIDs(p.Cohorts.MediumFeatured, t.MediumFeatured)
	p.Cohorts.MediumExtension = overrideIDs(p.Cohorts.MediumExtension, t.MediumExtension)
	p.Cohorts.SX = overrideIDs(p.Cohorts.SX, t.SXCohort)
	p.SX.HotspotShare = override(p.SX.HotspotShare, t.SXHotspotShare)
	p.SX.HotspotPity = override(p.SX.HotspotPity, t.SXHotspotPity)
	if t.SXClassWeights != nil {
		p.SX.ClassWeights = t.SXClassWeights
	}
	if t.JuicePerPull != nil {
		p.Juice.PerPull = *t.JuicePerPull
	}
	if err := c.summonable([]int64{t.Partner, t.Pet}, false); err != nil {
		return c, err
	}
	if err := c.summonableStrict(p.Cohorts.MediumFeatured, false); err != nil {
		return c, err
	}
	if err := c.summonableStrict(p.Cohorts.MediumExtension, false); err != nil {
		return c, err
	}
	if err := c.summonableStrict(p.Cohorts.SX, true); err != nil {
		return c, err
	}
	if distinctIDs(p.Cohorts.SX) < 5 || distinctIDs(p.Cohorts.MediumFeatured) < 2 {
		return c, errTuning
	}
	if len(t.Main) > 0 || len(t.Second) > 0 {
		if err := c.summonableStrict(t.Main, true); err != nil {
			return c, err
		}
		if err := c.summonableStrict(t.Second, true); err != nil {
			return c, err
		}
		if distinctIDs(t.Main) != len(t.Main) || distinctIDs(t.Second) != len(t.Second) {
			return c, errTuning
		}
	}
	if (len(t.Main) > 0 || len(t.Second) > 0) && (len(t.Main) != 2 || len(t.Second) != 3) {
		return c, errTuning
	}
	c.Policy, c.tuning = p, t
	return c, nil
}

// summonable accepts the optional Partner/Pet scalars, where zero means "keep the source".
func (c *Catalog) summonable(ids []int64, sx bool) error {
	for _, id := range ids {
		if id == 0 {
			continue
		}
		if err := c.summonableID(id, sx); err != nil {
			return err
		}
	}
	return nil
}

// summonableStrict checks a replacement list: every entry must be a positive,
// summonable ID, so an operator overlay cannot pin zero or unknown heroes.
func (c *Catalog) summonableStrict(ids []int64, sx bool) error {
	for _, id := range ids {
		if id <= 0 {
			return fmt.Errorf("%w: hero %d", errTuning, id)
		}
		if err := c.summonableID(id, sx); err != nil {
			return err
		}
	}
	return nil
}

func (c *Catalog) summonableID(id int64, sx bool) error {
	h, ok := c.heroes[id]
	if _, err := c.Fragments(id); !ok || err != nil || (sx && !h.SX) {
		return fmt.Errorf("%w: hero %d", errTuning, id)
	}
	return nil
}

func distinctIDs(ids []int64) int {
	seen := make(map[int64]struct{}, len(ids))
	for _, id := range ids {
		seen[id] = struct{}{}
	}
	return len(seen)
}

func override(source, tuned int64) int64 {
	if tuned == 0 {
		return source
	}
	return tuned
}

func overrideIDs(source, tuned []int64) []int64 {
	if len(tuned) == 0 {
		return source
	}
	return tuned
}
