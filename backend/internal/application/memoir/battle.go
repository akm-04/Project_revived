package memoir

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/application/characterasset"
	applicationcombat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"reflect"
	"time"
)

var reportPolicy = combat.ReportPolicy{ID: "I9_MEMOIR_REPORT_V1", Version: 1, Formation: true, Pet: true, CompleteEnemies: true, LivingWinner: true, WinClearsEnemies: true, MaxHP: 1e12, HPPerFrozen: 2, SelectFrozenRoster: true, ReportedWave: true}

func locator(actor identity.ActorContext) combat.Locator {
	return combat.Locator{DomainKind: "MEMOIR", AuthorityScope: fmt.Sprintf("server:%d", actor.LogicalServerID), DomainLocator: fmt.Sprint(actor.PlayerID)}
}
func (mode Mode) withdraw(ctx context.Context, actor identity.ActorContext, current scope, state *memoir.State) error {
	if state.Pending == nil {
		return nil
	}
	if state.Pending.Kind == memoir.Player {
		return memoir.ErrRefused
	}
	pending := state.Pending
	_, err := mode.Combat.CloseTx(ctx, current.timed.Tx, applicationcombat.TerminalRequest{Locator: locator(actor), GenerationRef: pending.Generation, TerminalKind: "MEMOIR_WITHDRAWN", SemanticReceiptID: "memoir-close:" + pending.Attempt, At: current.timed.Operation.DecisionAt()})
	if err == nil {
		state.Pending = nil
	}
	return err
}
func encounter(state memoir.State, position int) (int64, int64, error) {
	if !state.Active() || !state.Board.CanInteract(position) {
		return 0, 0, memoir.ErrRefused
	}
	kind := state.Board.Cells[position-1]
	if kind != memoir.Guardian && kind != memoir.Monster && kind != memoir.Player {
		return 0, 0, memoir.ErrRefused
	}
	return kind, state.Board.Enemies[position], nil
}
func (mode Mode) EnemyInfo(ctx context.Context, actor identity.ActorContext, position int, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "enemy_info", position, operationContext, func(_ context.Context, _ scope, state *memoir.State) (map[string]any, error) {
		kind, identifier, err := encounter(*state, position)
		if err != nil {
			return nil, err
		}
		carry := state.Enemies[position]
		if carry.Round == 0 {
			carry.Round = 1
		}
		if carry.Statuses == nil {
			carry.Statuses = map[int64]combat.ActorStatus{}
		}
		enemy := map[string]any{"enemy_status": enemyStatusProjection(carry.Statuses), "round": carry.Round}
		if kind == memoir.Player {
			opponent, found := state.Opponents[int(identifier)]
			if !found {
				return nil, memoir.ErrUnavailable
			}
			raw, err := json.Marshal(opponent)
			if err != nil {
				return nil, err
			}
			if err = json.Unmarshal(raw, &enemy); err != nil {
				return nil, err
			}
			enemy["enemy_status"], enemy["round"] = enemyStatusProjection(carry.Statuses), carry.Round
		}
		return map[string]any{"enemy_info": enemy}, nil
	})
}
func (mode Mode) StartFight(ctx context.Context, actor identity.ActorContext, position int, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "start_fight", position, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		kind, identifier, err := encounter(*state, position)
		if err != nil {
			return nil, err
		}
		if kind == memoir.Player {
			return nil, memoir.ErrRefused
		}
		if state.Pending != nil && state.Pending.Grid == position && current.timed.Operation.DecisionAt().Unix() < state.Pending.Deadline {
			return map[string]any{}, nil
		}
		if err = mode.withdraw(ctx, actor, current, state); err != nil {
			return nil, err
		}
		revision, err := mode.startRevision(ctx, current)
		if err != nil {
			return nil, err
		}
		battle := applicationcombat.BattleRequest{CampaignType: 53, BattleID: identifier}
		if kind == memoir.Guardian {
			battle.BattleID = current.catalog.BossBattle(identifier)
		}
		waves := current.catalog.Fights[battle.BattleID]
		if len(waves) == 0 {
			return nil, memoir.ErrUnavailable
		}
		for _, identifier := range current.heroes {
			if state.Alive(identifier) {
				battle.TeamA = append(battle.TeamA, applicationcombat.Participant{Origin: combat.OwnedSelf, Kind: combat.HeroActor, Player: actor.PlayerID, Identity: identifier})
			}
		}
		if len(battle.TeamA) == 0 {
			return nil, memoir.ErrRefused
		}
		for _, identifier := range current.pets {
			battle.PetsA = append(battle.PetsA, applicationcombat.Participant{Origin: combat.OwnedSelf, Kind: combat.PetActor, Player: actor.PlayerID, Identity: identifier})
		}
		for _, wave := range waves {
			participants := make([]applicationcombat.Participant, 0, len(wave))
			for _, identifier := range wave {
				participants = append(participants, applicationcombat.Participant{Origin: combat.Template, Kind: combat.HeroActor, Identity: identifier, TemplateParams: map[string]any{"table_id": identifier}})
			}
			battle.WavesB = append(battle.WavesB, participants)
		}
		carry := state.Enemies[position]
		if carry.Round == 0 {
			carry.Round = 1
		}
		parameters, err := combat.CanonicalJSON(map[string]any{"first_wave": carry.Round, "heroes_status": state.Heroes, "enemy_status": carry.Statuses})
		if err != nil {
			return nil, err
		}
		battle.Context = &combat.BattleContext{Transform: "MEMOIR_CARRY_V1", Parameters: parameters}
		state.Sequence++
		generation := fmt.Sprintf("%s/%d/%d", state.Occurrence, state.Floor, state.Sequence)
		coherent, err := characterasset.NewCoherentReadScope(tx.Scope{Tx: current.timed.Tx, Operation: current.timed.Operation.Operation(), Attempt: current.timed.Attempt, Options: current.timed.Options}, revision, current.timed.Operation.DecisionAt())
		if err != nil {
			return nil, err
		}
		fingerprint, err := receipt.FingerprintRequest(struct {
			Generation string
			Grid       int
		}{generation, position})
		if err != nil {
			return nil, err
		}
		deadline := current.timed.Operation.DecisionAt().Add(time.Duration(memoir.ResultWindowSeconds) * time.Second)
		started, err := mode.Combat.StartTx(ctx, current.timed.Tx, coherent, applicationcombat.StartRequest{Actor: actor, Locator: locator(actor), GenerationRef: generation, StartFingerprint: fmt.Sprintf("%x", fingerprint), ResultDeadline: deadline, Battle: battle, TrustProfile: combat.ClientFullReportAttested, Replay: combat.ReplaySpec{Response: combat.ReplayFightExist, ErrorCode: combat.FightExistCode}, Package: func(_ *combat.Stream) (any, error) {
			return map[string]any{"heroes_status": state.Heroes, "enemies_status": carry.Statuses, "round": carry.Round}, nil
		}})
		if err != nil {
			return nil, err
		}
		pending := &memoir.Pending{Attempt: started.Attempt.ID.String(), Generation: generation, Revision: state.Revision, Grid: position, Kind: kind, FirstWave: carry.Round, Deadline: deadline.Unix(), Rewards: freezeRewards(current, *state, kind)}
		state.Pending = pending
		index := 1
		if kind == memoir.Guardian {
			index = 0
		}
		frozen, err := frozenOperation(current, revision)
		if err != nil {
			return nil, err
		}
		if _, err = mode.Energy.DebitTemporalTx(ctx, current.timed.Tx, actor.PlayerID, "energy", current.catalog.Floors[state.Floor-1].Energy[index], frozen); err != nil {
			return nil, err
		}
		return map[string]any{}, nil
	})
}
func (mode Mode) startRevision(ctx context.Context, current scope) (string, error) {
	revision, err := mode.Content.ActiveRevision(ctx, current.timed.Tx)
	if err != nil {
		return "", err
	}
	if revision == current.revision {
		return revision, nil
	}
	catalog, err := mode.Content.MemoirCatalogTx(ctx, current.timed.Tx, revision)
	if err != nil {
		return "", err
	}
	if catalog.SourceArchive != current.catalog.SourceArchive || !reflect.DeepEqual(catalog, current.catalog) {
		return "", memoir.ErrUnavailable
	}
	return revision, nil
}
func freezeRewards(current scope, state memoir.State, kind int64) []campaign.Item {
	index := 1
	key := current.catalog.SmallKey
	if kind == memoir.Guardian {
		index = 0
		key = current.catalog.BigKey
	}
	if kind == memoir.Player {
		index = 2
	}
	girl, _ := current.catalog.Girl(state.Girl)
	random := combat.NewStream(current.timed.Operation.Operation().Derive("memoir.encounter/v1", uint64(state.Sequence)))
	items := current.catalog.Draw(girl.Boxes[state.Floor-1][index], random)
	scrolls := current.catalog.Floors[state.Floor-1].Scroll[index]
	if scrolls > 0 {
		items = append(items, campaign.Item{ItemID: girl.Scroll, Num: scrolls})
	}
	return append(items, campaign.Item{ItemID: key, Num: 1})
}

type MonsterResult struct {
	Grid   int
	Report combat.Report
}

func (mode Mode) MonsterResult(ctx context.Context, actor identity.ActorContext, request MonsterResult, operationContext operation.Context) (map[string]any, error) {
	if !request.Report.Finite() {
		return nil, memoir.ErrInvalid
	}
	return mode.run(ctx, actor, "monster_result", request, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		pending := state.Pending
		if pending == nil {
			return fightExistReply(*state), nil
		}
		if pending.Kind == memoir.Player || pending.Grid != request.Grid {
			return nil, memoir.ErrRefused
		}
		attested, err := mode.Combat.AttestReportTx(ctx, current.timed.Tx, applicationcombat.ReportRequest{Locator: locator(actor), GenerationRef: pending.Generation, TerminalKind: "MEMOIR_MONSTER_RESULT", At: current.timed.Operation.DecisionAt(), Policy: reportPolicy, Report: request.Report})
		if err != nil {
			return nil, err
		}
		state.Pending = nil
		if attested.Drained || attested.Attestation.Verdict == combat.VerdictRejected {
			return fightExistReply(*state), nil
		}
		state.ApplyHeroes(request.Report.Allies)
		statuses := map[int64]combat.ActorStatus{}
		if attested.ReportProgress.NextWave == attested.ReportProgress.Wave {
			for _, status := range request.Report.Enemies {
				statuses[status.Identity] = status
			}
		}
		state.Enemies[request.Grid] = memoir.EnemyCarry{Round: attested.ReportProgress.NextWave, Statuses: statuses}
		awards := []map[string]any{}
		if request.Report.Win {
			if err = state.Board.ClearEnemy(request.Grid); err != nil {
				return nil, err
			}
			if pending.Kind == memoir.Guardian {
				state.MaxFloor[state.Girl] = max(state.MaxFloor[state.Girl], state.Floor)
			}
			awards, err = mode.grant(ctx, actor, current, *state, "battle/"+pending.Attempt, pending.Rewards)
			if err != nil {
				return nil, err
			}
			if err = state.AppendDrops(pending.Rewards); err != nil {
				return nil, err
			}
		}
		response := projection(*state)
		response["awards"] = awards
		state.LastGrid, state.LastResult = request.Grid, response
		return response, nil
	})
}

// fightExistReply keeps the projection: the stock fightMonster callback overwrites baseInfo from any 200 reply, error code or not.
func fightExistReply(state memoir.State) map[string]any {
	response := projection(state)
	response["error_code"] = int64(combat.FightExistCode)
	return response
}

func enemyStatusProjection(statuses map[int64]combat.ActorStatus) map[int64]map[string]any {
	result := map[int64]map[string]any{}
	for identifier, status := range statuses {
		result[identifier] = map[string]any{"hero_id": identifier, "health": int64(1), "hp": status.HP, "mp": status.MP, "is_reborn": status.Reborn}
	}
	return result
}
