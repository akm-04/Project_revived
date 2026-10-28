package memoir

import (
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/combat"
	"gxb.local/backend/v2/internal/domain/grant"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/march"
	"gxb.local/backend/v2/internal/domain/memoir"
	"gxb.local/backend/v2/internal/foundation/operation"
	"gxb.local/backend/v2/internal/foundation/policy"
	"slices"
)

func projection(state memoir.State) map[string]any {
	started := int64(0)
	if state.Active() {
		started = 1
	}
	drops := make([]map[string]any, 0, len(state.Drops))
	for _, item := range state.Drops {
		drops = append(drops, map[string]any{"item_id": item.ItemID, "item_num": item.Num})
	}
	response := map[string]any{
		"base_info":  map[string]any{"hero_id": state.Girl, "is_game_start": started, "now_floor": state.Floor, "now_pos": state.Board.Position, "start_pos": memoir.InitialPosition, "end_pos": memoir.FinalPosition, "revive_times": state.ReviveTimes},
		"drops_info": drops, "max_floor_info": state.MaxFloor, "heroes_status": state.Heroes,
	}
	response["maze_info"] = map[string]any{"map_open": map[int]int64{}, "maze_map": []int64{}, "enemy_grids_info": map[int]int64{}}
	if state.Active() {
		response["maze_info"] = map[string]any{"map_open": state.Board.Open, "maze_map": state.Board.Cells, "enemy_grids_info": state.Board.Enemies}
	}
	return response
}
func (mode Mode) Info(ctx context.Context, actor identity.ActorContext, operationContext operation.Context) (map[string]any, error) {
	if _, err := mode.resumePlayer(ctx, actor, operationContext); err != nil {
		return nil, err
	}
	return mode.run(ctx, actor, "info", struct{}{}, operationContext, func(_ context.Context, _ scope, state *memoir.State) (map[string]any, error) {
		return projection(*state), nil
	})
}
func (mode Mode) Start(ctx context.Context, actor identity.ActorContext, girl int64, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "start", girl, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if state.Active() {
			return nil, memoir.ErrRefused
		}
		if _, found := current.catalog.Girl(girl); !found {
			return nil, memoir.ErrInvalid
		}
		sequence := state.Sequence + 1
		maxima := state.MaxFloor
		*state = memoir.State{Girl: girl, Floor: 1, Revision: current.revision, Occurrence: fmt.Sprintf("%d:%d", actor.PlayerID, sequence), Sequence: sequence, MaxFloor: maxima}
		state.Initialize()
		if err := mode.createFloor(ctx, actor, current, state); err != nil {
			return nil, err
		}
		return projection(*state), nil
	})
}
func (mode Mode) createFloor(ctx context.Context, actor identity.ActorContext, current scope, state *memoir.State) error {
	candidates, err := mode.Opponents.MarchCandidatesTx(ctx, current.timed.Tx, actor, current.timed.Operation.DecisionAt(), 1000)
	if err != nil {
		return err
	}
	if len(candidates) == 0 {
		return memoir.ErrUnavailable
	}
	floor := current.catalog.Floors[state.Floor-1]
	first, last := min(max(floor.Opponents[0]-1, 0), len(candidates)-1), min(max(floor.Opponents[1], 1), len(candidates))
	if last <= first {
		last = first + 1
	}
	candidates = candidates[first:last]
	state.Opponents = map[int]march.Enemy{}
	identifiers := []int64{}
	for index, enemy := range candidates {
		// Templates must not retain a mutable provider-owned map.
		raw, err := json.Marshal(enemy)
		if err != nil {
			return err
		}
		var copied march.Enemy
		if err = json.Unmarshal(raw, &copied); err != nil {
			return err
		}
		state.Opponents[index+1] = copied
		identifiers = append(identifiers, int64(index+1))
	}
	random := combat.NewStream(current.timed.Operation.Operation().Derive("memoir.map/v1", uint64(state.Sequence)))
	state.Board, err = current.catalog.NewBoard(state.Girl, state.Floor, identifiers, random)
	state.Enemies = map[int]memoir.EnemyCarry{}
	state.Pending = nil
	state.LastGrid, state.LastResult = 0, nil
	return err
}
func (mode Mode) SaveMap(ctx context.Context, actor identity.ActorContext, position int, opened []int, operationContext operation.Context) (map[string]any, error) {
	request := struct {
		Position int
		Opened   []int
	}{position, opened}
	return mode.run(ctx, actor, "save_map", request, operationContext, func(_ context.Context, _ scope, state *memoir.State) (map[string]any, error) {
		if !state.Active() {
			return nil, memoir.ErrRefused
		}
		if err := state.Board.SaveMap(position, opened); err != nil {
			return nil, err
		}
		return map[string]any{}, nil
	})
}
func (mode Mode) NextFloor(ctx context.Context, actor identity.ActorContext, position int, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "next_floor", position, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if !state.Active() || state.Pending != nil || state.Floor >= len(current.catalog.Floors) || !state.Board.CanExit(position) {
			return nil, memoir.ErrRefused
		}
		state.Floor++
		state.Sequence++
		if err := mode.createFloor(ctx, actor, current, state); err != nil {
			return nil, err
		}
		return projection(*state), nil
	})
}
func (mode Mode) Abandon(ctx context.Context, actor identity.ActorContext, operationContext operation.Context) (map[string]any, error) {
	if _, err := mode.resumePlayer(ctx, actor, operationContext); err != nil {
		return nil, err
	}
	return mode.run(ctx, actor, "abandon", struct{}{}, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if err := mode.withdraw(ctx, actor, current, state); err != nil {
			return nil, err
		}
		state.Abandon()
		return projection(*state), nil
	})
}
func (mode Mode) Revive(ctx context.Context, actor identity.ActorContext, partner int64, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "revive", partner, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if !slices.Contains(current.heroes, partner) {
			return nil, memoir.ErrRefused
		}
		cost, err := state.Revive(partner, current.catalog)
		if err != nil {
			return nil, err
		}
		frozen, err := frozenOperation(current, state.Revision)
		if err != nil {
			return nil, err
		}
		if _, err = mode.Costs.DebitMaterialCostTx(ctx, current.timed.Tx, actor.PlayerID, i5.MaterialCost{Scalars: []i5.ScalarMaterialCost{{ResourceKey: "crystal", Amount: cost}}}, frozen); err != nil {
			return nil, err
		}
		return projection(*state), nil
	})
}
func (mode Mode) OpenBox(ctx context.Context, actor identity.ActorContext, position int, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "open_box", position, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if !state.Active() || state.Pending != nil {
			return nil, memoir.ErrRefused
		}
		index, err := state.Board.OpenBox(position)
		if err != nil {
			return nil, err
		}
		floor := current.catalog.Floors[state.Floor-1]
		girl, _ := current.catalog.Girl(state.Girl)
		random := combat.NewStream(current.timed.Operation.Operation().Derive("memoir.box/v1", uint64(state.Sequence)))
		items, err := current.catalog.GiftItems(floor.Gifts[index], random)
		if err != nil {
			return nil, err
		}
		if floor.BoxScroll[index] > 0 {
			items = append(items, campaign.Item{ItemID: girl.Scroll, Num: floor.BoxScroll[index]})
		}
		key := current.catalog.BigKey
		if index == 1 {
			key = current.catalog.SmallKey
		}
		plan := rewardPlan(actor, *state, fmt.Sprintf("box/%d/%d", state.Floor, position), items)
		frozen, err := frozenOperation(current, state.Revision)
		if err != nil {
			return nil, err
		}
		prepared, err := mode.Exchange.PrepareMaterialExchangeTx(ctx, current.timed.Tx, actor, i5.MaterialExchangeRequest{Cost: i5.MaterialCost{Stacks: []i5.StackMaterialCost{{ItemID: key, Amount: 1}}}, Restoration: plan, AllowOverflowMail: true}, frozen)
		if err != nil {
			return nil, err
		}
		result, err := mode.Exchange.ApplyMaterialExchangeTx(ctx, current.timed.Tx, prepared)
		if err != nil {
			return nil, err
		}
		if err = state.AppendDrops(items); err != nil {
			return nil, err
		}
		response := projection(*state)
		response["awards"] = i5.StockRepresentableBulkAwards(result.Restoration.Awards)
		return response, nil
	})
}
func (mode Mode) FinalAward(ctx context.Context, actor identity.ActorContext, position int, gift int64, operationContext operation.Context) (map[string]any, error) {
	request := struct {
		Position int
		Gift     int64
	}{position, gift}
	return mode.run(ctx, actor, "final_award", request, operationContext, func(ctx context.Context, current scope, state *memoir.State) (map[string]any, error) {
		if !state.Active() || state.Pending != nil || state.Floor != len(current.catalog.Floors) || !state.Board.CanExit(position) || !slices.Contains(current.catalog.FinalGifts, gift) {
			return nil, memoir.ErrRefused
		}
		random := combat.NewStream(current.timed.Operation.Operation().Derive("memoir.final/v1", uint64(state.Sequence)))
		items, err := current.catalog.GiftItems(gift, random)
		if err != nil {
			return nil, err
		}
		awards, err := mode.grant(ctx, actor, current, *state, "final", items)
		if err != nil {
			return nil, err
		}
		if err = state.AppendDrops(items); err != nil {
			return nil, err
		}
		drops := append([]campaign.Item{}, state.Drops...)
		state.MaxFloor[state.Girl] = state.Floor
		state.Abandon()
		response := projection(*state)
		response["drops_info"] = dropProjection(drops)
		response["awards"] = awards
		return response, nil
	})
}
func dropProjection(items []campaign.Item) []map[string]any {
	result := make([]map[string]any, 0, len(items))
	for _, item := range items {
		result = append(result, map[string]any{"item_id": item.ItemID, "item_num": item.Num})
	}
	return result
}
func rewardPlan(actor identity.ActorContext, state memoir.State, key string, items []campaign.Item) grant.Plan {
	lines := make([]grant.Line, 0, len(items))
	for _, item := range items {
		lines = append(lines, grant.Line{Kind: grant.StackItem, ItemID: item.ItemID, Amount: item.Num})
	}
	return grant.Plan{PlayerID: actor.PlayerID, Source: grant.SourceIdentity{Domain: "memoir", Operation: "reward", BusinessKey: state.Occurrence + "/" + key, Occurrence: state.Occurrence, PolicyVersion: memoir.PolicyID}, Lines: lines}
}
func frozenOperation(current scope, revision string) (operation.Context, error) {
	operationContext := current.timed.Operation.Operation()
	references := operationContext.Policies.Refs()
	for index := range references {
		if references[index].Name == "content" {
			references[index].Version = revision
		}
	}
	var err error
	operationContext.Policies, err = policy.NewSet(references...)
	return operationContext, err
}
func (mode Mode) grant(ctx context.Context, actor identity.ActorContext, current scope, state memoir.State, key string, items []campaign.Item) ([]map[string]any, error) {
	if len(items) == 0 {
		return []map[string]any{}, nil
	}
	frozen, err := frozenOperation(current, state.Revision)
	if err != nil {
		return nil, err
	}
	result, err := mode.Grants.SettleGrantTx(ctx, current.timed.Tx, actor, rewardPlan(actor, state, key, items), frozen, i5.GrantTxOptions{AllowOverflowMail: true})
	if err != nil {
		return nil, err
	}
	return i5.StockRepresentableBulkAwards(result.Awards), nil
}
