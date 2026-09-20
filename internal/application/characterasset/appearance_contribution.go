package characterasset

import (
	"context"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// ValidateExactRevisionID rejects anything other than the canonical lowercase
// 64-hex revision form used by immutable content snapshots.
func ValidateExactRevisionID(revision string) error {
	if !validRevisionID(revision) {
		return errors.New("character asset: invalid exact content revision")
	}
	return nil
}

// HeroAppearanceContribution is the self-describing, immutable CA7 appearance
// observation handed to later snapshot orchestration. Identity fields are
// provenance/validation only; CA2/CA3 remain roster authority.
type HeroAppearanceContribution struct {
	OwnerID         int64
	TableID         int64
	OriginTableID   int64
	ContentRevision string
	Appearance      EffectiveHeroAppearance
}

func (c HeroAppearanceContribution) Validate() error {
	if c.OwnerID <= 0 || c.TableID <= 0 || c.OriginTableID <= 0 || ValidateExactRevisionID(c.ContentRevision) != nil || c.Appearance.Validate() != nil {
		return errors.New("character asset: invalid Hero appearance contribution")
	}
	return nil
}

// PetAppearanceContribution is the Pet-owner counterpart of
// HeroAppearanceContribution. It carries no write authority or battle policy.
type PetAppearanceContribution struct {
	OwnerID         int64
	TableID         int64
	OriginTableID   int64
	ContentRevision string
	Appearance      EffectivePetAppearance
}

func (c PetAppearanceContribution) Validate() error {
	if c.OwnerID <= 0 || c.TableID <= 0 || c.OriginTableID <= 0 || ValidateExactRevisionID(c.ContentRevision) != nil || c.Appearance.Validate() != nil {
		return errors.New("character asset: invalid Pet appearance contribution")
	}
	return nil
}

// These read-only provider interfaces intentionally require the caller's
// Queryer, exact immutable content revision and stable observation instant.
// They must not rediscover ActiveRevision or open a nested transaction.
type HeroAppearanceContributionProvider interface {
	HeroAppearanceContributionTx(context.Context, tx.Queryer, identity.PlayerID, int64, string, time.Time) (HeroAppearanceContribution, error)
}

type PetAppearanceContributionProvider interface {
	PetAppearanceContributionTx(context.Context, tx.Queryer, identity.PlayerID, int64, string, time.Time) (PetAppearanceContribution, error)
}
