package mentorstore

import (
	"context"
	"encoding/json"
	"errors"
	"time"

	"gxb.local/backend/v2/internal/application/mentor"
	"gxb.local/backend/v2/internal/domain/identity"
	"gxb.local/backend/v2/internal/domain/logicalserver"
	domain "gxb.local/backend/v2/internal/domain/mentor"
	"gxb.local/backend/v2/internal/foundation/ids"
	"gxb.local/backend/v2/internal/foundation/tx"
)

type Store struct{}

func validSnapshot(scope tx.Scope) bool {
	return scope.Tx != nil && (scope.Options.Isolation == tx.RepeatableRead || scope.Options.Isolation == tx.Serializable)
}

const selectActiveRelationships = `SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY mentor_id,student_id,relation_id),'[]'::jsonb)::text FROM mentor_relations r WHERE logical_server_id=$2 AND (mentor_id=$1 OR student_id=$1) AND ended_at IS NULL`

type relationshipJSON struct {
	Identifier string     `json:"relation_id"`
	Server     int32      `json:"logical_server_id"`
	MentorID   int64      `json:"mentor_id"`
	StudentID  int64      `json:"student_id"`
	Revision   string     `json:"content_revision"`
	Policy     string     `json:"policy_version"`
	AcceptedAt time.Time  `json:"accepted_at"`
	EndedAt    *time.Time `json:"ended_at"`
	Intimacy   int64      `json:"intimacy"`
	LastDay    *string    `json:"last_intimacy_day"`
	Baseline   int64      `json:"background_baseline"`
	Version    int64      `json:"state_version"`
}

func decodeRelationships(raw string, player identity.PlayerID, server identity.LogicalServerID) ([]domain.Relationship, error) {
	var rows []relationshipJSON
	if err := json.Unmarshal([]byte(raw), &rows); err != nil {
		return nil, domain.ErrRelationship
	}
	if len(rows) > 2 {
		return nil, domain.ErrRelationship
	}
	records := make([]domain.Relationship, 0, len(rows))
	hasMentor, hasStudent := false, false
	for _, row := range rows {
		identifier, err := ids.ParseUUID(row.Identifier)
		if err != nil {
			return nil, domain.ErrRelationship
		}
		record := domain.Relationship{ID: identifier, Mentor: identity.PlayerID(row.MentorID), Student: identity.PlayerID(row.StudentID), Server: identity.LogicalServerID(row.Server), ContentRevision: row.Revision, PolicyVersion: row.Policy, AcceptedAt: row.AcceptedAt.UTC(), Intimacy: row.Intimacy, BackgroundBaseline: row.Baseline, Version: row.Version}
		if row.EndedAt != nil {
			ended := row.EndedAt.UTC()
			record.EndedAt = &ended
		}
		if row.LastDay != nil {
			record.LastIntimacyDay = *row.LastDay
		}
		if record.Validate() != nil || record.EndedAt != nil || record.Server != server || (record.Mentor != player && record.Student != player) {
			return nil, domain.ErrRelationship
		}
		if record.Mentor == player {
			if hasStudent {
				return nil, domain.ErrRelationship
			}
			hasStudent = true
		}
		if record.Student == player {
			if hasMentor {
				return nil, domain.ErrRelationship
			}
			hasMentor = true
		}
		records = append(records, record)
	}
	if len(records) == 2 && records[0].Mentor == records[1].Student && records[0].Student == records[1].Mentor {
		return nil, domain.ErrRelationship
	}
	return records, nil
}

func (Store) ReadRelationshipsTx(ctx context.Context, q tx.Queryer, player identity.PlayerID, server identity.LogicalServerID) ([]domain.Relationship, error) {
	if q == nil || !player.Valid() || !server.Valid() || logicalserver.PlayerRegion(player) != server {
		return nil, domain.ErrRelationship
	}
	var raw string
	if err := q.QueryRow(ctx, selectActiveRelationships, int64(player), int32(server)).Scan(&raw); err != nil {
		return nil, err
	}
	return decodeRelationships(raw, player, server)
}

func (Store) LockRelationshipsTx(ctx context.Context, t tx.Tx, player identity.PlayerID, server identity.LogicalServerID) ([]domain.Relationship, error) {
	if t == nil || !player.Valid() || !server.Valid() || logicalserver.PlayerRegion(player) != server {
		return nil, domain.ErrRelationship
	}
	var raw string
	query := `SELECT COALESCE(jsonb_agg(to_jsonb(r) ORDER BY mentor_id,student_id,relation_id),'[]'::jsonb)::text FROM (SELECT * FROM mentor_relations WHERE logical_server_id=$2 AND (mentor_id=$1 OR student_id=$1) AND ended_at IS NULL ORDER BY mentor_id,student_id,relation_id FOR UPDATE) r`
	if err := t.QueryRow(ctx, query, int64(player), int32(server)).Scan(&raw); err != nil {
		return nil, err
	}
	return decodeRelationships(raw, player, server)
}

// Both canonical I4 player roots must already be fenced in this caller transaction.
func (Store) InsertRelationshipTx(ctx context.Context, t tx.Tx, record domain.Relationship) error {
	if record.Validate() != nil || record.EndedAt != nil || record.Version != 1 {
		return domain.ErrRelationship
	}
	if err := requireWritableTx(ctx, t); err != nil {
		return err
	}
	result, err := t.Exec(ctx, `INSERT INTO mentor_relations(relation_id,logical_server_id,mentor_id,student_id,content_revision,policy_version,accepted_at,intimacy,last_intimacy_day,background_baseline,state_version)VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,1)`, record.ID.String(), int32(record.Server), int64(record.Mentor), int64(record.Student), record.ContentRevision, record.PolicyVersion, record.AcceptedAt, record.Intimacy, sqlDate(record.LastIntimacyDay), record.BackgroundBaseline)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return domain.ErrRelationshipConflict
	}
	return nil
}

// Eligibility, cooldowns, friendship composition and terminal receipt remain caller-owned.
func (Store) EndRelationshipTx(ctx context.Context, t tx.Tx, expected domain.Relationship, at time.Time) error {
	if expected.Validate() != nil || expected.EndedAt != nil || at.IsZero() || at.Location() != time.UTC || at.Before(expected.AcceptedAt) {
		return domain.ErrRelationship
	}
	if err := requireWritableTx(ctx, t); err != nil {
		return err
	}
	result, err := t.Exec(ctx, `UPDATE mentor_relations SET ended_at=$10,state_version=state_version+1 WHERE relation_id=$1 AND logical_server_id=$2 AND mentor_id=$3 AND student_id=$4 AND content_revision=$5 AND policy_version=$6 AND accepted_at=$7 AND state_version=$8 AND ended_at IS NOT DISTINCT FROM $9::timestamptz`, expected.ID.String(), int32(expected.Server), int64(expected.Mentor), int64(expected.Student), expected.ContentRevision, expected.PolicyVersion, expected.AcceptedAt, expected.Version, expected.EndedAt, at)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return domain.ErrRelationshipConflict
	}
	return nil
}

// AddIntimacyTx advances the daily bond exactly once per day key.
func (Store) AddIntimacyTx(ctx context.Context, t tx.Tx, expected domain.Relationship, intimacy int64, day string, at time.Time) error {
	if expected.Validate() != nil || expected.EndedAt != nil || intimacy < 0 || intimacy > 3000 || at.IsZero() {
		return domain.ErrRelationship
	}
	if err := requireWritableTx(ctx, t); err != nil {
		return err
	}
	result, err := t.Exec(ctx, `UPDATE mentor_relations SET intimacy=$2,last_intimacy_day=$3,state_version=state_version+1 WHERE relation_id=$1 AND state_version=$4 AND ended_at IS NULL`, expected.ID.String(), intimacy, sqlDate(day), expected.Version)
	if err != nil {
		return err
	}
	if result.RowsAffected() != 1 {
		return domain.ErrRelationshipConflict
	}
	return nil
}

func sqlDate(day string) any {
	if day == "" {
		return nil
	}
	return day
}

var _ mentor.Store = Store{}
var _ = errors.New
