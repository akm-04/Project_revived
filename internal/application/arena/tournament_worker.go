package arena

import (
	"context"
	"encoding/json"
	"errors"

	gen "gxb.local/backend/v2/internal/application/generation"
	d "gxb.local/backend/v2/internal/domain/arena"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// roomWork is internal scheduling authority; callers must validate the durable room transition.
func (service Service) roomWork(requestContext context.Context, identifier ids.UUID, operationContext operation.Context, name string, apply func(context.Context, gen.TimedScope, *d.TournamentRoom) error) (d.TournamentRoom, error) {
	var result d.TournamentRoom
	if !service.ready() || identifier.IsZero() {
		return result, d.ErrUnavailable
	}
	pinned, err := service.pin(requestContext, operationContext)
	if err != nil {
		return result, err
	}
	identity := receipt.Identity{OwnerKind: "arena-room", OwnerKey: identifier.String(), Domain: "arena-tournament", Operation: name, SemanticKey: operationContext.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"room": identifier, "operation": name})
	if err != nil {
		return result, err
	}
	_, outcome, err := service.Timed.Run(requestContext, pinned, fightProfile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: service.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}, func(requestContext context.Context, scope gen.TimedScope) error {
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
		root, found, err := service.Store.ReadCompetitionTx(requestContext, scope.Tx, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrConflict)
		}
		room, found, err := service.Store.ReadTournamentRoomTx(requestContext, scope.Tx, identifier, true)
		if err != nil || !found {
			return errors.Join(err, d.ErrRefused)
		}
		previousVersion := room.StateVersion
		if err := apply(requestContext, scope, &room); err != nil {
			return err
		}
		if room.StateVersion != previousVersion {
			if err := service.Store.SaveTournamentRoomTx(requestContext, scope.Tx, room, previousVersion); err != nil {
				return err
			}
			rootVersion := root.StateVersion
			root.StateVersion++
			root.UpdatedAt = scope.Operation.DecisionAt()
			if err := service.Store.SaveCompetitionTx(requestContext, scope.Tx, root, rootVersion); err != nil {
				return err
			}
		}
		result = room
		payload, err := json.Marshal(room)
		if err != nil {
			return err
		}
		record, err := receipt.New(scope.Operation.Operation(), identity, "I9_7B_ARENA", "gxb.arena.room-work.v1", payload, fingerprint)
		if err != nil {
			return err
		}
		record.PolicyVersion = d.TournamentContractIdentifier
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
