package characterhero

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// LockStoryRosterTx acquires HeroRoot400 before the caller's Campaign605 row.
func (s Service) LockStoryRosterTx(c context.Context, t tx.Tx, pid identity.PlayerID) error {
	if s.AcquisitionStore == nil {
		return ErrHeroAcquisitionInvalid
	}
	_, err := s.AcquisitionStore.LockRootTx(c, t, pid)
	return err
}

// OwnsOriginTx tells whether the roster holds the origin in any form (awakened included); the caller holds HeroRoot400.
func (s Service) OwnsOriginTx(c context.Context, t tx.Tx, pid identity.PlayerID, origin int64) (bool, error) {
	if s.AcquisitionStore == nil {
		return false, ErrHeroAcquisitionInvalid
	}
	heroes, err := s.AcquisitionStore.ListHeroesTx(c, t, pid)
	return hasOrigin(heroes, origin), err
}

// AwardStoryPartnerTx uses the existing unique roster, admission and fresh-birth
// path. The caller holds HeroRoot400 and owns the durable campaign entitlement.
func (s Service) AwardStoryPartnerTx(c context.Context, t tx.Tx, pid identity.PlayerID, tableID int64, revision string, op operation.Context) (character.Hero, *character.CollectionAdmissionProof, error) {
	if t == nil || s.Acquisition == nil || s.AcquisitionStore == nil || s.CollectionAdmission == nil {
		return character.Hero{}, nil, ErrHeroAcquisitionInvalid
	}
	root, err := s.AcquisitionStore.ReadRootTx(c, t, pid)
	if err != nil {
		return character.Hero{}, nil, err
	}
	rule, err := s.Acquisition.HeroNormalSummonTx(c, t, revision, tableID)
	if err != nil {
		return character.Hero{}, nil, err
	}
	if rule.Template.Kind != character.NormalHero {
		return character.Hero{}, nil, ErrHeroAcquisitionInvalid
	}
	heroes, err := s.AcquisitionStore.ListHeroesTx(c, t, pid)
	if err != nil {
		return character.Hero{}, nil, err
	}
	// D116: an already owned choice returns the canonical entity without another grant.
	for _, h := range heroes {
		if h.OriginTableID == rule.Template.OriginTableID {
			return h, nil, nil
		}
	}
	refs := op.Policies.Refs()
	refs = append(refs, policy.Ref{Name: character.CollectionAdmissionPolicyRef, Version: character.CollectionAdmissionPolicy})
	op.Policies, err = policy.NewSet(refs...)
	if err != nil {
		return character.Hero{}, nil, err
	}
	proof, err := s.CollectionAdmission.AuthorizeCollectionOriginTx(c, t, root, heroes, rule.Template.OriginTableID, revision, op)
	if err != nil {
		return character.Hero{}, nil, err
	}
	if proof.Validate() != nil {
		return character.Hero{}, nil, errors.New("character: invalid story admission")
	}
	h, err := newHero(pid, root.NextPartnerID, rule.Template, rule.Template.InitialStar, revision, op)
	if err != nil {
		return h, nil, err
	}
	if err = insertFreshHero(c, t, s.AcquisitionStore, s.FreshFacets, h); err != nil {
		return h, nil, err
	}
	next, err := advanceRoot(root, 1, op)
	if err != nil {
		return h, nil, err
	}
	return h, &proof, s.AcquisitionStore.SaveRootAllocatorTx(c, t, next, root.StateVersion)
}
