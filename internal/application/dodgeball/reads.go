package dodgeball

import (
	"context"
	"gxb.local/backend/v2/internal/domain/dodgeball"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/operation"
	"sort"
)

func (mode Mode) Info(ctx context.Context, actor identity.ActorContext, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "info", struct{}{}, 0, operationContext, func(ctx context.Context, current scope) (map[string]any, error) {
		friends, err := mode.friendRows(ctx, actor, current)
		if err != nil {
			return nil, err
		}
		return map[string]any{"base_info": map[string]any{"daily_count": current.states[actor.PlayerID].Played, "act_id": int64(0)}, "friend_infos": friends}, nil
	})
}

func (mode Mode) FriendInfo(ctx context.Context, actor identity.ActorContext, operationContext operation.Context) (map[string]any, error) {
	return mode.run(ctx, actor, "friends", struct{}{}, 0, operationContext, func(ctx context.Context, current scope) (map[string]any, error) {
		friends, err := mode.friendRows(ctx, actor, current)
		return map[string]any{"friend_infos": friends}, err
	})
}

func (mode Mode) friendRows(ctx context.Context, actor identity.ActorContext, current scope) ([]map[string]any, error) {
	identifiers, err := mode.Friends.ActiveFriendsTx(ctx, current.timed.Tx, actor.PlayerID)
	if err != nil {
		return nil, err
	}
	sort.Slice(identifiers, func(left, right int) bool { return identifiers[left] < identifiers[right] })
	presentations, err := mode.Presentation.ReadManyAtTx(ctx, current.timed.Tx, identifiers, current.timed.Operation.DecisionAt())
	if err != nil {
		return nil, err
	}
	rows := []map[string]any{}
	for _, identifier := range identifiers {
		if identifier == actor.PlayerID || int64(identifier)/100000 != int64(actor.LogicalServerID) {
			return nil, dodgeball.ErrUnavailable
		}
		presentation, present := presentations.Players[identifier]
		if !present || presentation.Validate(identifier) != nil {
			return nil, dodgeball.ErrUnavailable
		}
		state, _, err := mode.Store.ReadTx(ctx, current.timed.Tx, identifier)
		if err != nil {
			return nil, err
		}
		if err = state.Normalize(current.timed.Operation.DecisionAt()); err != nil {
			return nil, err
		}
		invited := int64(0)
		if current.states[actor.PlayerID].Invited[int64(identifier)] {
			invited = 1
		}
		minimal := presentation.Minimal
		rows = append(rows, map[string]any{"player_info": map[string]any{"player_id": int64(identifier), "player_name": minimal.Name, "lev": minimal.Level, "avatar_id": minimal.AvatarID, "avatar_frame_id": minimal.AvatarFrameID, "conquer_lev": minimal.ConquerLevel, "conquer_loop_id": minimal.ConquerLoopID}, "invited_time": state.Incoming, "is_invited": invited})
	}
	return rows, nil
}
