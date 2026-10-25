// Package campaignstore persists I9_CAMPAIGN_V1 player state: one campaign_players
// row per player (lock rank 605, F14) and one campaign_nodes row per played node.
package campaignstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	d "gxb.local/backend/v2/internal/domain/campaign"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/modes"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

type nodeRow struct {
	CampaignID  int64 `json:"campaign_id"`
	Star        int64 `json:"star"`
	WinDay      int64 `json:"win_day"`
	Wins        int64 `json:"wins"`
	ResetDay    int64 `json:"reset_day"`
	Resets      int64 `json:"resets"`
	PartnerDrop bool  `json:"partner_drop"`
}

const readSQL = `SELECT p.normal_bonus_id,p.super_bonus_id,p.pending_generation,COALESCE(p.pending_items::text,'[]'),p.last_generation,COALESCE(p.last_result::text,''),p.state_version,
COALESCE((SELECT jsonb_agg(jsonb_build_object('campaign_id',n.campaign_id,'star',n.star,'win_day',n.win_day,'wins',n.wins,'reset_day',n.reset_day,'resets',n.resets,'partner_drop',n.partner_drop))
FROM campaign_nodes n WHERE n.player_id=p.player_id),'[]'::jsonb)::text,p.chapter_claims::text,p.story_claims::text FROM campaign_players p WHERE p.player_id=$1`

// ReadTx is the unlocked read for projections; an absent row is the new-player map.
func (Store) ReadTx(c context.Context, q tx.Queryer, p identity.PlayerID) (d.Record, error) {
	r, err := scan(q.QueryRow(c, readSQL, int64(p)))
	if errors.Is(err, kernelstore.ErrNoRows) {
		return d.Record{Progress: d.Progress{Nodes: map[int64]d.NodeState{}}}, nil
	}
	return r, err
}

// LockTx creates the player row on first use and locks it.
func (Store) LockTx(c context.Context, t tx.Tx, p identity.PlayerID, at time.Time) (d.Record, error) {
	if _, err := t.Exec(c, `INSERT INTO campaign_players(player_id,normal_bonus_id,super_bonus_id,pending_generation,last_generation,state_version,updated_at)VALUES($1,0,0,'','',1,$2) ON CONFLICT(player_id) DO NOTHING`, int64(p), at); err != nil {
		return d.Record{}, err
	}
	return scan(t.QueryRow(c, readSQL+` FOR UPDATE OF p`, int64(p)))
}

func scan(row tx.Row) (d.Record, error) {
	var r d.Record
	var pending, result, nodes, chapters, stories string
	if err := row.Scan(&r.Progress.NormalBonusID, &r.Progress.SuperBonusID, &r.PendingGeneration, &pending, &r.LastGeneration, &result, &r.StateVersion, &nodes, &chapters, &stories); err != nil {
		return d.Record{}, err
	}
	if err := json.Unmarshal([]byte(pending), &r.PendingItems); err != nil {
		return d.Record{}, err
	}
	if result != "" {
		r.LastResult = json.RawMessage(result)
	}
	if err := json.Unmarshal([]byte(chapters), &r.Progress.ChapterClaims); err != nil {
		return r, err
	}
	if err := json.Unmarshal([]byte(stories), &r.Progress.StoryClaims); err != nil {
		return r, err
	}
	var rows []nodeRow
	if err := json.Unmarshal([]byte(nodes), &rows); err != nil {
		return d.Record{}, err
	}
	r.Progress.Nodes = make(map[int64]d.NodeState, len(rows))
	for _, n := range rows {
		r.Progress.Nodes[n.CampaignID] = d.NodeState{CampaignID: n.CampaignID, Star: n.Star, Wins: modes.Counter{Period: n.WinDay, Used: n.Wins},
			Resets: modes.Counter{Period: n.ResetDay, Used: n.Resets}, PartnerDrop: n.PartnerDrop}
	}
	return r, nil
}

// SaveTx writes the locked record and upserts the changed nodes.
func (Store) SaveTx(c context.Context, t tx.Tx, p identity.PlayerID, r d.Record, changed []int64, at time.Time) error {
	var pending, result any
	if r.PendingGeneration != "" {
		raw, err := json.Marshal(r.PendingItems)
		if err != nil {
			return err
		}
		pending = string(raw)
	}
	if r.LastResult != nil {
		result = string(r.LastResult)
	}
	chapters, err := json.Marshal(r.Progress.ChapterClaims)
	if err != nil {
		return err
	}
	if string(chapters) == "null" {
		chapters = []byte("{}")
	}
	stories, err := json.Marshal(r.Progress.StoryClaims)
	if err != nil {
		return err
	}
	if string(stories) == "null" {
		stories = []byte("{}")
	}
	tag, err := t.Exec(c, `UPDATE campaign_players SET normal_bonus_id=$2,super_bonus_id=$3,pending_generation=$4,pending_items=$5::jsonb,last_generation=$6,last_result=$7::jsonb,state_version=state_version+1,updated_at=$8,chapter_claims=$10::jsonb,story_claims=$11::jsonb
WHERE player_id=$1 AND state_version=$9`, int64(p), r.Progress.NormalBonusID, r.Progress.SuperBonusID, r.PendingGeneration, pending, r.LastGeneration, result, at, r.StateVersion, string(chapters), string(stories))
	if err != nil {
		return err
	}
	if tag.RowsAffected() != 1 {
		return errors.New("campaign: stale player row")
	}
	rows := make([]nodeRow, 0, len(changed))
	for _, id := range changed {
		n := r.Progress.State(id)
		rows = append(rows, nodeRow{CampaignID: id, Star: n.Star, WinDay: n.Wins.Period, Wins: n.Wins.Used, ResetDay: n.Resets.Period, Resets: n.Resets.Used, PartnerDrop: n.PartnerDrop})
	}
	if len(rows) == 0 {
		return nil
	}
	raw, err := json.Marshal(rows)
	if err != nil {
		return err
	}
	_, err = t.Exec(c, `INSERT INTO campaign_nodes(player_id,campaign_id,star,win_day,wins,reset_day,resets,partner_drop)
SELECT $1,campaign_id,star,win_day,wins,reset_day,resets,partner_drop FROM jsonb_to_recordset($2::jsonb) AS x(campaign_id bigint,star smallint,win_day bigint,wins bigint,reset_day bigint,resets bigint,partner_drop boolean)
ON CONFLICT(player_id,campaign_id) DO UPDATE SET star=EXCLUDED.star,win_day=EXCLUDED.win_day,wins=EXCLUDED.wins,reset_day=EXCLUDED.reset_day,resets=EXCLUDED.resets,partner_drop=EXCLUDED.partner_drop`, int64(p), string(raw))
	return err
}
