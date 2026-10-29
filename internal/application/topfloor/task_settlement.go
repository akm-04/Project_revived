package topfloor

import (
	"context"
	"errors"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func (service Service) SettleTaskDue(requestContext context.Context, server identity.LogicalServerID, parent operation.Context) error {
	if !service.ready() {
		return domain.ErrUnavailable
	}
	numbers, err := service.Store.TaskPeriodsTx(requestContext, service.Fresh, server)
	if err != nil {
		return err
	}
	now, err := service.Timed.Binder.Time.Now(requestContext)
	if err != nil {
		return err
	}
	for _, number := range numbers {
		period, found, err := service.Store.ReadTaskPeriodTx(requestContext, service.Fresh, server, number, false)
		if err != nil || !found {
			return errors.Join(err, domain.ErrConflict)
		}
		for _, day := range period.Unsettled(now) {
			op, err := child(parent, fmt.Sprintf("task-day:%d:%d:%d", server, number, day))
			if err != nil {
				return err
			}
			_, _, err = service.Timed.Run(requestContext, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), taskDayEvidence{service: service, server: server, period: number, day: day}, func(requestContext context.Context, scope gen.TimedScope) error {
				if _, found, err := service.Store.ReadLadderTx(requestContext, scope.Tx, server, true); err != nil || !found {
					return errors.Join(err, domain.ErrConflict)
				}
				current, found, err := service.Store.ReadTaskPeriodTx(requestContext, scope.Tx, server, number, true)
				if err != nil || !found {
					return errors.Join(err, domain.ErrConflict)
				}
				if current.Ladder.SettledDay >= day {
					return nil
				}
				if current.Ladder.SettledDay != day-1 {
					return domain.ErrConflict
				}
				catalog, err := service.Content.TopFloorCatalogTx(requestContext, scope.Tx, current.Ladder.ContentRevision)
				if err != nil {
					return err
				}
				if catalog.TaskModes == nil {
					return domain.ErrUnavailable
				}
				at := scope.Operation.DecisionAt()
				calendar := catalog.TaskModes.Calendar()
				if at.Before(calendar.CutoffInstant(day)) {
					return domain.ErrConflict
				}
				ranks, err := service.Store.TaskRangeTx(requestContext, scope.Tx, server, number, 1, current.Ladder.Size)
				if err != nil {
					return err
				}
				settlement := domain.DaySettlement{Server: server, Day: day, CutoffAt: calendar.CutoffInstant(day), SettledAt: at, LadderVersion: current.Ladder.StateVersion, ContentRevision: current.Ladder.ContentRevision}
				rule, _ := catalog.TaskModes.Rule(current.Rotation.Mode)
				for _, ranked := range ranks {
					if ranked.Occupant.IsRobot() {
						continue
					}
					entry := domain.DayRank{Player: ranked.Occupant.Player, Rank: ranked.Rank}
					if lines := dailyLines(calendar, ranked.Rank); len(lines) > 0 {
						mail, _, err := service.Mail.DeliverTx(requestContext, scope.Tx, i5.SettlementMailRequest{Recipient: entry.Player, SourceKind: "TOP_FLOOR_TASK_DAY", SourceKey: fmt.Sprintf("%d:%d:%d:%d", server, number, day, entry.Player), Title: fmt.Sprintf(catalog.TaskModes.MailTitle, rule.Title), Body: fmt.Sprintf(catalog.TaskModes.MailText, rule.Title, rule.Title, entry.Rank), Sender: catalog.TaskModes.MailSender, PolicyVersion: domain.TaskModeContractID, Lines: lines, At: at})
						if err != nil {
							return err
						}
						entry.Mail = &mail.MailUUID
					}
					settlement.Ranks = append(settlement.Ranks, entry)
				}
				if err = service.Store.InsertTaskDayTx(requestContext, scope.Tx, domain.TaskModeDay{Settlement: settlement, PeriodNumber: number}); err != nil {
					return err
				}
				previous := current.Ladder.StateVersion
				current.Ladder.SettledDay = day
				current.Ladder.StateVersion++
				current.Ladder.UpdatedAt = at
				return service.Store.SaveTaskPeriodTx(requestContext, scope.Tx, current, previous)
			})
			if err != nil {
				return err
			}
		}
	}
	return nil
}

type taskDayEvidence struct {
	service Service
	server  identity.LogicalServerID
	period  int64
	day     int64
}

func (evidence taskDayEvidence) ResolveTimed(requestContext context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	period, found, err := evidence.service.Store.ReadTaskPeriodTx(requestContext, evidence.service.Fresh, evidence.server, evidence.period, false)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !found || period.Ladder.SettledDay < evidence.day {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: period.Ladder.SettledDay}, nil
}
