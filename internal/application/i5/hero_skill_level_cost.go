package i5

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/economy"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type PreparedHeroSkillLevelCost struct {
	mana        economy.ScalarBalance
	temporal    economy.TemporalState
	manaChanged bool
	timeChanged bool
	SkillPoint  int64
	SkillTime   int64
	Affordable  bool
}

type HeroSkillLevelCostResult struct {
	SkillPoint int64
	SkillTime  int64
}

type TxHeroSkillLevelCost interface {
	PrepareHeroSkillLevelCostTx(context.Context, tx.Tx, identity.PlayerID, int64, int64, operation.Context) (*PreparedHeroSkillLevelCost, error)
	ApplyHeroSkillLevelCostTx(context.Context, tx.Tx, *PreparedHeroSkillLevelCost) (HeroSkillLevelCostResult, error)
}

func (s Service) PrepareHeroSkillLevelCostTx(ctx context.Context, t tx.Tx, pid identity.PlayerID, manaCost, pointCost int64, op operation.Context) (*PreparedHeroSkillLevelCost, error) {
	if s.Store == nil || s.Content == nil || t == nil || !pid.Valid() || manaCost <= 0 || pointCost <= 0 || op.StartedAt.IsZero() {
		return nil, errors.New("invalid Hero skill resource debit")
	}
	revision, err := requireContentRevision(op)
	if err != nil {
		return nil, err
	}
	now := op.StartedAt.UTC()
	if err = s.Store.LockEconomyOwnerTx(ctx, t, pid); err != nil {
		return nil, err
	}
	progression, err := s.Store.LockProgressionTx(ctx, t, pid)
	if err != nil {
		return nil, err
	}
	mana, manaExists, err := s.Store.LockScalarTx(ctx, t, pid, "mana", now)
	if err != nil {
		return nil, err
	}
	points, pointsExist, err := s.Store.LockTemporalTx(ctx, t, pid, "skill_point")
	if err != nil {
		return nil, err
	}
	if !pointsExist {
		return nil, economy.ErrUnknownResource
	}
	policy, err := s.temporalPolicyAtTx(ctx, t, pid, "skill_point", revision, progression.Level, now)
	if err != nil {
		return nil, err
	}
	materialized, err := points.Materialize(now, policy)
	if err != nil {
		return nil, err
	}
	prepared := &PreparedHeroSkillLevelCost{
		mana:       mana,
		temporal:   points,
		SkillPoint: materialized.Amount,
		Affordable: manaExists && mana.Amount >= manaCost && materialized.Amount >= pointCost,
	}
	if materialized.State.RegenAnchorAt != nil {
		prepared.SkillTime = materialized.State.RegenAnchorAt.UTC().Unix()
	}
	if !prepared.Affordable {
		return prepared, nil
	}
	prepared.mana, err = mana.Debit(manaCost, now)
	if err != nil {
		return nil, err
	}
	prepared.temporal, err = s.prepareTemporalDebitState(points, pointCost, now, policy)
	if err != nil {
		return nil, err
	}
	prepared.manaChanged = true
	prepared.timeChanged = true
	prepared.SkillPoint = prepared.temporal.StoredAmount
	prepared.SkillTime = 0
	if prepared.temporal.RegenAnchorAt != nil {
		prepared.SkillTime = prepared.temporal.RegenAnchorAt.UTC().Unix()
	}
	return prepared, nil
}

func (s Service) ApplyHeroSkillLevelCostTx(ctx context.Context, t tx.Tx, prepared *PreparedHeroSkillLevelCost) (HeroSkillLevelCostResult, error) {
	if s.Store == nil || t == nil || prepared == nil || !prepared.Affordable || !prepared.manaChanged || !prepared.timeChanged {
		return HeroSkillLevelCostResult{}, errors.New("prepared Hero skill debit required")
	}
	if err := s.Store.SaveScalarTx(ctx, t, prepared.mana, true); err != nil {
		return HeroSkillLevelCostResult{}, err
	}
	if err := s.Store.SaveTemporalTx(ctx, t, prepared.temporal); err != nil {
		return HeroSkillLevelCostResult{}, err
	}
	return HeroSkillLevelCostResult{SkillPoint: prepared.SkillPoint, SkillTime: prepared.SkillTime}, nil
}

var _ TxHeroSkillLevelCost = Service{}
