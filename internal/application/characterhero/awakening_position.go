package characterhero

import (
	"context"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type rawAwakeningFacetReader interface {
	FindRawAwakeningTx(context.Context, tx.Queryer, character.HeroRef) (character.RawAwakeningBirth, bool, error)
}

// AwakeningPositionResolver mirrors NormalHero.getEquipList's raw-stage substitution.
type AwakeningPositionResolver struct {
	Raw     rawAwakeningFacetReader
	Content i5.AwakeningContent
	Queryer tx.Queryer
}

func (r *AwakeningPositionResolver) ResolveTx(ctx context.Context, q tx.Queryer, h character.Hero, revision string, pos character.HeroEquipmentPosition) (character.HeroEquipmentPosition, error) {
	if r == nil || pos.OrdinaryEligible || !pos.ItemID.Valid() {
		return pos, nil
	}
	if q == nil || r.Raw == nil || r.Content == nil {
		return pos, character.ErrRawAwakeningUnavailable
	}
	f, found, e := r.Raw.FindRawAwakeningTx(ctx, q, h.Ref())
	if e != nil {
		return pos, e
	}
	if !found {
		return pos, nil
	}
	if f.Validate() != nil || f.CreationContentRevision != h.CreationContentRevision || !f.BirthAt.Equal(h.CreatedAt) || f.UpdatedAt.After(h.UpdatedAt) {
		return pos, character.ErrRawAwakeningUnavailable
	}
	if f.RawStage <= 1 {
		return pos, nil
	}
	c, e := r.Content.AwakeningCatalogTx(ctx, q, revision)
	if e != nil {
		return pos, e
	}
	for _, d := range c.Definitions {
		if d.Type == 2 && d.Stage == 1 && d.Before == h.TableID {
			pos.ItemID = character.EquipmentTemplateID(d.Item)
			return pos, nil
		}
	}
	return pos, character.ErrRawAwakeningUnavailable
}
