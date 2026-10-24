package i4store

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/application/playerdirectory"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/tx"
)

// MaxDirectoryDiscoveryRead is an adapter safety bound, not Social gameplay
// policy. Social-specific saturation/scan limits remain in the Social owner.
const MaxDirectoryDiscoveryRead = 512

const exactNameProfilesSQL = `
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'player_id',player_id,
  'name',name,
  'lev',lev,
  'avatar_id',avatar_id,
  'avatar_frame_id',avatar_frame_id,
  'conquer_lev',conquer_lev,
  'conquer_loop_id',conquer_loop_id
) ORDER BY player_id),'[]'::jsonb)::text
FROM (
  SELECT player_id,name,lev,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id
  FROM player_directory_profiles
  WHERE name COLLATE "C" = $1 COLLATE "C"
  ORDER BY player_id
  LIMIT $2
) p`

const playerIDBoundsSQL = `SELECT COALESCE(MIN(player_id),0),COALESCE(MAX(player_id),0) FROM player_directory_profiles`

const profilesAfterSQL = `
SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'player_id',player_id,
  'name',name,
  'lev',lev,
  'avatar_id',avatar_id,
  'avatar_frame_id',avatar_frame_id,
  'conquer_lev',conquer_lev,
  'conquer_loop_id',conquer_loop_id
) ORDER BY player_id),'[]'::jsonb)::text
FROM (
  SELECT player_id,name,lev,avatar_id,avatar_frame_id,conquer_lev,conquer_loop_id
  FROM player_directory_profiles
  WHERE player_id > $1
  ORDER BY player_id
  LIMIT $2
) p`

func validDiscoveryLimit(limit int) bool { return limit > 0 && limit <= MaxDirectoryDiscoveryRead }

func (r PlayerDirectoryReader) ProfilesByExactName(ctx context.Context, name string, limit int) ([]playerdirectory.Profile, error) {
	if r.Queryer == nil || !validDiscoveryLimit(limit) {
		return nil, errors.New("invalid player directory discovery read")
	}
	return readProfileJSON(r.Queryer.QueryRow(ctx, exactNameProfilesSQL, name, limit))
}

func (r PlayerDirectoryReader) PlayerIDBounds(ctx context.Context) (identity.PlayerID, identity.PlayerID, bool, error) {
	if r.Queryer == nil {
		return 0, 0, false, errors.New("invalid player directory discovery read")
	}
	var minRaw, maxRaw int64
	if err := r.Queryer.QueryRow(ctx, playerIDBoundsSQL).Scan(&minRaw, &maxRaw); err != nil {
		return 0, 0, false, err
	}
	if minRaw == 0 && maxRaw == 0 {
		return 0, 0, false, nil
	}
	min, max := identity.PlayerID(minRaw), identity.PlayerID(maxRaw)
	if !min.Valid() || !max.Valid() || min > max {
		return 0, 0, false, errors.New("invalid stored player directory bounds")
	}
	return min, max, true, nil
}

// ProfilesAfter returns canonical profiles strictly after afterPlayerID in
// ascending PlayerID order. Zero is the explicit before-first sentinel.
func (r PlayerDirectoryReader) ProfilesAfter(ctx context.Context, afterPlayerID identity.PlayerID, limit int) ([]playerdirectory.Profile, error) {
	if r.Queryer == nil || afterPlayerID < 0 || !validDiscoveryLimit(limit) {
		return nil, errors.New("invalid player directory discovery read")
	}
	return readProfileJSON(r.Queryer.QueryRow(ctx, profilesAfterSQL, int64(afterPlayerID), limit))
}

type discoveryProfileRow struct {
	PlayerID      int64  `json:"player_id"`
	Name          string `json:"name"`
	Level         int64  `json:"lev"`
	AvatarID      int64  `json:"avatar_id"`
	AvatarFrameID int64  `json:"avatar_frame_id"`
	ConquerLevel  int64  `json:"conquer_lev"`
	ConquerLoopID int64  `json:"conquer_loop_id"`
}

func readProfileJSON(row tx.Row) ([]playerdirectory.Profile, error) {
	var raw string
	if err := row.Scan(&raw); err != nil {
		return nil, err
	}
	var rows []discoveryProfileRow
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	out := make([]playerdirectory.Profile, 0, len(rows))
	var previous identity.PlayerID
	for _, x := range rows {
		p := playerdirectory.Profile{PlayerID: identity.PlayerID(x.PlayerID), Name: x.Name, Level: x.Level, AvatarID: x.AvatarID, AvatarFrameID: x.AvatarFrameID, ConquerLevel: x.ConquerLevel, ConquerLoopID: x.ConquerLoopID}
		if err := p.Validate(); err != nil {
			return nil, err
		}
		if previous != 0 && p.PlayerID <= previous {
			return nil, errors.New("player directory discovery result is not strictly ordered")
		}
		previous = p.PlayerID
		out = append(out, p)
	}
	return out, nil
}

var _ playerdirectory.DiscoveryReader = PlayerDirectoryReader{}
