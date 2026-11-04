package librarylocal

// TemplateRule keeps the source's distinct identity mappings explicit.
type TemplateRule struct {
	TableID              int64 `json:"table_id"`
	RelationshipSourceID int64 `json:"relationship_source_id"`
	CollectionSourceID   int64 `json:"collection_source_id"`
	DialogEnabled        bool  `json:"dialog_enabled"`
	GiftLikeType         int64 `json:"gift_like_type"`
	GiftDislikeType      int64 `json:"gift_dislike_type"`
	ModelID              int64 `json:"model_id"`
	AwakenTableID        int64 `json:"awaken_table_id"`
	Awaken               int64 `json:"awaken"`
}
type GiftRule struct {
	ItemID       int64 `json:"item_id"`
	Category     int64 `json:"category"`
	BaseFavor    int64 `json:"base_favor"`
	Ring         bool  `json:"ring"`
	PriceCrystal int64 `json:"price_crystal"`
}
type FeedAxis struct {
	AttrID   int64    `json:"attr_id"`
	Cap      int64    `json:"cap"`
	Positive [2]int64 `json:"positive"`
	Negative [2]int64 `json:"negative"`
}
type FeedMethod struct {
	ID                int64    `json:"id"`
	CostType          int64    `json:"cost_type"`
	Cost              int64    `json:"cost"`
	InitialRates      [2]int64 `json:"initial_rates"`
	ChangeStepPercent int64    `json:"change_step_percent"`
	NegativeStepBP    int64    `json:"negative_step_bp"`
}
type FeedRules struct {
	Axes                 [AxisCount]FeedAxis `json:"axes"`
	Methods              [3]FeedMethod       `json:"methods"`
	DecreaseBeginPercent int64               `json:"decrease_begin_percent"`
}

func (r FeedRules) Validate() error {
	if r.DecreaseBeginPercent < 0 || r.DecreaseBeginPercent > 100 {
		return ErrUnqualified
	}
	for i, x := range r.Axes {
		// Bound multiplication and span arithmetic before the versioned integer policy.
		if x.AttrID != int64(i+4) || x.Cap <= 0 || x.Cap > 1_000_000_000 || x.Positive[0] <= 0 || x.Positive[1] < x.Positive[0] || x.Positive[1] > x.Cap || x.Negative[0] <= 0 || x.Negative[1] < x.Negative[0] || x.Negative[1] > x.Cap {
			return ErrUnqualified
		}
	}
	for i, m := range r.Methods {
		if m.ID != int64(i+1) || m.CostType <= 0 || m.Cost <= 0 || m.InitialRates[0] < 0 || m.InitialRates[1] < 0 || m.InitialRates[0]+m.InitialRates[1] != 100 || m.ChangeStepPercent <= 0 || m.ChangeStepPercent > 100 || m.NegativeStepBP < 0 || m.NegativeStepBP > 10000 {
			return ErrUnqualified
		}
	}
	return nil
}
func (r FeedRules) ValidateApplied(a FeedAttrs) error {
	if err := r.Validate(); err != nil {
		return err
	}
	for i, v := range a {
		if v < 0 || v > r.Axes[i].Cap {
			return ErrInvalidFacts
		}
	}
	return nil
}

// Hundredths preserves the selected source's exact decimals (including .01).
// It describes raw inputs; final stat aggregation remains its downstream owner.
type Contribution struct {
	AttrID     int64 `json:"attr_id"`
	Hundredths int64 `json:"hundredths"`
}
type NormalCollectionRule struct {
	SourceID          int64   `json:"source_id"`
	AttrID            int64   `json:"attr_id"`
	QualityThresholds []int64 `json:"quality_thresholds"`
	QualityHundredths []int64 `json:"quality_hundredths"`
	StarThresholds    []int64 `json:"star_thresholds"`
	StarHundredths    []int64 `json:"star_hundredths"`
}
type SpecialCollectionRule struct {
	ID                int64        `json:"id"`
	Type              int64        `json:"type"`
	RequiredSourceIDs []int64      `json:"required_source_ids"`
	Contribution      Contribution `json:"contribution"`
}
type Catalog struct {
	ContentRevision    string
	Templates          map[int64]TemplateRule
	Gifts              map[int64]GiftRule
	Feeding            FeedRules
	NormalCollections  map[int64]NormalCollectionRule
	SpecialCollections [SpecialClaimCount]SpecialCollectionRule
	Stages             []StageRule
	Acts               map[int64]ActRule
	Missions           map[int64]MissionRule
	Talks              map[int64]TalkRule
	CGs                map[int64]CGRule
	Backgrounds        map[int64]BackgroundRule
	DialogConfigs      map[int64]DialogConfigRule
	CourseGiftBoxes    map[int64]CourseGiftBoxRule
}

// StageRule is one favor stage and the act/mission sets it opens.
type StageRule struct {
	ID         int64   `json:"id"`
	Favor      int64   `json:"favor"`
	ActIDs     []int64 `json:"act_ids"`
	MissionIDs []int64 `json:"mission_ids"`
}

func (r StageRule) Validate() error {
	if r.ID <= 0 || r.Favor <= 0 || len(r.ActIDs) == 0 {
		return ErrUnqualified
	}
	for i, id := range r.ActIDs {
		if id < 1 || id > ActCount || (i > 0 && id <= r.ActIDs[i-1]) {
			return ErrUnqualified
		}
	}
	for i, id := range r.MissionIDs {
		if id <= 0 || (i > 0 && id <= r.MissionIDs[i-1]) {
			return ErrUnqualified
		}
	}
	return nil
}

type ActRule struct {
	ID     int64 `json:"id"`
	Dialog int64 `json:"dialog"`
	Amour  int64 `json:"amour"`
}

func (r ActRule) Validate() error {
	if r.ID < 1 || r.ID > ActCount || r.Dialog < 0 || r.Amour < 0 {
		return ErrUnqualified
	}
	return nil
}

type MissionRule struct {
	ID         int64 `json:"id"`
	Difficulty int64 `json:"difficulty"`
	Type       int64 `json:"type"`
	Required   int64 `json:"required"`
	Amour      int64 `json:"amour"`
	OpenLevel  int64 `json:"open_level"`
}

func (r MissionRule) Validate() error {
	if r.ID <= 0 || r.Difficulty < 1 || r.Difficulty > 3 || r.Type < 1 || r.Type > 3 || r.Required <= 0 || r.Amour < 0 || r.OpenLevel < 0 {
		return ErrUnqualified
	}
	return nil
}

type TalkRule struct {
	ID           int64   `json:"id"`
	UnlockTypes  []int64 `json:"unlock_types"`
	UnlockHeroes []int64 `json:"unlock_heroes"`
	UnlockParams []int64 `json:"unlock_params"`
	ItemID       int64   `json:"item_id"`
	ItemNum      int64   `json:"item_num"`
	Gold         int64   `json:"gold"`
	Diamond      int64   `json:"diamond"`
}

func (r TalkRule) Validate() error {
	if r.ID <= 0 || len(r.UnlockTypes) != len(r.UnlockHeroes) || len(r.UnlockTypes) != len(r.UnlockParams) || r.ItemID < 0 || r.ItemNum < 0 || r.Gold < 0 || r.Diamond < 0 {
		return ErrUnqualified
	}
	if r.ItemID > 0 && r.ItemNum <= 0 {
		return ErrUnqualified
	}
	return nil
}

type CGRule struct {
	ID          int64   `json:"id"`
	UnlockIDs   []int64 `json:"unlock_ids"`
	UnlockTypes []int64 `json:"unlock_types"`
	ItemID      int64   `json:"item_id"`
	Num         int64   `json:"num"`
}

func (r CGRule) Validate() error {
	if r.ID <= 0 || len(r.UnlockIDs) != len(r.UnlockTypes) || r.ItemID <= 0 || r.Num <= 0 {
		return ErrUnqualified
	}
	return nil
}

type BackgroundRule struct {
	ID    int64 `json:"id"`
	Limit int64 `json:"limit"`
}

func (r BackgroundRule) Validate() error {
	if r.ID <= 0 || (r.Limit != 0 && r.Limit != 1) {
		return ErrUnqualified
	}
	return nil
}

type DialogConfigRule struct {
	ID            int64 `json:"id"`
	Type          int64 `json:"type"`
	OpenCondition int64 `json:"open_condition"`
	AmourReward   int64 `json:"amour_reward"`
	GiftReward    int64 `json:"gift_reward"`
}

func (r DialogConfigRule) Validate() error {
	if r.ID <= 0 || r.Type < 1 || r.Type > 7 || r.OpenCondition < 0 || r.AmourReward < 0 || r.GiftReward < 0 {
		return ErrUnqualified
	}
	return nil
}

// CourseDropRoll is one row of a course gift box dropbox, rates in ten-thousandths.
type CourseDropRoll struct {
	ID      int64 `json:"id"`
	ItemID  int64 `json:"item_id"`
	ItemNum int64 `json:"item_num"`
	Rate    int64 `json:"rate"`
}

type CourseGiftBoxRule struct {
	ItemID    int64            `json:"item_id"`
	DropboxID int64            `json:"dropbox_id"`
	Rolls     []CourseDropRoll `json:"rolls"`
}

func (r CourseGiftBoxRule) Validate() error {
	if r.ItemID <= 0 || r.DropboxID <= 0 || len(r.Rolls) == 0 {
		return ErrUnqualified
	}
	total, seen := int64(0), map[int64]bool{}
	for _, roll := range r.Rolls {
		if roll.ID <= 0 || roll.ItemID <= 0 || roll.ItemNum <= 0 || roll.Rate < 0 || roll.Rate > 10000 || seen[roll.ItemID] {
			return ErrUnqualified
		}
		seen[roll.ItemID] = true
		total += roll.Rate
	}
	if total != 10000 {
		return ErrUnqualified
	}
	return nil
}

// Validate checks the fan-out rules that the 836 shape depends on.
func (c Catalog) Validate() error {
	for _, r := range c.Stages {
		if r.Validate() != nil {
			return ErrUnqualified
		}
	}
	if len(c.Acts) != ActCount {
		return ErrUnqualified
	}
	for id := int64(1); id <= ActCount; id++ {
		r, ok := c.Acts[id]
		if !ok || r.ID != id || r.Validate() != nil {
			return ErrUnqualified
		}
	}
	for _, r := range c.Missions {
		if r.Validate() != nil {
			return ErrUnqualified
		}
	}
	for _, r := range c.Talks {
		if r.Validate() != nil {
			return ErrUnqualified
		}
	}
	for _, r := range c.CGs {
		if r.Validate() != nil {
			return ErrUnqualified
		}
	}
	for _, r := range c.Backgrounds {
		if r.Validate() != nil {
			return ErrUnqualified
		}
	}
	for _, r := range c.DialogConfigs {
		if r.Validate() != nil {
			return ErrUnqualified
		}
	}
	for _, r := range c.CourseGiftBoxes {
		if r.Validate() != nil {
			return ErrUnqualified
		}
	}
	return nil
}

func (r NormalCollectionRule) Validate() error {
	if r.SourceID <= 0 || r.AttrID <= 0 || len(r.QualityThresholds) == 0 || len(r.QualityThresholds) != len(r.QualityHundredths) || len(r.StarThresholds) != len(r.StarHundredths) {
		return ErrUnqualified
	}
	for _, list := range [][]int64{r.QualityThresholds, r.StarThresholds} {
		for i, n := range list {
			if n <= 0 || (i > 0 && n <= list[i-1]) {
				return ErrUnqualified
			}
		}
	}
	for _, list := range [][]int64{r.QualityHundredths, r.StarHundredths} {
		for _, n := range list {
			if n < 0 {
				return ErrUnqualified
			}
		}
	}
	return nil
}
