// Package missioninputs composes canonical owner reads for the I5 objective owner.
package missioninputs

import (
	"context"
	"errors"

	"gxb.local/backend/v2/internal/application/bookskill"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/character"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Heroes interface {
	ListHeroesTx(context.Context, tx.Queryer, identity.PlayerID) ([]character.Hero, error)
}
type Progression interface {
	ReadProgressionTx(context.Context, tx.Queryer, identity.PlayerID) (player.Progression, error)
}
type Campaigns interface {
	ReadTx(context.Context, tx.Queryer, identity.PlayerID) (campaign.Record, error)
}
type Books interface {
	BookInputsTx(context.Context, tx.Queryer, bookskill.InputScope) (bookskill.Inputs, error)
}

type CrystalSpending interface {
	CrystalSpentOnDayTx(context.Context, tx.Queryer, identity.PlayerID, int64) (int64, error)
}
type Reader struct {
	Spending    CrystalSpending
	Heroes      Heroes
	Progression Progression
	Campaigns   Campaigns
	Books       Books
	Privileges  i5.PrivilegeSnapshotProvider
}

func (r Reader) MissionPartnerTemplatesTx(ctx context.Context, q tx.Queryer, scope i5.MissionScope) ([]int64, error) {
	if r.Heroes == nil {
		return nil, errors.New("mission hero reader unavailable")
	}
	heroes, err := r.Heroes.ListHeroesTx(ctx, q, scope.PlayerID)
	if err != nil {
		return nil, err
	}
	ids := make([]int64, 0, len(heroes))
	for _, hero := range heroes {
		ids = append(ids, hero.OriginTableID)
	}
	return ids, nil
}

func (r Reader) ObserveMissionTx(ctx context.Context, q tx.Queryer, scope i5.MissionScope, definition objective.MissionDefinition, boundHero int64) (i5.MissionObservation, error) {
	passed, err := r.gate(ctx, q, scope, definition, boundHero)
	if err != nil || !passed {
		return i5.MissionObservation{}, err
	}
	out := i5.MissionObservation{GatePassed: true}
	if definition.Strategy == "COMMITTED_DELTA" || definition.Presentation.DeferredUntil != "" && !(definition.Presentation.DeferredUntil == "I9-4B" && r.Spending != nil) {
		return out, nil
	}
	kind, parameters := definition.Presentation.Condition, definition.Presentation.Parameters
	switch {
	case kind == 126 || kind == 127:
		if r.Spending == nil {
			return out, errors.New("mission spend reader unavailable")
		}
		out.Value, err = r.Spending.CrystalSpentOnDayTx(ctx, q, scope.PlayerID, modes.Day(scope.DecisionAt))
		if err != nil {
			return out, err
		}
	case kind == 15:
		if r.Campaigns == nil {
			return out, errors.New("mission campaign reader unavailable")
		}
		state, err := r.Campaigns.ReadTx(ctx, q, scope.PlayerID)
		if err != nil {
			return out, err
		}
		out.Value = state.Progress.State(parameters[0]).ClearCountFloor
	case kind == 16:
		if r.Progression == nil {
			return out, errors.New("mission progression reader unavailable")
		}
		state, err := r.Progression.ReadProgressionTx(ctx, q, scope.PlayerID)
		if err != nil {
			return out, err
		}
		out.Value = state.Level
	case kind >= 3 && kind <= 14 || kind == 23 || kind == 24 || kind == 18 || kind == 21 || kind == 22:
		if r.Heroes == nil {
			return out, errors.New("mission hero reader unavailable")
		}
		heroes, err := r.Heroes.ListHeroesTx(ctx, q, scope.PlayerID)
		if err != nil {
			return out, err
		}
		threshold := kind
		if kind == 23 {
			threshold = 15
		}
		if kind == 24 {
			threshold = 16
		}
		for _, hero := range heroes {
			switch kind {
			case 18:
				target := parameters[0]
				if definition.Family == objective.Partner {
					target = boundHero
				}
				if hero.OriginTableID == target {
					out.Value = 1
				}
			case 21:
				if hero.OriginTableID == boundHero {
					out.Value = max(out.Value, hero.Level)
				}
			case 22:
				if hero.OriginTableID == boundHero {
					out.Value = max(out.Value, hero.Color)
				}
			default:
				if hero.Color >= threshold {
					out.Value++
				}
			}
		}
	case kind == 19 || kind == 20:
		if r.Books == nil {
			return out, errors.New("mission book reader unavailable")
		}
		inputs, err := r.Books.BookInputsTx(ctx, q, bookskill.InputScope{Player: scope.PlayerID, ContentRevision: scope.ContentRevision, ObservedAt: scope.DecisionAt})
		if err != nil {
			return out, err
		}
		if kind == 19 {
			out.Value = inputs.Applied.Buildings[parameters[0]].Level
		} else {
			for _, book := range inputs.Catalog.Books {
				complete := true
				for _, skill := range book.Skills {
					if inputs.Applied.Skills[skill] < book.Star {
						complete = false
						break
					}
				}
				if complete {
					out.Value++
				}
			}
		}
	case kind == 111 || kind == 118:
		claimable, err := definition.MealClaimable(scope.DecisionAt)
		if err != nil {
			return out, err
		}
		if claimable {
			out.Value = 1
		}
	case kind == 113:
		if r.Privileges == nil {
			return out, errors.New("mission privilege reader unavailable")
		}
		privilege, err := r.Privileges.SnapshotTx(ctx, q, scope.PlayerID, scope.DecisionAt)
		if err != nil {
			return out, err
		}
		if privilege.VIPLevel > 0 {
			out.Value = 1
		}
	default:
		return out, errors.New("mission canonical condition reader unavailable")
	}
	return out, nil
}

func (r Reader) gate(ctx context.Context, q tx.Queryer, scope i5.MissionScope, definition objective.MissionDefinition, boundHero int64) (bool, error) {
	if err := definition.Validate(); err != nil {
		return false, err
	}
	if definition.Prerequisite.UnavailableReason != "" || definition.Prerequisite.DeferredUntil != "" {
		return false, nil
	}
	gate := definition.Prerequisite.Gate
	switch gate[0] {
	case 0:
		return true, nil
	case 1, 5:
		if r.Progression == nil {
			return false, errors.New("mission progression reader unavailable")
		}
		state, err := r.Progression.ReadProgressionTx(ctx, q, scope.PlayerID)
		return state.Level >= gate[1], err
	case 2:
		if r.Campaigns == nil {
			return false, errors.New("mission campaign reader unavailable")
		}
		state, err := r.Campaigns.ReadTx(ctx, q, scope.PlayerID)
		return state.Progress.State(gate[1]).Star > 0, err
	case 3:
		if r.Privileges == nil {
			return false, errors.New("mission privilege reader unavailable")
		}
		state, err := r.Privileges.SnapshotTx(ctx, q, scope.PlayerID, scope.DecisionAt)
		return state.VIPLevel >= gate[1], err
	case 9:
		if r.Heroes == nil {
			return false, errors.New("mission hero reader unavailable")
		}
		heroes, err := r.Heroes.ListHeroesTx(ctx, q, scope.PlayerID)
		if err != nil {
			return false, err
		}
		for _, hero := range heroes {
			if hero.OriginTableID == boundHero {
				return true, nil
			}
		}
		return false, nil
	default:
		return false, errors.New("mission gate reader unavailable")
	}
}

var _ i5.MissionObservations = Reader{}
