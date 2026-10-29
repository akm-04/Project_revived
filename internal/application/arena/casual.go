package arena

import (
	"context"
	"errors"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (service Service) QueueCasual(requestContext context.Context, actor identity.ActorContext, operationContext operation.Context) (d.CasualEntry, error) {
	entryIdentifier, err := ids.NewUUID()
	if err != nil {
		return d.CasualEntry{}, err
	}
	result, err := service.tournamentCommand(requestContext, actor, operationContext, "casual-queue", operationContext.ID.String(), map[string]any{"player": actor.PlayerID}, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog) (TournamentCommandResult, error) {
		at := scope.Operation.DecisionAt()
		period := d.CasualPeriodAt(at)
		if !period.Open(at) {
			return TournamentCommandResult{}, d.ErrClosed
		}
		session, exists, err := service.Store.ReadCasualSessionTx(requestContext, scope.Tx, period.WeekDay, true)
		if err != nil {
			return TournamentCommandResult{}, err
		}
		if exists && session.Settled {
			return TournamentCommandResult{}, d.ErrClosed
		}
		if !exists {
			revision, err := service.Content.ActiveRevision(requestContext, scope.Tx)
			if err != nil {
				return TournamentCommandResult{}, err
			}
			session = d.CasualSession{Period: period, ContentRevision: revision, StateVersion: 1}
			if err := service.Store.SaveCasualSessionTx(requestContext, scope.Tx, session, 0); err != nil {
				return TournamentCommandResult{}, err
			}
		}
		current, found, err := service.Store.ActiveCasualEntryTx(requestContext, scope.Tx, actor.PlayerID)
		if err != nil {
			return TournamentCommandResult{}, err
		}
		if found && (current.Status == d.QueueMatched || at.Before(current.ExpiresAt)) {
			return TournamentCommandResult{Entry: &current}, nil
		}
		if found {
			previousVersion := current.StateVersion
			current.Status, current.StateVersion = d.QueueExpired, previousVersion+1
			if err := service.Store.SaveCasualEntryTx(requestContext, scope.Tx, current, previousVersion); err != nil {
				return TournamentCommandResult{}, err
			}
		}
		entry := d.CasualEntry{Identifier: entryIdentifier, WeekDay: period.WeekDay, Actor: d.AdmissionFrom(actor), Status: d.QueueWaiting, AdmittedAt: at, ExpiresAt: at.Add(d.CasualQueueLifetime), StateVersion: 1}
		if err := service.Store.SaveCasualEntryTx(requestContext, scope.Tx, entry, 0); err != nil {
			return TournamentCommandResult{}, err
		}
		return TournamentCommandResult{Entry: &entry}, nil
	})
	if err != nil || result.Entry == nil {
		return d.CasualEntry{}, errors.Join(err, d.ErrRefused)
	}
	return *result.Entry, nil
}

func (service Service) CancelCasual(requestContext context.Context, actor identity.ActorContext, operationContext operation.Context) error {
	_, err := service.tournamentCommand(requestContext, actor, operationContext, "casual-cancel", operationContext.ID.String(), map[string]any{"player": actor.PlayerID}, func(requestContext context.Context, scope gen.TimedScope, _ d.Catalog) (TournamentCommandResult, error) {
		entry, found, err := service.Store.ActiveCasualEntryTx(requestContext, scope.Tx, actor.PlayerID)
		if err != nil || !found {
			return TournamentCommandResult{}, err
		}
		if entry.Status != d.QueueWaiting {
			return TournamentCommandResult{}, d.ErrRefused
		}
		previousVersion := entry.StateVersion
		entry.Status, entry.StateVersion = d.QueueCancelled, previousVersion+1
		if err := service.Store.SaveCasualEntryTx(requestContext, scope.Tx, entry, previousVersion); err != nil {
			return TournamentCommandResult{}, err
		}
		return TournamentCommandResult{Entry: &entry}, nil
	})
	return err
}

// MatchCasual consumes both entries under the same owner fence used by cancellation.
func (service Service) MatchCasual(requestContext context.Context, operationContext operation.Context) (d.TournamentRoom, bool, error) {
	if !service.ready() {
		return d.TournamentRoom{}, false, d.ErrUnavailable
	}
	roomIdentifier, err := ids.NewUUID()
	if err != nil {
		return d.TournamentRoom{}, false, err
	}
	var room d.TournamentRoom
	var matched bool
	_, outcome, err := service.Timed.Run(requestContext, operationContext, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), casualMatchEvidence{store: service.Store, reader: service.Fresh, room: roomIdentifier}, func(requestContext context.Context, scope gen.TimedScope) error {
		matched = false
		at := scope.Operation.DecisionAt()
		period := d.CasualPeriodAt(at)
		root, found, err := service.Store.ReadCompetitionTx(requestContext, scope.Tx, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		entries, err := service.Store.WaitingCasualEntriesTx(requestContext, scope.Tx, period.WeekDay)
		if err != nil {
			return err
		}
		if len(entries) == 0 {
			return nil
		}
		previousVersion := root.StateVersion
		root.StateVersion++
		root.UpdatedAt = at
		if err := service.Store.SaveCompetitionTx(requestContext, scope.Tx, root, previousVersion); err != nil {
			return err
		}
		eligible := []d.CasualEntry{}
		for _, entry := range entries {
			if !period.Open(at) || !at.Before(entry.ExpiresAt) {
				previousVersion := entry.StateVersion
				entry.Status, entry.StateVersion = d.QueueExpired, previousVersion+1
				if err := service.Store.SaveCasualEntryTx(requestContext, scope.Tx, entry, previousVersion); err != nil {
					return err
				}
				continue
			}
			eligible = append(eligible, entry)
		}
		if len(eligible) < 2 {
			return nil
		}
		selection, err := d.NewSelectionRoom(eligible[0].Actor.PlayerID, eligible[1].Actor.PlayerID, at)
		if err != nil {
			return err
		}
		revision, catalog, err := service.catalogTx(requestContext, scope.Tx)
		if err != nil {
			return err
		}
		if catalog.Tournament == nil {
			return d.ErrUnavailable
		}
		room = d.TournamentRoom{Identifier: roomIdentifier, Casual: true, CasualWeekDay: period.WeekDay, Actors: [2]d.AdmissionContext{eligible[0].Actor, eligible[1].Actor}, Selection: selection, NoticeVersion: 1, Status: d.RoomSelecting, StartsAt: at, ContentRevision: revision, Contest: 1, StateVersion: 1}
		if err := service.describeSelection(requestContext, scope, &room); err != nil {
			return err
		}
		if err := service.Store.SaveTournamentRoomTx(requestContext, scope.Tx, room, 0); err != nil {
			return err
		}
		for _, entry := range eligible[:2] {
			previousVersion := entry.StateVersion
			entry.Status, entry.Room, entry.StateVersion = d.QueueMatched, roomIdentifier, previousVersion+1
			if err := service.Store.SaveCasualEntryTx(requestContext, scope.Tx, entry, previousVersion); err != nil {
				return err
			}
		}
		matched = true
		return nil
	})
	if err == nil && outcome.Reconciled {
		room, matched, err = service.Store.ReadTournamentRoomTx(requestContext, service.Fresh, roomIdentifier, false)
	}
	return room, matched, err
}

// An absent room after an ambiguous commit never authorizes consuming another pair.
type casualMatchEvidence struct {
	store  Store
	reader tx.Queryer
	room   ids.UUID
}

func (evidence casualMatchEvidence) ResolveTimed(requestContext context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	_, found, err := evidence.store.ReadTournamentRoomTx(requestContext, evidence.reader, evidence.room, false)
	if err != nil || !found {
		return tx.Resolution{State: tx.ResolutionUnknown}, err
	}
	return tx.Resolution{State: tx.ResolutionCommitted}, nil
}
