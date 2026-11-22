package stockruntime

import (
	"gxb.local/backend/v2/internal/adapters/socialpresentation"
	sp "gxb.local/backend/v2/internal/application/socialprojection"
	sr "gxb.local/backend/v2/internal/application/socialrelation"
	"gxb.local/backend/v2/internal/domain/identity"
	"sort"
	"strconv"
)

func mapSocialMutation(r sr.Result, mid uint16) (any, error) {
	ids := []identity.PlayerID{}
	for id := range r.Players.Players {
		ids = append(ids, id)
	}
	sort.Slice(ids, func(i, j int) bool { return ids[i] < ids[j] })
	v := sp.Result{ObservedAt: r.Players.ObservedAt}
	for _, id := range ids {
		p := r.Players.Players[id]
		if p.Validate(id) != nil {
			return nil, sr.ErrInvalidState
		}
		v.Friends = append(v.Friends, sp.Player{Presentation: p})
	}
	friends := socialpresentation.MapBase(v).Friends
	if mid == 177 || mid == 180 {
		if len(friends) != 1 {
			return nil, sr.ErrInvalidState
		}
		return friends[0], nil
	}
	if mid == 185 {
		if len(friends) != 1 {
			return nil, sr.ErrInvalidState
		}
		return map[string]any{"player_info": friends[0].Common}, nil
	}
	out := map[string]any{}
	for _, row := range friends {
		out[strconv.FormatInt(row.PlayerID, 10)] = row
	}
	return out, nil
}
