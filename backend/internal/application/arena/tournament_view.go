package arena

import (
	"context"
	"errors"
	"gxb.local/backend/v2/internal/foundation/ids"
	"unicode/utf8"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (service Service) PlayoffsView(requestContext context.Context, actor identity.ActorContext, operationContext operation.Context) (d.TournamentView, error) {
	result := d.TournamentView{Viewer: actor.PlayerID, Faces: map[identity.PlayerID]d.Face{}, Rooms: []d.TournamentRoom{}}
	if !service.ready() {
		return result, d.ErrUnavailable
	}
	_, _, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		result.At = scope.Operation.DecisionAt()
		if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, result.At); err != nil {
			return err
		}
		revision, catalog, err := service.catalogTx(requestContext, scope.Tx)
		if err != nil {
			return err
		}
		if catalog.Tournament == nil {
			return d.ErrUnavailable
		}
		season := catalog.LatestClosed(result.At)
		if season < 1 {
			return d.ErrClosed
		}
		calendar, err := catalog.Tournament.Rules.Calendar(catalog.SeasonNumbered(season))
		if err != nil {
			return err
		}
		period, found, err := service.Store.ReadTournamentTx(requestContext, scope.Tx, season, false)
		if err != nil {
			return err
		}
		if !found {
			period = d.TournamentPeriod{Season: season, Calendar: calendar, ContentRevision: revision}
		}
		result.Period = period
		result.Rooms, err = service.Store.TournamentRoomsTx(requestContext, scope.Tx, season, 0, false)
		if err != nil {
			return err
		}
		for _, entrant := range period.Entrants {
			face, err := service.face(requestContext, scope.Tx, entrant.PlayerID)
			if err != nil {
				return err
			}
			result.Faces[entrant.PlayerID] = face
		}
		return nil
	})
	return result, err
}

func (service Service) CasualView(requestContext context.Context, actor identity.ActorContext, operationContext operation.Context) (d.CasualView, error) {
	result := d.CasualView{Viewer: actor.PlayerID, Faces: map[identity.PlayerID]d.Face{}, Rooms: []d.TournamentRoom{}, Standings: []d.CasualStanding{}}
	if !service.ready() {
		return result, d.ErrUnavailable
	}
	_, _, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		result.At = scope.Operation.DecisionAt()
		result.Period = d.CasualPeriodAt(result.At)
		if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, result.At); err != nil {
			return err
		}
		entry, found, err := service.Store.ActiveCasualEntryTx(requestContext, scope.Tx, actor.PlayerID)
		if err != nil {
			return err
		}
		if found {
			result.Entry = &entry
		}
		result.Rooms, err = service.Store.TournamentRoomsTx(requestContext, scope.Tx, result.Period.WeekDay, actor.PlayerID, true)
		if err != nil {
			return err
		}
		standings, err := service.Store.CasualStandingsTx(requestContext, scope.Tx, result.Period.WeekDay)
		if err != nil {
			return err
		}
		result.Standings = d.OrderCasualStandings(standings)
		for _, standing := range result.Standings {
			face, err := service.face(requestContext, scope.Tx, standing.PlayerID)
			if err != nil {
				return err
			}
			result.Faces[standing.PlayerID] = face
		}
		return nil
	})
	return result, err
}

func (service Service) DeclareTournament(requestContext context.Context, actor identity.ActorContext, declaration string, operationContext operation.Context) (string, error) {
	if !utf8.ValidString(declaration) || sourceDeclarationLength(declaration) > 2*tournamentDeclarationLimit {
		return "", d.ErrInvalid
	}
	result, err := service.tournamentCommand(requestContext, actor, operationContext, "declaration", operationContext.ID.String(), map[string]any{"declaration": declaration}, ids.UUID{}, func(requestContext context.Context, scope gen.TimedScope, catalog d.Catalog) (TournamentCommandResult, error) {
		period, found, err := service.Store.ReadTournamentTx(requestContext, scope.Tx, catalog.LatestClosed(scope.Operation.DecisionAt()), true)
		if err != nil || !found {
			return TournamentCommandResult{}, errors.Join(err, d.ErrRefused)
		}
		if period.Settled || period.Cancelled {
			return TournamentCommandResult{}, d.ErrClosed
		}
		for index, entrant := range period.Entrants {
			if entrant.PlayerID != actor.PlayerID {
				continue
			}
			previous := period.StateVersion
			period.Entrants[index].Declaration = declaration
			period.StateVersion++
			if err := service.Store.SaveTournamentTx(requestContext, scope.Tx, period, previous); err != nil {
				return TournamentCommandResult{}, err
			}
			return TournamentCommandResult{Period: &period}, nil
		}
		return TournamentCommandResult{}, d.ErrRefused
	})
	if err != nil || result.Period == nil {
		return "", errors.Join(err, d.ErrRefused)
	}
	entrant, _ := result.Period.Entrant(actor.PlayerID)
	return entrant.Declaration, nil
}

const tournamentDeclarationLimit = 40

// Preserve getTextLen's byte thresholds, including its four-byte-character quirk.
func sourceDeclarationLength(value string) int {
	length := 0
	for offset := 0; offset < len(value); {
		first := value[offset]
		width := 1
		switch {
		case first > 240:
			width = 4
		case first > 225:
			width = 3
		case first > 192:
			width = 2
		}
		offset += width
		if first > 225 && first <= 240 {
			length += 2
		} else {
			length++
		}
	}
	return length
}
