package socialinvitestore

import (
	"context"
	"encoding/json"
	"errors"

	"gxb.local/backend/v2/internal/adapters/postgres/kernelstore"
	application "gxb.local/backend/v2/internal/application/socialinvite"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

func errNoRows() error { return kernelstore.ErrNoRows }

// TuningTx reads the validated D476 operator overlay. Absence means source policy.
func (Store) TuningTx(ctx context.Context, query tx.Queryer) (json.RawMessage, error) {
	if query == nil {
		return nil, application.ErrFacts
	}
	var payload string
	err := query.QueryRow(ctx, `SELECT payload::text FROM social_invite_tuning WHERE singleton=true`).Scan(&payload)
	if errors.Is(err, errNoRows()) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return json.RawMessage(payload), nil
}

// Store is the socialinvite owner adapter. It reads and writes only the two
// tables created by migration 00130.
type Store struct{}

var _ application.Owner = Store{}

func (Store) ReadBindingTx(ctx context.Context, query tx.Queryer, invitee identity.PlayerID) (application.BindingRecord, bool, error) {
	if query == nil || !invitee.Valid() {
		return application.BindingRecord{}, false, application.ErrFacts
	}
	var record application.BindingRecord
	var operationID string
	err := query.QueryRow(ctx, `SELECT inviter_player_id,logical_server_id,operation_id::text,policy_version,bound_at FROM social_invite_bindings WHERE invitee_player_id=$1`, int64(invitee)).Scan(&record.Inviter, &record.LogicalServerID, &operationID, &record.PolicyVersion, &record.BoundAt)
	if errors.Is(err, errNoRows()) {
		return application.BindingRecord{}, false, nil
	}
	if err != nil {
		return application.BindingRecord{}, false, err
	}
	record.Invitee = invitee
	record.OperationID, err = ids.ParseUUID(operationID)
	if err != nil {
		return application.BindingRecord{}, false, application.ErrFacts
	}
	record.BoundAt = record.BoundAt.UTC()
	if record.Validate() != nil || record.Invitee != invitee {
		return application.BindingRecord{}, false, application.ErrFacts
	}
	return record, true, nil
}

func (Store) InsertBindingTx(ctx context.Context, transaction tx.Tx, record application.BindingRecord) error {
	if transaction == nil || record.Validate() != nil {
		return application.ErrFacts
	}
	tag, err := transaction.Exec(ctx, `INSERT INTO social_invite_bindings(invitee_player_id,inviter_player_id,logical_server_id,operation_id,policy_version,bound_at) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(invitee_player_id) DO NOTHING`, int64(record.Invitee), int64(record.Inviter), int32(record.LogicalServerID), record.OperationID.String(), record.PolicyVersion, record.BoundAt)
	if err != nil {
		return err
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return application.ErrBindConflict
	}
	return nil
}

func (Store) InviteesForInviterTx(ctx context.Context, query tx.Queryer, inviter identity.PlayerID, server identity.LogicalServerID, limit int) ([]identity.PlayerID, error) {
	if query == nil || !inviter.Valid() || !server.Valid() || limit < 1 {
		return nil, application.ErrFacts
	}
	var raw string
	err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(invitee_player_id ORDER BY invitee_player_id),'[]'::jsonb)::text FROM (SELECT invitee_player_id FROM social_invite_bindings WHERE inviter_player_id=$1 AND logical_server_id=$2 ORDER BY invitee_player_id LIMIT $3) rows`, int64(inviter), int32(server), limit+1).Scan(&raw)
	if err != nil {
		return nil, err
	}
	out := []identity.PlayerID{}
	if err := json.Unmarshal([]byte(raw), &out); err != nil || len(out) > limit {
		return nil, application.ErrFacts
	}
	return out, nil
}

func (Store) ClaimsTx(ctx context.Context, query tx.Queryer, player identity.PlayerID, server identity.LogicalServerID) ([]int64, error) {
	if query == nil || !player.Valid() || !server.Valid() {
		return nil, application.ErrFacts
	}
	var raw string
	err := query.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(mission_id ORDER BY mission_id),'[]'::jsonb)::text FROM (SELECT mission_id FROM social_invite_mission_claims WHERE player_id=$1 AND logical_server_id=$2 ORDER BY mission_id LIMIT $3) rows`, int64(player), int32(server), application.ClaimLimit+1).Scan(&raw)
	if err != nil {
		return nil, err
	}
	out := []int64{}
	if err := json.Unmarshal([]byte(raw), &out); err != nil || len(out) > application.ClaimLimit {
		return nil, application.ErrFacts
	}
	return out, nil
}

func (Store) InsertClaimTx(ctx context.Context, transaction tx.Tx, record application.ClaimRecord) error {
	if transaction == nil || record.Validate() != nil {
		return application.ErrFacts
	}
	tag, err := transaction.Exec(ctx, `INSERT INTO social_invite_mission_claims(player_id,mission_id,logical_server_id,operation_id,content_revision,policy_version,grant_key,claimed_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT(player_id,mission_id) DO NOTHING`, record.Player, record.Mission, int32(record.LogicalServerID), record.OperationID.String(), record.ContentRevision, record.PolicyVersion, record.GrantKey, record.ClaimedAt)
	if err != nil {
		return err
	}
	if tag == nil || tag.RowsAffected() != 1 {
		return application.ErrClaimRefused
	}
	return nil
}
