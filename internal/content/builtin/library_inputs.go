package builtin

import (
	"fmt"
	library "gxb.local/backend/v2/internal/domain/librarylocal"
)

type LibraryInputCatalog struct {
	SchemaVersion                      int                             `json:"schema_version"`
	SeedPolicyID                       string                          `json:"seed_policy_id"`
	FeedPolicyID                       string                          `json:"feed_policy_id"`
	OriginalServerProbabilityRecovered bool                            `json:"original_server_probability_recovered"`
	FavorLimit                         int64                           `json:"favor_limit"`
	Templates                          []library.TemplateRule          `json:"templates"`
	Gifts                              []library.GiftRule              `json:"gifts"`
	Feeding                            library.FeedRules               `json:"feeding"`
	NormalCollections                  []library.NormalCollectionRule  `json:"normal_collections"`
	SpecialCollections                 []library.SpecialCollectionRule `json:"special_collections"`
}

func (c LibraryInputCatalog) Validate() error {
	if c.SchemaVersion != 1 || c.SeedPolicyID != library.SeedPolicyV1 || c.FeedPolicyID != library.FeedPolicyV1 || c.OriginalServerProbabilityRecovered || c.FavorLimit != library.FavorLimit || len(c.Templates) != 568 || len(c.Gifts) != 10 || len(c.NormalCollections) != 132 || len(c.SpecialCollections) != library.SpecialClaimCount || c.Feeding.Validate() != nil {
		return library.ErrUnqualified
	}
	seen := map[int64]bool{}
	for _, r := range c.Templates {
		if r.TableID <= 0 || r.RelationshipSourceID <= 0 || r.CollectionSourceID <= 0 || seen[r.TableID] {
			return library.ErrUnqualified
		}
		seen[r.TableID] = true
	}
	seen = map[int64]bool{}
	for _, g := range c.Gifts {
		if g.ItemID <= 0 || seen[g.ItemID] || g.Category < 1 || g.Category > 4 || (g.Ring && (g.ItemID != 50001112 || g.BaseFavor != 0)) || (!g.Ring && (g.BaseFavor <= 0 || g.BaseFavor > library.FavorLimit)) {
			return library.ErrUnqualified
		}
		seen[g.ItemID] = true
	}
	seen = map[int64]bool{}
	for _, r := range c.NormalCollections {
		if r.Validate() != nil || seen[r.SourceID] {
			return library.ErrUnqualified
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
func (c LibraryInputCatalog) Domain(revision string) (library.Catalog, error) {
	var out library.Catalog
	if !library.ValidRevision(revision) || c.Validate() != nil {
		return out, library.ErrUnqualified
	}
	out = library.Catalog{ContentRevision: revision, Templates: map[int64]library.TemplateRule{}, Gifts: map[int64]library.GiftRule{}, Feeding: c.Feeding, NormalCollections: map[int64]library.NormalCollectionRule{}}
	for _, r := range c.Templates {
		out.Templates[r.TableID] = r
	}
	for _, r := range c.Gifts {
		out.Gifts[r.ItemID] = r
	}
	for _, r := range c.NormalCollections {
		r.QualityThresholds = append([]int64(nil), r.QualityThresholds...)
		r.QualityHundredths = append([]int64(nil), r.QualityHundredths...)
		r.StarThresholds = append([]int64(nil), r.StarThresholds...)
		r.StarHundredths = append([]int64(nil), r.StarHundredths...)
		out.NormalCollections[r.SourceID] = r
	}
	for i, r := range c.SpecialCollections {
		r.RequiredSourceIDs = append([]int64(nil), r.RequiredSourceIDs...)
		out.SpecialCollections[i] = r
	}
	return out, nil
}
