package characterhero

import (
	"context"
	"errors"
	"fmt"
	"slices"
	"time"

	appi5 "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type AwakeningMutationStore interface {
	FindRawAwakeningTx(context.Context, tx.Queryer, character.HeroRef) (character.RawAwakeningBirth, bool, error)
	SaveRawAwakeningTx(context.Context, tx.Tx, character.RawAwakeningBirth, int64) error
	SaveHeroAwakeningTx(context.Context, tx.Tx, character.Hero, int64) error
}

// AwakeningHeroesTx does not seed legacy missing facets or infer raw stage from a template.
func (s Service) AwakeningHeroesTx(c context.Context, q tx.Queryer, p identity.PlayerID, revision string) ([]appi5.AwakeningHero, error) {
	if q == nil || s.AcquisitionStore == nil || s.Acquisition == nil || s.Awakening == nil {
		return nil, character.ErrRawAwakeningUnavailable
	}
	heroes, e := s.AcquisitionStore.ListHeroesTx(c, q, p)
	if e != nil {
		return nil, e
	}
	out := make([]appi5.AwakeningHero, 0, len(heroes))
	for _, h := range heroes {
		template, e := s.Acquisition.HeroTemplateProgressionTx(c, q, revision, h.TableID)
		if e != nil {
			return nil, e
		}
		h.Kind = template.Kind
		raw, found, e := s.Awakening.FindRawAwakeningTx(c, q, h.Ref())
		if e != nil {
			return nil, e
		}
		if !found {
			out = append(out, appi5.AwakeningHero{Hero: h})
			continue
		}
		if raw.CreationContentRevision != h.CreationContentRevision || !raw.BirthAt.Equal(h.CreatedAt) {
			return nil, character.ErrRawAwakeningUnavailable
		}
		out = append(out, appi5.AwakeningHero{Hero: h, Raw: &raw})
	}
	return out, nil
}

func (s Service) LockAwakeningHeroesTx(c context.Context, t tx.Tx, p identity.PlayerID, revision string) ([]appi5.AwakeningHero, error) {
	if s.AcquisitionStore == nil {
		return nil, character.ErrRawAwakeningUnavailable
	}
	if _, e := s.AcquisitionStore.LockRootTx(c, t, p); e != nil {
		return nil, e
	}
	heroes, e := s.AcquisitionStore.ListHeroesTx(c, t, p)
	if e != nil {
		return nil, e
	}
	slices.SortFunc(heroes, func(a, b character.Hero) int {
		if a.PartnerID < b.PartnerID {
			return -1
		}
		if a.PartnerID > b.PartnerID {
			return 1
		}
		return 0
	})
	for _, h := range heroes {
		if _, e = s.AcquisitionStore.LockHeroByPartnerIDTx(c, t, p, h.PartnerID); e != nil {
			return nil, e
		}
	}
	return s.AwakeningHeroesTx(c, t, p, revision)
}

// ApplyAwakeningHeroLockedTx composes in the mission transaction after its Character locks.
func (s Service) ApplyAwakeningHeroLockedTx(c context.Context, t tx.Tx, h appi5.AwakeningHero, d objective.AwakeDefinition, a objective.AwakeInstance, action string, op operation.Context, at time.Time) (appi5.AwakeningHero, error) {
	if s.Awakening == nil || t == nil || h.Hero.Validate() != nil || d.ID != a.Mission || d.Type != a.Type || a.OwnerID != h.Hero.PartnerID || d.Before != h.Hero.TableID || a.Validate() != nil || op.ID.IsZero() || at.IsZero() {
		return h, objective.ErrAwakeningRefused
	}
	next := h.Hero
	if d.Type == 1 {
		if action != "claim" || d.Stage != 2 {
			return h, objective.ErrAwakeningRefused
		}
		template, e := s.Acquisition.HeroTemplateProgressionTx(c, t, a.Revision, d.After)
		if e != nil {
			return h, e
		}
		if template.Kind != character.NormalHero || template.OriginTableID != h.Hero.OriginTableID {
			return h, objective.ErrAwakeningRefused
		}
		next.TableID = d.After
	} else if d.Type == 2 {
		if h.Raw == nil || h.Raw.Validate() != nil {
			return h, character.ErrRawAwakeningUnavailable
		}
		raw := *h.Raw
		stage := int64(-1)
		switch action {
		case "open":
			if d.Stage == 1 && raw.RawStage == 0 {
				stage = 1
			}
		case "cancel":
			if raw.RawStage == d.Stage {
				stage = 0
			}
		case "claim":
			if raw.RawStage == d.Stage {
				stage = d.Stage + 1
			}
		}
		if stage < 0 || stage > 3 {
			return h, objective.ErrAwakeningRefused
		}
		raw.RawStage = stage
		raw.Version++
		raw.UpdatedAt = at.UTC()
		raw.ProducerReference = fmt.Sprintf("%s/%d/%d/%s", objective.AwakeningContract, a.Mission, a.Generation, op.ID.String())
		if e := s.Awakening.SaveRawAwakeningTx(c, t, raw, h.Raw.Version); e != nil {
			return h, e
		}
		h.Raw = &raw
	} else {
		return h, objective.ErrAwakeningRefused
	}
	next.StateVersion++
	next.UpdatedAt = at.UTC()
	if next.UpdatedAt.Before(next.CreatedAt) {
		return h, errors.New("awakening decision precedes Hero birth")
	}
	if e := s.Awakening.SaveHeroAwakeningTx(c, t, next, h.Hero.StateVersion); e != nil {
		return h, e
	}
	h.Hero = next
	return h, nil
}

// OverlayRosterTx projects the intrinsic facet without manufacturing a stage for legacy missing rows.
func (s Service) OverlayRosterTx(c context.Context, q tx.Queryer, actor identity.ActorContext, revision string, at time.Time, body map[string]any) error {
	heroes, e := s.AwakeningHeroesTx(c, q, actor.PlayerID, revision)
	if e != nil {
		return e
	}
	rows, ok := body["heros"].(map[string]any)
	if !ok {
		return errors.New("awakening roster shape mismatch")
	}
	for _, h := range heroes {
		if h.Raw == nil {
			continue
		}
		if at.Before(h.Raw.UpdatedAt) || at.Before(h.Hero.UpdatedAt) {
			return character.ErrRawAwakeningUnavailable
		}
		row, ok := rows[fmt.Sprint(h.Hero.PartnerID)].(map[string]any)
		if !ok {
			return errors.New("awakening roster Hero missing")
		}
		row["twice_awake_stage"] = h.Raw.RawStage
	}
	return nil
}

// HasAwakeningHeroEquipmentTx observes the exact source item, never a previous mission's progress.
func (s Service) HasAwakeningHeroEquipmentTx(c context.Context, q tx.Queryer, h character.Hero, d objective.AwakeDefinition, revision string) (bool, error) {
	if d.Type != 1 || d.Stage != 1 || h.TableID != d.Before {
		return false, objective.ErrAwakeningRefused
	}
	if s.Equipment == nil {
		return false, ErrHeroEquipmentUnavailable
	}
	for i, collected := range h.Equipment {
		if collected == 0 {
			continue
		}
		pos, err := s.Equipment.HeroEquipmentPositionTx(c, q, revision, h.TableID, h.Color, int64(i+1))
		if err != nil {
			return false, err
		}
		if int64(pos.ItemID) == d.Item {
			return true, nil
		}
	}
	return false, nil
}
