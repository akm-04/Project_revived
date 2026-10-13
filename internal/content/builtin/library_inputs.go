package builtin

import (
	"errors"
	"fmt"
)

type LibraryInputCatalog struct {
	SchemaVersion                      int                            `json:"schema_version"`
	SeedPolicyID                       string                         `json:"seed_policy_id"`
	FeedPolicyID                       string                         `json:"feed_policy_id"`
	OriginalServerProbabilityRecovered bool                           `json:"original_server_probability_recovered"`
	FavorLimit                         int64                          `json:"favor_limit"`
	Templates                          []LibraryTemplateRule          `json:"templates"`
	Gifts                              []LibraryGiftRule              `json:"gifts"`
	Feeding                            LibraryFeedRules               `json:"feeding"`
	NormalCollections                  []LibraryNormalCollectionRule  `json:"normal_collections"`
	SpecialCollections                 []LibrarySpecialCollectionRule `json:"special_collections"`
}

func (c LibraryInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.SeedPolicyID != "LIBRARY_NEUTRAL_SEED_V1" || c.FeedPolicyID != "LIBRARY_FEED_RECONSTRUCTION_V1" || c.OriginalServerProbabilityRecovered || c.FavorLimit != int64(2000) || len(c.Templates) != 568 || len(c.Gifts) != 10 || len(c.NormalCollections) != 132 || len(c.SpecialCollections) != 23 || c.Feeding.Validate() != nil {
		return errLibraryInput
	}
	seen := map[int64]bool{}
	for _, r := range c.Templates {
		if r.TableID <= 0 || r.RelationshipSourceID <= 0 || r.CollectionSourceID <= 0 || seen[r.TableID] {
			return errLibraryInput
		}
		seen[r.TableID] = true
	}
	seen = map[int64]bool{}
	for _, g := range c.Gifts {
		if g.ItemID <= 0 || seen[g.ItemID] || g.Category < 1 || g.Category > 4 || (g.Ring && (g.ItemID != 50001112 || g.BaseFavor != 0)) || (!g.Ring && (g.BaseFavor <= 0 || g.BaseFavor > int64(2000))) {
			return errLibraryInput
		}
		seen[g.ItemID] = true
	}
	seen = map[int64]bool{}
	for _, r := range c.NormalCollections {
		if r.Validate() != nil || seen[r.SourceID] {
			return errLibraryInput
		}
		seen[r.SourceID] = true
	}
	for i, r := range c.SpecialCollections {
		if r.ID != int64(i+1) || r.Type != 1 || len(r.RequiredSourceIDs) == 0 || r.Contribution.AttrID <= 0 || r.Contribution.Hundredths < 0 {
			return fmt.Errorf("library: selected special row %d unqualified", i+1)
		}
	}
	return nil
}

var errLibraryInput = errors.New("library content: unqualified selected payload")

type LibraryTemplateRule struct {
	TableID              int64 `json:"table_id"`
	RelationshipSourceID int64 `json:"relationship_source_id"`
	CollectionSourceID   int64 `json:"collection_source_id"`
	DialogEnabled        bool  `json:"dialog_enabled"`
	GiftLikeType         int64 `json:"gift_like_type"`
	GiftDislikeType      int64 `json:"gift_dislike_type"`
}
type LibraryGiftRule struct {
	ItemID    int64 `json:"item_id"`
	Category  int64 `json:"category"`
	BaseFavor int64 `json:"base_favor"`
	Ring      bool  `json:"ring"`
}
type LibraryFeedAxis struct {
	AttrID   int64    `json:"attr_id"`
	Cap      int64    `json:"cap"`
	Positive [2]int64 `json:"positive"`
	Negative [2]int64 `json:"negative"`
}
type LibraryFeedMethod struct {
	ID                int64    `json:"id"`
	CostType          int64    `json:"cost_type"`
	Cost              int64    `json:"cost"`
	InitialRates      [2]int64 `json:"initial_rates"`
	ChangeStepPercent int64    `json:"change_step_percent"`
	NegativeStepBP    int64    `json:"negative_step_bp"`
}
type LibraryFeedRules struct {
	Axes                 [6]LibraryFeedAxis   `json:"axes"`
	Methods              [3]LibraryFeedMethod `json:"methods"`
	DecreaseBeginPercent int64                `json:"decrease_begin_percent"`
}

func (r LibraryFeedRules) Validate() error {
	if r.DecreaseBeginPercent < 0 || r.DecreaseBeginPercent > 100 {
		return errLibraryInput
	}
	for i, x := range r.Axes {
		// Bound multiplication and span arithmetic before the versioned integer policy.
		if x.AttrID != int64(i+4) || x.Cap <= 0 || x.Cap > 1_000_000_000 || x.Positive[0] <= 0 || x.Positive[1] < x.Positive[0] || x.Positive[1] > x.Cap || x.Negative[0] <= 0 || x.Negative[1] < x.Negative[0] || x.Negative[1] > x.Cap {
			return errLibraryInput
		}
	}
	for i, m := range r.Methods {
		if m.ID != int64(i+1) || m.CostType <= 0 || m.Cost <= 0 || m.InitialRates[0] < 0 || m.InitialRates[1] < 0 || m.InitialRates[0]+m.InitialRates[1] != 100 || m.ChangeStepPercent <= 0 || m.ChangeStepPercent > 100 || m.NegativeStepBP < 0 || m.NegativeStepBP > 10000 {
			return errLibraryInput
		}
	}
	return nil
}
func (r LibraryFeedRules) ValidateApplied(a [6]int64) error {
	if err := r.Validate(); err != nil {
		return err
	}
	for i, v := range a {
		if v < 0 || v > r.Axes[i].Cap {
			return errLibraryInput
		}
	}
	return nil
}

// Hundredths preserves the selected source's exact decimals (including .01).
// It describes raw inputs; final stat aggregation remains its downstream owner.
type LibraryContribution struct {
	AttrID     int64 `json:"attr_id"`
	Hundredths int64 `json:"hundredths"`
}
type LibraryNormalCollectionRule struct {
	SourceID          int64   `json:"source_id"`
	AttrID            int64   `json:"attr_id"`
	QualityThresholds []int64 `json:"quality_thresholds"`
	QualityHundredths []int64 `json:"quality_hundredths"`
	StarThresholds    []int64 `json:"star_thresholds"`
	StarHundredths    []int64 `json:"star_hundredths"`
}
type LibrarySpecialCollectionRule struct {
	ID                int64               `json:"id"`
	Type              int64               `json:"type"`
	RequiredSourceIDs []int64             `json:"required_source_ids"`
	Contribution      LibraryContribution `json:"contribution"`
}

func (r LibraryNormalCollectionRule) Validate() error {
	if r.SourceID <= 0 || r.AttrID <= 0 || len(r.QualityThresholds) == 0 || len(r.QualityThresholds) != len(r.QualityHundredths) || len(r.StarThresholds) != len(r.StarHundredths) {
		return errLibraryInput
	}
	for _, list := range [][]int64{r.QualityThresholds, r.StarThresholds} {
		for i, n := range list {
			if n <= 0 || (i > 0 && n <= list[i-1]) {
				return errLibraryInput
			}
		}
	}
	for _, list := range [][]int64{r.QualityHundredths, r.StarHundredths} {
		for _, n := range list {
			if n < 0 {
				return errLibraryInput
			}
		}
	}
	return nil
}
