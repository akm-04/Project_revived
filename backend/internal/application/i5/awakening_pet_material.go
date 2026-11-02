package i5

import (
	"context"

	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	ordinaryAwakeningKind = 1
	petAwakeningKind      = 3
)

// MaterialRoute is a mode's mission-keyed material: the mode lists what it can
// supply, I5 owns which occurrence is active.
type MaterialRoute struct{ Mission, Item, Count int64 }

// AwakeningPetMaterialPort supplies pet awakening material (kind 3).
type AwakeningPetMaterialPort interface {
	FreezeAwakeningPetMaterialTx(context.Context, tx.Queryer, identity.PlayerID, []MaterialRoute) (*objective.AwakeFrozenDrop, error)
	CheckAwakeningPetMaterialTx(context.Context, tx.Queryer, identity.PlayerID, objective.AwakeFrozenDrop) (bool, error)
}

// AwakeningOccultMaterialPort supplies ordinary hero awakening material (kind 1)
// from Occult by mission, not by campaign.
type AwakeningOccultMaterialPort interface {
	FreezeAwakeningOccultMaterialTx(context.Context, tx.Queryer, identity.PlayerID, []MaterialRoute) (*objective.AwakeFrozenDrop, error)
	CheckAwakeningOccultMaterialTx(context.Context, tx.Queryer, identity.PlayerID, objective.AwakeFrozenDrop) (bool, error)
}

func (s Service) FreezeAwakeningPetMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, routes []MaterialRoute) (*objective.AwakeFrozenDrop, error) {
	return s.freezeAwakeningMaterialTx(c, q, p, petAwakeningKind, routes)
}

func (s Service) CheckAwakeningPetMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, drop objective.AwakeFrozenDrop) (bool, error) {
	return s.checkAwakeningMaterialTx(c, q, p, petAwakeningKind, drop)
}

func (s Service) FreezeAwakeningOccultMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, routes []MaterialRoute) (*objective.AwakeFrozenDrop, error) {
	return s.freezeAwakeningMaterialTx(c, q, p, ordinaryAwakeningKind, routes)
}

func (s Service) CheckAwakeningOccultMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, drop objective.AwakeFrozenDrop) (bool, error) {
	return s.checkAwakeningMaterialTx(c, q, p, ordinaryAwakeningKind, drop)
}

func (s Service) freezeAwakeningMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, kind int64, routes []MaterialRoute) (*objective.AwakeFrozenDrop, error) {
	if e := s.awakeningAvailable(); e != nil {
		return nil, e
	}
	root, e := s.Awakening.Store.ReadAwakeningTx(c, q, p)
	if e != nil {
		return nil, e
	}
	a := root.Active[kind-1]
	if a.Mission == 0 {
		return nil, nil
	}
	catalog, e := s.Awakening.Content.AwakeningCatalogTx(c, q, a.Revision)
	if e != nil {
		return nil, e
	}
	d, ok := catalog.Definition(a.Mission)
	if !ok || d.Type != kind || d.Stage != 1 || a.Complete {
		return nil, nil
	}
	for _, r := range routes {
		if r.Mission == a.Mission {
			if r.Item <= 0 || !materialCountAllowed(kind, r.Count) {
				return nil, objective.ErrAwakeningRefused
			}
			return &objective.AwakeFrozenDrop{Occurrence: a, ItemID: r.Item, Rate: 10000, Count: r.Count}, nil
		}
	}
	return nil, nil
}

// materialCountAllowed keeps the pet route at its single item; the ordinary
// route's quantity is the Occult catalog's.
func materialCountAllowed(kind, count int64) bool {
	if kind == petAwakeningKind {
		return count == 1
	}
	return count > 0
}

func (s Service) checkAwakeningMaterialTx(c context.Context, q tx.Queryer, p identity.PlayerID, kind int64, drop objective.AwakeFrozenDrop) (bool, error) {
	if drop.Occurrence.Validate() != nil || drop.Occurrence.Type != kind || drop.ItemID <= 0 || !materialCountAllowed(kind, drop.Count) || drop.Rate != 10000 {
		return false, objective.ErrAwakeningRefused
	}
	root, e := s.Awakening.Store.ReadAwakeningTx(c, q, p)
	if e != nil {
		return false, e
	}
	a := root.Active[kind-1]
	return a.Mission == drop.Occurrence.Mission && a.Generation == drop.Occurrence.Generation && a.OwnerID == drop.Occurrence.OwnerID && a.Revision == drop.Occurrence.Revision && !a.Complete, nil
}
