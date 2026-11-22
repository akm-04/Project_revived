package mentorstore

import (
	"context"
	"encoding/json"
	"time"

	"gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type applicationJSON struct {
	Applicant int64     `json:"applicant_id"`
	Target    int64     `json:"target_id"`
	Server    int32     `json:"logical_server_id"`
	Slot      int16     `json:"recipient_relation_type"`
	Message   string    `json:"msg"`
	CreatedAt time.Time `json:"created_at"`
	ExpiresAt time.Time `json:"expires_at"`
	Status    string    `json:"status"`
	Version   int64     `json:"state_version"`
}

func (row applicationJSON) domain() (mentor.Application, error) {
	slot := domain.Slot(row.Slot)
	if !slot.Valid() || row.Applicant <= 0 || row.Target <= 0 || row.Applicant == row.Target || row.Version < 1 {
		return mentor.Application{}, domain.ErrApplication
	}
	switch row.Status {
	case mentor.ApplicationPending, mentor.ApplicationAccepted, mentor.ApplicationDenied:
	default:
		return mentor.Application{}, domain.ErrApplication
	}
	return mentor.Application{Applicant: identity.PlayerID(row.Applicant), Target: identity.PlayerID(row.Target), Server: identity.LogicalServerID(row.Server), RecipientSlot: slot, Message: row.Message, CreatedAt: row.CreatedAt.UTC(), ExpiresAt: row.ExpiresAt.UTC(), Status: row.Status, Version: row.Version}, nil
}

func (Store) LockApplicationTx(ctx context.Context, t tx.Tx, applicant, target identity.PlayerID) (mentor.Application, bool, error) {
	if t == nil || !applicant.Valid() || !target.Valid() || applicant == target {
		return mentor.Application{}, false, domain.ErrApplication
	}
	var raw string
	err := t.QueryRow(ctx, `SELECT to_jsonb(a)::text FROM mentor_applications a WHERE applicant_id=$1 AND target_id=$2 FOR UPDATE`, int64(applicant), int64(target)).Scan(&raw)
	if err != nil {
		if isNoRows(err) {
			return mentor.Application{}, false, nil
		}
		return mentor.Application{}, false, err
	}
	var row applicationJSON
	if err := json.Unmarshal([]byte(raw), &row); err != nil {
		return mentor.Application{}, false, domain.ErrApplication
	}
	application, err := row.domain()
	return application, err == nil, err
}

func (Store) PutApplicationTx(ctx context.Context, t tx.Tx, previous *mentor.Application, next mentor.Application) error {
	if err := requireWritableTx(ctx, t); err != nil {
		return err
	}
	if next.Server.Valid() == false || !next.Applicant.Valid() || !next.Target.Valid() || next.Applicant == next.Target || !next.RecipientSlot.Valid() || next.CreatedAt.IsZero() || next.ExpiresAt.IsZero() || !next.ExpiresAt.After(next.CreatedAt) || next.Version < 1 {
		return domain.ErrApplication
	}
	if previous == nil {
		result, err := t.Exec(ctx, `INSERT INTO mentor_applications(applicant_id,target_id,logical_server_id,recipient_relation_type,msg,created_at,expires_at,status,state_version)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9) ON CONFLICT(applicant_id,target_id) DO NOTHING`, int64(next.Applicant), int64(next.Target), int32(next.Server), int16(next.RecipientSlot), next.Message, next.CreatedAt, next.ExpiresAt, next.Status, next.Version)
		if err != nil {
			return err
		}
		if result.RowsAffected() != 1 {
			return domain.ErrRelationshipConflict
		}
		return nil
	}
	result, err := t.Exec(ctx, `UPDATE mentor_applications SET recipient_relation_type=$3,msg=$4,created_at=$5,expires_at=$6,status=$7,state_version=$8 WHERE applicant_id=$1 AND target_id=$2 AND state_version=$9`, int64(next.Applicant), int64(next.Target), int16(next.RecipientSlot), next.Message, next.CreatedAt, next.ExpiresAt, next.Status, next.Version, previous.Version)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return domain.ErrRelationshipConflict
	}
	return nil
}

func (Store) ListApplicationsToTx(ctx context.Context, q tx.Queryer, recipient identity.PlayerID, server identity.LogicalServerID, at time.Time) ([]mentor.Application, error) {
	if q == nil || !recipient.Valid() || !server.Valid() || logicalserver.PlayerRegion(recipient) != server || at.IsZero() {
		return nil, domain.ErrApplication
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(to_jsonb(a) ORDER BY created_at,applicant_id),'[]'::jsonb)::text FROM (SELECT * FROM mentor_applications WHERE target_id=$1 AND logical_server_id=$2 AND status='PENDING' AND expires_at>$3 ORDER BY created_at,applicant_id LIMIT 64) a`, int64(recipient), int32(server), at.UTC()).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var rows []applicationJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, domain.ErrApplication
	}
	out := make([]mentor.Application, 0, len(rows))
	for _, row := range rows {
		application, err := row.domain()
		if err != nil || application.Target != recipient || application.Server != server || application.Status != mentor.ApplicationPending || !application.ExpiresAt.After(at) {
			return nil, domain.ErrApplication
		}
		out = append(out, application)
	}
	return out, nil
}

func (Store) PendingTargetsTx(ctx context.Context, q tx.Queryer, applicant identity.PlayerID, server identity.LogicalServerID, at time.Time) ([]identity.PlayerID, error) {
	if q == nil || !applicant.Valid() || !server.Valid() || logicalserver.PlayerRegion(applicant) != server || at.IsZero() {
		return nil, domain.ErrApplication
	}
	var raw string
	err := q.QueryRow(ctx, `SELECT COALESCE(jsonb_agg(target_id ORDER BY target_id),'[]'::jsonb)::text FROM (SELECT target_id FROM mentor_applications WHERE applicant_id=$1 AND logical_server_id=$2 AND status='PENDING' AND expires_at>$3 ORDER BY target_id LIMIT 64) t`, int64(applicant), int32(server), at.UTC()).Scan(&raw)
	if err != nil {
		return nil, err
	}
	var ids []int64
	if err := json.Unmarshal([]byte(raw), &ids); err != nil {
		return nil, domain.ErrApplication
	}
	out := make([]identity.PlayerID, len(ids))
	for index, id := range ids {
		out[index] = identity.PlayerID(id)
	}
	return out, nil
}
