package i5store

import (
	"context"
	"encoding/json"
	"errors"
	app "gxb.local/backend/v2/internal/application/i5"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/player"
	"gxb.local/backend/v2/internal/foundation/tx"
	"time"
)

var _ app.PublicPlayerBasisReader = Store{}

func (Store) ReadPublicPlayerBasisTx(c context.Context, q tx.Queryer, pid identity.PlayerID) (app.PublicPlayerBasis, error) {
	if q == nil || !pid.Valid() {
		return app.PublicPlayerBasis{}, errors.New("invalid public Player read")
	}
	var b app.PublicPlayerBasis
	var id, progressID int64
	e := q.QueryRow(c, `SELECT p.player_id,p.display_name,p.avatar_id,p.avatar_frame_id,p.player_type,p.state_version,p.created_at,p.updated_at,pr.player_id,pr.level,pr.exp,pr.state_version,pr.updated_at FROM player_profiles p JOIN player_progression pr USING(player_id) WHERE p.player_id=$1`, int64(pid)).Scan(&id, &b.Profile.DisplayName, &b.Profile.AvatarID, &b.Profile.AvatarFrameID, &b.Profile.PlayerType, &b.Profile.StateVersion, &b.Profile.CreatedAt, &b.Profile.UpdatedAt, &progressID, &b.Progression.Level, &b.Progression.Exp, &b.Progression.StateVersion, &b.Progression.UpdatedAt)
	if e != nil {
		return b, e
	}
	if id != int64(pid) || progressID != id {
		return b, errors.New("public Player owner mismatch")
	}
	b.Profile.PlayerID = pid
	b.Progression.PlayerID = pid
	b.Profile.CreatedAt = b.Profile.CreatedAt.UTC()
	b.Profile.UpdatedAt = b.Profile.UpdatedAt.UTC()
	b.Progression.UpdatedAt = b.Progression.UpdatedAt.UTC()
	var raw string
	e = q.QueryRow(c, `SELECT COALESCE(jsonb_agg(jsonb_build_object('function_id',function_id,'opened_at',opened_at,'source_fact_key',source_fact_key,'state_version',state_version) ORDER BY function_id),'[]'::jsonb)::text FROM player_function_unlocks WHERE player_id=$1`, int64(pid)).Scan(&raw)
	if e != nil {
		return b, e
	}
	var fs []struct {
		FunctionID    int64     `json:"function_id"`
		OpenedAt      time.Time `json:"opened_at"`
		SourceFactKey string    `json:"source_fact_key"`
		StateVersion  int64     `json:"state_version"`
	}
	if e = json.Unmarshal([]byte(raw), &fs); e != nil {
		return b, e
	}
	b.Functions = make([]player.FunctionUnlock, 0, len(fs))
	for _, f := range fs {
		b.Functions = append(b.Functions, player.FunctionUnlock{PlayerID: pid, FunctionID: f.FunctionID, OpenedAt: f.OpenedAt.UTC(), SourceFactKey: f.SourceFactKey, StateVersion: f.StateVersion})
	}
	return b, b.Validate()
}
