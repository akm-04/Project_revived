package campaign

import (
	"bytes"
	"context"
	"encoding/json"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/objective"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type awakeningStartPackage struct {
	Items     []d.Item                        `json:"items"`
	Awakening *objective.AwakeCampaignContext `json:"awakening,omitempty"`
}

func readAwakeningPending(raw []byte) (*objective.AwakeCampaignContext, error) {
	if len(raw) == 0 {
		return nil, nil
	}
	var c objective.AwakeCampaignContext
	if e := json.Unmarshal(raw, &c); e != nil {
		return nil, e
	}
	return &c, c.Validate()
}
func readAwakeningPackage(raw []byte) ([]d.Item, json.RawMessage, error) {
	raw = bytes.TrimSpace(raw)
	if len(raw) == 0 {
		return nil, nil, d.ErrUnavailable
	}
	if raw[0] == '[' {
		var items []d.Item
		e := json.Unmarshal(raw, &items)
		return items, nil, e
	}
	var p awakeningStartPackage
	if e := json.Unmarshal(raw, &p); e != nil {
		return nil, nil, e
	}
	if p.Items == nil || p.Awakening == nil || p.Awakening.Validate() != nil {
		return nil, nil, d.ErrUnavailable
	}
	frozen, e := json.Marshal(p.Awakening)
	return p.Items, frozen, e
}
func (s Mode) freezeAwakening(c context.Context, q tx.Queryer, pid identity.PlayerID, node d.Node, progress d.Progress, day int64, formation []int64, pet int64) (*objective.AwakeCampaignContext, error) {
	if s.Awakening == nil || node.Type != d.Normal && node.Type != d.Super {
		return nil, nil
	}
	state := progress.State(node.ID)
	eligible := state.Star > 0 && (state.FirstClearDay == nil || day > *state.FirstClearDay)
	frozen, e := s.Awakening.FreezeAwakeningCampaignTx(c, q, pid, node.ID, node.Type, formation, pet, eligible)
	return &frozen, e
}
func (s Mode) settleAwakening(c context.Context, t tx.Tx, pid identity.PlayerID, result Result, record *d.Record, win bool) (map[string]any, error) {
	frozen, e := readAwakeningPending(record.PendingAwakening)
	if e != nil {
		return nil, e
	}
	if frozen == nil {
		if result.AwakeMission != 0 || result.PetAwakeMission != 0 {
			return nil, d.ErrRefused
		}
		return nil, nil
	}
	if s.Awakening == nil || frozen.Campaign != result.CampaignID || frozen.Type != result.Type {
		return nil, d.ErrUnavailable
	}
	drops, body, e := s.Awakening.SettleAwakeningCampaignTx(c, t, pid, *frozen, result.AwakeMission, result.PetAwakeMission, win)
	if e != nil {
		if e == objective.ErrAwakeningRefused {
			return nil, d.ErrRefused
		}
		return nil, e
	}
	for _, drop := range drops {
		record.PendingItems = append(record.PendingItems, d.Item{ItemID: drop.ItemID, Num: drop.Count})
	}
	return body, nil
}
