package i5

import (
	"context"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// Pet material origins supply source-qualified mappings; I5 owns the active occurrence.
type AwakeningPetMaterialPort interface {
	FreezeAwakeningPetMaterialTx(context.Context, tx.Queryer, identity.PlayerID, []PetMaterialRoute) (*objective.AwakeFrozenDrop, error)
	CheckAwakeningPetMaterialTx(context.Context, tx.Queryer, identity.PlayerID, objective.AwakeFrozenDrop) (bool, error)
}
type PetMaterialRoute struct{ Mission, Item, Count int64 }

func (s Service) FreezeAwakeningPetMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, routes []PetMaterialRoute) (*objective.AwakeFrozenDrop, error) {
	if e := s.awakeningAvailable(); e != nil {
		return nil, e
	}
	root, e := s.Awakening.Store.ReadAwakeningTx(c, q, p)
	if e != nil {
		return nil, e
	}
	a := root.Active[2]
	if a.Mission == 0 {
		return nil, nil
	}
	catalog, e := s.Awakening.Content.AwakeningCatalogTx(c, q, a.Revision)
	if e != nil {
		return nil, e
	}
	d, ok := catalog.Definition(a.Mission)
	if !ok || d.Type != 3 || d.Stage != 1 || a.Complete {
		return nil, nil
	}
	for _, r := range routes {
		if r.Mission == a.Mission {
			if r.Item <= 0 || r.Count != 1 {
				return nil, objective.ErrAwakeningRefused
			}
			return &objective.AwakeFrozenDrop{Occurrence: a, ItemID: r.Item, Rate: 10000, Count: r.Count}, nil
		}
	}
	return nil, nil
}
func (s Service) CheckAwakeningPetMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, drop objective.AwakeFrozenDrop) (bool, error) {
	if drop.Occurrence.Validate() != nil || drop.Occurrence.Type != 3 || drop.ItemID <= 0 || drop.Count != 1 || drop.Rate != 10000 {
		return false, objective.ErrAwakeningRefused
	}
	root, e := s.Awakening.Store.ReadAwakeningTx(c, q, p)
	if e != nil {
		return false, e
	}
	a := root.Active[2]
	return a.Mission == drop.Occurrence.Mission && a.Generation == drop.Occurrence.Generation && a.OwnerID == drop.Occurrence.OwnerID && a.Revision == drop.Occurrence.Revision && !a.Complete, nil
}
