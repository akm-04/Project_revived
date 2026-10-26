package i5

import (
	"context"
	"slices"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// AwakeningPetPort is the I9-5 mode owner binding; a client cannot call it directly.
// The caller freezes the actual pet formation in Combat and invokes completion only
// after accepting its matching terminal client-attested goal summary.
type AwakeningPetPort interface {
	FreezeAwakeningPetTx(context.Context, tx.Queryer, identity.PlayerID, int64, []int64) (*AwakeningPetContext, error)
	CompleteAwakeningPetTx(context.Context, tx.Tx, identity.PlayerID, AwakeningPetContext, int64, bool) (map[string]any, error)
}
type AwakeningPetContext struct {
	Occurrence objective.AwakeInstance `json:"occurrence"`
	Campaign   int64                   `json:"campaign"`
	Formation  []int64                 `json:"formation"`
}

func (s Service) FreezeAwakeningPetTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, campaign int64, formation []int64) (*AwakeningPetContext, error) {
	if s.awakeningAvailable() != nil || !pid.Valid() || campaign <= 0 || len(formation) == 0 || len(formation) > 6 {
		return nil, objective.ErrAwakeningRefused
	}
	seen := map[int64]bool{}
	for _, id := range formation {
		if id < 0 || id > 0 && seen[id] {
			return nil, objective.ErrAwakeningRefused
		}
		if id > 0 {
			seen[id] = true
		}
	}
	root, err := s.Awakening.Store.ReadAwakeningTx(ctx, q, pid)
	if err != nil {
		return nil, err
	}
	a := root.Active[2]
	if a.Mission == 0 {
		return nil, nil
	}
	catalog, err := s.Awakening.Content.AwakeningCatalogTx(ctx, q, a.Revision)
	if err != nil {
		return nil, err
	}
	d, ok := catalog.Definition(a.Mission)
	if !ok || d.Type != 3 || d.Stage != 2 || !slices.Contains(d.Routes, campaign) || !seen[a.OwnerID] {
		return nil, nil
	}
	pets, err := s.Awakening.Pets.AwakeningPetsTx(ctx, q, pid)
	if err != nil {
		return nil, err
	}
	for _, p := range pets {
		if p.PetID == a.OwnerID && p.TableID == d.Before {
			return &AwakeningPetContext{a, campaign, append([]int64{}, formation...)}, nil
		}
	}
	return nil, objective.ErrAwakeningRefused
}
func (s Service) CompleteAwakeningPetTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, frozen AwakeningPetContext, marker int64, win bool) (map[string]any, error) {
	if frozen.Occurrence.Validate() != nil || frozen.Occurrence.Type != 3 || marker != frozen.Occurrence.Mission || !win {
		return nil, objective.ErrAwakeningRefused
	}
	// Recheck route, owner and formation without taking a lower-ranked Character lock.
	qualified, err := s.FreezeAwakeningPetTx(ctx, t, pid, frozen.Campaign, frozen.Formation)
	if err != nil {
		return nil, err
	}
	if qualified == nil || qualified.Occurrence.Generation != frozen.Occurrence.Generation || qualified.Occurrence.OwnerID != frozen.Occurrence.OwnerID || qualified.Occurrence.Revision != frozen.Occurrence.Revision {
		return nil, objective.ErrAwakeningRefused
	}
	root, err := s.Awakening.Store.LockAwakeningTx(ctx, t, pid)
	if err != nil {
		return nil, err
	}
	a, err := root.Current(3, marker)
	if err != nil || a.Generation != frozen.Occurrence.Generation {
		return nil, objective.ErrAwakeningRefused
	}
	catalog, err := s.Awakening.Content.AwakeningCatalogTx(ctx, t, a.Revision)
	if err != nil {
		return nil, err
	}
	d, ok := catalog.Definition(marker)
	if !ok || d.Goal < 1 || d.Goal > 4 {
		return nil, objective.ErrAwakeningRefused
	}
	if d.Goal == 3 {
		n := 0
		for _, id := range frozen.Formation {
			if id > 0 {
				n++
			}
		}
		if n != 1 {
			return nil, objective.ErrAwakeningRefused
		}
	}
	if !a.Complete {
		old := root.Version
		if err = root.Complete(3, marker, a.Generation, d.Target); err != nil {
			return nil, err
		}
		root.Version++
		if err = s.Awakening.Store.SaveAwakeningTx(ctx, t, pid, root, old); err != nil {
			return nil, err
		}
	}
	body := map[string]any{objective.AwakeChannel(3): []map[string]any{root.Active[2].Wire(true)}}
	if err := s.awakeningRedmarksTx(ctx, t, pid, a.Revision, body); err != nil {
		return nil, err
	}
	return body, nil
}
