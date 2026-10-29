package arena

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (service Service) TournamentRoom(requestContext context.Context, actor identity.ActorContext, identifier ids.UUID, operationContext operation.Context) (d.TournamentRoom, error) {
	var room d.TournamentRoom
	if !service.ready() || identifier.IsZero() {
		return room, d.ErrUnavailable
	}
	_, _, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		stored, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, identifier, false)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		if _, err := roomSide(stored, actor.PlayerID); err != nil {
			return err
		}
		room = stored
		return nil
	})
	return room, err
}

var tournamentRetention = cd.Retention{ID: "I9_ARENA_TOURNAMENT_REPORT_RETENTION_V1", Version: 1, Window: cd.RetentionCeiling}

func (service Service) TournamentReport(requestContext context.Context, actor identity.ActorContext, identifier ids.UUID, round int, stage int, operationContext operation.Context) (d.TournamentRoomView, error) {
	view := d.TournamentRoomView{}
	if !service.ready() || identifier.IsZero() || round < 1 || round > d.SelectionTeamCount {
		return view, d.ErrInvalid
	}
	_, _, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, identifier, false)
		if err != nil || !found || !room.Casual && !room.IsFriendFight() && room.Stage != stage {
			return errors.Join(err, d.ErrRefused)
		}
		if room.Casual || room.IsFriendFight() {
			if _, err := roomSide(room, actor.PlayerID); err != nil {
				return err
			}
		}
		if room.Status == d.RoomFighting {
			view.Room, view.At = room, scope.Operation.DecisionAt()
			return nil
		}
		played := room.PlayedRounds()
		if room.Status != d.RoomSettled || round > len(played) {
			return d.ErrRefused
		}
		result, retained, err := service.Combat.ReplayTx(requestContext, scope.Tx, room.Attempts[played[round-1]], tournamentRetention, scope.Operation.DecisionAt())
		if err != nil || !retained {
			return errors.Join(err, d.ErrRefused)
		}
		view.Room, view.Report, view.At = room, result.Report, scope.Operation.DecisionAt()
		view.Heroes = [2]map[string]map[string]any{{}, {}}
		view.Pets = [2]map[string]map[string]any{{}, {}}
		for _, playedRound := range played {
			attempt := room.Attempts[playedRound]
			if attempt.IsZero() {
				continue
			}
			snapshot, err := service.Combat.SnapshotTx(requestContext, scope.Tx, attempt)
			if err != nil {
				return err
			}
			for side, actors := range [2][]cd.Actor{snapshot.Battle.TeamA, snapshot.Battle.WavesB[0]} {
				for _, fighter := range actors {
					if err := addFrozenActor(view.Heroes[side], fighter); err != nil {
						return err
					}
				}
			}
			for side, pets := range [2][]cd.Actor{snapshot.Battle.PetsA, snapshot.Battle.PetsB} {
				for _, pet := range pets {
					if err := addFrozenActor(view.Pets[side], pet); err != nil {
						return err
					}
				}
			}
		}
		return nil
	})
	return view, err
}

func addFrozenActor(rows map[string]map[string]any, actor cd.Actor) error {
	var row map[string]any
	if err := json.Unmarshal(actor.Params, &row); err != nil {
		return err
	}
	rows[strconv.FormatInt(actor.Identity, 10)] = row
	return nil
}

func (service Service) TournamentSelectionView(requestContext context.Context, actor identity.ActorContext, identifier ids.UUID, operationContext operation.Context) (d.TournamentRoomView, error) {
	view := d.TournamentRoomView{Heroes: [2]map[string]map[string]any{{}, {}}, Pets: [2]map[string]map[string]any{{}, {}}}
	if !service.ready() {
		return view, d.ErrUnavailable
	}
	_, _, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
			return err
		}
		room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, identifier, false)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		if _, err := roomSide(room, actor.PlayerID); err != nil {
			return err
		}
		view.Room, view.At = room, scope.Operation.DecisionAt()
		view.Heroes, view.Pets = room.SelectionHeroes, room.SelectionPets

		return nil
	})
	return view, err
}
