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
	Stages                             []LibraryStageRule             `json:"stages"`
	Acts                               []LibraryActRule               `json:"acts"`
	Missions                           []LibraryMissionRule           `json:"missions"`
	Talks                              []LibraryTalkRule              `json:"talks"`
	CGs                                []LibraryCGRule                `json:"cgs"`
	Backgrounds                        []LibraryBackgroundRule        `json:"backgrounds"`
	DialogConfigs                      []LibraryDialogConfigRule      `json:"dialog_configs"`
	CourseGiftBoxes                    []LibraryCourseGiftBoxRule     `json:"course_gift_boxes"`
}

func (c LibraryInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.SeedPolicyID != "LIBRARY_NEUTRAL_SEED_V1" || c.FeedPolicyID != "LIBRARY_FEED_RECONSTRUCTION_V1" || c.OriginalServerProbabilityRecovered || c.FavorLimit != int64(2000) || len(c.Templates) != 568 || len(c.Gifts) != 10 || len(c.NormalCollections) != 132 || len(c.SpecialCollections) != 23 || len(c.Stages) != 5 || len(c.Acts) != 4 || len(c.Missions) != 6 || len(c.Talks) != 23 || len(c.CGs) != 21 || len(c.Backgrounds) != 12 || len(c.DialogConfigs) != 19 || len(c.CourseGiftBoxes) != 2 || c.Feeding.Validate() != nil {
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
		if g.ItemID <= 0 || seen[g.ItemID] || g.Category < 1 || g.Category > 4 || g.PriceCrystal <= 0 || (g.Ring && (g.ItemID != 50001112 || g.BaseFavor != 0)) || (!g.Ring && (g.BaseFavor <= 0 || g.BaseFavor > int64(2000))) {
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
	for i, r := range c.Stages {
		if r.ID != int64(i+1) || r.Validate() != nil || (i > 0 && r.Favor <= c.Stages[i-1].Favor) {
			return fmt.Errorf("library: stage row %d unqualified", i+1)
		}
	}
	for i, r := range c.Acts {
		if r.ID != int64(i+1) || r.Validate() != nil {
			return fmt.Errorf("library: act row %d unqualified", i+1)
		}
	}
	for i, r := range c.Missions {
		if r.ID != 1001+int64(i) || r.Validate() != nil {
			return fmt.Errorf("library: mission row %d unqualified", i+1)
		}
	}
	seen = map[int64]bool{}
	for _, r := range c.Talks {
		if r.Validate() != nil || seen[r.ID] {
			return fmt.Errorf("library: talk row %d unqualified", r.ID)
		}
		seen[r.ID] = true
	}
	for i, r := range c.CGs {
		if r.ID != int64(i+1) || r.Validate() != nil {
			return fmt.Errorf("library: cg row %d unqualified", i+1)
		}
	}
	for i, r := range c.Backgrounds {
		if r.ID != int64(i+1) || r.Validate() != nil {
			return fmt.Errorf("library: background row %d unqualified", i+1)
		}
	}
	for i, r := range c.DialogConfigs {
		if r.ID != int64(i+1) || r.Validate() != nil {
			return fmt.Errorf("library: dialog config row %d unqualified", i+1)
		}
	}
	for _, r := range c.CourseGiftBoxes {
		if r.Validate() != nil {
			return fmt.Errorf("library: course gift box %d unqualified", r.ItemID)
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
	ItemID       int64 `json:"item_id"`
	Category     int64 `json:"category"`
	BaseFavor    int64 `json:"base_favor"`
	Ring         bool  `json:"ring"`
	PriceCrystal int64 `json:"price_crystal"`
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

type LibraryStageRule struct {
	ID         int64   `json:"id"`
	Favor      int64   `json:"favor"`
	ActIDs     []int64 `json:"act_ids"`
	MissionIDs []int64 `json:"mission_ids"`
}

func (r LibraryStageRule) Validate() error {
	if r.ID <= 0 || r.Favor <= 0 || len(r.ActIDs) == 0 {
		return errLibraryInput
	}
	for i, id := range r.ActIDs {
		if id < 1 || id > 4 || (i > 0 && id <= r.ActIDs[i-1]) {
			return errLibraryInput
		}
	}
	for i, id := range r.MissionIDs {
		if id <= 0 || (i > 0 && id <= r.MissionIDs[i-1]) {
			return errLibraryInput
		}
	}
	return nil
}

type LibraryActRule struct {
	ID     int64 `json:"id"`
	Dialog int64 `json:"dialog"`
	Amour  int64 `json:"amour"`
}

func (r LibraryActRule) Validate() error {
	if r.ID < 1 || r.ID > 4 || r.Dialog < 0 || r.Amour < 0 {
		return errLibraryInput
	}
	return nil
}

type LibraryMissionRule struct {
	ID         int64 `json:"id"`
	Difficulty int64 `json:"difficulty"`
	Type       int64 `json:"type"`
	Required   int64 `json:"required"`
	Amour      int64 `json:"amour"`
	OpenLevel  int64 `json:"open_level"`
}

func (r LibraryMissionRule) Validate() error {
	if r.ID <= 0 || r.Difficulty < 1 || r.Difficulty > 3 || r.Type < 1 || r.Type > 3 || r.Required <= 0 || r.Amour < 0 || r.OpenLevel < 0 {
		return errLibraryInput
	}
	return nil
}

type LibraryTalkRule struct {
	ID           int64   `json:"id"`
	UnlockTypes  []int64 `json:"unlock_types"`
	UnlockHeroes []int64 `json:"unlock_heroes"`
	UnlockParams []int64 `json:"unlock_params"`
	ItemID       int64   `json:"item_id"`
	ItemNum      int64   `json:"item_num"`
	Gold         int64   `json:"gold"`
	Diamond      int64   `json:"diamond"`
}

func (r LibraryTalkRule) Validate() error {
	if r.ID <= 0 || len(r.UnlockTypes) != len(r.UnlockHeroes) || len(r.UnlockTypes) != len(r.UnlockParams) || r.ItemID < 0 || r.ItemNum < 0 || r.Gold < 0 || r.Diamond < 0 {
		return errLibraryInput
	}
	if r.ItemID > 0 && r.ItemNum <= 0 {
		return errLibraryInput
	}
	return nil
}

type LibraryCGRule struct {
	ID          int64   `json:"id"`
	UnlockIDs   []int64 `json:"unlock_ids"`
	UnlockTypes []int64 `json:"unlock_types"`
	ItemID      int64   `json:"item_id"`
	Num         int64   `json:"num"`
}

func (r LibraryCGRule) Validate() error {
	if r.ID <= 0 || len(r.UnlockIDs) != len(r.UnlockTypes) || r.ItemID <= 0 || r.Num <= 0 {
		return errLibraryInput
	}
	return nil
}

type LibraryBackgroundRule struct {
	ID    int64 `json:"id"`
	Limit int64 `json:"limit"`
}

func (r LibraryBackgroundRule) Validate() error {
	if r.ID <= 0 || (r.Limit != 0 && r.Limit != 1) {
		return errLibraryInput
	}
	return nil
}

type LibraryDialogConfigRule struct {
	ID            int64 `json:"id"`
	Type          int64 `json:"type"`
	OpenCondition int64 `json:"open_condition"`
	AmourReward   int64 `json:"amour_reward"`
	GiftReward    int64 `json:"gift_reward"`
}

func (r LibraryDialogConfigRule) Validate() error {
	if r.ID <= 0 || r.Type < 1 || r.Type > 7 || r.OpenCondition < 0 || r.AmourReward < 0 || r.GiftReward < 0 {
		return errLibraryInput
	}
	return nil
}

type LibraryCourseDropRoll struct {
	ID      int64 `json:"id"`
	ItemID  int64 `json:"item_id"`
	ItemNum int64 `json:"item_num"`
	Rate    int64 `json:"rate"`
}

type LibraryCourseGiftBoxRule struct {
	ItemID    int64                   `json:"item_id"`
	DropboxID int64                   `json:"dropbox_id"`
	Rolls     []LibraryCourseDropRoll `json:"rolls"`
}

func (r LibraryCourseGiftBoxRule) Validate() error {
	if r.ItemID <= 0 || r.DropboxID <= 0 || len(r.Rolls) == 0 {
		return errLibraryInput
	}
	total, seen := int64(0), map[int64]bool{}
	for _, roll := range r.Rolls {
		if roll.ID <= 0 || roll.ItemID <= 0 || roll.ItemNum <= 0 || roll.Rate < 0 || roll.Rate > 10000 || seen[roll.ItemID] {
			return errLibraryInput
		}
		seen[roll.ItemID] = true
		total += roll.Rate
	}
	if total != 10000 {
		return errLibraryInput
	}
	return nil
}
