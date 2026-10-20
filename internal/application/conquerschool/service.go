package conquerschool

import (
	"context"
	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/playerroot"
	"gxb.local/backend/v2/internal/domain/character"
	d "gxb.local/backend/v2/internal/domain/conquerschool"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strings"
	"time"
)

type OwnerPort interface {
	ReadFactsTx(context.Context, tx.Queryer, identity.PlayerID) (d.Facts, error)
	LockFactsTx(context.Context, tx.Tx, identity.PlayerID) (d.Facts, error)
	SaveFactsTx(context.Context, tx.Tx, d.Facts, int64, d.Catalog) error
}
type ContentPort interface {
	ConquerCatalogTx(context.Context, tx.Queryer, string) (d.Catalog, error)
}
type HeroPort interface {
	ReadRootTx(context.Context, tx.Queryer, identity.PlayerID) (character.HeroRoot, error)
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
}
type KindPort interface {
	HeroKindTx(context.Context, tx.Queryer, string, int64) (character.HeroKind, error)
}
type Service struct {
	Owner   OwnerPort
	Content ContentPort
	Heroes  HeroPort
	Kinds   KindPort
	Players playerroot.TxLocker
}
type Observation struct {
	Facts           d.Facts
	ContentRevision string
	ObservedAt      time.Time
	Contributions   map[int64]int64
	RunAvailable    bool
	RunComplete     bool
}

func (s Service) FactsTx(ctx context.Context, scope characterasset.CoherentReadScope, p identity.PlayerID) (Observation, error) {
	var out Observation
	if scope.Validate() != nil || !p.Valid() || s.Owner == nil || s.Content == nil {
		return out, d.ErrUnqualified
	}
	pin, ok := scope.Operation.Policies.Get("content")
	if !ok || pin != scope.ContentRevision {
		return out, d.ErrUnqualified
	}
	f, e := s.Owner.ReadFactsTx(ctx, scope.Queryer(), p)
	if e != nil {
		return out, e
	}
	// I7C-5E amendment: a row written under an earlier revision is validated
	// against the pinned catalog; its revision is provenance.
	if f.Player != p {
		return out, d.ErrUnqualified
	}
	c, e := s.Content.ConquerCatalogTx(ctx, scope.Queryer(), pin)
	if e != nil {
		return out, e
	}
	if e = f.Validate(c); e != nil {
		return out, e
	}
	if scope.ObservedAt.Before(f.UpdatedAt) {
		return out, d.ErrStale
	}
	if !f.Known() {
		return out, d.ErrUnavailable
	}
	v, e := c.Evaluate(*f.Payload.Progress)
	if e != nil {
		return out, e
	}
	out = Observation{Facts: f, ContentRevision: pin, ObservedAt: scope.ObservedAt, Contributions: v}
	out.Facts.Payload = f.Payload.Clone()
	if f.Payload.Run != nil {
		out.RunAvailable = true
		out.RunComplete, e = c.Complete(*f.Payload.Run)
	}
	return out, e
}

type HeroInputs struct {
	Hero              character.Hero
	PopulationVersion int64
	Observation       Observation
}

func (s Service) HeroInputsTx(ctx context.Context, scope characterasset.CoherentReadScope, ref character.HeroRef) (HeroInputs, error) {
	var out HeroInputs
	if scope.Validate() != nil || ref.Validate() != nil || s.Heroes == nil || s.Kinds == nil {
		return out, d.ErrUnqualified
	}
	q := scope.Queryer()
	root, e := s.Heroes.ReadRootTx(ctx, q, ref.PlayerID)
	if e != nil {
		return out, e
	}
	h, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, q, ref.PlayerID, ref.PartnerID)
	if e != nil {
		return out, e
	}
	if root.PlayerID != ref.PlayerID || h.PlayerID != ref.PlayerID || h.PartnerID != ref.PartnerID || h.ValidatePersistent() != nil {
		return out, d.ErrUnqualified
	}
	if scope.ObservedAt.Before(root.UpdatedAt) || scope.ObservedAt.Before(h.UpdatedAt) {
		return out, d.ErrStale
	}
	h.Kind, e = s.Kinds.HeroKindTx(ctx, q, scope.ContentRevision, h.TableID)
	if e != nil || h.Validate() != nil {
		if e == nil {
			e = d.ErrUnqualified
		}
		return out, e
	}
	v, e := s.FactsTx(ctx, scope, ref.PlayerID)
	if e != nil {
		return out, e
	}
	return HeroInputs{Hero: h, PopulationVersion: root.StateVersion, Observation: v}, nil
}

// PreparedWrite is the caller-Tx writer seam; the I7C-5E Mode service is its
// only production writer and qualifies attempt, receipt and value effects.
type PreparedWrite struct {
	before  d.Facts
	catalog d.Catalog
	op      operation.Context
}

func (s Service) PrepareWriteTx(ctx context.Context, t tx.Tx, server identity.LogicalServerID, p identity.PlayerID, rev string, op operation.Context) (*PreparedWrite, error) {
	if t == nil || s.Players == nil || s.Owner == nil || s.Content == nil || op.ID.IsZero() || op.StartedAt.IsZero() {
		return nil, d.ErrUnqualified
	}
	pin, ok := op.Policies.Get("content")
	if !ok || pin != rev {
		return nil, d.ErrUnqualified
	}
	roots, e := s.Players.LockPlayerRootsTx(ctx, t, server, []identity.PlayerID{p})
	if e != nil {
		return nil, e
	}
	if len(roots) != 1 || roots[0].PlayerID != p {
		return nil, d.ErrUnqualified
	}
	f, e := s.Owner.LockFactsTx(ctx, t, p)
	if e != nil {
		return nil, e
	}
	c, e := s.Content.ConquerCatalogTx(ctx, t, rev)
	if e != nil {
		return nil, e
	}
	if e = f.Validate(c); e != nil {
		return nil, e
	}
	if op.StartedAt.Before(f.UpdatedAt) {
		return nil, d.ErrStale
	}
	return &PreparedWrite{before: f, catalog: c, op: op}, nil
}
func (s Service) ApplyWriteTx(ctx context.Context, t tx.Tx, p *PreparedWrite, progress d.Progress, run *d.Run, originRef string) (d.Facts, error) {
	if t == nil || p == nil || strings.TrimSpace(originRef) == "" {
		return d.Facts{}, d.ErrUnqualified
	}
	f := p.before
	f.Version++
	f.ContentRevision, _ = p.op.Policies.Get("content")
	f.UpdatedAt = p.op.StartedAt
	f.Payload = d.Payload{Kind: d.Retained, Policy: d.Policy, OriginOperation: p.op.ID, OriginRef: originRef, Progress: &progress, Run: run}
	f.Payload = f.Payload.Clone()
	if e := f.Validate(p.catalog); e != nil {
		return d.Facts{}, e
	}
	if e := s.Owner.SaveFactsTx(ctx, t, f, p.before.Version, p.catalog); e != nil {
		return d.Facts{}, e
	}
	return f, nil
}
