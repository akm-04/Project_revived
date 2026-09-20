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

type HeroAppearanceContributionStore interface {
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
	ListHeroSkinEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroSkinEntitlement, error)
	ListHeroLIVEEntitlementsTx(context.Context, tx.Queryer, identity.PlayerID, int64) ([]character.HeroLIVEEntitlement, error)
}

type HeroAppearanceContributionContent interface {
	AppearanceRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
	characterasset.AppearanceTxContent
}

type AppearanceContributionReader struct {
	Store   HeroAppearanceContributionStore
	Content HeroAppearanceContributionContent
}

func (r AppearanceContributionReader) HeroAppearanceContributionTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64, revision string, observedAt time.Time) (characterasset.HeroAppearanceContribution, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || partnerID <= 0 || observedAt.IsZero() || characterasset.ValidateExactRevisionID(revision) != nil {
		return characterasset.HeroAppearanceContribution{}, errors.New("character hero: invalid appearance contribution read")
	}
	good, err := r.Content.AppearanceRevisionTx(ctx, q, revision)
	if err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	if !good {
		return characterasset.HeroAppearanceContribution{}, ErrAppearanceContentInactive
	}
	h, err := r.Store.ReadHeroByPartnerIDTx(ctx, q, pid, partnerID)
	if err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	if h.PlayerID != pid || h.PartnerID != partnerID {
		return characterasset.HeroAppearanceContribution{}, errors.New("character hero: appearance contribution owner mismatch")
	}
	if err := h.ValidatePersistent(); err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	kind, err := r.Content.HeroKindTx(ctx, q, h.CreationContentRevision, h.TableID)
	if err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	h.Kind = kind
	if err := h.Validate(); err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	skins, err := r.Store.ListHeroSkinEntitlementsTx(ctx, q, pid, partnerID)
	if err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	lives, err := r.Store.ListHeroLIVEEntitlementsTx(ctx, q, pid, partnerID)
	if err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	appearance, err := characterasset.BuildEffectiveHeroAppearanceTx(ctx, q, revision, h, skins, lives, observedAt, r.Content)
	if err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	out := characterasset.HeroAppearanceContribution{
		OwnerID: h.PartnerID, TableID: h.TableID, OriginTableID: h.OriginTableID,
		ContentRevision: revision, Appearance: appearance,
	}
	if err := out.Validate(); err != nil {
		return characterasset.HeroAppearanceContribution{}, err
	}
	return out, nil
}

var _ characterasset.HeroAppearanceContributionProvider = AppearanceContributionReader{}
