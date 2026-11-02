package builtin

import (
	"encoding/json"
	"errors"
)

type DodgeballCatalog struct {
	Activities        []json.RawMessage `json:"activities"`
	Schema            int               `json:"schema_version"`
	Contract          string            `json:"contract_id"`
	Targets           []json.RawMessage `json:"targets"`
	Groups            []json.RawMessage `json:"groups"`
	Buffs             []json.RawMessage `json:"buffs"`
	TicketItem        int64             `json:"ticket_item"`
	InitialBalls      int64             `json:"initial_balls"`
	MinimumBuffs      int64             `json:"minimum_buffs"`
	MaximumBuffs      int64             `json:"maximum_buffs"`
	FriendProbability int64             `json:"friend_probability_permille"`
	FriendBalls       int64             `json:"friend_balls"`
	IncomingLimit     int64             `json:"incoming_limit"`
	MarkedMultiplier  int64             `json:"marked_multiplier"`
}

func (catalog DodgeballCatalog) Validate() error {
	if catalog.Schema != 1 || catalog.Contract != "I9_DODGEBALL_V1" || len(catalog.Targets) != 90 || len(catalog.Groups) != 5 || len(catalog.Buffs) != 6 || len(catalog.Activities) != 2 || catalog.TicketItem != 50001979 || catalog.InitialBalls != 200 || catalog.MinimumBuffs != 6 || catalog.MaximumBuffs != 9 || catalog.FriendProbability != 100 || catalog.FriendBalls != 5 || catalog.IncomingLimit != 3 || catalog.MarkedMultiplier != 2 {
		return errors.New("dodgeball catalog")
	}
	return nil
}
