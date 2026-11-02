package characterpet

import (
	"context"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
	"time"
)

type AwakeningStore interface {
	ListPetsTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Pet, error)
	SavePetAwakeningTx(context.Context, tx.Tx, character.Pet, int64) error
}

func (s Service) AwakeningPetsTx(c context.Context, q tx.Queryer, p identity.PlayerID) ([]character.Pet, error) {
	if s.Awakening == nil {
		return nil, ErrPetAwakeningProviderUnavailable
	}
	return s.Awakening.ListPetsTx(c, q, p)
}
func (s Service) LockAwakeningPetsTx(c context.Context, t tx.Tx, p identity.PlayerID) ([]character.Pet, error) {
	if s.Store == nil || s.Awakening == nil {
		return nil, ErrPetAwakeningProviderUnavailable
	}
	if _, e := s.Store.LockPetRootTx(c, t, p); e != nil {
		return nil, e
	}
	pets, e := s.Awakening.ListPetsTx(c, t, p)
	if e != nil {
		return nil, e
	}
	slices.SortFunc(pets, func(a, b character.Pet) int {
		if a.PetID < b.PetID {
			return -1
		}
		if a.PetID > b.PetID {
			return 1
		}
		return 0
	})
	for _, pet := range pets {
		if _, found, e := s.Store.LockPetByIDTx(c, t, p, pet.PetID); e != nil {
			return nil, e
		} else if !found {
			return nil, ErrPetNotFound
		}
	}
	return pets, nil
}

func (s Service) FinishAwakeningPetLockedTx(c context.Context, t tx.Tx, pet character.Pet, d objective.AwakeDefinition, revision string, op operation.Context, at time.Time) error {
	if s.Awakening == nil || s.Equipment == nil || t == nil || d.Type != 3 || d.Stage != 2 || d.Before != pet.TableID || pet.ValidatePersistent() != nil || op.ID.IsZero() || at.Before(pet.UpdatedAt) {
		return objective.ErrAwakeningRefused
	}
	awakened, e := s.Equipment.PetTemplateAwakenedTx(c, t, revision, d.After)
	if e != nil {
		return e
	}
	if !awakened {
		return objective.ErrAwakeningRefused
	}
	old := pet.StateVersion
	pet.TableID = d.After
	pet.StateVersion++
	pet.UpdatedAt = at.UTC()
	return s.Awakening.SavePetAwakeningTx(c, t, pet, old)
}

func (s Service) HasAwakeningPetEquipmentTx(c context.Context, q tx.Queryer, p character.Pet, d objective.AwakeDefinition, revision string) (bool, error) {
	if d.Type != 3 || d.Stage != 1 || p.TableID != d.Before {
		return false, objective.ErrAwakeningRefused
	}
	if s.Equipment == nil {
		return false, ErrPetEquipmentUnavailable
	}
	for i, collected := range p.Equipment {
		if collected == 0 {
			continue
		}
		pos, err := s.Equipment.PetEquipmentPositionTx(c, q, revision, p.TableID, p.Color, int64(i+1))
		if err != nil {
			return false, err
		}
		if int64(pos.ItemID) == d.Item {
			return true, nil
		}
	}
	return false, nil
}
