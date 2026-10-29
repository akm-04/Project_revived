package topfloor

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	ca "gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/combat"
	gen "gxb.local/backend/v2/internal/application/generation"
	cd "gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	domain "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
)

type TaskStartCommand struct {
	StartCommand
	Leader int64
}

func taskLocator(server identity.LogicalServerID, player identity.PlayerID) cd.Locator {
	return cd.Locator{DomainKind: "TOP_FLOOR_TASK", AuthorityScope: fmt.Sprintf("server:%d", server), DomainLocator: fmt.Sprintf("challenger:%d", player)}
}
func taskFingerprint(player identity.PlayerID, command TaskStartCommand) string {
	raw, _ := json.Marshal(struct {
		Player  identity.PlayerID
		Command TaskStartCommand
	}{player, command})
	digest := sha256.Sum256(raw)
	return hex.EncodeToString(digest[:])
}
func (service Service) StartTask(requestContext context.Context, actor identity.ActorContext, command TaskStartCommand, op operation.Context) (FightView, error) {
	if command.Validate() != nil || command.Leader < 0 {
		return FightView{}, domain.ErrInvalid
	}
	if !service.ready() {
		return FightView{}, domain.ErrUnavailable
	}
	// Fence before reading a previously admitted attempt, including terminal retries.
	if _, _, err := service.Timed.Run(requestContext, op, Profile(), tx.Options{}, retry(), nil, func(requestContext context.Context, scope gen.TimedScope) error {
		return service.Fence.FenceActorTx(requestContext, scope.Tx, actor, scope.Operation.DecisionAt())
	}); err != nil {
		return FightView{}, err
	}
	fingerprint := taskFingerprint(actor.PlayerID, command)
	latest, found, err := service.Store.LatestTaskFightTx(requestContext, service.Fresh, actor.PlayerID)
	if err != nil {
		return FightView{}, err
	}
	now, err := service.Timed.Binder.Time.Now(requestContext)
	if err != nil {
		return FightView{}, err
	}
	if found && latest.Fight.Fingerprint == fingerprint && (latest.Fight.Status == domain.StatusStarted || now.Sub(latest.Fight.StartedAt) < replayWindow) {
		return service.finishTask(requestContext, latest, op)
	}
	if found && latest.Fight.Status == domain.StatusStarted {
		if _, err = service.finishTask(requestContext, latest, op); err != nil {
			return FightView{}, err
		}
		pending, present, readErr := service.Store.ReadTaskFightTx(requestContext, service.Fresh, latest.Fight.AttemptID, false)
		if readErr != nil {
			return FightView{}, readErr
		}
		if !present || pending.Fight.Status == domain.StatusStarted {
			return FightView{}, domain.ErrRefused
		}
	}
	if err = service.SettleTaskDue(requestContext, actor.LogicalServerID, op); err != nil {
		return FightView{}, err
	}
	op, err = service.pin(requestContext, op)
	if err != nil {
		return FightView{}, err
	}
	var fight domain.TaskModeFight
	_, resolution, err := service.Timed.Run(requestContext, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), taskStartEvidence{service: service, actor: actor, fingerprint: fingerprint}, func(requestContext context.Context, scope gen.TimedScope) error {
		catalog, period, player, err := service.taskStateTx(requestContext, scope, actor)
		if err != nil {
			return err
		}
		at := scope.Operation.DecisionAt()
		formation, _, err := service.taskTeam(requestContext, scope.Tx, catalog, period, actor.PlayerID, domain.TaskModeDefense{Heroes: command.Formation, Pet: command.PetID, Leader: command.Leader}, at)
		if err != nil {
			return err
		}
		opponent, present := offered(player.Player, command.Enemy)
		if command.Avenge {
			opponent = domain.Occupant{Player: identity.PlayerID(int64(actor.LogicalServerID)*domain.RegionStride + command.Enemy)}
			records, readErr := service.Store.TaskRecordsTx(requestContext, scope.Tx, actor.PlayerID)
			if readErr != nil {
				return readErr
			}
			present = false
			for _, record := range records {
				if record.PeriodNumber == period.Rotation.Number && !record.Record.Attack && !record.Record.Win && record.Record.Opponent == opponent {
					present = true
				}
			}
		}
		if !present {
			return domain.ErrRefused
		}
		display, err := service.taskDisplay(requestContext, scope.Tx, catalog, period, opponent, at)
		if err != nil {
			return err
		}
		rank, _, err := service.Store.TaskRankOfTx(requestContext, scope.Tx, actor.LogicalServerID, period.Rotation.Number, domain.Occupant{Player: actor.PlayerID})
		if err != nil {
			return err
		}
		if command.Avenge && catalog.AvengeType(rank, display.Rank) != 0 {
			return domain.ErrRefused
		}
		next := player
		next.Player = catalog.Rolled(player.Player, at)
		if next.Player.TicketsLeft <= 0 || catalog.Cooling(next.Player, at) {
			return domain.ErrRefused
		}
		next.Player.TicketsLeft--
		next.Player.LastMatchAt = &at
		next.Player.UpdatedAt = at
		next.Player.StateVersion++
		if err = service.Store.SaveTaskPlayerTx(requestContext, scope.Tx, next, period, player.Player.StateVersion); err != nil {
			return err
		}
		battle := combat.BattleRequest{CampaignType: domain.TaskModeCampaignType, BattleID: domain.BattleID, TeamA: []combat.Participant{}, PetsA: []combat.Participant{}, PetsB: []combat.Participant{}, WavesB: [][]combat.Participant{{}}}
		for _, hero := range command.Formation {
			battle.TeamA = append(battle.TeamA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.HeroActor, Player: actor.PlayerID, Identity: hero})
		}
		if command.PetID > 0 {
			battle.PetsA = append(battle.PetsA, combat.Participant{Origin: cd.OwnedSelf, Kind: cd.PetActor, Player: actor.PlayerID, Identity: command.PetID})
		}
		leaderB := int64(0)
		if opponent.IsRobot() {
			heroes, err := catalog.TaskModes.RobotFormation(catalog, opponent.Robot, period.Rotation)
			if err != nil {
				return err
			}
			for index, hero := range heroes {
				parameters, _ := catalog.RobotHeroParams(hero.ID)
				local := int64(index + 1)
				parameters["partner_id"] = local
				battle.WavesB[0] = append(battle.WavesB[0], combat.Participant{Origin: cd.Template, Kind: cd.HeroActor, Identity: local, TemplateParams: parameters})
			}
			if period.Rotation.Mode == domain.TaskModeLeader {
				leaderB = 1
			}
		} else {
			defender, found, err := service.Store.ReadTaskPlayerTx(requestContext, scope.Tx, opponent.Player, period, false)
			if err != nil || !found {
				return errors.Join(err, domain.ErrRefused)
			}
			leaderB = defender.Leader
			for _, hero := range defender.Player.Defense {
				battle.WavesB[0] = append(battle.WavesB[0], combat.Participant{Origin: cd.OwnedForeign, Kind: cd.HeroActor, Player: opponent.Player, Identity: hero})
			}
			if defender.Player.DefensePet > 0 {
				battle.PetsB = append(battle.PetsB, combat.Participant{Origin: cd.OwnedForeign, Kind: cd.PetActor, Player: opponent.Player, Identity: defender.Player.DefensePet})
			}
		}
		rule, _ := catalog.TaskModes.Rule(period.Rotation.Mode)
		buffs := func(rows []map[string]any) ([]int64, error) {
			table, err := integerValue(rows[0]["table_id"])
			if err != nil {
				return nil, err
			}
			return rule.Buffs(catalog.TaskModes.HeroCamps[table])
		}
		buffsA, err := buffs(formation)
		if err != nil {
			return err
		}
		buffsB, err := buffs(display.Heroes)
		if err != nil {
			return err
		}
		parameters, err := cd.CanonicalJSON(map[string]any{"mode": period.Rotation.Mode, "buffs_a": buffsA, "buffs_b": buffsB, "leader_a": command.Leader, "leader_b": leaderB, "leader_buff_a": catalog.TaskModes.AttackingLeaderBuff, "leader_buff_b": catalog.TaskModes.DefendingLeaderBuff})
		if err != nil {
			return err
		}
		battle.Context = &cd.BattleContext{Transform: "TOP_FLOOR_TASK_V1", Parameters: parameters}
		// Rotation rules stay pinned separately; Combat freezes new actors against active content.
		battleRevision, bound := scope.Operation.Operation().Policies.Get("content")
		if !bound {
			return cd.ErrContentMismatch
		}
		coherent, err := ca.NewCoherentReadScope(tx.Scope{Tx: scope.Tx, Operation: scope.Operation.Operation(), Attempt: scope.Attempt, Options: scope.Options}, battleRevision, at)
		if err != nil {
			return err
		}
		started, err := service.Combat.StartTx(requestContext, scope.Tx, coherent, combat.StartRequest{Actor: actor, Locator: taskLocator(actor.LogicalServerID, actor.PlayerID), GenerationRef: domain.TaskModeContractID, StartFingerprint: fingerprint, ResultDeadline: at.Add(resultWindow), Battle: battle})
		if err != nil {
			return err
		}
		fight = domain.TaskModeFight{Fight: domain.Fight{AttemptID: started.Attempt.ID, Server: actor.LogicalServerID, Challenger: actor.PlayerID, Defender: opponent, Avenge: command.Avenge, Fingerprint: fingerprint, Formation: slices.Clone(command.Formation), PetID: command.PetID, ChallengerRank: rank, DefenderRank: display.Rank, StartedAt: at, Status: domain.StatusStarted, StateVersion: 1}, PeriodNumber: period.Rotation.Number, Mode: period.Rotation.Mode, Formation: formation, Enemy: display}
		return service.Store.InsertTaskFightTx(requestContext, scope.Tx, fight)
	})
	if err != nil {
		return FightView{}, err
	}
	if resolution.Reconciled {
		fight, err = (taskStartEvidence{service: service, actor: actor, fingerprint: fingerprint}).fight(requestContext)
		if err != nil {
			return FightView{}, err
		}
	}
	return service.finishTask(requestContext, fight, op)
}
func integerValue(value any) (int64, error) {
	var number json.Number
	raw, err := json.Marshal(value)
	if err != nil {
		return 0, err
	}
	if err = json.Unmarshal(raw, &number); err != nil {
		return 0, err
	}
	return number.Int64()
}

type taskStartEvidence struct {
	service     Service
	actor       identity.ActorContext
	fingerprint string
}

func (evidence taskStartEvidence) fight(requestContext context.Context) (domain.TaskModeFight, error) {
	attempt, found, err := evidence.service.Combat.StartEvidenceTx(requestContext, evidence.service.Fresh, taskLocator(evidence.actor.LogicalServerID, evidence.actor.PlayerID), evidence.fingerprint)
	if err != nil || !found {
		return domain.TaskModeFight{}, errors.Join(err, domain.ErrConflict)
	}
	fight, found, err := evidence.service.Store.ReadTaskFightTx(requestContext, evidence.service.Fresh, attempt.ID, false)
	if err != nil || !found || fight.Fight.Fingerprint != evidence.fingerprint {
		return domain.TaskModeFight{}, errors.Join(err, domain.ErrConflict)
	}
	return fight, nil
}
func (evidence taskStartEvidence) ResolveTimed(requestContext context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	fight, err := evidence.fight(requestContext)
	if err != nil {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: fight.Fight.AttemptID}, nil
}
func (service Service) finishTask(requestContext context.Context, fight domain.TaskModeFight, parent operation.Context) (FightView, error) {
	if fight.Fight.Status == domain.StatusStarted {
		_, err := service.Combat.Resolve(requestContext, parent, fight.Fight.AttemptID)
		if errors.Is(err, cd.ErrResolverPermanent) {
			return FightView{}, errors.Join(err, service.closeTask(requestContext, fight, parent))
		}
		if err != nil && !errors.Is(err, cd.ErrNotReady) && !errors.Is(err, cd.ErrResolverRetryable) {
			return FightView{}, err
		}
		if err == nil {
			if err = service.settleTask(requestContext, fight, parent); err != nil {
				return FightView{}, err
			}
			fight, _, err = service.Store.ReadTaskFightTx(requestContext, service.Fresh, fight.Fight.AttemptID, false)
			if err != nil {
				return FightView{}, err
			}
		}
	}
	if fight.Fight.Status == domain.StatusClosed {
		return FightView{}, domain.ErrRefused
	}
	view := FightView{Formation: fight.Formation, Enemy: fight.Enemy}
	if fight.Fight.Status != domain.StatusSettled {
		return view, nil
	}
	result, err := service.Combat.ResultTx(requestContext, service.Fresh, fight.Fight.AttemptID)
	view.Report, view.Win = result.Report, fight.Fight.Outcome.Win
	return view, err
}
func (service Service) settleTask(requestContext context.Context, fight domain.TaskModeFight, parent operation.Context) error {
	op, err := child(parent, "task-settle:"+fight.Fight.AttemptID.String())
	if err != nil {
		return err
	}
	if err = service.SettleTaskDue(requestContext, fight.Fight.Server, op); err != nil {
		return err
	}
	_, _, err = service.Timed.Run(requestContext, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), taskFightEvidence{service: service, attempt: fight.Fight.AttemptID, status: domain.StatusSettled}, func(requestContext context.Context, scope gen.TimedScope) error {
		if _, found, err := service.Store.ReadLadderTx(requestContext, scope.Tx, fight.Fight.Server, true); err != nil || !found {
			return errors.Join(err, domain.ErrConflict)
		}
		period, found, err := service.Store.ReadTaskPeriodTx(requestContext, scope.Tx, fight.Fight.Server, fight.PeriodNumber, true)
		if err != nil || !found {
			return errors.Join(err, domain.ErrConflict)
		}
		current, found, err := service.Store.ReadTaskFightTx(requestContext, scope.Tx, fight.Fight.AttemptID, true)
		if err != nil || !found {
			return errors.Join(err, domain.ErrConflict)
		}
		if current.Fight.Status != domain.StatusStarted {
			return nil
		}
		at := scope.Operation.DecisionAt()
		if len(period.Unsettled(at)) > 0 {
			return ErrSettlementDue
		}
		owners := []identity.PlayerID{current.Fight.Challenger}
		if !current.Fight.Defender.IsRobot() {
			owners = append(owners, current.Fight.Defender.Player)
		}
		slices.Sort(owners)
		players := map[identity.PlayerID]domain.TaskModePlayer{}
		for _, owner := range owners {
			player, found, err := service.Store.ReadTaskPlayerTx(requestContext, scope.Tx, owner, period, true)
			if err != nil || !found {
				return errors.Join(err, domain.ErrConflict)
			}
			players[owner] = player
		}
		challengerRank, _, err := service.Store.TaskRankOfTx(requestContext, scope.Tx, current.Fight.Server, current.PeriodNumber, domain.Occupant{Player: current.Fight.Challenger})
		if err != nil {
			return err
		}
		defenderRank, _, err := service.Store.TaskRankOfTx(requestContext, scope.Tx, current.Fight.Server, current.PeriodNumber, current.Fight.Defender)
		if err != nil {
			return err
		}
		terminal, err := service.Combat.TerminalTx(requestContext, scope.Tx, combat.TerminalRequest{Locator: taskLocator(current.Fight.Server, current.Fight.Challenger), GenerationRef: domain.TaskModeContractID, TerminalKind: "TOP_FLOOR_TASK_SETTLED", SemanticReceiptID: "top-floor-task:" + current.Fight.AttemptID.String(), At: at})
		if err != nil {
			return err
		}
		requestContext, err = service.Facts.PrepareTx(requestContext, scope.Tx, current.Fight.Challenger, scope.Operation)
		if err != nil {
			return err
		}
		outcome := (domain.Catalog{}).Decide(terminal.Resolution.Outcome.Star, challengerRank, defenderRank, players[current.Fight.Challenger].Player.BestRank)
		outcome.AwardCrystal = 0
		if outcome.ChallengerAfter != challengerRank {
			if err = service.Store.SwapTaskRanksTx(requestContext, scope.Tx, current.Fight.Server, current.PeriodNumber, domain.Ranked{Rank: challengerRank, Occupant: domain.Occupant{Player: current.Fight.Challenger}}, domain.Ranked{Rank: defenderRank, Occupant: current.Fight.Defender}); err != nil {
				return err
			}
		}
		for _, owner := range owners {
			player := players[owner]
			previous := player.Player.StateVersion
			player.Player.Fights++
			won := outcome.Win
			if owner != current.Fight.Challenger {
				won = !won
			}
			if won {
				player.Player.Wins++
			}
			if owner == current.Fight.Challenger {
				player.Player.BestRank = outcome.BestAfter
			}
			player.Player.StateVersion++
			player.Player.UpdatedAt = at
			if err = service.Store.SaveTaskPlayerTx(requestContext, scope.Tx, player, period, previous); err != nil {
				return err
			}
			opponent := current.Fight.Defender
			if owner != current.Fight.Challenger {
				opponent = domain.Occupant{Player: current.Fight.Challenger}
			}
			if err = service.Store.InsertTaskRecordTx(requestContext, scope.Tx, domain.TaskModeRecord{Record: domain.Record{Owner: owner, AttemptID: current.Fight.AttemptID, Attack: owner == current.Fight.Challenger, Win: won, Opponent: opponent, At: at}, PeriodNumber: current.PeriodNumber, Mode: current.Mode}, 10); err != nil {
				return err
			}
		}
		if err = service.Facts.RecordTx(requestContext, scope.Tx, scope.Operation.Operation(), objective.Fact{PlayerID: current.Fight.Challenger, SourceDomain: "top-floor-task", SourceBusinessKey: current.Fight.AttemptID.String(), Kind: objective.PVPFightKind, Delta: 1}); err != nil {
			return err
		}
		previous := period.Ladder.StateVersion
		period.Ladder.StateVersion++
		period.Ladder.UpdatedAt = at
		if err = service.Store.SaveTaskPeriodTx(requestContext, scope.Tx, period, previous); err != nil {
			return err
		}
		previous = current.Fight.StateVersion
		current.Fight.Status = domain.StatusSettled
		current.Fight.Outcome = &outcome
		current.Fight.SettledAt = &at
		current.Fight.StateVersion++
		return service.Store.FinishTaskFightTx(requestContext, scope.Tx, current, previous)
	})
	return err
}
func (service Service) closeTask(requestContext context.Context, fight domain.TaskModeFight, parent operation.Context) error {
	op, err := child(parent, "task-close:"+fight.Fight.AttemptID.String())
	if err != nil {
		return err
	}
	_, _, err = service.Timed.Run(requestContext, op, Profile(), tx.Options{Isolation: tx.RepeatableRead}, retry(), taskFightEvidence{service: service, attempt: fight.Fight.AttemptID, status: domain.StatusClosed}, func(requestContext context.Context, scope gen.TimedScope) error {
		current, found, err := service.Store.ReadTaskFightTx(requestContext, scope.Tx, fight.Fight.AttemptID, true)
		if err != nil || !found {
			return errors.Join(err, domain.ErrConflict)
		}
		if current.Fight.Status != domain.StatusStarted {
			return nil
		}
		at := scope.Operation.DecisionAt()
		if _, err = service.Combat.CloseTx(requestContext, scope.Tx, combat.TerminalRequest{Locator: taskLocator(current.Fight.Server, current.Fight.Challenger), GenerationRef: domain.TaskModeContractID, TerminalKind: "TOP_FLOOR_TASK_CLOSED", SemanticReceiptID: "top-floor-task:" + current.Fight.AttemptID.String(), At: at}); err != nil {
			return err
		}
		previous := current.Fight.StateVersion
		current.Fight.Status = domain.StatusClosed
		current.Fight.SettledAt = &at
		current.Fight.StateVersion++
		return service.Store.FinishTaskFightTx(requestContext, scope.Tx, current, previous)
	})
	return err
}

type taskFightEvidence struct {
	service Service
	attempt ids.UUID
	status  string
}

func (evidence taskFightEvidence) ResolveTimed(requestContext context.Context, _ gen.TimedResolutionRequest) (tx.Resolution, error) {
	fight, found, err := evidence.service.Store.ReadTaskFightTx(requestContext, evidence.service.Fresh, evidence.attempt, false)
	if err != nil {
		return tx.Resolution{}, err
	}
	if !found || fight.Fight.Status != evidence.status {
		return tx.Resolution{State: tx.ResolutionUnknown}, nil
	}
	return tx.Resolution{State: tx.ResolutionCommitted, Evidence: fight.Fight.AttemptID}, nil
}
