package librarylocal

import (
	"context"

	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	lib "gxb.local/backend/v2/internal/domain/librarylocal"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

// ensurePartnerMissionsTx materializes the favor-stage mission set of one owned
// hero. Existing progress and state are never rewritten.
func (s Service) ensurePartnerMissionsTx(ctx context.Context, t tx.Tx, player identity.PlayerID, partnerID int64, revision string, at time.Time) error {
	catalog, e := s.Content.LibraryCatalogTx(ctx, t, revision)
	if e != nil {
		return e
	}
	hero, e := s.Heroes.ReadHeroByPartnerIDTx(ctx, t, player, partnerID)
	if e != nil {
		return lib.ErrUnqualified
	}
	if _, ok := catalog.Templates[hero.TableID]; !ok {
		return lib.ErrUnqualified
	}
	facts, e := s.Library.ReadHeroTx(ctx, t, hero.Ref())
	if e != nil {
		return e
	}
	return s.ensureMissionSetTx(ctx, t, catalog, player, partnerID, facts.Favor, at)
}

func (s Service) ensureMissionSetTx(ctx context.Context, t tx.Tx, catalog lib.Catalog, player identity.PlayerID, partnerID, favor int64, at time.Time) error {
	for _, missionID := range catalog.UnlockedMissions(favor) {
		if _, ok := catalog.Missions[missionID]; !ok {
			return lib.ErrUnqualified
		}
		row := lib.MissionFact{PlayerID: player, PartnerID: partnerID, MissionID: missionID, Process: 0, MissionState: lib.MissionProceed, UpdatedAt: at}
		if _, e := s.Library.EnsureMissionTx(ctx, t, row); e != nil {
			return e
		}
	}
	return nil
}

// settlePartnerMissionsTx advances mission 1001 on a favor-raising gift and
// awards every success row once, returning the amour the caller must raise on
// the hero through the ordinary favor path.
func (s Service) settlePartnerMissionsTx(ctx context.Context, t tx.Tx, catalog lib.Catalog, player identity.PlayerID, partnerID int64, advanceGift bool, at time.Time) (int64, bool, error) {
	rows, e := s.Library.ListMissionsTx(ctx, t, player)
	if e != nil {
		return 0, false, e
	}
	changed := false
	var amour int64
	for _, row := range rows {
		if row.PartnerID != partnerID {
			continue
		}
		moved := false
		if advanceGift && row.MissionID == lib.GiftMissionID && row.MissionState == lib.MissionProceed {
			rule, ok := catalog.Missions[row.MissionID]
			if !ok {
				return 0, false, lib.ErrUnqualified
			}
			next, advanced, e := row.Advance(rule.Required, at)
			if e != nil {
				return 0, false, e
			}
			if advanced {
				row, moved = next, true
			}
		}
		if row.MissionState == lib.MissionSuccess {
			rule, ok := catalog.Missions[row.MissionID]
			if !ok {
				return 0, false, lib.ErrUnqualified
			}
			next, awarded, e := row.Award(at)
			if e != nil {
				return 0, false, e
			}
			if awarded {
				row, moved = next, true
				amour += rule.Amour
			}
		}
		if !moved {
			continue
		}
		if e = s.Library.SaveMissionTx(ctx, t, row); e != nil {
			return 0, false, e
		}
		changed = true
	}
	return amour, changed, nil
}

// awardMissionAmour folds the mission amour into the command's one hero write:
// a command that already advanced the state version keeps that single bump.
func awardMissionAmour(facts lib.HeroFacts, amour int64, advanced bool, at time.Time) (lib.HeroFacts, bool, error) {
	if advanced {
		return facts.AwardAmour(amour, at)
	}
	return facts.RaiseFavor(amour, at)
}

func (s Service) prepareFacts(ctx context.Context, t tx.Tx, player identity.PlayerID, d Admission) (context.Context, error) {
	if s.Facts == nil {
		return ctx, ErrUnavailable
	}
	timed, e := gen.NewTimedOperation(d.Operation, d.DecisionAt)
	if e != nil {
		return ctx, e
	}
	return s.Facts.PrepareTx(ctx, t, player, timed)
}

// recordIntimacy emits fact 124 once per settling command that raised favor.
// A missing port refuses the command so its transaction rolls back the value.
func (s Service) recordIntimacy(ctx context.Context, t tx.Tx, op operation.Context, player identity.PlayerID) error {
	if s.Facts == nil {
		return ErrUnavailable
	}
	return s.Facts.RecordTx(ctx, t, op, objective.Fact{PlayerID: player, SourceDomain: "library", SourceBusinessKey: op.ID.String(), Kind: objective.IntimacyImprovedKind, Delta: 1})
}
