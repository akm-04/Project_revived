package heroevolution

import (
	"context"
	evo "gxb.local/backend/v2/internal/domain/heroevolution"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// Source HeroMainWindow gates the panel by Player.lev >= first-stage level,
// separately from Hero per-stage level/star. The canonical I5 policy is reused.
func (s Service) requirePlayer(ctx context.Context, q tx.Queryer, p identity.PlayerID, rev string, at time.Time) error {
	if s.Values == nil {
		return ErrUnavailable
	}
	v, e := s.Values.ReadProgressionTx(ctx, q, p)
	if e != nil {
		return e
	}
	if v.PlayerID != p || v.Validate() != nil {
		return evo.ErrUnqualified
	}
	rule, e := s.Content.ResolveProgressionPolicyTx(ctx, q, rev)
	if e != nil {
		return e
	}
	if rule.Validate() != nil || rule.ValidateState(v) != nil {
		return evo.ErrUnqualified
	}
	if at.Before(v.UpdatedAt) {
		return ErrStale
	}
	c, e := s.Content.EvolutionCatalogTx(ctx, q, rev)
	if e != nil {
		return e
	}
	first, ok := c.Stage(1)
	if !ok {
		return evo.ErrUnqualified
	}
	if v.Level < first.Level {
		return evo.ErrInvalid
	}
	return nil
}
