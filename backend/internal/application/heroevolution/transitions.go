package heroevolution

import (
	"context"
	i5 "gxb.local/backend/v2/internal/application/i5"
	evo "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (s Service) apply(ctx context.Context, t tx.Tx, a identity.ActorContext, d Admission) (map[string]any, error) {
	if e := s.requirePlayer(ctx, t, a.PlayerID, d.ContentRevision, d.DecisionAt); e != nil {
		return nil, e
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, t, a.PlayerID, d.Command.PartnerID)
	if e != nil {
		return nil, e
	}
	if h.ValidatePersistent() != nil {
		return nil, evo.ErrUnqualified
	}
	pop, e := s.Heroes.ReadRootTx(ctx, t, a.PlayerID)
	if e != nil {
		return nil, e
	}
	f, e := s.Owner.ReadHeroTx(ctx, t, a.PlayerID, d.Command.PartnerID)
	if e != nil {
		return nil, e
	}
	if d.DecisionAt.Before(h.UpdatedAt) || d.DecisionAt.Before(pop.UpdatedAt) || d.DecisionAt.Before(f.UpdatedAt) {
		return nil, ErrStale
	}
	c, e := s.Content.EvolutionCatalogTx(ctx, t, d.ContentRevision)
	if e != nil {
		return nil, e
	}
	if e = f.Validate(c); e != nil {
		return nil, e
	}
	k, e := s.Content.HeroKindTx(ctx, t, d.ContentRevision, h.TableID)
	if e != nil {
		return nil, e
	}
	template, ok := c.Hero(h.TableID)
	if !ok || string(k) != template.Kind {
		return nil, evo.ErrUnqualified
	}
	var next evo.Facts
	switch d.Command.Family {
	case Allocate:
		next, e = c.Allocate(f.Facts, h.TableID, h.Level, h.Star, d.Command.AttrID, d.Command.Amount, d.Command.CostItem)
	case Advance:
		next, e = c.Advance(f.Facts, h.TableID, h.Level, h.Star)
	default:
		return nil, evo.ErrInvalid
	}
	if e != nil {
		return nil, e
	}
	// The complete known I5 suffix is prepared before any gameplay write.
	var prepared *i5.PreparedMaterialDebit
	if d.Command.Family == Allocate {
		op := d.Operation
		op.StartedAt = d.DecisionAt
		prepared, e = s.Costs.PrepareMaterialDebitTx(ctx, t, a.PlayerID, i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: d.Command.CostItem, Amount: d.Command.Amount}}}, op)
		if e != nil {
			return nil, e
		}
	}
	old := f.Version
	f.Facts = next
	f.Version++
	f.UpdatedAt = d.DecisionAt
	if e = s.Owner.SaveHeroTx(ctx, t, f, old); e != nil {
		return nil, e
	}
	if prepared != nil {
		if _, e = s.Costs.ApplyMaterialDebitTx(ctx, t, prepared); e != nil {
			return nil, e
		}
	}
	return map[string]any{"evo_info": f.Facts.Wire()}, nil
}
