package socialrecallstore

import (
	"context"
	"encoding/json"
	"time"

	application "gxb.local/backend/v2/internal/application/socialrecall"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/socialrecall"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var _ application.AwardOwner = Store{}

func (Store) CompletedTasksTx(ctx context.Context, query tx.Queryer, player identity.PlayerID, server identity.LogicalServerID, at time.Time) ([]application.TaskRecord, error) {
	if query == nil || !player.Valid() || !server.Valid() || logicalserver.PlayerRegion(player) != server || at.IsZero() {
		return nil, application.ErrAwardFacts
	}
	var raw string
	if err := query.QueryRow(ctx, "SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY target_player_id),'[]'::jsonb)::text FROM social_recall_tasks t WHERE caller_player_id=$1 AND logical_server_id=$2 AND status='COMPLETED' AND completed_at<=$3", int64(player), int32(server), at).Scan(&raw); err != nil {
		return nil, err
	}
	var rows []struct {
		Operation   string                   `json:"operation_id"`
		Caller      identity.PlayerID        `json:"caller_player_id"`
		Target      identity.PlayerID        `json:"target_player_id"`
		Server      identity.LogicalServerID `json:"logical_server_id"`
		Revision    string                   `json:"content_revision"`
		Policy      string                   `json:"policy_version"`
		StartedAt   time.Time                `json:"started_at"`
		ExpiresAt   time.Time                `json:"expires_at"`
		CompletedAt *time.Time               `json:"completed_at"`
		Status      domain.Status            `json:"status"`
		Level       int64                    `json:"baseline_academy_level"`
		Heroes      int64                    `json:"baseline_owned_hero_count"`
		Charge      int64                    `json:"baseline_charge_total"`
		Version     int64                    `json:"state_version"`
		UpdatedAt   time.Time                `json:"updated_at"`
	}
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, err
	}
	result := make([]application.TaskRecord, 0, len(rows))
	for _, row := range rows {
		identifier, err := ids.ParseUUID(row.Operation)
		if err != nil {
			return nil, application.ErrAwardFacts
		}
		row.StartedAt = row.StartedAt.UTC()
		row.ExpiresAt = row.ExpiresAt.UTC()
		row.UpdatedAt = row.UpdatedAt.UTC()
		if row.CompletedAt != nil {
			completed := row.CompletedAt.UTC()
			row.CompletedAt = &completed
		}
		record := application.TaskRecord{Task: domain.Task{OperationID: identifier, Caller: row.Caller, Target: row.Target, LogicalServerID: row.Server, StartedAt: row.StartedAt, ExpiresAt: row.ExpiresAt, CompletedAt: row.CompletedAt, Status: row.Status, Baseline: domain.Baseline{AcademyLevel: row.Level, OwnedHeroCount: row.Heroes, ChargeTotal: row.Charge}}, ContentRevision: row.Revision, PolicyVersion: row.Policy, StateVersion: row.Version, UpdatedAt: row.UpdatedAt}
		if !validRecord(record) || record.Task.Caller != player || record.Task.LogicalServerID != server || record.Task.Status != domain.StatusCompleted || record.Task.CompletedAt.After(at) || record.UpdatedAt.After(at) {
			return nil, application.ErrAwardFacts
		}
		result = append(result, record)
	}
	return result, nil
}
func (Store) AwardedIDsTx(ctx context.Context, query tx.Queryer, player identity.PlayerID, server identity.LogicalServerID) ([]int64, error) {
	if query == nil || !player.Valid() || !server.Valid() || logicalserver.PlayerRegion(player) != server {
		return nil, application.ErrAwardFacts
	}
	var raw string
	if err := query.QueryRow(ctx, "SELECT COALESCE(jsonb_agg(award_id ORDER BY award_id),'[]'::jsonb)::text FROM social_recall_awards WHERE player_id=$1 AND logical_server_id=$2", int64(player), int32(server)).Scan(&raw); err != nil {
		return nil, err
	}
	var result []int64
	if err := json.Unmarshal([]byte(raw), &result); err != nil {
		return nil, err
	}
	previous := int64(0)
	for _, identifier := range result {
		if identifier <= previous {
			return nil, application.ErrAwardFacts
		}
		previous = identifier
	}
	return result, nil
}
func (Store) InsertAwardTx(ctx context.Context, transaction tx.Tx, record application.AwardRecord) error {
	if transaction == nil || record.Validate() != nil {
		return application.ErrAwardFacts
	}

	effect, err := transaction.Exec(ctx, "INSERT INTO social_recall_awards(player_id,logical_server_id,award_id,gift_id,operation_id,content_revision,policy_version,grant_key,earned_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT(player_id,award_id) DO NOTHING", int64(record.Player), int32(record.Server), record.AwardID, record.GiftID, record.OperationID.String(), record.Revision, record.PolicyVersion, record.GrantKey, record.EarnedAt)
	if err != nil {
		return err
	}
	if effect == nil || effect.RowsAffected() != 1 {
		return application.ErrAwardRefused
	}
	return nil
}
