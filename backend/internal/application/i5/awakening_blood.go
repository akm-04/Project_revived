package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type AwakeningBloodContext struct {
	Occurrence    objective.AwakeInstance
	WindowSeconds int64
}
type AwakeningBloodPort interface {
	FreezeAwakeningBloodTx(context.Context, tx.Queryer, identity.PlayerID, int64) (AwakeningBloodContext, error)
	CompleteAwakeningBloodTx(context.Context, tx.Tx, identity.PlayerID, objective.AwakeInstance) (map[string]any, error)
}

func (s Service) FreezeAwakeningBloodTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, id int64) (AwakeningBloodContext, error) {
	if s.awakeningAvailable() != nil || id <= 0 {
		return AwakeningBloodContext{}, objective.ErrAwakeningRefused
	}
	root, e := s.Awakening.Store.ReadAwakeningTx(ctx, q, pid)
	if e != nil {
		return AwakeningBloodContext{}, e
	}
	a, e := root.Current(2, id)
	if e != nil {
		return AwakeningBloodContext{}, e
	}
	c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, q, a.Revision)
	if e != nil {
		return AwakeningBloodContext{}, e
	}
	d, ok := c.Definition(id)
	if !ok || d.Type != 2 || d.Stage != 2 || len(d.Routes) != 1 || d.Routes[0] != id || c.PrivatePolicy.BloodResultWindowSeconds <= 0 || !c.PrivatePolicy.GuardWitnessOnly {
		return AwakeningBloodContext{}, objective.ErrAwakeningRefused
	}
	heroes, e := s.Awakening.Heroes.AwakeningHeroesTx(ctx, q, pid, a.Revision)
	if e != nil {
		return AwakeningBloodContext{}, e
	}
	for _, h := range heroes {
		if h.Hero.PartnerID == a.OwnerID && h.Hero.TableID == d.Before && h.Raw != nil && h.Raw.RawStage == 2 {
			return AwakeningBloodContext{Occurrence: a, WindowSeconds: c.PrivatePolicy.BloodResultWindowSeconds}, nil
		}
	}
	return AwakeningBloodContext{}, objective.ErrAwakeningRefused
}
func (s Service) CompleteAwakeningBloodTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, frozen objective.AwakeInstance) (map[string]any, error) {
	if s.awakeningAvailable() != nil || frozen.Validate() != nil || frozen.Type != 2 {
		return nil, objective.ErrAwakeningRefused
	}
	root, e := s.Awakening.Store.LockAwakeningTx(ctx, t, pid)
	if e != nil {
		return nil, e
	}
	a, e := root.Current(2, frozen.Mission)
	if e != nil || a.Generation != frozen.Generation || a.Revision != frozen.Revision || a.OwnerID != frozen.OwnerID {
		return nil, objective.ErrAwakeningRefused
	}
	c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, t, a.Revision)
	if e != nil {
		return nil, e
	}
	d, ok := c.Definition(a.Mission)
	if !ok || d.Type != 2 || d.Stage != 2 {
		return nil, objective.ErrAwakeningRefused
	}
	if !a.Complete {
		old := root.Version
		if e = root.Complete(2, a.Mission, a.Generation, d.Target); e != nil {
			return nil, e
		}
		root.Version++
		if e = s.Awakening.Store.SaveAwakeningTx(ctx, t, pid, root, old); e != nil {
			return nil, e
		}
	}
	body := map[string]any{objective.AwakeChannel(2): []map[string]any{root.Active[1].Wire(true)}}
	if err := s.awakeningRedmarksTx(ctx, t, pid, a.Revision, body); err != nil {
		return nil, err
	}
	return body, nil
}
