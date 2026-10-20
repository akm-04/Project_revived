package playerdisplay

import (
	"context"
	"sort"

	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// SkinCollectionPolicy (1003) and CosmeticCountPolicy (1005/1006) are private
// I7C-4 full stage C dedup rules over the caller's coherent observation.
const SkinCollectionPolicy = "C4F_SKIN_COLLECTION_V1"
const CosmeticCountPolicy = "C4F_COSMETIC_COUNT_V1"

type SkinItems interface {
	AppearanceSkinItemTx(context.Context, tx.Queryer, string, int64) (ca.AppearanceSkinItemDefinition, bool, error)
}

// CosmeticCount is versioned by the Character root the observation read.
type CosmeticCount struct {
	Policy           string
	Value            int64
	SourceVersion    int64
	PopulationDigest string
}

// SkinCollectionTx counts distinct skin models from unexpired entitlements and
// held I5 skin items (SelfPlayer.hasSkin).
func (s Service) SkinCollectionTx(c context.Context, sc ca.CoherentReadScope, pid identity.PlayerID) (CosmeticCount, error) {
	if s.SkinItems == nil {
		return CosmeticCount{}, ErrUnavailable
	}
	o, e := s.ReadEligibilityTx(c, sc, EligibilityRequest{PlayerID: pid, Family: "avatar"})
	if e != nil {
		return CosmeticCount{}, e
	}
	models := map[int64]bool{}
	for _, h := range o.Character.Heroes {
		for _, model := range h.Skins {
			models[model] = true
		}
	}
	// shortcut: one content lookup per held stack, upgrade to a batched item read if inventories grow past a few hundred stacks.
	for _, stack := range o.Inventory.Stacks {
		if stack.Quantity == 0 {
			continue
		}
		skin, ok, e := s.SkinItems.AppearanceSkinItemTx(c, sc.Queryer(), sc.ContentRevision, stack.ItemID)
		if e != nil {
			return CosmeticCount{}, e
		}
		if !ok {
			continue
		}
		if skin.Validate() != nil || skin.ItemID != stack.ItemID {
			return CosmeticCount{}, ErrConflict
		}
		models[skin.ModelID] = true
	}
	held := make([]int64, 0, len(models))
	for model := range models {
		held = append(held, model)
	}
	sort.Slice(held, func(i, j int) bool { return held[i] < held[j] })
	return CosmeticCount{Policy: SkinCollectionPolicy, Value: int64(len(held)), SourceVersion: o.Character.RootVersion, PopulationDigest: PopulationDigest(held)}, nil
}

// CosmeticCountTx counts ELIGIBLE frame rows, or ELIGIBLE (avatar, category)
// rows, over a complete family; an incomplete family is never read as zero.
func (s Service) CosmeticCountTx(c context.Context, sc ca.CoherentReadScope, pid identity.PlayerID, family string) (CosmeticCount, error) {
	if family != "frame" && family != "avatar" {
		return CosmeticCount{}, ErrRequest
	}
	o, e := s.ReadEligibilityTx(c, sc, EligibilityRequest{PlayerID: pid, Family: family, CompleteFamily: true})
	if e != nil {
		return CosmeticCount{}, e
	}
	eligible := []EligibilityFact{}
	for _, f := range o.Facts {
		if f.Status == Eligible {
			eligible = append(eligible, EligibilityFact{Family: f.Family, CatalogID: f.CatalogID, Category: f.Category})
		}
	}
	return CosmeticCount{Policy: CosmeticCountPolicy, Value: int64(len(eligible)), SourceVersion: o.Character.RootVersion, PopulationDigest: PopulationDigest(eligible)}, nil
}
