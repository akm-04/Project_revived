package characterhero

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/characterasset"
	apppractice "gxb.local/backend/v2/internal/application/characterpractice"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type HeroPracticeContributionStore interface {
	ReadHeroByPartnerIDTx(context.Context, tx.Queryer, identity.PlayerID, int64) (character.Hero, error)
}

type HeroPracticeContributionContent interface {
	PracticeRevisionTx(context.Context, tx.Queryer, string) (bool, error)
	HeroPracticeThresholdsTx(context.Context, tx.Queryer, string, int64) ([]apppractice.Threshold, error)
}

type PracticeContributionReader struct {
	Store   HeroPracticeContributionStore
	Content HeroPracticeContributionContent
}

func (r PracticeContributionReader) HeroPracticeContributionTx(ctx context.Context, q tx.Queryer, pid identity.PlayerID, partnerID int64, revision string) (characterasset.PracticeContribution, error) {
	if r.Store == nil || r.Content == nil || q == nil || !pid.Valid() || partnerID <= 0 || len(revision) != 64 {
		return characterasset.PracticeContribution{}, errors.New("character hero: invalid Practice contribution read")
	}
	good, err := r.Content.PracticeRevisionTx(ctx, q, revision)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	if !good {
		return characterasset.PracticeContribution{}, apppractice.ErrContentInactive
	}
	h, err := r.Store.ReadHeroByPartnerIDTx(ctx, q, pid, partnerID)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	if err := h.ValidatePersistent(); err != nil {
		return characterasset.PracticeContribution{}, err
	}
	thresholds, err := r.Content.HeroPracticeThresholdsTx(ctx, q, revision, h.TableID)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	reducer, rows, err := apppractice.ReduceAppliedPracticeContribution(characterasset.PracticeFamilyHero, h.Practice, thresholds)
	if err != nil {
		return characterasset.PracticeContribution{}, err
	}
	out := characterasset.PracticeContribution{
		Family: characterasset.PracticeFamilyHero, OwnerID: h.PartnerID, TableID: h.TableID, StateVersion: h.StateVersion,
		ContentRevision: revision, Applied: h.Practice, Reducer: reducer, Contributions: rows,
	}
	if err := out.Validate(); err != nil {
		return characterasset.PracticeContribution{}, err
	}
	return out, nil
}

var _ characterasset.HeroPracticeContributionProvider = PracticeContributionReader{}
