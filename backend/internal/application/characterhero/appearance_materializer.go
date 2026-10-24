package characterhero

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// PermanentSkinGrant is the typed Character-owned destination contract exposed
// to future Commerce settlement. Commerce remains owner of product/pricing and
// its semantic receipt; this request contains only Character facts needed to
// materialize one permanent entitlement inside the caller-owned transaction.
type PermanentSkinGrant struct {
	PlayerID        identity.PlayerID
	PartnerID       int64
	ModelID         int64
	ContentRevision string
	DecisionAt      time.Time
}

type PermanentSkinGrantResult struct {
	StateVersion int64
	Mutated      bool
}

// TxPermanentSkinMaterializer is the only CA7-3 permanent-skin write seam a
// future foreign owner should need. Callers own transaction/retry/receipt and
// must invoke this Character lock before later-ranked foreign-owner locks.
type TxPermanentSkinMaterializer interface {
	GrantPermanentSkinTx(context.Context, tx.Tx, PermanentSkinGrant) (PermanentSkinGrantResult, error)
}

type PermanentSkinMaterializer struct {
	Store   HeroAppearanceMutationStore
	Content HeroAppearanceMutationContent
}

func (m PermanentSkinMaterializer) GrantPermanentSkinTx(ctx context.Context, t tx.Tx, req PermanentSkinGrant) (PermanentSkinGrantResult, error) {
	if m.Store == nil || m.Content == nil || t == nil || !req.PlayerID.Valid() || req.PartnerID <= 0 || req.ModelID <= 0 || len(req.ContentRevision) != 64 || req.DecisionAt.IsZero() {
		return PermanentSkinGrantResult{}, errors.New("character hero appearance materializer: invalid permanent-skin grant")
	}
	good, err := m.Content.AppearanceRevisionTx(ctx, t, req.ContentRevision)
	if err != nil {
		return PermanentSkinGrantResult{}, err
	}
	if !good {
		return PermanentSkinGrantResult{}, ErrAppearanceContentInactive
	}
	h, err := m.Store.LockHeroByPartnerIDTx(ctx, t, req.PlayerID, req.PartnerID)
	if err != nil {
		return PermanentSkinGrantResult{}, err
	}
	h, err = resolveAppearanceHero(ctx, t, h, m.Content)
	if err != nil {
		return PermanentSkinGrantResult{}, err
	}
	def, ok, err := m.Content.AppearanceSkinTx(ctx, t, req.ContentRevision, req.ModelID)
	if err != nil {
		return PermanentSkinGrantResult{}, err
	}
	if !ok || def.Validate() != nil || def.HeroOriginTableID != h.OriginTableID {
		return PermanentSkinGrantResult{}, ErrHeroAppearanceUnavailable
	}
	ents, err := m.Store.ListHeroSkinEntitlementsTx(ctx, t, req.PlayerID, req.PartnerID)
	if err != nil {
		return PermanentSkinGrantResult{}, err
	}
	if durable, exists := findSkinEntitlement(ents, req.ModelID); exists && durable.ExpiresAt == nil {
		return PermanentSkinGrantResult{StateVersion: h.StateVersion}, nil
	}
	pre, err := characterasset.BuildEffectiveHeroAppearanceTx(ctx, t, req.ContentRevision, h, ents, nil, req.DecisionAt, m.Content)
	if err != nil {
		return PermanentSkinGrantResult{}, err
	}
	// Materialization is acquisition, not selection: preserve only the effective
	// pre-state so stale expired selectors cannot resurrect through the grant.
	h.CurrentSkinID = pre.CurrentSkinID
	h.IllusionSkinID = pre.IllusionSkinID
	ent := character.HeroSkinEntitlement{PlayerID: req.PlayerID, PartnerID: req.PartnerID, ModelID: req.ModelID}
	old := h.StateVersion
	h.StateVersion++
	h.UpdatedAt = req.DecisionAt.UTC()
	if err := m.Store.SaveHeroAppearanceMutationTx(ctx, t, h, &ent, old); err != nil {
		return PermanentSkinGrantResult{}, err
	}
	return PermanentSkinGrantResult{StateVersion: h.StateVersion, Mutated: true}, nil
}

var _ TxPermanentSkinMaterializer = PermanentSkinMaterializer{}
