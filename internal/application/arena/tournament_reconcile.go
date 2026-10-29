package arena

import (
	"context"
	"errors"

	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/foundation/operation"
)

func (service Service) ReconcileTournaments(requestContext context.Context, parent operation.Context, limit int) (int, error) {
	if limit < 1 {
		return 0, nil
	}
	_, found, err := service.Store.ReadCompetitionTx(requestContext, service.Fresh, false)
	if err != nil || !found {
		return 0, err
	}
	now, err := service.Timed.Binder.Time.Now(requestContext)
	if err != nil {
		return 0, err
	}
	_, catalog, err := service.catalogTx(requestContext, service.Fresh)
	if err != nil || catalog.Tournament == nil {
		return 0, err
	}
	applied := 0
	for applied < limit {
		operationContext, err := child(parent, "casual-match")
		if err != nil {
			return applied, err
		}
		_, matched, err := service.MatchCasual(requestContext, operationContext)
		if err != nil {
			return applied, err
		}
		if !matched {
			break
		}
		applied++
	}
	seasons, err := service.Store.PendingTournamentsTx(requestContext, service.Fresh, limit)
	if err != nil {
		return applied, err
	}
	for _, season := range seasons {
		operationContext, err := child(parent, "tournament-advance")
		if err != nil {
			return applied, err
		}
		if _, err := service.AdvanceTournament(requestContext, season, operationContext); err != nil {
			return applied, err
		}
	}
	rooms, err := service.Store.DueTournamentRoomsTx(requestContext, service.Fresh, now, limit)
	if err != nil {
		return applied, err
	}
	for _, identifier := range rooms {
		operationContext, err := child(parent, "tournament-room")
		if err != nil {
			return applied, err
		}
		room, err := service.ReconcileTournamentSelection(requestContext, identifier, operationContext)
		if err != nil {
			return applied, err
		}
		if room.Status == d.RoomFighting {
			operationContext, err = child(parent, "tournament-start")
			if err != nil {
				return applied, err
			}
			if room, err = service.StartTournamentCombat(requestContext, identifier, operationContext); err != nil {
				return applied, err
			}
			operationContext, err = child(parent, "tournament-terminal")
			if err != nil {
				return applied, err
			}
			room, err = service.ResolveTournamentCombat(requestContext, identifier, operationContext)
			if errors.Is(err, context.Canceled) || errors.Is(err, context.DeadlineExceeded) {
				return applied, nil
			}
			if err != nil {
				return applied, err
			}
		}
		if room.Status == d.RoomSettled {
			applied++
		}
	}
	sessions, err := service.Store.PendingCasualSessionsTx(requestContext, service.Fresh, now, limit)
	if err != nil {
		return applied, err
	}
	for _, weekDay := range sessions {
		operationContext, err := child(parent, "casual-settle")
		if err != nil {
			return applied, err
		}
		if err := service.SettleCasualSession(requestContext, weekDay, operationContext); errors.Is(err, ErrUnresolved) {
			continue
		} else if err != nil {
			return applied, err
		}
		applied++
	}
	return applied, nil
}
