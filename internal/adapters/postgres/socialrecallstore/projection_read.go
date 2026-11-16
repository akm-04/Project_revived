package socialrecallstore

import (
	"context"
	"encoding/json"
	"time"

	application "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/tx"
)

const (
	recallProjectionDoingLimit   = 3
	recallProjectionDoneLimit    = 512
	recallProjectionGotLimit     = 512
	recallProjectionAwardedLimit = 25
)

// RecallProjectionReader is the typed owner read used by the existing MID176
// load base. Completed-target current facts reuse the same qualified
// progression/roster/privilege reader as the award transaction; no friend or
// offline eligibility gate is involved.
type RecallProjectionReader struct {
	Current application.CurrentFactsReader
}

var _ application.RecallBaseReader = RecallProjectionReader{}

func (reader RecallProjectionReader) ReadRecallBaseTx(ctx context.Context, scope tx.Scope, actor identity.ActorContext, revision string, at time.Time, friends []identity.PlayerID) (application.RecallBase, error) {
	base := application.RecallBase{Doing: []application.RecallDoing{}, Done: []application.RecallDone{}, Got: []identity.PlayerID{}, Awarded: []int64{}, Recalling: []identity.PlayerID{}}
	if reader.Current == nil || scope.Tx == nil || (scope.Options.Isolation != tx.Serializable && scope.Options.Isolation != tx.RepeatableRead) || !actor.PlayerID.Valid() || !actor.LogicalServerID.Valid() || logicalserver.PlayerRegion(actor.PlayerID) != actor.LogicalServerID || len(revision) != 64 || at.IsZero() {
		return base, application.ErrRecallRead
	}
	if err := reader.readDoing(ctx, scope, actor, at, &base); err != nil {
		return application.RecallBase{}, err
	}
	if err := reader.readCompleted(ctx, scope, actor, revision, at, &base); err != nil {
		return application.RecallBase{}, err
	}
	if err := reader.readGotAndAwarded(ctx, scope, actor, &base); err != nil {
		return application.RecallBase{}, err
	}
	if err := reader.readRecalling(ctx, scope, friends, at, &base); err != nil {
		return application.RecallBase{}, err
	}
	if err := base.Validate(actor.LogicalServerID); err != nil {
		return application.RecallBase{}, err
	}
	return base, nil
}

func (reader RecallProjectionReader) readDoing(ctx context.Context, scope tx.Scope, actor identity.ActorContext, at time.Time, base *application.RecallBase) error {
	var raw string
	err := scope.Tx.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(jsonb_build_object('target',target_player_id,'started',started_at) ORDER BY target_player_id),'[]'::jsonb)::text FROM (SELECT target_player_id,started_at FROM social_recall_tasks WHERE caller_player_id=$1 AND logical_server_id=$2 AND status='ACTIVE' AND started_at<=$3 AND expires_at>$3 ORDER BY target_player_id LIMIT $4) t`, int64(actor.PlayerID), int32(actor.LogicalServerID), at, recallProjectionDoingLimit+1).Scan(&raw)
	if err != nil {
		return err
	}
	var rows []struct {
		Target  identity.PlayerID `json:"target"`
		Started time.Time         `json:"started"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil || len(rows) > recallProjectionDoingLimit {
		return application.ErrRecallRead
	}
	for _, row := range rows {
		if !row.Target.Valid() || logicalserver.PlayerRegion(row.Target) != actor.LogicalServerID || row.Started.IsZero() || row.Started.After(at) {
			return application.ErrRecallRead
		}
		base.Doing = append(base.Doing, application.RecallDoing{PlayerID: row.Target, RecallingTime: row.Started.UTC().Unix()})
	}
	return nil
}

func (reader RecallProjectionReader) readCompleted(ctx context.Context, scope tx.Scope, actor identity.ActorContext, revision string, at time.Time, base *application.RecallBase) error {
	var raw string
	err := scope.Tx.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY target_player_id),'[]'::jsonb)::text FROM (SELECT target_player_id,baseline_academy_level,baseline_owned_hero_count,baseline_charge_total FROM social_recall_tasks WHERE caller_player_id=$1 AND logical_server_id=$2 AND status='COMPLETED' AND completed_at<=$3 ORDER BY target_player_id LIMIT $4) t`, int64(actor.PlayerID), int32(actor.LogicalServerID), at, recallProjectionDoneLimit+1).Scan(&raw)
	if err != nil {
		return err
	}
	var rows []struct {
		Target identity.PlayerID `json:"target_player_id"`
		Level  int64             `json:"baseline_academy_level"`
		Heroes int64             `json:"baseline_owned_hero_count"`
		Charge int64             `json:"baseline_charge_total"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil || len(rows) > recallProjectionDoneLimit {
		return application.ErrRecallRead
	}
	for _, row := range rows {
		if !row.Target.Valid() || logicalserver.PlayerRegion(row.Target) != actor.LogicalServerID {
			return application.ErrRecallRead
		}
		baseline := domain.Baseline{AcademyLevel: row.Level, OwnedHeroCount: row.Heroes, ChargeTotal: row.Charge}
		if baseline.Validate() != nil {
			return application.ErrRecallRead
		}
		current, err := reader.Current.ReadRecallCurrentTx(ctx, scope, row.Target, revision, at)
		if err != nil {
			return err
		}
		if current.PlayerID != row.Target || current.Revision != revision || !current.ObservedAt.Equal(at) || current.Baseline.Validate() != nil {
			return application.ErrRecallRead
		}
		base.Done = append(base.Done, application.RecallDone{PlayerID: row.Target, Baseline: baseline, Current: current.Baseline})
	}
	return nil
}

func (reader RecallProjectionReader) readGotAndAwarded(ctx context.Context, scope tx.Scope, actor identity.ActorContext, base *application.RecallBase) error {
	var gotRaw string
	if err := scope.Tx.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(target_player_id ORDER BY target_player_id),'[]'::jsonb)::text FROM (SELECT DISTINCT target_player_id FROM social_recall_tasks WHERE caller_player_id=$1 AND logical_server_id=$2 ORDER BY target_player_id LIMIT $3) t`, int64(actor.PlayerID), int32(actor.LogicalServerID), recallProjectionGotLimit+1).Scan(&gotRaw); err != nil {
		return err
	}
	if err := json.Unmarshal([]byte(gotRaw), &base.Got); err != nil || len(base.Got) > recallProjectionGotLimit {
		return application.ErrRecallRead
	}
	var awardRaw string
	if err := scope.Tx.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(award_id ORDER BY award_id),'[]'::jsonb)::text FROM (SELECT award_id FROM social_recall_awards WHERE player_id=$1 AND logical_server_id=$2 ORDER BY award_id LIMIT $3) t`, int64(actor.PlayerID), int32(actor.LogicalServerID), recallProjectionAwardedLimit+1).Scan(&awardRaw); err != nil {
		return err
	}
	if err := json.Unmarshal([]byte(awardRaw), &base.Awarded); err != nil || len(base.Awarded) > recallProjectionAwardedLimit {
		return application.ErrRecallRead
	}
	return nil
}

func (reader RecallProjectionReader) readRecalling(ctx context.Context, scope tx.Scope, friends []identity.PlayerID, at time.Time, base *application.RecallBase) error {
	if len(friends) == 0 {
		return nil
	}
	values := make([]int64, 0, len(friends))
	for _, friend := range friends {
		if !friend.Valid() {
			return application.ErrRecallRead
		}
		values = append(values, int64(friend))
	}
	var raw string
	if err := scope.Tx.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(target_player_id ORDER BY target_player_id),'[]'::jsonb)::text FROM (SELECT DISTINCT target_player_id FROM social_recall_tasks WHERE status='ACTIVE' AND started_at<=$2 AND expires_at>$2 AND target_player_id=ANY($1::bigint[]) ORDER BY target_player_id LIMIT $3) t`, values, at, recallProjectionGotLimit+1).Scan(&raw); err != nil {
		return err
	}
	return json.Unmarshal([]byte(raw), &base.Recalling)
}
