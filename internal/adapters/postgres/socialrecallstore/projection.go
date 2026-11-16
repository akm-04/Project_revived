package socialrecallstore

import (
	"context"
	"encoding/json"
	"math"
	"time"
	"unicode/utf8"

	"gxb.local/backend/v2/internal/application/characterasset"
	"gxb.local/backend/v2/internal/application/playerdirectory"
	application "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type DoingProjection struct {
	Directory playerdirectory.TxDiscoveryReader
}

var _ application.DoingProjection = DoingProjection{}

func (projection DoingProjection) DoingRecallTx(ctx context.Context, transaction tx.Tx, caller identity.PlayerID, revision string, at time.Time, limit int) ([]application.DoingRecall, error) {
	server := logicalserver.PlayerRegion(caller)
	if projection.Directory == nil || transaction == nil || !caller.Valid() || !server.Valid() || characterasset.ValidateExactRevisionID(revision) != nil || at.IsZero() || limit < 1 || limit == math.MaxInt {
		return nil, application.ErrStartFacts
	}
	var raw string
	err := transaction.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(active) ORDER BY active.started_at DESC,active.target_player_id),'[]'::jsonb)::text FROM (SELECT target_player_id,started_at FROM social_recall_tasks WHERE caller_player_id=$1 AND logical_server_id=$2 AND status='ACTIVE' AND expires_at>$3 ORDER BY started_at DESC,target_player_id LIMIT $4) active`, int64(caller), int32(server), at.UTC(), limit+1).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var tasks []struct {
		Target    identity.PlayerID `json:"target_player_id"`
		StartedAt time.Time         `json:"started_at"`
	}
	if err := json.Unmarshal([]byte(raw), &tasks); err != nil {
		return nil, err
	}
	if len(tasks) > limit {
		return nil, application.ErrStartFacts
	}
	rows := make([]application.DoingRecall, 0, len(tasks))
	seen := make(map[identity.PlayerID]bool, len(tasks))
	for _, task := range tasks {
		if !task.Target.Valid() || task.Target == caller || logicalserver.PlayerRegion(task.Target) != server || seen[task.Target] || task.StartedAt.IsZero() || task.StartedAt.After(at) || task.StartedAt.Unix() < 0 {
			return nil, application.ErrStartFacts
		}
		seen[task.Target] = true
		profile, found, err := projection.Directory.ProfileTx(ctx, transaction, task.Target)
		if err != nil {
			return nil, err
		}
		if !found || profile.PlayerID != task.Target || profile.Validate() != nil || !utf8.ValidString(profile.Name) {
			return nil, application.ErrStartFacts
		}
		rows = append(rows, application.DoingRecall{PlayerID: task.Target, PlayerName: profile.Name, RecallingTime: task.StartedAt.Unix()})
	}
	return rows, nil
}
