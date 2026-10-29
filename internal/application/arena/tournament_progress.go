package arena

import (
	"context"
	"errors"
	"math"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (service Service) SupportTournament(requestContext context.Context, actor identity.ActorContext, target identity.PlayerID, operationContext operation.Context) (d.TournamentPeriod, error) {
	if !target.Valid() {
		return d.TournamentPeriod{}, d.ErrInvalid
	}
	result, err := service.tournamentCommand(requestContext, actor, operationContext, "support", operationContext.ID.String(), map[string]any{"target": target}, func(requestContext context.Context, scope gen.TimedScope, catalog d.Catalog) (TournamentCommandResult, error) {
		season := catalog.LatestClosed(scope.Operation.DecisionAt())
		period, found, err := service.Store.ReadTournamentTx(requestContext, scope.Tx, season, true)
		if err != nil || !found {
			return TournamentCommandResult{}, errors.Join(err, d.ErrRefused)
		}
		stage := period.Calendar.StageAt(scope.Operation.DecisionAt())
		entrant, enrolled := period.Entrant(target)
		if stage < 2 || stage >= 6 || !period.RosterLocked || period.Cancelled || period.Settled || !enrolled || entrant.Eliminated || entrant.Group == 0 {
			return TournamentCommandResult{}, d.ErrRefused
		}
		profile, found, err := service.Directory.ProfileTx(requestContext, scope.Tx, actor.PlayerID)
		if err != nil || !found || profile.Level < d.TournamentSupportLevel {
			return TournamentCommandResult{}, errors.Join(err, d.ErrRefused)
		}
		previousVersion := period.StateVersion
		updated := false
		for index, support := range period.Supporters {
			if support.Player != actor.PlayerID {
				continue
			}
			if support.Target == target {
				return TournamentCommandResult{Period: &period}, nil
			}
			previous, exists := period.Entrant(support.Target)
			if !exists || !previous.Eliminated {
				return TournamentCommandResult{}, d.ErrRefused
			}
			earned, err := catalog.Tournament.Rules.SupportReward(support.Level, support.Advancements)
			if err != nil || support.EarnedMana > math.MaxInt64-earned {
				return TournamentCommandResult{}, d.ErrConflict
			}
			period.Supporters[index].EarnedMana += earned
			period.Supporters[index].Target, period.Supporters[index].Advancements = target, 0
			updated = true
			break
		}
		if !updated {
			period.Supporters = append(period.Supporters, d.TournamentSupport{Player: actor.PlayerID, Target: target, Level: profile.Level})
		}
		period.StateVersion++
		if err := service.Store.SaveTournamentTx(requestContext, scope.Tx, period, previousVersion); err != nil {
			return TournamentCommandResult{}, err
		}
		return TournamentCommandResult{Period: &period}, nil
	})
	if err != nil || result.Period == nil {
		return d.TournamentPeriod{}, errors.Join(err, d.ErrRefused)
	}
	return *result.Period, nil
}

func (service Service) ReconcileTournamentSelection(requestContext context.Context, identifier ids.UUID, operationContext operation.Context) (d.TournamentRoom, error) {
	return service.roomWork(requestContext, identifier, operationContext, "selection-deadlines", func(requestContext context.Context, scope gen.TimedScope, room *d.TournamentRoom) error {
		at := scope.Operation.DecisionAt()
		if at.Before(room.StartsAt) && !at.Before(room.StartsAt.Add(-TournamentReadyLead)) {
			return service.Store.WakeTournamentRoomTx(requestContext, scope.Tx, room.Identifier)
		}
		if at.Before(room.StartsAt) || room.Status == d.RoomSettled || room.Status == d.RoomFighting {
			return nil
		}
		if room.Status == d.RoomSelecting && at.Before(room.Selection.Deadline) {
			return service.Store.WakeTournamentRoomTx(requestContext, scope.Tx, room.Identifier)
		}
		rosters := [2]d.SelectionRoster{}
		for side, player := range room.Selection.Players {
			roster, err := service.selectionRoster(requestContext, scope.Tx, scope, player)
			if err != nil {
				return err
			}
			rosters[side] = roster
		}
		room.Status = d.RoomSelecting
		for !room.Selection.Complete() && !at.Before(room.Selection.Deadline) {
			next, err := room.Selection.Expire(rosters[room.Selection.Turn%2], room.Selection.Deadline)
			if err != nil {
				return err
			}
			room.Selection = next
		}
		if room.Selection.Complete() {
			room.Status = d.RoomFighting
		}
		room.StateVersion++
		room.NoticeVersion++
		if err := service.describeSelection(requestContext, scope, room); err != nil {
			return err
		}
		return nil
	})
}
