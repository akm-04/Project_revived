package memoir

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"gxb.local/backend/v2/internal/application/characterasset"
	applicationcombat "gxb.local/backend/v2/internal/application/combat"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/receipt"
	"gxb.local/backend/v2/internal/foundation/tx"
	"slices"
	"sort"
	"strconv"
	"strings"
	"time"
)

type PlayerFight struct {
	Grid      int
	Formation []int64
	Pet       int64
}

func (request PlayerFight) valid() bool {
	if request.Grid < 1 || request.Grid > memoir.BoardCells || request.Pet < 0 || len(request.Formation) < 1 || len(request.Formation) > memoir.TeamLimit {
		return false
	}
	seen := map[int64]bool{}
	for _, identifier := range request.Formation {
		if identifier <= 0 || seen[identifier] {
			return false
		}
		seen[identifier] = true
	}
	return true
}
func (mode Mode) PlayerFight(ctx context.Context, actor identity.ActorContext, request PlayerFight, operationContext operation.Context) (map[string]any, error) {
	if !request.valid() {
		return nil, memoir.ErrInvalid
	}
	operationContext, err := mode.pin(ctx, operationContext)
	if err != nil {
		return nil, err
	}
	stored, present, err := mode.ReceiptRead.Find(ctx, receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "memoir", Operation: "player_start", SemanticKey: operationContext.ID.String()})
	if err != nil {
		return nil, err
	}
	if present {
		fingerprint, err := receipt.FingerprintRequest(request)
		if err != nil {
			return nil, err
		}
		if stored.RequestFingerprint != fingerprint {
			return nil, &receipt.ConflictError{Identity: stored.Identity}
		}
		var response map[string]any
		if err = json.Unmarshal(stored.ResultPayload, &response); err != nil {
			return nil, err
		}
		if response["battle_info"] != nil {
			return mode.run(ctx, actor, "player_replay", request, operationContext, func(_ context.Context, _ scope, _ *memoir.State) (map[string]any, error) { return response, nil })
		}
		attempt, valid := response["attempt"].(string)
		if !valid || attempt == "" {
			return nil, memoir.ErrUnavailable
		}
		return mode.playerReply(ctx, actor, attempt, operationContext)
	}
	prior, _, err := mode.Store.ReadTx(ctx, mode.Fresh, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	response, err := mode.resumePlayer(ctx, actor, operationContext)
	if err != nil {
		return nil, err
	}
	if prior.Pending != nil && prior.Pending.Kind == memoir.Player && prior.Pending.Grid == request.Grid && slices.Equal(prior.Pending.Formation, request.Formation) && prior.Pending.Pet == request.Pet {
		return mode.run(ctx, actor, "player_start", request, operationContext, func(_ context.Context, _ scope, _ *memoir.State) (map[string]any, error) { return response, nil })
	}
	response, err = mode.run(ctx, actor, "player_start", request, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if state.Pending == nil && state.Active() && state.Board.Cells[request.Grid-1] == memoir.Road && state.LastGrid == request.Grid && state.LastResult["battle_info"] != nil {
			return state.LastResult, nil
		}
		kind, identifier, err := encounter(*state, request.Grid)
		if err != nil {
			return nil, err
		}
		if kind != memoir.Player {
			return nil, memoir.ErrRefused
		}
		if state.Pending != nil && state.Pending.Kind == memoir.Player {
			if state.Pending.Grid != request.Grid || !slices.Equal(state.Pending.Formation, request.Formation) || state.Pending.Pet != request.Pet {
				return nil, memoir.ErrRefused
			}
			return map[string]any{"attempt": state.Pending.Attempt}, nil
		}
		if err = mode.withdraw(ctx, actor, current, state); err != nil {
			return nil, err
		}
		revision, err := mode.startRevision(ctx, current)
		if err != nil {
			return nil, err
		}
		battle := applicationcombat.BattleRequest{CampaignType: 53, BattleID: identifier}
		for _, identifier := range request.Formation {
			if !slices.Contains(current.heroes, identifier) || !state.Alive(identifier) {
				return nil, memoir.ErrRefused
			}
			battle.TeamA = append(battle.TeamA, applicationcombat.Participant{Origin: combat.OwnedSelf, Kind: combat.HeroActor, Player: actor.PlayerID, Identity: identifier})
		}
		if request.Pet > 0 {
			if !slices.Contains(current.pets, request.Pet) {
				return nil, memoir.ErrRefused
			}
			battle.PetsA = []applicationcombat.Participant{{Origin: combat.OwnedSelf, Kind: combat.PetActor, Player: actor.PlayerID, Identity: request.Pet}}
		}
		opponent, present := state.Opponents[int(identifier)]
		if !present {
			return nil, memoir.ErrUnavailable
		}
		keys := make([]string, 0, len(opponent.Heroes))
		for key := range opponent.Heroes {
			keys = append(keys, key)
		}
		sort.Strings(keys)
		enemies := []applicationcombat.Participant{}
		for _, key := range keys {
			identifier, err := strconv.ParseInt(key, 10, 64)
			if err != nil || identifier <= 0 {
				return nil, memoir.ErrUnavailable
			}
			parameters := map[string]any{}
			for name, value := range opponent.Heroes[key] {
				parameters[name] = value
			}
			parameters["partner_id"], parameters["player_id"] = identifier, int64(0)
			enemies = append(enemies, applicationcombat.Participant{Origin: combat.Template, Kind: combat.HeroActor, Identity: identifier, TemplateParams: parameters})
		}
		if len(enemies) == 0 {
			return nil, memoir.ErrUnavailable
		}
		battle.WavesB = [][]applicationcombat.Participant{enemies}
		parameters, err := combat.CanonicalJSON(map[string]any{"heroes_status": state.Heroes, "enemy_status": state.Enemies[request.Grid].Statuses})
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
			Request    PlayerFight
		}{generation, request})
		if err != nil {
			return nil, err
		}
		deadline := current.timed.Operation.DecisionAt().Add(time.Duration(memoir.ResultWindowSeconds) * time.Second)
		started, err := mode.Combat.StartTx(ctx, current.timed.Tx, coherent, applicationcombat.StartRequest{Actor: actor, Locator: locator(actor), GenerationRef: generation, StartFingerprint: fmt.Sprintf("%x", fingerprint), ResultDeadline: deadline, Battle: battle})
		if err != nil {
			return nil, err
		}
		state.Pending = &memoir.Pending{Attempt: started.Attempt.ID.String(), Generation: generation, Revision: state.Revision, Grid: request.Grid, Kind: kind, FirstWave: 1, Deadline: deadline.Unix(), Formation: append([]int64{}, request.Formation...), Pet: request.Pet, Rewards: freezeRewards(current, *state, kind)}
		frozen, err := frozenOperation(current, revision)
		if err != nil {
			return nil, err
		}
		if _, err = mode.Energy.DebitTemporalTx(ctx, current.timed.Tx, actor.PlayerID, "energy", current.catalog.Floors[state.Floor-1].Energy[1], frozen); err != nil {
			return nil, err
		}
		return map[string]any{"attempt": started.Attempt.ID.String()}, nil
	})
	if err != nil || response["battle_info"] != nil {
		return response, err
	}
	attempt, valid := response["attempt"].(string)
	if !valid || attempt == "" {
		return nil, memoir.ErrUnavailable
	}
	return mode.playerReply(ctx, actor, attempt, operationContext)
}
func (mode Mode) resumePlayer(ctx context.Context, actor identity.ActorContext, operationContext operation.Context) (map[string]any, error) {
	operationContext, err := mode.pin(ctx, operationContext)
	if err != nil {
		return nil, err
	}
	state, _, err := mode.Store.ReadTx(ctx, mode.Fresh, actor.PlayerID)
	if err != nil || state.Pending == nil || state.Pending.Kind != memoir.Player {
		return nil, err
	}
	pending := *state.Pending
	attempt, err := ids.ParseUUID(pending.Attempt)
	if err != nil {
		return nil, memoir.ErrUnavailable
	}
	_, resolveError := mode.Combat.Resolve(ctx, operationContext, attempt)
	if resolveError != nil && !errors.Is(resolveError, combat.ErrResolverPermanent) {
		return nil, resolveError
	}
	return mode.run(ctx, actor, "player_finish", pending.Attempt, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if state.Pending == nil {
			if state.LastResult != nil {
				return state.LastResult, nil
			}
			return nil, memoir.ErrRefused
		}
		if state.Pending.Attempt != pending.Attempt {
			return nil, memoir.ErrRefused
		}
		terminal := applicationcombat.TerminalRequest{Locator: locator(actor), GenerationRef: pending.Generation, TerminalKind: "MEMOIR_PLAYER_RESULT", SemanticReceiptID: "memoir-result:" + pending.Attempt, At: current.timed.Operation.DecisionAt()}
		if resolveError != nil || current.timed.Operation.DecisionAt().Unix() >= pending.Deadline {
			terminal.TerminalKind = "MEMOIR_PLAYER_CLOSED"
			if _, err := mode.Combat.CloseTx(ctx, current.timed.Tx, terminal); err != nil {
				return nil, err
			}
			state.Pending = nil
			return map[string]any{"error_code": int64(combat.FightExistCode)}, nil
		}
		settled, err := mode.Combat.TerminalTx(ctx, current.timed.Tx, terminal)
		if err != nil {
			return nil, err
		}
		allies, enemies, err := playerStatuses(settled.Report, pending.Formation, int64(actor.PlayerID))
		if err != nil {
			return nil, err
		}
		state.ApplyHeroes(allies)
		state.Enemies[pending.Grid] = memoir.EnemyCarry{Round: 1, Statuses: enemies}
		awards := []map[string]any{}
		if settled.Resolution.Outcome.Star > 0 {
			if err = state.Board.ClearEnemy(pending.Grid); err != nil {
				return nil, err
			}
			awards, err = mode.grant(ctx, actor, current, *state, "battle/"+pending.Attempt, pending.Rewards)
			if err != nil {
				return nil, err
			}
			if err = state.AppendDrops(pending.Rewards); err != nil {
				return nil, err
			}
		}
		state.Pending = nil
		response := projection(*state)
		health := map[int64]combat.ActorStatus{}
		for _, status := range allies {
			health[status.Identity] = status
		}
		response["battle_info"] = map[string]any{"battle_report": string(settled.Report), "star": settled.Resolution.Outcome.Star, "health_status": map[string]any{"team_A": health}}
		response["awards"] = awards
		state.LastGrid, state.LastResult = pending.Grid, response
		return response, nil
	})
}
func playerStatuses(raw []byte, formation []int64, player int64) ([]combat.ActorStatus, map[int64]combat.ActorStatus, error) {
	var report struct {
		Fighters map[string]struct {
			Summon int `json:"summon_type"`
			Hero   struct {
				Identity int64 `json:"partner_id"`
			} `json:"hero"`
			Final *combat.ActorStatus `json:"memoir_final_status"`
		} `json:"fighter"`
	}
	if json.Unmarshal(raw, &report) != nil {
		return nil, nil, memoir.ErrUnavailable
	}
	allies := []combat.ActorStatus{}
	enemies := map[int64]combat.ActorStatus{}
	seen := map[int64]bool{}
	for key, fighter := range report.Fighters {
		if fighter.Summon != 0 {
			continue
		}
		if !strings.HasPrefix(key, "A|") && !strings.HasPrefix(key, "B|") {
			continue
		}
		if fighter.Hero.Identity <= 0 || fighter.Final == nil {
			return nil, nil, memoir.ErrUnavailable
		}
		status := *fighter.Final
		status.Identity = fighter.Hero.Identity
		if !(combat.Report{Allies: []combat.ActorStatus{status}}).Finite() || status.HP < 0 || status.MP < 0 || status.MP > 1000 || status.Reborn < 0 || status.Reborn > 1 {
			return nil, nil, memoir.ErrUnavailable
		}
		if strings.HasPrefix(key, "B|") {
			enemies[status.Identity] = status
			continue
		}
		if !slices.Contains(formation, status.Identity) || seen[status.Identity] {
			return nil, nil, memoir.ErrUnavailable
		}
		status.Player = player
		seen[status.Identity] = true
		allies = append(allies, status)
	}
	if len(allies) != len(formation) || len(enemies) == 0 {
		return nil, nil, memoir.ErrUnavailable
	}
	sort.Slice(allies, func(left, right int) bool { return allies[left].Identity < allies[right].Identity })
	return allies, enemies, nil
}

func (mode Mode) playerReply(ctx context.Context, actor identity.ActorContext, attempt string, operationContext operation.Context) (map[string]any, error) {
	stored, present, err := mode.ReceiptRead.Find(ctx, receipt.Identity{OwnerKind: "player", OwnerKey: fmt.Sprint(actor.PlayerID), Domain: "memoir", Operation: "player_finish", SemanticKey: attempt})
	if err != nil {
		return nil, err
	}
	if present {
		fingerprint, err := receipt.FingerprintRequest(attempt)
		if err != nil {
			return nil, err
		}
		if stored.RequestFingerprint != fingerprint {
			return nil, memoir.ErrUnavailable
		}
		var response map[string]any
		if err = json.Unmarshal(stored.ResultPayload, &response); err != nil {
			return nil, err
		}
		return mode.run(ctx, actor, "player_replay", attempt, operationContext, func(_ context.Context, _ scope, _ *memoir.State) (map[string]any, error) { return response, nil })
	}
	state, _, err := mode.Store.ReadTx(ctx, mode.Fresh, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	if state.Pending == nil || state.Pending.Attempt != attempt {
		return nil, memoir.ErrUnavailable
	}
	return mode.resumePlayer(ctx, actor, operationContext)
}
