package topfloor

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"gxb.local/backend/v2/internal/domain/identity"
	march "gxb.local/backend/v2/internal/domain/march"
	d "gxb.local/backend/v2/internal/domain/topfloor"
	"gxb.local/backend/v2/internal/foundation/tx"
	"sort"
	"strconv"
	"time"
)

// MarchCandidatesTx exposes copied defense projections; it neither enters nor
// locks the ladder and never changes another player's team or run health.
func (s Service) MarchCandidatesTx(c context.Context, q tx.Queryer, a identity.ActorContext, at time.Time, limit int) ([]march.Enemy, error) {
	if limit < 15 || limit > 1000 {
		return nil, d.ErrInvalid
	}
	_, catalog, err := s.catalogTx(c, q)
	if err != nil {
		return nil, err
	}
	ranked, err := s.Store.RankedPlayersTx(c, q, a.LogicalServerID)
	if err != nil {
		return nil, err
	}
	out := []march.Enemy{}
	appendView := func(view d.Display) error {
		if len(view.Heroes) == 0 {
			return nil
		}
		enemy := march.Enemy{TableID: view.Occupant.TableID(), AvatarFrame: view.FrameID, ConquerLevel: view.ConquerLevel, ConquerLoop: view.ConquerLoop, Player: int64(view.Occupant.Player), Name: view.Name, Level: view.Level, Avatar: view.AvatarID, Heroes: map[string]map[string]any{}, Force: view.Force}
		// JSON copies prevent health updates from mutating shared catalog/roster rows.
		for i, row := range view.Heroes {
			raw, err := json.Marshal(row)
			if err != nil {
				return err
			}
			copy := map[string]any{}
			decoder := json.NewDecoder(bytes.NewReader(raw))
			decoder.UseNumber()
			if err = decoder.Decode(&copy); err != nil {
				return err
			}
			id, err := strconv.ParseInt(fmt.Sprint(copy["partner_id"]), 10, 64)
			if err != nil {
				return err
			}
			if view.Occupant.IsRobot() {
				enemy.Robot = 1
				copy["table_id"] = copy["partner_id"]
			}
			copy["source_partner_id"] = id
			id = int64(i + 1)
			if !view.Occupant.IsRobot() {
				copy["partner_id"] = id
			}
			copy["hero_id"], copy["player_id"] = id, int64(0)
			copy["health"], copy["hp"], copy["mp"], copy["is_reborn"] = int64(0), int64(0), int64(0), int64(0)
			enemy.Heroes[strconv.FormatInt(id, 10)] = copy
		}
		out = append(out, enemy)
		return nil
	}
	for _, r := range ranked {
		if len(out) >= limit {
			break
		}
		if r.Occupant.Player == a.PlayerID || r.Occupant.IsRobot() {
			continue
		}
		view, err := s.display(c, q, catalog, a.LogicalServerID, r.Occupant, at)
		if err != nil {
			return nil, err
		}
		if err = appendView(view); err != nil {
			return nil, err
		}
	}
	// Sparse preservation servers use existing, source-qualified robot teams.
	profile, found, err := s.Directory.ProfileTx(c, q, a.PlayerID)
	if err != nil {
		return nil, err
	}
	if !found {
		return nil, d.ErrUnavailable
	}
	indices := make([]int, len(catalog.Robots))
	for i := range indices {
		indices[i] = i
	}
	distance := func(i int) int64 {
		n := catalog.Robots[i].Level - profile.Level
		if n < 0 {
			return -n
		}
		return n
	}
	sort.SliceStable(indices, func(i, j int) bool { return distance(indices[i]) < distance(indices[j]) })
	for _, index := range indices {
		if len(out) >= 15 {
			break
		}
		view, err := s.display(c, q, catalog, a.LogicalServerID, d.Occupant{Robot: int64(index + 1)}, at)
		if err != nil {
			return nil, err
		}
		if err = appendView(view); err != nil {
			return nil, err
		}
	}
	return out, nil
}
