package arena

import (
	"context"
	"errors"
	"fmt"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type TournamentSelectionCommand struct {
	Room      ids.UUID
	Team      int
	Turn      int
	Formation d.SelectedFormation
}

func roomSide(room d.TournamentRoom, player identity.PlayerID) (int, error) {
	for side, participant := range room.Selection.Players {
		if participant == player {
			return side, nil
		}
	}
	return 0, d.ErrRefused
}

func (service Service) selectionRoster(requestContext context.Context, query tx.Queryer, scope gen.TimedScope, player identity.PlayerID) (d.SelectionRoster, error) {
	heroes, err := service.heroRows(requestContext, query, player, scope.Operation.DecisionAt())
	if err != nil {
		return d.SelectionRoster{}, err
	}
	pets, err := service.petRows(requestContext, query, player, scope.Operation.DecisionAt())
	if err != nil {
		return d.SelectionRoster{}, err
	}
	roster := d.SelectionRoster{}
	for _, raw := range heroes {
		row, valid := raw.(map[string]any)
		if !valid {
			return roster, d.ErrConflict
		}
		roster.Heroes = append(roster.Heroes, d.SelectionHero{Identifier: number(row["partner_id"]), TableIdentifier: number(row["table_id"])})
	}
	for _, row := range pets {
		roster.Pets = append(roster.Pets, number(row["pet_id"]))
	}
	return roster, nil
}

func (service Service) SelectTournament(requestContext context.Context, actor identity.ActorContext, command TournamentSelectionCommand, operationContext operation.Context) (d.TournamentRoom, error) {
	if command.Room.IsZero() || command.Team < 1 || command.Team > d.SelectionTeamCount || command.Turn < 0 || command.Turn >= d.SelectionDoneTurn {
		return d.TournamentRoom{}, d.ErrInvalid
	}
	semanticKey := fmt.Sprintf("%s:%d:%d", command.Room.String(), command.Team, command.Turn)
	result, err := service.tournamentCommand(requestContext, actor, operationContext, "select", semanticKey, command, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog) (TournamentCommandResult, error) {
		room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, command.Room, true)
		if err != nil || !found {
			return TournamentCommandResult{}, errors.Join(err, d.ErrRefused)
		}
		if room.Status != d.RoomSelecting || room.Selection.Team != command.Team {
			return TournamentCommandResult{}, d.ErrRefused
		}
		roster, err := service.selectionRoster(requestContext, scope.Tx, scope, actor.PlayerID)
		if err != nil {
			return TournamentCommandResult{}, err
		}
		next, err := room.Selection.Select(d.SelectionCommand{Player: actor.PlayerID, Turn: command.Turn, Formation: command.Formation}, roster, scope.Operation.DecisionAt())
		if err != nil {
			return TournamentCommandResult{}, err
		}
		previousVersion := room.StateVersion
		room.Selection, room.StateVersion = next, previousVersion+1
		room.NoticeVersion++
		if err := service.describeSelection(requestContext, scope, &room); err != nil {
			return TournamentCommandResult{}, err
		}
		if next.Complete() {
			room.Status = d.RoomFighting
		}
		if err := service.Store.SaveTournamentRoomTx(requestContext, scope.Tx, room, previousVersion); err != nil {
			return TournamentCommandResult{}, err
		}
		return TournamentCommandResult{Room: &room}, nil
	})
	if err != nil || result.Room == nil {
		return d.TournamentRoom{}, errors.Join(err, d.ErrRefused)
	}
	return *result.Room, nil
}

func (service Service) ReadyTournament(requestContext context.Context, actor identity.ActorContext, roomIdentifier ids.UUID, operationContext operation.Context) (d.TournamentRoom, error) {
	result, err := service.tournamentCommand(requestContext, actor, operationContext, "ready", roomIdentifier.String(), map[string]any{"room": roomIdentifier}, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog) (TournamentCommandResult, error) {
		room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, roomIdentifier, true)
		if err != nil || !found {
			return TournamentCommandResult{}, errors.Join(err, d.ErrRefused)
		}
		side, err := roomSide(room, actor.PlayerID)
		if err != nil {
			return TournamentCommandResult{}, err
		}
		if room.Status != d.RoomPreparing || !scope.Operation.DecisionAt().Before(room.StartsAt) {
			return TournamentCommandResult{}, d.ErrRefused
		}
		previousVersion := room.StateVersion
		room.Ready[side], room.StateVersion = true, previousVersion+1
		room.NoticeVersion++
		if err := service.Store.SaveTournamentRoomTx(requestContext, scope.Tx, room, previousVersion); err != nil {
			return TournamentCommandResult{}, err
		}
		return TournamentCommandResult{Room: &room}, nil
	})
	if err != nil || result.Room == nil {
		return d.TournamentRoom{}, errors.Join(err, d.ErrRefused)
	}
	return *result.Room, nil
}

func (service Service) AcknowledgeTournament(requestContext context.Context, actor identity.ActorContext, roomIdentifier ids.UUID, version int64, operationContext operation.Context) error {
	if roomIdentifier.IsZero() || version < 1 {
		return d.ErrInvalid
	}
	_, err := service.tournamentCommand(requestContext, actor, operationContext, "acknowledge", roomIdentifier.String()+":"+strconv.FormatInt(version, 10), map[string]any{"room": roomIdentifier, "version": version}, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog) (TournamentCommandResult, error) {
		room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, roomIdentifier, true)
		if err != nil || !found {
			return TournamentCommandResult{}, errors.Join(err, d.ErrRefused)
		}
		side, err := roomSide(room, actor.PlayerID)
		if err != nil || version > room.NoticeVersion {
			return TournamentCommandResult{}, d.ErrRefused
		}
		if room.Acknowledged[side] >= version {
			return TournamentCommandResult{Room: &room}, nil
		}
		previousVersion := room.StateVersion
		room.Acknowledged[side], room.StateVersion = version, previousVersion+1
		if err := service.Store.SaveTournamentRoomTx(requestContext, scope.Tx, room, previousVersion); err != nil {
			return TournamentCommandResult{}, err
		}
		return TournamentCommandResult{Room: &room}, nil
	})
	return err
}
