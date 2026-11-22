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

func (r Reader) MissionRosterTx(ctx context.Context, q tx.Queryer, scope i5.MissionScope) ([]character.Hero, error) {
	if r.Heroes == nil {
		return nil, errors.New("mission hero reader unavailable")
	}
	return r.Heroes.ListHeroesTx(ctx, q, scope.PlayerID)
}

func (r Reader) ObserveMissionTx(ctx context.Context, q tx.Queryer, scope i5.MissionScope, roster []character.Hero, definition objective.MissionDefinition, boundHero int64, memo *i5.MissionReadMemo) (i5.MissionObservation, error) {
	passed, err := r.gate(ctx, q, scope, roster, definition, boundHero, memo)
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
		out.Value, err = r.crystalSpent(ctx, q, scope, memo)
		if err != nil {
			return out, err
		}
	case kind == 15:
		state, err := r.campaignState(ctx, q, scope, memo)
		if err != nil {
			return out, err
		}
		out.Value = state.Progress.State(parameters[0]).ClearCountFloor
	case kind == 16:
		state, err := r.progression(ctx, q, scope, memo)
		if err != nil {
			return out, err
		}
		out.Value = state.Level
	case kind >= 3 && kind <= 14 || kind == 23 || kind == 24 || kind == 18 || kind == 21 || kind == 22:
		threshold := kind
		if kind == 23 {
			threshold = 15
		}
		if kind == 24 {
			threshold = 16
		}
		for _, hero := range roster {
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
		inputs, err := r.bookInputs(ctx, q, scope, memo)
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
		privilege, err := r.privilege(ctx, q, scope, memo)
		if err != nil {
			return out, err
		}
		if privilege.VIPLevel > 0 {
			out.Value = 1
		}
	case kind == 110 || kind == 129 || kind == 130 || kind == 131:
		out.Value = 1
	default:
		return out, errors.New("mission canonical condition reader unavailable")
	}
	return out, nil
}

func (r Reader) gate(ctx context.Context, q tx.Queryer, scope i5.MissionScope, roster []character.Hero, definition objective.MissionDefinition, boundHero int64, memo *i5.MissionReadMemo) (bool, error) {
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
		state, err := r.progression(ctx, q, scope, memo)
		if err != nil {
			return false, err
		}
		return state.Level >= gate[1], nil
	case 2:
		state, err := r.campaignState(ctx, q, scope, memo)
		if err != nil {
			return false, err
		}
		return state.Progress.State(gate[1]).Star > 0, nil
	case 3:
		state, err := r.privilege(ctx, q, scope, memo)
		if err != nil {
			return false, err
		}
		return state.VIPLevel >= gate[1], nil
	case 4:
		state, err := r.privilege(ctx, q, scope, memo)
		if err != nil {
			return false, err
		}
		return state.MonthCardActive, nil
	case 8:
		state, err := r.privilege(ctx, q, scope, memo)
		if err != nil {
			return false, err
		}
		return state.MonthlyPrivilegeActive, nil
	case 9:
		for _, hero := range roster {
			if hero.OriginTableID == boundHero {
				return true, nil
			}
		}
		return false, nil
	default:
		return false, errors.New("mission gate reader unavailable")
	}
}

func (r Reader) progression(ctx context.Context, q tx.Queryer, scope i5.MissionScope, memo *i5.MissionReadMemo) (player.Progression, error) {
	if memo != nil && memo.Progression != nil {
		return *memo.Progression, nil
	}
	if r.Progression == nil {
		return player.Progression{}, errors.New("mission progression reader unavailable")
	}
	state, err := r.Progression.ReadProgressionTx(ctx, q, scope.PlayerID)
	if err == nil && memo != nil {
		memo.Progression = &state
	}
	return state, err
}

func (r Reader) campaignState(ctx context.Context, q tx.Queryer, scope i5.MissionScope, memo *i5.MissionReadMemo) (campaign.Record, error) {
	if memo != nil && memo.Campaign != nil {
		return *memo.Campaign, nil
	}
	if r.Campaigns == nil {
		return campaign.Record{}, errors.New("mission campaign reader unavailable")
	}
	state, err := r.Campaigns.ReadTx(ctx, q, scope.PlayerID)
	if err == nil && memo != nil {
		memo.Campaign = &state
	}
	return state, err
}

func (r Reader) privilege(ctx context.Context, q tx.Queryer, scope i5.MissionScope, memo *i5.MissionReadMemo) (i5.PrivilegeSnapshot, error) {
	if memo != nil && memo.Privilege != nil {
		return *memo.Privilege, nil
	}
	if r.Privileges == nil {
		return i5.PrivilegeSnapshot{}, errors.New("mission privilege reader unavailable")
	}
	state, err := r.Privileges.SnapshotTx(ctx, q, scope.PlayerID, scope.DecisionAt)
	if err == nil && memo != nil {
		memo.Privilege = &state
	}
	return state, err
}

func (r Reader) crystalSpent(ctx context.Context, q tx.Queryer, scope i5.MissionScope, memo *i5.MissionReadMemo) (int64, error) {
	if memo != nil && memo.CrystalSpent != nil {
		return *memo.CrystalSpent, nil
	}
	if r.Spending == nil {
		return 0, errors.New("mission spend reader unavailable")
	}
	value, err := r.Spending.CrystalSpentOnDayTx(ctx, q, scope.PlayerID, modes.Day(scope.DecisionAt))
	if err == nil && memo != nil {
		memo.CrystalSpent = &value
	}
	return value, err
}

func (r Reader) bookInputs(ctx context.Context, q tx.Queryer, scope i5.MissionScope, memo *i5.MissionReadMemo) (bookskill.Inputs, error) {
	if memo != nil {
		if cached, ok := memo.Books.(bookskill.Inputs); ok {
			return cached, nil
		}
	}
	if r.Books == nil {
		return bookskill.Inputs{}, errors.New("mission book reader unavailable")
	}
	inputs, err := r.Books.BookInputsTx(ctx, q, bookskill.InputScope{Player: scope.PlayerID, ContentRevision: scope.ContentRevision, ObservedAt: scope.DecisionAt})
	if err == nil && memo != nil {
		memo.Books = inputs
	}
	return inputs, err
}

var _ i5.MissionObservations = Reader{}
