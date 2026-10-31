package topfloor

import (
	"context"
	"encoding/json"
	"errors"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"strconv"
)

func (service Service) PurchaseTask(requestContext context.Context, actor identity.ActorContext, op operation.Context, reset bool) (domain.Player, error) {
	if !service.ready() {
		return domain.Player{}, domain.ErrUnavailable
	}
	name := "buy-ticket"
	if reset {
		name = "reset-timer"
	}
	identity := receipt.Identity{OwnerKind: "player", OwnerKey: strconv.FormatInt(int64(actor.PlayerID), 10), Domain: "top-floor-task", Operation: name, SemanticKey: op.ID.String()}
	fingerprint, err := receipt.FingerprintRequest(map[string]any{"player": int64(actor.PlayerID), "operation": name})
	if err != nil {
		return domain.Player{}, err
	}
	op, err = service.pin(requestContext, op)
	if err != nil {
		return domain.Player{}, err
	}
	var result domain.Player
	for settlementRetry := 0; settlementRetry < 2; settlementRetry++ {
		// A receipt is read under the actor fence before current-period admission.
		_, resolution, err := service.Timed.Run(requestContext, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), timedReceipt{receipt.Resolver{Reader: service.ReceiptRead, Identity: identity, Fingerprint: fingerprint}}, func(requestContext context.Context, scope gen.TimedScope) error {
			if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, scope.Operation.DecisionAt()); err != nil {
				return err
			}
			saved, found, err := service.Receipts.FindTx(requestContext, scope.Tx, identity)
			if err != nil {
				return err
			}
			if found {
				if saved.RequestFingerprint != fingerprint {
					return domain.ErrConflict
				}
				return json.Unmarshal(saved.ResultPayload, &result)
			}
			catalog, period, player, err := service.taskStateTx(requestContext, scope, actor)
			if err != nil {
				return err
			}
			at := scope.Operation.DecisionAt()
			privileges, err := service.Privileges.SnapshotTx(requestContext, scope.Tx, actor.PlayerID, at)
			if err != nil {
				return err
			}
			var next domain.Player
			var cost int64
			if reset {
				next, cost, err = catalog.ResetTimer(player.Player, catalog.Privilege(privileges.VIPLevel), privileges.MonthlyPrivilegeActive, at)
			} else {
				next, cost, err = catalog.Buy(player.Player, catalog.Privilege(privileges.VIPLevel), at)
			}
			if err != nil {
				return err
			}
			if _, err = service.Costs.DebitMaterialCostTx(requestContext, scope.Tx, actor.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}}, scope.Operation.Operation()); err != nil {
				return err
			}
			next.StateVersion++
			next.UpdatedAt = at
			updated := player
			updated.Player = next
			if err = service.Store.SaveTaskPlayerTx(requestContext, scope.Tx, updated, period, player.Player.StateVersion); err != nil {
				return err
			}
			raw, err := json.Marshal(next)
			if err != nil {
				return err
			}
			saved, err = receipt.New(scope.Operation.Operation(), identity, "I9_TOP_FLOOR_TASK", "gxb.topfloor.task.purchase.v1", raw, fingerprint)
			if err != nil {
				return err
			}
			saved.PolicyVersion = domain.TaskModeContractID
			saved.ActorAccountUID = string(actor.AccountUID)
			saved.ContextID = actor.ContextID.UUID()
			_, err = service.Receipts.PutTx(requestContext, scope.Tx, saved)
			result = next
			return err
		})
		if errors.Is(err, ErrSettlementDue) && settlementRetry == 0 {
			if err = service.SettleTaskDue(requestContext, actor.LogicalServerID, op); err != nil {
				return result, err
			}
			continue
		}
		if err != nil {
			return result, err
		}
		if resolution.Reconciled {
			saved, found, err := service.ReceiptRead.Find(requestContext, identity)
			if err != nil || !found {
				return result, errors.Join(err, domain.ErrConflict)
			}
			err = json.Unmarshal(saved.ResultPayload, &result)
			return result, err
		}
		return result, nil
	}
	return result, domain.ErrConflict
}
func (service Service) TaskFormation(requestContext context.Context, actor identity.ActorContext, wire int64) (domain.Display, error) {
	catalog, at, err := service.readContext(requestContext)
	if err != nil {
		return domain.Display{}, err
	}
	catalog, period, found, err := service.taskCatalog(requestContext, service.Fresh, actor.LogicalServerID, at)
	if err != nil || !found {
		return domain.Display{}, errors.Join(err, domain.ErrRefused)
	}
	if wire/domain.RegionStride != int64(actor.LogicalServerID) || wire%domain.RegionStride <= 0 {
		return domain.Display{}, domain.ErrInvalid
	}
	occupant := domain.Occupant{Player: identity.PlayerID(wire)}
	if _, found, err = service.Store.TaskRankOfTx(requestContext, service.Fresh, actor.LogicalServerID, period.Rotation.Number, occupant); err != nil {
		return domain.Display{}, err
	} else if !found {
		occupant = domain.Occupant{Robot: wire % domain.RegionStride}
	}
	return service.taskDisplay(requestContext, service.Fresh, catalog, period, occupant, at)
}
func (service Service) TaskPreFight(requestContext context.Context, actor identity.ActorContext, enemy int64) error {
	_, at, err := service.readContext(requestContext)
	if err != nil {
		return err
	}
	catalog, period, found, err := service.taskCatalog(requestContext, service.Fresh, actor.LogicalServerID, at)
	if err != nil || !found {
		return errors.Join(err, domain.ErrRefused)
	}
	eligibility, err := service.TaskModeEligibilityTx(requestContext, service.Fresh, *catalog.TaskModes, actor, at)
	if err != nil {
		return err
	}
	if !eligibility.Eligible {
		return domain.ErrRefused
	}
	player, found, err := service.Store.ReadTaskPlayerTx(requestContext, service.Fresh, actor.PlayerID, period, false)
	if err != nil || !found {
		return errors.Join(err, domain.ErrRefused)
	}
	if enemy == 0 {
		return nil
	}
	occupant, found := offered(player.Player, enemy)
	if !found {
		return domain.ErrRefused
	}
	_, err = service.taskDisplay(requestContext, service.Fresh, catalog, period, occupant, at)
	return err
}
func (service Service) TaskRankList(requestContext context.Context, actor identity.ActorContext) (RankList, error) {
	_, at, err := service.readContext(requestContext)
	if err != nil {
		return RankList{}, err
	}
	catalog, period, found, err := service.taskCatalog(requestContext, service.Fresh, actor.LogicalServerID, at)
	if err != nil {
		return RankList{}, err
	}
	if !found {
		return RankList{Rows: []domain.Display{}}, nil
	}
	rows, err := service.Store.TaskRangeTx(requestContext, service.Fresh, actor.LogicalServerID, period.Rotation.Number, 1, rankListSize)
	if err != nil {
		return RankList{}, err
	}
	result := RankList{Rows: []domain.Display{}}
	result.MyRank, _, err = service.Store.TaskRankOfTx(requestContext, service.Fresh, actor.LogicalServerID, period.Rotation.Number, domain.Occupant{Player: actor.PlayerID})
	if err != nil {
		return result, err
	}
	for _, row := range rows {
		display, err := service.taskDisplay(requestContext, service.Fresh, catalog, period, row.Occupant, at)
		if errors.Is(err, domain.ErrRefused) {
			continue
		}
		if err != nil {
			return result, err
		}
		result.Rows = append(result.Rows, display)
	}
	return result, nil
}
func (service Service) TaskRecordInfo(requestContext context.Context, actor identity.ActorContext, id int64) (RecordInfo, error) {
	record, found, err := service.Store.TaskRecordTx(requestContext, service.Fresh, id)
	if err != nil || !found || record.Record.Owner != actor.PlayerID {
		return RecordInfo{}, errors.Join(err, domain.ErrRefused)
	}
	fight, found, err := service.Store.ReadTaskFightTx(requestContext, service.Fresh, record.Record.AttemptID, false)
	if err != nil || !found {
		return RecordInfo{}, errors.Join(err, domain.ErrConflict)
	}
	_, at, err := service.readContext(requestContext)
	if err != nil {
		return RecordInfo{}, err
	}
	catalog, period, present, err := service.taskCatalog(requestContext, service.Fresh, actor.LogicalServerID, at)
	if err != nil {
		return RecordInfo{}, err
	}
	display := fight.Enemy
	if !record.Record.Attack {
		display, err = service.face(requestContext, catalog, actor.LogicalServerID, record.Record.Opponent, at)
		if err != nil {
			return RecordInfo{}, err
		}
	}
	info := RecordInfo{Opponent: display, AvengeType: 4}
	if present && period.Rotation.Number == record.PeriodNumber {
		display, err = service.taskDisplay(requestContext, service.Fresh, catalog, period, record.Record.Opponent, at)
		if errors.Is(err, domain.ErrRefused) {
			return info, nil
		}
		if err != nil {
			return info, err
		}
		rank, _, err := service.Store.TaskRankOfTx(requestContext, service.Fresh, actor.LogicalServerID, period.Rotation.Number, domain.Occupant{Player: actor.PlayerID})
		if err != nil {
			return info, err
		}
		info.Opponent = display
		info.AvengeType = catalog.AvengeType(rank, display.Rank)
		info.CanAvenge = !record.Record.Attack && !record.Record.Win && !record.Record.Opponent.IsRobot() && info.AvengeType == 0
	}
	return info, nil
}
func (service Service) TaskReport(requestContext context.Context, actor identity.ActorContext, key string) ([]byte, error) {
	id, err := ids.ParseUUID(key)
	if err != nil {
		return nil, domain.ErrInvalid
	}
	records, err := service.Store.TaskRecordsTx(requestContext, service.Fresh, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	retained := false
	for _, record := range records {
		retained = retained || record.Record.AttemptID == id
	}
	if !retained {
		return nil, domain.ErrRefused
	}
	now, err := service.Timed.Binder.Time.Now(requestContext)
	if err != nil {
		return nil, err
	}
	result, _, err := service.Combat.ReplayTx(requestContext, service.Fresh, id, reportRetention, now)
	return result.Report, err
}
