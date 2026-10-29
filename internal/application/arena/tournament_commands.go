package arena

import (
	"context"
	"encoding/json"
	"errors"
	"strconv"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type TournamentCommandResult struct {
	Period *d.TournamentPeriod `json:"period,omitempty"`
	Entry  *d.CasualEntry      `json:"entry,omitempty"`
	Room   *d.TournamentRoom   `json:"room,omitempty"`
}

func (service Service) tournamentCommand(requestContext context.Context, actor identity.ActorContext, operationContext operation.Context, name, semanticKey string, request any, roomIdentifier ids.UUID, apply func(context.Context, gen.TimedScope, d.Catalog) (TournamentCommandResult, error)) (TournamentCommandResult, error) {
	var result TournamentCommandResult
	if !service.ready() || !actor.PlayerID.Valid() {
		return result, d.ErrUnavailable
	}
	identity := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "arena-tournament", Operation: name, SemanticKey: semanticKey}
	fingerprint, err := receipt.FingerprintRequest(request)
	if err != nil {
		return result, err
	}
	_, outcome, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: service.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}, func(requestContext context.Context, scope gen.TimedScope) error {
		at := scope.Operation.DecisionAt()
		if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, at); err != nil {
			return err
		}
		stored, found, err := service.Receipts.FindTx(requestContext, scope.Tx, identity)
		if err != nil {
			return err
		}
		if found {
			if stored.RequestFingerprint != fingerprint {
				return &receipt.ConflictError{Identity: identity}
			}
			return json.Unmarshal(stored.ResultPayload, &result)
		}
		_, catalog, err := service.catalogTx(requestContext, scope.Tx)
		if err != nil {
			return err
		}
		if catalog.Tournament == nil || catalog.Tournament.Validate() != nil {
			return d.ErrUnavailable
		}
		friendRoom := false
		if !roomIdentifier.IsZero() {
			room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, roomIdentifier, false)
			if err != nil || !found {
				return errors.Join(err, d.ErrRefused)
			}
			friendRoom = room.IsFriendFight()
		}
		if friendRoom {
			profile, found, err := service.Directory.ProfileTx(requestContext, scope.Tx, actor.PlayerID)
			if err != nil {
				return err
			}
			if catalog.FriendBattleLevel < 1 {
				return d.ErrUnavailable
			}
			if !found || profile.Level < catalog.FriendBattleLevel {
				return d.ErrRefused
			}
		} else if err := service.gate(requestContext, scope.Tx, catalog, actor.PlayerID, at); err != nil {
			return err
		}

		root, found, err := service.Store.ReadCompetitionTx(requestContext, scope.Tx, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		previousVersion := root.StateVersion
		root.StateVersion++
		root.UpdatedAt = at
		if err := service.Store.SaveCompetitionTx(requestContext, scope.Tx, root, previousVersion); err != nil {
			return err
		}
		result, err = apply(requestContext, scope, catalog)
		if err != nil {
			return err
		}
		payload, err := json.Marshal(result)
		if err != nil {
			return err
		}
		record, err := receipt.New(scope.Operation.Operation(), identity, "I9_7B_ARENA", "gxb.arena.tournament-command.v1", payload, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion, record.ActorAccountUID, record.ContextID = d.TournamentContractIdentifier, string(actor.AccountUID), actor.ContextID.UUID()
		_, err = service.Receipts.PutTx(requestContext, scope.Tx, record)
		return err
	})
	if err != nil || !outcome.Reconciled {
		return result, err
	}
	record, found, err := service.ReceiptRead.Find(requestContext, identity)
	if err != nil || !found {
		return result, errors.Join(err, d.ErrConflict)
	}
	err = json.Unmarshal(record.ResultPayload, &result)
	return result, err
}

func (service Service) EnrollTournament(requestContext context.Context, actor identity.ActorContext, operationContext operation.Context) (d.TournamentPeriod, error) {
	result, err := service.tournamentCommand(requestContext, actor, operationContext, "enroll", operationContext.ID.String(), map[string]any{"player": actor.PlayerID}, ids.UUID{}, func(requestContext context.Context, scope gen.TimedScope, catalog d.Catalog) (TournamentCommandResult, error) {
		season := catalog.LatestClosed(scope.Operation.DecisionAt())
		if season < 1 {
			return TournamentCommandResult{}, d.ErrRefused
		}
		calendar, err := catalog.Tournament.Rules.Calendar(catalog.SeasonNumbered(season))
		if err != nil {
			return TournamentCommandResult{}, err
		}
		if calendar.StageAt(scope.Operation.DecisionAt()) != 1 {
			return TournamentCommandResult{}, d.ErrClosed
		}
		period, found, err := service.Store.ReadTournamentTx(requestContext, scope.Tx, season, true)
		if err != nil {
			return TournamentCommandResult{}, err
		}
		previousVersion := period.StateVersion
		if !found {
			revision, err := service.Content.ActiveRevision(requestContext, scope.Tx)
			if err != nil {
				return TournamentCommandResult{}, err
			}
			period = d.TournamentPeriod{Season: season, Calendar: calendar, ContentRevision: revision}
		}
		if _, enrolled := period.Entrant(actor.PlayerID); enrolled {
			return TournamentCommandResult{Period: &period}, nil
		}
		ranks, err := service.Store.PreviousSeasonRanksTx(requestContext, scope.Tx, season)
		if err != nil {
			return TournamentCommandResult{}, err
		}
		for _, rank := range ranks {
			if rank.PlayerID != actor.PlayerID {
				continue
			}
			rank.RegistrationSequence = int64(len(period.Entrants) + 1)
			period.Entrants = append(period.Entrants, d.TournamentEntrant{TournamentEnrollment: rank, Actor: d.AdmissionFrom(actor)})
			period.StateVersion++
			if err := service.Store.SaveTournamentTx(requestContext, scope.Tx, period, previousVersion); err != nil {
				return TournamentCommandResult{}, err
			}
			return TournamentCommandResult{Period: &period}, nil
		}
		return TournamentCommandResult{}, d.ErrRefused
	})
	if err != nil || result.Period == nil {
		return d.TournamentPeriod{}, errors.Join(err, d.ErrRefused)
	}
	return *result.Period, nil
}
