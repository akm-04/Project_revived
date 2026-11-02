package characterpet

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// LockCampaignPetTx precedes Campaign605/Combat609 and I5 value locks.
func (s Service) LockCampaignPetTx(c context.Context, t tx.Tx, pid identity.PlayerID, id int64) error {
	if s.Store == nil || t == nil {
		return errors.New("character pet: incomplete campaign participant lock")
	}
	if id <= 0 {
		return ErrPetNotFound
	}
	p, found, err := s.Store.LockPetByIDTx(c, t, pid, id)
	if err != nil {
		return err
	}
	if !found || !p.IsShow {
		return ErrPetNotFound
	}
	return nil
}

// CreditCampaignEXPTx credits a caller-locked participant using the same source
// cap/thresholds as feeding. The campaign receipt owns replay, not a potion debit.
func (s Service) CreditCampaignEXPTx(c context.Context, t tx.Tx, pid identity.PlayerID, id, amount, level int64, revision string, at time.Time) (character.Pet, error) {
	if s.Store == nil || s.Progression == nil || t == nil || amount < 0 || at.IsZero() {
		return character.Pet{}, errors.New("character pet: invalid campaign EXP")
	}
	p, found, err := s.Store.LockPetByIDTx(c, t, pid, id)
	if err != nil {
		return p, err
	}
	if !found || !p.IsShow {
		return p, ErrPetNotFound
	}
	if at.Before(p.UpdatedAt) {
		return p, errors.New("character pet: stale campaign EXP")
	}
	cap, err := s.Progression.CharacterMaxLevelTx(c, t, revision, level)
	if err != nil {
		return p, err
	}
	rows, err := s.Progression.PetExpPolicyTx(c, t, revision, cap)
	if err != nil {
		return p, err
	}
	if len(rows) == 0 || p.Level > cap || p.Exp > rows[len(rows)-1].TotalExp {
		return p, errors.New("character pet: invalid campaign EXP cap")
	}
	if p.Level >= cap || amount == 0 {
		return p, nil
	}
	nextExp := rows[len(rows)-1].TotalExp
	if amount <= nextExp-p.Exp {
		nextExp = p.Exp + amount
	}
	nextLevel, err := petLevelForExp(nextExp, cap, rows)
	if err != nil {
		return p, err
	}
	old := p.StateVersion
	p.Exp = nextExp
	p.Level = nextLevel
	p.StateVersion++
	p.UpdatedAt = at.UTC()
	return p, s.Store.SavePetStateTx(c, t, p, old)
}
