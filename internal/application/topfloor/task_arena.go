package topfloor

import (
	"context"
	"errors"
	"fmt"
	gen "gxb.local/backend/v2/internal/application/generation"
	"gxb.local/backend/v2/internal/domain/identity"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
	"strconv"
	"time"
)

type TaskArenaView struct {
	ArenaView
	Rotation domain.TaskModeRotation
	Leader   int64
}

func (service Service) taskCatalog(requestContext context.Context, query tx.Queryer, server identity.LogicalServerID, at time.Time) (domain.Catalog, domain.TaskModePeriod, bool, error) {
	revision, catalog, err := service.catalogTx(requestContext, query)
	if err != nil {
		return catalog, domain.TaskModePeriod{}, false, err
	}
	if catalog.TaskModes == nil {
		return catalog, domain.TaskModePeriod{}, false, domain.ErrUnavailable
	}
	proposal, err := catalog.TaskModes.NewPeriod(server, revision, at)
	if err != nil {
		return catalog, proposal, false, err
	}
	period, found, err := service.Store.ReadTaskPeriodTx(requestContext, query, server, proposal.Rotation.Number, false)
	if err != nil {
		return catalog, period, found, err
	}
	if !found {
		return catalog, proposal, false, nil
	}
	catalog, err = service.Content.TopFloorCatalogTx(requestContext, query, period.Ladder.ContentRevision)
	if err == nil && catalog.TaskModes == nil {
		err = domain.ErrUnavailable
	}
	return catalog, period, true, err
}
func (service Service) taskStateTx(requestContext context.Context, scope gen.TimedScope, actor identity.ActorContext) (domain.Catalog, domain.TaskModePeriod, domain.TaskModePlayer, error) {
	at := scope.Operation.DecisionAt()
	if err := service.Fence.FenceActorTx(requestContext, scope.Tx, actor, at); err != nil {
		return domain.Catalog{}, domain.TaskModePeriod{}, domain.TaskModePlayer{}, err
	}
	if _, found, err := service.Store.ReadLadderTx(requestContext, scope.Tx, actor.LogicalServerID, true); err != nil || !found {
		return domain.Catalog{}, domain.TaskModePeriod{}, domain.TaskModePlayer{}, errors.Join(err, domain.ErrRefused)
	}
	catalog, period, found, err := service.taskCatalog(requestContext, scope.Tx, actor.LogicalServerID, at)
	if err != nil {
		return catalog, period, domain.TaskModePlayer{}, err
	}
	if err = service.open(requestContext, scope.Tx, catalog, actor.PlayerID, at); err != nil {
		return catalog, period, domain.TaskModePlayer{}, err
	}
	eligibility, err := service.TaskModeEligibilityTx(requestContext, scope.Tx, *catalog.TaskModes, actor, at)
	if err != nil {
		return catalog, period, domain.TaskModePlayer{}, err
	}
	if !eligibility.Eligible {
		return catalog, period, domain.TaskModePlayer{}, domain.ErrRefused
	}
	if !found {
		if err = service.Store.CreateTaskPeriodTx(requestContext, scope.Tx, period); err != nil {
			return catalog, period, domain.TaskModePlayer{}, err
		}
	}
	if len(period.Unsettled(at)) > 0 {
		return catalog, period, domain.TaskModePlayer{}, ErrSettlementDue
	}
	player, found, err := service.Store.ReadTaskPlayerTx(requestContext, scope.Tx, actor.PlayerID, period, true)
	if err != nil {
		return catalog, period, player, err
	}
	if found {
		return catalog, period, player, nil
	}
	player = domain.TaskModePlayer{PeriodNumber: period.Rotation.Number, Player: catalog.NewPlayer(actor.PlayerID, actor.LogicalServerID, period.Ladder.ContentRevision, period.Ladder.Size+1, at)}
	rule, _ := catalog.TaskModes.Rule(period.Rotation.Mode)
	if !rule.ResetDefense {
		preference, present, readErr := service.Store.TaskPreferenceTx(requestContext, scope.Tx, actor.PlayerID, rule.ID)
		if readErr != nil {
			return catalog, period, player, readErr
		}
		if present {
			if _, _, validation := service.taskTeam(requestContext, scope.Tx, catalog, period, actor.PlayerID, preference, at); validation == nil {
				player.Player.Defense, player.Player.DefensePet, player.Leader = preference.Heroes, preference.Pet, preference.Leader
			}
		}
	}
	if err = service.Store.AppendTaskPlayerTx(requestContext, scope.Tx, actor.LogicalServerID, period.Rotation.Number, player.Player.BestRank, actor.PlayerID); err != nil {
		return catalog, period, player, err
	}
	previous := period.Ladder.StateVersion
	period.Ladder.Size++
	period.Ladder.StateVersion++
	period.Ladder.UpdatedAt = at
	if err = service.Store.SaveTaskPeriodTx(requestContext, scope.Tx, period, previous); err != nil {
		return catalog, period, player, err
	}
	return catalog, period, player, service.Store.InsertTaskPlayerTx(requestContext, scope.Tx, player, period)
}
func (service Service) taskTeam(requestContext context.Context, query tx.Queryer, catalog domain.Catalog, period domain.TaskModePeriod, player identity.PlayerID, defense domain.TaskModeDefense, at time.Time) ([]map[string]any, map[string]any, error) {
	rows, pet, err := service.team(requestContext, query, player, defense.Heroes, defense.Pet, at)
	if err != nil {
		return nil, nil, err
	}
	tables := make([]int64, 0, len(rows))
	for _, row := range rows {
		table, parseErr := strconv.ParseInt(fmt.Sprint(row["table_id"]), 10, 64)
		if parseErr != nil {
			return nil, nil, domain.ErrConflict
		}
		tables = append(tables, table)
	}
	heroes, err := catalog.TaskModes.Heroes(defense.Heroes, tables)
	if err != nil {
		return nil, nil, err
	}
	rule, found := catalog.TaskModes.Rule(period.Rotation.Mode)
	if !found {
		return nil, nil, domain.ErrUnavailable
	}
	if err = rule.ValidateFormation(heroes, defense.Pet, defense.Leader, period.Rotation.Submode); err != nil {
		return nil, nil, err
	}
	return rows, pet, nil
}
func (service Service) taskDisplay(requestContext context.Context, query tx.Queryer, catalog domain.Catalog, period domain.TaskModePeriod, occupant domain.Occupant, at time.Time) (domain.Display, error) {
	rank, found, err := service.Store.TaskRankOfTx(requestContext, query, period.Ladder.Server, period.Rotation.Number, occupant)
	if err != nil || !found {
		return domain.Display{}, errors.Join(err, domain.ErrRefused)
	}
	if occupant.IsRobot() {
		team, _ := catalog.Team(occupant.Robot)
		heroes, err := catalog.TaskModes.RobotFormation(catalog, occupant.Robot, period.Rotation)
		if err != nil {
			return domain.Display{}, err
		}
		display := domain.Display{Occupant: occupant, Rank: rank, Name: catalog.RobotName(occupant.Robot), Level: team.Level, AvatarID: catalog.RobotAvatarID, FrameID: catalog.RobotFrameID}
		for _, hero := range heroes {
			parameters, _ := catalog.RobotHeroParams(hero.ID)
			display.Heroes = append(display.Heroes, parameters)
		}
		return display, nil
	}
	display, err := service.playerDisplay(requestContext, query, occupant)
	if err != nil {
		return display, err
	}
	display.Rank = rank
	player, found, err := service.Store.ReadTaskPlayerTx(requestContext, query, occupant.Player, period, false)
	if err != nil || !found {
		return display, errors.Join(err, domain.ErrRefused)
	}
	display.Wins = player.Player.Wins
	display.Heroes, display.Pet, err = service.taskTeam(requestContext, query, catalog, period, occupant.Player, domain.TaskModeDefense{Heroes: player.Player.Defense, Pet: player.Player.DefensePet, Leader: player.Leader}, at)
	display.Force = teamForce(display.Heroes)
	return display, err
}
func (service Service) taskOffers(requestContext context.Context, query tx.Queryer, catalog domain.Catalog, period domain.TaskModePeriod, player domain.Player, rank int64, at time.Time) ([]domain.Occupant, error) {
	result := []domain.Occupant{}
	seen := map[int64]bool{}
	for _, probe := range catalog.OfferRanks(player.Server, player.PlayerID, rank, player.TicketDay, player.RefreshCount) {
		if len(probe) == 0 {
			continue
		}
		low, high := slices.Min(probe), slices.Max(probe)
		rows, err := service.Store.TaskRangeTx(requestContext, query, player.Server, period.Rotation.Number, low, high)
		if err != nil {
			return nil, err
		}
		byRank := map[int64]domain.Occupant{}
		for _, row := range rows {
			byRank[row.Rank] = row.Occupant
		}
		for _, candidate := range probe {
			occupant, found := byRank[candidate]
			if !found || occupant.Player == player.PlayerID || seen[occupant.TableID()] {
				continue
			}
			if _, err = service.taskDisplay(requestContext, query, catalog, period, occupant, at); errors.Is(err, domain.ErrRefused) {
				continue
			} else if err != nil {
				return nil, err
			}
			result = append(result, occupant)
			seen[occupant.TableID()] = true
			break
		}
		if len(result) == 3 {
			break
		}
	}
	return result, nil
}
func (service Service) LoadTask(requestContext context.Context, actor identity.ActorContext, op operation.Context, refresh bool) (TaskArenaView, error) {
	var result TaskArenaView
	if !service.ready() {
		return result, domain.ErrUnavailable
	}
	if err := service.SettleTaskDue(requestContext, actor.LogicalServerID, op); err != nil {
		return result, err
	}
	_, _, err := service.Timed.Run(requestContext, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		catalog, period, player, err := service.taskStateTx(requestContext, scope, actor)
		if err != nil {
			return err
		}
		at := scope.Operation.DecisionAt()
		rank, _, err := service.Store.TaskRankOfTx(requestContext, scope.Tx, actor.LogicalServerID, period.Rotation.Number, domain.Occupant{Player: actor.PlayerID})
		if err != nil {
			return err
		}
		next := player
		next.Player = catalog.Rolled(player.Player, at)
		if refresh {
			next.Player.RefreshCount++
		}
		next.Player.Offered, err = service.taskOffers(requestContext, scope.Tx, catalog, period, next.Player, rank, at)
		if err != nil {
			return err
		}
		next.Player.StateVersion++
		next.Player.UpdatedAt = at
		if err = service.Store.SaveTaskPlayerTx(requestContext, scope.Tx, next, period, player.Player.StateVersion); err != nil {
			return err
		}
		result = TaskArenaView{ArenaView: ArenaView{Player: next.Player, Rank: rank, ServerTime: at}, Rotation: period.Rotation, Leader: next.Leader}
		for _, occupant := range next.Player.Offered {
			display, readErr := service.taskDisplay(requestContext, scope.Tx, catalog, period, occupant, at)
			if readErr != nil {
				return readErr
			}
			result.Enemies = append(result.Enemies, display)
		}
		return nil
	})
	return result, err
}
func (service Service) SaveTaskDefense(requestContext context.Context, actor identity.ActorContext, defense domain.TaskModeDefense, op operation.Context) error {
	if !service.ready() {
		return domain.ErrUnavailable
	}
	if err := service.SettleTaskDue(requestContext, actor.LogicalServerID, op); err != nil {
		return err
	}
	_, _, err := service.Timed.Run(requestContext, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		catalog, period, player, err := service.taskStateTx(requestContext, scope, actor)
		if err != nil {
			return err
		}
		at := scope.Operation.DecisionAt()
		if _, _, err = service.taskTeam(requestContext, scope.Tx, catalog, period, actor.PlayerID, defense, at); err != nil {
			return err
		}
		next := player
		next.Player.Defense, next.Player.DefensePet, next.Leader = slices.Clone(defense.Heroes), defense.Pet, defense.Leader
		next.Player.DefenseSetAt = &at
		next.Player.StateVersion++
		next.Player.UpdatedAt = at
		if err = service.Store.SaveTaskPlayerTx(requestContext, scope.Tx, next, period, player.Player.StateVersion); err != nil {
			return err
		}
		return service.Store.SaveTaskPreferenceTx(requestContext, scope.Tx, actor.PlayerID, period.Rotation.Mode, defense)
	})
	return err
}
func (service Service) TaskSchedule(requestContext context.Context) ([]domain.TaskModeRotation, error) {
	catalog, at, err := service.readContext(requestContext)
	if err != nil {
		return nil, err
	}
	if catalog.TaskModes == nil {
		return nil, domain.ErrUnavailable
	}
	return catalog.TaskModes.ScheduleFrom(at)
}
