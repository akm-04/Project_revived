package librarylocal

// TemplateRule keeps the source's distinct identity mappings explicit.
type TemplateRule struct {
	TableID              int64 `json:"table_id"`
	RelationshipSourceID int64 `json:"relationship_source_id"`
	CollectionSourceID   int64 `json:"collection_source_id"`
	DialogEnabled        bool  `json:"dialog_enabled"`
	GiftLikeType         int64 `json:"gift_like_type"`
	GiftDislikeType      int64 `json:"gift_dislike_type"`
}
type GiftRule struct {
	ItemID    int64 `json:"item_id"`
	Category  int64 `json:"category"`
	BaseFavor int64 `json:"base_favor"`
	Ring      bool  `json:"ring"`
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
