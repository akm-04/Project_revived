package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
)

type AwakeningCampaignPort interface {
	FreezeAwakeningCampaignTx(context.Context, tx.Queryer, identity.PlayerID, int64, int64, []int64, int64, bool) (objective.AwakeCampaignContext, error)
	SettleAwakeningCampaignTx(context.Context, tx.Tx, identity.PlayerID, objective.AwakeCampaignContext, int64, int64, bool) ([]objective.AwakeFrozenDrop, map[string]any, error)
}

func (s Service) FreezeAwakeningCampaignTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, campaign, kind int64, formation []int64, pet int64, materials bool) (objective.AwakeCampaignContext, error) {
	out := objective.AwakeCampaignContext{Player: int64(pid), Campaign: campaign, Type: kind, Formation: append([]int64{}, formation...), Pet: pet, Drops: []objective.AwakeFrozenDrop{}}
	if e := s.awakeningAvailable(); e != nil {
		return out, e
	}
	if out.Validate() != nil {
		return out, objective.ErrAwakeningRefused
	}
	root, e := s.Awakening.Store.ReadAwakeningTx(ctx, q, pid)
	if e != nil {
		return out, e
	}
	for _, a := range root.Active {
		if a.Mission == 0 || a.Type == 3 {
			continue
		}
		c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, q, a.Revision)
		if e != nil {
			return out, e
		}
		d, ok := c.Definition(a.Mission)
		if !ok {
			return out, objective.ErrAwakeningRefused
		}
		if a.Type == 1 && d.Stage == 2 && slices.Contains(d.Routes, campaign) && slices.Contains(formation, a.OwnerID) {
			copy := a
			out.Final = &copy
		}
		if materials && d.Stage == 1 {
			for _, r := range c.Drops {
				if r.Mission == a.Mission && r.Campaign == campaign && r.Type == kind {
					out.Drops = append(out.Drops, objective.AwakeFrozenDrop{Occurrence: a, ItemID: r.Item, Rate: r.Rate})
				}
			}
		}
	}
	return out, out.Validate()
}
func (s Service) SettleAwakeningCampaignTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, frozen objective.AwakeCampaignContext, marker, petMarker int64, win bool) ([]objective.AwakeFrozenDrop, map[string]any, error) {
	if s.awakeningAvailable() != nil || frozen.Validate() != nil || frozen.Player != int64(pid) || marker < 0 || petMarker != 0 {
		return nil, nil, objective.ErrAwakeningRefused
	}
	if marker > 0 && (frozen.Final == nil || frozen.Final.Mission != marker) {
		return nil, nil, objective.ErrAwakeningRefused
	}
	root, e := s.Awakening.Store.LockAwakeningTx(ctx, t, pid)
	if e != nil {
		return nil, nil, e
	}
	old := root.Version
	awards := []objective.AwakeFrozenDrop{}
	body := map[string]any{}
	for _, drop := range frozen.Drops {
		a := root.Active[drop.Occurrence.Type-1]
		if win && a.Mission == drop.Occurrence.Mission && a.Generation == drop.Occurrence.Generation && a.OwnerID == drop.Occurrence.OwnerID && a.Revision == drop.Occurrence.Revision && drop.Count > 0 {
			catalog, e := s.Awakening.Content.AwakeningCatalogTx(ctx, t, a.Revision)
			if e != nil {
				return nil, nil, e
			}
			qualified := false
			for _, route := range catalog.Drops {
				if route.Mission == a.Mission && route.Campaign == frozen.Campaign && route.Type == frozen.Type && route.Item == drop.ItemID && route.Rate == drop.Rate {
					qualified = true
					break
				}
			}
			if !qualified {
				return nil, nil, objective.ErrAwakeningRefused
			}
			awards = append(awards, drop)
		}
	}
	if marker > 0 {
		if !win {
			return nil, nil, objective.ErrAwakeningRefused
		}
		a, e := root.Current(1, marker)
		if e != nil || a.Generation != frozen.Final.Generation || a.OwnerID != frozen.Final.OwnerID || a.Revision != frozen.Final.Revision {
			return nil, nil, objective.ErrAwakeningRefused
		}
		c, e := s.Awakening.Content.AwakeningCatalogTx(ctx, t, a.Revision)
		if e != nil {
			return nil, nil, e
		}
		d, ok := c.Definition(marker)
		if !ok || d.Type != 1 || d.Stage != 2 || d.Goal < 1 || d.Goal > 4 || !slices.Contains(d.Routes, frozen.Campaign) || !slices.Contains(frozen.Formation, a.OwnerID) {
			return nil, nil, objective.ErrAwakeningRefused
		}
		if d.Goal == 3 {
			n := 0
			for _, id := range frozen.Formation {
				if id > 0 {
					n++
				}
			}
			if n != 1 || frozen.Pet != 0 {
				return nil, nil, objective.ErrAwakeningRefused
			}
		}
		if !a.Complete {
			if e = root.Complete(1, marker, a.Generation, d.Target); e != nil {
				return nil, nil, e
			}
			root.Version++
			if e = s.Awakening.Store.SaveAwakeningTx(ctx, t, pid, root, old); e != nil {
				return nil, nil, e
			}
		}
		body[objective.AwakeChannel(1)] = []map[string]any{root.Active[0].Wire(true)}
	}
	return awards, body, nil
}
